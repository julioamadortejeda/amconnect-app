import 'package:amconnect/core/utils/api_error_mapper.dart';
import 'package:amconnect/core/utils/error_translator.dart';
import 'package:amconnect/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<BuildContext> _pump(WidgetTester tester, Locale locale) async {
  late BuildContext ctx;
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(builder: (c) {
      ctx = c;
      return const SizedBox();
    }),
  ));
  return ctx;
}

void main() {
  for (final locale in const [Locale('es'), Locale('en')]) {
    testWidgets('toda clave de kTranslatedErrorKeys se traduce ($locale)', (tester) async {
      final ctx = await _pump(tester, locale);
      for (final key in kTranslatedErrorKeys) {
        final t = ctx.translateError(key);
        expect(t, isNot(key), reason: '$key no tiene traducción en el switch');
        expect(t, isNotEmpty);
      }
    });
  }

  testWidgets('RATE_LIMITED (límite por minuto) no se confunde con la cuota mensual', (tester) async {
    final ctx = await _pump(tester, const Locale('es'));
    expect(ctx.translateError('RATE_LIMITED'), 'Vas muy rápido, espera un momento e intenta de nuevo.');
    expect(ctx.translateError('RATE_LIMITED'), isNot(ctx.translateError('QUOTA_EXCEEDED')));
  });

  testWidgets('texto desconocido se muestra tal cual', (tester) async {
    final ctx = await _pump(tester, const Locale('es'));
    expect(ctx.translateError('El comentario es obligatorio'), 'El comentario es obligatorio');
  });

  testWidgets('CONNECTION_FAILED con referencia', (tester) async {
    final ctx = await _pump(tester, const Locale('es'));
    final l10n = AppLocalizations.of(ctx)!;
    expect(
      ctx.translateError('CONNECTION_FAILED${kErrRefSeparator}abc'),
      '${l10n.errNetwork}\n${l10n.errRefCode('abc')}',
    );
  });
}
