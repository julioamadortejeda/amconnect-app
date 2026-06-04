import 'package:flutter/material.dart';
import 'package:amconnect/core/theme/app_colors.dart';
import 'am_press.dart';

enum AmIconBtnTone { soft, sunken, accent, ghost }

class AmIconBtn extends StatelessWidget {
  const AmIconBtn({
    super.key,
    required this.icon,
    this.onTap,
    this.tone = AmIconBtnTone.soft,
    this.size = 22,
    this.dim = 40,
    this.dot = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final AmIconBtnTone tone;
  final double size;
  final double dim;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, shadow) = switch (tone) {
      AmIconBtnTone.soft    => (AmColors.cardLight, AmColors.inkSoftLight, true),
      AmIconBtnTone.sunken  => (AmColors.cardSunkenLight, AmColors.inkSoftLight, false),
      AmIconBtnTone.accent  => (AmColors.accent, Colors.white, true),
      AmIconBtnTone.ghost   => (Colors.transparent, AmColors.inkSoftLight, false),
    };

    final btn = Container(
      width: dim,
      height: dim,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(13),
        boxShadow: shadow
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.055), blurRadius: 22, offset: const Offset(0, 4))]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, size: size, color: fg),
          if (dot)
            Positioned(
              top: 7,
              right: 8,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: AmColors.redLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );

    return AmPress(onTap: onTap, child: btn);
  }
}
