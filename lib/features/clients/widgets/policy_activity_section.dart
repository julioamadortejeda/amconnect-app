import 'package:flutter/material.dart';
import '../../../core/models/reminder.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/reminder_utils.dart';
import '../../../core/widgets/am_form_row.dart';
import '../../../core/widgets/am_group_card.dart';
import '../../../core/widgets/am_section_label.dart';
import '../../../l10n/app_localizations.dart';
import '../../reminders/widgets/reminder_item.dart';

/// Bitácora de la póliza: sus recordatorios de pago, renovación y aniversario,
/// abiertos primero y cerrados después.
///
/// Es la trazabilidad de pagos — cada renglón lleva al detalle del recordatorio,
/// donde vive el comentario que dejó el asesor ("Juan dijo que paga en 15 días").
class PolicyActivitySection extends StatelessWidget {
  const PolicyActivitySection({super.key, required this.reminders});

  final List<Reminder> reminders;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final upcoming = reminders.where((r) => r.isActive).toList()
      ..sort(compareReminderDueDate);
    // El historial va del más reciente hacia atrás: lo último que pasó, arriba.
    final history = reminders.where((r) => !r.isActive).toList()
      ..sort((a, b) => compareReminderDueDate(b, a));

    if (upcoming.isEmpty && history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AmDimens.gapM),
        child: Text(
          l10n.policiesActivityEmpty,
          style: TextStyle(fontSize: 13.5, color: cs.tertiary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (upcoming.isNotEmpty) ...[
          _SubLabel(text: l10n.policiesActivityUpcoming),
          AmGroupCard(children: _rows(upcoming)),
        ],
        if (history.isNotEmpty) ...[
          if (upcoming.isNotEmpty) const SizedBox(height: AmDimens.gapM),
          _SubLabel(text: l10n.policiesActivityHistory),
          AmGroupCard(children: _rows(history)),
        ],
      ],
    );
  }

  List<Widget> _rows(List<Reminder> items) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) rows.add(const AmFormDivider());
      rows.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: AmDimens.gapXS),
        child: ReminderItem(reminder: items[i]),
      ));
    }
    return rows;
  }
}

class _SubLabel extends StatelessWidget {
  const _SubLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AmDimens.gapXS),
        child: AmSectionLabel(label: text),
      );
}
