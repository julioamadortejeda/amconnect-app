import 'package:flutter/material.dart';
import '../../../core/models/contact.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_card.dart';

class ClientFiscalInfo extends StatelessWidget {
  const ClientFiscalInfo({super.key, required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final rows = [
      (label: 'RFC', value: contact.rfc),
      (label: 'CURP', value: contact.curp),
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
                  SizedBox(
                    width: 48,
                    child: Text(
                      rows[i].label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.tertiary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rows[i].value ?? '—',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: rows[i].value != null
                            ? cs.onSurface
                            : cs.tertiary,
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
