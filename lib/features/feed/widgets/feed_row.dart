import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/repositories/supabase_storage_repository.dart';
import '../../../core/theme/am_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/app_localizations.dart';
import '../../chat/data/chat_context.dart';
import '../data/feed_item.dart';

/// Fila expandible de un documento/nota en las listas del Feed.
/// Muestra resumen/contenido al expandir, abre el archivo con URL firmada
/// y permite saltar al chat de IA con la nota como contexto.
class FeedRow extends ConsumerStatefulWidget {
  const FeedRow({super.key, required this.item});

  final FeedItem item;

  @override
  ConsumerState<FeedRow> createState() => _FeedRowState();
}

class _FeedRowState extends ConsumerState<FeedRow> {
  bool _loadingFile = false;
  bool _expanded = false;

  static (IconData, Color) _typeStyle(String sourceType) => (
    AmIcons.forSourceType(sourceType),
    switch (sourceType) {
      'pdf' || 'doc' || 'document' => AmColors.srcDoc,
      'audio' || 'wave'            => AmColors.srcWave,
      'image' || 'photo'           => AmColors.srcImage,
      'text'                       => AmColors.srcNote,
      _                            => AmColors.srcWhatsApp,
    },
  );

  Future<void> _openFile() async {
    final storagePath = widget.item.storagePath;
    if (storagePath == null || _loadingFile) return;

    setState(() => _loadingFile = true);
    try {
      final signedUrl = await ref
          .read(storageRepositoryProvider)
          .getSignedUrl(storagePath);
      final uri = Uri.parse(signedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // silently ignore or show alert
    } finally {
      if (mounted) {
        setState(() => _loadingFile = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final (icon, color) = _typeStyle(widget.item.sourceType);
    final bg = Color.alphaBlend(color.withValues(alpha: 0.1), cs.surface);

    final name = widget.item.fileName ??
        widget.item.summary ??
        (widget.item.content != null && widget.item.content!.length > 45
            ? '${widget.item.content!.substring(0, 45).replaceAll('\n', ' ')}...'
            : widget.item.content) ??
        l10n.feedTypeDocument;

    final date = fmtRelativeDay(DateTime.tryParse(widget.item.createdAt), l10n);
    final hasFile = widget.item.storagePath != null;
    final hasSummary = widget.item.summary != null && widget.item.summary!.isNotEmpty;
    final hasContent = widget.item.content != null && widget.item.content!.isNotEmpty;

    final typeLabel = switch (widget.item.sourceType) {
      'pdf' || 'doc' || 'document' => l10n.clientsNoteTypePdf,
      'audio' || 'wave'            => l10n.clientsNoteTypeAudio,
      'image' || 'photo'           => l10n.clientsNoteTypeImage,
      'whatsapp'                   => l10n.clientsNoteTypeWhatsapp,
      'text' || _                  => l10n.clientsNoteTypeText,
    };
    final subtitleText = '$typeLabel · $date';

    final contentWidget = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: _loadingFile
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AmColors.accent),
                    ),
                  ),
                )
              : Icon(icon, size: 19, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurface,
                  height: 1.4,
                ),
                maxLines: _expanded ? null : 2,
                overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
              if (_expanded) ...[
                if (hasSummary && widget.item.fileName != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.item.summary!,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: cs.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ],
                if (hasContent && (widget.item.fileName == null || _expanded)) ...[
                  const SizedBox(height: 8),
                  if (hasSummary && widget.item.fileName != null) ...[
                    Container(height: 1, color: cs.outlineVariant),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    widget.item.content!,
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      subtitleText,
                      style: TextStyle(fontSize: 12, color: cs.tertiary),
                    ),
                  ),
                  if (hasFile)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _openFile,
                      child: _OpenFileButton(
                        loading: _loadingFile,
                        label: l10n.clientsNoteOpenFile,
                      ),
                    )
                  else
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: cs.tertiary,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: IconButton(
            icon: Image.asset(
              'assets/logo/logo_t.png',
              width: 18,
              height: 18,
              color: AmColors.accent,
            ),
            onPressed: () {
              context.push('/chat', extra: AiChatContext.fromKnowledgeNote(widget.item));
            },
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
            style: IconButton.styleFrom(
              backgroundColor: cs.primaryContainer.withValues(alpha: 0.5),
              shape: const CircleBorder(),
            ),
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AmDimens.cardPad),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AmDimens.cardRadius),
            boxShadow: AmShadows.card,
          ),
          child: contentWidget,
        ),
      ),
    );
  }
}

class _OpenFileButton extends StatelessWidget {
  const _OpenFileButton({required this.loading, required this.label});

  final bool loading;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(AmDimens.cardRadius / 2),
      ),
      child: loading
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
                  label,
                  style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
    );
  }
}
