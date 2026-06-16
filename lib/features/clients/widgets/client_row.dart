import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/contact.dart';
import '../../../core/widgets/am_avatar.dart';
import '../../../core/widgets/am_badge.dart';
import '../../../core/widgets/am_card.dart';
import '../../../l10n/app_localizations.dart';

class ClientRow extends StatelessWidget {
  const ClientRow({super.key, required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final subtitle = [
      if (contact.occupation?.isNotEmpty == true) contact.occupation!,
      if (contact.address?.isNotEmpty == true) contact.address!,
    ].join(' · ');

    return AmCard(
      onTap: () => context.push('/clients/${contact.id}'),
      child: Row(
        children: [
          AmAvatar(
            inicial: contact.inicial,
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
          const SizedBox(width: 10),
          AmBadge(label: l10n.clientsStatusUpToDate, tone: AmBadgeTone.green),
        ],
      ),
    );
  }
}
