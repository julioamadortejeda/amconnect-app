import 'package:amconnect/core/network/api_client.dart';

class ChatMessage {
  final String role; // 'user' | 'ai'
  final String text;
  const ChatMessage({required this.role, required this.text});
}

class ChatRepository {
  final ApiClient _api;
  ChatRepository(this._api);

  Future<({String text, String sessionId})> sendMessage(
    String message, {
    String? sessionId,
  }) async {
    final res = await _api.post('ai/chat', body: {
      'message': message,
      if (sessionId != null) 'sessionId': sessionId,
    });
    final data = res['data'] as Map<String, dynamic>;
    return (
      text: data['text'] as String,
      sessionId: data['sessionId'] as String,
    );
  }

  Future<void> cancelSession(String sessionId) async {
    await _api.post('ai/sessions/$sessionId/cancel');
  }
}
