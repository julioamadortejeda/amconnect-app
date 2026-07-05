import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_loader.dart';
import '../../../core/widgets/am_press.dart';
import '../../../core/widgets/am_top_bar.dart';
import '../../../core/widgets/am_stagger.dart';
import '../../../core/models/contact.dart';
import '../../../core/models/policy.dart';
import '../providers/clients_provider.dart';
import '../widgets/client_row.dart';
import '../widgets/client_search_bar.dart';
import '../widgets/client_policy_card.dart';
import '../../../l10n/app_localizations.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  int _tabIdx = 0; // 0 = Clientes, 1 = Pólizas

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final contactsAsync = ref.watch(clientsProvider);
    final allContacts = contactsAsync.asData?.value ?? [];

    final policiesAsync = ref.watch(policiesProvider);
    final allPolicies = policiesAsync.asData?.value ?? [];

    final subtitle = _tabIdx == 0
        ? l10n.clientsTotal(allContacts.length)
        : l10n.clientsTotal(allPolicies.length);

    final clientsLabel = l10n.clientsTabClients;
    final policiesLabel = l10n.clientsTabPolicies;

    final title = _tabIdx == 0 ? l10n.clientsTitle : l10n.clientsTabPolicies;

    return Scaffold(
      appBar: AmTopBar(
        title: title,
        subtitle: subtitle,
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
                child: SizedBox(
                  width: double.infinity,
                  child: CupertinoSlidingSegmentedControl<int>(
                    groupValue: _tabIdx,
                    children: {
                      0: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        child: Text(
                          clientsLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _tabIdx == 0 ? cs.onSurface : cs.tertiary,
                          ),
                        ),
                      ),
                      1: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        child: Text(
                          policiesLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _tabIdx == 1 ? cs.onSurface : cs.tertiary,
                          ),
                        ),
                      ),
                    },
                    onValueChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _tabIdx = val;
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: AmDimens.gapS),
            AmAnimateIn(
              index: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AmDimens.screenH),
                child: _tabIdx == 0
                    ? ClientSearchBar(
                        key: const ValueKey('search_clients'),
                        onChanged: (v) => ref.read(clientSearchProvider.notifier).set(v),
                      )
                    : ClientSearchBar(
                        key: const ValueKey('search_policies'),
                        onChanged: (v) => ref.read(policySearchProvider.notifier).set(v),
                        hintText: l10n.clientsSearchPolicyHint,
                      ),
              ),
            ),
            const SizedBox(height: AmDimens.gapS),
            Expanded(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOutCubic,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _tabIdx == 0
                      ? _buildClientsList(contactsAsync, cs, l10n)
                      : _buildPoliciesList(policiesAsync, cs, l10n),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientsList(
    AsyncValue<List<Contact>> contactsAsync,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    final q = ref.watch(clientSearchProvider);
    final allContacts = contactsAsync.asData?.value ?? [];
    final list = allContacts.where((c) => c.matchesQuery(q)).toList();

    return KeyedSubtree(
      key: const ValueKey('clients_view'),
      child: contactsAsync.when(
        loading: () => const AmLoader(),
      error: (_, __) => Center(
        child: Text(
          l10n.clientsError,
          style: TextStyle(color: cs.tertiary),
        ),
      ),
      data: (_) => list.isEmpty
          ? Center(
              child: Text(
                l10n.clientsEmpty,
                style: TextStyle(color: cs.tertiary),
              ),
            )
          : ListView.separated(
              key: const PageStorageKey('clients_list'),
              padding: const EdgeInsets.fromLTRB(
                AmDimens.screenH,
                0,
                AmDimens.screenH,
                AmDimens.scrollBottomPad,
              ),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => AmAnimateIn(
                index: i + 1,
                child: ClientRow(contact: list[i]),
              ),
            ),
      ),
    );
  }

  Widget _buildPoliciesList(
    AsyncValue<List<Policy>> policiesAsync,
    ColorScheme cs,
    AppLocalizations l10n,
  ) {
    final q = ref.watch(policySearchProvider);
    final allPolicies = policiesAsync.asData?.value ?? [];
    final list = allPolicies.where((p) => p.matchesQuery(q)).toList();

    return KeyedSubtree(
      key: const ValueKey('policies_view'),
      child: policiesAsync.when(
        loading: () => const AmLoader(),
      error: (_, __) => Center(
        child: Text(
          l10n.clientsErrorPolicies,
          style: TextStyle(color: cs.tertiary),
        ),
      ),
      data: (_) => list.isEmpty
          ? Center(
              child: Text(
                l10n.clientsEmptyPolicies,
                style: TextStyle(color: cs.tertiary),
              ),
            )
          : ListView.separated(
              key: const PageStorageKey('policies_list'),
              padding: const EdgeInsets.fromLTRB(
                AmDimens.screenH,
                0,
                AmDimens.screenH,
                AmDimens.scrollBottomPad,
              ),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => AmAnimateIn(
                index: i + 1,
                child: ClientPolicyCard(policy: list[i]),
              ),
            ),
      ),
    );
  }
}
