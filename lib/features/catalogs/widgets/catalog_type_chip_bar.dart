import 'package:flutter/material.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../reminders/widgets/reminder_filter_chip.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/catalogs_provider.dart';

class CatalogTypeChipBar extends StatelessWidget {
  const CatalogTypeChipBar({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final CatalogType selected;
  final ValueChanged<CatalogType> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = {
      CatalogType.carriers: l10n.catalogsTypeCarriers,
      CatalogType.branches: l10n.catalogsTypeBranches,
      CatalogType.products: l10n.catalogsTypeProducts,
    };

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AmDimens.screenH),
        children: [
          for (final type in CatalogType.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ReminderFilterChip(
                label: labels[type]!,
                active: selected == type,
                onTap: () => onSelect(type),
              ),
            ),
        ],
      ),
    );
  }
}
