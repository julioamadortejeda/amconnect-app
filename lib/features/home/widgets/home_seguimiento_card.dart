import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:amconnect/core/models/reminder.dart';
import 'package:amconnect/core/theme/am_theme.dart';
import 'package:amconnect/core/widgets/am_avatar.dart';
import 'package:amconnect/core/widgets/am_card.dart';
import 'package:amconnect/core/widgets/am_press.dart';

class HomeSeguimientoCard extends StatelessWidget {
  const HomeSeguimientoCard({super.key, required this.reminder});
  final Reminder reminder;

  static const _avatarColors = [
    Color(0xFF007AC0), Color(0xFF0E7C42), Color(0xFFB9791A),
    Color(0xFF7A4FD0), Color(0xFFD8453F),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;

    // Derivar avatar del nombre del contacto y del contactId
    final words = reminder.sub.trim().split(RegExp(r'\s+'));
    final inicial = words.take(2).map((w) => w.isEmpty ? '' : w[0].toUpperCase()).join();
    final colorIdx = (reminder.contactId?.hashCode.abs() ?? 0) % _avatarColors.length;

    final (badgeBg, badgeFg) = switch (reminder.priority) {
      ReminderPriority.urgent  => (cs.errorContainer, cs.error),
      ReminderPriority.warning => (am.amberWash, am.amber),
      ReminderPriority.normal  => (cs.primaryContainer, cs.primary),
    };

    return AmPress(
      onTap: () {
        if (reminder.contactId != null) context.push('/clientes/${reminder.contactId}');
      },
      child: AmCard(
        child: Row(
          children: [
            AmAvatar(inicial: inicial, color: _avatarColors[colorIdx], size: 46, radius: 15),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reminder.titulo,
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500,
                          color: cs.onSurface),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (reminder.sub.isNotEmpty) ...[
                        Flexible(
                          child: Text(reminder.sub,
                              style: TextStyle(fontSize: 12.5, color: cs.tertiary),
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(reminder.fecha,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                color: badgeFg)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: am.muted2, size: 18),
          ],
        ),
      ),
    );
  }
}
