import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:amconnect/core/theme/app_colors.dart';
import 'package:amconnect/core/mock/mock_data.dart';
import 'package:amconnect/core/widgets/am_card.dart';
import 'package:amconnect/core/widgets/am_badge.dart';
import 'package:amconnect/core/widgets/am_avatar.dart';
import 'package:amconnect/l10n/app_localizations.dart';

class _SearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String v) => state = v;
}

final clientSearchProvider =
    NotifierProvider<_SearchNotifier, String>(_SearchNotifier.new);

class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final q = ref.watch(clientSearchProvider);
    final list = mockClients
        .where((c) => c.nombre.toLowerCase().contains(q.toLowerCase()))
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.clientsTotal(mockClients.length),
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500,
                                color: cs.tertiary, letterSpacing: 0.02)),
                        Text(l10n.clientsTitle,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600,
                                color: cs.onSurface, letterSpacing: -0.01)),
                      ],
                    ),
                  ),
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AmColors.accent, shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AmColors.accent.withValues(alpha: 0.3),
                          blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _SearchBar(
                onChanged: (v) => ref.read(clientSearchProvider.notifier).set(v),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _ClientRow(client: list[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface, borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.055), blurRadius: 22)],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: cs.onSurfaceVariant, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: TextStyle(fontSize: 15, color: cs.onSurface),
              decoration: InputDecoration(
                border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
                hintText: l10n.clientsSearchHint,
                hintStyle: TextStyle(color: cs.tertiary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientRow extends StatelessWidget {
  const _ClientRow({required this.client});
  final MockClient client;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final (statusLabel, tone) = _clientStatus(client, l10n);
    return AmCard(
      onTap: () => context.push('/clientes/${client.id}'),
      child: Row(
        children: [
          AmAvatar(client: client, size: 48, radius: 15),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(client.nombre,
                    style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500,
                        color: cs.onSurface)),
                const SizedBox(height: 2),
                Text(
                  '${client.ocupacion} · ${client.ciudad} · ${client.polizas.length} póliza${client.polizas.length != 1 ? "s" : ""}',
                  style: TextStyle(fontSize: 12.5, color: cs.tertiary),
                ),
              ],
            ),
          ),
          AmBadge(label: statusLabel, tone: tone),
        ],
      ),
    );
  }

  (String, AmBadgeTone) _clientStatus(MockClient c, AppLocalizations l10n) {
    if (c.desde == 'Prospecto') return (l10n.clientsStatusProspect, AmBadgeTone.accent);
    for (final p in c.polizas) {
      if (p.estado == 'Por renovar') return (l10n.clientsStatusToRenew, AmBadgeTone.amber);
      if (p.estado == 'Pago próximo') return (l10n.clientsStatusPaymentDue, AmBadgeTone.amber);
    }
    return (l10n.clientsStatusUpToDate, AmBadgeTone.green);
  }
}
