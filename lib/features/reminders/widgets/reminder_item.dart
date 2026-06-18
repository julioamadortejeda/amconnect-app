import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/reminder.dart';
import '../../../core/theme/am_theme.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_press.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/reminder_utils.dart';
import '../../../l10n/app_localizations.dart';
import 'am_reminder_actions_sheet.dart';

class ReminderItem extends ConsumerWidget {
  const ReminderItem({
    super.key,
    required this.reminder,
    this.showContextMenu = true,
  });

  final Reminder reminder;
  final bool showContextMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    final l10n = AppLocalizations.of(context)!;
    final r = reminder;

    final statusText = switch (r.statusCode) {
      'CREATED'     => l10n.reminderStatusCreated,
      'IN_PROGRESS' => l10n.reminderStatusInProgress,
      'PAUSED'      => l10n.reminderStatusPaused,
      'DONE'        => l10n.reminderStatusDone,
      'CANCELLED'   => l10n.reminderStatusCancelled,
      _             => null,
    };

    final statusColor = switch (r.statusCode) {
      'CREATED'     => cs.tertiary,
      'IN_PROGRESS' => am.amber,
      'PAUSED'      => cs.tertiary,
      'DONE'        => am.green,
      'CANCELLED'   => cs.error,
      _             => null,
    };

    final (iconFg, iconBg, badgeBg, badgeFg) = switch (r.priority) {
      ReminderPriority.urgent => (
          cs.error,
          cs.errorContainer,
          cs.errorContainer.withValues(alpha: 0.7),
          cs.error
        ),
      ReminderPriority.warning => (
          am.amber,
          am.amberWash,
          am.amberWash.withValues(alpha: 0.7),
          am.amber
        ),
      ReminderPriority.normal => (
          cs.primary,
          cs.primaryContainer,
          cs.primaryContainer.withValues(alpha: 0.7),
          cs.primary
        ),
    };

    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final daysLeft = r.dueDate != null
        ? DateTime(r.dueDate!.year, r.dueDate!.month, r.dueDate!.day)
            .difference(todayKey)
            .inDays
        : null;

    final bool hasSub = (r.time != '—' || r.sub.isNotEmpty);
    final String mainSub = r.time != '—'
        ? (r.sub.isNotEmpty ? '${r.sub} · ${r.time}' : r.time)
        : r.sub;

    final content = Opacity(
      opacity: r.done ? 0.55 : 1.0,
      child: AmPress(
        onTap: () => context.push('/reminder/${r.id}', extra: r),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AmDimens.screenH, AmDimens.gapS, AmDimens.screenH, AmDimens.gapS),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: iconBg, borderRadius: BorderRadius.circular(11)),
                child: Icon(reminderIcon(r.type), size: 18, color: iconFg),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                          decoration:
                              r.done ? TextDecoration.lineThrough : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            if (statusText != null) ...[
                              TextSpan(
                                  text: statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w600,
                                  )),
                              if (hasSub)
                                TextSpan(
                                  text: '  ·  ',
                                  style: TextStyle(color: cs.outlineVariant),
                                ),
                            ],
                            TextSpan(text: mainSub),
                          ],
                        ),
                        style: TextStyle(fontSize: 12.5, color: cs.tertiary),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(fmtSmartDate(r.dueDate, l10n),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: badgeFg)),
                    ),
                    if (daysLeft != null && daysLeft != 0) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${daysLeft}d',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: badgeFg)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: showContextMenu
          ? () {
              showModalBottomSheet(
                context: context,
                useRootNavigator: true,
                backgroundColor: cs.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) => AmReminderActionsSheet(
                  reminder: r,
                  showReschedule: true,
                ),
              );
            }
          : null,
      child: content,
    );
  }
}
