import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import 'chat_context.dart';

class ChatMessage {
  final String role; // 'user' | 'ai'
  final String text;
  final Map<String, dynamic>? metadata;
  const ChatMessage({required this.role, required this.text, this.metadata});
}

class ChatRepository {
  final ApiClient _api;
  ChatRepository(this._api);

  Future<({String text, String sessionId, Map<String, dynamic>? metadata})> sendMessage(
    String message, {
    String? sessionId,
    AiChatContext? context,
  }) async {
    final body = {
      'message': message,
      if (sessionId != null) 'sessionId': sessionId,
      if (context != null) 'context': context.toJson(),
    };
    debugPrint('[ai/chat] ${const JsonEncoder.withIndent('  ').convert(body)}');
    final res = await _api.post('ai/chat', body: body);
    final data = res['data'] as Map<String, dynamic>;
    final rawMeta = data['metadata'];
    return (
      text: data['text'] as String,
      sessionId: data['sessionId'] as String,
      metadata: rawMeta is Map<String, dynamic> ? rawMeta : null,
    );
  }

  Future<void> cancelSession(String sessionId) async {
    await _api.post('ai/sessions/$sessionId/cancel');
  }
}
