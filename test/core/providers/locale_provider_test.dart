import 'dart:ui';
import 'package:amconnect/core/providers/locale_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolveLanguageCode', () {
    expect(resolveLanguageCode(null, const Locale('es', 'MX')), 'es');
    expect(resolveLanguageCode(null, const Locale('en', 'US')), 'en');
    expect(resolveLanguageCode(const Locale('en'), const Locale('es')), 'en');
    expect(resolveLanguageCode(null, const Locale('fr')), 'en');
  });
}
