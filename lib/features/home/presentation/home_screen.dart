import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:amconnect/core/theme/app_colors.dart';
import 'package:amconnect/core/theme/app_dimensions.dart';
import 'package:amconnect/core/widgets/am_section_label.dart';
import 'package:amconnect/features/home/providers/home_provider.dart';
import 'package:amconnect/features/clients/providers/clients_provider.dart';
import 'package:amconnect/features/home/widgets/home_clientes_recientes.dart';
import 'package:amconnect/core/widgets/am_loader.dart';
import 'package:amconnect/features/home/widgets/home_floating_btn.dart';
import 'package:amconnect/features/home/widgets/home_header.dart';
import 'package:amconnect/features/home/widgets/home_pendientes_card.dart';
import 'package:amconnect/features/home/widgets/home_seguimiento_card.dart';
import 'package:amconnect/features/home/widgets/home_stats_row.dart';
import 'package:amconnect/l10n/app_localizations.dart';

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

    final ready = ref.watch(homeReadyProvider);
    if (!ready.hasValue) return const AmLoader();

    final reminders    = ref.watch(remindersProvider).asData?.value ?? [];
    final agentName    = ref.watch(agentNameProvider).asData?.value ?? '';
    final polizasCount = ref.watch(policiesCountProvider).asData?.value ?? 0;
    final clientsCount = ref.watch(clientsProvider).asData?.value?.length ?? 0;

    final pending    = reminders.where((r) => !r.hecho).toList();
    final urgentCount = pending.where((r) => r.urgente).length;
    final porRenovar  = pending.where((r) => r.tipo == 'RENEWAL').length;

    // Seguimientos: FOLLOW_UP reminders pendientes, ordenados por fecha más próxima
    final followUps = (pending.where((r) => r.tipo == 'FOLLOW_UP').toList())
      ..sort((a, b) => a.fecha.compareTo(b.fecha));

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(AmDimens.screenH, 0, AmDimens.screenH, AmDimens.scrollBottomPad),
              children: [
                const SizedBox(height: 8),
                HomeHeader(agentName: agentName, urgentCount: urgentCount),
                const SizedBox(height: AmDimens.gapM),
                HomeStatsRow(
                  polizas: polizasCount,
                  porRenovar: porRenovar,
                  seguimientos: followUps.length,
                ),
                const SizedBox(height: AmDimens.gapL),
                AmSectionLabel(
                  label: l10n.homePendientes,
                  trailing: GestureDetector(
                    onTap: () => context.push('/agenda'),
                    child: Text(
                      pending.length > 4
                          ? l10n.homeViewAllCount(pending.length)
                          : l10n.homeViewAgenda,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: AmColors.accent),
                    ),
                  ),
                ),
                const SizedBox(height: AmDimens.gapXS),
                if (pending.isNotEmpty)
                  HomePendientesCard(reminders: pending.take(4).toList()),
                const SizedBox(height: AmDimens.gapL),
                if (followUps.isNotEmpty) ...[
                  AmSectionLabel(
                    label: l10n.homeSeguimientos,
                    trailing: followUps.length > 3 ? GestureDetector(
                      onTap: () => context.push('/agenda'),
                      child: Text(
                        l10n.homeViewAllCount(followUps.length),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                            color: AmColors.accent),
                      ),
                    ) : null,
                  ),
                  const SizedBox(height: AmDimens.gapXS),
                  ...followUps.take(3).map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: HomeSeguimientoCard(reminder: r),
                      )),
                  const SizedBox(height: 6),
                ],
                AmSectionLabel(
                  label: l10n.homeClientesRecientes,
                  trailing: GestureDetector(
                    onTap: () => context.go('/clientes'),
                    child: Text(
                      clientsCount > 0
                          ? l10n.homeViewAllCount(clientsCount)
                          : l10n.homeViewAll,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: AmColors.accent),
                    ),
                  ),
                ),
                const SizedBox(height: AmDimens.gapXS),
                const HomeClientesRecientes(),
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
                        onTap: () => context.push('/agenda'),
                        dot: urgentCount > 0,
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
