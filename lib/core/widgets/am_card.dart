import 'package:flutter/material.dart';
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
    final card = Container(
      padding: noPad ? EdgeInsets.zero : (padding ?? const EdgeInsets.all(AmDimens.cardPad)),
      decoration: style ??
          BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AmDimens.cardRadius),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D141E1A),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
              BoxShadow(
                color: Color(0x0A141E1A),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
      child: child,
    );

    if (onTap == null) return card;
    return AmPress(onTap: onTap, child: card);
  }
}
