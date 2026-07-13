import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/contact.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/am_theme.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/error_translator.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/am_form_row.dart';
import '../../../core/widgets/am_group_card.dart';
import '../../../core/widgets/am_info_row.dart';
import '../../../core/widgets/am_keyboard_dismiss.dart';
import '../../../core/widgets/am_press.dart';
import '../../../core/widgets/am_section_label.dart';
import '../../../core/widgets/am_top_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/clients_provider.dart';

class CreateClientScreen extends ConsumerStatefulWidget {
  const CreateClientScreen({super.key, this.contact});

  /// Si se provee, la pantalla precarga sus datos y guarda actualizando
  /// en vez de crear un cliente nuevo.
  final Contact? contact;

  @override
  ConsumerState<CreateClientScreen> createState() => _CreateClientScreenState();
}

class _CreateClientScreenState extends ConsumerState<CreateClientScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _occupationCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _rfcCtrl = TextEditingController();
  final _curpCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _birthdate;
  bool _showSuccess = false;

  bool get _isEditing => widget.contact != null;

  @override
  void initState() {
    super.initState();
    final contact = widget.contact;
    if (contact != null) {
      _nameCtrl.text = contact.fullName;
      _phoneCtrl.text = contact.phone ?? '';
      _emailCtrl.text = contact.email ?? '';
      _occupationCtrl.text = contact.occupation ?? '';
      _addressCtrl.text = contact.address ?? '';
      _rfcCtrl.text = contact.rfc ?? '';
      _curpCtrl.text = contact.curp ?? '';
      _notesCtrl.text = contact.notes ?? '';
      _birthdate = contact.birthdate != null
          ? DateTime.tryParse(contact.birthdate!)
          : null;
    }
    _nameCtrl.addListener(_rebuild);
    // Estado del provider de creación es compartido entre visitas a esta
    // pantalla — limpiar cualquier error de un intento anterior. Diferido
    // porque Riverpod prohíbe modificar un provider durante el build.
    Future.microtask(() {
      if (mounted) ref.read(createClientProvider.notifier).reset();
    });
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _nameCtrl.removeListener(_rebuild);
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _occupationCtrl.dispose();
    _addressCtrl.dispose();
    _rfcCtrl.dispose();
    _curpCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthdate ?? DateTime(now.year - 30, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthdate = picked);
  }

  Future<void> _save() async {
    final notifier = ref.read(createClientProvider.notifier);
    final fullName = _nameCtrl.text.trim();
    final phone =
        _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim();
    final email =
        _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim();
    final birthdate = _birthdate?.toIso8601String().split('T').first;
    final occupation = _occupationCtrl.text.trim().isEmpty
        ? null
        : _occupationCtrl.text.trim();
    final address =
        _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim();
    final rfc = _rfcCtrl.text.trim().isEmpty ? null : _rfcCtrl.text.trim();
    final curp = _curpCtrl.text.trim().isEmpty ? null : _curpCtrl.text.trim();
    final notes =
        _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();

    final saved = _isEditing
        ? await notifier.updateContact(
            widget.contact!.id,
            fullName: fullName,
            phone: phone,
            email: email,
            birthdate: birthdate,
            occupation: occupation,
            address: address,
            rfc: rfc,
            curp: curp,
            notes: notes,
          )
        : await notifier.submit(
            fullName: fullName,
            phone: phone,
            email: email,
            birthdate: birthdate,
            occupation: occupation,
            address: address,
            rfc: rfc,
            curp: curp,
            notes: notes,
          );
    if (!mounted || saved == null) return;
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

    final createState = ref.watch(createClientProvider);
    final canSave = _nameCtrl.text.trim().isNotEmpty && !createState.loading;

    return Scaffold(
      appBar: AmTopBar(
        title: _isEditing ? l10n.clientsEditTitle : l10n.clientsNewTitle,
        showBack: true,
      ),
      body: SafeArea(
        top: false,
        child: AmKeyboardDismiss(
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(
                    AmDimens.screenH, AmDimens.gapM, AmDimens.screenH, 40),
                children: [
                  AmSectionLabel(label: l10n.clientsSectionPersonal),
                  const SizedBox(height: AmDimens.gapXS),
                  AmGroupCard(children: [
                    AmFormRow(
                      label: l10n.fieldFullName,
                      controller: _nameCtrl,
                      icon: Icons.person_outline,
                    ),
                    const AmFormDivider(),
                    AmFormRow(
                      label: l10n.fieldOccupation,
                      controller: _occupationCtrl,
                      icon: Icons.work_outline,
                    ),
                    const AmFormDivider(),
                    AmInfoRow(
                      icon: Icons.cake_outlined,
                      label: l10n.fieldBirthdate,
                      trailing: Text(
                        _birthdate != null
                            ? fmtDate(_birthdate, showYear: true)
                            : l10n.clientsFieldNoBirthdate,
                        style: TextStyle(fontSize: 13.5, color: cs.onSurface),
                      ),
                      chevron: true,
                      onTap: _pickBirthdate,
                    ),
                  ]),
                  const SizedBox(height: AmDimens.gapM),
                  AmSectionLabel(label: l10n.clientsContactSection),
                  const SizedBox(height: AmDimens.gapXS),
                  AmGroupCard(children: [
                    AmFormRow(
                      label: l10n.fieldPhone,
                      controller: _phoneCtrl,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const AmFormDivider(),
                    AmFormRow(
                      label: l10n.fieldEmail,
                      controller: _emailCtrl,
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const AmFormDivider(),
                    AmFormRow(
                      label: l10n.fieldAddress,
                      controller: _addressCtrl,
                      icon: Icons.location_on_outlined,
                    ),
                  ]),
                  const SizedBox(height: AmDimens.gapM),
                  AmSectionLabel(label: l10n.clientsSectionFiscal),
                  const SizedBox(height: AmDimens.gapXS),
                  AmGroupCard(children: [
                    Row(
                      children: [
                        Expanded(
                          child: AmFormRow(
                            label: l10n.fieldRfc,
                            controller: _rfcCtrl,
                            icon: Icons.badge_outlined,
                          ),
                        ),
                        Expanded(
                          child: AmFormRow(
                            label: l10n.fieldCurp,
                            controller: _curpCtrl,
                            icon: Icons.fingerprint,
                          ),
                        ),
                      ],
                    ),
                  ]),
                  const SizedBox(height: AmDimens.gapM),
                  AmSectionLabel(label: l10n.clientsFieldGeneralNotes),
                  const SizedBox(height: AmDimens.gapXS),
                  AmGroupCard(children: [
                    AmFormRow(
                      label: l10n.clientsFieldGeneralNotes,
                      controller: _notesCtrl,
                      icon: Icons.notes_outlined,
                      minLines: 2,
                      maxLines: 4,
                    ),
                  ]),
                  const SizedBox(height: AmDimens.gapL),
                  AmPress(
                    onTap: canSave ? _save : null,
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
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                      _isEditing
                                          ? Icons.save_outlined
                                          : Icons.person_add_alt_1_outlined,
                                      size: 19,
                                      color: Colors.white),
                                  const SizedBox(width: 9),
                                  Text(
                                    _isEditing
                                        ? l10n.accountSave
                                        : l10n.clientsCreateBtn,
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
                  color: Colors.black.withValues(alpha: 0.34),
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
                            _isEditing
                                ? l10n.clientsUpdated
                                : l10n.clientsCreated,
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
