import 'package:flutter/material.dart';
import '../../../core/models/contact.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_card.dart';

class ClientContactInfo extends StatelessWidget {
  const ClientContactInfo({super.key, required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final List<String> phones = contact.phone
            ?.split(RegExp(r'[,\/;]'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList() ??
        [];
    final List<String> emails = contact.email
            ?.split(RegExp(r'[,\/;]'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList() ??
        [];

    final rows = <({IconData icon, String text})>[
      ...phones.map((p) => (icon: Icons.phone_outlined, text: p)),
      ...emails.map((e) => (icon: Icons.email_outlined, text: e)),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

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
                  Icon(rows[i].icon, size: 17, color: cs.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rows[i].text,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
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
