import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:amconnect/core/theme/app_colors.dart';
import 'package:amconnect/core/mock/mock_data.dart';
import 'package:amconnect/core/widgets/am_card.dart';
import 'package:amconnect/core/widgets/am_badge.dart';
import 'package:amconnect/core/widgets/am_avatar.dart';
import 'package:amconnect/core/widgets/am_icon_btn.dart';
import 'package:amconnect/core/widgets/am_section_label.dart';
import 'package:amconnect/core/widgets/am_press.dart';

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
    final reminders = ref.watch(remindersProvider);
    final pending = reminders.where((r) => !r.hecho).toList();
    final urgent = pending.where((r) => r.urgente).toList();

    return Scaffold(
      backgroundColor: AmColors.bgLight,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
          children: [
            const SizedBox(height: 8),
            _Header(urgentCount: urgent.length),
            const SizedBox(height: 14),
            if (pending.isNotEmpty) _AlertBanner(pending: pending, urgent: urgent),
            if (pending.isNotEmpty) const SizedBox(height: 14),
            _AskBar(),
            const SizedBox(height: 14),
            AmSectionLabel(
              label: 'Atención inmediata',
              trailing: urgent.isNotEmpty
                  ? AmBadge(
                      label: '${urgent.length} urgente${urgent.length != 1 ? "s" : ""}',
                      tone: AmBadgeTone.red)
                  : null,
            ),
            const SizedBox(height: 11),
            ...pending.take(3).map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: _ActionCard(r: r),
                )),
            const SizedBox(height: 4),
            const AmSectionLabel(label: 'Tu cartera'),
            const SizedBox(height: 9),
            const _PortfolioStats(),
            const SizedBox(height: 14),
            const AmSectionLabel(label: 'Necesitan atención'),
            const SizedBox(height: 11),
            const _ClientsAttention(),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Image.asset('assets/logo/logo_t.png', width: 38, height: 38),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('AMConnect',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500,
                        color: AmColors.mutedLight, letterSpacing: 0.02)),
                Text('Hola, Daniel',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600,
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

// ── Alert Banner ──────────────────────────────────────────────────────────────

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.pending, required this.urgent});
  final List<MockReminder> pending;
  final List<MockReminder> urgent;

  @override
  Widget build(BuildContext context) {
    final hasUrgent = urgent.isNotEmpty;
    final bg = hasUrgent ? AmColors.redWashLight : AmColors.amberWashLight;
    final iconBg = hasUrgent ? AmColors.redLight : AmColors.amberLight;
    return AmPress(
      onTap: () => context.push('/agenda'),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 19),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${pending.length} póliza${pending.length != 1 ? "s" : ""} necesitan tu atención',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AmColors.inkLight),
                  ),
                  if (hasUrgent)
                    Text(
                      '${urgent.length} urgente${urgent.length != 1 ? "s" : ""} · hoy',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: AmColors.redLight),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AmColors.muted2Light, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── AI Ask Bar ────────────────────────────────────────────────────────────────

class _AskBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AmPress(
      onTap: () => context.push('/chat'),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment(2.2, 2.2),
            colors: [Colors.white, AmColors.accentWash],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AmColors.lineLight),
          boxShadow: const [
            BoxShadow(color: Color(0x0D141E1A), blurRadius: 2, offset: Offset(0, 1)),
            BoxShadow(color: Color(0x0A141E1A), blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, color: AmColors.accentInk, size: 18),
            const SizedBox(width: 11),
            const Expanded(
              child: Text('Pregúntale sobre tus clientes',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500,
                      color: AmColors.inkSoftLight)),
            ),
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: AmColors.accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.mic_none_outlined, color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Action Card ───────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.r});
  final MockReminder r;

  @override
  Widget build(BuildContext context) {
    final client = clientById(r.clienteId);
    if (client == null) return const SizedBox.shrink();

    final (icon, label, tone) = switch (r.tipo) {
      'pago'       => (Icons.payments_outlined, 'Pago', AmColors.amberLight),
      'renovacion' => (Icons.autorenew, 'Renovación', AmColors.accentInk),
      _            => (Icons.phone_outlined, 'Llamada', AmColors.greenLight),
    };
    final accentColor = r.urgente ? AmColors.redLight : tone;

    return AmCard(
      noPad: true,
      onTap: () => context.push('/clientes/${client.id}'),
      child: Row(
        children: [
          Container(width: 4, height: 110, color: accentColor),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          color: r.urgente
                              ? AmColors.redWashLight
                              : Color.alphaBlend(accentColor.withValues(alpha: 0.12), Colors.white),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Icon(icon, size: 13, color: accentColor),
                      ),
                      const SizedBox(width: 7),
                      Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: accentColor)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: r.urgente ? AmColors.redWashLight : AmColors.cardSunkenLight,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(r.fecha,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                color: r.urgente ? AmColors.redLight : AmColors.mutedLight)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      AmAvatar(client: client, size: 42, radius: 14),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.titulo.split(' — ').first,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                                    color: AmColors.inkLight),
                                overflow: TextOverflow.ellipsis),
                            Text('${client.nombre} · ${r.sub}',
                                style: const TextStyle(fontSize: 13, color: AmColors.mutedLight)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Row(
                    children: [
                      _MiniAction(icon: Icons.phone_outlined, label: 'Llamar', onTap: () {}),
                      const SizedBox(width: 8),
                      _MiniAction(icon: Icons.chat_bubble_outline, label: 'WhatsApp', onTap: () {}),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AmPress(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AmColors.lineLight, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AmColors.inkSoftLight),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                    color: AmColors.inkSoftLight)),
          ],
        ),
      ),
    );
  }
}

// ── Portfolio Stats ───────────────────────────────────────────────────────────

class _PortfolioStats extends ConsumerWidget {
  const _PortfolioStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(remindersProvider);
    final pending = reminders.where((r) => !r.hecho).toList();
    final renovaciones = pending.where((r) => r.tipo == 'renovacion').length;

    final tiles = [
      (mockStats['polizas']!.toString(), 'Pólizas'),
      (renovaciones.toString(), 'Por renovar'),
      (mockClients.length.toString(), 'Clientes'),
    ];

    return AmCard(
      noPad: true,
      child: IntrinsicHeight(
        child: Row(
          children: tiles.asMap().entries.map((e) {
            final (value, lbl) = e.value;
            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                decoration: BoxDecoration(
                  border: e.key > 0
                      ? const Border(left: BorderSide(color: AmColors.lineSoftLight, width: 1))
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600,
                            color: AmColors.inkLight, letterSpacing: -0.02)),
                    const SizedBox(height: 3),
                    Text(lbl,
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

// ── Clients needing attention ─────────────────────────────────────────────────

class _ClientsAttention extends StatelessWidget {
  const _ClientsAttention();

  @override
  Widget build(BuildContext context) {
    final clients = mockClients
        .where((c) => c.diasSinContacto >= 7)
        .toList()
      ..sort((a, b) => b.diasSinContacto.compareTo(a.diasSinContacto));

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: clients.length,
        separatorBuilder: (_, __) => const SizedBox(width: 11),
        itemBuilder: (_, i) {
          final c = clients[i];
          return AmPress(
            onTap: () => context.push('/clientes/${c.id}'),
            child: SizedBox(
              width: 68,
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AmAvatar(client: c, size: 52, radius: 17),
                      if (c.diasSinContacto >= 14)
                        Positioned(
                          bottom: -2, right: -2,
                          child: Container(
                            width: 18, height: 18,
                            decoration: BoxDecoration(
                              color: AmColors.amberLight, shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            alignment: Alignment.center,
                            child: Text('${c.diasSinContacto}d',
                                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(c.nombre.split(' ').first,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600,
                          color: AmColors.inkSoftLight),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
