import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:amconnect/core/theme/app_colors.dart';
import 'package:amconnect/core/mock/mock_data.dart';
import 'package:amconnect/core/widgets/am_card.dart';
import 'package:amconnect/core/widgets/am_avatar.dart';
import 'package:amconnect/core/widgets/am_icon_btn.dart';
import 'package:amconnect/core/widgets/am_section_label.dart';
import 'package:amconnect/core/widgets/am_press.dart';
import 'package:amconnect/l10n/app_localizations.dart';

// ── Shared reminders provider ─────────────────────────────────────────────────

class RemindersNotifier extends Notifier<List<MockReminder>> {
  @override
  List<MockReminder> build() => mockReminders
      .map((r) => MockReminder(
            id: r.id, clienteId: r.clienteId, tipo: r.tipo, titulo: r.titulo,
            sub: r.sub, fecha: r.fecha, hora: r.hora, urgente: r.urgente, hecho: r.hecho,
          ))
      .toList();

  void toggle(String id) {
    state = [
      for (final r in state)
        if (r.id == id)
          MockReminder(
            id: r.id, clienteId: r.clienteId, tipo: r.tipo, titulo: r.titulo,
            sub: r.sub, fecha: r.fecha, hora: r.hora, urgente: r.urgente, hecho: !r.hecho,
          )
        else
          r,
    ];
  }
}

final remindersProvider =
    NotifierProvider<RemindersNotifier, List<MockReminder>>(RemindersNotifier.new);

// ── Screen ────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final reminders = ref.watch(remindersProvider);
    final pending = reminders.where((r) => !r.hecho).toList();
    final urgentCount = pending.where((r) => r.urgente).length;
    final porRenovar = pending.where((r) => r.tipo == 'renovacion').length;
    final attention = (mockClients.where((c) => c.diasSinContacto >= 7).toList()
      ..sort((a, b) => b.diasSinContacto.compareTo(a.diasSinContacto)));

    return Scaffold(
      backgroundColor: AmColors.bgLight,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
          children: [
            const SizedBox(height: 8),
            _Header(urgentCount: urgentCount),
            const SizedBox(height: 16),
            _StatsRow(
              polizas: mockStats['polizas']!,
              porRenovar: porRenovar,
              seguimientos: attention.length,
            ),
            const SizedBox(height: 20),
            AmSectionLabel(
              label: l10n.homePendientes,
              trailing: GestureDetector(
                onTap: () => context.push('/agenda'),
                child: Text(l10n.homeViewAgenda,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: AmColors.accent)),
              ),
            ),
            const SizedBox(height: 11),
            if (pending.isNotEmpty)
              _PendientesCard(reminders: pending.take(4).toList()),
            const SizedBox(height: 20),
            AmSectionLabel(label: l10n.homeSeguimientos),
            const SizedBox(height: 11),
            ...attention.take(2).map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: _SeguimientoCard(client: c),
                )),
            const SizedBox(height: 6),
            AmSectionLabel(
              label: l10n.homeClientesRecientes,
              trailing: GestureDetector(
                onTap: () => context.go('/clientes'),
                child: Text(l10n.homeViewAll,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: AmColors.accent)),
              ),
            ),
            const SizedBox(height: 11),
            const _ClientesRecientes(),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.urgentCount});
  final int urgentCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Image.asset('assets/logo/logo_t.png', width: 38, height: 38),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.homeTitle,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500,
                        color: AmColors.mutedLight, letterSpacing: 0.02)),
                Text(l10n.homeGreeting('Daniel'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600,
                        color: AmColors.inkLight, letterSpacing: -0.01)),
              ],
            ),
          ),
          AmIconBtn(
            icon: Icons.notifications_outlined,
            onTap: () => context.push('/agenda'),
            tone: AmIconBtnTone.soft,
            dot: urgentCount > 0,
          ),
        ],
      ),
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.polizas,
    required this.porRenovar,
    required this.seguimientos,
  });
  final int polizas, porRenovar, seguimientos;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tiles = [
      (polizas.toString(), l10n.homePolicies),
      (porRenovar.toString(), l10n.homeToRenew),
      (seguimientos.toString(), l10n.homeSeguimientos),
    ];
    return AmCard(
      noPad: true,
      child: IntrinsicHeight(
        child: Row(
          children: tiles.asMap().entries.map((e) {
            final (value, label) = e.value;
            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                decoration: BoxDecoration(
                  border: e.key > 0
                      ? const Border(left: BorderSide(color: AmColors.lineSoftLight))
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600,
                            color: AmColors.inkLight, letterSpacing: -0.02)),
                    const SizedBox(height: 3),
                    Text(label,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600,
                            color: AmColors.mutedLight)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Pendientes Card ───────────────────────────────────────────────────────────

class _PendientesCard extends StatelessWidget {
  const _PendientesCard({required this.reminders});
  final List<MockReminder> reminders;

  @override
  Widget build(BuildContext context) {
    return AmCard(
      noPad: true,
      child: Column(
        children: reminders.asMap().entries.map((e) {
          return _PendingRow(r: e.value, isLast: e.key == reminders.length - 1);
        }).toList(),
      ),
    );
  }
}

class _PendingRow extends StatelessWidget {
  const _PendingRow({required this.r, required this.isLast});
  final MockReminder r;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final (iconData, iconColor, iconBg) = switch (r.tipo) {
      'pago'       => (Icons.payments_outlined, AmColors.amberLight, AmColors.amberWashLight),
      'renovacion' => (Icons.autorenew, AmColors.accentInk, AmColors.accentWash),
      _            => (Icons.phone_outlined, AmColors.greenLight, AmColors.greenWashLight),
    };

    return AmPress(
      onTap: () {
        final c = clientById(r.clienteId);
        if (c != null) context.push('/clientes/${c.id}');
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
        decoration: isLast
            ? null
            : const BoxDecoration(
                border: Border(bottom: BorderSide(color: AmColors.lineSoftLight))),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: r.urgente ? AmColors.redWashLight : iconBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(iconData, size: 18,
                  color: r.urgente ? AmColors.redLight : iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.titulo,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500,
                          color: AmColors.inkLight),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(r.sub,
                      style: const TextStyle(fontSize: 12.5, color: AmColors.mutedLight)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (r.urgente)
              Container(
                width: 7, height: 7,
                margin: const EdgeInsets.only(right: 6),
                decoration: const BoxDecoration(
                    color: AmColors.redLight, shape: BoxShape.circle),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: r.urgente ? AmColors.redWashLight : AmColors.cardSunkenLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(r.fecha,
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: r.urgente ? AmColors.redLight : AmColors.mutedLight,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Seguimiento Card ──────────────────────────────────────────────────────────

class _SeguimientoCard extends StatelessWidget {
  const _SeguimientoCard({required this.client});
  final MockClient client;

  @override
  Widget build(BuildContext context) {
    final task = client.notas.isNotEmpty
        ? client.notas.first.t
        : 'Pendiente de seguimiento';

    return AmPress(
      onTap: () => context.push('/clientes/${client.id}'),
      child: AmCard(
        child: Row(
          children: [
            AmAvatar(client: client, size: 46, radius: 15),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500,
                          color: AmColors.inkLight),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(client.nombre,
                            style: const TextStyle(fontSize: 12.5, color: AmColors.mutedLight),
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AmColors.amberWashLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('${client.diasSinContacto}d sin respuesta',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                color: AmColors.amberLight)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AmColors.muted2Light, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Clientes Recientes ────────────────────────────────────────────────────────

class _ClientesRecientes extends StatelessWidget {
  const _ClientesRecientes();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: mockClients.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final c = mockClients[i];
          return AmPress(
            onTap: () => context.push('/clientes/${c.id}'),
            child: Column(
              children: [
                AmAvatar(client: c, size: 48, radius: 16),
                const SizedBox(height: 5),
                Text(c.nombre.split(' ').first,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500,
                        color: AmColors.inkSoftLight)),
              ],
            ),
          );
        },
      ),
    );
  }
}
