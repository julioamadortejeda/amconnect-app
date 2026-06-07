import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:amconnect/core/theme/app_colors.dart';
import 'package:amconnect/core/mock/mock_data.dart';
import 'package:amconnect/core/widgets/am_card.dart';
import 'package:amconnect/core/widgets/am_badge.dart';
import 'package:amconnect/core/widgets/am_avatar.dart';
import 'package:amconnect/core/widgets/am_back_bar.dart';
import 'package:amconnect/core/widgets/am_segmented.dart';
import 'package:amconnect/core/widgets/am_press.dart';
import 'package:amconnect/core/widgets/am_ramo_icon.dart';
import 'package:amconnect/l10n/app_localizations.dart';

class ClientDetailScreen extends StatefulWidget {
  const ClientDetailScreen({super.key, required this.clientId});
  final String clientId;

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  int _tabIdx = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final client = clientById(widget.clientId) ?? mockClients.first;

    return Scaffold(
      backgroundColor: AmColors.bgLight,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              // Status bar spacer + back bar height
              const SizedBox(height: 90),
              // Profile hero
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [
                    AmAvatar(client: client, size: 76, radius: 24),
                    const SizedBox(height: 8),
                    Text(client.nombre,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600,
                            color: AmColors.inkLight)),
                    const SizedBox(height: 4),
                    Text('${client.ocupacion} · ${client.edad} años · ${client.ciudad}',
                        style: const TextStyle(fontSize: 13.5, color: AmColors.mutedLight)),
                    const SizedBox(height: 6),
                    AmBadge(label: client.desde, tone: AmBadgeTone.green),
                    const SizedBox(height: 18),
                    // Quick actions
                    Row(
                      children: [
                        _QuickAction(icon: Icons.phone_outlined, label: l10n.clientsActionCall, onTap: () {}),
                        const SizedBox(width: 9),
                        _QuickAction(icon: Icons.chat_bubble_outline, label: l10n.clientsActionMessage, onTap: () {}),
                        const SizedBox(width: 9),
                        _QuickAction(
                          icon: Icons.notifications_outlined, label: l10n.clientsActionRemind,
                          onTap: () => context.push('/crear-recordatorio?cliente=${widget.clientId}'),
                        ),
                        const SizedBox(width: 9),
                        _QuickAction(
                          icon: Icons.auto_awesome, label: l10n.clientsActionAsk,
                          onTap: () => context.push('/chat'),
                          accent: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Contact card
                    AmCard(
                      noPad: true,
                      child: Column(
                        children: [
                          _ContactRow(icon: Icons.phone_outlined, text: client.tel, hasBorder: true),
                          _ContactRow(icon: Icons.email_outlined, text: client.email, hasBorder: false),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Tabs
                    AmSegmented(
                      options: [
                        l10n.clientsPoliciesTab(client.polizas.length),
                        l10n.clientsNotesTab(client.notas.length),
                      ],
                      selected: _tabIdx == 0
                          ? l10n.clientsPoliciesTab(client.polizas.length)
                          : l10n.clientsNotesTab(client.notas.length),
                      onSelect: (v) => setState(() => _tabIdx = v == l10n.clientsPoliciesTab(client.polizas.length) ? 0 : 1),
                    ),
                    const SizedBox(height: 14),
                    // Tab content
                    if (_tabIdx == 0)
                      ...client.polizas.map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 11),
                            child: _PolicyCard(p: p),
                          ))
                    else
                      ...client.notas.map((n) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _NoteCard(n: n),
                          )),
                    const SizedBox(height: 14),
                    // Ask CTA
                    AmPress(
                      onTap: () => context.push('/chat'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AmColors.accent,
                          borderRadius: BorderRadius.circular(17),
                          boxShadow: [
                            BoxShadow(color: AmColors.accent.withValues(alpha: 0.3),
                                blurRadius: 18, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.auto_awesome, color: Colors.white, size: 19),
                            const SizedBox(width: 10),
                            Text(l10n.clientsAskAbout(client.nombre.split(' ').first),
                                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
          // Floating back bar
          AmBackBar(trailing: IconButton(
            icon: const Icon(Icons.more_horiz, color: AmColors.inkLight),
            onPressed: () {},
          )),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.text, required this.hasBorder});
  final IconData icon;
  final String text;
  final bool hasBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: hasBorder
          ? const BoxDecoration(border: Border(bottom: BorderSide(color: AmColors.lineSoftLight)))
          : null,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AmColors.accentInk),
          const SizedBox(width: 12),
          Text(text,
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500,
                  color: AmColors.inkLight)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon, required this.label, required this.onTap, this.accent = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AmPress(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              if (accent)
                BoxShadow(color: AmColors.accent.withValues(alpha: 0.3), blurRadius: 12)
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: accent ? AmColors.accent : AmColors.accentWash,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 19, color: accent ? Colors.white : AmColors.accentInk),
              ),
              const SizedBox(height: 7),
              Text(label,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500,
                      color: AmColors.inkSoftLight)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({required this.p});
  final MockPolicy p;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = switch (p.estado) {
      'Vigente'      => AmBadgeTone.green,
      'Por renovar'  => AmBadgeTone.amber,
      'Pago próximo' => AmBadgeTone.amber,
      _              => AmBadgeTone.muted,
    };
    final badgeLabel = p.dias != null ? '${p.estado} · ${p.dias}d' : p.estado;

    return AmCard(
      child: Column(
        children: [
          Row(
            children: [
              AmRamoIcon(ramo: p.ramo, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.ramo,
                        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600,
                            color: AmColors.inkLight)),
                    Text('${p.aseguradora} · ${p.numero}',
                        style: const TextStyle(fontSize: 12.5, color: AmColors.mutedLight)),
                  ],
                ),
              ),
              AmBadge(label: badgeLabel, tone: tone),
            ],
          ),
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AmColors.cardSunkenLight,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _PolicyField(label: l10n.clientsPolicySumInsured, value: p.suma),
                    const SizedBox(width: 14),
                    _PolicyField(label: l10n.clientsPolicyPremium, value: '${p.prima} · ${p.period}'),
                  ],
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    _PolicyField(label: l10n.clientsPolicyNextPayment, value: p.proxPago),
                    const SizedBox(width: 14),
                    _PolicyField(label: l10n.clientsPolicyDeductible, value: p.deducible),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyField extends StatelessWidget {
  const _PolicyField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                  color: AmColors.mutedLight, letterSpacing: 0.04)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500,
                  color: AmColors.inkLight)),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.n});
  final MockNote n;

  @override
  Widget build(BuildContext context) {
    final color = switch (n.tipo) {
      'doc'      => AmColors.srcDoc,
      'whatsapp' => AmColors.srcWhatsApp,
      'wave'     => AmColors.srcWave,
      'image'    => AmColors.srcImage,
      _          => AmColors.srcNote,
    };
    final icon = switch (n.tipo) {
      'doc'      => Icons.description_outlined,
      'whatsapp' => Icons.chat_bubble_outline,
      'wave'     => Icons.graphic_eq,
      'image'    => Icons.image_outlined,
      _          => Icons.note_outlined,
    };
    final bg = Color.alphaBlend(color.withValues(alpha: 0.14), Colors.white);

    return AmCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.t,
                    style: const TextStyle(fontSize: 14, color: AmColors.inkLight, height: 1.5)),
                const SizedBox(height: 6),
                Text(n.src,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600,
                        color: AmColors.mutedLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
