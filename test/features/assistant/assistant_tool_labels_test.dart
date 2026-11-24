import 'dart:ui';
import 'package:amconnect/features/assistant/models/assistant_tool_labels.dart';
import 'package:amconnect/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final es = lookupAppLocalizations(const Locale('es'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('nombre conocido -> etiqueta localizada (es y en)', () {
    expect(resolveToolLabel(es, 'search_contact', 'x'), 'Buscando contacto…');
    expect(resolveToolLabel(en, 'search_contact', 'x'), 'Looking up contact…');
    expect(resolveToolLabel(es, 'reschedule_reminder', null), 'Moviendo la cita…');
    expect(resolveToolLabel(en, 'recall', null), 'Searching your notes…');
    expect(resolveToolLabel(en, 'get_expiring_policies', null), 'Checking policies…');
  });

  test('nombre desconocido -> genérico', () {
    expect(resolveToolLabel(es, 'nueva_tool', 'Algo'), 'Trabajando…');
    expect(resolveToolLabel(en, 'nueva_tool', 'Algo'), 'Working…');
  });

  test('sin nombre -> etiqueta del backend; sin nada -> genérico', () {
    expect(resolveToolLabel(en, null, 'Buscando contacto'), 'Buscando contacto');
    expect(resolveToolLabel(en, '', 'Buscando contacto'), 'Buscando contacto');
    expect(resolveToolLabel(en, null, null), 'Working…');
  });
}
