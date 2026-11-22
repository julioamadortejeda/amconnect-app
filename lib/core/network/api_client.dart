import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';
import '../providers/locale_provider.dart';
import '../utils/device_timezone.dart';

/// Código que la app genera cuando la petición no llegó al backend o no
/// regresó (sin red, DNS, TLS, timeout). Lo traduce `error_translator.dart`.
const kConnectionFailedCode = 'CONNECTION_FAILED';

class ApiClient {
  /// [client], [baseUrl] y [headersBuilder] existen para las pruebas: en la app
  /// se usan los defaults (cliente con timeout de conexión, `Env.apiBaseUrl` y
  /// headers con la sesión de Supabase).
  ApiClient({
    http.Client? client,
    String? baseUrl,
    @visibleForTesting Future<Map<String, String>> Function()? headersBuilder,
    String Function()? languageCode,
    this.requestTimeout = const Duration(seconds: 30),
    this.aiRequestTimeout = const Duration(seconds: 150),
    this.uploadTimeout = const Duration(seconds: 120),
  })  : _client = client ?? _defaultClient(),
        _baseOverride = baseUrl,
        _headersBuilder = headersBuilder,
        _languageCode = languageCode;

  final http.Client _client;
  final String? _baseOverride;
  final Future<Map<String, String>> Function()? _headersBuilder;

  /// Idioma de la APP (es|en), el que eligió el asesor en Cuenta, no el del
  /// teléfono. Es el único lugar que arma `Accept-Language` (D-024).
  final String Function()? _languageCode;

  /// Tope para recibir la respuesta completa de una petición normal (CRUD).
  final Duration requestTimeout;

  /// Tope para `ai/*`: chat e ingesta llaman al modelo y tardan decenas de
  /// segundos. 150 s es el límite de una Edge Function de Supabase; esperar
  /// más no sirve porque el gateway ya habrá cortado.
  final Duration aiRequestTimeout;

  /// Tope para subir un archivo a una URL firmada de Storage.
  final Duration uploadTimeout;

  /// Tope para abrir el socket. Sin esto, con red mala `HttpClient` espera lo
  /// que diga el sistema operativo (minutos).
  static const connectTimeout = Duration(seconds: 10);

  static http.Client _defaultClient() =>
      IOClient(HttpClient()..connectionTimeout = connectTimeout);

  String get _base => _baseOverride ?? Env.apiBaseUrl;

  Duration _timeoutFor(String path) =>
      path.startsWith('ai/') ? aiRequestTimeout : requestTimeout;

  /// Margen con el que se considera "por expirar" un access token. El refresh
  /// tarda un round-trip y la petición sale después: sin margen, un token que
  /// vence en dos segundos llega muerto al backend.
  static const _refreshMargin = Duration(seconds: 60);

  Future<Map<String, String>> _buildHeaders() async {
    final override = _headersBuilder;
    if (override != null) return override();
    await _ensureFreshSession();
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final locale = _languageCode?.call() ??
        resolveLanguageCode(null, PlatformDispatcher.instance.locale);
    final appVersion = await _appVersion();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      'x-timezone': DeviceTimezone.name, // IANA real, e.g. "America/Mexico_City"
      'x-timezone-offset': DeviceTimezone.offset,
      'Accept-Language': locale,
      // Versión y plataforma: el backend las guarda como evidencia del consentimiento.
      if (appVersion != null) 'x-app-version': appVersion,
      'x-platform': Platform.isIOS ? 'ios' : 'android',
    };
  }

  static Future<String?>? _appVersionFuture;

  /// "1.4.0+23". Se lee una vez; si falla devuelve null (el header se omite).
  static Future<String?> _appVersion() => _appVersionFuture ??= () async {
        try {
          final info = await PackageInfo.fromPlatform();
          return '${info.version}+${info.buildNumber}';
        } catch (_) {
          return null;
        }
      }();

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
    final res = await _send(
      path,
      (uri, headers) => _client.get(uri, headers: headers),
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) async {
    final res = await _send(
      path,
      (uri, headers) => _client.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
    );
    return _handle(res);
  }

  /// POST que devuelve el cuerpo como stream de bytes (SSE). Mismos headers,
  /// auth y traducción de errores que [post]:
  ///
  /// - fallo de transporte al conectar → `ApiException(CONNECTION_FAILED)`;
  /// - status no 2xx → se lee el JSON de error y se lanza `ApiException`;
  /// - 2xx → stream de bytes. Cancelar su suscripción cierra la conexión.
  ///   Si pasa [idleTimeout] sin recibir bytes, el stream falla con
  ///   `CONNECTION_FAILED` (el backend manda heartbeats, así que silencio
  ///   largo = conexión muerta).
  Future<Stream<List<int>>> postStream(
    String path, {
    Map<String, dynamic>? body,
    Duration? idleTimeout,
  }) async {
    final uri = Uri.parse('$_base/$path');
    final headers = await _buildHeaders();
    headers['Accept'] = 'text/event-stream';
    final request = http.Request('POST', uri)..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);

    // El timeout cubre solo hasta recibir los headers de la respuesta.
    final streamed = await guardTransport(
      () => _client.send(request),
      _timeoutFor(path),
    );
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      final res = await guardTransport(
        () => http.Response.fromStream(streamed),
        _timeoutFor(path),
      );
      throw _toApiException(res);
    }
    final idle = idleTimeout ?? aiRequestTimeout;
    return streamed.stream.timeout(
      idle,
      onTimeout: (sink) {
        sink.addError(_connectionFailed(TimeoutException('sse idle')));
        sink.close();
      },
    ).handleError((Object e) {
      throw e is ApiException ? e : _connectionFailed(e);
    }, test: (e) => e is! ApiException);
  }

  Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? body}) async {
    final res = await _send(
      path,
      (uri, headers) => _client.patch(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
    );
    return _handle(res);
  }

  Future<void> delete(String path, {Map<String, dynamic>? body}) async {
    final res = await _send(
      path,
      (uri, headers) => _client.delete(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw _toApiException(res);
    }
  }

  /// Arma la petición y la ejecuta con timeout. Todo fallo de transporte sale
  /// como `ApiException(CONNECTION_FAILED)`: los providers solo atrapan
  /// `ApiException`, y cualquier otra excepción dejaba el botón girando y
  /// llegaba a Crashlytics como fatal.
  Future<http.Response> _send(
    String path,
    Future<http.Response> Function(Uri uri, Map<String, String> headers) request,
  ) async {
    final uri = Uri.parse('$_base/$path');
    final headers = await _buildHeaders();
    return guardTransport(() => request(uri, headers), _timeoutFor(path));
  }

  /// Ejecuta [request] con [timeout] y convierte los errores de red en
  /// `ApiException(CONNECTION_FAILED)`. Las `ApiException` pasan intactas.
  @visibleForTesting
  static Future<T> guardTransport<T>(
    Future<T> Function() request,
    Duration timeout,
  ) async {
    try {
      return await request().timeout(timeout);
    } on ApiException {
      rethrow;
    } on TimeoutException catch (e) {
      throw _connectionFailed(e);
    } on SocketException catch (e) {
      throw _connectionFailed(e);
    } on HandshakeException catch (e) {
      throw _connectionFailed(e);
    } on TlsException catch (e) {
      throw _connectionFailed(e);
    } on HttpException catch (e) {
      throw _connectionFailed(e);
    } on http.ClientException catch (e) {
      throw _connectionFailed(e);
    }
  }

  static ApiException _connectionFailed(Object cause) {
    // Solo el tipo: el mensaje del sistema puede traer la URL completa.
    debugPrint('[ApiClient] transporte falló: ${cause.runtimeType}');
    return const ApiException(
      statusCode: 0,
      message: kConnectionFailedCode,
      errorCode: kConnectionFailedCode,
    );
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
    final res = await guardTransport(
      () => _client.put(
        Uri.parse(targetUrl),
        headers: {'Content-Type': mimeType},
        body: bytes,
      ),
      uploadTimeout,
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
      final Object? body;
      try {
        body = jsonDecode(res.body);
      } on FormatException {
        // Un 2xx que no es JSON (proxy, portal cautivo de un wifi público).
        // Sin esto el FormatException escapaba de los `on ApiException`.
        throw ApiException(statusCode: res.statusCode, message: 'errUnknown');
      }
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
        message: kConnectionFailedCode,
        errorCode: kConnectionFailedCode,
      );
    }
    // Sin `error` en el cuerpo se guarda una clave que la UI sabe traducir,
    // nunca un texto fijo en español.
    return ApiException(
      statusCode: res.statusCode,
      message: (body is Map ? body['error']?.toString() : null) ?? 'errUnknown',
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

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    // read, no watch: el idioma se consulta en cada petición y cambiarlo no
    // debe recrear el cliente.
    languageCode: () => resolveLanguageCode(
      ref.read(localeProvider),
      PlatformDispatcher.instance.locale,
    ),
  ),
);
