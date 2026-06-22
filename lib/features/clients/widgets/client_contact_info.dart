import 'package:flutter/material.dart';
import '../../../core/models/contact.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/am_card.dart';

class ClientContactInfo extends StatelessWidget {
  const ClientContactInfo({super.key, required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final phoneEntries = contact.phone
            ?.split(RegExp(r'[,\/;]'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList() ??
        [];
    final emailEntries = contact.email
            ?.split(RegExp(r'[,\/;]'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList() ??
        [];

    final birthdateText = contact.birthdate != null
        ? fmtDateFromIso(contact.birthdate)
        : null;

    final List<({IconData icon, String text, bool muted})> rows = [
      if (phoneEntries.isEmpty)
        (icon: Icons.phone_outlined, text: '—', muted: true)
      else
        for (final p in phoneEntries)
          (icon: Icons.phone_outlined, text: p, muted: false),
      if (emailEntries.isEmpty)
        (icon: Icons.chat_bubble_outline_rounded, text: '—', muted: true)
      else
        for (final e in emailEntries)
          (icon: Icons.chat_bubble_outline_rounded, text: e, muted: false),
      (
        icon: Icons.cake_outlined,
        text: birthdateText ?? '—',
        muted: birthdateText == null,
      ),
    ];

    return AmCard(
      noPad: true,
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: 0,
                indent: AmDimens.screenH,
                endIndent: AmDimens.screenH,
                color: cs.outlineVariant,
              ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AmDimens.screenH,
                vertical: 13,
              ),
              child: Row(
                children: [
                  Icon(rows[i].icon, size: 17,
                      color: rows[i].muted ? cs.outlineVariant : cs.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rows[i].text,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: rows[i].muted ? cs.tertiary : cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
