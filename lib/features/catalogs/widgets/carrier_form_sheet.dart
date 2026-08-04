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
import '../../../core/widgets/am_keyboard_dismiss.dart';
import '../../../core/widgets/am_press.dart';
import '../../../core/widgets/am_sheet_header.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/catalogs_provider.dart';

class CarrierFormSheet extends ConsumerStatefulWidget {
  const CarrierFormSheet({super.key, this.carrier});

  /// Si se provee, el sheet precarga sus datos y guarda actualizando en
  /// vez de crear una aseguradora nueva.
  final Carrier? carrier;

  static Future<void> show(BuildContext context, {Carrier? carrier}) {
    final cs = Theme.of(context).colorScheme;
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => CarrierFormSheet(carrier: carrier),
    );
  }

  @override
  ConsumerState<CarrierFormSheet> createState() => _CarrierFormSheetState();
}

class _CarrierFormSheetState extends ConsumerState<CarrierFormSheet> {
  final _nameCtrl = TextEditingController();
  final _shortNameCtrl = TextEditingController();

  bool get _isEditing => widget.carrier != null;

  @override
  void initState() {
    super.initState();
    final carrier = widget.carrier;
    if (carrier != null) {
      _nameCtrl.text = carrier.name;
      _shortNameCtrl.text = carrier.shortName ?? '';
    }
    _nameCtrl.addListener(_rebuild);
    Future.microtask(() {
      if (mounted) ref.read(createCarrierProvider.notifier).reset();
    });
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _nameCtrl.removeListener(_rebuild);
    _nameCtrl.dispose();
    _shortNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final notifier = ref.read(createCarrierProvider.notifier);
    final navigator = Navigator.of(context);
    final name = _nameCtrl.text.trim();
    final shortName =
        _shortNameCtrl.text.trim().isEmpty ? null : _shortNameCtrl.text.trim();

    final saved = _isEditing
        ? await notifier.update(widget.carrier!.id, name: name, shortName: shortName)
        : await notifier.submit(name: name, shortName: shortName);
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
          final notifier = ref.read(createCarrierProvider.notifier);
          final navigator = Navigator.of(context);
          final ok = await notifier.delete(widget.carrier!.id);
          if (ok) navigator.pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final formState = ref.watch(createCarrierProvider);
    final canSave = _nameCtrl.text.trim().isNotEmpty && !formState.loading;

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
                      ? l10n.catalogsEditCarrierTitle
                      : l10n.catalogsNewCarrierTitle,
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
                  AmFormRow(
                    label: l10n.catalogsFieldName,
                    controller: _nameCtrl,
                    icon: Icons.business_outlined,
                  ),
                  const AmFormDivider(),
                  AmFormRow(
                    label: l10n.catalogsFieldShortName,
                    controller: _shortNameCtrl,
                    icon: Icons.short_text,
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
