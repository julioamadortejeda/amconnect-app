import 'package:flutter/material.dart';
import 'package:amconnect/core/theme/app_colors.dart';

class VoicePulsingMic extends StatefulWidget {
  const VoicePulsingMic({super.key});

  @override
  State<VoicePulsingMic> createState() => _VoicePulsingMicState();
}

class _VoicePulsingMicState extends State<VoicePulsingMic>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        // Two staggered rings: one at value, one offset by half period
        final t1 = Curves.easeOut.transform(_ctrl.value);
        final t2 = Curves.easeOut.transform((_ctrl.value + 0.5).remainder(1.0));

        return Stack(
          alignment: Alignment.center,
          children: [
            // Ring 1
            Container(
              width: 80 + 56 * t1,
              height: 80 + 56 * t1,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AmColors.accent.withValues(alpha: 0.18 * (1 - t1)),
              ),
            ),
            // Ring 2
            Container(
              width: 80 + 56 * t2,
              height: 80 + 56 * t2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AmColors.accent.withValues(alpha: 0.18 * (1 - t2)),
              ),
            ),
            // Static halo
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AmColors.accent.withValues(alpha: 0.2),
              ),
            ),
            // Mic circle
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AmColors.accent,
                boxShadow: [
                  BoxShadow(
                    color: AmColors.accent.withValues(alpha: 0.55),
                    blurRadius: 32,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.mic_rounded, color: Colors.white, size: 38),
            ),
          ],
        );
      },
    );
  }
}
