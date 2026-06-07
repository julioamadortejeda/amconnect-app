import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:amconnect/core/theme/app_colors.dart';
import 'package:amconnect/core/widgets/am_press.dart';
import 'package:amconnect/l10n/app_localizations.dart';

class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  static const _tabs = [
    _Tab(path: '/home',     icon: Icons.home_outlined),
    _Tab(path: '/agenda',   icon: Icons.calendar_today_outlined),
    _Tab(path: '/clientes', icon: Icons.group_outlined),
    _Tab(path: '/datos',    icon: Icons.folder_outlined),
  ];

  String get _activeTab {
    for (final t in _tabs) {
      if (location.startsWith(t.path)) return t.path;
    }
    return '/home';
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: AmColors.bgLight,
      body: child,
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: EdgeInsets.only(
                  left: 14,
                  right: 14,
                  top: 10,
                  bottom: bottom + 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xDDF5F6F7),
                  border: Border(
                    top: BorderSide(color: Colors.black.withValues(alpha: 0.07), width: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ..._tabs.sublist(0, 2).map((t) => _TabItem(t: t, active: _activeTab == t.path)),
                    const SizedBox(width: 60),
                    ..._tabs.sublist(2, 4).map((t) => _TabItem(t: t, active: _activeTab == t.path)),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -30,
            left: 0,
            right: 0,
            child: Center(
              child: AmPress(
                onTap: () => context.push('/chat'),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AmColors.accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AmColors.accent.withValues(alpha: 0.4),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.mic_none_rounded, color: Colors.white, size: 26),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab {
  const _Tab({required this.path, required this.icon});
  final String path;
  final IconData icon;
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.t, required this.active});
  final _Tab t;
  final bool active;

  String _label(AppLocalizations l10n) => switch (t.path) {
    '/home'     => l10n.shellHome,
    '/agenda'   => l10n.shellAgenda,
    '/clientes' => l10n.shellClients,
    '/datos'    => l10n.shellData,
    _           => '',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AmPress(
      onTap: () => context.go(t.path),
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              t.icon,
              size: 23,
              color: active ? AmColors.accent : AmColors.mutedLight,
            ),
            const SizedBox(height: 3),
            Text(
              _label(l10n),
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: active ? AmColors.accentInk : AmColors.mutedLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
