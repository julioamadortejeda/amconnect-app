import 'package:flutter/material.dart';
import 'package:amconnect/core/widgets/am_press.dart';

class HomeFloatingBtn extends StatelessWidget {
  const HomeFloatingBtn({
    super.key,
    required this.child,
    required this.onTap,
    this.dot = false,
  });
  final Widget child;
  final VoidCallback onTap;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AmPress(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(child: child),
          ),
          if (dot)
            Positioned(
              top: 6, right: 6,
              child: Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                    color: cs.error, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}
