import 'package:flutter/material.dart';
import '../../../core/widgets/am_spinner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/contact.dart';
import '../../../core/models/policy.dart';
import '../../../core/models/reminder_type.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/am_theme.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/error_translator.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/reminder_utils.dart';
import '../../../core/utils/catalog_l10n.dart';
import '../../../core/widgets/am_avatar.dart';
import '../../../core/widgets/am_form_row.dart';
import '../../../core/widgets/am_group_card.dart';
import '../../../core/widgets/am_info_row.dart';
import '../../../core/widgets/am_keyboard_dismiss.dart';
import '../../../core/widgets/am_press.dart';
import '../../../core/widgets/am_reschedule_dialog.dart';
import '../../../core/widgets/am_section_label.dart';
import '../../../core/widgets/am_top_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../../clients/providers/clients_provider.dart';
import '../providers/reminders_provider.dart';
import '../widgets/reminder_client_sheet.dart';
import '../widgets/reminder_policy_sheet.dart';
import '../widgets/reminder_status_chip.dart';
import '../widgets/reminder_status_selection_sheet.dart';
import '../widgets/reminder_type_chip.dart';
import '../widgets/reminder_type_selection_sheet.dart';

class CreateReminderScreen extends ConsumerStatefulWidget {
  const CreateReminderScreen({super.key, this.clienteId});
  final String? clienteId;

  @override
  ConsumerState<CreateReminderScreen> createState() =>
      _CreateReminderScreenState();
}

class _CreateReminderScreenState extends ConsumerState<CreateReminderScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _typeId;
  String _statusCode = 'CREATED';
  String? _clienteId;
  String? _policyId;
  late DateTime _dueDate;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _clienteId = widget.clienteId;
    final now = DateTime.now();
    _dueDate = DateTime(now.year, now.month, now.day + 1, 9, 0);
    _titleCtrl.addListener(_rebuild);
    // Estado del provider de creación es compartido entre visitas a esta
    // pantalla — limpiar cualquier error de un intento anterior. Diferido
    // porque Riverpod prohíbe modificar un provider durante el build.
    Future.microtask(() {
      if (mounted) ref.read(createReminderProvider.notifier).reset();
    });
    // Necesita la cartera completa para poder mostrar/buscar el cliente
    // seleccionado, no solo la primera página cargada por scroll.
    Future.microtask(() => ref.read(clientsProvider.notifier).loadAll());
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _titleCtrl.removeListener(_rebuild);
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Contact? _findContact(List<Contact> clients) {
    if (_clienteId == null) return null;
    for (final c in clients) {
      if (c.id == _clienteId) return c;
    }
    return null;
  }

  ReminderType? _findType(List<ReminderType> types, String? id) {
    if (id == null) return null;
    for (final t in types) {
      if (t.id == id) return t;
    }
    return null;
  }

  Policy? _findPolicy(List<Policy> policies) {
    if (_policyId == null) return null;
    for (final p in policies) {
      if (p.id == _policyId) return p;
    }
    return null;
  }

  void _openTypeSheet(List<ReminderType> types, String? selectedId) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ReminderTypeSelectionSheet(
        types: types,
        selectedTypeId: selectedId,
        onSelect: (t) => setState(() => _typeId = t.id),
      ),
    );
  }

  void _openStatusSheet() {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ReminderStatusSelectionSheet(
        selectedCode: _statusCode,
        onSelect: (code) => setState(() => _statusCode = code),
      ),
    );
  }

  void _openClientSheet() {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ReminderClientSheet(
        selectedClientId: _clienteId,
        onSelect: (c) => setState(() {
          if (c?.id != _clienteId) _policyId = null;
          _clienteId = c?.id;
        }),
      ),
    );
  }

  void _openPolicySheet(String contactId) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ReminderPolicySheet(
        contactId: contactId,
        selectedPolicyId: _policyId,
        onSelect: (p) => setState(() => _policyId = p?.id),
      ),
    );
  }

  void _openDatePicker() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AmRescheduleDialog(
        initialDateTime: _dueDate,
        title: l10n.remindersPickDateTitle,
        message: l10n.remindersPickDateMessage,
        onConfirm: (dt) => setState(() => _dueDate = dt),
      ),
    );
  }

  Future<void> _save(String typeId) async {
    final notifier = ref.read(createReminderProvider.notifier);
    final created = await notifier.submit(
      typeId: typeId,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      dueDate: _dueDate,
      contactId: _clienteId,
      policyId: _clienteId != null ? _policyId : null,
      status: _statusCode,
    );
    if (!mounted || created == null) return;
    setState(() => _showSuccess = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    final l10n = AppLocalizations.of(context)!;

    final types = ref.watch(reminderTypesProvider).asData?.value ?? [];
    final clients = ref.watch(clientsProvider).asData?.value ?? [];
    final createState = ref.watch(createReminderProvider);

    final effectiveTypeId =
        _typeId ?? (types.isNotEmpty ? types.first.id : null);
    final selectedType = _findType(types, effectiveTypeId);
    final selectedContact = _findContact(clients);
    final policies = _clienteId != null
        ? ref.watch(contactPoliciesProvider(_clienteId!)).asData?.value ?? []
        : const <Policy>[];
    final selectedPolicy = _findPolicy(policies);

    final canSave = _titleCtrl.text.trim().isNotEmpty &&
        effectiveTypeId != null &&
        !createState.loading;

    return Scaffold(
      appBar: AmTopBar(title: l10n.remindersNewTitle, showBack: true),
      body: SafeArea(
        top: false,
        child: AmKeyboardDismiss(
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(
                    AmDimens.screenH, AmDimens.gapM, AmDimens.screenH, 40),
                children: [
                  AmSectionLabel(label: l10n.remindersSectionInfo),
                  const SizedBox(height: AmDimens.gapXS),
                  AmGroupCard(children: [
                    AmFormRow(
                      label: l10n.remindersFieldTitle,
                      controller: _titleCtrl,
                      icon: Icons.edit_outlined,
                    ),
                    const AmFormDivider(),
                    AmFormRow(
                      label: l10n.remindersFieldDescription,
                      controller: _descCtrl,
                      icon: Icons.notes_outlined,
                      minLines: 2,
                      maxLines: 4,
                    ),
                  ]),
                  const SizedBox(height: AmDimens.gapM),
                  AmSectionLabel(label: l10n.remindersSectionDetails),
                  const SizedBox(height: AmDimens.gapXS),
                  AmGroupCard(children: [
                    AmInfoRow(
                      icon: selectedType != null
                          ? reminderIcon(selectedType.code)
                          : Icons.category_outlined,
                      label: l10n.remindersFieldType,
                      trailing: selectedType != null
                          ? ReminderTypeChip(
                              label: l10n.reminderType(selectedType.code),
                              fg: cs.primary,
                              bg: cs.primaryContainer,
                            )
                          : Text('—', style: TextStyle(color: cs.tertiary)),
                      chevron: types.isNotEmpty,
                      onTap: types.isEmpty
                          ? null
                          : () => _openTypeSheet(types, effectiveTypeId),
                    ),
                    const AmFormDivider(),
                    AmInfoRow(
                      icon: Icons.radio_button_checked_outlined,
                      label: l10n.remindersDetailStatus,
                      trailing: ReminderStatusChip(statusCode: _statusCode),
                      chevron: true,
                      onTap: _openStatusSheet,
                    ),
                    const AmFormDivider(),
                    AmInfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: l10n.remindersFieldDateTime,
                      trailing: Text(
                        '${fmtDateWithWeekday(_dueDate)} · ${fmtTime(_dueDate)}',
                        style: TextStyle(fontSize: 13.5, color: cs.onSurface),
                      ),
                      chevron: true,
                      onTap: _openDatePicker,
                    ),
                  ]),
                  const SizedBox(height: AmDimens.gapM),
                  AmSectionLabel(label: l10n.remindersDetailRelations),
                  const SizedBox(height: AmDimens.gapXS),
                  AmGroupCard(children: [
                    AmInfoRow(
                      icon: Icons.person_outline,
                      label: l10n.remindersFieldClient,
                      trailing: selectedContact != null
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AmAvatar(
                                  initials: selectedContact.initials,
                                  color: selectedContact.color,
                                  size: 26,
                                  radius: 8,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  selectedContact.fullName,
                                  style: TextStyle(
                                      fontSize: 13.5, color: cs.onSurface),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            )
                          : Text(
                              l10n.remindersNoClientOption,
                              style:
                                  TextStyle(fontSize: 13.5, color: cs.tertiary),
                            ),
                      chevron: true,
                      onTap: _openClientSheet,
                    ),
                    const AmFormDivider(),
                    AmInfoRow(
                      icon: Icons.description_outlined,
                      label: l10n.remindersDetailPolicy,
                      trailing: Text(
                        selectedPolicy?.policyNumber ??
                            (_clienteId == null
                                ? l10n.remindersPolicyNeedsClient
                                : l10n.remindersNoPolicyOption),
                        style: TextStyle(fontSize: 13.5, color: cs.tertiary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      chevron: _clienteId != null,
                      onTap: _clienteId == null
                          ? null
                          : () => _openPolicySheet(_clienteId!),
                    ),
                  ]),
                  const SizedBox(height: AmDimens.gapL),
                  AmPress(
                    onTap: canSave ? () => _save(effectiveTypeId) : null,
                    child: Opacity(
                      opacity: canSave ? 1.0 : 0.5,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 17),
                        decoration: BoxDecoration(
                          color: AmColors.accent,
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: createState.loading
                            ? const Center(
                                child: AmSpinner(
                                    size: 20, strokeWidth: 2, color: Colors.white),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.notifications_outlined,
                                      size: 19, color: Colors.white),
                                  const SizedBox(width: 9),
                                  Text(
                                    l10n.remindersCreateBtn,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  if (createState.error != null) ...[
                    const SizedBox(height: AmDimens.gapS),
                    Text(
                      context.translateError(createState.error),
                      style: TextStyle(fontSize: 13, color: cs.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
              if (_showSuccess)
                Container(
                  color: AmColors.scrim,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(34, 30, 34, 30),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AmShadows.card,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: am.greenWash,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.check, size: 38, color: am.green),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            l10n.remindersCreated,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface),
                          ),
                        ],
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
