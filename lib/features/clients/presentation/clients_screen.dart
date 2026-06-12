import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/models/contact.dart';
import '../../../core/widgets/am_card.dart';
import '../../../core/widgets/am_badge.dart';
import '../../../core/widgets/am_avatar.dart';
import '../providers/clients_provider.dart';
import '../../../l10n/app_localizations.dart';

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
    final contactsAsync = ref.watch(clientsProvider);
    final allContacts = contactsAsync.asData?.value ?? [];
    final list = q.isEmpty
        ? allContacts
        : allContacts
            .where((c) => c.fullName.toLowerCase().contains(q.toLowerCase()))
            .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AmDimens.screenH, 12, AmDimens.screenH, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.clientsTotal(allContacts.length),
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
            const SizedBox(height: AmDimens.gapS),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AmDimens.screenH),
              child: _SearchBar(
                onChanged: (v) => ref.read(clientSearchProvider.notifier).set(v),
              ),
            ),
            const SizedBox(height: AmDimens.gapS),
            Expanded(
              child: contactsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Error al cargar clientes',
                      style: TextStyle(color: cs.tertiary)),
                ),
                data: (_) => list.isEmpty
                    ? Center(
                        child: Text('Sin clientes',
                            style: TextStyle(color: cs.tertiary)),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(AmDimens.screenH, 0, AmDimens.screenH, AmDimens.scrollBottomPad),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _ClientRow(contact: list[i]),
                      ),
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
  const _ClientRow({required this.contact});
  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final subtitle = [
      if (contact.occupation != null && contact.occupation!.isNotEmpty) contact.occupation!,
      if (contact.address != null && contact.address!.isNotEmpty) contact.address!,
    ].join(' · ');

    return AmCard(
      onTap: () => context.push('/clientes/${contact.id}'),
      child: Row(
        children: [
          AmAvatar(inicial: contact.inicial, color: contact.color, size: 48, radius: 15),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.fullName,
                    style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500,
                        color: cs.onSurface)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(fontSize: 12.5, color: cs.tertiary)),
              ],
            ),
          ),
          AmBadge(label: l10n.clientsStatusUpToDate, tone: AmBadgeTone.green),
        ],
      ),
    );
  }
}
