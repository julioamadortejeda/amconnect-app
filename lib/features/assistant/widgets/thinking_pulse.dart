import 'dart:math';
import 'package:flutter/material.dart';

/// Blob que respira en loop continuo — indicador genérico de "la IA está
/// trabajando" sin nivel de audio real (a diferencia de [ModelSpeakingPulse],
/// que reacciona a la voz del modelo). Se usa en el chat de texto mientras
/// espera respuesta, y en la barra de voz mientras hay una skill en vuelo
/// (tool call) mientras el status todavía no pasa a "modelSpeaking".
class ThinkingPulse extends StatefulWidget {
  const ThinkingPulse({super.key, required this.color, this.size = 16});

  final Color color;
  final double size;

  @override
  State<ThinkingPulse> createState() => _ThinkingPulseState();
}

class _ThinkingPulseState extends State<ThinkingPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breatheCtrl;

  @override
  void initState() {
    super.initState();
    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _breatheCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    // Espacio extra alrededor del punto para que el blur del glow no se
    // recorte contra los límites del SizedBox.
    final box = size * 2.6;
    return SizedBox(
      width: box,
      height: box,
      child: Center(
        child: AnimatedBuilder(
          animation: _breatheCtrl,
          builder: (_, __) {
            final breathing = sin(_breatheCtrl.value * 2 * pi) * 0.5 + 0.5;
            final scale = 0.88 + breathing * 0.12;
            final glowAlpha = 0.35 + breathing * 0.35;

            return Transform.scale(
              scale: scale,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: glowAlpha),
                      blurRadius: size * 0.9,
                      spreadRadius: size * 0.08,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
