import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/providers/permission_provider.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_loader.dart';
import '../../../core/widgets/am_section_label.dart';
import '../../../core/providers/commitments_provider.dart';
import '../../reminders/providers/reminders_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/home_clientes_recientes.dart';
import '../widgets/home_empty_section.dart';
import '../widgets/home_floating_btn.dart';
import '../widgets/home_header.dart';
import '../../../core/widgets/am_commitments_card.dart';
import '../widgets/home_pendientes_card.dart';
import '../widgets/home_section_trailing.dart';
import '../widgets/home_stats_row.dart';
import '../widgets/notifications_permission_banner.dart';
import '../../../core/widgets/am_stagger.dart';
import '../../../l10n/app_localizations.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  final _scrollCtrl = ScrollController();
  bool _showFloating = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addObserver(this);
  }

  void _onScroll() {
    final shouldShow = _scrollCtrl.offset > 62;
    if (shouldShow != _showFloating) setState(() => _showFloating = shouldShow);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al volver de Ajustes del sistema (p.ej. tras activar notificaciones),
    // refresca el estado del permiso para que el banner desaparezca solo.
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(notificationPermissionStatusProvider);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    if (!ref.watch(homeReadyProvider).hasValue) return const AmLoader();

    final data = ref.watch(homeDashboardProvider);
    // Sin `.when`: si los compromisos aún cargan o fallan, el dashboard se pinta
    // igual sin la sección. No es dato crítico como para bloquear la pantalla.
    final commitments = ref.watch(commitmentsProvider).asData?.value ?? const [];
    final notifPermission = ref.watch(notificationPermissionStatusProvider).asData?.value;
    final showNotifBanner = notifPermission != null &&
        (notifPermission.isDenied || notifPermission.isPermanentlyDenied);
    int aniIdx = 0;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(AmDimens.screenH, 0,
                  AmDimens.screenH, AmDimens.scrollBottomPad),
              children: [
                const SizedBox(height: 8),
                if (showNotifBanner) ...[
                  AmAnimateIn(
                    index: aniIdx++,
                    child: NotificationsPermissionBanner(
                      onTap: () => context.push('/account'),
                    ),
                  ),
                  const SizedBox(height: AmDimens.gapM),
                ],
                AmAnimateIn(
                  index: aniIdx++,
                  child: HomeHeader(
                      agentName: data.agentName, urgentCount: data.urgentCount),
                ),
                const SizedBox(height: AmDimens.gapM),
                AmAnimateIn(
                  index: aniIdx++,
                  child: HomeStatsRow(
                    polizas: data.polizasCount,
                    porRenovar: data.porRenovar,
                    seguimientos: data.followUps.length,
                  ),
                ),
                const SizedBox(height: AmDimens.gapL),
                // Va antes que todo lo demás a propósito: es lo único del
                // dashboard que le dice al asesor qué está a punto de
                // perderse. Si no hay nada pendiente, la sección no aparece —
                // un "no tienes nada" en el primer lugar de la pantalla ocupa
                // el espacio más caro para no decir nada.
                if (commitments.isNotEmpty) ...[
                  AmAnimateIn(
                    index: aniIdx++,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AmSectionLabel(
                          label: l10n.commitmentsTitle,
                          trailing: commitments.length > 4
                              ? HomeSectionTrailing(
                                  label: l10n.homeViewAllCount(commitments.length),
                                  // A la pestaña de compromisos, no a la de
                                  // recordatorios: antes "ver los 5" llevaba a
                                  // una pantalla donde no salía ninguno.
                                  onTap: () {
                                    ref
                                        .read(agendaTabProvider.notifier)
                                        .select(AgendaTab.commitments);
                                    context.go('/reminders');
                                  },
                                )
                              : null,
                        ),
                        const SizedBox(height: AmDimens.gapXS),
                        AmCommitmentsCard(commitments: commitments),
                      ],
                    ),
                  ),
                  const SizedBox(height: AmDimens.gapL),
                ],
                AmAnimateIn(
                  index: aniIdx++,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AmSectionLabel(
                        label: l10n.homePendientes,
                        trailing: HomeSectionTrailing(
                          label: data.pending.length > 4
                              ? l10n.homeViewAllCount(data.pending.length)
                              : l10n.homeViewAgenda,
                          // Explícito: la pestaña se queda como el asesor la
                          // dejó, y sin esto "ver agenda" podía abrir la de
                          // compromisos.
                          onTap: () {
                            ref
                                .read(agendaTabProvider.notifier)
                                .select(AgendaTab.reminders);
                            context.go('/reminders');
                          },
                        ),
                      ),
                      const SizedBox(height: AmDimens.gapXS),
                      if (data.pending.isNotEmpty)
                        HomePendientesCard(
                            reminders: data.pending.take(4).toList())
                      else
                        HomeEmptySection(message: l10n.homeEmptyPendientes),
                    ],
                  ),
                ),
                const SizedBox(height: AmDimens.gapL),
                AmAnimateIn(
                  index: aniIdx++,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AmSectionLabel(
                        label: l10n.homeSeguimientos,
                        trailing: data.followUps.length > 3
                            ? HomeSectionTrailing(
                                label: l10n
                                    .homeViewAllCount(data.followUps.length),
                                onTap: () {
                                  ref
                                      .read(agendaTabProvider.notifier)
                                      .select(AgendaTab.reminders);
                                  context.go('/reminders');
                                },
                              )
                            : null,
                      ),
                      const SizedBox(height: AmDimens.gapXS),
                      if (data.followUps.isNotEmpty)
                        HomePendientesCard(
                            reminders: data.followUps.take(3).toList())
                      else
                        HomeEmptySection(message: l10n.homeEmptySeguimientos),
                    ],
                  ),
                ),
                const SizedBox(height: AmDimens.gapL),
                AmAnimateIn(
                  index: aniIdx++,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AmSectionLabel(
                        label: l10n.homeClientesRecientes,
                        trailing: HomeSectionTrailing(
                          label: data.clientsCount > 0
                              ? l10n.homeViewAllCount(data.clientsCount)
                              : l10n.homeViewAll,
                          onTap: () => context.go('/portfolio'),
                        ),
                      ),
                      const SizedBox(height: AmDimens.gapXS),
                      if (data.clientsCount > 0)
                        const HomeClientesRecientes()
                      else
                        HomeEmptySection(message: l10n.homeEmptyClientes),
                    ],
                  ),
                ),
              ],
            ),
            IgnorePointer(
              ignoring: !_showFloating,
              child: AnimatedOpacity(
                opacity: _showFloating ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 120),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AmDimens.screenH, 8, AmDimens.screenH, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      HomeFloatingBtn(
                        onTap: () => _scrollCtrl.animateTo(0,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOut),
                        child: Image.asset('assets/logo/logo.png',
                            width: 32, height: 32),
                      ),
                      HomeFloatingBtn(
                        onTap: () => context.push('/analytics'),
                        child: Icon(Icons.bar_chart_rounded,
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
