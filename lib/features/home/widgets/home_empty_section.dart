import 'package:flutter/material.dart';
import 'package:amconnect/core/widgets/am_card.dart';

class HomeEmptySection extends StatelessWidget {
  const HomeEmptySection({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AmCard(
      child: Row(
        children: [
          Icon(Icons.inbox_outlined, size: 18, color: cs.tertiary),
          const SizedBox(width: 10),
          Text(
            message,
            style: TextStyle(fontSize: 13, color: cs.tertiary),
          ),
        ],
      ),
    );
  }
}
