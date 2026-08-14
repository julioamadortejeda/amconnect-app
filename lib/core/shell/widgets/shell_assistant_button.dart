import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../widgets/am_press.dart';

/// Diámetro del botón flotante del asistente de la shell.
const kShellAssistantSize = 64.0;

/// FAB del asistente: dispara un ripple de pantalla completa y navega a /chat.
///
/// Lleva el logo y no un micrófono a propósito. Antes tenía un mic y abría el
/// chat en modo texto, así que el icono prometía una cosa y pasaba otra. El
/// botón no declara un modo: la barra del composer decide si se escribe, se
/// dicta o se abre la voz Live.
class ShellAssistantButton extends ConsumerStatefulWidget {
  const ShellAssistantButton({super.key});

  @override
  ConsumerState<ShellAssistantButton> createState() => _ShellAssistantButtonState();
}

class _ShellAssistantButtonState extends ConsumerState<ShellAssistantButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  OverlayEntry? _ripple;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
  }

  @override
  void dispose() {
    _ripple?.remove();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    if (_ctrl.isAnimating) return;

    final box = context.findRenderObject() as RenderBox?;
    final center = box == null
        ? Offset.zero
        : box.localToGlobal(Offset(box.size.width / 2, box.size.height / 2));

    _ripple = OverlayEntry(
      builder: (_) => AnimatedBuilder(
        animation: _ctrl,
        builder: (ctx, __) {
          final t = Curves.easeOut.transform(_ctrl.value);
          final s = MediaQuery.sizeOf(ctx);
          final maxR = sqrt(s.width * s.width + s.height * s.height);
          return IgnorePointer(
            child: CustomPaint(
              painter: _RipplePainter(
                center: center,
                radius: maxR * t,
                alpha: (1 - t) * 0.5,
              ),
              child: const SizedBox.expand(),
            ),
          );
        },
      ),
    );

    Overlay.of(context).insert(_ripple!);
    _ctrl.forward(from: 0);

    // Show overlay partway through the ripple so they overlap briefly
    await Future.delayed(const Duration(milliseconds: 260));
    if (mounted) {
      GoRouter.of(context).push('/chat');
    }

    await Future.delayed(const Duration(milliseconds: 280));
    _ripple?.remove();
    _ripple = null;
  }

  @override
  Widget build(BuildContext context) {
    return AmPress(
      onTap: _onTap,
      child: Container(
        width: kShellAssistantSize,
        height: kShellAssistantSize,
        decoration: BoxDecoration(
          color: AmColors.accent,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Image.asset(
            'assets/logo/logo_t.png',
            color: AmColors.onAccent,
            width: 28,
            height: 28,
          ),
        ),
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  const _RipplePainter({
    required this.center,
    required this.radius,
    required this.alpha,
  });
  final Offset center;
  final double radius;
  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    if (radius <= 0 || alpha <= 0) return;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AmColors.accent.withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
  }

  @override
  bool shouldRepaint(_RipplePainter old) =>
      old.radius != radius || old.alpha != alpha;
}
