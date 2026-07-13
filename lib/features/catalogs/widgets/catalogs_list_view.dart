import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/catalog.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_loader.dart';
import '../../clients/providers/catalog_provider.dart';
import '../providers/catalogs_provider.dart';
import '../../../l10n/app_localizations.dart';
import 'branch_form_sheet.dart';
import 'carrier_form_sheet.dart';
import 'catalog_row.dart';
import 'product_form_sheet.dart';

class CatalogsListView extends ConsumerWidget {
  const CatalogsListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final type = ref.watch(catalogsUiProvider);
    final query = ref.watch(catalogSearchProvider).trim().toLowerCase();

    switch (type) {
      case CatalogType.carriers:
        final async = ref.watch(carriersProvider);
        return async.when(
          loading: () => const AmLoader(),
          error: (_, __) => _ErrorText(text: l10n.catalogsError),
          data: (items) {
            final list = items
                .where((c) => c.name.toLowerCase().contains(query))
                .toList();
            return _CatalogList(
              isEmpty: list.isEmpty,
              itemCount: list.length,
              itemBuilder: (i) => CatalogRow(
                icon: Icons.business_outlined,
                title: list[i].name,
                subtitle: list[i].shortName,
                onTap: () => CarrierFormSheet.show(context, carrier: list[i]),
              ),
            );
          },
        );
      case CatalogType.branches:
        final async = ref.watch(branchesProvider);
        return async.when(
          loading: () => const AmLoader(),
          error: (_, __) => _ErrorText(text: l10n.catalogsError),
          data: (items) {
            final list = items
                .where((b) => b.name.toLowerCase().contains(query))
                .toList();
            return _CatalogList(
              isEmpty: list.isEmpty,
              itemCount: list.length,
              itemBuilder: (i) => CatalogRow(
                icon: Icons.category_outlined,
                title: list[i].name,
                subtitle: list[i].code,
                onTap: () => BranchFormSheet.show(context, branch: list[i]),
              ),
            );
          },
        );
      case CatalogType.products:
        final async = ref.watch(productsProvider);
        final carriers = ref.watch(carriersProvider).asData?.value ?? const <Carrier>[];
        final branches = ref.watch(branchesProvider).asData?.value ?? const <Branch>[];
        return async.when(
          loading: () => const AmLoader(),
          error: (_, __) => _ErrorText(text: l10n.catalogsError),
          data: (items) {
            final list = items
                .where((p) => p.name.toLowerCase().contains(query))
                .toList();
            return _CatalogList(
              isEmpty: list.isEmpty,
              itemCount: list.length,
              itemBuilder: (i) {
                final product = list[i];
                final carrierName = carriers
                    .where((c) => c.id == product.carrierId)
                    .firstOrNull
                    ?.name;
                final branchName = branches
                    .where((b) => b.id == product.branchId)
                    .firstOrNull
                    ?.name;
                final subtitle = [
                  if (carrierName != null) carrierName,
                  if (branchName != null) branchName,
                ].join(' · ');
                return CatalogRow(
                  icon: Icons.local_offer_outlined,
                  title: product.name,
                  subtitle: subtitle,
                  onTap: () => ProductFormSheet.show(context, product: product),
                );
              },
            );
          },
        );
    }
  }
}

class _CatalogList extends StatelessWidget {
  const _CatalogList({
    required this.isEmpty,
    required this.itemCount,
    required this.itemBuilder,
  });

  final bool isEmpty;
  final int itemCount;
  final Widget Function(int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    if (isEmpty) {
      return Center(
        child: Text(l10n.catalogsEmpty, style: TextStyle(color: cs.tertiary)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AmDimens.screenH,
        0,
        AmDimens.screenH,
        AmDimens.scrollBottomPad,
      ),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => itemBuilder(i),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(child: Text(text, style: TextStyle(color: cs.tertiary)));
  }
}
