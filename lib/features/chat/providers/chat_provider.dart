import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amconnect/core/network/api_client.dart';
import 'package:amconnect/features/chat/data/chat_repository.dart';

export 'package:amconnect/features/chat/data/chat_repository.dart' show ChatMessage;

class ChatState {
  final List<ChatMessage> messages;
  final String? sessionId;
  final bool isLoading;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.sessionId,
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    String? sessionId,
    bool? isLoading,
    String? error,
  }) => ChatState(
    messages: messages ?? this.messages,
    sessionId: sessionId ?? this.sessionId,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class ChatNotifier extends Notifier<ChatState> {
  late ChatRepository _repo;

  @override
  ChatState build() {
    _repo = ChatRepository(ref.read(apiClientProvider));
    return const ChatState();
  }

  Future<void> send(String text) async {
    if (text.trim().isEmpty) return;

    state = state.copyWith(
      messages: [...state.messages, ChatMessage(role: 'user', text: text)],
      isLoading: true,
      error: null,
    );

    try {
      final result = await _repo.sendMessage(text, sessionId: state.sessionId);
      state = state.copyWith(
        messages: [...state.messages, ChatMessage(role: 'ai', text: result.text)],
        sessionId: result.sessionId,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is ApiException ? e.message : e.toString(),
      );
    }
  }

  Future<void> reset() async {
    final sid = state.sessionId;
    if (sid != null) {
      try { await _repo.cancelSession(sid); } catch (_) {}
    }
    state = const ChatState();
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
