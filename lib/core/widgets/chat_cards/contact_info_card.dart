import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/am_theme.dart';
import '../../theme/app_dimensions.dart';
import '../../utils/formatters.dart';
import '../../../l10n/app_localizations.dart';
import 'chat_card_shared.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  CONTACT INFO CARD
// ═══════════════════════════════════════════════════════════════════════════════

class ContactInfoCard extends StatelessWidget {
  const ContactInfoCard({super.key, required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    final l10n = AppLocalizations.of(context)!;
    final fullName = data['fullName'] as String? ?? 'Contacto';
    final email = data['email'] as String?;
    final phone = data['phone'] as String?;
    final isProspect = data['isProspect'] as bool? ?? false;
    final contactId = data['contactId'] as String? ?? '';
    final initials = getInitials(fullName);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AmDimens.cardRadius),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
        boxShadow: const [
          BoxShadow(
            color: AmColors.shadowSoft,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AmDimens.cardPad),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isProspect
                          ? [am.amber, AmColors.amberDeep]
                          : [am.green, AmColors.greenBright],
                    ),
                    borderRadius: BorderRadius.circular(AmDimens.radiusM),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isProspect ? am.amberWash : am.greenWash,
                          borderRadius: BorderRadius.circular(AmDimens.radiusXS),
                        ),
                        child: Text(
                          isProspect ? l10n.clientsStatusProspect : l10n.clientsNewClient,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isProspect ? am.amber : am.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (phone != null || email != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AmDimens.cardPad),
              child: Divider(height: 1, color: cs.outline.withValues(alpha: 0.08)),
            ),
            Padding(
              padding: const EdgeInsets.all(AmDimens.cardPad),
              child: Column(
                children: [
                  if (phone != null && phone.isNotEmpty)
                    ChatDetailRow(icon: Icons.phone_rounded, label: l10n.clientsContactSection, value: fmtPhone(phone)),
                  if (email != null && email.isNotEmpty)
                    ChatDetailRow(icon: Icons.email_rounded, label: l10n.chatCardFieldEmail, value: email),
                ],
              ),
            ),
          ],
          if (contactId.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(AmDimens.cardPad, 0, AmDimens.cardPad, AmDimens.cardPad),
              child: ChatCardActionButton(
                label: l10n.chatCardViewProfile,
                icon: Icons.arrow_forward_rounded,
                color: isProspect ? am.amber : am.green,
                onTap: () => context.push('/clients/$contactId?fromChat=true'),
              ),
            ),
        ],
      ),
    );
  }
}
