import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/features.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/providers/ai_backend_provider.dart';
import '../../../core/utils/api_error_mapper.dart';
import '../../../core/services/gemini_voice_engine.dart';
import '../../../core/services/native_audio_service.dart';
import '../../../core/services/speech_dictation_service.dart';
import '../data/assistant_repository.dart';
import '../models/assistant_state.dart';

export '../models/assistant_state.dart';

const String _kLogTag = 'Assistant/Voice';

// ── Provider ──────────────────────────────────────────────────────────────────

final assistantProvider =
    NotifierProvider<AssistantNotifier, AssistantState>(AssistantNotifier.new);

/// Repositorio del asistente; se sobreescribe en pruebas.
final assistantRepositoryProvider = Provider<AssistantRepository>(
  (ref) => AssistantRepository(ref.read(apiClientProvider)),
);

// ── Notifier ──────────────────────────────────────────────────────────────────

/// El chat de texto vive aquí; la sesión de voz se delega a [GeminiVoiceEngine]
/// (la misma orquestación que usa VoiceChatNotifier) y este Notifier solo mapea
/// sus eventos a [AssistantState].
class AssistantNotifier extends Notifier<AssistantState> {
  late AssistantRepository _repo;
  late GeminiVoiceEngine _engine;
  late SpeechDictationService _dictation;
  StreamSubscription<VoiceEngineEvent>? _engineSubscription;
  StreamSubscription<DictationEvent>? _dictationSubscription;

  /// Turno de texto en curso por SSE (null si no hay). Cancelarlo cierra la
  /// conexión.
  StreamSubscription<AssistantStreamEvent>? _turnSubscription;

  /// Se incrementa por turno; los eventos de un turno viejo se ignoran.
  int _turnId = 0;

  /// Completa cuando el turno SSE termina o se cancela (sendText lo espera).
  Completer<void>? _turnDone;

  @override
  AssistantState build() {
    _repo = ref.read(assistantRepositoryProvider);
    _engine = GeminiVoiceEngine(
      audioService: ref.read(nativeAudioServiceProvider),
      api: ref.read(apiClientProvider),
      logTag: _kLogTag,
    );
    _dictation = ref.read(speechDictationServiceProvider);
    _engineSubscription = _engine.events.listen(_onEngineEvent);
    _dictationSubscription = _dictation.events.listen(_onDictationEvent);
    ref.onDispose(() {
      _turnSubscription?.cancel();
      _engineSubscription?.cancel();
      _dictationSubscription?.cancel();
      // El servicio de dictado lo dispone su propio provider; aquí solo hay
      // que soltar el micrófono si quedó una sesión abierta.
      _dictation.cancel();
      _engine.dispose();
    });
    return const AssistantState();
  }

  // ── Reset & Navigation API ───────────────────────────────────────────────

  void reset() {
    cancelTurn();
    stopVoice();
    _dictation.cancel();
    state = const AssistantState();
  }

  // [suggestionText] siembra una burbuja "ai" sintética como si el asistente
  // ya hubiera invitado a preguntar sobre este contexto — nunca se manda al
  // backend (sendMessage no envía el historial local), es puramente visual.
  void resetWithContext(AiChatContext context, {String? suggestionText}) {
    cancelTurn();
    stopVoice();
    state = AssistantState(
      pendingContext: context,
      activeContext: context,
      messages: suggestionText != null
          ? [AssistantMessage(role: 'ai', text: suggestionText)]
          : const [],
    );
  }

  void setPendingContext(AiChatContext context) {
    state = state.copyWith(pendingContext: context, activeContext: context);
  }

  void resumeIngestSession(String sessionId, List<AssistantMessage> messages) {
    state = state.copyWith(
      sessionId: sessionId,
      messages: messages,
      isLoading: false,
      clearError: true,
    );
  }

  void switchMode(AssistantMode newMode) {
    if (state.mode == newMode) return;
    if (newMode == AssistantMode.text && state.mode == AssistantMode.voice) {
      stopVoice();
    }
    state = state.copyWith(mode: newMode);
  }

  void interruptVoice() => _engine.interrupt();

  // ── Texto ─────────────────────────────────────────────────────────────────

  Future<void> sendText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final isFirstMessage = state.sessionId == null;
    final context = isFirstMessage ? (state.activeContext ?? state.pendingContext) : null;

    state = state.copyWith(
      messages: [...state.messages, AssistantMessage(role: 'user', text: trimmed)],
      isLoading: true,
      clearError: true,
      clearContext: isFirstMessage,
    );

    if (kAssistantStreamingEnabled) {
      await _sendTextStreaming(trimmed, context);
    } else {
      await _sendTextJson(trimmed, context);
    }
  }

  /// Camino JSON (`POST /ai/chat`): flag apagado o fallback del stream.
  Future<void> _sendTextJson(String text, AiChatContext? context) async {
    final turn = ++_turnId;
    try {
      final result = await _repo.sendMessage(text, sessionId: state.sessionId, context: context);
      if (turn != _turnId) return;
      _commitResult(result);
    } catch (e) {
      if (turn != _turnId) return;
      state = state.copyWith(isLoading: false, error: mapApiError(e));
    }
  }

  void _commitResult(AssistantChatResult result) {
    ref.read(aiBackendProvider.notifier).set(result.aiBackend);
    state = state.copyWith(
      messages: [
        ...state.messages,
        AssistantMessage(role: 'ai', text: result.text, metadata: result.metadata),
      ],
      sessionId: result.sessionId,
      isLoading: false,
      streamingText: '',
      clearToolLabel: true,
    );
  }

  /// Camino SSE (`POST /ai/chat/stream`). Termina cuando el stream cierra.
  ///
  /// Fallback al JSON SOLO si falla la conexión y todavía no llegó ningún
  /// evento: ahí el backend no empezó el turno. Si el stream se cae a la
  /// mitad se muestra el error de conexión y NO se reenvía (el turno puede
  /// seguir corriendo en el servidor y se duplicarían efectos como crear
  /// recordatorios). Los errores de negocio (402/404/409/422/429 o el evento
  /// `error`) se muestran igual que en el JSON.
  Future<void> _sendTextStreaming(String text, AiChatContext? context) async {
    final turn = ++_turnId;
    final completer = _turnDone = Completer<void>();
    var gotEvent = false;
    var finished = false;

    void finish() {
      finished = true;
      _turnSubscription = null;
      if (!completer.isCompleted) completer.complete();
    }

    void fail(Object e) {
      state = state.copyWith(
        isLoading: false,
        streamingText: '',
        clearToolLabel: true,
        error: mapApiError(e),
      );
      finish();
    }

    _turnSubscription = _repo
        .sendMessageStream(text, sessionId: state.sessionId, context: context)
        .listen(
      (event) {
        if (turn != _turnId) return;
        gotEvent = true;
        switch (event) {
          case AssistantStreamStatus(:final sessionId):
            if (sessionId != null) state = state.copyWith(sessionId: sessionId);
          case AssistantStreamTool(:final name, :final label, :final started):
            if (started) {
              state = state.copyWith(
                  clearToolLabel: true, toolName: name, toolLabel: label);
            }
            // finished: NO se limpia; la etiqueta queda hasta el siguiente
            // `started` (la herramienta dura ms, el modelo segundos).
          case AssistantStreamDelta(:final text):
            state = state.copyWith(
                streamingText: state.streamingText + text, clearToolLabel: true);
          case AssistantStreamDone(:final result):
            // Autoritativo: reemplaza lo acumulado y procesa metadata igual
            // que el JSON.
            _commitResult(result);
            finished = true;
          case AssistantStreamError(:final error):
            fail(error);
          case AssistantStreamCancelled():
            state = state.copyWith(
                isLoading: false, streamingText: '', clearToolLabel: true);
            finished = true;
        }
      },
      onError: (Object e) async {
        if (turn != _turnId) return finish();
        if (!gotEvent &&
            e is ApiException &&
            e.errorCode == kConnectionFailedCode) {
          // El completer sigue abierto: sendText espera al JSON también.
          await _sendTextJson(text, context);
          finish();
          return;
        }
        fail(e);
      },
      onDone: () {
        if (turn == _turnId && !finished) {
          // El stream cerró sin done/error/cancelled: no hay respuesta.
          fail(const ApiException(
            statusCode: 0,
            message: kConnectionFailedCode,
            errorCode: kConnectionFailedCode,
          ));
          return;
        }
        finish();
      },
      cancelOnError: true,
    );
    await completer.future;
  }

  /// Aborta el turno de texto en curso (el asesor salió de la pantalla, o
  /// reinició la conversación): cierra la conexión SSE y le avisa al backend
  /// con `POST /ai/sessions/:id/cancel` para que deje de gastar modelo.
  /// Sin turno en curso no hace nada.
  void cancelTurn() {
    final sub = _turnSubscription;
    if (sub == null && !state.isLoading) return;
    _turnId++; // invalida los eventos que lleguen después
    _turnSubscription = null;
    sub?.cancel();
    final done = _turnDone;
    if (done != null && !done.isCompleted) done.complete();
    final sid = state.sessionId;
    if (sid != null) {
      // fire-and-forget: si falla (sin red) el backend igual notará la
      // conexión cerrada; no hay nada útil que mostrar al asesor.
      unawaited(_repo.cancelSession(sid).catchError((_) {}));
    }
    state = state.copyWith(isLoading: false, streamingText: '', clearToolLabel: true);
  }

  // ── Dictado (STT del sistema → campo de texto) ─────────────────────────────

  /// Empieza a dictar en [languageCode] ('es', 'en'…). El audio se queda en el
  /// teléfono: al terminar solo cae texto en el campo, que el asesor revisa y
  /// envía él mismo. No manda nada al backend por su cuenta.
  Future<void> startDictation(String languageCode) async {
    // El dictado y Gemini Live se pelean el micrófono; en modo voz el composer
    // ni se dibuja, pero el candado va aquí y no en la UI.
    if (state.mode == AssistantMode.voice || state.isDictating) return;

    state = state.copyWith(isDictating: true, clearError: true, clearDictationText: true);
    await _dictation.start(languageCode);
  }

  Future<void> stopDictation() async {
    if (!state.isDictating) return;
    await _dictation.stop();
  }

  /// Aborta el dictado sin entregar texto — al salir de la pantalla o al pasar
  /// a voz Live.
  Future<void> cancelDictation() async {
    if (!state.isDictating) return;
    state = state.copyWith(isDictating: false, clearDictationText: true);
    await _dictation.cancel();
  }

  /// La pantalla ya metió el texto dictado en el campo.
  void consumeDictationText() {
    if (state.dictationText == null) return;
    state = state.copyWith(clearDictationText: true);
  }

  /// Nivel de voz del dictado (0..1) para la onda del composer.
  ValueListenable<double> get dictationLevel => _dictation.level;

  void _onDictationEvent(DictationEvent event) {
    switch (event) {
      // El texto parcial no se pinta a propósito: con nombres de clientes y
      // aseguradoras se corrige solo varias veces y parpadear se ve peor que
      // esperar. La onda ya dice que está oyendo.
      case DictationPartial():
        break;
      case DictationFinished(:final text):
        state = state.copyWith(
          isDictating: false,
          dictationText: text.isEmpty ? null : text,
        );
      case DictationFailed(:final code):
        state = state.copyWith(isDictating: false, error: code);
    }
  }

  // ── Voz (Gemini Live, full-duplex) ──────────────────────────────────────────

  Future<void> startVoice(String timezone) async {
    // Nunca los dos sobre el mismo micrófono.
    await cancelDictation();

    final isFirstMessage = state.sessionId == null;

    state = state.copyWith(
      mode: AssistantMode.voice,
      voiceStatus: VoiceStatus.connecting,
      clearContext: isFirstMessage,
    );

    try {
      final (initData, tokenData) = await _fetchInitAndToken(timezone, state.sessionId);

      final sessionId = initData['sessionId'] as String;
      ref.read(aiBackendProvider.notifier).set(tokenData['aiBackend'] as String?);
      state = state.copyWith(sessionId: sessionId);

      // Sin fallback de modelo: el backend decide el modelo de la sesión y si no
      // lo manda es un error del contrato, no algo que la app deba adivinar.
      final modelName = tokenData['model'] as String?;
      if (modelName == null || modelName.isEmpty) {
        throw const ApiException(
          statusCode: 500,
          message: 'Voice token response is missing "model"',
          errorCode: 'INTERNAL_ERROR',
        );
      }

      await _engine.connect(
        sessionId: sessionId,
        timezone: timezone,
        systemInstruction: initData['systemInstruction'] as String,
        dynamicContext: initData['dynamicContext'] as String? ?? '',
        tools: initData['tools'] as List<dynamic>? ?? [],
        url: tokenData['url'] as String,
        token: tokenData['token'] as String,
        headersMap: tokenData['headers'] as Map<String, dynamic>?,
        modelName: modelName,
      );
      // El paso a `listening` llega con EngineListening cuando Gemini confirma
      // el setup (ahí mismo se abre el mic).
    } catch (e) {
      debugPrint('[$_kLogTag] startVoice error: $e');
      state = state.copyWith(
        voiceStatus: VoiceStatus.error,
        error: mapApiError(e),
      );
    }
  }

  void stopVoice() {
    _engine.shutdown();
    state = state.copyWith(mode: AssistantMode.text, voiceStatus: VoiceStatus.connecting);
  }

  void endVoice() {
    stopVoice();
  }

  /// Nivel de audio en vivo (0..1) para las animaciones reactivas de la barra
  /// de voz — mic real mientras escucha, salida real del modelo mientras
  /// responde. Expuestos como [ValueListenable] (no como parte de
  /// [AssistantState]) porque cambian ~20 veces/seg y no deben disparar un
  /// rebuild de toda la pantalla.
  ValueListenable<double> get micLevel => _engine.micLevel;
  ValueListenable<double> get modelLevel => _engine.modelLevel;

  /// Dispositivos de salida disponibles (selector de audio en modo voz).
  Future<List<AudioOutputDevice>> audioOutputDevices() =>
      ref.read(nativeAudioServiceProvider).getAudioDevices();

  /// Cambia la salida de audio de la sesión de voz activa.
  Future<void> selectAudioOutput(String id) =>
      ref.read(nativeAudioServiceProvider).selectAudioDevice(id);

  // ── Engine event mapping ───────────────────────────────────────────────────

  void _onEngineEvent(VoiceEngineEvent event) {
    switch (event) {
      case EngineListening():
        state = state.copyWith(voiceStatus: VoiceStatus.listening);
      case EngineModelSpeaking():
        state = state.copyWith(voiceStatus: VoiceStatus.modelSpeaking);
      case EngineUserTranscript(:final delta):
        state = state.copyWith(
          liveUserText: state.liveUserText + delta,
        );
      case EngineModelTranscript(:final delta):
        state = state.copyWith(
          voiceStatus: VoiceStatus.modelSpeaking,
          liveModelText: state.liveModelText + delta,
        );
      case EngineTurnCommitted(:final userText, :final modelText, :final metadata):
        final newMsgs = [...state.messages];
        if (userText.isNotEmpty) {
          newMsgs.add(AssistantMessage(role: 'user', text: userText));
        }
        if (modelText.isNotEmpty) {
          newMsgs.add(AssistantMessage(role: 'ai', text: modelText, metadata: metadata));
        }
        state = state.copyWith(
          messages: newMsgs,
          liveUserText: '',
          liveModelText: '',
          // La card ya quedó anclada a la burbuja — quitar la transitoria
          // para no mostrarla duplicada.
          clearActiveWidgetMetadata: metadata != null,
        );
      case EngineSkillStarted(:final name):
        state = state.copyWith(activeSkill: name);
      case EngineSkillCleared():
        state = state.copyWith(clearActiveSkill: true);
      case EngineWidgetMetadata(:final metadata):
        state = state.copyWith(activeWidgetMetadata: metadata);
      case EngineWidgetMetadataCleared():
        state = state.copyWith(clearActiveWidgetMetadata: true);
      case EngineCountdownTick(:final secondsLeft):
        state = state.copyWith(voiceTimeLeftSeconds: secondsLeft);
      case EngineTimeExpired():
        endVoice();
      case EngineWatchdogTimeout():
        stopVoice();
      case EngineFailure(:final message):
        state = state.copyWith(voiceStatus: VoiceStatus.error, error: message);
    }
  }

  // ── Backend ────────────────────────────────────────────────────────────────

  Future<(Map<String, dynamic>, Map<String, dynamic>)> _fetchInitAndToken(
      String timezone, String? resumeSessionId) async {
    final api = ref.read(apiClientProvider);
    final ctx = state.activeContext ?? state.pendingContext;
    final initData = unwrapData(await api.post('ai/voice/init', body: {
      'timezone': timezone,
      if (resumeSessionId != null) 'sessionId': resumeSessionId,
      if (ctx != null) 'context': ctx.toJson(),
    }));
    final tokenData = unwrapData(await api.post('ai/voice/token', body: {
      'systemInstruction': initData['systemInstruction'],
      'tools': initData['tools'] ?? [],
    }));
    return (initData, tokenData);
  }
}
