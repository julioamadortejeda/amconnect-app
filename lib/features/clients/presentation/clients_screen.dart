import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_loader.dart';
import '../../../core/widgets/am_press.dart';
import '../../../core/widgets/am_top_bar.dart';
import '../../../core/widgets/am_stagger.dart';
import '../providers/clients_provider.dart';
import '../widgets/client_row.dart';
import '../widgets/client_search_bar.dart';
import '../../../l10n/app_localizations.dart';

class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final q = ref.watch(clientSearchProvider);
    final contactsAsync = ref.watch(clientsProvider);
    final allContacts = contactsAsync.asData?.value ?? [];
    final list = allContacts.where((c) => c.matchesQuery(q)).toList();

    return Scaffold(
      appBar: AmTopBar(
        title: l10n.clientsTitle,
        subtitle: l10n.clientsTotal(allContacts.length),
        actions: [
          AmPress(
            onTap: () {},
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AmColors.accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AmColors.accent.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
          SizedBox(width: AmDimens.screenH),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: AmDimens.gapS),
            AmAnimateIn(
              index: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AmDimens.screenH),
                child: ClientSearchBar(
                  onChanged: (v) => ref.read(clientSearchProvider.notifier).set(v),
                ),
              ),
            ),
            const SizedBox(height: AmDimens.gapS),
            Expanded(
              child: contactsAsync.when(
                loading: () => const AmLoader(),
                error: (_, __) => Center(
                  child: Text(l10n.clientsError,
                      style: TextStyle(color: cs.tertiary)),
                ),
                data: (_) => list.isEmpty
                    ? Center(
                        child: Text(l10n.clientsEmpty,
                            style: TextStyle(color: cs.tertiary)),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                            AmDimens.screenH, 0, AmDimens.screenH, AmDimens.scrollBottomPad),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => AmAnimateIn(
                          index: i + 1,
                          child: ClientRow(contact: list[i]),
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

