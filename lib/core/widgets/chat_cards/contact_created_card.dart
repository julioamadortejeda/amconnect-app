import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/am_theme.dart';
import '../../theme/app_dimensions.dart';
import '../../utils/formatters.dart';
import '../../../l10n/app_localizations.dart';
import 'chat_card_shared.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  CONTACT CREATED CARD
// ═══════════════════════════════════════════════════════════════════════════════

class ContactCreatedCard extends StatelessWidget {
  const ContactCreatedCard({super.key, required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    final l10n = AppLocalizations.of(context)!;
    final fullName = data['fullName'] as String? ?? l10n.chatCardContactFallback;
    final email = data['email'] as String?;
    final phone = data['phone'] as String?;
    final isProspect = data['isProspect'] as bool? ?? false;
    final contactId = data['contactId'] as String? ?? '';

    // Initials
    final initials = getInitials(fullName);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AmDimens.radiusL),
        border: Border.all(color: am.green.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: am.green.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                // Avatar with gradient initials
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isProspect
                          ? [am.amber, AmColors.amberDeep]
                          : [am.green, AmColors.greenBright],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: (isProspect ? am.amber : am.green).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
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
                      const SizedBox(height: 3),
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
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.check_circle_rounded, color: am.green, size: 22),
              ],
            ),
          ),

          // ── Contact details ─────────────────────────────────────
          if (phone != null || email != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Column(
                children: [
                  if (phone != null)
                    ChatDetailRow(icon: Icons.phone_rounded, label: l10n.chatCardFieldPhone, value: phone),
                  if (email != null)
                    ChatDetailRow(icon: Icons.email_rounded, label: l10n.chatCardFieldEmail, value: email),
                ],
              ),
            ),

          // ── Action ──────────────────────────────────────────────
          if (contactId.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: ChatCardActionButton(
                label: l10n.chatCardViewProfile,
                icon: Icons.arrow_forward_rounded,
                color: am.green,
                onTap: () => context.push('/clients/$contactId?fromChat=true'),
              ),
            ),
        ],
      ),
    );
  }
}
