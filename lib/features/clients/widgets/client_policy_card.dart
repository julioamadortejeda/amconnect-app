import 'package:flutter/material.dart';
import '../../../core/models/policy.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/am_card.dart';
import '../../../core/widgets/am_ramo_icon.dart';
import '../../../l10n/app_localizations.dart';

class ClientPolicyCard extends StatelessWidget {
  const ClientPolicyCard({super.key, required this.policy});

  final Policy policy;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isActive = policy.statusCode == 'ACTIVE';

    return AmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AmRamoIcon(ramo: policy.branchName, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      policy.productName,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _carrierAndNumber(policy),
                      style: TextStyle(fontSize: 12.5, color: cs.tertiary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF0E7C42).withValues(alpha: 0.08)
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? l10n.clientsPolicyActive : policy.statusCode,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isActive ? const Color(0xFF0E7C42) : cs.tertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _DataCell(
                      label: l10n.clientsPolicySumInsured,
                      value: fmtCurrency(policy.sumInsured),
                    ),
                    _DataCell(
                      label: l10n.clientsPolicyPremium,
                      value: fmtPremium(policy.premium, policy.frequencyLabel),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _DataCell(
                      label: l10n.clientsPolicyNextPayment,
                      value: fmtDateFromIso(policy.nextPaymentDate),
                    ),
                    _DataCell(
                      label: l10n.clientsPolicyDeductible,
                      value: policy.deductible ?? '—',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _carrierAndNumber(Policy p) {
    final parts = <String>[
      if (p.carrierName.isNotEmpty && p.carrierName != '—') p.carrierName,
      if (p.policyNumber?.isNotEmpty == true) p.policyNumber!,
    ];
    return parts.join(' · ');
  }
}

class _DataCell extends StatelessWidget {
  const _DataCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: cs.tertiary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
