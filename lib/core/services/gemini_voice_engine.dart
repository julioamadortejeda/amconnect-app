import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import '../network/api_client.dart';
import 'gemini_live_service.dart';
import 'gemini_usage_tracker.dart';
import 'native_audio_service.dart';

/// Eventos de alto nivel que el engine emite hacia el Notifier de cada
/// pantalla. El Notifier solo los mapea a su clase de estado — toda la
/// orquestación (mic, echo guard, turnos, tokens, watchdog) vive aquí y es
/// idéntica para VoiceChat y Assistant.
sealed class VoiceEngineEvent {
  const VoiceEngineEvent();
}

class EngineListening extends VoiceEngineEvent {
  const EngineListening();
}

class EngineModelSpeaking extends VoiceEngineEvent {
  const EngineModelSpeaking();
}

/// Delta de transcripción del usuario (acumular en el live text de la UI).
class EngineUserTranscript extends VoiceEngineEvent {
  final String delta;
  const EngineUserTranscript(this.delta);
}

/// Delta de transcripción del modelo (acumular en el live text de la UI).
class EngineModelTranscript extends VoiceEngineEvent {
  final String delta;
  const EngineModelTranscript(this.delta);
}

/// El turno en vuelo terminó — mover los live texts a burbujas permanentes
/// (usuario primero, luego modelo) y limpiar los buffers de la UI.
/// [metadata] es el `__skillMetadata` de la última skill del turno (si hubo):
/// va anclado a la burbuja del modelo para que la card persista en el hilo,
/// igual que en el chat de texto.
class EngineTurnCommitted extends VoiceEngineEvent {
  final String userText;
  final String modelText;
  final Map<String, dynamic>? metadata;
  const EngineTurnCommitted({
    required this.userText,
    required this.modelText,
    this.metadata,
  });
}

class EngineSkillStarted extends VoiceEngineEvent {
  final String name;
  const EngineSkillStarted(this.name);
}

class EngineSkillCleared extends VoiceEngineEvent {
  const EngineSkillCleared();
}

class EngineWidgetMetadata extends VoiceEngineEvent {
  final Map<String, dynamic> metadata;
  const EngineWidgetMetadata(this.metadata);
}

class EngineWidgetMetadataCleared extends VoiceEngineEvent {
  const EngineWidgetMetadataCleared();
}

class EngineCountdownTick extends VoiceEngineEvent {
  final int secondsLeft;
  const EngineCountdownTick(this.secondsLeft);
}

/// Se agotó el límite de 10 minutos — el Notifier decide cómo cerrar.
class EngineTimeExpired extends VoiceEngineEvent {
  const EngineTimeExpired();
}

/// Gemini lleva 12s sin responder tras hablar el usuario — el Notifier decide
/// (VoiceChat cierra la sesión; Assistant regresa a modo texto).
class EngineWatchdogTimeout extends VoiceEngineEvent {
  const EngineWatchdogTimeout();
}

/// Error fatal (WebSocket caído, cuota agotada…). El engine ya hizo shutdown;
/// el Notifier solo refleja el error en la UI.
class EngineFailure extends VoiceEngineEvent {
  final String message;
  const EngineFailure(this.message);
}

/// Orquesta una sesión de voz full-duplex contra Gemini Live: WebSocket,
/// micrófono nativo, echo guard, commit de turnos, tool calls, tracking de
/// tokens y guardado de rondas. Reutilizable: `connect()` puede llamarse de
/// nuevo después de `shutdown()` (Assistant abre/cierra voz sin recrear su
/// Notifier).
class GeminiVoiceEngine {
  GeminiVoiceEngine({
    required NativeAudioService audioService,
    required ApiClient api,
    required String logTag,
  })  : _audioService = audioService,
        _api = api,
        _logTag = logTag {
    _usageTracker = GeminiUsageTracker(onRoundReady: _postSaveRound, logTag: logTag);
    _liveSubscription = _liveService.events.listen(_handleLiveEvent);
    _playbackFinishedSubscription = _audioService.onPlaybackFinished.listen((_) {
      modelLevel.value = 0.0;
      if (_modelSpeaking) {
        _modelSpeaking = false;
        _emit(const EngineListening());
      }
    });
  }

  final NativeAudioService _audioService;
  final ApiClient _api;
  final String _logTag;
  final GeminiLiveService _liveService = GeminiLiveService();
  late final GeminiUsageTracker _usageTracker;

  final _eventsController = StreamController<VoiceEngineEvent>.broadcast();
  Stream<VoiceEngineEvent> get events => _eventsController.stream;

  // Nivel de audio (0..1) en vivo — alimenta las animaciones reactivas de la
  // barra de voz: mic real mientras escucha, salida real mientras responde.
  // ValueNotifier en vez de VoiceEngineEvent a propósito: llega ~20 veces por
  // segundo y no debe disparar un rebuild de todo AssistantState/la pantalla.
  final ValueNotifier<double> micLevel = ValueNotifier<double>(0.0);
  final ValueNotifier<double> modelLevel = ValueNotifier<double>(0.0);

  StreamSubscription<GeminiLiveEvent>? _liveSubscription;
  StreamSubscription<void>? _playbackFinishedSubscription;
  StreamSubscription<Uint8List>? _micSubscription;

  Timer? _watchdogTimer;
  Timer? _countdownTimer;

  String? _sessionId;
  String? _timezone;
  bool _active = false;
  bool _disposed = false;

  // Buffers del turno en vuelo — fuente de verdad para el guardado de rondas
  // (la UI mantiene su propio espejo vía los eventos de transcript).
  String _liveUserText = '';
  String _liveModelText = '';
  final List<Map<String, dynamic>> _pendingToolCalls = [];
  bool _discardingModelTurn = false;

  // Metadata de la última skill del turno en vuelo. Sobrevive commits sin
  // texto del modelo (el tool call cae en un turno y la respuesta hablada en
  // el siguiente) y se consume cuando un commit CON texto del modelo lo ancla
  // a su burbuja.
  Map<String, dynamic>? _turnWidgetMetadata;

  // Echo guard: no mandar audio del mic mientras el modelo habla ni durante el
  // hangover posterior al último chunk reproducido.
  bool _modelSpeaking = false;
  DateTime? _lastPlaybackAt;
  Duration get _playbackHangover => defaultTargetPlatform == TargetPlatform.android
      ? const Duration(milliseconds: 1200)
      : const Duration(milliseconds: 700);

  bool get _micSendBlockedByPlayback {
    if (_discardingModelTurn) return false;
    if (_modelSpeaking) return true;
    final last = _lastPlaybackAt;
    return last != null && DateTime.now().difference(last) < _playbackHangover;
  }

  bool get isConnected => _liveService.isConnected;
  String? get sessionId => _sessionId;

  Future<void> connect({
    required String sessionId,
    required String timezone,
    required String systemInstruction,
    required String dynamicContext,
    required List<dynamic> tools,
    required String url,
    required String token,
    Map<String, dynamic>? headersMap,
    required String modelName,
  }) async {
    _sessionId = sessionId;
    _timezone = timezone;
    _active = true;
    _usageTracker.resetSession();
    _pendingToolCalls.clear();
    _liveUserText = '';
    _liveModelText = '';
    _discardingModelTurn = false;
    _modelSpeaking = false;
    _lastPlaybackAt = null;
    _turnWidgetMetadata = null;

    await _liveService.connect(
      url: url,
      token: token,
      systemInstruction: systemInstruction,
      dynamicContext: dynamicContext,
      tools: tools,
      headersMap: headersMap,
      modelName: modelName,
      logTag: _logTag,
    );
    // El mic se abre cuando Gemini confirme el setup (GeminiSetupCompleteEvent)
    // — abrirlo antes desperdicia audio que el servidor aún no acepta.
  }

  /// Interrupción manual (tap del usuario mientras el modelo habla).
  void interrupt() {
    if (!_modelSpeaking) return;
    debugPrint('[$_logTag] Interrupt — stopping playback');

    // Descartar el audio/texto que Gemini siga mandando de este turno, y
    // mantener el mic abierto para que el barge-in del usuario sí llegue.
    _discardingModelTurn = true;
    _modelSpeaking = false;
    modelLevel.value = 0.0;
    _audioService.stopPlayback();

    _commitCurrentTurn(); // conserva la pregunta + lo que el modelo alcanzó a decir
    _pendingToolCalls.clear();
    _emit(const EngineWidgetMetadataCleared());
    _emit(const EngineListening());
  }

  /// Cierra la sesión de voz. Idempotente; el engine queda listo para un nuevo
  /// `connect()`. La ronda pendiente de tokens se emite antes de cerrar para
  /// no perder el último turno.
  Future<void> shutdown() async {
    if (!_active) return;
    _active = false;
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    await _micSubscription?.cancel();
    _micSubscription = null;
    _usageTracker.flushPendingUsageRound();
    await _audioService.stopAudio();
    await _audioService.stopPlayback();
    await _liveService.close();
    _modelSpeaking = false;
    _discardingModelTurn = false;
    micLevel.value = 0.0;
    modelLevel.value = 0.0;
    debugPrint('[$_logTag] Engine shutdown done');
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    shutdown();
    _playbackFinishedSubscription?.cancel();
    _liveSubscription?.cancel();
    _usageTracker.dispose();
    _liveService.dispose();
    micLevel.dispose();
    modelLevel.dispose();
    _eventsController.close();
  }

  // ── Eventos del WebSocket ──────────────────────────────────────────────────

  void _handleLiveEvent(GeminiLiveEvent event) {
    if (!_active) return;
    _touchGeminiActivity();

    switch (event) {
      case GeminiSetupCompleteEvent():
        _emit(const EngineListening());
        // Abrir mic AQUÍ, una vez que Gemini confirmó el setup.
        _audioService.startAudio().then((_) {
          if (!_active) return;
          _startMicStream();
          debugPrint('[$_logTag] 🎙 Mic abierto tras SetupComplete');
        }).catchError((e) {
          debugPrint('[$_logTag] startAudio error tras setup: $e');
          // Sin esto, un permiso denegado dejaba la UI trabada en "Escuchando…"
          // para siempre — el mic nunca abrió pero nadie se enteraba.
          _fail(e is PlatformException && e.code == 'MIC_PERMISSION_DENIED'
              ? 'MIC_PERMISSION_DENIED'
              : 'errUnknown');
        });
        _startCountdown();

      case GeminiUsageMetadataEvent(:final usageMetadata):
        _usageTracker.processUsageMetadata(usageMetadata);

      case GeminiAudioChunkEvent(:final base64PcmAudio):
        if (!_discardingModelTurn) {
          _lastPlaybackAt = DateTime.now(); // arma el hangover del echo guard
          if (!_modelSpeaking) {
            _modelSpeaking = true;
            _emit(const EngineModelSpeaking());
          }
          modelLevel.value = _pcm16Level(base64Decode(base64PcmAudio));
          _audioService.playPcm(base64PcmAudio);
        }

      case GeminiTranscriptionEvent(:final userText, :final modelText):
        // Texto del modelo: se descarta tras un interrupt — el parcial ya se
        // comprometió; texto tardío crearía una segunda burbuja fuera de lugar.
        if (modelText != null && !_discardingModelTurn) {
          _liveModelText += modelText;
          if (!_modelSpeaking) {
            _modelSpeaking = true;
            _emit(const EngineModelSpeaking());
          }
          _emit(EngineModelTranscript(modelText));
        }
        if (userText != null) {
          _liveUserText += userText;
          _emit(EngineUserTranscript(userText));
          _emit(const EngineWidgetMetadataCleared());
          _armWatchdog(); // el usuario habló → esperar respuesta del modelo
        }

      case GeminiTurnCompleteEvent(:final chunksThisTurn):
        _handleTurnComplete(chunksThisTurn);

      case GeminiInterruptedEvent():
        _handleInterrupted();

      case GeminiToolCallEvent(:final functionCalls):
        _handleToolCalls(functionCalls);

      case GeminiErrorEvent(:final message):
        _fail(message);
    }
  }

  void _handleTurnComplete(int chunksThisTurn) {
    _discardingModelTurn = false; // el turno terminó — flujo normal de nuevo
    debugPrint('[$_logTag] ✅ TURN COMPLETE ($chunksThisTurn chunks)');

    final userText = _liveUserText;
    final modelText = _liveModelText;
    _commitCurrentTurn();

    final toolCalls = List<Map<String, dynamic>>.from(_pendingToolCalls);
    _pendingToolCalls.clear();

    // No se guarda aquí: Gemini puede mandar el usageMetadata final de este
    // turno en un mensaje posterior. El tracker congela la ronda y la emite
    // cuando llegue (o al vencer su timer de seguridad).
    _usageTracker.armPendingRoundSnapshot(
      userText: userText,
      modelText: modelText,
      toolCalls: toolCalls,
    );

    _emit(const EngineSkillCleared());
    // Sin audio en el turno no habrá playbackFinished que regrese a listening
    // — hacerlo aquí, si no el mic queda bloqueado por el echo guard.
    if (chunksThisTurn == 0) {
      _modelSpeaking = false;
      modelLevel.value = 0.0;
      _emit(const EngineListening());
    }
  }

  void _handleInterrupted() {
    debugPrint('[$_logTag] ⚡ INTERRUPTED — flushing playback');
    modelLevel.value = 0.0;
    _audioService.stopPlayback();
    // Barge-in puro por voz (sin tap previo): conservar el parcial en orden.
    // Tras un tap el turno ya se comprometió — no recomitear, fragmentaría la
    // nueva pregunta que el usuario está diciendo.
    if (!_discardingModelTurn) _commitCurrentTurn();
    _pendingToolCalls.clear();
    _discardingModelTurn = false;
    _modelSpeaking = false;
    // La ronda NO se guarda aquí — Gemini manda turnComplete después del
    // interrupted y ese es el único punto de guardado (igual que el original).
    _emit(const EngineListening());
  }

  Future<void> _handleToolCalls(List<Map<String, dynamic>> functionCalls) async {
    final futures = functionCalls.map((call) async {
      try {
        final id = (call['id'] ?? '') as String;
        final name = call['name'] as String;
        final args = call['args'] as Map<String, dynamic>? ?? {};

        _emit(EngineSkillStarted(name));
        final executionRes = await _executeToolInSupabase(name, args);

        if (executionRes is Map && executionRes['quotaExceeded'] == true) {
          _fail(executionRes['message'] as String? ??
              'Has alcanzado el límite de tu plan.');
          return null;
        }

        dynamic result = executionRes;
        if (executionRes is Map && executionRes.containsKey('result')) {
          result = executionRes['result'];
          final rawMeta = executionRes['__skillMetadata'];
          if (rawMeta is Map<String, dynamic>) {
            _turnWidgetMetadata = rawMeta;
            _emit(EngineWidgetMetadata(rawMeta));
          }
        }

        _pendingToolCalls.add({'name': name, 'args': args, 'response': result});

        final resMap = <String, dynamic>{
          'name': name,
          'response': {'result': result},
        };
        if (id.isNotEmpty) resMap['id'] = id;
        return resMap;
      } catch (e) {
        debugPrint('[$_logTag] executeTool error: $e');
        return null;
      }
    }).toList();

    final results =
        (await Future.wait(futures)).whereType<Map<String, dynamic>>().toList();
    _liveService.sendToolResponses(results);
    _emit(const EngineSkillCleared());
  }

  // ── Turnos y persistencia ──────────────────────────────────────────────────

  void _commitCurrentTurn() {
    final cleanModelText = _liveModelText
        .replaceAll(RegExp(r'response:[a-zA-Z0-9_]+\{.*?\}(?=\s*|\b)', caseSensitive: false, dotAll: true), '')
        .trim();
    if (_liveUserText.trim().isEmpty && cleanModelText.isEmpty) return;
    final modelText = cleanModelText;
    // El metadata solo se consume cuando hay burbuja del modelo que lo ancle;
    // si este commit es solo del usuario, queda pendiente para el siguiente.
    final metadata = modelText.isNotEmpty ? _turnWidgetMetadata : null;
    if (metadata != null) _turnWidgetMetadata = null;
    _emit(EngineTurnCommitted(
      userText: _liveUserText.trim(),
      modelText: modelText,
      metadata: metadata,
    ));
    _liveUserText = '';
    _liveModelText = '';
  }

  void _postSaveRound(VoiceRoundPayload payload) {
    final sessionId = _sessionId;
    if (sessionId == null || sessionId.isEmpty) {
      debugPrint('[$_logTag] save-round skipped — no sessionId');
      return;
    }
    _api.post('ai/voice/save-round', body: {
      'sessionId': sessionId,
      'userText': payload.userText,
      'modelText': payload.modelText,
      'promptTokens': payload.promptTokens,
      'completionTokens': payload.completionTokens,
      'totalTokens': payload.totalTokens,
      'textPromptTokens': payload.textPromptTokens,
      'audioPromptTokens': payload.audioPromptTokens,
      'textCompletionTokens': payload.textCompletionTokens,
      'audioCompletionTokens': payload.audioCompletionTokens,
      'toolCalls': payload.toolCalls,
    }).then((_) {
      debugPrint('[$_logTag] Round saved in DB (${payload.toolCalls.length} tool calls)');
    }).catchError((e) {
      debugPrint('[$_logTag] saveRound error: $e');
    });
  }

  Future<dynamic> _executeToolInSupabase(String name, Map<String, dynamic> args) async {
    try {
      return await _api.post('ai/voice/execute-tool', body: {
        'sessionId': _sessionId,
        'timezone': _timezone,
        'toolName': name,
        'args': args,
      });
    } catch (e) {
      debugPrint('[$_logTag] executeTool error: $e');
      return {'error': e.toString()};
    }
  }

  // ── Mic, countdown y watchdog ──────────────────────────────────────────────

  bool _hasReceivedMicData = false;
  int _micChunksSent = 0;

  void _startMicStream() {
    _hasReceivedMicData = false;
    _micChunksSent = 0;
    _micSubscription?.cancel();
    _micSubscription = _audioService.onAudioChunk.listen((data) {
      if (!_active) return;
      if (!_hasReceivedMicData) {
        _hasReceivedMicData = true;
        debugPrint('[$_logTag] 🎙 Primer chunk de mic (${data.length} bytes)');
      }
      // Nivel real del mic — independiente del echo guard: el usuario sigue
      // "escuchándose" visualmente aunque ese chunk no se reenvíe a Gemini.
      micLevel.value = _pcm16Level(data);
      if (_liveService.isConnected && !_micSendBlockedByPlayback) {
        _micChunksSent++;
        if (_micChunksSent % 50 == 0) {
          debugPrint('[$_logTag] 📤 Mic streaming ($_micChunksSent chunks)');
        }
        _liveService.sendAudioChunk(data);
      }
    }, onError: (err) {
      debugPrint('[$_logTag] Mic stream error: $err');
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    var secondsLeft = 600;
    _emit(EngineCountdownTick(secondsLeft));
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_active) {
        timer.cancel();
        return;
      }
      secondsLeft--;
      if (secondsLeft <= 0) {
        timer.cancel();
        _countdownTimer = null;
        _emit(const EngineTimeExpired());
      } else {
        _emit(EngineCountdownTick(secondsLeft));
      }
    });
  }

  void _touchGeminiActivity() {
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
  }

  void _armWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer(const Duration(seconds: 12), () {
      if (!_active) return;
      debugPrint('[$_logTag] Silence watchdog fired — no response in 12s');
      _emit(const EngineWatchdogTimeout());
    });
  }

  // RMS de un buffer PCM16 mono LE, mapeado a 0..1 en escala de dB (no
  // lineal): la voz hablada tiene picos altos pero promedio bajo, así que un
  // gain lineal solo se nota "gritando". En dB, ruido de piso/silencio cae
  // bajo _dbFloor y voz conversacional normal ya ocupa la mayor parte del
  // rango hasta _dbCeil (gritar satura el resto).
  static const _dbFloor = -45.0;
  static const _dbCeil = -8.0;

  double _pcm16Level(Uint8List bytes) {
    if (bytes.length < 2) return 0.0;
    final data = ByteData.sublistView(bytes);
    final sampleCount = bytes.length ~/ 2;
    double sumSquares = 0;
    for (var i = 0; i < sampleCount; i++) {
      final sample = data.getInt16(i * 2, Endian.little) / 32768.0;
      sumSquares += sample * sample;
    }
    final rms = math.sqrt(sumSquares / sampleCount);
    if (rms <= 0) return 0.0;
    final db = 20 * math.log(rms) / math.ln10;
    final normalized = (db - _dbFloor) / (_dbCeil - _dbFloor);
    return normalized.clamp(0.0, 1.0);
  }

  void _fail(String message) {
    debugPrint('[$_logTag] Voice failure: $message');
    shutdown();
    _emit(EngineFailure(message));
  }

  void _emit(VoiceEngineEvent event) {
    if (!_disposed && !_eventsController.isClosed) {
      _eventsController.add(event);
    }
  }
}
