import 'package:amconnect/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fmtPhone', () {
    test('null y vacío → cadena vacía', () {
      expect(fmtPhone(null), '');
      expect(fmtPhone(''), '');
      expect(fmtPhone('   '), '');
    });

    test('México con +52, ladas 55/33/81 en 2-4-4', () {
      expect(fmtPhone('+525512340011'), '+52 55 1234 0011');
      expect(fmtPhone('+523312345678'), '+52 33 1234 5678');
      expect(fmtPhone('+528112345678'), '+52 81 1234 5678');
    });

    test('México con otras ladas en 3-3-4', () {
      expect(fmtPhone('+522221234567'), '+52 222 123 4567');
    });

    test('prefijo móvil legacy +521 se descarta', () {
      expect(fmtPhone('+5215512340011'), '+52 55 1234 0011');
      expect(fmtPhone('+5212221234567'), '+52 222 123 4567');
    });

    test('10 dígitos sin país', () {
      expect(fmtPhone('5512340011'), '55 1234 0011');
      expect(fmtPhone('2221234567'), '222 123 4567');
    });

    test('ignora espacios, guiones, puntos y paréntesis', () {
      expect(fmtPhone('+52 (55) 1234-0011'), '+52 55 1234 0011');
      expect(fmtPhone('(222) 123.4567'), '222 123 4567');
      expect(fmtPhone('  55-1234-0011 '), '55 1234 0011');
    });

    test('EE. UU./Canadá', () {
      expect(fmtPhone('+14155550123'), '+1 415 555 0123');
      expect(fmtPhone('+1 (415) 555-0123'), '+1 415 555 0123');
    });

    test('otros formatos se devuelven igual (recortados)', () {
      expect(fmtPhone('+34612345678'), '+34612345678');
      expect(fmtPhone(' +44 20 7946 0958 '), '+44 20 7946 0958');
      expect(fmtPhone('5512340011 ext 5'), '5512340011 ext 5');
      expect(fmtPhone('55123'), '55123');
      expect(fmtPhone('+52551234'), '+52551234');
      expect(fmtPhone('abc'), 'abc');
    });
  });
}
