import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_info_row.dart';
import '../../../l10n/app_localizations.dart';

/// Siempre visible (asignado o no) — el toque abre el selector de
/// cliente/póliza y guarda al instante, igual que Type/Status.
class ReminderDetailRelationsSection extends StatelessWidget {
  const ReminderDetailRelationsSection({
    super.key,
    required this.contactId,
    required this.contactName,
    required this.policyId,
    required this.policyNumber,
    this.onTapClient,
    this.onTapPolicy,
  });

  final String? contactId;
  final String? contactName;
  final String? policyId;
  final String? policyNumber;
  final VoidCallback? onTapClient;
  final VoidCallback? onTapPolicy;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AmDimens.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AmColors.shadowSoft,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          AmInfoRow(
            icon: Icons.person_outline,
            label: l10n.remindersFieldClient,
            trailing: Text(
              contactName ?? l10n.remindersNoClientOption,
              style: TextStyle(
                fontSize: 13.5,
                color: contactId != null ? cs.onSurface : cs.tertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            chevron: true,
            onTap: onTapClient,
          ),
          Divider(
            height: 1,
            indent: AmDimens.screenH + 30,
            endIndent: AmDimens.screenH,
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
          AmInfoRow(
            icon: Icons.description_outlined,
            label: l10n.remindersDetailPolicy,
            trailing: Text(
              policyNumber ??
                  (contactId == null
                      ? l10n.remindersPolicyNeedsClient
                      : l10n.remindersNoPolicyOption),
              style: TextStyle(
                fontSize: 13.5,
                color: policyNumber != null ? cs.onSurface : cs.tertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            chevron: true,
            onTap: contactId == null ? null : onTapPolicy,
          ),
        ],
      ),
    );
  }
}
