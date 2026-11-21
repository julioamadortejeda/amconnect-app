import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/am_theme.dart';
import '../../theme/app_dimensions.dart';
import '../am_badge.dart';
import '../am_section_label.dart';
import '../../../l10n/app_localizations.dart';
import 'chat_card_shared.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  POLICY CONFIRMED CARD
// ═══════════════════════════════════════════════════════════════════════════════

class PolicyConfirmedCard extends StatelessWidget {
  const PolicyConfirmedCard({super.key, required this.data, this.isUpdate = false});
  final Map<String, dynamic> data;
  final bool isUpdate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    final l10n = AppLocalizations.of(context)!;
    final carrier = data['carrierName'] as String? ?? '';
    final branch = data['branchName'] as String? ?? '';
    final holder = data['holderName'] as String? ?? '';
    final policyNumber = data['policyNumber'] as String? ?? '';
    final policyId = data['policyId'] as String? ?? '';
    final remindersMap = data['reminders'] as Map<String, dynamic>? ?? {};
    final reminders = [
      ...(remindersMap['created'] as List? ?? []),
      ...(remindersMap['existing'] as List? ?? []),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AmDimens.cardRadius),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: AmShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: am.greenWash,
                    borderRadius: BorderRadius.circular(AmDimens.radiusM),
                  ),
                  child: Icon(Icons.check_circle_rounded, color: am.green, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isUpdate ? l10n.chatCardPolicyUpdated : l10n.chatCardPolicyCreated,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      if (policyNumber.isNotEmpty)
                        Text(
                          '#$policyNumber',
                          style: TextStyle(fontSize: 12, color: cs.tertiary),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant),

          // ── Body fields ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (carrier.isNotEmpty)
                  ChatDetailRow(icon: Icons.business_rounded, label: l10n.policiesCarrier, value: carrier),
                if (branch.isNotEmpty)
                  ChatDetailRow(icon: Icons.category_rounded, label: l10n.policiesBranch, value: branch),
                if (holder.isNotEmpty)
                  ChatDetailRow(icon: Icons.person_rounded, label: l10n.chatCardFieldHolder, value: holder),
              ],
            ),
          ),

          // ── Auto-generated reminders ────────────────────────────
          if (reminders.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
              child: AmSectionLabel(
                label: l10n.chatCardRemindersLabel,
                trailing: AmBadge(label: '${reminders.length}', tone: AmBadgeTone.accent),
              ),
            ),
            ...reminders.take(3).map((r) {
              final title = (r is Map ? r['title'] : null) as String? ?? l10n.chatCardReminderFallback;
              return Padding(
                padding: const EdgeInsets.fromLTRB(14, 2, 14, 2),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active_rounded, size: 13, color: am.amber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(title,
                          style: TextStyle(fontSize: 12, color: cs.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 6),
          ],

          // ── Action button ──────────────────────────────────────
          if (policyId.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: ChatCardActionButton(
                label: l10n.chatCardViewPolicy,
                icon: Icons.arrow_forward_rounded,
                color: cs.primary,
                onTap: () => context.push('/policy/$policyId'),
              ),
            ),
        ],
      ),
    );
  }
}
