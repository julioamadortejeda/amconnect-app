import 'package:amconnect/core/models/reminder.dart';
import 'package:amconnect/core/theme/theme.dart';
import 'package:amconnect/features/reminders/widgets/reminder_item.dart';
import 'package:amconnect/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Reminder reminder) async {
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(
      theme: AzulProTheme.lightTheme,
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: ReminderItem(reminder: reminder, showContextMenu: false)),
    ),
  ));
  await tester.pump();
}

Map<String, dynamic> _json({
  required String title,
  Map<String, dynamic>? contact,
  Map<String, dynamic>? policy,
  String? description,
}) =>
    {
      'id': 'r-1',
      'title': title,
      'description': description,
      'dueDate': '2026-11-23T06:00:00+00:00',
      'type': {'id': 't', 'code': 'PAYMENT', 'name': 'Payment'},
      'status': {'id': 's', 'code': 'CREATED', 'name': 'Created'},
      'contactId': contact?['id'],
      'contact': contact,
      'policyId': policy?['id'],
      'policy': policy,
    };

void main() {
  testWidgets('automático (D-023): muestra al cliente una vez y no repite el número de póliza', (tester) async {
    await _pump(
      tester,
      Reminder.fromJson(_json(
        title: 'Pago · ALFA MEDICAL INTEGRO · Rosa Martínez Hernández',
        contact: {'id': 'c-1', 'fullName': 'Rosa Martínez Hernández'},
        policy: {'id': 'p-1', 'policyNumber': 'GMM-2026-10451'},
      )),
    );
    expect(find.text('Pago · ALFA MEDICAL INTEGRO · Rosa Martínez Hernández'), findsOneWidget);
    expect(find.text('Rosa Martínez Hernández'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.text('GMM-2026-10451'), findsNothing);
    expect(find.byIcon(Icons.description_outlined), findsNothing);
  });

  testWidgets('sin cliente, el número de póliza sigue como dato secundario', (tester) async {
    await _pump(
      tester,
      Reminder.fromJson(_json(
        title: 'Revisar endoso',
        policy: {'id': 'p-1', 'policyNumber': 'GMM-2026-10451'},
      )),
    );
    expect(find.text('GMM-2026-10451'), findsOneWidget);
    expect(find.byIcon(Icons.description_outlined), findsOneWidget);
  });
}
