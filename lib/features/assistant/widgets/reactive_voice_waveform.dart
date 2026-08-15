import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Barras de ecualizador reactivas al nivel de audio REAL del micrófono
/// (0..1, ver [GeminiVoiceEngine.micLevel]) — a diferencia de la onda
/// decorativa de `VoiceWaveformBars`, aquí en silencio las barras se aplanan
/// y solo suben cuando el usuario efectivamente habla.
class ReactiveVoiceWaveform extends StatefulWidget {
  const ReactiveVoiceWaveform({
    super.key,
    required this.level,
    required this.color,
    this.maxHeight = 24.0,
  });

  final ValueListenable<double> level;

  /// Color de las barras — lo decide quien la usa, porque vive sobre fondos
  /// distintos: el pill azul de la voz Live y el composer de texto.
  final Color color;

  final double maxHeight;

  @override
  State<ReactiveVoiceWaveform> createState() => _ReactiveVoiceWaveformState();
}

class _ReactiveVoiceWaveformState extends State<ReactiveVoiceWaveform>
    with SingleTickerProviderStateMixin {
  // Wobble continuo por barra (efecto ecualizador) — el envolvente real lo
  // marca _smoothed, esto solo evita que todas las barras suban parejas.
  late final AnimationController _wobbleCtrl;
  double _smoothed = 0.0;

  @override
  void initState() {
    super.initState();
    _wobbleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    widget.level.addListener(_onLevelChanged);
  }

  // Ataque rápido / release lento — como un VU-meter: sube de inmediato con
  // la voz, baja suave para no verse nervioso entre samples.
  void _onLevelChanged() {
    final target = widget.level.value;
    setState(() {
      _smoothed = target > _smoothed ? target : _smoothed * 0.82 + target * 0.18;
    });
  }

  @override
  void didUpdateWidget(ReactiveVoiceWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level != widget.level) {
      oldWidget.level.removeListener(_onLevelChanged);
      widget.level.addListener(_onLevelChanged);
    }
  }

  @override
  void dispose() {
    widget.level.removeListener(_onLevelChanged);
    _wobbleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const barCount = 11;
    const minH = 5.0;
    final maxH = widget.maxHeight;

    return SizedBox(
      height: maxH + 4,
      child: AnimatedBuilder(
        animation: _wobbleCtrl,
        builder: (_, __) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(barCount, (i) {
              final phase = (i / barCount) * 2 * pi;
              final wobble = sin(_wobbleCtrl.value * 2 * pi + phase) * 0.5 + 0.5;
              final barLevel = (_smoothed * (0.55 + wobble * 0.45)).clamp(0.0, 1.0);
              final h = minH + (maxH - minH) * barLevel;
              final isCenter = i == barCount ~/ 2;
              final opacity = 0.38 + barLevel * 0.62;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: isCenter ? 5 : 4,
                height: h,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: opacity),
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
