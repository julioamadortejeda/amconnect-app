import '../../../core/network/api_client.dart';
import '../../../core/models/ai_chat_context.dart';

class AssistantMessage {
  final String role; // 'user' | 'ai'
  final String text;
  final Map<String, dynamic>? metadata;
  const AssistantMessage({required this.role, required this.text, this.metadata});
}

class AssistantRepository {
  final ApiClient _api;
  AssistantRepository(this._api);

  Future<({String text, String sessionId, Map<String, dynamic>? metadata, String? aiBackend})> sendMessage(
    String message, {
    String? sessionId,
    AiChatContext? context,
  }) async {
    final body = {
      'message': message,
      if (sessionId != null) 'sessionId': sessionId,
      if (context != null) 'context': context.toJson(),
    };
    final res = await _api.post('ai/chat', body: body);
    final data = res['data'] as Map<String, dynamic>;
    final rawMeta = data['metadata'];
    return (
      text: data['text'] as String,
      sessionId: data['sessionId'] as String,
      metadata: rawMeta is Map<String, dynamic> ? rawMeta : null,
      aiBackend: data['aiBackend'] as String?,
    );
  }

  Future<void> cancelSession(String sessionId) async {
    await _api.post('ai/sessions/$sessionId/cancel');
  }
}
