import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_card.dart';
import '../../../core/widgets/am_loader.dart';
import '../../../core/widgets/am_top_bar.dart';
import '../../clients/providers/clients_provider.dart';
import '../../../l10n/app_localizations.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final contactsAsync = ref.watch(clientsProvider);
    final policiesAsync = ref.watch(policiesProvider);

    if (contactsAsync.isLoading || policiesAsync.isLoading) {
      return const Scaffold(
        appBar: AmTopBar(
          title: '',
          showBack: true,
        ),
        body: Center(child: AmLoader()),
      );
    }

    final contacts = contactsAsync.asData?.value ?? [];
    final policies = policiesAsync.asData?.value ?? [];

    // 1. Funnel Calculations
    final prospectsCount = contacts.where((c) => c.isProspect).length;
    final clientsCount = contacts.where((c) => !c.isProspect).length;
    final totalContacts = contacts.length;
    final closeRate = totalContacts > 0 ? (clientsCount / totalContacts * 100).round() : 0;

    // 2. Policy Status Calculations
    int activeCount = 0;
    int pendingCount = 0;
    int expiredCount = 0;

    for (final p in policies) {
      final code = p.statusCode.toUpperCase();
      if (code == 'ACTIVE') {
        activeCount++;
      } else if (code == 'PENDING' || code == 'IN_PROGRESS' || code == 'UNDERWRITING' || code == 'IN_FLOW') {
        pendingCount++;
      } else {
        expiredCount++;
      }
    }

    // 3. Branch & Carrier Distribution
    final branchCounts = <String, int>{};
    final carrierCounts = <String, int>{};

    for (final p in policies) {
      final branch = p.branchName;
      if (branch.isNotEmpty && branch != '—') {
        branchCounts[branch] = (branchCounts[branch] ?? 0) + 1;
      }
      final carrier = p.carrierName;
      if (carrier.isNotEmpty && carrier != '—') {
        carrierCounts[carrier] = (carrierCounts[carrier] ?? 0) + 1;
      }
    }

    final sortedBranches = branchCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedCarriers = carrierCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalBranchPolicies = branchCounts.values.fold<int>(0, (sum, val) => sum + val);
    final totalCarrierPolicies = carrierCounts.values.fold<int>(0, (sum, val) => sum + val);

    return Scaffold(
      appBar: AmTopBar(
        title: l10n.analyticsTitle,
        showBack: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AmDimens.screenH,
            vertical: 12.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Funnel section
              Text(
                l10n.analyticsFunnelTitle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: AmDimens.gapS),
              AmCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _MetricRow(
                            dotColor: cs.tertiary,
                            label: l10n.analyticsFunnelProspects,
                            value: prospectsCount.toString(),
                          ),
                          const SizedBox(height: 12),
                          _MetricRow(
                            dotColor: AmColors.accent,
                            label: l10n.analyticsFunnelClients,
                            value: clientsCount.toString(),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 52,
                      color: cs.outlineVariant,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '$closeRate%',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AmColors.accent,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          l10n.analyticsFunnelRate,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: cs.tertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AmDimens.gapM),

              // Policy status section
              Text(
                l10n.analyticsPolicyStatus,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: AmDimens.gapS),
              Row(
                children: [
                  Expanded(
                    child: _StatusCard(
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: cs.primary,
                      bgColor: cs.primaryContainer.withValues(alpha: 0.3),
                      label: l10n.analyticsPolicyActive,
                      count: activeCount,
                    ),
                  ),
                  const SizedBox(width: AmDimens.gapS),
                  Expanded(
                    child: _StatusCard(
                      icon: Icons.pending_actions_rounded,
                      iconColor: cs.secondary,
                      bgColor: cs.secondaryContainer.withValues(alpha: 0.3),
                      label: l10n.analyticsPolicyPending,
                      count: pendingCount,
                    ),
                  ),
                  const SizedBox(width: AmDimens.gapS),
                  Expanded(
                    child: _StatusCard(
                      icon: Icons.error_outline_rounded,
                      iconColor: cs.error,
                      bgColor: cs.errorContainer.withValues(alpha: 0.3),
                      label: l10n.analyticsPolicyExpired,
                      count: expiredCount,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AmDimens.gapM),

              // Branch distribution
              Text(
                l10n.analyticsBranchDist,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: AmDimens.gapS),
              AmCard(
                child: sortedBranches.isEmpty
                    ? Center(
                        child: Text(
                          '—',
                          style: TextStyle(color: cs.tertiary),
                        ),
                      )
                    : Column(
                        children: [
                          for (int i = 0; i < sortedBranches.length; i++) ...[
                            if (i > 0) const SizedBox(height: 14),
                            _DistributionRow(
                              name: sortedBranches[i].key,
                              count: sortedBranches[i].value,
                              total: totalBranchPolicies,
                            ),
                          ],
                        ],
                      ),
              ),

              const SizedBox(height: AmDimens.gapM),

              // Carrier distribution
              Text(
                l10n.analyticsCarrierDist,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: AmDimens.gapS),
              AmCard(
                child: sortedCarriers.isEmpty
                    ? Center(
                        child: Text(
                          '—',
                          style: TextStyle(color: cs.tertiary),
                        ),
                      )
                    : Column(
                        children: [
                          for (int i = 0; i < sortedCarriers.length; i++) ...[
                            if (i > 0) const SizedBox(height: 14),
                            _DistributionRow(
                              name: sortedCarriers[i].key,
                              count: sortedCarriers[i].value,
                              total: totalCarrierPolicies,
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.dotColor,
    required this.label,
    required this.value,
  });

  final Color dotColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.label,
    required this.count,
  });

  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AmDimens.cardRadius),
        boxShadow: AmShadows.card,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: cs.tertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _DistributionRow extends StatelessWidget {
  const _DistributionRow({
    required this.name,
    required this.count,
    required this.total,
  });

  final String name;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double percent = total > 0 ? count / total : 0.0;
    final int pctLabel = (percent * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$count ($pctLabel%)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.tertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 6,
            backgroundColor: cs.secondaryContainer,
            valueColor: const AlwaysStoppedAnimation<Color>(AmColors.accent),
          ),
        ),
      ],
    );
  }
}
