import 'dart:math';
import 'package:flutter/material.dart';

/// Holographic border glow that mimics the iOS Siri / Apple Intelligence
/// activation effect: large soft fields of color hugging the screen edges,
/// drifting slowly around the perimeter. No sharp lines — everything is
/// diffuse bloom, brightest at the very edge and fading inward.
///
/// On entry the glow "paints itself" clockwise starting from the right edge;
/// once complete, the colors rotate continuously.
class AmAurora extends StatefulWidget {
  const AmAurora({super.key, this.delay = Duration.zero});

  /// How long to wait before starting the entry sweep.
  /// Set this to match the parent overlay's transition duration so the
  /// sweep only begins once the screen is fully visible.
  final Duration delay;

  @override
  State<AmAurora> createState() => _AmAuroraState();
}

class _AmAuroraState extends State<AmAurora> with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _loopCtrl;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _loopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9000),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      final route = ModalRoute.of(context);
      if (route != null) {
        if (route.animation!.isCompleted) {
          _startEntry();
        } else {
          void listener(AnimationStatus status) {
            if (status == AnimationStatus.completed) {
              _startEntry();
              route.animation!.removeStatusListener(listener);
            }
          }

          route.animation!.addStatusListener(listener);
        }
      } else {
        _startEntry();
      }
    }
  }

  void _startEntry() {
    if (widget.delay == Duration.zero) {
      if (mounted) _entryCtrl.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _entryCtrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _loopCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routeAnimation = ModalRoute.of(context)?.animation;
    final animList = <Listenable>[_entryCtrl, _loopCtrl];
    if (routeAnimation != null) {
      animList.add(routeAnimation);
    }
    return AnimatedBuilder(
      animation: Listenable.merge(animList),
      builder: (context, __) {
        final routeVal = routeAnimation?.value ?? 1.0;
        // Bypasses painting completely (entry = 0.0) during transitions to optimize GPU/CPU frames
        final visibleEntry = _entryCtrl.value * (routeVal < 0.99 ? 0.0 : 1.0);
        return CustomPaint(
          painter: _AuroraPainter(entry: visibleEntry, loop: _loopCtrl.value),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _AuroraPainter extends CustomPainter {
  const _AuroraPainter({required this.entry, required this.loop});

  final double entry; // 0→1 once
  final double loop; // 0→1 repeating

  // App blue family: sky → primary #007AC0 → deep navy → indigo → sky (closed).
  static const _palette = [
    Color(0xFF38BEFF), // sky blue
    Color(0xFF007AC0), // app primary
    Color(0xFF003F9E), // deep navy
    Color(0xFF4F6EF7), // indigo
    Color(0xFF38BEFF), // sky blue (close)
  ];

  // Deep navy is at stop 2/4. Rotate so primary blue faces east at loop=0.
  static final _initialRotation = -(1.0 / 4.0) * 2 * pi;

  // Matches iPhone screen corner curvature so the glow hugs the corners.
  static const _cornerRadius = 48.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (entry <= 0.0) return;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final shader = SweepGradient(
      colors: _palette,
      transform: GradientRotation(_initialRotation + loop * 2 * pi),
    ).createShader(rect);

    // Rounded path along the screen edge — outer half of every stroke is
    // clipped at the screen boundary so the glow only spreads inward.
    final edgePath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        rect.deflate(1),
        const Radius.circular(_cornerRadius),
      ));
    final metrics = edgePath.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final m = metrics.first;
    final total = m.length;

    final Path drawn;
    if (entry >= 1.0) {
      drawn = edgePath;
    } else {
      // RRect path also starts near the top and runs clockwise. Start the
      // sweep at the top-right corner so the first visible color appears
      // on the right edge.
      final startLen =
          (size.width - 2) / (2 * (size.width + size.height - 4)) * total;
      final sweepLen = total * Curves.easeInOut.transform(entry);

      if (sweepLen >= total) {
        drawn = edgePath;
      } else {
        final endLen = startLen + sweepLen;
        if (endLen <= total) {
          drawn = m.extractPath(startLen, endLen);
        } else {
          // Wrap-around: two segments joined
          drawn = Path()
            ..addPath(m.extractPath(startLen, total), Offset.zero)
            ..addPath(m.extractPath(0, endLen - total), Offset.zero);
        }
      }
    }

    // Subtle breathing so the glow feels alive (slow, ±5px)
    final breath = sin(loop * 2 * pi * 2) * 5;

    // ── Outer field: wide, very diffuse — the body of the glow ───────────
    // strokeWidth=72 → 36px visible inward; blur 30 carries it to ~65px,
    // but at low opacity so the center stays clean.
    canvas.drawPath(
      drawn,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 72 + breath
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30)
        ..shader = shader
        ..color = Colors.white.withValues(alpha: 0.55),
    );

    // ── Edge core: brighter but still soft — peak brightness at the rim ──
    canvas.drawPath(
      drawn,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
        ..shader = shader
        ..color = Colors.white.withValues(alpha: 0.85),
    );

    // ── Wave: soft light pockets drifting along the perimeter ────────────
    // Very large + very blurred so they read as brightness swells in the
    // color fields, not as distinct dots.
    const blobCount = 4;
    for (var i = 0; i < blobCount; i++) {
      final u = (loop + i / blobCount) % 1.0;
      final pos = m.getTangentForOffset(u * total)?.position;
      if (pos == null) continue;
      final pulse = 0.5 + 0.5 * sin(2 * pi * (loop * 2 + i * 0.41));
      final blobAlpha = (0.12 + 0.22 * pulse) * entry;
      canvas.drawCircle(
        pos,
        80 + 26 * pulse,
        Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 55)
          ..shader = shader
          ..color = Colors.white.withValues(alpha: blobAlpha),
      );
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter old) =>
      old.entry != entry || old.loop != loop;
}
