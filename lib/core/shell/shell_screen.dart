import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/providers/home_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/am_press.dart';
import '../../features/chat/widgets/voice_overlay.dart';
import '../../l10n/app_localizations.dart';

const _kMicSize = 64.0;
const _kMicRight = 16.0;
const _kGap = 6.0;
const _kBarLeft = 16.0;
const _kBarRight = _kMicRight + _kMicSize + _kGap;
const _kBarHeight = 64.0;
const _kBottomOffset = 8.0;

// Padding vertical del indicador deslizante dentro de la píldora
const _kIndicatorVPad = 8.0;
// Padding horizontal extra a cada lado del indicador
const _kIndicatorHPad = 6.0;

class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  static const _tabs = [
    _Tab(path: '/home',     icon: Icons.home_outlined,            activeIcon: Icons.home),
    _Tab(path: '/reminders', icon: Icons.calendar_today_outlined,  activeIcon: Icons.calendar_today),
    _Tab(path: '/clients',   icon: Icons.group_outlined,           activeIcon: Icons.group),
    _Tab(path: '/data',      icon: Icons.folder_outlined,          activeIcon: Icons.folder),
  ];

  String get _activeTab {
    for (final t in _tabs) {
      if (location.startsWith(t.path)) return t.path;
    }
    return '/home';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final barVisible = location != '/home' || ref.watch(homeReadyProvider).hasValue;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: child),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOut,
            left: _kBarLeft,
            right: _kBarRight,
            bottom: barVisible ? bottom + _kBottomOffset : -(bottom + _kBarHeight + _kBottomOffset),
            height: _kBarHeight,
            child: _PillBar(tabs: _tabs, activeTab: _activeTab),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOut,
            right: _kMicRight,
            bottom: barVisible ? bottom + _kBottomOffset : -(bottom + _kMicSize + _kBottomOffset),
            width: _kMicSize,
            height: _kMicSize,
            child: const _MicButton(),
          ),
        ],
      ),
    );
  }
}

class _Tab {
  const _Tab({required this.path, required this.icon, required this.activeIcon});
  final String path;
  final IconData icon;
  final IconData activeIcon;
}

/// Barra píldora con indicador deslizante estilo iOS.
/// Un único Container de fondo se anima entre posiciones con
/// AnimatedPositioned — misma técnica que usa UIKit en iOS 16+.
class _PillBar extends StatelessWidget {
  const _PillBar({required this.tabs, required this.activeTab});
  final List<_Tab> tabs;
  final String activeTab;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activeIndex = tabs.indexWhere((t) => t.path == activeTab);

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / tabs.length;
          final indicatorW = tabWidth - _kIndicatorHPad * 2;
          final indicatorLeft = activeIndex * tabWidth + _kIndicatorHPad;

          return Stack(
            children: [
              // Cápsula deslizante
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOutCubic,
                left: indicatorLeft,
                top: _kIndicatorVPad,
                bottom: _kIndicatorVPad,
                width: indicatorW,
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
              ),

              // Items encima de la cápsula
              Row(
                children: tabs.map((t) => Expanded(
                  child: _TabItem(t: t, active: activeTab == t.path),
                )).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.t, required this.active});
  final _Tab t;
  final bool active;

  String _label(AppLocalizations l10n) => switch (t.path) {
        '/home'      => l10n.shellHome,
        '/reminders' => l10n.shellAgenda,
        '/clients'   => l10n.shellClients,
        '/data'      => l10n.shellData,
        _            => '',
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return AmPress(
      onTap: () => context.go(t.path),
      child: SizedBox(
        height: _kBarHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                active ? t.activeIcon : t.icon,
                key: ValueKey(active),
                size: 22,
                color: active ? AmColors.accent : cs.tertiary,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: active ? AmColors.accent : cs.tertiary,
              ),
              child: Text(_label(l10n)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MicButton extends StatefulWidget {
  const _MicButton();

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton>
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
    if (mounted) VoiceOverlay.show(context);

    await Future.delayed(const Duration(milliseconds: 280));
    _ripple?.remove();
    _ripple = null;
  }

  @override
  Widget build(BuildContext context) {
    return AmPress(
      onTap: _onTap,
      child: Container(
        width: _kMicSize,
        height: _kMicSize,
        decoration: BoxDecoration(
          color: AmColors.accent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AmColors.accent.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.mic_none_rounded, color: Colors.white, size: 26),
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
