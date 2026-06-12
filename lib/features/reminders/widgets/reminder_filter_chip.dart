import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/am_press.dart';

class ReminderFilterChip extends StatelessWidget {
  const ReminderFilterChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AmPress(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AmColors.accent : cs.surface,
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(
              color: active
                  ? AmColors.accent.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.055),
              blurRadius: active ? 12 : 8,
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: active ? Colors.white : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
