import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/providers/home_provider.dart';
import '../../features/feed/presentation/ingest_flow_overlay.dart';
import '../providers/provider_keep_alive.dart';
import '../../features/share_target/widgets/share_handler_listener.dart';
import 'widgets/shell_mic_button.dart';
import 'widgets/shell_pill_bar.dart';

const _kMicRight = 16.0;
const _kGap = 6.0;
const _kBarLeft = 16.0;
const _kBarRight = _kMicRight + kShellMicSize + _kGap;

class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    ShellTab(icon: Icons.home_outlined, activeIcon: Icons.home),
    ShellTab(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today),
    ShellTab(icon: Icons.folder_shared_outlined, activeIcon: Icons.folder_shared),
    ShellTab(icon: Icons.folder_outlined, activeIcon: Icons.folder),
  ];

  void _onTabSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final activeIndex = navigationShell.currentIndex;
    final barVisible =
        activeIndex != 0 || ref.watch(homeReadyProvider).hasValue;

    return ShareHandlerListener(
      child: Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: navigationShell),

          // Escucha ingestProvider durante toda la sesión, sin importar el
          // tab activo — ver comentario en ingest_flow_overlay.dart.
          // Positioned.fill (no un hijo plano) para no alterar el cálculo de
          // tamaño del Stack: un hijo no-posicionado fuerza al Stack a
          // dimensionarse por sus hijos no-posicionados en vez de llenar las
          // constraints del Scaffold, colapsando todo a tamaño cero.
          const Positioned.fill(child: IngestFlowOverlay()),

          // Mantiene activos los providers compartidos entre tabs para que
          // sus rebuilds nunca queden diferidos al resume de un tab oculto —
          // ver comentario en provider_keep_alive.dart.
          const Positioned.fill(child: ProviderKeepAlive()),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOut,
            left: _kBarLeft,
            right: _kBarRight,
            bottom: barVisible ? bottom : -(bottom + kShellBarHeight),
            height: kShellBarHeight,
            child: ShellPillBar(
              tabs: _tabs,
              activeIndex: activeIndex,
              onTabSelected: _onTabSelected,
            ),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOut,
            right: _kMicRight,
            bottom: barVisible ? bottom : -(bottom + kShellMicSize),
            width: kShellMicSize,
            height: kShellMicSize,
            child: const ShellMicButton(),
          ),
        ],
      ),
    ),
  );
  }
}
