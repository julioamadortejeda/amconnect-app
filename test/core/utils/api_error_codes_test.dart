import 'package:amconnect/core/network/api_client.dart';
import 'package:amconnect/core/utils/api_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('todo código conocido del backend se conserva tal cual (la UI lo traduce)', () {
    final codes = kTranslatedErrorKeys.where((k) => k == k.toUpperCase());
    expect(codes, isNotEmpty);
    for (final code in codes) {
      expect(
        mapApiError(ApiException(statusCode: 400, message: 'texto del backend', errorCode: code)),
        code,
        reason: code,
      );
    }
  });

  test('código nuevo y desconocido muestra el mensaje del backend, no el código', () {
    expect(
      mapApiError(const ApiException(statusCode: 422, message: 'Falta el RFC', errorCode: 'RFC_REQUIRED')),
      'Falta el RFC',
    );
  });

  test('el código de referencia se abrevia a 8 caracteres y respeta ids cortos', () {
    expect(
      mapApiError(const ApiException(
          statusCode: 500, message: 'x', errorCode: 'AI_ERROR', errorId: 'abc')),
      'AI_ERROR${kErrRefSeparator}abc',
    );
  });
}
