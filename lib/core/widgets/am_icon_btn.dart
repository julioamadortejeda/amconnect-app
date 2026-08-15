import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
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
    final cs = Theme.of(context).colorScheme;
    // Sin acción = se ve sin acción. Antes un botón deshabilitado quedaba
    // idéntico a uno vivo y el usuario lo tocaba esperando que respondiera —
    // en el composer eso hacía parecer que la app se había trabado.
    final disabled = onTap == null;
    final (bg, fg, shadow) = disabled
        ? (cs.secondaryContainer, cs.onSurfaceVariant.withValues(alpha: 0.38), false)
        : switch (tone) {
            AmIconBtnTone.soft    => (cs.surface, cs.onSurfaceVariant, true),
            AmIconBtnTone.sunken  => (cs.secondaryContainer, cs.onSurfaceVariant, false),
            AmIconBtnTone.accent  => (AmColors.accent, Colors.white, true),
            AmIconBtnTone.ghost   => (Colors.transparent, cs.onSurfaceVariant, false),
          };

    final btn = Container(
      width: dim,
      height: dim,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(13),
        boxShadow: shadow
            ? [const BoxShadow(color: AmColors.shadowSoft, blurRadius: 22, offset: Offset(0, 4))]
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
                  color: cs.error,
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
