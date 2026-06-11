import 'package:flutter/material.dart';

class VoiceEdgeGlow extends StatefulWidget {
  const VoiceEdgeGlow({super.key});

  @override
  State<VoiceEdgeGlow> createState() => _VoiceEdgeGlowState();
}

class _VoiceEdgeGlowState extends State<VoiceEdgeGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
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
      builder: (_, __) => CustomPaint(
        painter: _EdgeGlowPainter(_ctrl.value),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _EdgeGlowPainter extends CustomPainter {
  const _EdgeGlowPainter(this.t);
  final double t;

  // Color palette that cycles: blue → purple → pink → orange → blue
  static const _palette = [
    Color(0xFF007AC0),
    Color(0xFF6D28D9),
    Color(0xFFEC4899),
    Color(0xFFF97316),
    Color(0xFF007AC0),
  ];

  Color _lerp(double pos) {
    final p = pos.clamp(0.0, 1.0);
    final scaled = p * (_palette.length - 1);
    final i = scaled.floor().clamp(0, _palette.length - 2);
    return Color.lerp(_palette[i], _palette[i + 1], scaled - i)!;
  }

  void _drawGradient(
    Canvas canvas,
    Rect rect,
    Color color,
    Alignment begin,
    Alignment end,
    double alpha,
  ) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: begin,
        end: end,
        colors: [color.withValues(alpha: alpha), Colors.transparent],
        stops: const [0.0, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Each gradient covers ~65% of the dimension so they overlap and blend
    // in the center — no uncolored grey zone left.
    final hw = size.width * 0.65;
    final hh = size.height * 0.60;

    final leftColor   = _lerp(t);
    final rightColor  = _lerp((t + 0.5).remainder(1.0));
    final bottomColor = _lerp((t + 0.25).remainder(1.0));
    final topColor    = _lerp((t + 0.75).remainder(1.0));

    // Left
    _drawGradient(
      canvas,
      Rect.fromLTWH(0, 0, hw, size.height),
      leftColor,
      Alignment.centerLeft, Alignment.centerRight,
      0.65,
    );

    // Right
    _drawGradient(
      canvas,
      Rect.fromLTWH(size.width - hw, 0, hw, size.height),
      rightColor,
      Alignment.centerRight, Alignment.centerLeft,
      0.65,
    );

    // Bottom
    _drawGradient(
      canvas,
      Rect.fromLTWH(0, size.height - hh, size.width, hh),
      bottomColor,
      Alignment.bottomCenter, Alignment.topCenter,
      0.50,
    );

    // Top
    _drawGradient(
      canvas,
      Rect.fromLTWH(0, 0, size.width, hh * 0.7),
      topColor,
      Alignment.topCenter, Alignment.bottomCenter,
      0.42,
    );
  }

  @override
  bool shouldRepaint(_EdgeGlowPainter old) => old.t != t;
}
