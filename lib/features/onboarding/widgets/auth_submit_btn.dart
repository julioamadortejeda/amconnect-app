import 'package:flutter/material.dart';
import '../../../core/widgets/am_spinner.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/am_press.dart';

class AuthSubmitBtn extends StatelessWidget {
  const AuthSubmitBtn({
    super.key,
    required this.label,
    required this.enabled,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AmPress(
      onTap: (enabled && !isLoading) ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          boxShadow: enabled
              ? [
                  const BoxShadow(
                    color: AmColors.shadowStrong,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: isLoading
            ? const AmSpinner(
                size: 24,
                strokeWidth: 2.5,
                color: AmColors.accent,
              )
            : Text(
                label,
                style: TextStyle(
                  color: enabled ? AmColors.accent : Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}