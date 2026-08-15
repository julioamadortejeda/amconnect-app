import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_press.dart';
import '../../../core/widgets/am_top_bar.dart';
import '../../clients/widgets/client_search_bar.dart';
import '../providers/catalogs_provider.dart';
import '../widgets/branch_form_sheet.dart';
import '../widgets/carrier_form_sheet.dart';
import '../widgets/catalog_type_chip_bar.dart';
import '../widgets/catalogs_list_view.dart';
import '../widgets/product_form_sheet.dart';
import '../../../l10n/app_localizations.dart';

class CatalogsScreen extends ConsumerWidget {
  const CatalogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final type = ref.watch(catalogsUiProvider);

    return Scaffold(
      appBar: AmTopBar(
        title: l10n.catalogsTitle,
        showBack: true,
        actions: [
          AmPress(
            onTap: () {
              switch (type) {
                case CatalogType.carriers:
                  CarrierFormSheet.show(context);
                case CatalogType.branches:
                  BranchFormSheet.show(context);
                case CatalogType.products:
                  ProductFormSheet.show(context);
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AmColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: AmDimens.screenH),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: AmDimens.gapS),
            CatalogTypeChipBar(
              selected: type,
              onSelect: (t) => ref.read(catalogsUiProvider.notifier).select(t),
            ),
            const SizedBox(height: AmDimens.gapS),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AmDimens.screenH),
              child: ClientSearchBar(
                key: ValueKey('search_${type.name}'),
                hintText: l10n.catalogsSearchHint,
                onChanged: (v) => ref.read(catalogSearchProvider.notifier).set(v),
              ),
            ),
            const SizedBox(height: AmDimens.gapS),
            const Expanded(child: CatalogsListView()),
          ],
        ),
      ),
    );
  }
}
