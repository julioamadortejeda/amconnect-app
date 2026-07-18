import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Glow pulsante para "el modelo está respondiendo" — a propósito NO son
/// barras (esas quedan para cuando el usuario habla): un blob que respira
/// solo y se hincha con el nivel real de la voz del modelo (ver
/// [GeminiVoiceEngine.modelLevel]), para que de un vistazo quede claro quién
/// está hablando sin necesidad de leer el texto de estado.
class ModelSpeakingPulse extends StatefulWidget {
  const ModelSpeakingPulse({
    super.key,
    required this.level,
    this.size = 24.0,
  });

  final ValueListenable<double> level;
  final double size;

  @override
  State<ModelSpeakingPulse> createState() => _ModelSpeakingPulseState();
}

class _ModelSpeakingPulseState extends State<ModelSpeakingPulse>
    with SingleTickerProviderStateMixin {
  // Respiración lenta continua — mantiene el blob vivo aun en los huecos
  // entre chunks de audio, en vez de quedarse estático.
  late final AnimationController _breatheCtrl;
  double _smoothed = 0.0;

  @override
  void initState() {
    super.initState();
    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    widget.level.addListener(_onLevelChanged);
  }

  void _onLevelChanged() {
    final target = widget.level.value;
    setState(() {
      _smoothed = target > _smoothed ? target : _smoothed * 0.82 + target * 0.18;
    });
  }

  @override
  void didUpdateWidget(ModelSpeakingPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level != widget.level) {
      oldWidget.level.removeListener(_onLevelChanged);
      widget.level.addListener(_onLevelChanged);
    }
  }

  @override
  void dispose() {
    widget.level.removeListener(_onLevelChanged);
    _breatheCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    // Espacio extra para que el blur del glow no se recorte contra el borde
    // del SizedBox (mismo criterio que el pulse de "pensando" en texto).
    final box = size * 2.6;
    return SizedBox(
      width: box,
      height: box,
      child: Center(
        child: AnimatedBuilder(
          animation: _breatheCtrl,
          builder: (_, __) {
            final breathing = sin(_breatheCtrl.value * 2 * pi) * 0.5 + 0.5;
            final base = 0.65 + _smoothed * 0.35;
            final scale = base + breathing * 0.08;
            final glowAlpha = (0.3 + _smoothed * 0.45).clamp(0.0, 0.75);

            return Transform.scale(
              scale: scale,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: glowAlpha),
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
