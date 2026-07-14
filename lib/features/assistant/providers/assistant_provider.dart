import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/env.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/ai_backend_provider.dart';
import '../../../core/utils/api_error_mapper.dart';
import '../../../core/utils/device_timezone.dart';
import '../data/assistant_repository.dart';
import '../../chat/data/chat_context.dart';

export 'package:amconnect/features/assistant/data/assistant_repository.dart' show AssistantMessage;
export 'package:amconnect/features/chat/data/chat_context.dart' show AiChatContext;

// ── Tipos públicos ────────────────────────────────────────────────────────────

/// Datos para retomar una sesión ya iniciada fuera del Assistant (ej. la
/// sesión de confirmación de una ingesta de póliza) en vez de arrancar una
/// conversación nueva — ver AssistantNotifier.resumeIngestSession.
class AssistantResumeArgs {
  final String sessionId;
  final List<AssistantMessage> messages;
  const AssistantResumeArgs({required this.sessionId, required this.messages});
}

enum AssistantMode { text, voice }

enum VoiceStatus { connecting, listening, modelSpeaking, error }

@immutable
class AssistantState {
  final List<AssistantMessage> messages;
  final String? sessionId;
  final bool isLoading;
  final String? error;
  final AiChatContext? pendingContext;
  final AiChatContext? activeContext;

  final AssistantMode mode;
  final VoiceStatus voiceStatus;
  final String liveUserText;
  final String liveModelText;
  final String? activeSkill;
  final Map<String, dynamic>? activeWidgetMetadata;
  final int voiceTimeLeftSeconds;

  const AssistantState({
    this.messages = const [],
    this.sessionId,
    this.isLoading = false,
    this.error,
    this.pendingContext,
    this.activeContext,
    this.mode = AssistantMode.text,
    this.voiceStatus = VoiceStatus.connecting,
    this.liveUserText = '',
    this.liveModelText = '',
    this.activeSkill,
    this.activeWidgetMetadata,
    this.voiceTimeLeftSeconds = 600,
  });

  AssistantState copyWith({
    List<AssistantMessage>? messages,
    String? sessionId,
    bool? isLoading,
    String? error,
    bool clearError = false,
    AiChatContext? pendingContext,
    bool clearContext = false,
    AssistantMode? mode,
    VoiceStatus? voiceStatus,
    String? liveUserText,
    String? liveModelText,
    String? activeSkill,
    bool clearActiveSkill = false,
    Map<String, dynamic>? activeWidgetMetadata,
    bool clearActiveWidgetMetadata = false,
    int? voiceTimeLeftSeconds,
  }) {
    return AssistantState(
      messages: messages ?? this.messages,
      sessionId: sessionId ?? this.sessionId,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      pendingContext: clearContext ? null : (pendingContext ?? this.pendingContext),
      activeContext: activeContext,
      mode: mode ?? this.mode,
      voiceStatus: voiceStatus ?? this.voiceStatus,
      liveUserText: liveUserText ?? this.liveUserText,
      liveModelText: liveModelText ?? this.liveModelText,
      activeSkill: clearActiveSkill ? null : (activeSkill ?? this.activeSkill),
      activeWidgetMetadata:
          clearActiveWidgetMetadata ? null : (activeWidgetMetadata ?? this.activeWidgetMetadata),
      voiceTimeLeftSeconds: voiceTimeLeftSeconds ?? this.voiceTimeLeftSeconds,
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final assistantProvider = NotifierProvider<AssistantNotifier, AssistantState>(AssistantNotifier.new);

// ── Notifier ──────────────────────────────────────────────────────────────────
//
// Fusiona el chat de texto (POST /ai/chat) y la voz Gemini Live full-duplex
// (WebSocket directo + audio nativo) en un solo estado — un mismo
// `messages`/`sessionId` compartido por ambos modos, para que la conversación
// se vea y se persista como una sola, sin importar si cada turno vino de texto
// o de voz.
class AssistantNotifier extends Notifier<AssistantState> {
  late AssistantRepository _repo;

  static const _audioControl = MethodChannel('com.amconnect/audio');
  static const _audioInput = EventChannel('com.amconnect/audio_input');

  WebSocket? _socket;
  StreamSubscription<dynamic>? _wsSub;
  StreamSubscription<dynamic>? _audioSub;
  bool _disposed = false;

  // Verdadero solo tras un QUOTA_EXCEEDED del backend — bloquea el
  // auto-reconnect. Se limpia en endVoice() para permitir un nuevo intento en
  // la siguiente llamada de voz (una sesión de app puede tener varias).
  bool _terminated = false;

  // Verdadero durante endVoice() — evita que el cierre del socket que
  // provoca dispare un reconnect automático (ver _onSocketClosed).
  bool _endingVoluntarily = false;

  // Full-duplex: el mic transmite continuo y nunca se gatea por estado. El AEC
  // del OS mantiene la voz del modelo fuera del mic, así que es seguro seguir
  // enviando mientras el modelo habla — eso es lo que permite que el VAD de
  // Gemini detecte un barge-in y dispare `interrupted`. `modelSpeaking` es
  // puramente un estado visual, nunca un gate del micrófono.
  int _audioChunksReceived = 0;

  // Echo guard: mientras el modelo habla (y un hangover corto después), no se
  // reenvía audio del mic — su propia voz se filtra al mic y dispara el VAD de
  // Gemini, haciendo que se auto-interrumpa. El mic sigue capturando; solo no
  // se envía el eco. El barge-in por voz queda inhabilitado en esa ventana; el
  // usuario interrumpe tocando la pantalla (interruptVoice()).
  DateTime? _lastPlaybackAt;
  static const _playbackHangover = Duration(milliseconds: 700);

  // Verdadero desde que el usuario interrumpe hasta que el turno del modelo
  // realmente termina — descarta cualquier audio/texto que Gemini siga
  // mandando de ese turno.
  bool _discardingModelTurn = false;

  bool get _micSendBlockedByPlayback {
    if (_discardingModelTurn) return false;
    if (state.voiceStatus == VoiceStatus.modelSpeaking) return true;
    final last = _lastPlaybackAt;
    return last != null && DateTime.now().difference(last) < _playbackHangover;
  }

  // Watchdog de silencio: si el mic lleva enviando audio sin ninguna
  // respuesta de Gemini por más de _stuckThreshold, la sesión Live
  // probablemente quedó colgada. Reconecta.
  static const _stuckThreshold = Duration(seconds: 12);
  DateTime? _lastGeminiActivity;
  Timer? _watchdogTimer;
  Timer? _countdownTimer;
  String? _timezone;

  int _promptTokens = 0;
  int _completionTokens = 0;
  int _totalTokens = 0;

  // Tool calls ejecutados durante el turno en curso, mandados a /save-round
  // en turnComplete para que el historial refleje lo mismo que persiste el
  // loop de texto (la function call + su respuesta).
  final List<Map<String, dynamic>> _pendingToolCalls = [];

  bool _hasReceivedMicData = false;

  @override
  AssistantState build() {
    _repo = AssistantRepository(ref.read(apiClientProvider));
    _audioControl.setMethodCallHandler(_handleAudioControlCall);
    ref.onDispose(_cleanup);
    return const AssistantState();
  }

  // ── Texto ─────────────────────────────────────────────────────────────────

  Future<void> sendText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final isFirstMessage = state.sessionId == null;
    final context = isFirstMessage ? state.pendingContext : null;

    state = state.copyWith(
      messages: [...state.messages, AssistantMessage(role: 'user', text: trimmed)],
      isLoading: true,
      clearError: true,
      clearContext: isFirstMessage,
    );

    try {
      final result = await _repo.sendMessage(trimmed, sessionId: state.sessionId, context: context);
      ref.read(aiBackendProvider.notifier).set(result.aiBackend);
      state = state.copyWith(
        messages: [
          ...state.messages,
          AssistantMessage(role: 'ai', text: result.text, metadata: result.metadata),
        ],
        sessionId: result.sessionId,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: mapApiError(e));
    }
  }

  Future<void> reset() async {
    final sid = state.sessionId;
    await endVoice();
    if (sid != null) {
      try {
        await _repo.cancelSession(sid);
      } catch (_) {}
    }
    state = const AssistantState();
  }

  Future<void> resetWithContext(AiChatContext ctx) async {
    await reset();
    state = AssistantState(pendingContext: ctx, activeContext: ctx);
  }

  /// Retoma una sesión ya iniciada fuera del Assistant (ej. la sesión de
  /// confirmación de una ingesta de póliza) en vez de arrancar una nueva —
  /// como sessionId ya no es null, sendText() la trata como continuación.
  Future<void> resumeIngestSession(String sessionId, List<AssistantMessage> messages) async {
    await reset();
    state = AssistantState(sessionId: sessionId, messages: messages);
  }

  // ── Voz (Gemini Live, full-duplex) ──────────────────────────────────────────

  Future<void> startVoice(String timezone) async {
    if (_socket != null) return;
    _terminated = false;
    state = state.copyWith(mode: AssistantMode.voice, voiceStatus: VoiceStatus.connecting, clearError: true);
    await _connectInternal(timezone);
  }

  Future<void> endVoice() async {
    if (state.mode != AssistantMode.voice && _socket == null) return;
    _endingVoluntarily = true;
    _terminated = false;
    await _partialCleanup();
    if (!_disposed) {
      state = state.copyWith(
        mode: AssistantMode.text,
        liveUserText: '',
        liveModelText: '',
        clearActiveWidgetMetadata: true,
        clearActiveSkill: true,
        clearError: true,
      );
    }
    _endingVoluntarily = false;
  }

  Future<void> interruptVoice() async {
    if (state.voiceStatus != VoiceStatus.modelSpeaking) return;
    _discardingModelTurn = true;
    try {
      await _audioControl.invokeMethod<void>('stopPlayback');
    } catch (e) {
      debugPrint('[Assistant/Voice] stopPlayback error: $e');
    }

    final userText = state.liveUserText;
    final modelText = state.liveModelText;
    final toolCalls = List<Map<String, dynamic>>.from(_pendingToolCalls);

    _commitCurrentTurn();
    _pendingToolCalls.clear();
    state = state.copyWith(voiceStatus: VoiceStatus.listening, clearActiveWidgetMetadata: true);

    if (userText.isNotEmpty || modelText.isNotEmpty || toolCalls.isNotEmpty) {
      _saveRoundInSupabase(userText, modelText, toolCalls);
    }
  }

  Future<void> _handleAudioControlCall(MethodCall call) async {
    if (_disposed) return;
    if (call.method == 'playbackFinished') {
      if (state.voiceStatus == VoiceStatus.modelSpeaking) {
        state = state.copyWith(voiceStatus: VoiceStatus.listening);
      }
    }
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final response = await http.post(
      Uri.parse('${Env.apiBaseUrl}$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        if (_timezone != null) 'x-timezone': _timezone!,
        'x-timezone-offset': DeviceTimezone.offset,
      },
      body: jsonEncode(body),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('HTTP error ${response.statusCode}: ${response.body}');
    }
  }

  Future<dynamic> _executeToolInSupabase(String name, Map<String, dynamic> args) async {
    try {
      final res = await _post('/ai/voice/execute-tool', {
        'sessionId': state.sessionId,
        'timezone': _timezone,
        'toolName': name,
        'args': args,
      });
      return res;
    } catch (e) {
      debugPrint('[Assistant/Voice] executeTool error: $e');
      return {'error': e.toString()};
    }
  }

  Future<void> _saveRoundInSupabase(
    String userText,
    String modelText,
    List<Map<String, dynamic>> toolCalls,
  ) async {
    try {
      await _post('/ai/voice/save-round', {
        'sessionId': state.sessionId,
        'userText': userText,
        'modelText': modelText,
        'promptTokens': _promptTokens,
        'completionTokens': _completionTokens,
        'totalTokens': _totalTokens,
        'toolCalls': toolCalls,
      });
    } catch (e) {
      debugPrint('[Assistant/Voice] saveRound error: $e');
    }
  }

  // sessionId de texto existente (si lo hay) viaja como resumeSessionId — así
  // el backend reutiliza la misma ai_session en vez de crear una nueva y el
  // modelo conserva el contexto de lo hablado/escrito antes.
  Future<(Map<String, dynamic>, Map<String, dynamic>)> _fetchInitAndToken(
      String timezone, String? resumeSessionId) async {
    final ctx = state.activeContext ?? state.pendingContext;
    final initData = await _post('/ai/voice/init', {
      'timezone': timezone,
      'sessionId': resumeSessionId,
      if (ctx != null) 'context': ctx.toJson(),
    }) as Map<String, dynamic>;
    final tokenData = await _post('/ai/voice/token', {
      'systemInstruction': initData['systemInstruction'],
      'tools': initData['tools'] ?? [],
    }) as Map<String, dynamic>;
    return (initData, tokenData);
  }

  Future<void> _connectInternal(String timezone) async {
    _timezone = timezone;
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) {
      _setVoiceError('SESSION_EXPIRED');
      return;
    }

    try {
      final (initData, tokenData) = await _fetchInitAndToken(timezone, state.sessionId);
      if (_disposed) return;

      final sessionId = initData['sessionId'] as String;
      final systemInstruction = initData['systemInstruction'] as String;
      final tools = initData['tools'] as List<dynamic>? ?? [];

      state = state.copyWith(voiceStatus: VoiceStatus.connecting, sessionId: sessionId);
      ref.read(aiBackendProvider.notifier).set(tokenData['aiBackend'] as String?);

      final String wsUrl = tokenData['url'] as String? ?? '';
      final Map<String, dynamic>? customHeaders = tokenData['headers'] as Map<String, dynamic>?;
      final String targetModel = tokenData['model'] as String? ?? '';

      if (wsUrl.isEmpty || targetModel.isEmpty) {
        throw Exception('El servidor no devolvió URL/modelo para el chat de voz.');
      }

      final headersMap = customHeaders != null
          ? Map<String, String>.from(customHeaders.map((key, value) => MapEntry(key, value.toString())))
          : <String, String>{};

      _socket = await WebSocket.connect(wsUrl, headers: headersMap.isNotEmpty ? headersMap : null);
      if (_disposed) {
        try {
          _socket?.close();
        } catch (_) {}
        _socket = null;
        return;
      }

      _wsSub = _socket!.listen(
        _onMessage,
        onDone: _onSocketClosed,
        onError: (Object e) {
          debugPrint('[Assistant/Voice] WebSocket error: $e');
          _setVoiceError('CONNECTION_FAILED');
        },
        cancelOnError: false,
      );

      final camelTools = tools.map((t) {
        if (t is Map) {
          final funcDecls = t['function_declarations'] ?? t['functionDeclarations'];
          if (funcDecls != null) {
            return {'functionDeclarations': funcDecls};
          }
        }
        return t;
      }).toList();

      final setupMessage = {
        'setup': {
          'model': targetModel,
          'generationConfig': {
            'responseModalities': ['AUDIO'],
          },
          'realtimeInputConfig': {
            'automaticActivityDetection': {
              'startOfSpeechSensitivity': 'START_SENSITIVITY_HIGH',
              'endOfSpeechSensitivity': 'END_SENSITIVITY_LOW',
              'prefixPaddingMs': 200,
              'silenceDurationMs': 500,
            },
          },
          'inputAudioTranscription': {},
          'outputAudioTranscription': {},
          'systemInstruction': {
            'parts': [
              {'text': systemInstruction}
            ],
          },
          'tools': camelTools,
        }
      };

      _socket!.add(jsonEncode(setupMessage));

      await _audioControl.invokeMethod<void>('startAudio');
      if (_disposed) {
        try {
          await _audioControl.invokeMethod<void>('stopAudio');
        } catch (_) {}
        return;
      }
    } catch (e) {
      if (_disposed) return;
      debugPrint('[Assistant/Voice] Connection failed: $e');
      // _partialCleanup (no _cleanup): una falla de conexión debe permitir
      // reintentar — a diferencia del provider autoDispose original, este
      // provider vive toda la sesión de la app y _cleanup marcaría _disposed
      // permanentemente, bloqueando cualquier intento futuro de voz.
      await _partialCleanup();
      _setVoiceError('CONNECTION_FAILED');
    }
  }

  void _setVoiceError(String message) {
    if (!_disposed) {
      state = state.copyWith(voiceStatus: VoiceStatus.error, error: message);
    }
  }

  // Vuelca el turno en curso (pregunta del usuario Y lo que el modelo llevaba
  // dicho) al historial ÚNICO (state.messages), en orden — la misma lista que
  // usa el chat de texto. Así la fusión es automática: no hay paso de
  // sincronización entre "modo texto" y "modo voz".
  void _commitCurrentTurn() {
    final user = state.liveUserText;
    final model = state.liveModelText;
    if (user.isEmpty && model.isEmpty) return;
    final newMessages = [...state.messages];
    if (user.isNotEmpty) newMessages.add(AssistantMessage(role: 'user', text: user));
    if (model.isNotEmpty) {
      newMessages.add(AssistantMessage(role: 'ai', text: model, metadata: state.activeWidgetMetadata));
    }
    state = state.copyWith(
      messages: newMessages,
      liveUserText: '',
      liveModelText: '',
      clearActiveWidgetMetadata: true,
    );
  }

  // ── Mensajes entrantes de Gemini Live API ─────────────────────────────────

  Future<void> _onMessage(dynamic raw) async {
    if (_disposed) return;
    Map<String, dynamic> msg;
    try {
      String text;
      if (raw is String) {
        text = raw;
      } else if (raw is List<int>) {
        text = utf8.decode(raw);
      } else {
        return;
      }
      msg = jsonDecode(text) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[Assistant/Voice] Parse error: $e');
      return;
    }

    final setupComplete = msg['setupComplete'] ?? msg['setup_complete'];
    if (setupComplete != null) {
      debugPrint('[Assistant/Voice] ▶ Gemini ready — entrando a LISTENING, iniciando mic');
      state = state.copyWith(voiceStatus: VoiceStatus.listening);
      _touchGeminiActivity();
      _startMicStream();
      _startCountdown();
      return;
    }

    final usageMetadata = msg['usageMetadata'] ?? msg['usage_metadata'];
    if (usageMetadata is Map) {
      _promptTokens = (usageMetadata['promptTokenCount'] ?? usageMetadata['prompt_token_count'] ?? 0) as int;
      _completionTokens = (usageMetadata['responseTokenCount'] ??
          usageMetadata['response_token_count'] ??
          usageMetadata['candidatesTokenCount'] ??
          usageMetadata['candidates_token_count'] ??
          0) as int;
      _totalTokens = (usageMetadata['totalTokenCount'] ?? usageMetadata['total_token_count'] ?? 0) as int;
    }

    final serverContent = msg['serverContent'] ?? msg['server_content'];
    if (serverContent is Map) {
      _touchGeminiActivity();

      if (serverContent['interrupted'] == true) {
        _audioChunksReceived = 0;
        try {
          await _audioControl.invokeMethod<void>('stopPlayback');
        } catch (_) {}

        final userText = state.liveUserText;
        final modelText = state.liveModelText;
        final toolCalls = List<Map<String, dynamic>>.from(_pendingToolCalls);

        if (!_discardingModelTurn) _commitCurrentTurn();
        _pendingToolCalls.clear();
        _discardingModelTurn = false;
        state = state.copyWith(voiceStatus: VoiceStatus.listening);

        if (userText.isNotEmpty || modelText.isNotEmpty || toolCalls.isNotEmpty) {
          _saveRoundInSupabase(userText, modelText, toolCalls);
        }
      }

      final modelTurn = serverContent['modelTurn'] ?? serverContent['model_turn'];
      if (modelTurn is Map && modelTurn['parts'] is List && !_discardingModelTurn) {
        final parts = modelTurn['parts'] as List;
        for (final part in parts) {
          if (part is Map) {
            final inlineData = part['inlineData'] ?? part['inline_data'];
            if (inlineData is Map && inlineData['data'] is String) {
              final base64Audio = inlineData['data'] as String;
              if (base64Audio.isNotEmpty) {
                _audioChunksReceived++;
                _lastPlaybackAt = DateTime.now();
                try {
                  await _audioControl.invokeMethod<void>('playPcm', {'data': base64Audio});
                } catch (e) {
                  debugPrint('[Assistant/Voice] playPcm error: $e');
                }
              }
            }
          }
        }
        if (state.voiceStatus != VoiceStatus.modelSpeaking) {
          state = state.copyWith(voiceStatus: VoiceStatus.modelSpeaking);
        }
      }

      final outputTrans = serverContent['outputTranscription'] ?? serverContent['output_transcription'];
      if (outputTrans is Map && outputTrans['text'] is String && !_discardingModelTurn) {
        var text = outputTrans['text'] as String;
        text = text.replaceAll(RegExp(r'<ctrl\d+>'), '');
        state = state.copyWith(
          voiceStatus: VoiceStatus.modelSpeaking,
          liveModelText: state.liveModelText + text,
        );
      }

      final inputTrans = serverContent['inputTranscription'] ?? serverContent['input_transcription'];
      if (inputTrans is Map && inputTrans['text'] is String) {
        var text = inputTrans['text'] as String;
        text = text.replaceAll(RegExp(r'<ctrl\d+>'), '');
        state = state.copyWith(
          liveUserText: state.liveUserText + text,
          clearActiveWidgetMetadata: true,
        );
        _armWatchdog();
      }

      if (serverContent['turnComplete'] == true || serverContent['turn_complete'] == true) {
        final chunksThisTurn = _audioChunksReceived;
        _audioChunksReceived = 0;
        _discardingModelTurn = false;

        final userText = state.liveUserText;
        final modelText = state.liveModelText;

        _commitCurrentTurn();

        final toolCalls = List<Map<String, dynamic>>.from(_pendingToolCalls);
        _pendingToolCalls.clear();
        _saveRoundInSupabase(userText, modelText, toolCalls);

        if (chunksThisTurn == 0) {
          state = state.copyWith(voiceStatus: VoiceStatus.listening, clearActiveSkill: true);
        } else {
          state = state.copyWith(clearActiveSkill: true);
        }

        _promptTokens = 0;
        _completionTokens = 0;
        _totalTokens = 0;
      }
    }

    final toolCall = msg['toolCall'] ?? msg['tool_call'];
    if (toolCall is Map) {
      final functionCalls = toolCall['functionCalls'] ?? toolCall['function_calls'];
      if (functionCalls is List && functionCalls.isNotEmpty) {
        _touchGeminiActivity();

        final futures = functionCalls.map((call) async {
          if (call is Map) {
            try {
              final id = (call['id'] ?? '') as String;
              final name = call['name'] as String;
              final args = call['args'] as Map<String, dynamic>? ?? {};

              state = state.copyWith(activeSkill: name);
              final executionRes = await _executeToolInSupabase(name, args);

              if (executionRes is Map && executionRes['quotaExceeded'] == true) {
                await _handleQuotaExceeded(executionRes['message'] as String?);
                return null;
              }

              dynamic result = executionRes;
              Map<String, dynamic>? metadata;

              if (executionRes is Map && executionRes.containsKey('result')) {
                result = executionRes['result'];
                final rawMeta = executionRes['__skillMetadata'];
                if (rawMeta is Map<String, dynamic>) {
                  metadata = rawMeta;
                }
              }

              if (metadata != null) {
                state = state.copyWith(activeWidgetMetadata: metadata);
              }

              _pendingToolCalls.add({'name': name, 'args': args, 'response': result});

              final resMap = {
                'name': name,
                'response': {'result': result},
              };
              if (id.isNotEmpty) {
                resMap['id'] = id;
              }
              return resMap;
            } catch (e, stack) {
              debugPrint('[Assistant/Voice] Error executing tool call: $e\n$stack');
              return null;
            }
          }
          return null;
        }).toList();

        final results = (await Future.wait(futures)).whereType<Map<String, dynamic>>().toList();

        final toolResponse = {
          'toolResponse': {
            'functionResponses': results,
          }
        };
        _socket?.add(jsonEncode(toolResponse));

        state = state.copyWith(clearActiveSkill: true);
      }
    }
  }

  void _onSocketClosed() {
    if (_disposed || _terminated || _endingVoluntarily || state.mode != AssistantMode.voice) return;
    debugPrint('[Assistant/Voice] ♻ Server closed socket — reconectando');
    _reconnect();
  }

  // ── Micrófono (via native EventChannel) ───────────────────────────────────

  void _startMicStream() {
    _hasReceivedMicData = false;
    _audioSub = _audioInput.receiveBroadcastStream().listen(
      (dynamic data) {
        if (_disposed) return;
        if (data is! Uint8List) return;
        if (!_hasReceivedMicData) {
          _hasReceivedMicData = true;
          debugPrint('[Assistant/Voice] 🎙 Primer chunk de mic (${data.length} bytes)');
        }
        if (_socket?.readyState == WebSocket.open && !_micSendBlockedByPlayback) {
          final pcmChunkMessage = {
            'realtimeInput': {
              'audio': {
                'mimeType': 'audio/pcm;rate=16000',
                'data': base64Encode(data),
              }
            }
          };
          _socket!.add(jsonEncode(pcmChunkMessage));
        }
      },
      onError: (Object e) {
        debugPrint('[Assistant/Voice] Mic input error: $e');
      },
    );
  }

  // ── Watchdog de sesión Gemini ─────────────────────────────────────────────

  void _touchGeminiActivity() {
    _lastGeminiActivity = DateTime.now();
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
  }

  void _armWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer(_stuckThreshold, () {
      if (_disposed) return;
      final since = DateTime.now().difference(_lastGeminiActivity ?? DateTime.now());
      debugPrint('[Assistant/Voice] ⚠ Watchdog: sin actividad ${since.inSeconds}s — reconectando');
      _reconnect();
    });
  }

  Future<void> _reconnect() async {
    final tz = _timezone ?? '';
    await _partialCleanup();
    if (_disposed) return;
    state = state.copyWith(voiceStatus: VoiceStatus.connecting, liveUserText: '', liveModelText: '');
    await _connectInternal(tz);
  }

  // Cierra socket/audio pero NO marca _disposed (permite reconectar).
  Future<void> _partialCleanup() async {
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _audioChunksReceived = 0;
    _discardingModelTurn = false;
    await _audioSub?.cancel();
    _audioSub = null;
    await _wsSub?.cancel();
    _wsSub = null;
    try {
      await _audioControl.invokeMethod<void>('stopAudio');
    } catch (_) {}
    try {
      await _socket?.close();
    } catch (_) {}
    _socket = null;
  }

  // Límite de plan alcanzado (señalado por el backend en execute-tool). Cierra
  // audio/socket sin reconectar y deja el error visible en la barra de voz
  // hasta que el usuario la cierre manualmente.
  Future<void> _handleQuotaExceeded(String? message) async {
    if (_terminated || _disposed) return;
    _terminated = true;
    await _partialCleanup();
    _setVoiceError(message ?? 'QUOTA_EXCEEDED');
  }

  // ── Límite de duración + limpieza ─────────────────────────────────────────

  void _startCountdown() {
    if (_countdownTimer != null) return;
    state = state.copyWith(voiceTimeLeftSeconds: 600);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }
      if (state.voiceTimeLeftSeconds <= 1) {
        timer.cancel();
        _countdownTimer = null;
        endVoice();
      } else {
        state = state.copyWith(voiceTimeLeftSeconds: state.voiceTimeLeftSeconds - 1);
      }
    });
  }

  Future<void> _cleanup() async {
    _disposed = true;
    _audioControl.setMethodCallHandler(null);
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    await _audioSub?.cancel();
    _audioSub = null;
    await _wsSub?.cancel();
    _wsSub = null;
    try {
      await _audioControl.invokeMethod<void>('stopAudio');
    } catch (_) {}
    try {
      await _socket?.close();
    } catch (_) {}
    _socket = null;
  }
}
