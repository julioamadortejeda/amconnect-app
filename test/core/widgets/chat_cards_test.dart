import 'package:amconnect/core/theme/theme.dart';
import 'package:amconnect/core/widgets/chat_cards.dart';
import 'package:amconnect/core/widgets/chat_cards/attachment_list_card.dart';
import 'package:amconnect/core/widgets/chat_cards/contact_created_card.dart';
import 'package:amconnect/core/widgets/chat_cards/contact_info_card.dart';
import 'package:amconnect/core/widgets/chat_cards/policy_confirmed_card.dart';
import 'package:amconnect/core/widgets/chat_cards/policy_info_card.dart';
import 'package:amconnect/core/widgets/chat_cards/policy_list_card.dart';
import 'package:amconnect/core/widgets/chat_cards/reminder_created_card.dart';
import 'package:amconnect/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Monta lo que devuelve `buildChatCard` dentro de la app mínima que las
/// tarjetas necesitan (tema con `AmTheme`, l10n, Riverpod).
Future<void> _pumpCard(WidgetTester tester, Map<String, dynamic> metadata) async {
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(
      theme: AzulProTheme.lightTheme,
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Builder(builder: (ctx) => buildChatCard(metadata, ctx) ?? const Text('NO_CARD')),
        ),
      ),
    ),
  ));
  await tester.pump();
}

void main() {
  test('buildChatCard devuelve null para un tipo desconocido o ausente', () {
    // No necesita contexto real: el switch no lo usa para tipos desconocidos.
    expect(buildChatCard({'type': 'nope'}, _FakeContext()), isNull);
    expect(buildChatCard(const {}, _FakeContext()), isNull);
  });

  test('listas vacías no dibujan tarjeta', () {
    for (final e in {
      'reminder_list': 'reminders',
      'policy_list': 'policies',
      'contact_list': 'contacts',
      'attachment_list': 'attachments',
    }.entries) {
      expect(buildChatCard({'type': e.key, e.value: []}, _FakeContext()), isNull);
      expect(buildChatCard({'type': e.key}, _FakeContext()), isNull);
    }
  });

  testWidgets('policy_list con elementos sí dibuja tarjeta', (tester) async {
    await _pumpCard(tester, {
      'type': 'policy_list',
      'policies': [
        {'id': 'p1', 'policyNumber': 'X1'}
      ],
    });
    expect(find.byType(PolicyListCard), findsOneWidget);
  });

  testWidgets('attachment_list con elementos sí dibuja tarjeta', (tester) async {
    await _pumpCard(tester, {
      'type': 'attachment_list',
      'attachments': [
        {'fileName': 'a.pdf'}
      ],
    });
    expect(find.byType(AttachmentListCard), findsOneWidget);
  });

  group('buildChatCard elige la tarjeta correcta', () {
    final cases = <String, Type>{
      'policy_confirmed': PolicyConfirmedCard,
      'policy_updated': PolicyConfirmedCard,
      'contact_created': ContactCreatedCard,
      'reminder_created': ReminderCreatedCard,
      'contact_info': ContactInfoCard,
      'policy_info': PolicyInfoCard,
    };
    cases.forEach((type, widgetType) {
      testWidgets(type, (tester) async {
        await _pumpCard(tester, {'type': type});
        expect(find.byType(widgetType), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  });

  testWidgets('PolicyConfirmedCard pinta aseguradora y número de póliza', (tester) async {
    await _pumpCard(tester, {
      'type': 'policy_confirmed',
      'carrierName': 'Aseguradora Test',
      'branchName': 'Autos',
      'holderName': 'Ana Pérez',
      'policyNumber': 'POL-123',
      'policyId': 'p1',
    });
    expect(find.textContaining('POL-123'), findsWidgets);
    expect(find.textContaining('Aseguradora Test'), findsWidgets);
    expect(find.textContaining('Ana Pérez'), findsWidgets);
  });

  testWidgets('ContactCreatedCard pinta nombre, correo y teléfono', (tester) async {
    await _pumpCard(tester, {
      'type': 'contact_created',
      'fullName': 'Luis Gómez',
      'email': 'luis@test.com',
      'phone': '5512345678',
      'contactId': 'c1',
    });
    expect(find.textContaining('Luis Gómez'), findsWidgets);
    expect(find.textContaining('luis@test.com'), findsWidgets);
    expect(find.textContaining('55 1234 5678'), findsWidgets);
  });

  testWidgets('ReminderCreatedCard pinta el título del recordatorio', (tester) async {
    await _pumpCard(tester, {
      'type': 'reminder_created',
      'title': 'Llamar a Luis',
      'clientName': 'Luis Gómez',
    });
    expect(find.textContaining('Llamar a Luis'), findsWidgets);
    expect(find.textContaining('Luis Gómez'), findsWidgets);
  });
}

class _FakeContext extends Fake implements BuildContext {}
