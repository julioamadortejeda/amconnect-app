import 'dart:convert';
import '../network/api_client.dart';

/// Separador interno entre la clave de error y el código de referencia.
/// Solo lo conocen este archivo y `error_translator.dart`.
const kErrRefSeparator = '#ref=';

/// Convierte cualquier error capturado en un provider a la string que se
/// guarda en el estado y que la UI traduce con `context.translateError(...)`.
///
/// - `ApiException` con `errorCode` → devuelve el código (la UI lo localiza).
/// - `ApiException` sin código → intenta inferirlo por status o devuelve el
///   mensaje del backend tal cual (fallback del contrato).
/// - Cualquier otro error → clave genérica (nunca `e.toString()` al usuario).
///
/// Si la excepción trae `errorId` (registro en `error_logs` del backend),
/// se adjunta abreviado como sufijo `#ref=xxxxxxxx` para que la UI lo muestre
/// como "código de referencia" de soporte.
String mapApiError(Object e) {
  if (e is! ApiException) return 'errUnknown';

  final key = _keyFor(e);
  final ref = e.errorId;
  if (ref != null && ref.isNotEmpty) {
    return '$key$kErrRefSeparator${ref.substring(0, ref.length < 8 ? ref.length : 8)}';
  }
  return key;
}

String _keyFor(ApiException e) {
  if (e.errorCode != null) return e.errorCode!;

  if (e.statusCode == 503 || e.message.contains('unavailable') || e.message.contains('high demand')) {
    return 'AI_PROVIDER_BUSY';
  }
  if (e.statusCode == 401) return 'SESSION_EXPIRED';
  if (e.statusCode == 404) return 'RESOURCE_NOT_FOUND';
  if (e.statusCode == 429) return 'QUOTA_EXCEEDED';

  // Respuestas legacy donde el mensaje venía como JSON anidado
  try {
    final decoded = jsonDecode(e.message);
    if (decoded is Map) {
      if (decoded['error'] is Map) {
        return decoded['error']['message']?.toString() ?? 'errUnknown';
      }
      return decoded['error']?.toString() ?? decoded['message']?.toString() ?? e.message;
    }
  } catch (_) {
    // fire-and-forget: intento de parseo de un formato legacy — si falla, cae al `return e.message` de abajo
  }

  return e.message;
}
