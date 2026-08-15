import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';
import '../utils/device_timezone.dart';

class ApiClient {
  String get _base => Env.apiBaseUrl;

  /// Margen con el que se considera "por expirar" un access token. El refresh
  /// tarda un round-trip y la petición sale después: sin margen, un token que
  /// vence en dos segundos llega muerto al backend.
  static const _refreshMargin = Duration(seconds: 60);

  Future<Map<String, String>> _buildHeaders() async {
    await _ensureFreshSession();
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final locale = Platform.localeName; // e.g. "es_MX"
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      'x-timezone': DeviceTimezone.name, // IANA real, e.g. "America/Mexico_City"
      'x-timezone-offset': DeviceTimezone.offset,
      'Accept-Language': locale,
    };
  }

  /// Renueva el access token si ya venció o está por vencer.
  ///
  /// El SDK de Supabase refresca con un temporizador que solo corre con la app
  /// viva. iOS la suspende en segundo plano y el temporizador se detiene, así
  /// que al despertar desde una notificación la sesión en memoria puede estar
  /// vencida: la pantalla dispara su petición antes de que el SDK alcance a
  /// refrescar. Esa carrera era el 401 SESSION_EXPIRED intermitente al abrir un
  /// recordatorio desde un push.
  ///
  /// `refreshSession` deduplica llamadas concurrentes internamente
  /// (`_refreshTokenCompleter`), así que no hace falta un candado aquí.
  Future<void> _ensureFreshSession() async {
    final auth = Supabase.instance.client.auth;
    final session = auth.currentSession;
    if (session == null) return;

    // Sin `expiresAt` no hay forma de saberlo; se asume vigente, igual que
    // hace `Session.isExpired`.
    final expiresAt = session.expiresAt;
    if (expiresAt == null) return;

    final expiry = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
    if (expiry.isAfter(DateTime.now().add(_refreshMargin))) return;

    try {
      await auth.refreshSession();
    } on AuthRetryableFetchException {
      // Sin red o backend caído. La sesión NO se toca: el token puede seguir
      // siendo válido y desloguear a alguien por estar en el metro sería peor
      // que el 401. Esta rama va antes que AuthException a propósito —
      // AuthRetryableFetchException hereda de ella.
    } on AuthException {
      // El refresh token caducó (días sin abrir la app) o fue revocado: no hay
      // nada que renovar. Cerramos sesión para que el router redirija a /login,
      // en vez de dejar la pantalla con un 401 del que no se puede salir.
      try {
        await auth.signOut();
      } catch (_) {
        // Si ni el signOut sale, la petición seguirá y fallará con 401.
      }
    }
  }

  Future<Map<String, dynamic>> get(String path) async {
    final res = await http.get(Uri.parse('$_base/$path'), headers: await _buildHeaders());
    return _handle(res);
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) async {
    final res = await http.post(
      Uri.parse('$_base/$path'),
      headers: await _buildHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? body}) async {
    final res = await http.patch(
      Uri.parse('$_base/$path'),
      headers: await _buildHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handle(res);
  }

  Future<void> delete(String path, {Map<String, dynamic>? body}) async {
    final res = await http.delete(
      Uri.parse('$_base/$path'),
      headers: await _buildHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw _toApiException(res);
    }
  }

  /// PUT sin Authorization — para URLs firmadas de Supabase Storage.
  Future<void> putFile(String signedUrl, File file, String mimeType) async {
    String targetUrl = signedUrl;
    try {
      final supabaseUri = Uri.parse(Env.supabaseUrl);
      final signedUri = Uri.parse(signedUrl);
      if (signedUri.host == '127.0.0.1' || signedUri.host == 'localhost' || signedUri.host == 'kong') {
        targetUrl = signedUri.replace(
          scheme: supabaseUri.scheme,
          host: supabaseUri.host,
          port: supabaseUri.port,
        ).toString();
      }
    } catch (e) {
      // Si falla el parsing por alguna razón, conservamos la URL original
      targetUrl = signedUrl;
    }

    final bytes = await file.readAsBytes();
    final res = await http.put(
      Uri.parse(targetUrl),
      headers: {'Content-Type': mimeType},
      body: bytes,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        statusCode: res.statusCode,
        message: 'UPLOAD_FAILED',
        errorCode: 'UPLOAD_FAILED',
      );
    }
  }

  Map<String, dynamic> _handle(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final body = jsonDecode(res.body);
      return body is Map<String, dynamic> ? body : {'data': body};
    }
    throw _toApiException(res);
  }

  /// Construye la excepción a partir de la respuesta de error del backend.
  /// Contrato: `{ success: false, error: <msg>, errorCode: <CODE>, errorId?: <uuid> }`.
  /// Si el body no es JSON (ej: HTML de un gateway caído), se trata como
  /// error de conexión en lugar de crashear con FormatException.
  ApiException _toApiException(http.Response res) {
    Object? body;
    try {
      body = jsonDecode(res.body);
    } catch (_) {
      return ApiException(
        statusCode: res.statusCode,
        message: 'CONNECTION_FAILED',
        errorCode: 'CONNECTION_FAILED',
      );
    }
    return ApiException(
      statusCode: res.statusCode,
      message: (body is Map ? body['error']?.toString() : null) ?? 'Error desconocido',
      errorCode: body is Map ? body['errorCode']?.toString() : null,
      errorId: body is Map ? body['errorId']?.toString() : null,
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? errorCode;

  /// UUID del registro en `error_logs` del backend (si el error fue persistido).
  /// Se muestra abreviado al usuario como "código de referencia" para soporte.
  final String? errorId;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.errorCode,
    this.errorId,
  });

  @override
  String toString() => 'ApiException($statusCode): $message (Code: $errorCode, Ref: $errorId)';
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
