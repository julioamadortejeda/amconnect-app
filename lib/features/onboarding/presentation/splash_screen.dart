import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..forward(from: 0);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();

    Future.delayed(const Duration(milliseconds: 2100), () {
      if (mounted) context.go('/login');
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/login'),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2EB0FF), Color(0xFF007AC0), Color(0xFF005A8A)],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pulsing rings + logo
                  SizedBox(
                    width: 132,
                    height: 132,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Rings
                        ...List.generate(3, (i) => _PulseRing(ctrl: _pulseCtrl, delay: i * 0.5)),
                        // Logo
                        ScaleTransition(
                          scale: CurvedAnimation(
                            parent: _logoCtrl,
                            curve: const Interval(0, 1, curve: Curves.elasticOut),
                          ),
                          child: Image.asset('assets/logo/logo_t.png', width: 108, height: 108,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  // Title
                  FadeTransition(
                    opacity: CurvedAnimation(parent: _textCtrl, curve: const Interval(0.3, 1)),
                    child: Column(
                      children: [
                        const Text('AMConnect',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: -0.01,
                            )),
                        const SizedBox(height: 6),
                        Text('by JACAT',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.78),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                  // Loading dots
                  _LoadingDots(ctrl: _pulseCtrl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  const _PulseRing({required this.ctrl, required this.delay});
  final AnimationController ctrl;
  final double delay;

  @override
  Widget build(BuildContext context) {
    final anim = CurvedAnimation(
      parent: ctrl,
      curve: Interval(delay / 3, ((delay / 3) + 0.67).clamp(0.0, 1.0), curve: Curves.easeOut),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) => Transform.scale(
        scale: 0.9 + anim.value * 1.0,
        child: Opacity(
          opacity: (1 - anim.value) * 0.55,
          child: Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.ctrl});
  final AnimationController ctrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final anim = CurvedAnimation(
          parent: ctrl,
          curve: Interval(i * 0.15, i * 0.15 + 0.5, curve: Curves.easeInOut),
        );
        return AnimatedBuilder(
          animation: anim,
          builder: (_, __) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.4 + anim.value * 0.6),
              shape: BoxShape.circle,
            ),
            transform: Matrix4.translationValues(0, -anim.value * 5, 0),
          ),
        );
      }),
    );
  }
}
