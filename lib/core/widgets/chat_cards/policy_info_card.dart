import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../utils/formatters.dart';
import '../../../l10n/app_localizations.dart';
import 'chat_card_shared.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  POLICY INFO CARD
// ═══════════════════════════════════════════════════════════════════════════════

class PolicyInfoCard extends StatelessWidget {
  const PolicyInfoCard({super.key, required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final carrier = data['carrierName'] as String? ?? '';
    final branch = data['branchName'] as String? ?? '';
    final holder = data['holderName'] as String? ?? '';
    final productName = data['productName'] as String? ?? '';
    final policyNumber = data['policyNumber'] as String? ?? '';
    final contactId = data['contactId'] as String? ?? '';
    final premium = data['premium'];
    final sumInsured = data['sumInsured'];
    final endDate = data['endDate'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AmDimens.cardRadius),
        border: Border.all(color: AmColors.accent.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: AmColors.accent.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AmColors.accent, AmColors.accentBright],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AmDimens.cardRadius - 1),
                topRight: Radius.circular(AmDimens.cardRadius - 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AmDimens.radiusS),
                  ),
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.chatCardPolicyInfoTitle,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (policyNumber.isNotEmpty)
                        Text(
                          '#$policyNumber',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AmDimens.cardPad),
            child: Column(
              children: [
                if (carrier.isNotEmpty)
                  ChatDetailRow(icon: Icons.business_rounded, label: l10n.policiesCarrier, value: carrier),
                if (branch.isNotEmpty)
                  ChatDetailRow(icon: Icons.category_rounded, label: l10n.policiesBranch, value: branch),
                if (productName.isNotEmpty)
                  ChatDetailRow(icon: Icons.inventory_2_rounded, label: l10n.policiesProduct, value: productName),
                if (holder.isNotEmpty)
                  ChatDetailRow(icon: Icons.person_rounded, label: l10n.chatCardFieldInsured, value: holder),
                if (premium != null)
                  ChatDetailRow(
                    icon: Icons.monetization_on_rounded,
                    label: l10n.clientsPolicyPremium,
                    value: fmtCurrency((premium as num?)?.toDouble()),
                  ),
                if (sumInsured != null)
                  ChatDetailRow(
                    icon: Icons.payments_rounded,
                    label: l10n.clientsPolicySumInsured,
                    value: fmtCurrency((sumInsured as num?)?.toDouble()),
                  ),
                if (endDate != null)
                  ChatDetailRow(icon: Icons.calendar_today_rounded, label: l10n.clientsPolicyEndDate, value: fmtDateFromIso(endDate)),
              ],
            ),
          ),
          if (contactId.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(AmDimens.cardPad, 0, AmDimens.cardPad, AmDimens.cardPad),
              child: ChatCardActionButton(
                label: l10n.chatCardViewProfile,
                icon: Icons.person_rounded,
                color: AmColors.accent,
                onTap: () => context.push('/clients/$contactId?fromChat=true'),
              ),
            ),
        ],
      ),
    );
  }

}
