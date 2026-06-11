import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amconnect/core/theme/app_colors.dart';
import 'package:amconnect/core/widgets/am_badge.dart';
import 'package:amconnect/core/widgets/am_section_label.dart';
import 'package:amconnect/features/feed/providers/ingest_provider.dart';
import 'package:amconnect/l10n/app_localizations.dart';

class PolicySuccessSheet extends ConsumerWidget {
  const PolicySuccessSheet({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final data = ref.watch(ingestProvider).confirmedPolicy;

    if (data == null) return const SizedBox.shrink();

    final allReminders = data.allReminders;
    final newCount = data.remindersCreated.length;
    final existingCount = data.remindersExisting.length;

    String newLabel() {
      if (newCount == 1) return l10n.feedSuccessNewOne;
      return l10n.feedSuccessNewMany(newCount);
    }

    String existingLabel() {
      if (existingCount == 1) return l10n.feedSuccessExistingOne;
      return l10n.feedSuccessExistingMany(existingCount);
    }

    final subtitle = [
      if (data.branchName != null) data.branchName!,
      if (data.carrierName != null) data.carrierName!,
      if (data.holderName != null) data.holderName!,
    ].join(' · ');

    return Container(
      color: Colors.black.withValues(alpha: 0.34),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(top: 14, bottom: 20),
                decoration: BoxDecoration(
                  color: cs.outline,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.check_circle_outline,
                              color: Color(0xFF34A853),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.feedSuccessTitle,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface,
                                  ),
                                ),
                                if (subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    subtitle,
                                    style: TextStyle(fontSize: 13, color: cs.tertiary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: cs.tertiary, size: 20),
                            onPressed: onClose,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Stats chips
                      Row(
                        children: [
                          _StatChip(
                            label: l10n.feedSuccessFieldsSaved(data.fieldCount),
                            icon: Icons.save_outlined,
                            color: AmColors.accent,
                          ),
                          const SizedBox(width: 10),
                          if (newCount > 0)
                            _StatChip(
                              label: newLabel(),
                              icon: Icons.notifications_active_outlined,
                              color: const Color(0xFF34A853),
                            ),
                        ],
                      ),

                      if (existingCount > 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          existingLabel(),
                          style: TextStyle(fontSize: 12.5, color: cs.tertiary),
                        ),
                      ],

                      if (allReminders.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        AmSectionLabel(
                          label: l10n.feedSuccessRemindersSection,
                          trailing: AmBadge(
                            label: '${allReminders.length}',
                            tone: AmBadgeTone.accent,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: cs.secondaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: allReminders.asMap().entries.map((e) {
                              final r = e.value;
                              final isLast = e.key == allReminders.length - 1;
                              return _ReminderRow(
                                reminder: r,
                                isLast: isLast,
                                l10n: l10n,
                              );
                            }).toList(),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // CTA
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: onClose,
                    style: FilledButton.styleFrom(
                      backgroundColor: AmColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      l10n.feedSuccessDone,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.icon, required this.color});
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final bg = Color.alphaBlend(color.withValues(alpha: 0.12), Colors.white);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.reminder,
    required this.isLast,
    required this.l10n,
  });
  final GeneratedReminder reminder;
  final bool isLast;
  final AppLocalizations l10n;

  (IconData, Color) get _iconAndColor {
    return switch (reminder.typeCode) {
      'PAGO' => (Icons.account_balance_wallet_outlined, const Color(0xFFA07040)),
      'RENOVACION' => (Icons.refresh, const Color(0xFF34A853)),
      'ANNIVERSARY' => (Icons.event_repeat_outlined, const Color(0xFF5C6BC0)),
      'SEGUIMIENTO' => (Icons.phone_outlined, AmColors.accent),
      'LLAMADA' => (Icons.call_outlined, AmColors.accent),
      'CUMPLEANOS' => (Icons.cake_outlined, const Color(0xFF9B59B6)),
      _ => (Icons.notifications_outlined, AmColors.accent),
    };
  }

  String _formatDate(String isoDate) {
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return isoDate;
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (icon, color) = _iconAndColor;
    final bg = Color.alphaBlend(color.withValues(alpha: 0.14), Colors.white);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(bottom: BorderSide(color: cs.outlineVariant)),
            ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(reminder.dueDate),
                  style: TextStyle(fontSize: 12, color: cs.tertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: reminder.isNew
                  ? const Color(0xFFE8F5E9)
                  : cs.secondaryContainer,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              reminder.isNew
                  ? '+ ${l10n.feedSuccessReminderNew}'
                  : l10n.feedSuccessReminderExisting,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: reminder.isNew
                    ? const Color(0xFF34A853)
                    : cs.tertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
