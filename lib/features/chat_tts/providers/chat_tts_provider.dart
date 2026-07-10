import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/ai_backend_provider.dart';
import '../../../core/services/audio_playback_service.dart';
import '../../../core/utils/api_error_mapper.dart';
import '../data/chat_tts_repository.dart';

enum ChatTtsPhase { idle, thinking, speaking, error }

class ChatTtsState {
  final String? sessionId;
  final String lastUserText;
  final String lastAiText;
  final ChatTtsPhase phase;
  final String? error;

  const ChatTtsState({
    this.sessionId,
    this.lastUserText = '',
    this.lastAiText = '',
    this.phase = ChatTtsPhase.idle,
    this.error,
  });

  ChatTtsState copyWith({
    String? sessionId,
    String? lastUserText,
    String? lastAiText,
    ChatTtsPhase? phase,
    String? error,
    bool clearError = false,
  }) => ChatTtsState(
    sessionId: sessionId ?? this.sessionId,
    lastUserText: lastUserText ?? this.lastUserText,
    lastAiText: lastAiText ?? this.lastAiText,
    phase: phase ?? this.phase,
    error: clearError ? null : (error ?? this.error),
  );
}

/// Orquesta un turno del chat de voz walkie-talkie: recibe el texto ya
/// transcrito on-device (sttProvider hace el STT, este notifier no toca
/// audio de entrada) → /ai/chat/tts → reproduce la respuesta.
class ChatTtsNotifier extends Notifier<ChatTtsState> {
  late ChatTtsRepository _repo;
  late AudioPlaybackService _audio;

  @override
  ChatTtsState build() {
    _repo = ChatTtsRepository(ref.read(apiClientProvider));
    _audio = ref.read(audioPlaybackServiceProvider);
    return const ChatTtsState();
  }

  Future<void> send(String text) async {
    if (text.trim().isEmpty) return;

    state = state.copyWith(
      lastUserText: text,
      phase: ChatTtsPhase.thinking,
      clearError: true,
    );

    try {
      final result = await _repo.sendMessage(text, sessionId: state.sessionId);
      ref.read(aiBackendProvider.notifier).set(result.aiBackend);
      state = state.copyWith(
        sessionId: result.sessionId,
        lastAiText: result.text,
        phase: ChatTtsPhase.speaking,
      );

      if (result.audioBase64 != null && result.audioBase64!.isNotEmpty) {
        await _audio.playBase64(result.audioBase64!, mimeType: result.audioMimeType ?? 'audio/wav');
      }
      state = state.copyWith(phase: ChatTtsPhase.idle);
    } catch (e) {
      state = state.copyWith(phase: ChatTtsPhase.error, error: mapApiError(e));
    }
  }

  Future<void> reset() async {
    final sid = state.sessionId;
    if (sid != null) {
      try { await _repo.cancelSession(sid); } catch (_) {}
    }
    await _audio.stop();
    state = const ChatTtsState();
  }
}

final chatTtsProvider = NotifierProvider<ChatTtsNotifier, ChatTtsState>(ChatTtsNotifier.new);
