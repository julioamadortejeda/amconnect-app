import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/ai_backend_provider.dart';
import '../../../core/utils/api_error_mapper.dart';
import '../../../core/services/gemini_voice_engine.dart';
import '../../../core/services/native_audio_service.dart';
import '../data/assistant_repository.dart';
import '../models/assistant_state.dart';

export '../models/assistant_state.dart';

const String _kLogTag = 'Assistant/Voice';

// ── Provider ──────────────────────────────────────────────────────────────────

final assistantProvider =
    NotifierProvider<AssistantNotifier, AssistantState>(AssistantNotifier.new);

// ── Notifier ──────────────────────────────────────────────────────────────────

/// El chat de texto vive aquí; la sesión de voz se delega a [GeminiVoiceEngine]
/// (la misma orquestación que usa VoiceChatNotifier) y este Notifier solo mapea
/// sus eventos a [AssistantState].
class AssistantNotifier extends Notifier<AssistantState> {
  late final AssistantRepository _repo;
  late final GeminiVoiceEngine _engine;
  StreamSubscription<VoiceEngineEvent>? _engineSubscription;

  // Prefetch de init/token para abrir la voz sin esperar los dos POST.
  Future<(Map<String, dynamic>, Map<String, dynamic>)>? _prefetched;
  DateTime? _prefetchedAt;

  @override
  AssistantState build() {
    _repo = AssistantRepository(ref.read(apiClientProvider));
    _engine = GeminiVoiceEngine(
      audioService: ref.read(nativeAudioServiceProvider),
      api: ref.read(apiClientProvider),
      logTag: _kLogTag,
    );
    _engineSubscription = _engine.events.listen(_onEngineEvent);
    ref.onDispose(() {
      _engineSubscription?.cancel();
      _engine.dispose();
    });
    return const AssistantState();
  }

  // ── Reset & Navigation API ───────────────────────────────────────────────

  void reset() {
    stopVoice();
    state = const AssistantState();
  }

  void resetWithContext(AiChatContext context) {
    stopVoice();
    state = AssistantState(pendingContext: context);
  }

  void setPendingContext(AiChatContext context) {
    state = state.copyWith(pendingContext: context);
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

  // ── Voz (Gemini Live, full-duplex) ──────────────────────────────────────────

  Future<void> startVoice(String timezone) async {
    final isFirstMessage = state.sessionId == null;

    state = state.copyWith(
      mode: AssistantMode.voice,
      voiceStatus: VoiceStatus.connecting,
      clearContext: isFirstMessage,
    );

    try {
      final prefetchFuture = _prefetched;
      final prefetchAge = _prefetchedAt != null
          ? DateTime.now().difference(_prefetchedAt!)
          : null;

      Map<String, dynamic> initData;
      Map<String, dynamic> tokenData;

      if (prefetchFuture != null && prefetchAge != null && prefetchAge.inSeconds < 45) {
        debugPrint('[$_kLogTag] Using prefetched session init/token');
        final res = await prefetchFuture;
        initData = res.$1;
        tokenData = res.$2;
      } else {
        debugPrint('[$_kLogTag] Prefetch miss — fetching init/token on start');
        final res = await _fetchInitAndToken(timezone, state.sessionId);
        initData = res.$1;
        tokenData = res.$2;
      }
      _prefetched = null;
      _prefetchedAt = null;

      final sessionId = initData['sessionId'] as String;
      ref.read(aiBackendProvider.notifier).set(tokenData['aiBackend'] as String?);
      state = state.copyWith(sessionId: sessionId);

      await _engine.connect(
        sessionId: sessionId,
        timezone: timezone,
        systemInstruction: initData['systemInstruction'] as String,
        dynamicContext: initData['dynamicContext'] as String? ?? '',
        tools: initData['tools'] as List<dynamic>? ?? [],
        url: tokenData['url'] as String,
        token: tokenData['token'] as String,
        headersMap: tokenData['headers'] as Map<String, dynamic>?,
        modelName: tokenData['model'] as String? ?? 'models/gemini-2.0-flash-exp',
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

  void prefetch(String timezone) {
    if (_engine.isConnected || _prefetched != null) return;
    _prefetchedAt = DateTime.now();
    final future = _fetchInitAndToken(timezone, state.sessionId);
    // Evita el warning de future no manejado si el prefetch falla antes de que
    // startVoice lo espere; el error real se maneja en startVoice.
    future.catchError((_) => (<String, dynamic>{}, <String, dynamic>{}));
    _prefetched = future;
  }

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
    final initData = await api.post('ai/voice/init', body: {
      'timezone': timezone,
      if (resumeSessionId != null) 'sessionId': resumeSessionId,
      if (ctx != null) 'context': ctx.toJson(),
    });
    final tokenData = await api.post('ai/voice/token', body: {
      'systemInstruction': initData['systemInstruction'],
      'tools': initData['tools'] ?? [],
    });
    return (initData, tokenData);
  }
}
