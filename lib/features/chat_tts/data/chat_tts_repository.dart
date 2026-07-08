import '../../../core/network/api_client.dart';
import '../../chat/data/chat_context.dart';

/// Repositorio del chat de voz turn-based (walkie-talkie) — feature aislado,
/// independiente de ChatRepository (chat de texto) y de VoiceChatProvider
/// (Live API): sesión y estado propios, mismo patrón que ya separa esas dos.
class ChatTtsRepository {
  final ApiClient _api;
  ChatTtsRepository(this._api);

  Future<({String text, String sessionId, String? audioBase64, String? audioMimeType})> sendMessage(
    String message, {
    String? sessionId,
    AiChatContext? context,
  }) async {
    final body = {
      'message': message,
      if (sessionId != null) 'sessionId': sessionId,
      if (context != null) 'context': context.toJson(),
    };
    final res = await _api.post('ai/chat/tts', body: body);
    final data = res['data'] as Map<String, dynamic>;
    return (
      text: data['text'] as String,
      sessionId: data['sessionId'] as String,
      audioBase64: data['audioBase64'] as String?,
      audioMimeType: data['audioMimeType'] as String?,
    );
  }

  Future<void> cancelSession(String sessionId) async {
    await _api.post('ai/sessions/$sessionId/cancel');
  }
}
