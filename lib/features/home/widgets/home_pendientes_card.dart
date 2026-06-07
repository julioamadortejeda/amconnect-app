import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:amconnect/core/theme/am_theme.dart';
import 'package:amconnect/core/mock/mock_data.dart';
import 'package:amconnect/core/widgets/am_card.dart';
import 'package:amconnect/core/widgets/am_press.dart';

class HomePendientesCard extends StatelessWidget {
  const HomePendientesCard({super.key, required this.reminders});
  final List<MockReminder> reminders;

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

class HomePendingRow extends StatelessWidget {
  const HomePendingRow({super.key, required this.r, required this.isLast});
  final MockReminder r;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    final (iconData, iconColor, iconBg) = switch (r.tipo) {
      'pago'       => (Icons.payments_outlined, am.amber, am.amberWash),
      'renovacion' => (Icons.autorenew, cs.onPrimaryContainer, cs.primaryContainer),
      _            => (Icons.phone_outlined, am.green, am.greenWash),
    };

    return AmPress(
      onTap: () {
        final c = clientById(r.clienteId);
        if (c != null) context.push('/clientes/${c.id}');
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
        decoration: isLast
            ? null
            : BoxDecoration(
                border: Border(bottom: BorderSide(color: cs.outlineVariant))),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: r.urgente ? cs.errorContainer : iconBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(iconData, size: 18,
                  color: r.urgente ? cs.error : iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.titulo,
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500,
                          color: cs.onSurface),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(r.sub,
                      style: TextStyle(fontSize: 12.5, color: cs.tertiary)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (r.urgente)
              Container(
                width: 7, height: 7,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                    color: cs.error, shape: BoxShape.circle),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: r.urgente ? cs.errorContainer : cs.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(r.fecha,
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: r.urgente ? cs.error : cs.tertiary,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
