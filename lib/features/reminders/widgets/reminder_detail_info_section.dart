import 'package:flutter/material.dart';
import '../../../core/models/reminder.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/am_theme.dart';
import '../../../core/utils/catalog_l10n.dart';
import '../../../core/utils/formatters.dart';
import 'reminder_info_row.dart';
import 'reminder_status_chip.dart';
import 'reminder_type_chip.dart';
import '../../../l10n/app_localizations.dart';

class ReminderDetailInfoSection extends StatelessWidget {
  const ReminderDetailInfoSection({
    super.key,
    required this.reminder,
    this.onTapType,
    this.onTapStatus,
    this.onTapReschedule,
  });

  final Reminder reminder;
  final VoidCallback? onTapType;
  final VoidCallback? onTapStatus;
  final VoidCallback? onTapReschedule;

  static String _fmtDate(DateTime? dt) => fmtDateWithWeekday(dt);
  static String _fmtTime(DateTime? dt) => fmtTime(dt, fallback: '');

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

    final dateStr = _fmtDate(r.dueDate);
    final timeStr = _fmtTime(r.dueDate);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AmDimens.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          ReminderInfoRow(
            icon: Icons.category_outlined,
            label: l10n.remindersFieldType,
            trailing: ReminderTypeChip(
              label: l10n.reminderType(r.type),
              fg: iconFg,
              bg: iconBg,
            ),
            chevron: true,
            onTap: onTapType,
          ),
          Divider(
            height: 1,
            indent: AmDimens.screenH + 30,
            endIndent: AmDimens.screenH,
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
          ReminderInfoRow(
            icon: Icons.radio_button_checked_outlined,
            label: l10n.remindersDetailStatus,
            trailing: ReminderStatusChip(statusCode: r.statusCode),
            chevron: true,
            onTap: onTapStatus,
          ),
          Divider(
            height: 1,
            indent: AmDimens.screenH + 30,
            endIndent: AmDimens.screenH,
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
          ReminderInfoRow(
            icon: Icons.calendar_today_outlined,
            label: l10n.remindersDetailDueDate,
            trailing: Text(
              timeStr.isNotEmpty ? '$dateStr · $timeStr' : dateStr,
              style: TextStyle(fontSize: 13.5, color: cs.onSurface),
              textAlign: TextAlign.right,
            ),
            chevron: true,
            onTap: onTapReschedule,
          ),
          Divider(
            height: 1,
            indent: AmDimens.screenH + 30,
            endIndent: AmDimens.screenH,
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
          ReminderInfoRow(
            icon: Icons.access_time_outlined,
            label: l10n.remindersDetailCreatedAt,
            trailing: Text(
              _fmtDate(r.createdAt),
              style: TextStyle(fontSize: 13.5, color: cs.tertiary),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
