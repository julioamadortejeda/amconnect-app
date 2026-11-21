import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/am_theme.dart';
import '../../theme/app_dimensions.dart';
import '../../utils/formatters.dart';
import '../../../l10n/app_localizations.dart';
import 'chat_card_shared.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  REMINDER CREATED CARD
// ═══════════════════════════════════════════════════════════════════════════════

class ReminderCreatedCard extends StatelessWidget {
  const ReminderCreatedCard({super.key, required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    final l10n = AppLocalizations.of(context)!;
    final title = data['title'] as String? ?? l10n.chatCardReminderFallback;
    final description = data['description'] as String?;
    final dueDate = data['dueDate'] as String?;
    final clientName = data['clientName'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AmDimens.radiusL),
        border: Border.all(color: am.amber.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: am.amber.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [am.amber, AmColors.amberDeep],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: am.amber.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.alarm_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (clientName != null)
                        Text(
                          clientName,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.tertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.check_circle_rounded, color: am.amber, size: 22),
              ],
            ),
          ),

          // ── Details ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dueDate != null)
                  ChatDetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: l10n.chatCardFieldDate,
                    value: fmtSmartDateTime(DateTime.tryParse(dueDate), l10n,
                        showYear: true),
                  ),
                if (description != null && description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      description,
                      style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant, height: 1.4),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),

          // ── Action ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
            child: ChatCardActionButton(
              label: l10n.chatCardGoToAgenda,
              icon: Icons.arrow_forward_rounded,
              color: am.amber,
              onTap: () => context.go('/reminders'),
            ),
          ),
        ],
      ),
    );
  }

}
