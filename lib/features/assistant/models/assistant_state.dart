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
    );
  }
}
