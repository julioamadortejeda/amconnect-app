import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:amconnect/core/theme/am_theme.dart';
import 'package:amconnect/core/models/reminder.dart';
import 'package:amconnect/core/widgets/am_card.dart';
import 'package:amconnect/core/widgets/am_press.dart';
import 'package:amconnect/features/home/providers/home_provider.dart';

IconData _reminderIcon(String tipo) => switch (tipo) {
      'PAYMENT'      => Icons.payments_outlined,
      'RENEWAL'      => Icons.autorenew,
      'CANCELLATION' => Icons.block,
      'FOLLOW_UP'    => Icons.flag_outlined,
      'CALL'         => Icons.phone_outlined,
      'APPOINTMENT'  => Icons.event_outlined,
      'ANNIVERSARY'  => Icons.cake,
      _              => Icons.notifications_outlined,
    };

class HomePendientesCard extends StatelessWidget {
  const HomePendientesCard({super.key, required this.reminders});
  final List<Reminder> reminders;

  @override
  Widget build(BuildContext context) {
    return AmCard(
      noPad: true,
      child: Column(
        children: reminders.asMap().entries.map((e) {
          return HomePendingRow(r: e.value, isLast: e.key == reminders.length - 1);
        }).toList(),
      ),
    );
  }
}

class HomePendingRow extends ConsumerWidget {
  const HomePendingRow({super.key, required this.r, required this.isLast});
  final Reminder r;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;

    final (iconBg, iconFg, dotColor, badgeBg, badgeText) = switch (r.priority) {
      ReminderPriority.urgent => (
          cs.errorContainer,
          cs.error,
          cs.error,
          cs.errorContainer.withValues(alpha: 0.7),
          cs.error,
        ),
      ReminderPriority.warning => (
          am.amberWash,
          am.amber,
          am.amber,
          am.amberWash.withValues(alpha: 0.7),
          am.amber,
        ),
      ReminderPriority.normal => (
          cs.primaryContainer,
          cs.primary,
          null as Color?,
          cs.primaryContainer.withValues(alpha: 0.7),
          cs.primary,
        ),
    };

    return AmPress(
      onTap: () {
        if (r.contactId != null) context.push('/clientes/${r.contactId}');
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
        decoration: isLast
            ? null
            : BoxDecoration(
                border: Border(bottom: BorderSide(color: cs.outlineVariant))),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => ref.read(remindersProvider.notifier).toggle(r.id),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: r.hecho ? am.green : Colors.transparent,
                  border: r.hecho ? null : Border.all(color: cs.outline, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: r.hecho
                    ? const Icon(Icons.check, size: 15, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(_reminderIcon(r.tipo), size: 18, color: iconFg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.titulo,
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(r.sub,
                      style: TextStyle(fontSize: 12.5, color: cs.tertiary)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (dotColor != null)
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(r.fecha,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: badgeText)),
            ),
          ],
        ),
      ),
    );
  }
}
