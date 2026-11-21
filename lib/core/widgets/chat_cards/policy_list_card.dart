import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../am_press.dart';
import '../../../l10n/app_localizations.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  POLICY LIST CARD
// ═══════════════════════════════════════════════════════════════════════════════

class PolicyListCard extends StatelessWidget {
  const PolicyListCard({super.key, required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final policiesRaw = data['policies'] as List? ?? [];

    if (policiesRaw.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AmDimens.cardPad),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AmDimens.cardRadius),
        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
        boxShadow: const [
          BoxShadow(
            color: AmColors.shadowSoft,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: cs.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                l10n.chatCardPolicyListTitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: AmDimens.gapS),
          ...policiesRaw.map((p) {
            if (p is! Map<String, dynamic>) return const SizedBox.shrink();
            final id = p['id'] as String?;
            final policyNumber = p['policyNumber'] as String? ?? l10n.shareTargetPolicyNoNumber;
            final holderName = p['holderName'] as String? ?? '';
            final carrierName = p['carrierName'] as String? ?? '';
            final branchName = p['branchName'] as String? ?? '';
            final productName = p['productName'] as String? ?? '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: AmPress(
                onTap: id != null && id.isNotEmpty
                    ? () => context.push('/policy/$id')
                    : null,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AmDimens.radiusM),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(AmDimens.radiusS),
                        ),
                        child: Icon(Icons.description_outlined,
                            size: 18, color: cs.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              policyNumber.isNotEmpty
                                  ? policyNumber
                                  : l10n.shareTargetPolicyNoNumber,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              [
                                if (holderName.isNotEmpty) holderName,
                                if (carrierName.isNotEmpty) carrierName,
                                if (branchName.isNotEmpty || productName.isNotEmpty)
                                  (branchName.isNotEmpty ? branchName : productName),
                              ].join(' · '),
                              style:
                                  TextStyle(fontSize: 11.5, color: cs.tertiary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.chevron_right_rounded,
                          size: 18, color: cs.tertiary),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
