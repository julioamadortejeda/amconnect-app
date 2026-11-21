import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/am_theme.dart';
import '../../theme/app_dimensions.dart';
import '../am_press.dart';
import '../../utils/api_error_mapper.dart';
import '../../utils/error_translator.dart';
import '../../utils/formatters.dart';
import '../../../l10n/app_localizations.dart';
import '../../../features/home/providers/home_provider.dart';
import 'chat_card_shared.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  REMINDER LIST CARD
// ═══════════════════════════════════════════════════════════════════════════════

class ReminderListCard extends ConsumerStatefulWidget {
  const ReminderListCard({super.key, required this.data});
  final Map<String, dynamic> data;

  @override
  ConsumerState<ReminderListCard> createState() => _ReminderListCardState();
}

class _ReminderListCardState extends ConsumerState<ReminderListCard> {
  final Set<String> _completedIds = {};

  /// Marca como hecho y revierte la palomita si el backend no lo guardó —
  /// antes la tarjeta quedaba palomeada aunque nada se hubiera guardado.
  Future<void> _markDone(String id) async {
    final notifier = ref.read(remindersProvider.notifier);
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _completedIds.add(id));
    try {
      await notifier.markDone(id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _completedIds.remove(id));
      messenger?.showSnackBar(SnackBar(
        content: Text(context.translateError(mapApiError(e))),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    final l10n = AppLocalizations.of(context)!;
    final list = widget.data['reminders'] as List? ?? [];

    return Container(
      padding: const EdgeInsets.all(AmDimens.cardPad),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AmDimens.cardRadius),
        border: Border.all(color: am.amber.withValues(alpha: 0.2)),
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
              Icon(Icons.checklist_rounded, color: am.amber, size: 18),
              const SizedBox(width: 8),
              Text(
                l10n.chatCardReminderListTitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: am.amber,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: AmDimens.gapS),
          ...list.map((item) {
            final map = item as Map<String, dynamic>? ?? {};
            final id = map['id'] as String? ?? '';
            final title = map['title'] as String? ?? l10n.chatCardReminderFallback;
            final dueDate = map['dueDate'] as String?;
            final clientName = map['clientName'] as String?;
            final isDone = _completedIds.contains(id);

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  AmPress(
                    onTap: () {
                      if (id.isNotEmpty && !isDone) _markDone(id);
                    },
                    child: Icon(
                      isDone ? Icons.check_box_outlined : Icons.check_box_outline_blank,
                      color: isDone ? am.green : cs.tertiary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDone ? cs.tertiary : cs.onSurface,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (clientName != null || dueDate != null)
                          Text(
                            [
                              if (clientName != null) clientName,
                              if (dueDate != null)
                                fmtSmartDateTime(
                                    DateTime.tryParse(dueDate), l10n),
                            ].join(' · '),
                            style: TextStyle(fontSize: 11, color: cs.tertiary),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          ChatCardActionButton(
            label: l10n.chatCardGoToAgenda,
            icon: Icons.arrow_forward_rounded,
            color: am.amber,
            onTap: () => context.go('/reminders'),
          ),
        ],
      ),
    );
  }

}
