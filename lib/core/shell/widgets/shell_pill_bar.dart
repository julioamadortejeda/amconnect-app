import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../widgets/am_press.dart';
import '../../../l10n/app_localizations.dart';

/// Altura de la píldora de navegación inferior de la shell.
const kShellBarHeight = 64.0;

// Padding vertical del indicador deslizante dentro de la píldora
const _kIndicatorVPad = 8.0;
// Padding horizontal extra a cada lado del indicador
const _kIndicatorHPad = 6.0;

/// Descriptor de un tab de la barra inferior (icono normal + activo).
class ShellTab {
  const ShellTab({required this.icon, required this.activeIcon});
  final IconData icon;
  final IconData activeIcon;
}

/// Píldora de navegación inferior con indicador deslizante animado.
class ShellPillBar extends StatelessWidget {
  const ShellPillBar({
    super.key,
    required this.tabs,
    required this.activeIndex,
    required this.onTabSelected,
  });

  final List<ShellTab> tabs;
  final int activeIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: AmColors.shadowStrong,
            blurRadius: 20,
            offset: Offset(0, 4),
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
              Row(
                children: tabs
                    .asMap()
                    .entries
                    .map((e) => Expanded(
                          child: _TabItem(
                            t: e.value,
                            index: e.key,
                            active: activeIndex == e.key,
                            onTap: onTabSelected,
                          ),
                        ))
                    .toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.t,
    required this.index,
    required this.active,
    required this.onTap,
  });

  final ShellTab t;
  final int index;
  final bool active;
  final ValueChanged<int> onTap;

  String _label(AppLocalizations l10n) => switch (index) {
        0 => l10n.shellHome,
        1 => l10n.shellAgenda,
        2 => l10n.shellClients,
        3 => l10n.shellData,
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return AmPress(
      onTap: () => onTap(index),
      child: SizedBox(
        height: kShellBarHeight,
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
