import 'package:amconnect/core/theme/theme.dart';
import 'package:amconnect/features/assistant/widgets/assistant_status_line.dart';
import 'package:amconnect/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra "Pensando…" localizado (es y en)', (tester) async {
    for (final loc in ['es', 'en']) {
      await tester.pumpWidget(MaterialApp(
        theme: AzulProTheme.lightTheme,
        locale: Locale(loc),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (ctx) =>
                AssistantStatusLine(label: AppLocalizations.of(ctx)!.chatThinking),
          ),
        ),
      ));
      await tester.pump();
      expect(find.text(loc == 'es' ? 'Pensando…' : 'Thinking…'), findsOneWidget);
    }
  });
}
