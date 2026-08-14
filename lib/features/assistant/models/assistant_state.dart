import 'package:flutter/foundation.dart';
import '../data/assistant_repository.dart';
import '../../../core/models/ai_chat_context.dart';

export 'package:amconnect/features/assistant/data/assistant_repository.dart' show AssistantMessage;
export 'package:amconnect/core/models/ai_chat_context.dart' show AiChatContext;

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

  /// El STF del sistema está capturando voz para llenar el campo de texto.
  /// No tiene nada que ver con [AssistantMode.voice] (Gemini Live) — de hecho
  /// son excluyentes, ver `AssistantNotifier.startDictation`.
  final bool isDictating;

  /// Texto que acaba de dictarse, esperando a que la pantalla lo meta en el
  /// campo. Vive en el estado (y no se envía solo) porque el
  /// `TextEditingController` es de la pantalla; se limpia con
  /// [AssistantNotifier.consumeDictationText] en cuanto se aplica.
  final String? dictationText;

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
    this.isDictating = false,
    this.dictationText,
  });

  AssistantState copyWith({
    List<AssistantMessage>? messages,
    String? sessionId,
    bool? isLoading,
    String? error,
    bool clearError = false,
    AiChatContext? pendingContext,
    AiChatContext? activeContext,
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
    bool? isDictating,
    String? dictationText,
    bool clearDictationText = false,
  }) {
    return AssistantState(
      messages: messages ?? this.messages,
      sessionId: sessionId ?? this.sessionId,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      pendingContext: clearContext ? null : (pendingContext ?? this.pendingContext),
      activeContext: clearContext ? null : (activeContext ?? this.activeContext),
      mode: mode ?? this.mode,
      voiceStatus: voiceStatus ?? this.voiceStatus,
      liveUserText: liveUserText ?? this.liveUserText,
      liveModelText: liveModelText ?? this.liveModelText,
      activeSkill: clearActiveSkill ? null : (activeSkill ?? this.activeSkill),
      activeWidgetMetadata:
          clearActiveWidgetMetadata ? null : (activeWidgetMetadata ?? this.activeWidgetMetadata),
      voiceTimeLeftSeconds: voiceTimeLeftSeconds ?? this.voiceTimeLeftSeconds,
      isDictating: isDictating ?? this.isDictating,
      dictationText: clearDictationText ? null : (dictationText ?? this.dictationText),
    );
  }
}
