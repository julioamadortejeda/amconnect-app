import 'package:flutter/material.dart';
import '../../../core/theme/am_theme.dart';
import '../../../l10n/app_localizations.dart';

class ReminderStatusChip extends StatelessWidget {
  const ReminderStatusChip({super.key, required this.statusCode});

  final String statusCode;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    final l10n = AppLocalizations.of(context)!;

    final (label, color) = switch (statusCode) {
      'DONE'        => (l10n.reminderStatusDone,       am.green),
      'IN_PROGRESS' => (l10n.reminderStatusInProgress, am.amber),
      'CANCELLED'   => (l10n.reminderStatusCancelled,  cs.error),
      'PAUSED'      => (l10n.reminderStatusPaused,     cs.tertiary),
      'CREATED'     => (l10n.reminderStatusCreated,    cs.onSurfaceVariant),
      _             => (l10n.reminderStatusCreated,    cs.onSurfaceVariant),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12.5, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
