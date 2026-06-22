import 'package:flutter/material.dart';
import '../../../core/models/contact.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_card.dart';

class ClientContactNotes extends StatelessWidget {
  const ClientContactNotes({super.key, required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final notes = contact.notes;
    if (notes == null || notes.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    return AmCard(
      noPad: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AmDimens.screenH,
          vertical: 13,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.notes_outlined, size: 17, color: cs.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                notes,
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
    );
  }
}
