import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/agent_note.dart';
import '../../../core/models/policy.dart';
import '../../../core/repositories/supabase_note_repository.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/am_card.dart';
import '../../../core/widgets/am_confirm_dialog.dart';
import '../../../core/widgets/am_ramo_icon.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/clients_provider.dart';

class ClientPolicyCard extends ConsumerStatefulWidget {
  const ClientPolicyCard({super.key, required this.policy});

  final Policy policy;

  @override
  ConsumerState<ClientPolicyCard> createState() => _ClientPolicyCardState();
}

class _ClientPolicyCardState extends ConsumerState<ClientPolicyCard> {
  bool _showObsolete = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final policy = widget.policy;
    final isActive = policy.statusCode == 'ACTIVE';

    final notesAsync = ref.watch(policyNotesProvider(policy.id));
    final notes = notesAsync.asData?.value ?? <AgentNote>[];
    final activeNotes = notes.where((n) => !n.isObsolete).toList();
    final obsoleteNotes = notes.where((n) => n.isObsolete).toList();

    return AmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AmRamoIcon(ramo: policy.branchName, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      policy.productName,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _carrierAndNumber(policy),
                      style: TextStyle(fontSize: 12.5, color: cs.tertiary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF0E7C42).withValues(alpha: 0.08)
                      : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? l10n.clientsPolicyActive : policy.statusCode,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color:
                        isActive ? const Color(0xFF0E7C42) : cs.tertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ── Data grid ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _DataCell(
                      label: l10n.clientsPolicySumInsured,
                      value: fmtCurrency(policy.sumInsured),
                    ),
                    _DataCell(
                      label: l10n.clientsPolicyPremium,
                      value: fmtPremium(policy.premium, policy.frequencyLabel),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _DataCell(
                      label: l10n.clientsPolicyNextPayment,
                      value: fmtDateFromIso(policy.nextPaymentDate),
                    ),
                    _DataCell(
                      label: l10n.clientsPolicyDeductible,
                      value: policy.deductible ?? '—',
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ── Files section ─────────────────────────────────────────────────
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(color: cs.outlineVariant, height: 1),
            const SizedBox(height: 12),
            Text(
              l10n.clientsPolicyFiles,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: cs.tertiary,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            for (final note in activeNotes)
              _PolicyFileRow(note: note, l10n: l10n),
            if (obsoleteNotes.isNotEmpty) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => setState(() => _showObsolete = !_showObsolete),
                child: Row(
                  children: [
                    AnimatedRotation(
                      turns: _showObsolete ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: cs.tertiary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.clientsPolicyOldVersions(obsoleteNotes.length),
                      style: TextStyle(fontSize: 12, color: cs.tertiary),
                    ),
                  ],
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _showObsolete
                    ? Column(
                        children: [
                          const SizedBox(height: 6),
                          for (final note in obsoleteNotes)
                            _PolicyFileRow(
                              note: note,
                              l10n: l10n,
                              onDelete: () => _confirmDelete(note),
                            ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(AgentNote note) async {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AmConfirmDialog(
        title: l10n.clientsPolicyDeleteNoteTitle,
        message: l10n.clientsPolicyDeleteNoteMsg,
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
      ref.invalidate(policyNotesProvider(widget.policy.id));
    } catch (_) {}
  }

  String _carrierAndNumber(Policy p) {
    final parts = <String>[
      if (p.carrierName.isNotEmpty && p.carrierName != '—') p.carrierName,
      if (p.policyNumber?.isNotEmpty == true) p.policyNumber!,
    ];
    return parts.join(' · ');
  }
}

class _PolicyFileRow extends StatefulWidget {
  const _PolicyFileRow({
    required this.note,
    required this.l10n,
    this.onDelete,
  });

  final AgentNote note;
  final AppLocalizations l10n;
  final VoidCallback? onDelete;

  @override
  State<_PolicyFileRow> createState() => _PolicyFileRowState();
}

class _PolicyFileRowState extends State<_PolicyFileRow> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final note = widget.note;
    final fileName = note.fileName ?? 'documento.pdf';
    final dt = DateTime.tryParse(note.createdAt)?.toLocal();
    final dateStr = dt != null ? DateFormat.MMMd().format(dt) : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: note.isObsolete
                  ? cs.surfaceContainerHighest
                  : cs.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.picture_as_pdf_outlined,
              size: 17,
              color: note.isObsolete ? cs.tertiary : cs.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: note.isObsolete ? cs.tertiary : cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Text(
                      dateStr,
                      style: TextStyle(fontSize: 11.5, color: cs.tertiary),
                    ),
                    if (note.isObsolete) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.errorContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.l10n.clientsPolicyFileObsolete,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: cs.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (note.storagePath != null)
            GestureDetector(
              onTap: _openFile,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius:
                      BorderRadius.circular(AmDimens.cardRadius / 2),
                ),
                child: _loading
                    ? SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: cs.onSurfaceVariant,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.open_in_new_rounded,
                              size: 12, color: cs.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            widget.l10n.clientsNoteOpenFile,
                            style: TextStyle(
                                fontSize: 12, color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
              ),
            ),
          if (note.isObsolete && widget.onDelete != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: widget.onDelete,
              child: Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: cs.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openFile() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final signedUrl = await Supabase.instance.client.storage
          .from('policies')
          .createSignedUrl(widget.note.storagePath!, 3600);
      final uri = Uri.parse(signedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _DataCell extends StatelessWidget {
  const _DataCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: cs.tertiary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
