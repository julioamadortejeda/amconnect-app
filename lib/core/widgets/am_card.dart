import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import 'am_press.dart';

class AmCard extends StatelessWidget {
  const AmCard({
    super.key,
    this.child,
    this.onTap,
    this.padding,
    this.style,
    this.noPad = false,
  });

  final Widget? child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final BoxDecoration? style;
  final bool noPad;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final card = Container(
      padding: noPad ? EdgeInsets.zero : (padding ?? const EdgeInsets.all(AmDimens.cardPad)),
      decoration: style ??
          BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AmDimens.cardRadius),
            boxShadow: AmShadows.card,
          ),
      child: child,
    );

    if (onTap == null) return card;
    return AmPress(onTap: onTap, child: card);
  }
}
