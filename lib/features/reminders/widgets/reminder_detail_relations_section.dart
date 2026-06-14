import 'package:flutter/material.dart';
import '../../../core/models/reminder.dart';
import '../../../core/theme/app_dimensions.dart';
import 'reminder_info_row.dart';
import '../../../l10n/app_localizations.dart';

class ReminderDetailRelationsSection extends StatelessWidget {
  const ReminderDetailRelationsSection({
    super.key,
    required this.reminder,
    required this.onTapClient,
  });

  final Reminder reminder;
  final VoidCallback onTapClient;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final r = reminder;

    if (r.policyNumber == null && r.contactId == null) {
      return const SizedBox.shrink();
    }

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
          if (r.policyNumber != null) ...[
            ReminderInfoRow(
              icon: Icons.description_outlined,
              label: l10n.remindersDetailPolicy,
              trailing: Text(
                r.policyNumber!,
                style: TextStyle(fontSize: 13.5, color: cs.onSurface),
              ),
            ),
            if (r.contactId != null)
              Divider(
                height: 1,
                indent: AmDimens.screenH + 30,
                endIndent: AmDimens.screenH,
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
          ],
          if (r.contactId != null)
            ReminderInfoRow(
              icon: Icons.person_outline,
              label: l10n.remindersFieldClient,
              trailing: Text(
                r.contactName ?? r.contactId!,
                style: TextStyle(fontSize: 13.5, color: cs.onSurface),
              ),
              chevron: true,
              onTap: onTapClient,
            ),
        ],
      ),
    );
  }
}
