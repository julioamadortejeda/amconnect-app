import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/reminder.dart';
import '../../../core/theme/am_theme.dart';
import '../../../core/widgets/am_confirm_dialog.dart';
import '../../../core/widgets/am_sheet.dart';
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


    // Dynamically build the action items list
    final items = <Widget>[
      AmSheetTile(
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
      AmSheetTile(
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
        AmSheetTile(
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
        AmSheetTile(
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
      AmSheetTile(
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
        AmSheetTile(
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
            AmSheetHeader(
              title: r.title,
              subtitle: r.sub.isEmpty
                  ? null
                  : (r.time != '—' ? '${r.sub} · ${r.time}' : r.sub),
            ),
            const SizedBox(height: 20),
            ...rows,
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
