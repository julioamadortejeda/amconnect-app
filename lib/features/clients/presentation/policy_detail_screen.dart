import 'package:flutter/material.dart';
import '../../../core/widgets/am_spinner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/agent_note.dart';
import '../../../core/models/policy.dart';
import '../../../core/repositories/supabase_note_repository.dart';
import '../../../core/repositories/supabase_policy_repository.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/catalog_l10n.dart';
import '../../../core/widgets/am_confirm_dialog.dart';
import '../../../core/widgets/am_form_row.dart';
import '../../feed/widgets/ingest_type_picker.dart';
import '../../../core/widgets/am_group_card.dart';
import '../../../core/widgets/am_info_row.dart';
import '../../../core/widgets/am_loader.dart';
import '../../../core/widgets/am_press.dart';
import '../../../core/widgets/am_ramo_icon.dart';
import '../../../core/widgets/am_section_label.dart';
import '../../../core/widgets/am_text_field.dart';
import '../../../core/widgets/am_top_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/clients_provider.dart';
import '../widgets/policy_detail_note_row.dart';
import '../widgets/policy_status_chip.dart';
import '../../../core/widgets/am_ai_ask_button.dart';
import '../../../core/models/ai_chat_context.dart';

class PolicyDetailScreen extends ConsumerStatefulWidget {
  const PolicyDetailScreen({super.key, this.policy, this.policyId})
      : assert(policy != null || policyId != null,
            'Must provide either policy or policyId');

  final Policy? policy;
  final String? policyId;

  @override
  ConsumerState<PolicyDetailScreen> createState() =>
      _PolicyDetailScreenState();
}

class _PolicyDetailScreenState extends ConsumerState<PolicyDetailScreen> {
  Policy? _policy;
  bool _loading = false;
  bool _loadError = false;
  final _noteCtrl = TextEditingController();
  bool _sendingNote = false;

  @override
  void initState() {
    super.initState();
    if (widget.policy != null) {
      _policy = widget.policy;
    } else {
      _loadPolicy();
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPolicy() async {
    setState(() {
      _loading = true;
      _loadError = false;
    });
    try {
      final p = await ref.read(policyRepositoryProvider).getById(widget.policyId!);
      if (!mounted) return;
      setState(() {
        _policy = p;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = true;
      });
    }
  }

  Future<void> _edit() async {
    final result = await context.push<Policy>('/create-policy', extra: _policy);
    if (result != null && mounted) setState(() => _policy = result);
  }

  Future<void> _sendNote() async {
    final text = _noteCtrl.text.trim();
    final policy = _policy;
    if (text.isEmpty || policy == null || _sendingNote) return;
    setState(() => _sendingNote = true);
    try {
      await ref.read(noteRepositoryProvider).createPolicyNote(policy.id, text);
      _noteCtrl.clear();
      ref.invalidate(policyNotesProvider(policy.id));
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.policiesErrAddNote),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _sendingNote = false);
    }
  }

  Future<void> _confirmDeletePolicy() async {
    final policy = _policy;
    if (policy == null) return;
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AmConfirmDialog(
        title: l10n.policiesDeleteTitle,
        message: l10n.policiesDeleteMessage,
        confirmLabel: l10n.commonDelete,
        cancelLabel: l10n.commonCancel,
        icon: Icons.delete_outline_rounded,
        iconBgColor: cs.errorContainer,
        iconFgColor: cs.error,
        onConfirm: () => Navigator.of(ctx).pop(true),
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(policiesProvider.notifier).delete(policy.id);
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.policiesErrDelete),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _confirmDeleteNote(AgentNote note) async {
    final policy = _policy;
    if (policy == null) return;
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AmConfirmDialog(
        title: l10n.policiesDeleteNoteTitle,
        message: l10n.policiesDeleteNoteMsg,
        confirmLabel: l10n.commonDelete,
        cancelLabel: l10n.commonCancel,
        icon: Icons.delete_outline_rounded,
        iconBgColor: cs.errorContainer,
        iconFgColor: cs.error,
        onConfirm: () => Navigator.of(ctx).pop(true),
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(noteRepositoryProvider).deleteNote(note.id);
      ref.invalidate(policyNotesProvider(policy.id));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.policiesErrDeleteNote),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    if (_loading) {
      return Scaffold(
        appBar: AmTopBar(title: l10n.policiesDetailTitle, showBack: true),
        body: const AmLoader(),
      );
    }

    if (_loadError || _policy == null) {
      return Scaffold(
        appBar: AmTopBar(title: l10n.policiesDetailTitle, showBack: true),
        body: SafeArea(
          top: false,
          child: Center(
            child: Text(
              l10n.policiesDetailLoadError,
              style: TextStyle(color: cs.error, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final policy = _policy!;
    ref.watch(policyNotesRealtimeProvider(policy.id));
    final notesAsync = ref.watch(policyNotesProvider(policy.id));
    final notes = notesAsync.asData?.value ?? <AgentNote>[];

    return Scaffold(
      bottomNavigationBar: AmAiAskButton(
        label: l10n.policiesAskAbout,
        aiContext: AiChatContext.fromPolicy(policy, notes: notes),
      ),
      appBar: AmTopBar(
        title: l10n.policiesDetailTitle,
        showBack: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: AmPress(
              onTap: _edit,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.edit_outlined,
                    size: 18, color: cs.onSurfaceVariant),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: AmPress(
              onTap: _confirmDeletePolicy,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.delete_outline_rounded,
                    size: 18, color: cs.error),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AmDimens.screenH, AmDimens.gapM, AmDimens.screenH, 40),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AmRamoIcon(ramo: policy.branchName, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        policy.productName,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _carrierAndNumber(policy),
                        style: TextStyle(fontSize: 13, color: cs.tertiary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AmDimens.gapL),

            AmSectionLabel(label: l10n.policiesDetailCoverage),
            const SizedBox(height: AmDimens.gapXS),
            AmGroupCard(children: [
              AmInfoRow(
                icon: Icons.info_outline,
                label: l10n.policiesStatus,
                trailing: PolicyStatusChip(
                  statusCode: policy.statusCode,
                  rawName: policy.status?.name,
                ),
              ),
              const AmFormDivider(),
              AmInfoRow(
                icon: Icons.shield_outlined,
                label: l10n.policiesSumInsured,
                trailing: Text(fmtCurrency(policy.sumInsured)),
              ),
              const AmFormDivider(),
              AmInfoRow(
                icon: Icons.wallet_outlined,
                label: l10n.policiesPremium,
                trailing: Text(fmtPremium(policy.premium, policy.frequencyLabel)),
              ),
              const AmFormDivider(),
              AmInfoRow(
                icon: Icons.price_change_outlined,
                label: l10n.policiesDeductible,
                trailing: Text(policy.deductible ?? '—'),
              ),
              const AmFormDivider(),
              AmInfoRow(
                icon: Icons.monetization_on_outlined,
                label: l10n.policiesCurrency,
                trailing: Text(policy.currencyCode),
              ),
              const AmFormDivider(),
              AmInfoRow(
                icon: Icons.payment_outlined,
                label: l10n.policiesPaymentMethod,
                trailing: Text(policy.paymentMethod != null
                    ? l10n.paymentMethod(policy.paymentMethod!.name.toUpperCase())
                    : '—'),
              ),
            ]),
            const SizedBox(height: AmDimens.gapM),

            AmSectionLabel(label: l10n.policiesDetailDates),
            const SizedBox(height: AmDimens.gapXS),
            AmGroupCard(children: [
              AmInfoRow(
                icon: Icons.calendar_today_outlined,
                label: l10n.policiesStartDate,
                trailing: Text(fmtDateFromIso(policy.startDate)),
              ),
              const AmFormDivider(),
              AmInfoRow(
                icon: Icons.event_busy_outlined,
                label: l10n.policiesEndDate,
                trailing: Text(fmtDateFromIso(policy.endDate)),
              ),
              const AmFormDivider(),
              AmInfoRow(
                icon: Icons.autorenew_outlined,
                label: l10n.policiesRenewalDate,
                trailing: Text(fmtDateFromIso(policy.renewalDate)),
              ),
              const AmFormDivider(),
              AmInfoRow(
                icon: Icons.next_plan_outlined,
                label: l10n.policiesNextPaymentDate,
                trailing: Text(fmtDateFromIso(policy.nextPaymentDate)),
              ),
            ]),
            const SizedBox(height: AmDimens.gapM),

            AmSectionLabel(
              label: l10n.policiesNotesSection,
              trailing: GestureDetector(
                onTap: () => IngestTypePicker.show(
                  context,
                  contactId: policy.contactId,
                  policyId: policy.id,
                  showPolicyExtraction: false,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.attach_file_outlined, size: 14, color: cs.primary),
                    const SizedBox(width: 4),
                    Text(
                      l10n.policiesAttachFile,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AmDimens.gapXS),
            AmGroupCard(children: [
              if (notes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AmDimens.screenH, vertical: AmDimens.gapS),
                  child: Text(
                    l10n.policiesEmptyNotes,
                    style: TextStyle(fontSize: 13.5, color: cs.tertiary),
                  ),
                )
              else
                for (final note in notes)
                  PolicyDetailNoteRow(
                    note: note,
                    onDelete: note.sourceType == 'text'
                        ? () => _confirmDeleteNote(note)
                        : null,
                  ),
              const AmFormDivider(),
              Padding(
                padding: const EdgeInsets.all(AmDimens.gapS),
                child: AmTextField(
                  controller: _noteCtrl,
                  hint: l10n.policiesAddNoteHint,
                  icon: Icons.edit_note_outlined,
                  onSubmitted: (_) => _sendNote(),
                  suffix: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _sendingNote
                        ? const AmSpinner(size: 18, strokeWidth: 2)
                        : IconButton(
                            icon: Icon(Icons.send_rounded, color: cs.primary),
                            onPressed: _sendNote,
                          ),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  String _carrierAndNumber(Policy p) {
    final parts = <String>[
      if (p.carrierName.isNotEmpty && p.carrierName != '—') p.carrierName,
      if (p.policyNumber?.isNotEmpty == true) p.policyNumber!,
    ];
    return parts.join(' · ');
  }
}

