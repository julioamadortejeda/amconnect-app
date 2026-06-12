import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:amconnect/core/models/reminder.dart';
import 'package:amconnect/core/theme/am_theme.dart';
import 'package:amconnect/core/theme/app_dimensions.dart';
import 'package:amconnect/core/widgets/am_press.dart';
import 'package:amconnect/features/home/providers/home_provider.dart';
import 'package:amconnect/features/reminders/widgets/reminder_comment_sheet.dart';
import 'package:amconnect/l10n/app_localizations.dart';

IconData reminderIcon(String tipo) => switch (tipo) {
      'PAYMENT'      => Icons.payments_outlined,
      'RENEWAL'      => Icons.autorenew,
      'CANCELLATION' => Icons.block,
      'FOLLOW_UP'    => Icons.flag_outlined,
      'CALL'         => Icons.phone_outlined,
      'APPOINTMENT'  => Icons.event_outlined,
      'ANNIVERSARY'  => Icons.cake,
      _              => Icons.notifications_outlined,
    };

enum ReminderMenuType {
  contextMenu, // Original CupertinoContextMenu
  actionSheet, // CupertinoActionSheet on long press
  bottomSheet, // Custom premium Material 3 bottom sheet
}

// TOGGLE MENU TYPE HERE:
const _menuType = ReminderMenuType.bottomSheet;

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
      ReminderPriority.urgent  => (cs.error,    cs.errorContainer,   cs.errorContainer.withValues(alpha: 0.7),   cs.error),
      ReminderPriority.warning => (am.amber,    am.amberWash,        am.amberWash.withValues(alpha: 0.7),        am.amber),
      ReminderPriority.normal  => (cs.primary,  cs.primaryContainer, cs.primaryContainer.withValues(alpha: 0.7), cs.primary),
    };

    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final daysLeft = r.dueDate != null
        ? DateTime(r.dueDate!.year, r.dueDate!.month, r.dueDate!.day)
            .difference(todayKey)
            .inDays
        : null;

    void onReschedule() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!context.mounted) return;
        final initial = r.dueDate ?? DateTime.now().add(const Duration(days: 1));
        final date = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
        );
        if (date == null || !context.mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(initial),
        );
        if (!context.mounted) return;
        final dt = DateTime(
          date.year, date.month, date.day,
          time?.hour ?? initial.hour,
          time?.minute ?? initial.minute,
        );
        ref.read(remindersProvider.notifier).reschedule(r.id, dt);
      });
    }

    void onCancel() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: cs.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (ctx) => ReminderCommentSheet(
            title: r.titulo,
            onConfirm: (comment) {
              Navigator.pop(ctx);
              ref.read(remindersProvider.notifier).updateStatus(
                r.id, 'CANCELLED', comment: comment,
              );
            },
          ),
        );
      });
    }

    final content = Opacity(
      opacity: r.hecho ? 0.55 : 1.0,
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
                child: Icon(reminderIcon(r.tipo), size: 18, color: iconFg),
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
                        r.titulo,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface,
                          decoration: r.hecho ? TextDecoration.lineThrough : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        r.hora != '—' ? '${r.sub} · ${r.hora}' : r.sub,
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
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(r.fecha,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: badgeFg)),
                    ),
                    if (daysLeft != null && daysLeft != 0) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${daysLeft}d',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant)),
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

    void showActionSheetMenu(BuildContext context) {
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: Text(r.titulo),
          message: r.sub.isNotEmpty ? Text(r.hora != '—' ? '${r.sub} · ${r.hora}' : r.sub) : null,
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(remindersProvider.notifier).updateStatus(r.id, 'DONE');
              },
              child: Text(l10n.remindersActionDone),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(remindersProvider.notifier).updateStatus(r.id, 'IN_PROGRESS');
              },
              child: Text(l10n.remindersActionInProgress),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                onReschedule();
              },
              child: Text(l10n.remindersActionReschedule),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(ctx);
                onCancel();
              },
              child: Text(l10n.remindersActionCancel),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: Text(l10n.remindersActionCancel),
            onPressed: () {
              Navigator.pop(ctx);
            },
          ),
        ),
      );
    }

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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
                    r.titulo,
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
                      r.hora != '—' ? '${r.sub} · ${r.hora}' : r.sub,
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
                          ref.read(remindersProvider.notifier).updateStatus(r.id, 'DONE');
                        },
                      ),
                      const SizedBox(width: 12),
                      buildGridItem(
                        icon: CupertinoIcons.clock,
                        color: am.amber,
                        label: l10n.remindersActionInProgress,
                        onTap: () {
                          Navigator.pop(ctx);
                          ref.read(remindersProvider.notifier).updateStatus(r.id, 'IN_PROGRESS');
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

    if (_menuType == ReminderMenuType.actionSheet) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () => showActionSheetMenu(context),
        child: content,
      );
    }

    if (_menuType == ReminderMenuType.bottomSheet) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () => showMaterialBottomSheetMenu(context),
        child: content,
      );
    }

    final actions = [
      CupertinoContextMenuAction(
        onPressed: () {
          Navigator.pop(context);
          ref.read(remindersProvider.notifier).updateStatus(r.id, 'DONE');
        },
        trailingIcon: CupertinoIcons.checkmark_circle,
        child: Text(l10n.remindersActionDone),
      ),
      CupertinoContextMenuAction(
        onPressed: () {
          Navigator.pop(context);
          ref.read(remindersProvider.notifier).updateStatus(r.id, 'IN_PROGRESS');
        },
        trailingIcon: CupertinoIcons.clock,
        child: Text(l10n.remindersActionInProgress),
      ),
      CupertinoContextMenuAction(
        onPressed: () {
          Navigator.pop(context);
          onReschedule();
        },
        trailingIcon: CupertinoIcons.calendar,
        child: Text(l10n.remindersActionReschedule),
      ),
      CupertinoContextMenuAction(
        isDestructiveAction: true,
        onPressed: () {
          Navigator.pop(context);
          onCancel();
        },
        trailingIcon: CupertinoIcons.xmark_circle,
        child: Text(l10n.remindersActionCancel),
      ),
    ];

    return CupertinoContextMenu.builder(
      actions: actions,
      builder: (ctx, animation) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Color.lerp(Colors.transparent, cs.surface, animation.value),
            borderRadius: BorderRadius.circular(16 * animation.value),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: content,
          ),
        );
      },
    );
  }
}
