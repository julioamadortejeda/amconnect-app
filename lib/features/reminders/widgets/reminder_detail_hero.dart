import 'package:flutter/material.dart';
import '../../../core/models/reminder.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/am_theme.dart';
import '../../../core/utils/reminder_utils.dart';
import '../../../core/utils/catalog_l10n.dart';
import '../../../core/widgets/am_press.dart';
import '../../../l10n/app_localizations.dart';

class ReminderDetailHero extends StatelessWidget {
  const ReminderDetailHero({
    super.key,
    required this.reminder,
    required this.editing,
    required this.titleCtrl,
    required this.descCtrl,
    required this.onEdit,
  });

  final Reminder reminder;
  final bool editing;
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    final l10n = AppLocalizations.of(context)!;
    final r = reminder;

    final (iconFg, iconBg) = switch (r.priority) {
      ReminderPriority.urgent => (cs.error, cs.errorContainer),
      ReminderPriority.warning => (am.amber, am.amberWash),
      ReminderPriority.normal => (cs.primary, cs.primaryContainer),
    };

    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final daysLeft = r.dueDate != null
        ? DateTime(r.dueDate!.year, r.dueDate!.month, r.dueDate!.day)
            .difference(todayKey)
            .inDays
        : null;
    final daysLabel = daysLeft == null
        ? null
        : daysLeft == 0
            ? l10n.calendarToday
            : daysLeft == 1
                ? l10n.remindersDetailTomorrow
                : daysLeft < 0
                    ? l10n.remindersDetailDaysOverdue(-daysLeft)
                    : l10n.remindersDetailDaysLeft(daysLeft);

    final priorityLabel = switch (r.priority) {
      ReminderPriority.urgent => l10n.reminderPriorityUrgent,
      ReminderPriority.warning => l10n.reminderPriorityWarning,
      ReminderPriority.normal => null,
    };

    return Container(
      padding: const EdgeInsets.all(AmDimens.cardPad),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AmDimens.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  children: [
                    Icon(reminderIcon(r.type), size: 14, color: iconFg),
                    const SizedBox(width: 5),
                    Text(
                      l10n.reminderType(r.type),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: iconFg,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (priorityLabel != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    priorityLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: iconFg,
                    ),
                  ),
                ),
                const SizedBox(width: AmDimens.gapXS),
              ],
              if (daysLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    daysLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: iconFg,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AmDimens.gapS),
          editing
              ? TextField(
                  controller: titleCtrl,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    letterSpacing: -0.02,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: l10n.remindersFieldTitle,
                    hintStyle: TextStyle(color: cs.tertiary),
                  ),
                )
              : Text(
                  r.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    letterSpacing: -0.02,
                  ),
                ),
          const SizedBox(height: AmDimens.gapXS),
          editing
              ? TextField(
                  controller: descCtrl,
                  minLines: 2,
                  maxLines: 5,
                  style: TextStyle(fontSize: 14.5, color: cs.onSurface),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: l10n.remindersDetailNoDescription,
                    hintStyle: TextStyle(color: cs.tertiary),
                  ),
                )
              : Text(
                  r.description?.isNotEmpty == true
                      ? r.description!
                      : l10n.remindersDetailNoDescription,
                  style: TextStyle(
                    fontSize: 14.5,
                    color: r.description?.isNotEmpty == true
                        ? cs.onSurface
                        : cs.tertiary,
                  ),
                ),
          if (!editing) ...[
            const SizedBox(height: AmDimens.gapS),
            Align(
              alignment: Alignment.centerRight,
              child: AmPress(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined, size: 13, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        l10n.remindersDetailEdit,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
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
