import 'package:flutter/material.dart';
import '../../../core/models/reminder.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/reminder_utils.dart';
import '../../../core/widgets/am_section_label.dart';
import '../../../core/widgets/am_stagger.dart';
import '../../../l10n/app_localizations.dart';
import 'reminder_item.dart';

const _kBucketOrder = [
  ReminderDateBucket.overdue,
  ReminderDateBucket.today,
  ReminderDateBucket.tomorrow,
  ReminderDateBucket.thisWeek,
  ReminderDateBucket.later,
];

String _bucketLabel(ReminderDateBucket bucket, AppLocalizations l10n) =>
    switch (bucket) {
      ReminderDateBucket.overdue => l10n.remindersGroupOverdue,
      ReminderDateBucket.today => l10n.calendarToday,
      ReminderDateBucket.tomorrow => l10n.remindersDetailTomorrow,
      ReminderDateBucket.thisWeek => l10n.remindersGroupThisWeek,
      ReminderDateBucket.later => l10n.remindersGroupLater,
    };

/// Agenda agrupada por cercanía a hoy (Vencidos/Hoy/Mañana/Esta
/// semana/Más adelante) — reemplaza la lista plana para que el asesor
/// ubique de un vistazo en qué día está parado cada recordatorio, en vez
/// de tener que releer el badge de fecha de cada fila una por una.
class ReminderGroupedList extends StatelessWidget {
  const ReminderGroupedList({super.key, required this.reminders});

  final List<Reminder> reminders;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final grouped = groupRemindersByDateBucket(reminders);
    final sections =
        _kBucketOrder.where((b) => grouped[b]?.isNotEmpty == true).toList();

    var aniIdx = 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AmDimens.screenH, 0, AmDimens.screenH, AmDimens.scrollBottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final bucket in sections) ...[
            if (bucket != sections.first)
              const SizedBox(height: AmDimens.gapM),
            AmAnimateIn(
              index: (aniIdx++).clamp(0, 10),
              child: AmSectionLabel(label: _bucketLabel(bucket, l10n)),
            ),
            const SizedBox(height: AmDimens.gapXS),
            AmAnimateIn(
              index: (aniIdx++).clamp(0, 10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(AmDimens.cardRadius),
                  boxShadow: AmShadows.card,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AmDimens.cardRadius),
                  child: Column(
                    children: [
                      for (int i = 0; i < grouped[bucket]!.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 0,
                            indent: AmDimens.screenH,
                            endIndent: AmDimens.screenH,
                            color: cs.outlineVariant,
                          ),
                        ReminderItem(reminder: grouped[bucket]![i]),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
