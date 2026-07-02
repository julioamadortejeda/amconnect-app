import 'package:flutter/material.dart';
import '../../../core/models/subscription_info.dart';
import '../../../core/theme/am_theme.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/am_badge.dart';
import '../../../l10n/app_localizations.dart';

class AccountPlanCard extends StatelessWidget {
  const AccountPlanCard({super.key, required this.info});

  final SubscriptionInfo info;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    final l10n = AppLocalizations.of(context)!;

    final (statusLabel, statusTone) = switch (info.status) {
      'trial' => (l10n.accountPlanStatusTrial, AmBadgeTone.accent),
      'active' => (l10n.accountPlanStatusActive, AmBadgeTone.green),
      'expired' => (l10n.accountPlanStatusExpired, AmBadgeTone.red),
      'cancelled' => (l10n.accountPlanStatusCancelled, AmBadgeTone.red),
      _ => (info.status, AmBadgeTone.muted),
    };

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
              Expanded(
                child: Text(
                  info.plan.name,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
                ),
              ),
              AmBadge(label: statusLabel, tone: statusTone),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.accountPlanPrice(fmtCurrency(info.plan.priceMxn)),
            style: TextStyle(fontSize: 14, color: cs.tertiary),
          ),
          if (info.status == 'trial' && info.trialDaysRemaining != null) ...[
            const SizedBox(height: AmDimens.gapXS),
            Text(
              l10n.accountTrialDaysLeft(info.trialDaysRemaining!),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: am.amber),
            ),
          ],
          const SizedBox(height: AmDimens.gapM),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
          const SizedBox(height: AmDimens.gapM),
          _UsageRow(
            label: l10n.accountUsageChatLabel,
            used: info.usage.chatMessages,
            limit: info.plan.limits.chatMessagesMonthly,
          ),
          const SizedBox(height: AmDimens.gapS),
          _UsageRow(
            label: l10n.accountUsageIngestionsLabel,
            used: info.usage.ingestions,
            limit: info.plan.limits.ingestionsMonthly,
          ),
        ],
      ),
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({required this.label, required this.used, required this.limit});

  final String label;
  final int used;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final ratio = limit > 0 ? (used / limit).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 13.5, color: cs.onSurfaceVariant)),
            Text(
              l10n.accountUsageFormat(used, limit),
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: cs.onSurface),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: cs.secondaryContainer,
            valueColor: AlwaysStoppedAnimation(cs.primary),
          ),
        ),
      ],
    );
  }
}
