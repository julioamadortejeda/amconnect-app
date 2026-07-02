import 'package:flutter/material.dart';
import '../../../core/models/agent_profile.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_avatar.dart';
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

    return Container(
      padding: const EdgeInsets.all(AmDimens.cardPad),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AmDimens.cardRadius),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AmAvatar(initials: profile.initials, color: cs.primary, size: 56, radius: 18),
              const SizedBox(width: AmDimens.gapM),
              Expanded(
                child: editing
                    ? TextField(
                        controller: nameCtrl,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: l10n.fieldFullName,
                          hintStyle: TextStyle(color: cs.tertiary),
                        ),
                      )
                    : Text(
                        profile.fullName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: AmDimens.gapM),
          Row(
            children: [
              Icon(Icons.email_outlined, size: 16, color: cs.tertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  profile.email,
                  style: TextStyle(fontSize: 14, color: cs.tertiary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AmDimens.gapS),
          Row(
            children: [
              Icon(Icons.phone_outlined, size: 16, color: cs.tertiary),
              const SizedBox(width: 8),
              Expanded(
                child: editing
                    ? TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(fontSize: 14, color: cs.onSurface),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: l10n.fieldPhone,
                          hintStyle: TextStyle(color: cs.tertiary),
                        ),
                      )
                    : Text(
                        profile.phone?.isNotEmpty == true ? profile.phone! : '—',
                        style: TextStyle(fontSize: 14, color: cs.onSurface),
                      ),
              ),
            ],
          ),
          if (!editing) ...[
            const SizedBox(height: AmDimens.gapS),
            Align(
              alignment: Alignment.centerRight,
              child: AmPress(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
