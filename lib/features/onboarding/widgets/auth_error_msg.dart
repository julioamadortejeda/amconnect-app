import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AuthErrorMsg extends StatelessWidget {
  const AuthErrorMsg({
    super.key,
    required this.message,
    this.scale = 1.0,
    this.onDismiss,
  });

  final String message;
  final double scale;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        padding: EdgeInsets.only(
          left: 12 * scale,
          right: onDismiss != null ? 8 * scale : 12 * scale,
          top: 9 * scale,
          bottom: 9 * scale,
        ),
        decoration: BoxDecoration(
          color: AmColors.authError.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AmColors.authError.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                color: AmColors.authError, size: 15 * scale),
            SizedBox(width: 7 * scale),
            Flexible(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 13 * scale,
                  color: AmColors.authError,
                  height: 1.3,
                ),
              ),
            ),
            if (onDismiss != null) ...[
              SizedBox(width: 6 * scale),
              Icon(Icons.close_rounded,
                  color: AmColors.authError.withValues(alpha: 0.7),
                  size: 15 * scale),
            ],
          ],
        ),
      ),
    );
  }
}
