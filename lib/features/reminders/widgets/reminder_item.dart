import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:amconnect/core/models/reminder.dart';
import 'package:amconnect/core/theme/am_theme.dart';
import 'package:amconnect/core/theme/app_dimensions.dart';
import 'package:amconnect/core/widgets/am_press.dart';
import 'package:amconnect/features/home/providers/home_provider.dart';

IconData reminderIcon(String tipo) => switch (tipo) {
      'PAYMENT'      => Icons.payments_outlined,
      'RENEWAL'      => Icons.autorenew,
      'CANCELLATION' => Icons.block,
      'FOLLOW_UP'    => Icons.flag_outlined,
      'CALL'         => Icons.phone_outlined,
      'APPOINTMENT'  => Icons.event_outlined,
      'ANNIVERSARY'  => Icons.cake,
      _              => Icons.notifications_outlined,
    };

class ReminderItem extends ConsumerWidget {
  const ReminderItem({super.key, required this.reminder});

  final Reminder reminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    final r = reminder;

    final (iconFg, iconBg, badgeBg, badgeFg) = switch (r.priority) {
      ReminderPriority.urgent  => (cs.error,    cs.errorContainer,  cs.errorContainer.withValues(alpha: 0.7),  cs.error),
      ReminderPriority.warning => (am.amber,    am.amberWash,       am.amberWash.withValues(alpha: 0.7),       am.amber),
      ReminderPriority.normal  => (cs.primary,  cs.primaryContainer, cs.primaryContainer.withValues(alpha: 0.7), cs.primary),
    };

    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final daysLeft = r.dueDate != null
        ? DateTime(r.dueDate!.year, r.dueDate!.month, r.dueDate!.day)
            .difference(todayKey)
            .inDays
        : null;

    return Opacity(
      opacity: r.hecho ? 0.55 : 1.0,
      child: AmPress(
        onTap: () {
          if (r.contactId != null) context.push('/clientes/${r.contactId}');
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AmDimens.screenH, AmDimens.gapS, AmDimens.screenH, AmDimens.gapS),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => ref.read(remindersProvider.notifier).toggle(r.id),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: r.hecho ? am.green : Colors.transparent,
                    border:
                        r.hecho ? null : Border.all(color: cs.outline, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: r.hecho
                      ? const Icon(Icons.check, size: 15, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: iconBg, borderRadius: BorderRadius.circular(11)),
                child: Icon(reminderIcon(r.tipo), size: 18, color: iconFg),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.titulo,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                        decoration: r.hecho ? TextDecoration.lineThrough : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      r.hora != '—' ? '${r.sub} · ${r.hora}' : r.sub,
                      style: TextStyle(fontSize: 12.5, color: cs.tertiary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(r.fecha,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: badgeFg)),
                  ),
                  if (daysLeft != null && daysLeft != 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${daysLeft}d',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
