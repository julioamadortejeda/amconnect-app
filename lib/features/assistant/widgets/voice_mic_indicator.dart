import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/assistant_provider.dart';

/// Ícono de micrófono que hace explícito cuándo el usuario aún NO puede
/// hablar (conectando: atenuado, con un anillo pulsante tipo "buscando") y
/// el instante exacto en que ya sí puede (un solo rebote + destello de
/// confirmación + haptic, luego queda sólido). Sin esto solo cambiaba el
/// texto de la barra y el usuario no notaba la transición.
class VoiceMicIndicator extends StatefulWidget {
  const VoiceMicIndicator({super.key, required this.status});

  final VoiceStatus status;

  @override
  State<VoiceMicIndicator> createState() => _VoiceMicIndicatorState();
}

class _VoiceMicIndicatorState extends State<VoiceMicIndicator>
    with TickerProviderStateMixin {
  // Anillo pulsante en bucle mientras se conecta ("buscando/preparando").
  late final AnimationController _pulseCtrl;
  // Rebote + destello de una sola vez al pasar a listo.
  late final AnimationController _readyCtrl;

  bool get _wasConnecting => widget.status == VoiceStatus.connecting;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _readyCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    if (_wasConnecting) {
      _pulseCtrl.repeat();
    } else {
      _readyCtrl.value = 1;
    }
  }

  @override
  void didUpdateWidget(VoiceMicIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    final becameReady = oldWidget.status == VoiceStatus.connecting &&
        widget.status != VoiceStatus.connecting &&
        widget.status != VoiceStatus.error;
    if (becameReady) {
      _pulseCtrl.stop();
      HapticFeedback.mediumImpact();
      _readyCtrl.forward(from: 0);
    } else if (widget.status == VoiceStatus.connecting && !_pulseCtrl.isAnimating) {
      _readyCtrl.value = 0;
      _pulseCtrl.repeat();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _readyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = 34.0;
    final connecting = widget.status == VoiceStatus.connecting;
    final error = widget.status == VoiceStatus.error;

    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseCtrl, _readyCtrl]),
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Anillo de "preparando" — pulso continuo mientras no está listo.
              if (connecting)
                _buildPulseRing(size),
              // Destello de confirmación — una sola expansión al quedar listo.
              if (!error && _readyCtrl.value > 0 && _readyCtrl.value < 1)
                _buildReadyBurst(size),
              // Ícono: contorno atenuado (aún no puedes hablar) → relleno
              // sólido con un pequeño rebote (ya puedes hablar). En error,
              // mic tachado y sin animación.
              Transform.scale(
                scale: (connecting || error)
                    ? 1.0
                    : 1.0 + (_bounceCurve(_readyCtrl.value) * 0.22),
                child: Icon(
                  error
                      ? Icons.mic_off_rounded
                      : connecting
                          ? Icons.mic_none_rounded
                          : Icons.mic_rounded,
                  size: 19,
                  color: Colors.white
                      .withValues(alpha: (connecting || error) ? 0.55 : 1.0),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Rebote simple: sube y vuelve a 1.0 (no un curve estándar porque solo
  // queremos el "pop" en la primera mitad de _readyCtrl).
  double _bounceCurve(double t) {
    if (t >= 1.0) return 0.0;
    return Curves.elasticOut.transform(t) * (1 - t);
  }

  Widget _buildPulseRing(double size) {
    final t = _pulseCtrl.value;
    final scale = 1.0 + t * 0.9;
    final opacity = (1.0 - t).clamp(0.0, 1.0) * 0.55;
    return Transform.scale(
      scale: scale,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: opacity),
            width: 1.6,
          ),
        ),
      ),
    );
  }

  Widget _buildReadyBurst(double size) {
    final t = _readyCtrl.value;
    final scale = 1.0 + t * 1.1;
    final opacity = (1.0 - t).clamp(0.0, 1.0);
    return Transform.scale(
      scale: scale,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity * 0.35),
        ),
      ),
    );
  }
}
