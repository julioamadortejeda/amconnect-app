import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/ai_backend_provider.dart';
import '../../../core/services/gemini_voice_engine.dart';
import '../../../core/services/native_audio_service.dart';

const String _kLogTag = 'VoiceChat';

enum VoiceChatStatus {
  connecting,
  ready,
  listening,
  modelSpeaking,
  error,
  closed,
}

@immutable
class VoiceChatTurn {
  final bool isUser;
  final String text;
  const VoiceChatTurn({required this.isUser, required this.text});
}

@immutable
class VoiceChatState {
  final VoiceChatStatus status;
  final String? sessionId;
  final List<VoiceChatTurn> turns;
  final String liveUserText;
  final String liveModelText;
  final String? activeSkill;
  final String? error;
  final int timeLeftSeconds;
  final Map<String, dynamic>? activeWidgetMetadata;

  const VoiceChatState({
    this.status = VoiceChatStatus.connecting,
    this.sessionId,
    this.turns = const [],
    this.liveUserText = '',
    this.liveModelText = '',
    this.activeSkill,
    this.error,
    this.timeLeftSeconds = 600,
    this.activeWidgetMetadata,
  });

  VoiceChatState copyWith({
    VoiceChatStatus? status,
    String? sessionId,
    List<VoiceChatTurn>? turns,
    String? liveUserText,
    String? liveModelText,
    String? activeSkill,
    bool clearActiveSkill = false,
    String? error,
    int? timeLeftSeconds,
    Map<String, dynamic>? activeWidgetMetadata,
    bool clearActiveWidgetMetadata = false,
  }) {
    return VoiceChatState(
      status: status ?? this.status,
      sessionId: sessionId ?? this.sessionId,
      turns: turns ?? this.turns,
      liveUserText: liveUserText ?? this.liveUserText,
      liveModelText: liveModelText ?? this.liveModelText,
      activeSkill: clearActiveSkill ? null : (activeSkill ?? this.activeSkill),
      error: error ?? this.error,
      timeLeftSeconds: timeLeftSeconds ?? this.timeLeftSeconds,
      activeWidgetMetadata: clearActiveWidgetMetadata
          ? null
          : (activeWidgetMetadata ?? this.activeWidgetMetadata),
    );
  }
}

final voiceChatProvider =
    NotifierProvider.autoDispose<VoiceChatNotifier, VoiceChatState>(
  VoiceChatNotifier.new,
);

/// Adaptador delgado: la orquestación de la sesión de voz (WebSocket, mic,
/// turnos, tokens) vive en [GeminiVoiceEngine]; aquí solo se mapean sus
/// eventos al estado de esta pantalla.
class VoiceChatNotifier extends Notifier<VoiceChatState> {
  late final GeminiVoiceEngine _engine;
  StreamSubscription<VoiceEngineEvent>? _engineSubscription;

  @override
  VoiceChatState build() {
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
    return const VoiceChatState();
  }

  Future<void> connect(String timezone) async {
    state = const VoiceChatState(status: VoiceChatStatus.connecting);

    try {
      final api = ref.read(apiClientProvider);
      final initData = await api.post('ai/voice/init', body: {
        'timezone': timezone,
      });
      final tokenData = await api.post('ai/voice/token', body: {
        'systemInstruction': initData['systemInstruction'],
        'tools': initData['tools'] ?? [],
      });

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
      // el setup — no antes.
    } catch (e) {
      debugPrint('[$_kLogTag] connect error: $e');
      state = state.copyWith(
        status: VoiceChatStatus.error,
        error: e.toString(),
      );
    }
  }

  void interrupt() => _engine.interrupt();

  void endSession() {
    _engine.shutdown();
    state = state.copyWith(status: VoiceChatStatus.closed);
  }

  void _onEngineEvent(VoiceEngineEvent event) {
    switch (event) {
      case EngineListening():
        state = state.copyWith(status: VoiceChatStatus.listening);
      case EngineModelSpeaking():
        state = state.copyWith(status: VoiceChatStatus.modelSpeaking);
      case EngineUserTranscript(:final delta):
        state = state.copyWith(liveUserText: state.liveUserText + delta);
      case EngineModelTranscript(:final delta):
        state = state.copyWith(liveModelText: state.liveModelText + delta);
      case EngineTurnCommitted(:final userText, :final modelText):
        final newTurns = [...state.turns];
        if (userText.isNotEmpty) {
          newTurns.add(VoiceChatTurn(isUser: true, text: userText));
        }
        if (modelText.isNotEmpty) {
          newTurns.add(VoiceChatTurn(isUser: false, text: modelText));
        }
        state = state.copyWith(
          turns: newTurns,
          liveUserText: '',
          liveModelText: '',
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
        state = state.copyWith(timeLeftSeconds: secondsLeft);
      case EngineTimeExpired():
        endSession();
      case EngineWatchdogTimeout():
        endSession();
      case EngineFailure(:final message):
        state = state.copyWith(status: VoiceChatStatus.error, error: message);
    }
  }
}
