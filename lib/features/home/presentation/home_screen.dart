import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_loader.dart';
import '../../../core/widgets/am_section_label.dart';
import '../providers/home_provider.dart';
import '../widgets/home_clientes_recientes.dart';
import '../widgets/home_empty_section.dart';
import '../widgets/home_floating_btn.dart';
import '../widgets/home_header.dart';
import '../widgets/home_pendientes_card.dart';
import '../widgets/home_section_trailing.dart';
import '../widgets/home_stats_row.dart';
import '../../../l10n/app_localizations.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollCtrl = ScrollController();
  bool _showFloating = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    final shouldShow = _scrollCtrl.offset > 62;
    if (shouldShow != _showFloating) setState(() => _showFloating = shouldShow);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    if (!ref.watch(homeReadyProvider).hasValue) return const AmLoader();

    final data = ref.watch(homeDashboardProvider);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(AmDimens.screenH, 0, AmDimens.screenH, AmDimens.scrollBottomPad),
              children: [
                const SizedBox(height: 8),
                HomeHeader(agentName: data.agentName, urgentCount: data.urgentCount),
                const SizedBox(height: AmDimens.gapM),
                HomeStatsRow(
                  polizas: data.polizasCount,
                  porRenovar: data.porRenovar,
                  seguimientos: data.followUps.length,
                ),
                const SizedBox(height: AmDimens.gapL),
                AmSectionLabel(
                  label: l10n.homePendientes,
                  trailing: HomeSectionTrailing(
                    label: data.pending.length > 4
                        ? l10n.homeViewAllCount(data.pending.length)
                        : l10n.homeViewAgenda,
                    onTap: () => context.push('/reminders'),
                  ),
                ),
                const SizedBox(height: AmDimens.gapXS),
                if (data.pending.isNotEmpty)
                  HomePendientesCard(reminders: data.pending.take(4).toList())
                else
                  HomeEmptySection(message: l10n.homeEmptyPendientes),
                const SizedBox(height: AmDimens.gapL),
                AmSectionLabel(
                  label: l10n.homeSeguimientos,
                  trailing: data.followUps.length > 3 ? HomeSectionTrailing(
                    label: l10n.homeViewAllCount(data.followUps.length),
                    onTap: () => context.push('/reminders'),
                  ) : null,
                ),
                const SizedBox(height: AmDimens.gapXS),
                if (data.followUps.isNotEmpty)
                  HomePendientesCard(reminders: data.followUps.take(3).toList())
                else
                  HomeEmptySection(message: l10n.homeEmptySeguimientos),
                const SizedBox(height: AmDimens.gapL),
                AmSectionLabel(
                  label: l10n.homeClientesRecientes,
                  trailing: HomeSectionTrailing(
                    label: data.clientsCount > 0
                        ? l10n.homeViewAllCount(data.clientsCount)
                        : l10n.homeViewAll,
                    onTap: () => context.go('/clients'),
                  ),
                ),
                const SizedBox(height: AmDimens.gapXS),
                if (data.clientsCount > 0)
                  const HomeClientesRecientes()
                else
                  HomeEmptySection(message: l10n.homeEmptyClientes),
              ],
            ),
            IgnorePointer(
              ignoring: !_showFloating,
              child: AnimatedOpacity(
                opacity: _showFloating ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 120),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AmDimens.screenH, 8, AmDimens.screenH, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      HomeFloatingBtn(
                        onTap: () => _scrollCtrl.animateTo(0,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOut),
                        child: Image.asset('assets/logo/logo_t.png', width: 32, height: 32),
                      ),
                      HomeFloatingBtn(
                        onTap: () => context.push('/reminders'),
                        dot: data.urgentCount > 0,
                        child: Icon(Icons.notifications_outlined,
                            size: 20, color: cs.onSurface),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
