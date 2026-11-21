import 'package:amconnect/core/network/api_client.dart';
import 'package:amconnect/core/utils/api_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mapApiError', () {
    test('código conocido → el código', () {
      expect(
        mapApiError(const ApiException(statusCode: 0, message: 'x', errorCode: 'CONNECTION_FAILED')),
        'CONNECTION_FAILED',
      );
    });

    test('código desconocido → el mensaje del backend, no el código', () {
      expect(
        mapApiError(const ApiException(
          statusCode: 400,
          message: 'El comentario es obligatorio',
          errorCode: 'CANCEL_COMMENT_REQUIRED',
        )),
        'El comentario es obligatorio',
      );
    });

    test('código desconocido sin mensaje → errUnknown', () {
      expect(
        mapApiError(const ApiException(statusCode: 400, message: ' ', errorCode: 'NEW_CODE')),
        'errUnknown',
      );
    });

    test('sin código: se infiere por status', () {
      expect(mapApiError(const ApiException(statusCode: 401, message: 'x')), 'SESSION_EXPIRED');
      expect(mapApiError(const ApiException(statusCode: 404, message: 'x')), 'RESOURCE_NOT_FOUND');
      expect(mapApiError(const ApiException(statusCode: 429, message: 'x')), 'QUOTA_EXCEEDED');
      expect(mapApiError(const ApiException(statusCode: 503, message: 'x')), 'AI_PROVIDER_BUSY');
    });

    test('sin código ni status conocido → mensaje tal cual', () {
      expect(mapApiError(const ApiException(statusCode: 400, message: 'Algo pasó')), 'Algo pasó');
    });

    test('adjunta la referencia abreviada', () {
      expect(
        mapApiError(const ApiException(
          statusCode: 500,
          message: 'x',
          errorCode: 'INTERNAL_ERROR',
          errorId: '1234567890abcdef',
        )),
        'INTERNAL_ERROR${kErrRefSeparator}12345678',
      );
    });

    test('cualquier otra excepción → errUnknown', () {
      expect(mapApiError(StateError('boom')), 'errUnknown');
      expect(mapApiError(const FormatException('x')), 'errUnknown');
    });
  });
}
