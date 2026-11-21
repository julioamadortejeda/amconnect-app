import 'package:amconnect/core/models/agent_profile.dart';
import 'package:amconnect/core/repositories/agent_repository.dart';
import 'package:amconnect/core/repositories/supabase_agent_repository.dart';
import 'package:amconnect/core/widgets/am_check_row.dart';
import 'package:amconnect/features/onboarding/widgets/auth_submit_btn.dart';
import 'package:amconnect/features/privacy/presentation/privacy_consent_screen.dart';
import 'package:amconnect/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repo implements AgentRepository {
  @override
  Future<AgentProfile> getMe() async => const AgentProfile(
      id: '1',
      fullName: 'Ana',
      email: 'a@x.com',
      plan: 'trial',
      isActive: true,
      privacy: PrivacyConsent(currentVersion: 'v1', url: '', required: true));

  @override
  Future<void> updateLocale(String locale) async {}

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  testWidgets('muestra las dos casillas y el botón se habilita con ambas', (tester) async {
    // Pantalla de teléfono real: con 800x600 las casillas quedan fuera de vista.
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(
      overrides: [agentRepositoryProvider.overrideWithValue(_Repo())],
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: PrivacyConsentScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    final rows = find.byType(AmCheckRow);
    expect(rows, findsNWidgets(2));
    bool enabled() => tester.widget<AuthSubmitBtn>(find.byType(AuthSubmitBtn)).enabled;
    expect(enabled(), isFalse);

    await tester.ensureVisible(rows.at(0));
    await tester.pumpAndSettle();
    await tester.tap(rows.at(0));
    await tester.pump();
    expect(enabled(), isFalse);
    await tester.ensureVisible(rows.at(1));
    await tester.pumpAndSettle();
    await tester.tap(rows.at(1));
    await tester.pump();
    expect(enabled(), isTrue);
  });
}
