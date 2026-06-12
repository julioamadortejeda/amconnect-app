import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:amconnect/core/models/reminder.dart';
import 'package:amconnect/core/theme/am_theme.dart';
import 'package:amconnect/core/theme/app_dimensions.dart';
import 'package:amconnect/core/widgets/am_press.dart';
import 'package:amconnect/features/home/providers/home_provider.dart';
import 'package:amconnect/core/utils/reminder_utils.dart';
import 'package:amconnect/l10n/app_localizations.dart';
import 'package:amconnect/core/widgets/am_confirm_dialog.dart';
import 'package:amconnect/core/widgets/am_reschedule_dialog.dart';
import 'package:amconnect/core/widgets/am_cancel_dialog.dart';

class ReminderItem extends ConsumerWidget {
  const ReminderItem({super.key, required this.reminder});

  final Reminder reminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    final l10n = AppLocalizations.of(context)!;
    final r = reminder;

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

    void onReschedule() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (_) => AmRescheduleDialog(
            initialDateTime: r.dueDate ?? DateTime.now().add(const Duration(days: 1)),
            onConfirm: (newDt) {
              ref.read(remindersProvider.notifier).reschedule(r.id, newDt);
            },
          ),
        );
      });
    }

    void onCancel() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (_) => AmCancelDialog(
            title: r.title,
            onConfirm: (comment) {
              ref.read(remindersProvider.notifier).updateStatus(
                    r.id,
                    'CANCELLED',
                    comment: comment,
                  );
            },
          ),
        );
      });
    }

    final content = Opacity(
      opacity: r.done ? 0.55 : 1.0,
      child: AmPress(
        onTap: () {
          if (r.contactId != null) context.push('/clientes/${r.contactId}');
        },
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
                      Text(
                        r.time != '—' ? '${r.sub} · ${r.time}' : r.sub,
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
                      child: Text(r.date,
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

    void showMaterialBottomSheetMenu(BuildContext context) {
      Widget buildGridItem({
        required IconData icon,
        required Color color,
        required String label,
        String? subtitle,
        required VoidCallback onTap,
      }) {
        return Expanded(
          child: Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            color: cs.surfaceVariant.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: 26),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 9.5,
                            color: cs.error,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }

      showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        backgroundColor: cs.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    r.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (r.sub.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      r.time != '—' ? '${r.sub} · ${r.time}' : r.sub,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: cs.tertiary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      buildGridItem(
                        icon: CupertinoIcons.checkmark_circle,
                        color: am.green,
                        label: l10n.remindersActionDone,
                        onTap: () {
                          Navigator.pop(ctx);
                          showDialog(
                            context: context,
                            builder: (_) => AmConfirmDialog(
                              title: l10n.remindersConfirmDoneTitle,
                              message: l10n.remindersConfirmDoneMessage,
                              confirmLabel: l10n.remindersConfirmDoneBtn,
                              cancelLabel: l10n.remindersConfirmCancelBtn,
                              icon: Icons.check,
                              iconBgColor: am.greenWash,
                              iconFgColor: am.green,
                              onConfirm: () {
                                ref
                                    .read(remindersProvider.notifier)
                                    .updateStatus(r.id, 'DONE');
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      buildGridItem(
                        icon: CupertinoIcons.clock,
                        color: am.amber,
                        label: l10n.remindersActionInProgress,
                        onTap: () {
                          Navigator.pop(ctx);
                          showDialog(
                            context: context,
                            builder: (_) => AmConfirmDialog(
                              title: l10n.remindersConfirmInProgressTitle,
                              message: l10n.remindersConfirmInProgressMessage,
                              confirmLabel: l10n.remindersConfirmInProgressBtn,
                              cancelLabel: l10n.remindersConfirmCancelBtn,
                              icon: Icons.access_time_filled_rounded,
                              iconBgColor: am.amberWash,
                              iconFgColor: am.amber,
                              onConfirm: () {
                                ref
                                    .read(remindersProvider.notifier)
                                    .updateStatus(r.id, 'IN_PROGRESS');
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      buildGridItem(
                        icon: CupertinoIcons.calendar,
                        color: cs.primary,
                        label: l10n.remindersActionReschedule,
                        onTap: () {
                          Navigator.pop(ctx);
                          onReschedule();
                        },
                      ),
                      const SizedBox(width: 12),
                      buildGridItem(
                        icon: CupertinoIcons.xmark_circle,
                        color: cs.error,
                        label: l10n.remindersActionCancel,
                        subtitle: l10n.remindersActionCommentRequired,
                        onTap: () {
                          Navigator.pop(ctx);
                          onCancel();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => showMaterialBottomSheetMenu(context),
      child: content,
    );
  }
}
