import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/reminder.dart';
import '../../../core/theme/am_theme.dart';
import '../../../core/widgets/am_confirm_dialog.dart';
import '../../../core/widgets/am_reschedule_dialog.dart';
import '../../../core/widgets/am_cancel_dialog.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/providers/home_provider.dart';

class AmReminderActionsSheet extends ConsumerWidget {
  const AmReminderActionsSheet({
    super.key,
    required this.reminder,
    this.showReschedule = true,
  });

  final Reminder reminder;
  final bool showReschedule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    final l10n = AppLocalizations.of(context)!;
    final r = reminder;
    // Capturar el notifier aquí, antes de cualquier pop/dismiss,
    // para usarlo de forma segura en closures asíncronos (dialogs).
    final notifier = ref.read(remindersProvider.notifier);

    void onReschedule() {
      showDialog(
        context: context,
        builder: (_) => AmRescheduleDialog(
          initialDateTime: r.dueDate ?? DateTime.now().add(const Duration(days: 1)),
          onConfirm: (newDt) {
            notifier.reschedule(r.id, newDt);
          },
        ),
      );
    }

    void onCancel() {
      showDialog(
        context: context,
        builder: (_) => AmCancelDialog(
          title: r.title,
          onConfirm: (comment) {
            notifier.updateStatus(r.id, 'CANCELLED', comment: comment);
          },
        ),
      );
    }

    void onPause() {
      notifier.updateStatus(r.id, 'PAUSED');
    }

    void onResetToCreated() {
      notifier.updateStatus(r.id, 'CREATED');
    }

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
          color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
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

    // Dynamically build the action items list
    final items = <Widget>[
      buildGridItem(
        icon: CupertinoIcons.checkmark_circle,
        color: am.green,
        label: l10n.remindersActionDone,
        onTap: () {
          Navigator.pop(context);
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
              onConfirm: () => notifier.updateStatus(r.id, 'DONE'),
            ),
          );
        },
      ),
      buildGridItem(
        icon: CupertinoIcons.clock,
        color: am.amber,
        label: l10n.remindersActionInProgress,
        onTap: () {
          Navigator.pop(context);
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
              onConfirm: () => notifier.updateStatus(r.id, 'IN_PROGRESS'),
            ),
          );
        },
      ),
    ];

    if (showReschedule) {
      items.add(
        buildGridItem(
          icon: CupertinoIcons.calendar,
          color: cs.primary,
          label: l10n.remindersActionReschedule,
          onTap: () {
            Navigator.pop(context);
            onReschedule();
          },
        ),
      );
    }

    if (r.statusCode != 'PAUSED') {
      items.add(
        buildGridItem(
          icon: CupertinoIcons.pause_circle,
          color: cs.tertiary,
          label: l10n.reminderStatusPaused,
          onTap: () {
            Navigator.pop(context);
            onPause();
          },
        ),
      );
    }

    items.add(
      buildGridItem(
        icon: CupertinoIcons.xmark_circle,
        color: cs.error,
        label: l10n.remindersActionCancel,
        subtitle: l10n.remindersActionCommentRequired,
        onTap: () {
          Navigator.pop(context);
          onCancel();
        },
      ),
    );

    if (r.statusCode != 'CREATED') {
      items.add(
        buildGridItem(
          icon: CupertinoIcons.arrow_counterclockwise,
          color: cs.secondary,
          label: l10n.reminderStatusCreated,
          onTap: () {
            Navigator.pop(context);
            onResetToCreated();
          },
        ),
      );
    }

    // Chunk list into pairs to render as rows
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      final item1 = items[i];
      final item2 = (i + 1 < items.length) ? items[i + 1] : null;
      if (rows.isNotEmpty) {
        rows.add(const SizedBox(height: 12));
      }
      rows.add(
        Row(
          children: [
            item1,
            if (item2 != null) ...[
              const SizedBox(width: 12),
              item2,
            ] else ...[
              const SizedBox(width: 12),
              const Spacer(),
            ],
          ],
        ),
      );
    }

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
            ...rows,
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
