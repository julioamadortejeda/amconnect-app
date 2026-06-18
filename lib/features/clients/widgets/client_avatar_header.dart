import 'package:flutter/material.dart';
import '../../../core/models/contact.dart';
import '../../../core/widgets/am_avatar.dart';
import '../../../l10n/app_localizations.dart';

class ClientAvatarHeader extends StatelessWidget {
  const ClientAvatarHeader({super.key, required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final subtitleParts = <String>[
      if (contact.occupation?.isNotEmpty == true) contact.occupation!,
      if (contact.address?.isNotEmpty == true) contact.address!,
      if (contact.age != null) l10n.clientsAge(contact.age!),
    ];
    final subtitle = subtitleParts.join(' · ');

    final year = contact.memberSinceYear;
    final isGold = year != null && year <= 2019;
    final badgeColor = isGold ? const Color(0xFFB9791A) : const Color(0xFF0E7C42);
    final badgeBg = badgeColor.withValues(alpha: 0.08);

    return Column(
      children: [
        AmAvatar(
          initials: contact.initials,
          color: contact.color,
          size: 76,
          radius: 38,
        ),
        const SizedBox(height: 10),
        Text(
          contact.fullName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
            letterSpacing: -0.01,
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: cs.tertiary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            year != null ? l10n.clientsMemberSince(year) : l10n.clientsNewClient,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ),
      ],
    );
  }
}
