import 'package:flutter/material.dart';
import 'package:amconnect/core/theme/app_colors.dart';
import 'package:amconnect/core/widgets/am_press.dart';

class LoginSocialBtn extends StatelessWidget {
  const LoginSocialBtn({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  final Widget icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AmPress(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          icon,
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: AmColors.accent)),
        ]),
      ),
    );
  }
}
