import 'dart:async';
import 'dart:convert';
import '../../../core/network/api_client.dart';
import '../../../core/network/sse_parser.dart';
import '../../../core/models/ai_chat_context.dart';

class AssistantMessage {
  final String role; // 'user' | 'ai'
  final String text;
  final Map<String, dynamic>? metadata;
  const AssistantMessage({required this.role, required this.text, this.metadata});
}

/// Respuesta final de un turno de chat — la misma forma en `/ai/chat` (JSON) y
/// en el evento `done` de `/ai/chat/stream`.
typedef AssistantChatResult = ({
  String text,
  String sessionId,
  Map<String, dynamic>? metadata,
  String? aiBackend,
});

/// Eventos tipados de `POST /ai/chat/stream`.
sealed class AssistantStreamEvent {
  const AssistantStreamEvent();
}

/// El backend va a llamar al modelo; trae el sessionId (también en sesiones nuevas).
class AssistantStreamStatus extends AssistantStreamEvent {
  const AssistantStreamStatus({required this.phase, this.sessionId});
  final String phase;
  final String? sessionId;
}

/// Una herramienta empezó o terminó. [name] es el nombre técnico (la app lo
/// traduce a su idioma); [label] viene del backend y solo es el respaldo cuando
/// [name] no llega (backends viejos).
class AssistantStreamTool extends AssistantStreamEvent {
  const AssistantStreamTool({this.name, this.label = '', required this.started, this.ok});
  final String? name;
  final String label;
  final bool started;
  final bool? ok;
}

/// Texto incremental para agregar a la burbuja.
class AssistantStreamDelta extends AssistantStreamEvent {
  const AssistantStreamDelta(this.text);
  final String text;
}

/// Resultado autoritativo del turno.
class AssistantStreamDone extends AssistantStreamEvent {
  const AssistantStreamDone(this.result);
  final AssistantChatResult result;
}

/// Error del turno ya como excepción tipada (se traduce con `mapApiError`).
class AssistantStreamError extends AssistantStreamEvent {
  const AssistantStreamError(this.error);
  final ApiException error;
}

/// El backend canceló el turno (tras `POST /ai/sessions/:id/cancel`).
class AssistantStreamCancelled extends AssistantStreamEvent {
  const AssistantStreamCancelled({this.sessionId});
  final String? sessionId;
}

class AssistantRepository {
  final ApiClient _api;
  AssistantRepository(this._api);

  Map<String, dynamic> _body(String message, String? sessionId, AiChatContext? context) => {
        'message': message,
        if (sessionId != null) 'sessionId': sessionId,
        if (context != null) 'context': context.toJson(),
      };

  /// Fallback JSON (un solo round-trip, sin streaming).
  Future<AssistantChatResult> sendMessage(
    String message, {
    String? sessionId,
    AiChatContext? context,
  }) async {
    final res = await _api.post('ai/chat', body: _body(message, sessionId, context));
    return _parseDone(res['data'] as Map<String, dynamic>);
  }

  /// `POST /ai/chat/stream` (SSE). Un status no 2xx o un fallo al conectar se
  /// lanza como `ApiException` al hacer `listen` (antes de cualquier evento);
  /// errores de negocio posteriores llegan como [AssistantStreamError].
  /// Cancelar la suscripción cierra la conexión.
  Stream<AssistantStreamEvent> sendMessageStream(
    String message, {
    String? sessionId,
    AiChatContext? context,
  }) async* {
    final bytes = await _api.postStream(
      'ai/chat/stream',
      body: _body(message, sessionId, context),
    );
    await for (final raw in bytes.transform(const SseParser())) {
      final e = mapSseEvent(raw);
      if (e != null) yield e;
    }
  }

  /// Traduce un evento SSE crudo; null si es desconocido o malformado.
  static AssistantStreamEvent? mapSseEvent(SseEvent raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw.data);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, dynamic>) return null;
    switch (raw.event) {
      case 'status':
        return AssistantStreamStatus(
          phase: decoded['phase']?.toString() ?? 'thinking',
          sessionId: decoded['sessionId'] as String?,
        );
      case 'tool':
        final label = decoded['label']?.toString() ?? '';
        final name = decoded['name']?.toString();
        final hasName = name != null && name.isNotEmpty;
        if (label.isEmpty && !hasName) return null;
        return AssistantStreamTool(
          name: hasName ? name : null,
          label: label,
          started: decoded['state'] == 'started',
          ok: decoded['ok'] as bool?,
        );
      case 'delta':
        final text = decoded['text'];
        return text is String && text.isNotEmpty ? AssistantStreamDelta(text) : null;
      case 'done':
        try {
          return AssistantStreamDone(_parseDone(decoded));
        } on TypeError {
          return null;
        }
      case 'error':
        return AssistantStreamError(ApiException(
          statusCode: 200,
          message: decoded['error']?.toString() ?? 'errUnknown',
          errorCode: decoded['errorCode']?.toString(),
          errorId: decoded['errorId']?.toString(),
        ));
      case 'cancelled':
        return AssistantStreamCancelled(sessionId: decoded['sessionId'] as String?);
      default:
        return null;
    }
  }

  static AssistantChatResult _parseDone(Map<String, dynamic> data) {
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
