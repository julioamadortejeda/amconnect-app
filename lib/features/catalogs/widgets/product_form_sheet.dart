import 'package:flutter/material.dart';
import '../../../core/widgets/am_spinner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/catalog.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/error_translator.dart';
import '../../../core/widgets/am_confirm_dialog.dart';
import '../../../core/widgets/am_form_row.dart';
import '../../../core/widgets/am_group_card.dart';
import '../../../core/widgets/am_info_row.dart';
import '../../../core/widgets/am_keyboard_dismiss.dart';
import '../../../core/widgets/am_press.dart';
import '../../../core/widgets/am_select_sheet.dart';
import '../../../core/widgets/am_sheet_header.dart';
import '../../../l10n/app_localizations.dart';
import '../../clients/providers/catalog_provider.dart';
import '../providers/catalogs_provider.dart';

class ProductFormSheet extends ConsumerStatefulWidget {
  const ProductFormSheet({super.key, this.product});

  /// Si se provee, el sheet precarga sus datos y guarda actualizando en
  /// vez de crear un producto nuevo.
  final Product? product;

  static Future<void> show(BuildContext context, {Product? product}) {
    final cs = Theme.of(context).colorScheme;
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ProductFormSheet(product: product),
    );
  }

  @override
  ConsumerState<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends ConsumerState<ProductFormSheet> {
  final _nameCtrl = TextEditingController();
  String? _carrierId;
  String? _branchId;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product != null) {
      _nameCtrl.text = product.name;
      _carrierId = product.carrierId;
      _branchId = product.branchId;
    }
    _nameCtrl.addListener(_rebuild);
    Future.microtask(() {
      if (mounted) ref.read(createProductProvider.notifier).reset();
    });
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _nameCtrl.removeListener(_rebuild);
    _nameCtrl.dispose();
    super.dispose();
  }

  void _showSelectSheet<T>({
    required String title,
    required List<T> items,
    required String Function(T) itemLabel,
    required bool Function(T, String) itemFilter,
    required String Function(T) itemId,
    required T? selectedItem,
    required ValueChanged<T?> onSelect,
  }) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AmSelectSheet<T>(
        title: title,
        items: items,
        itemLabel: itemLabel,
        itemFilter: itemFilter,
        itemId: itemId,
        selectedId: selectedItem != null ? itemId(selectedItem) : null,
        onSelect: onSelect,
      ),
    );
  }

  Future<void> _save() async {
    if (_carrierId == null || _branchId == null) return;
    final notifier = ref.read(createProductProvider.notifier);
    final navigator = Navigator.of(context);
    final name = _nameCtrl.text.trim();

    final saved = _isEditing
        ? await notifier.update(widget.product!.id,
            name: name, carrierId: _carrierId!, branchId: _branchId!)
        : await notifier.submit(name: name, carrierId: _carrierId!, branchId: _branchId!);
    if (saved != null) navigator.pop();
  }

  void _confirmDelete() {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AmConfirmDialog(
        title: l10n.catalogsDeleteTitle,
        message: l10n.catalogsDeleteMessage,
        confirmLabel: l10n.commonDelete,
        cancelLabel: l10n.commonCancel,
        icon: Icons.delete_outline,
        iconBgColor: cs.errorContainer,
        iconFgColor: cs.error,
        onConfirm: () async {
          final notifier = ref.read(createProductProvider.notifier);
          final navigator = Navigator.of(context);
          final ok = await notifier.delete(widget.product!.id);
          if (ok) navigator.pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final carriers = ref.watch(carriersProvider).asData?.value ?? const <Carrier>[];
    final branches = ref.watch(branchesProvider).asData?.value ?? const <Branch>[];
    final selectedCarrier = carriers.where((c) => c.id == _carrierId).firstOrNull;
    final selectedBranch = branches.where((b) => b.id == _branchId).firstOrNull;

    final formState = ref.watch(createProductProvider);
    final canSave = _nameCtrl.text.trim().isNotEmpty &&
        _carrierId != null &&
        _branchId != null &&
        !formState.loading;

    return AmKeyboardDismiss(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AmDimens.gapM, AmDimens.gapXS, AmDimens.gapM, AmDimens.gapL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AmSheetHeader(
                  title: _isEditing
                      ? l10n.catalogsEditProductTitle
                      : l10n.catalogsNewProductTitle,
                  trailing: _isEditing
                      ? AmPress(
                          onTap: _confirmDelete,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: cs.errorContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.delete_outline, size: 16, color: cs.error),
                          ),
                        )
                      : null,
                ),
                AmGroupCard(children: [
                  AmInfoRow(
                    icon: Icons.business_outlined,
                    label: l10n.policiesCarrier,
                    trailing: Text(
                      selectedCarrier?.name ?? l10n.catalogsSelectCarrier,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight:
                            selectedCarrier != null ? FontWeight.w500 : FontWeight.w400,
                        color: selectedCarrier != null ? cs.onSurface : cs.tertiary,
                      ),
                    ),
                    chevron: true,
                    onTap: () => _showSelectSheet<Carrier>(
                      title: l10n.policiesCarrier,
                      items: carriers,
                      itemLabel: (c) => c.name,
                      itemFilter: (c, q) => c.name.toLowerCase().contains(q.toLowerCase()),
                      itemId: (c) => c.id,
                      selectedItem: selectedCarrier,
                      onSelect: (c) => setState(() => _carrierId = c?.id),
                    ),
                  ),
                  const AmFormDivider(),
                  AmInfoRow(
                    icon: Icons.category_outlined,
                    label: l10n.policiesBranch,
                    trailing: Text(
                      selectedBranch?.name ?? l10n.catalogsSelectBranch,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight:
                            selectedBranch != null ? FontWeight.w500 : FontWeight.w400,
                        color: selectedBranch != null ? cs.onSurface : cs.tertiary,
                      ),
                    ),
                    chevron: true,
                    onTap: () => _showSelectSheet<Branch>(
                      title: l10n.policiesBranch,
                      items: branches,
                      itemLabel: (b) => b.name,
                      itemFilter: (b, q) => b.name.toLowerCase().contains(q.toLowerCase()),
                      itemId: (b) => b.id,
                      selectedItem: selectedBranch,
                      onSelect: (b) => setState(() => _branchId = b?.id),
                    ),
                  ),
                  const AmFormDivider(),
                  AmFormRow(
                    label: l10n.catalogsFieldName,
                    controller: _nameCtrl,
                    icon: Icons.local_offer_outlined,
                    textCapitalization: TextCapitalization.words,
                  ),
                ]),
                const SizedBox(height: AmDimens.gapM),
                AmPress(
                  onTap: canSave ? _save : null,
                  child: Opacity(
                    opacity: canSave ? 1.0 : 0.5,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AmColors.accent,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: formState.loading
                          ? const Center(
                              child: AmSpinner(
                                  size: 20, strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _isEditing ? l10n.accountSave : l10n.catalogsCreateBtn,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                    ),
                  ),
                ),
                if (formState.error != null) ...[
                  const SizedBox(height: AmDimens.gapS),
                  Text(
                    context.translateError(formState.error),
                    style: TextStyle(fontSize: 13, color: cs.error),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
