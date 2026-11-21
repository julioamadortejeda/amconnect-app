import 'package:flutter/material.dart';
import '../am_spinner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../repositories/supabase_storage_repository.dart';
import '../../theme/am_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../../l10n/app_localizations.dart';

// ═══════════════════════════════════════════════════════════════════════════════
//  ATTACHMENT LIST CARD
// ═══════════════════════════════════════════════════════════════════════════════

class AttachmentListCard extends StatelessWidget {
  const AttachmentListCard({super.key, required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final attachmentsRaw = data['attachments'] as List? ?? [];

    if (attachmentsRaw.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AmDimens.cardRadius),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: AmShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              children: [
                Icon(Icons.attach_file_rounded, color: cs.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  l10n.remindersDetailAttachments,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final item in attachmentsRaw)
            if (item is Map<String, dynamic>) _AttachmentItemRow(item: item),
        ],
      ),
    );
  }
}

class _AttachmentItemRow extends ConsumerStatefulWidget {
  const _AttachmentItemRow({required this.item});
  final Map<String, dynamic> item;

  @override
  ConsumerState<_AttachmentItemRow> createState() => _AttachmentItemRowState();
}

class _AttachmentItemRowState extends ConsumerState<_AttachmentItemRow> {
  bool _opening = false;

  Future<void> _openFile() async {
    final path = widget.item['storagePath'] as String?;
    if (path == null || path.isEmpty || _opening) return;
    setState(() => _opening = true);
    try {
      final signedUrl = await ref
          .read(storageRepositoryProvider)
          .getSignedUrl(path);
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
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final fileName = widget.item['fileName'] as String? ??
        widget.item['summary'] as String? ??
        l10n.chatCardAttachmentFallback;
    final sourceType = widget.item['sourceType'] as String? ?? 'document';
    final summary = widget.item['summary'] as String?;
    final hasFile = widget.item['storagePath'] != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                  AmColors.srcDoc.withValues(alpha: 0.14), cs.surface),
              borderRadius: BorderRadius.circular(AmDimens.radiusS),
            ),
            child: Icon(
              AmIcons.forSourceType(sourceType),
              size: 18,
              color: AmColors.srcDoc,
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
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (summary != null &&
                    summary.isNotEmpty &&
                    summary != fileName) ...[
                  const SizedBox(height: 2),
                  Text(
                    summary,
                    style: TextStyle(fontSize: 12, color: cs.tertiary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (hasFile) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _openFile,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius:
                      BorderRadius.circular(AmDimens.cardRadius / 2),
                ),
                child: _opening
                    ? AmSpinner(
                        size: 13,
                        strokeWidth: 1.5,
                        color: cs.onSurfaceVariant,
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.open_in_new_rounded,
                              size: 13, color: cs.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            l10n.clientsNoteOpenFile,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
