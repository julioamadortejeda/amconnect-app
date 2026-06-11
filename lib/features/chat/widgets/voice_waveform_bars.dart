import 'dart:math';
import 'package:flutter/material.dart';

class VoiceWaveformBars extends StatefulWidget {
  const VoiceWaveformBars({super.key});

  @override
  State<VoiceWaveformBars> createState() => _VoiceWaveformBarsState();
}

class _VoiceWaveformBarsState extends State<VoiceWaveformBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const barCount = 11;
    const maxH = 48.0;
    const minH = 5.0;

    return SizedBox(
      height: maxH + 4,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(barCount, (i) {
              // Sinusoidal wave with per-bar phase offset
              final phase = (i / barCount) * 2 * pi;
              final sine = sin(_ctrl.value * 2 * pi + phase);
              // Normalize 0..1
              final normalized = sine * 0.5 + 0.5;
              final h = minH + (maxH - minH) * normalized;

              final isCenter = i == barCount ~/ 2;
              final opacity = 0.38 + normalized * 0.62;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: isCenter ? 5 : 4,
                height: h,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: opacity),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
