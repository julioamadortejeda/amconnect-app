import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../data/chat_context.dart';
import '../data/chat_repository.dart';

export 'package:amconnect/features/chat/data/chat_repository.dart' show ChatMessage;
export 'package:amconnect/features/chat/data/chat_context.dart' show AiChatContext;

class ChatState {
  final List<ChatMessage> messages;
  final String? sessionId;
  final bool isLoading;
  final String? error;
  final AiChatContext? pendingContext;
  final AiChatContext? activeContext;

  const ChatState({
    this.messages = const [],
    this.sessionId,
    this.isLoading = false,
    this.error,
    this.pendingContext,
    this.activeContext,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    String? sessionId,
    bool? isLoading,
    String? error,
    AiChatContext? pendingContext,
    bool clearContext = false,
  }) => ChatState(
    messages: messages ?? this.messages,
    sessionId: sessionId ?? this.sessionId,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    pendingContext: clearContext ? null : (pendingContext ?? this.pendingContext),
    activeContext: activeContext,
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

    final isFirstMessage = state.sessionId == null;
    final context = isFirstMessage ? state.pendingContext : null;

    state = state.copyWith(
      messages: [...state.messages, ChatMessage(role: 'user', text: text)],
      isLoading: true,
      error: null,
      clearContext: isFirstMessage,
    );

    try {
      final result = await _repo.sendMessage(
        text,
        sessionId: state.sessionId,
        context: context,
      );
      state = state.copyWith(
        messages: [...state.messages, ChatMessage(role: 'ai', text: result.text, metadata: result.metadata)],
        sessionId: result.sessionId,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is ApiException ? _mapApiException(e) : e.toString(),
      );
    }
  }

  String _mapApiException(ApiException e) {
    if (e.errorCode != null) {
      return e.errorCode!;
    }
    if (e.statusCode == 503 || e.message.contains("unavailable") || e.message.contains("high demand")) {
      return "AI_PROVIDER_BUSY";
    }
    if (e.statusCode == 401) {
      return "SESSION_EXPIRED";
    }
    if (e.statusCode == 404) {
      return "RESOURCE_NOT_FOUND";
    }

    try {
      final decoded = jsonDecode(e.message);
      if (decoded is Map) {
        if (decoded['error'] is Map) {
          return decoded['error']['message']?.toString() ?? 'Error del servidor';
        }
        return decoded['error']?.toString() ?? decoded['message']?.toString() ?? e.message;
      }
    } catch (_) {}

    return e.message;
  }

  Future<void> reset() async {
    final sid = state.sessionId;
    if (sid != null) {
      try { await _repo.cancelSession(sid); } catch (_) {}
    }
    state = const ChatState();
  }

  Future<void> resetWithContext(AiChatContext ctx) async {
    await reset();
    state = ChatState(pendingContext: ctx, activeContext: ctx);
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
