import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';

class ApiClient {
  String get _base => Env.apiBaseUrl;

  Map<String, String> get _headers {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    // Compute timezone offset string (e.g., "-06:00")
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final tzOffset = '$sign$hours:$minutes';
    // Use the IANA timezone name when available, fall back to offset
    final tzName = now.timeZoneName; // e.g. "CST" or "America/Mexico_City"
    final locale = Platform.localeName; // e.g. "es_MX"
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      'x-timezone': tzName,
      'x-timezone-offset': tzOffset,
      'Accept-Language': locale,
    };
  }

  Future<Map<String, dynamic>> get(String path) async {
    final res = await http.get(Uri.parse('$_base/$path'), headers: _headers);
    return _handle(res);
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) async {
    final res = await http.post(
      Uri.parse('$_base/$path'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> patch(String path, {Map<String, dynamic>? body}) async {
    final res = await http.patch(
      Uri.parse('$_base/$path'),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handle(res);
  }

  Future<void> delete(String path) async {
    final res = await http.delete(Uri.parse('$_base/$path'), headers: _headers);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final body = jsonDecode(res.body);
      throw ApiException(
        statusCode: res.statusCode,
        message: (body is Map ? body['error']?.toString() : null) ?? 'Error desconocido',
      );
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
      throw ApiException(statusCode: res.statusCode, message: 'Error al subir archivo');
    }
  }

  Map<String, dynamic> _handle(http.Response res) {
    final body = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body is Map<String, dynamic> ? body : {'data': body};
    }
    throw ApiException(
      statusCode: res.statusCode,
      message: (body is Map ? body['error']?.toString() : null) ?? 'Error desconocido',
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException({required this.statusCode, required this.message});
  @override
  String toString() => 'ApiException($statusCode): $message';
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
