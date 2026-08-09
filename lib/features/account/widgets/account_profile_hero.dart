import 'package:flutter/material.dart';
import '../../../core/models/agent_profile.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_avatar.dart';
import '../../../core/widgets/am_form_row.dart';
import '../../../core/widgets/am_group_card.dart';
import '../../../core/widgets/am_info_row.dart';
import '../../../core/widgets/am_press.dart';
import '../../../l10n/app_localizations.dart';

class AccountProfileHero extends StatelessWidget {
  const AccountProfileHero({
    super.key,
    required this.profile,
    required this.editing,
    required this.nameCtrl,
    required this.phoneCtrl,
    this.onEdit,
  });

  final AgentProfile profile;
  final bool editing;
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return AmGroupCard(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
            AmDimens.screenH, AmDimens.cardPad, AmDimens.screenH, AmDimens.gapM),
        child: Row(
          children: [
            AmAvatar(initials: profile.initials, color: cs.primary, size: 52, radius: 16),
            const SizedBox(width: AmDimens.gapM),
            Expanded(
              child: editing
                  ? TextField(
                      controller: nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: l10n.fieldFullName,
                        hintStyle: TextStyle(color: cs.tertiary.withValues(alpha: 0.55)),
                      ),
                    )
                  : Text(
                      profile.fullName,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
            ),
            if (!editing && onEdit != null) ...[
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                child: AmPress(
                  onTap: onEdit,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                            l10n.accountEdit,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      const AmFormDivider(),
      AmInfoRow(
        icon: Icons.email_outlined,
        label: l10n.fieldEmail,
        trailing: Text(
          profile.email,
          style: TextStyle(fontSize: 13.5, color: cs.onSurface),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      const AmFormDivider(),
      editing
          ? AmFormRow(
              label: l10n.fieldPhone,
              controller: phoneCtrl,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textCapitalization: TextCapitalization.none,
            )
          : AmInfoRow(
              icon: Icons.phone_outlined,
              label: l10n.fieldPhone,
              trailing: Text(
                profile.phone?.isNotEmpty == true ? profile.phone! : '—',
                style: TextStyle(fontSize: 13.5, color: cs.onSurface),
              ),
            ),
    ]);
  }
}
