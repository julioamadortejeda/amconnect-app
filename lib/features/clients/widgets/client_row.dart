import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/contact.dart';
import '../../../core/models/reminder.dart';
import '../../../core/widgets/am_avatar.dart';
import '../../../core/widgets/am_badge.dart';
import '../../../core/widgets/am_card.dart';
import '../providers/clients_provider.dart';
import '../../../l10n/app_localizations.dart';

({String label, AmBadgeTone tone})? _resolveBadge(
  List<Reminder> reminders,
  AppLocalizations l10n,
) {
  if (reminders.isEmpty) return null;

  // Solo alertas de pago y renovación — las demás no se muestran en el listado
  final financial = reminders
      .where((r) => r.isPayment || r.isRenewal)
      .toList()
    ..sort((a, b) {
      final da = a.dueDate ?? DateTime(2099);
      final db = b.dueDate ?? DateTime(2099);
      return da.compareTo(db);
    });

  for (final r in financial) {
    if (r.priority == ReminderPriority.urgent ||
        r.priority == ReminderPriority.warning) {
      final label =
          r.isPayment ? l10n.clientsStatusPaymentDue : l10n.clientsStatusToRenew;
      return (label: label, tone: AmBadgeTone.amber);
    }
  }

  return (label: l10n.clientsStatusUpToDate, tone: AmBadgeTone.green);
}

class ClientRow extends ConsumerWidget {
  const ClientRow({super.key, required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final reminders =
        ref.watch(contactRemindersMapProvider)[contact.id] ?? const [];
    final badge = _resolveBadge(reminders, l10n);

    final subtitle = [
      if (contact.occupation?.isNotEmpty == true) contact.occupation!,
      if (contact.address?.isNotEmpty == true) contact.address!,
    ].join(' · ');

    return AmCard(
      onTap: () => context.push('/clients/${contact.id}'),
      child: Row(
        children: [
          AmAvatar(
            initials: contact.initials,
            color: contact.color,
            size: 42,
            radius: 13,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.fullName,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12.5, color: cs.tertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 10),
            AmBadge(label: badge.label, tone: badge.tone),
          ],
        ],
      ),
    );
  }
}
