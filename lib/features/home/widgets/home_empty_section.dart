import 'package:flutter/material.dart';
import '../../../core/theme/app_dimensions.dart';

class HomeEmptySection extends StatelessWidget {
  const HomeEmptySection({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AmDimens.gapM),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            fontSize: 13,
            color: cs.tertiary,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
