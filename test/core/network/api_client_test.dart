import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:amconnect/core/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ApiClient _client(
  MockClientHandler handler, {
  Duration requestTimeout = const Duration(seconds: 5),
  Duration aiRequestTimeout = const Duration(seconds: 5),
}) =>
    ApiClient(
      client: MockClient(handler),
      baseUrl: 'https://api.test',
      headersBuilder: () async => {'Content-Type': 'application/json'},
      requestTimeout: requestTimeout,
      aiRequestTimeout: aiRequestTimeout,
    );

Matcher _isConnectionFailed() => isA<ApiException>()
    .having((e) => e.errorCode, 'errorCode', kConnectionFailedCode)
    .having((e) => e.statusCode, 'statusCode', 0);

void main() {
  group('ApiClient: errores de transporte → CONNECTION_FAILED', () {
    test('SocketException (sin red)', () async {
      final api = _client((_) async => throw const SocketException('down'));
      await expectLater(api.get('contacts'), throwsA(_isConnectionFailed()));
    });

    test('ClientException', () async {
      final api = _client((_) async => throw http.ClientException('reset'));
      await expectLater(api.post('reminders', body: {}), throwsA(_isConnectionFailed()));
    });

    test('HandshakeException', () async {
      final api = _client((_) async => throw const HandshakeException('tls'));
      await expectLater(api.patch('reminders/1'), throwsA(_isConnectionFailed()));
    });

    test('delete también se protege', () async {
      final api = _client((_) async => throw const SocketException('down'));
      await expectLater(api.delete('contacts/1'), throwsA(_isConnectionFailed()));
    });

    test('timeout de respuesta', () async {
      final api = _client(
        (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          return http.Response('{}', 200);
        },
        requestTimeout: const Duration(milliseconds: 20),
      );
      await expectLater(api.get('contacts'), throwsA(_isConnectionFailed()));
    });

    test('ai/* usa el timeout largo', () async {
      final api = _client(
        (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 60));
          return http.Response('{"data":{"ok":true}}', 200);
        },
        requestTimeout: const Duration(milliseconds: 20),
        aiRequestTimeout: const Duration(seconds: 2),
      );
      final res = await api.post('ai/chat', body: {'message': 'hola'});
      expect(res['data'], {'ok': true});
    });
  });

  group('ApiClient: respuestas del backend', () {
    test('error del contrato se conserva', () async {
      final api = _client((_) async => http.Response(
            jsonEncode({
              'success': false,
              'error': 'No existe',
              'errorCode': 'RESOURCE_NOT_FOUND',
              'errorId': 'abcdef1234',
            }),
            404,
          ));
      await expectLater(
        api.get('reminders/x'),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 404)
            .having((e) => e.errorCode, 'errorCode', 'RESOURCE_NOT_FOUND')
            .having((e) => e.message, 'message', 'No existe')
            .having((e) => e.errorId, 'errorId', 'abcdef1234')),
      );
    });

    test('error no-JSON (gateway caído) → CONNECTION_FAILED', () async {
      final api = _client((_) async => http.Response('<html>502</html>', 502));
      await expectLater(
        api.get('contacts'),
        throwsA(isA<ApiException>()
            .having((e) => e.errorCode, 'errorCode', kConnectionFailedCode)),
      );
    });

    test('2xx que no es JSON → ApiException, no FormatException', () async {
      final api = _client((_) async => http.Response('<html>portal</html>', 200));
      await expectLater(api.get('contacts'), throwsA(isA<ApiException>()));
    });

    test('lista en la raíz se envuelve en data', () async {
      final api = _client((_) async => http.Response('[1,2]', 200));
      expect(await api.get('x'), {'data': [1, 2]});
    });
  });

  test('guardTransport deja pasar ApiException intacta', () async {
    const original = ApiException(statusCode: 409, message: 'm', errorCode: 'RESOURCE_CONFLICT');
    await expectLater(
      ApiClient.guardTransport<void>(() async => throw original, const Duration(seconds: 1)),
      throwsA(same(original)),
    );
  });

  test('guardTransport convierte TimeoutException', () async {
    await expectLater(
      ApiClient.guardTransport<void>(
          () async => throw TimeoutException('t'), const Duration(seconds: 1)),
      throwsA(_isConnectionFailed()),
    );
  });
}
