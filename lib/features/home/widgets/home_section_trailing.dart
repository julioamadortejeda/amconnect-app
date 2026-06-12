import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class HomeSectionTrailing extends StatelessWidget {
  const HomeSectionTrailing({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AmColors.accent,
        ),
      ),
    );
  }
}
