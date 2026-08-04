import 'package:flutter/material.dart';
import '../../../core/widgets/am_spinner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/agent_note.dart';
import '../../../core/repositories/supabase_storage_repository.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../l10n/app_localizations.dart';

/// Fila de nota/documento ligada a una póliza en la pantalla de detalle.
class PolicyDetailNoteRow extends ConsumerStatefulWidget {
  const PolicyDetailNoteRow({super.key, required this.note, this.onDelete});

  final AgentNote note;
  final VoidCallback? onDelete;

  @override
  ConsumerState<PolicyDetailNoteRow> createState() => _PolicyDetailNoteRowState();
}

class _PolicyDetailNoteRowState extends ConsumerState<PolicyDetailNoteRow> {
  bool _openingFile = false;

  Future<void> _openFile() async {
    if (_openingFile || widget.note.storagePath == null) return;
    setState(() => _openingFile = true);
    try {
      final signedUrl = await ref
          .read(storageRepositoryProvider)
          .getSignedUrl(widget.note.storagePath!);
      final uri = Uri.parse(signedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.errFileOpenFailed),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _openingFile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final note = widget.note;
    final dt = DateTime.tryParse(note.createdAt)?.toLocal();
    final dateStr = dt != null ? DateFormat.MMMd().format(dt) : '';
    final isTextNote = note.sourceType == 'text';

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AmDimens.screenH, vertical: AmDimens.gapS / 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isTextNote ? Icons.sticky_note_2_outlined : Icons.picture_as_pdf_outlined,
              size: 17,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTextNote ? note.content : (note.fileName ?? 'documento.pdf'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(dateStr, style: TextStyle(fontSize: 11.5, color: cs.tertiary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!isTextNote && note.storagePath != null)
            GestureDetector(
              onTap: _openFile,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(AmDimens.cardRadius / 2),
                ),
                child: _openingFile
                    ? AmSpinner(
                        size: 12,
                        strokeWidth: 1.5,
                        color: cs.onSurfaceVariant,
                      )
                    : Icon(Icons.open_in_new_rounded, size: 14, color: cs.onSurfaceVariant),
              ),
            ),
          if (widget.onDelete != null)
            GestureDetector(
              onTap: widget.onDelete,
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(Icons.delete_outline_rounded, size: 18, color: cs.error),
              ),
            ),
        ],
      ),
    );
  }
}
