import 'package:flutter/material.dart';
import '../../../core/widgets/am_spinner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/catalog.dart';
import '../../../core/models/contact.dart';
import '../../../core/models/policy.dart';
import '../../../core/repositories/supabase_policy_repository.dart';
import '../../../core/utils/api_error_mapper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/error_translator.dart';
import '../../../core/widgets/am_form_row.dart';
import '../../../core/widgets/am_group_card.dart';
import '../../../core/widgets/am_info_row.dart';
import '../../../core/widgets/am_keyboard_dismiss.dart';
import '../../../core/widgets/am_press.dart';
import '../../../core/widgets/am_section_label.dart';
import '../../../core/widgets/am_select_sheet.dart';
import '../../../core/widgets/am_top_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../../clients/providers/clients_provider.dart';
import '../providers/catalog_provider.dart';

class CreatePolicyScreen extends ConsumerStatefulWidget {
  const CreatePolicyScreen({super.key, this.clientId, this.policy});

  final String? clientId;

  /// Si se provee, la pantalla precarga sus datos y guarda actualizando
  /// en vez de crear una póliza nueva.
  final Policy? policy;

  @override
  ConsumerState<CreatePolicyScreen> createState() => _CreatePolicyScreenState();
}

class _CreatePolicyScreenState extends ConsumerState<CreatePolicyScreen> {
  final _policyNumberCtrl = TextEditingController();
  final _sumInsuredCtrl = TextEditingController();
  final _premiumCtrl = TextEditingController();
  final _deductibleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _contactId;
  String? _carrierId;
  String? _branchId;
  String? _productId;
  String? _statusId;
  String? _currencyId;
  String? _paymentFrequencyId;
  String? _paymentMethodId;

  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _renewalDate;
  DateTime? _nextPaymentDate;

  bool _loading = false;
  String? _errorMessage;
  bool _prefilledCatalogIds = false;

  bool get _isEditing => widget.policy != null;

  @override
  void initState() {
    super.initState();
    final policy = widget.policy;
    if (policy != null) {
      _contactId = policy.contactId;
      _statusId = policy.status?.id;
      _currencyId = policy.currency?.id;
      _paymentFrequencyId = policy.paymentFrequency?.id;
      _paymentMethodId = policy.paymentMethod?.id;
      _policyNumberCtrl.text = policy.policyNumber ?? '';
      _sumInsuredCtrl.text = policy.sumInsured?.toString() ?? '';
      _premiumCtrl.text = policy.premium?.toString() ?? '';
      _deductibleCtrl.text = policy.deductible ?? '';
      _notesCtrl.text = policy.notes ?? '';
      _startDate = policy.startDate != null ? DateTime.tryParse(policy.startDate!) : null;
      _endDate = policy.endDate != null ? DateTime.tryParse(policy.endDate!) : null;
      _renewalDate = policy.renewalDate != null ? DateTime.tryParse(policy.renewalDate!) : null;
      _nextPaymentDate = policy.nextPaymentDate != null ? DateTime.tryParse(policy.nextPaymentDate!) : null;
    } else {
      _contactId = widget.clientId;
    }
    // El selector de cliente necesita la cartera completa, no solo la
    // primera página cargada por scroll.
    Future.microtask(() => ref.read(clientsProvider.notifier).loadAll());
  }

  @override
  void dispose() {
    _policyNumberCtrl.dispose();
    _sumInsuredCtrl.dispose();
    _premiumCtrl.dispose();
    _deductibleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _selectDate(BuildContext context, String field) async {
    DateTime initial = DateTime.now();
    if (field == 'start' && _startDate != null) initial = _startDate!;
    if (field == 'end' && _endDate != null) initial = _endDate!;
    if (field == 'renewal' && _renewalDate != null) initial = _renewalDate!;
    if (field == 'nextPayment' && _nextPaymentDate != null) {
      initial = _nextPaymentDate!;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 5),
      lastDate: DateTime(initial.year + 15),
    );

    if (picked != null) {
      setState(() {
        if (field == 'start') _startDate = picked;
        if (field == 'end') _endDate = picked;
        if (field == 'renewal') _renewalDate = picked;
        if (field == 'nextPayment') _nextPaymentDate = picked;
      });
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  void _showSelectSheet<T>({
    required String title,
    required List<T> items,
    required String Function(T) itemLabel,
    required bool Function(T, String) itemFilter,
    required String Function(T) itemId,
    required T? selectedItem,
    required ValueChanged<T?> onSelect,
    String? createNewLabel,
    Future<T?> Function(String)? onCreateNew,
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
        createNewLabel: createNewLabel,
        onCreateNew: onCreateNew,
      ),
    );
  }

  Future<void> _save() async {
    if (_contactId == null ||
        _carrierId == null ||
        _branchId == null ||
        _productId == null ||
        _statusId == null ||
        _currencyId == null) {
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final payload = {
      'contactId': _contactId,
      'carrierId': _carrierId,
      'branchId': _branchId,
      'productId': _productId,
      'statusId': _statusId,
      'currencyId': _currencyId,
      if (_paymentFrequencyId != null)
        'paymentFrequencyId': _paymentFrequencyId,
      if (_paymentMethodId != null) 'paymentMethodId': _paymentMethodId,
      if (_policyNumberCtrl.text.isNotEmpty)
        'policyNumber': _policyNumberCtrl.text.trim(),
      if (_sumInsuredCtrl.text.isNotEmpty)
        'sumInsured': double.tryParse(_sumInsuredCtrl.text),
      if (_premiumCtrl.text.isNotEmpty)
        'premium': double.tryParse(_premiumCtrl.text),
      if (_startDate != null) 'startDate': _formatDate(_startDate),
      if (_endDate != null) 'endDate': _formatDate(_endDate),
      if (_renewalDate != null) 'renewalDate': _formatDate(_renewalDate),
      if (_nextPaymentDate != null)
        'nextPaymentDate': _formatDate(_nextPaymentDate),
      if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text.trim(),
      if (_deductibleCtrl.text.isNotEmpty)
        'deductible': _deductibleCtrl.text.trim(),
    };

    try {
      final repo = ref.read(policyRepositoryProvider);
      final savedPolicy = _isEditing
          ? await repo.update(widget.policy!.id, payload)
          : await repo.create(payload);

      // Invalida la lista de pólizas del contacto para forzar refetch
      ref.invalidate(contactPoliciesProvider(_contactId!));

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? l10n.policiesUpdatedSuccess : l10n.policiesCreatedSuccess),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        Navigator.pop(context, savedPolicy);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = context.translateError(mapApiError(e));
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final clients = ref.watch(clientsProvider).asData?.value ?? [];
    final carriers = ref.watch(carriersProvider).asData?.value ?? [];
    final branches = ref.watch(branchesProvider).asData?.value ?? [];
    final products = ref.watch(productsProvider).asData?.value ?? [];

    final statuses = ref.watch(statusesProvider).asData?.value ?? [];
    final currencies = ref.watch(currenciesProvider).asData?.value ?? [];
    final frequencies = ref.watch(frequenciesProvider).asData?.value ?? [];
    final methods = ref.watch(methodsProvider).asData?.value ?? [];

    // El modelo Policy no trae carrierId/branchId planos — se resuelven una
    // sola vez buscando el Product del catálogo que coincide con el producto
    // de la póliza, en cuanto el catálogo termina de cargar.
    if (_isEditing && !_prefilledCatalogIds && products.isNotEmpty) {
      final matched = products
          .where((p) => p.id == widget.policy!.product?.id)
          .firstOrNull;
      if (matched != null) {
        _carrierId = matched.carrierId;
        _branchId = matched.branchId;
        _productId = matched.id;
      }
      _prefilledCatalogIds = true;
    }

    final selectedClient = clients.cast<Contact?>().firstWhere(
          (c) => c?.id == _contactId,
          orElse: () => null,
        );

    final selectedCarrier = carriers.cast<Carrier?>().firstWhere(
          (c) => c?.id == _carrierId,
          orElse: () => null,
        );

    final selectedBranch = branches.cast<Branch?>().firstWhere(
          (b) => b?.id == _branchId,
          orElse: () => null,
        );

    // Los productos se filtran por la aseguradora y el ramo seleccionados
    final filteredProducts = products
        .where((p) => p.carrierId == _carrierId && p.branchId == _branchId)
        .toList();

    final selectedProduct = filteredProducts.cast<Product?>().firstWhere(
          (p) => p?.id == _productId,
          orElse: () => null,
        );

    final selectedStatus = statuses.cast<PolicyStatus?>().firstWhere(
          (s) => s?.id == _statusId,
          orElse: () => null,
        );

    final selectedCurrency = currencies.cast<Currency?>().firstWhere(
          (c) => c?.id == _currencyId,
          orElse: () => null,
        );

    final selectedFrequency = frequencies.cast<PaymentFrequency?>().firstWhere(
          (f) => f?.id == _paymentFrequencyId,
          orElse: () => null,
        );

    final selectedMethod = methods.cast<PaymentMethod?>().firstWhere(
          (m) => m?.id == _paymentMethodId,
          orElse: () => null,
        );

    final isCatalogSelectionActive = _carrierId != null && _branchId != null;

    final canSave = _contactId != null &&
        _carrierId != null &&
        _branchId != null &&
        _productId != null &&
        _statusId != null &&
        _currencyId != null &&
        !_loading;

    return Scaffold(
      appBar: AmTopBar(
        title: _isEditing ? l10n.policiesEditPolicyTitle : l10n.policiesNewPolicyTitle,
        showBack: true,
      ),
      body: SafeArea(
        top: false,
        child: AmKeyboardDismiss(
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(
                  AmDimens.screenH,
                  AmDimens.gapM,
                  AmDimens.screenH,
                  80,
                ),
                children: [
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _errorMessage!,
                        style:
                            TextStyle(color: cs.onErrorContainer, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: AmDimens.gapM),
                  ],

                  // ── Cliente ──────────────────────────────────────────────────
                  AmSectionLabel(label: l10n.policiesSelectClient),
                  const SizedBox(height: AmDimens.gapXS),
                  AmGroupCard(children: [
                    AmInfoRow(
                      icon: Icons.person_outline,
                      label: l10n.policiesSelectClient,
                      trailing: Text(
                        selectedClient?.fullName ?? l10n.policiesSelectClient,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: selectedClient != null
                              ? FontWeight.w500
                              : FontWeight.w400,
                          color: selectedClient != null
                              ? cs.onSurface
                              : cs.tertiary,
                        ),
                      ),
                      chevron: widget.clientId == null && !_isEditing,
                      onTap: widget.clientId == null && !_isEditing
                          ? () {
                              _showSelectSheet<Contact>(
                                title: l10n.policiesSelectClient,
                                items: clients,
                                itemLabel: (c) => c.fullName,
                                itemFilter: (c, q) => c.matchesQuery(q),
                                itemId: (c) => c.id,
                                selectedItem: selectedClient,
                                onSelect: (c) =>
                                    setState(() => _contactId = c?.id),
                              );
                            }
                          : null,
                    ),
                  ]),
                  const SizedBox(height: AmDimens.gapM),

                  // ── Catálogos Editables (Número de póliza, Aseguradora, Ramo, Producto) ─
                  AmSectionLabel(label: l10n.policiesSectionInsuranceDetails),
                  const SizedBox(height: AmDimens.gapXS),
                  AmGroupCard(children: [
                    AmFormRow(
                      label: l10n.policiesPolicyNumber,
                      controller: _policyNumberCtrl,
                      icon: Icons.description_outlined,
                    ),
                    const AmFormDivider(),
                    AmInfoRow(
                      icon: Icons.business_outlined,
                      label: l10n.policiesCarrier,
                      trailing: Text(
                        selectedCarrier?.name ?? 'Seleccionar...',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: selectedCarrier != null
                              ? FontWeight.w500
                              : FontWeight.w400,
                          color: selectedCarrier != null
                              ? cs.onSurface
                              : cs.tertiary,
                        ),
                      ),
                      chevron: true,
                      onTap: () {
                        _showSelectSheet<Carrier>(
                          title: l10n.policiesCarrier,
                          items: carriers,
                          itemLabel: (c) => c.name,
                          itemFilter: (c, q) =>
                              c.name.toLowerCase().contains(q.toLowerCase()),
                          itemId: (c) => c.id,
                          selectedItem: selectedCarrier,
                          onSelect: (c) => setState(() {
                            _carrierId = c?.id;
                            _productId =
                                null; // Reiniciamos producto al cambiar aseguradora
                          }),
                          createNewLabel: l10n.policiesCreateCarrier,
                          onCreateNew: (name) => ref
                              .read(carriersProvider.notifier)
                              .createCarrier(name),
                        );
                      },
                    ),
                    const AmFormDivider(),
                    AmInfoRow(
                      icon: Icons.category_outlined,
                      label: l10n.policiesBranch,
                      trailing: Text(
                        selectedBranch?.name ?? 'Seleccionar...',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: selectedBranch != null
                              ? FontWeight.w500
                              : FontWeight.w400,
                          color: selectedBranch != null
                              ? cs.onSurface
                              : cs.tertiary,
                        ),
                      ),
                      chevron: true,
                      onTap: () {
                        _showSelectSheet<Branch>(
                          title: l10n.policiesBranch,
                          items: branches,
                          itemLabel: (b) => b.name,
                          itemFilter: (b, q) =>
                              b.name.toLowerCase().contains(q.toLowerCase()),
                          itemId: (b) => b.id,
                          selectedItem: selectedBranch,
                          onSelect: (b) => setState(() {
                            _branchId = b?.id;
                            _productId =
                                null; // Reiniciamos producto al cambiar ramo
                          }),
                          createNewLabel: l10n.policiesCreateBranch,
                          onCreateNew: (name) => ref
                              .read(branchesProvider.notifier)
                              .createBranch(name),
                        );
                      },
                    ),
                    const AmFormDivider(),
                    AmInfoRow(
                      icon: Icons.local_offer_outlined,
                      label: l10n.policiesProduct,
                      trailing: Text(
                        selectedProduct?.name ?? 'Seleccionar...',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: selectedProduct != null
                              ? FontWeight.w500
                              : FontWeight.w400,
                          color: isCatalogSelectionActive
                              ? (selectedProduct != null
                                  ? cs.onSurface
                                  : cs.tertiary)
                              : cs.tertiary.withValues(alpha: 0.5),
                        ),
                      ),
                      chevron: isCatalogSelectionActive,
                      onTap: isCatalogSelectionActive
                          ? () {
                              _showSelectSheet<Product>(
                                title: l10n.policiesProduct,
                                items: filteredProducts,
                                itemLabel: (p) => p.name,
                                itemFilter: (p, q) => p.name
                                    .toLowerCase()
                                    .contains(q.toLowerCase()),
                                itemId: (p) => p.id,
                                selectedItem: selectedProduct,
                                onSelect: (p) =>
                                    setState(() => _productId = p?.id),
                                createNewLabel: l10n.policiesCreateProduct,
                                onCreateNew: (name) => ref
                                    .read(productsProvider.notifier)
                                    .createProduct(
                                        name, _carrierId!, _branchId!),
                              );
                            }
                          : null,
                    ),
                  ]),
                  const SizedBox(height: AmDimens.gapM),

                  // ── Catálogos Globales (Estado, Moneda, Frecuencia, Método) ───
                  AmSectionLabel(label: l10n.policiesSectionParamsPayment),
                  const SizedBox(height: AmDimens.gapXS),
                  AmGroupCard(children: [
                    AmInfoRow(
                      icon: Icons.info_outline,
                      label: l10n.policiesStatus,
                      trailing: Text(
                        selectedStatus?.name ?? 'Seleccionar...',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: selectedStatus != null
                              ? FontWeight.w500
                              : FontWeight.w400,
                          color: selectedStatus != null
                              ? cs.onSurface
                              : cs.tertiary,
                        ),
                      ),
                      chevron: true,
                      onTap: () {
                        _showSelectSheet<PolicyStatus>(
                          title: l10n.policiesStatus,
                          items: statuses,
                          itemLabel: (s) => s.name,
                          itemFilter: (s, q) =>
                              s.name.toLowerCase().contains(q.toLowerCase()),
                          itemId: (s) => s.id,
                          selectedItem: selectedStatus,
                          onSelect: (s) => setState(() => _statusId = s?.id),
                        );
                      },
                    ),
                    const AmFormDivider(),
                    AmInfoRow(
                      icon: Icons.monetization_on_outlined,
                      label: l10n.policiesCurrency,
                      trailing: Text(
                        selectedCurrency != null
                            ? '${selectedCurrency.code} - ${selectedCurrency.name}'
                            : 'Seleccionar...',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: selectedCurrency != null
                              ? FontWeight.w500
                              : FontWeight.w400,
                          color: selectedCurrency != null
                              ? cs.onSurface
                              : cs.tertiary,
                        ),
                      ),
                      chevron: true,
                      onTap: () {
                        _showSelectSheet<Currency>(
                          title: l10n.policiesCurrency,
                          items: currencies,
                          itemLabel: (c) => '${c.code} - ${c.name}',
                          itemFilter: (c, q) =>
                              c.name.toLowerCase().contains(q.toLowerCase()) ||
                              c.code.toLowerCase().contains(q.toLowerCase()),
                          itemId: (c) => c.id,
                          selectedItem: selectedCurrency,
                          onSelect: (c) => setState(() => _currencyId = c?.id),
                        );
                      },
                    ),
                    const AmFormDivider(),
                    AmInfoRow(
                      icon: Icons.update_outlined,
                      label: l10n.policiesPaymentFrequency,
                      trailing: Text(
                        selectedFrequency?.name ?? 'Seleccionar...',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: selectedFrequency != null
                              ? FontWeight.w500
                              : FontWeight.w400,
                          color: selectedFrequency != null
                              ? cs.onSurface
                              : cs.tertiary,
                        ),
                      ),
                      chevron: true,
                      onTap: () {
                        _showSelectSheet<PaymentFrequency>(
                          title: l10n.policiesPaymentFrequency,
                          items: frequencies,
                          itemLabel: (f) => f.name,
                          itemFilter: (f, q) =>
                              f.name.toLowerCase().contains(q.toLowerCase()),
                          itemId: (f) => f.id,
                          selectedItem: selectedFrequency,
                          onSelect: (f) =>
                              setState(() => _paymentFrequencyId = f?.id),
                        );
                      },
                    ),
                    const AmFormDivider(),
                    AmInfoRow(
                      icon: Icons.payment_outlined,
                      label: l10n.policiesPaymentMethod,
                      trailing: Text(
                        selectedMethod?.name ?? 'Seleccionar...',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: selectedMethod != null
                              ? FontWeight.w500
                              : FontWeight.w400,
                          color: selectedMethod != null
                              ? cs.onSurface
                              : cs.tertiary,
                        ),
                      ),
                      chevron: true,
                      onTap: () {
                        _showSelectSheet<PaymentMethod>(
                          title: l10n.policiesPaymentMethod,
                          items: methods,
                          itemLabel: (m) => m.name,
                          itemFilter: (m, q) =>
                              m.name.toLowerCase().contains(q.toLowerCase()),
                          itemId: (m) => m.id,
                          selectedItem: selectedMethod,
                          onSelect: (m) =>
                              setState(() => _paymentMethodId = m?.id),
                        );
                      },
                    ),
                  ]),
                  const SizedBox(height: AmDimens.gapM),

                  // ── Datos Financieros ────────────────────────────────────────
                  AmSectionLabel(label: l10n.policiesSectionAmountsCoverage),
                  const SizedBox(height: AmDimens.gapXS),
                  AmGroupCard(children: [
                    Row(
                      children: [
                        Expanded(
                          child: AmFormRow(
                            label: l10n.policiesSumInsured,
                            controller: _sumInsuredCtrl,
                            icon: Icons.shield_outlined,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            textCapitalization: TextCapitalization.none,
                          ),
                        ),
                        Expanded(
                          child: AmFormRow(
                            label: l10n.policiesPremium,
                            controller: _premiumCtrl,
                            icon: Icons.wallet_outlined,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            textCapitalization: TextCapitalization.none,
                          ),
                        ),
                      ],
                    ),
                    const AmFormDivider(),
                    AmFormRow(
                      label: l10n.policiesDeductible,
                      controller: _deductibleCtrl,
                      icon: Icons.price_change_outlined,
                      textCapitalization: TextCapitalization.none,
                    ),
                  ]),
                  const SizedBox(height: AmDimens.gapM),

                  // ── Fechas ───────────────────────────────────────────────────
                  AmSectionLabel(label: l10n.policiesSectionDatesValidity),
                  const SizedBox(height: AmDimens.gapXS),
                  AmGroupCard(children: [
                    AmInfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: l10n.policiesStartDate,
                      trailing: Text(
                        _formatDate(_startDate),
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: _startDate != null
                              ? FontWeight.w500
                              : FontWeight.w400,
                          color:
                              _startDate != null ? cs.onSurface : cs.tertiary,
                        ),
                      ),
                      chevron: true,
                      onTap: () => _selectDate(context, 'start'),
                    ),
                    const AmFormDivider(),
                    AmInfoRow(
                      icon: Icons.event_busy_outlined,
                      label: l10n.policiesEndDate,
                      trailing: Text(
                        _formatDate(_endDate),
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: _endDate != null
                              ? FontWeight.w500
                              : FontWeight.w400,
                          color: _endDate != null ? cs.onSurface : cs.tertiary,
                        ),
                      ),
                      chevron: true,
                      onTap: () => _selectDate(context, 'end'),
                    ),
                    const AmFormDivider(),
                    AmInfoRow(
                      icon: Icons.autorenew_outlined,
                      label: l10n.policiesRenewalDate,
                      trailing: Text(
                        _formatDate(_renewalDate),
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: _renewalDate != null
                              ? FontWeight.w500
                              : FontWeight.w400,
                          color:
                              _renewalDate != null ? cs.onSurface : cs.tertiary,
                        ),
                      ),
                      chevron: true,
                      onTap: () => _selectDate(context, 'renewal'),
                    ),
                    const AmFormDivider(),
                    AmInfoRow(
                      icon: Icons.next_plan_outlined,
                      label: l10n.policiesNextPaymentDate,
                      trailing: Text(
                        _formatDate(_nextPaymentDate),
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: _nextPaymentDate != null
                              ? FontWeight.w500
                              : FontWeight.w400,
                          color: _nextPaymentDate != null
                              ? cs.onSurface
                              : cs.tertiary,
                        ),
                      ),
                      chevron: true,
                      onTap: () => _selectDate(context, 'nextPayment'),
                    ),
                  ]),
                  const SizedBox(height: AmDimens.gapM),

                  // ── Notas ────────────────────────────────────────────────────
                  AmSectionLabel(label: l10n.policiesNotes),
                  const SizedBox(height: AmDimens.gapXS),
                  AmGroupCard(children: [
                    AmFormRow(
                      label: l10n.policiesNotes,
                      controller: _notesCtrl,
                      icon: Icons.notes_outlined,
                      minLines: 2,
                      maxLines: 4,
                    ),
                  ]),
                  const SizedBox(height: AmDimens.gapL),
                ],
              ),

              // ── Botón de Guardar ───────────────────────────────────────────
              Positioned(
                left: AmDimens.screenH,
                right: AmDimens.screenH,
                bottom: 16,
                child: AmPress(
                  onTap: canSave ? _save : null,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: canSave ? cs.primary : cs.outlineVariant,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: canSave ? AmShadows.card : null,
                    ),
                    child: Center(
                      child: _loading
                          ? const AmSpinner(
                              size: 20,
                              strokeWidth: 2,
                              color: Colors.white,
                            )
                          : Text(
                              _isEditing ? l10n.policiesSaveChangesBtn : l10n.policiesSaveBtn,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: canSave ? cs.onPrimary : cs.tertiary,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
