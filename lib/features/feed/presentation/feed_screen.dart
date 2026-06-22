import 'dart:io';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/repositories/supabase_note_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_badge.dart';
import '../../../core/widgets/am_card.dart';
import '../../../core/widgets/am_loader.dart';
import '../../../core/widgets/am_section_label.dart';
import '../../../core/widgets/am_stagger.dart';
import '../../../core/widgets/am_top_bar.dart';
import '../data/feed_item.dart';
import '../providers/ingest_provider.dart';
import '../../../l10n/app_localizations.dart';
import 'ingest_chat_sheet.dart';
import 'knowledge_success_sheet.dart';
import 'policy_success_sheet.dart';
import 'text_ingest_sheet.dart';
import '../../chat/data/chat_context.dart';
import '../providers/knowledge_dashboard_provider.dart';

// ── Providers ──────────────────────────────────────────────────────────────────

final recentFeedProvider = FutureProvider<List<FeedItem>>((ref) {
  return ref.read(noteRepositoryProvider).getRecent();
});

// ── Screen ─────────────────────────────────────────────────────────────────────

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  bool _isPickingFile = false;

  Future<void> _safePick(Future<void> Function() action) async {
    if (_isPickingFile) return;
    setState(() => _isPickingFile = true);
    try {
      await action().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException("La selección de archivo tardó demasiado tiempo.");
        },
      );
    } catch (e) {
      debugPrint('Error picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is TimeoutException ? (e.message ?? 'La selección de archivo tardó demasiado tiempo.') : 'Error al abrir el selector: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingFile = false);
      }
    }
  }

  Future<void> _pickPolicyPdf() => _safePick(() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null) return;
    if (result.files.single.path == null) {
      _showNullPathAlert();
      return;
    }
    await ref.read(ingestProvider.notifier).processPolicy(
          File(result.files.single.path!),
          result.files.single.name,
        );
  });

  Future<void> _pickPolicyImage() => _safePick(() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result == null) return;
    if (result.files.single.path == null) {
      _showNullPathAlert();
      return;
    }
    await ref.read(ingestProvider.notifier).processPolicy(
          File(result.files.single.path!),
          result.files.single.name,
        );
  });

  Future<void> _pickKnowledgeImage() => _safePick(() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result == null) return;
    if (result.files.single.path == null) {
      _showNullPathAlert();
      return;
    }
    await ref.read(ingestProvider.notifier).processKnowledgeFile(
          File(result.files.single.path!),
          result.files.single.name,
        );
  });

  Future<void> _pickKnowledgeAudio() => _safePick(() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'm4a', 'wav', 'aac', 'ogg'],
    );
    if (result == null) return;
    if (result.files.single.path == null) {
      _showNullPathAlert();
      return;
    }
    await ref.read(ingestProvider.notifier).processKnowledgeFile(
          File(result.files.single.path!),
          result.files.single.name,
        );
  });

  Future<void> _pickKnowledgeDocument() => _safePick(() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null) return;
    if (result.files.single.path == null) {
      _showNullPathAlert();
      return;
    }
    await ref.read(ingestProvider.notifier).processKnowledgeFile(
          File(result.files.single.path!),
          result.files.single.name,
        );
  });

  void _showNullPathAlert() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: El archivo seleccionado no devolvió una ruta local válida en iOS."),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openTextInput(String sourceType) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => TextIngestSheet(sourceType: sourceType),
    );
  }

  void _handleClose() {
    ref.read(ingestProvider.notifier).reset();
    ref.invalidate(recentFeedProvider);
  }

  void _showKnowledgeSuccess(String message) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => KnowledgeSuccessSheet(
        message: message,
        onClose: () => Navigator.of(ctx).pop(),
      ),
    ).then((_) => _handleClose());
  }

  void _showIngestBottomSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (_) => const _UnifiedIngestBottomSheet(),
    ).then((_) {
      final state = ref.read(ingestProvider);
      if (state.phase == IngestPhase.knowledgeSuccess && state.knowledgeMessage != null) {
        _showKnowledgeSuccess(state.knowledgeMessage!);
      } else if (state.phase != IngestPhase.idle) {
        ref.read(ingestProvider.notifier).reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<IngestState>(ingestProvider, (prev, next) {
      if ((next.phase == IngestPhase.uploading || next.phase == IngestPhase.processing) &&
          (prev == null || prev.phase == IngestPhase.idle)) {
        _showIngestBottomSheet();
      }
      if (next.phase == IngestPhase.error &&
          prev?.phase != IngestPhase.error &&
          next.error != null) {
        if (prev?.phase == IngestPhase.idle) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.error!),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final ingest = ref.watch(ingestProvider);
    final recentAsync = ref.watch(recentFeedProvider);

    final feedTypes = [
      _InputType('policyPdf', Icons.description_outlined, AmColors.srcDoc,
          l10n.feedTypePolicyPdf, l10n.feedTypePolicyPdfDesc,
          onTap: _pickPolicyPdf),
      _InputType('policyPhoto', Icons.camera_alt_outlined, AmColors.srcImage,
          l10n.feedTypePolicyPhoto, l10n.feedTypePolicyPhotoDesc,
          onTap: _pickPolicyImage),
      _InputType('audio', Icons.graphic_eq, AmColors.srcWave,
          l10n.feedTypeAudio, l10n.feedTypeAudioDesc,
          onTap: _pickKnowledgeAudio),
      _InputType('text', Icons.edit_note_outlined, AmColors.srcNote,
          l10n.feedTypeText, l10n.feedTypeTextDesc,
          onTap: () => _openTextInput('text')),
      _InputType('image', Icons.image_outlined, AmColors.srcImage,
          l10n.feedTypeKnowledgeImage, l10n.feedTypeKnowledgeImageDesc,
          onTap: _pickKnowledgeImage),
      _InputType('document', Icons.picture_as_pdf_outlined, AmColors.srcDoc,
          l10n.feedTypeDocument, l10n.feedTypeDocumentDesc,
          onTap: _pickKnowledgeDocument),
    ];

    final viewMode = ref.watch(feedViewModeProvider);

    return Scaffold(
      appBar: AmTopBar(
        title: l10n.feedTitle,
        subtitle: viewMode == FeedViewMode.knowledge
            ? l10n.feedViewModeKnowledge
            : l10n.feedViewModeIngest,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AmDimens.screenH, 12, AmDimens.screenH, 4),
              child: CupertinoSlidingSegmentedControl<FeedViewMode>(
                groupValue: viewMode,
                children: {
                  FeedViewMode.knowledge: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    child: Text(
                      l10n.feedViewModeKnowledge,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: viewMode == FeedViewMode.knowledge
                            ? cs.onSurface
                            : cs.tertiary,
                      ),
                    ),
                  ),
                  FeedViewMode.ingest: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    child: Text(
                      l10n.feedViewModeIngest,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: viewMode == FeedViewMode.ingest
                            ? cs.onSurface
                            : cs.tertiary,
                      ),
                    ),
                  ),
                },
                onValueChanged: (val) {
                  if (val != null) {
                    ref.read(feedViewModeProvider.notifier).toggle(val);
                  }
                },
              ),
            ),
            Expanded(
              child: Stack(
                children: [
            if (viewMode == FeedViewMode.ingest)
              ListView(
                padding: const EdgeInsets.fromLTRB(
                    AmDimens.screenH, 0, AmDimens.screenH, AmDimens.scrollBottomPad),
                children: [
                  const SizedBox(height: AmDimens.gapS),

                  // ── Input type grid ──────────────────────────────────────
                  AmAnimateIn(
                    index: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AmSectionLabel(label: l10n.feedQuestion),
                        const SizedBox(height: AmDimens.gapXS),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final cols = constraints.maxWidth < 340 ? 2 : 3;
                            return GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: cols,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: cols == 3 ? 0.95 : 1.1,
                              children: feedTypes
                                  .map((t) => _TypeCard(t: t, compact: cols == 3))
                                  .toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── WhatsApp card ────────────────────────────────────────
                  AmAnimateIn(
                    index: 1,
                    child: AmCard(
                      onTap: () => _openTextInput('whatsapp'),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Color.alphaBlend(
                                  AmColors.srcWhatsApp.withValues(alpha: 0.14),
                                  Colors.white),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(Icons.chat_bubble_outline,
                                size: 24, color: AmColors.srcWhatsApp),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.feedTypeWhatsapp,
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurface)),
                                const SizedBox(height: 2),
                                Text(l10n.feedTypeWhatsappDesc,
                                    style: TextStyle(
                                        fontSize: 12.5, color: cs.tertiary)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              color: cs.onSurfaceVariant, size: 18),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ── Recently uploaded ────────────────────────────────────
                  AmAnimateIn(
                    index: 2,
                    child: recentAsync.when(
                      loading: () => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AmSectionLabel(label: l10n.feedRecentlyUploaded),
                          const SizedBox(height: 10),
                          const AmLoader(),
                        ],
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (items) => items.isEmpty
                          ? const SizedBox.shrink()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AmSectionLabel(
                                  label: l10n.feedRecentlyUploaded,
                                  trailing: AmBadge(
                                      label: '${items.length}',
                                      tone: AmBadgeTone.accent),
                                ),
                                Column(
                                  children: items.map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: AmDimens.gapS),
                                    child: _FeedRow(item: item),
                                  )).toList(),
                                ),
                              ],
                            ),
                    ),
                  ),

                  // ── Error state ──────────────────────────────────────────
                  if (ingest.phase == IngestPhase.error && ingest.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cs.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: cs.error.withValues(alpha: 0.25)),
                        ),
                        child: Row(children: [
                          Icon(Icons.error_outline, color: cs.error, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(ingest.error!,
                                  style: TextStyle(
                                      fontSize: 13.5, color: cs.error))),
                          TextButton(
                            onPressed: _handleClose,
                            child: Text(l10n.commonClose,
                                style: TextStyle(color: cs.error, fontSize: 13)),
                          ),
                        ]),
                      ),
                    ),
                ],
              )
            else
              const _KnowledgeDashboardView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Type card ──────────────────────────────────────────────────────────────────

class _TypeCard extends StatelessWidget {
  const _TypeCard({required this.t, this.compact = false});

  final _InputType t;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = Color.alphaBlend(t.color.withValues(alpha: 0.14), Colors.white);
    final iconSize = compact ? 34.0 : 40.0;
    final iconInner = compact ? 18.0 : 22.0;
    final iconRadius = compact ? 10.0 : 13.0;

    return AmCard(
      onTap: t.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(iconRadius)),
            child: Icon(t.icon, size: iconInner, color: t.color),
          ),
          SizedBox(height: compact ? 7 : 10),
          Text(t.label,
              style: TextStyle(
                  fontSize: compact ? 13.0 : 15.0,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface)),
          const SizedBox(height: 3),
          Flexible(
            child: Text(t.sub,
                style: TextStyle(
                    fontSize: compact ? 11.0 : 12.0,
                    color: cs.tertiary,
                    height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ── Feed row ───────────────────────────────────────────────────────────────────

class _FeedRow extends ConsumerStatefulWidget {
  const _FeedRow({required this.item});

  final FeedItem item;

  @override
  ConsumerState<_FeedRow> createState() => _FeedRowState();
}

class _FeedRowState extends ConsumerState<_FeedRow> {
  bool _loadingFile = false;
  bool _expanded = false;

  static (IconData, Color) _typeStyle(String sourceType) =>
      switch (sourceType) {
        'pdf' || 'doc' || 'document' => (
            Icons.article_outlined,
            AmColors.srcDoc,
          ),
        'audio' || 'wave' => (
            Icons.volume_up_outlined,
            AmColors.srcWave,
          ),
        'image' || 'photo' => (
            Icons.image_outlined,
            AmColors.srcImage,
          ),
        _ => (Icons.chat_bubble_outline, AmColors.srcWhatsApp),
      };

  static String _relativeDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) return 'hoy';
      if (diff.inDays == 1) return 'ayer';
      if (diff.inDays < 7) {
        const days = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
        return days[dt.weekday - 1];
      }
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }

  Future<void> _openFile() async {
    final storagePath = widget.item.storagePath;
    if (storagePath == null || _loadingFile) return;

    setState(() => _loadingFile = true);
    try {
      final signedUrl = await Supabase.instance.client.storage
          .from('policies')
          .createSignedUrl(storagePath, 3600);
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
    final (icon, color) = _typeStyle(widget.item.sourceType);
    final bg = Color.alphaBlend(color.withValues(alpha: 0.1), cs.surface);
    
    final name = widget.item.fileName ?? 
        widget.item.summary ?? 
        (widget.item.content != null && widget.item.content!.length > 45 
            ? '${widget.item.content!.substring(0, 45).replaceAll('\n', ' ')}...' 
            : widget.item.content) ?? 
        'Documento';
        
    final date = _relativeDate(widget.item.createdAt);
    final hasFile = widget.item.storagePath != null;
    final hasSummary = widget.item.summary != null && widget.item.summary!.isNotEmpty;
    final hasContent = widget.item.content != null && widget.item.content!.isNotEmpty;
    final l10n = AppLocalizations.of(context)!;

    final typeLabel = switch (widget.item.sourceType) {
      'pdf' || 'doc' || 'document' => l10n.clientsNoteTypePdf,
      'audio' || 'wave'            => l10n.clientsNoteTypeAudio,
      'image' || 'photo'           => l10n.clientsNoteTypeImage,
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
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D141E1A),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
              BoxShadow(
                color: Color(0x0A141E1A),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
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

// ── Processing overlay ─────────────────────────────────────────────────────────

class _ProcessingOverlay extends StatelessWidget {
  const _ProcessingOverlay({required this.phase, this.statusMessageKey});

  final IngestPhase phase;
  final String? statusMessageKey;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final step1Status = switch (statusMessageKey) {
      'feedStepGettingUrl' => _StepStatus.active,
      'feedStepUploading' || 'feedStepProcessing' || null => _StepStatus.completed,
      _ => _StepStatus.pending,
    };

    final step2Status = switch (statusMessageKey) {
      'feedStepGettingUrl' => _StepStatus.pending,
      'feedStepUploading' => _StepStatus.active,
      'feedStepProcessing' || null => _StepStatus.completed,
      _ => _StepStatus.pending,
    };

    final step3Status = switch (statusMessageKey) {
      'feedStepProcessing' => _StepStatus.active,
      null => _StepStatus.completed,
      _ => _StepStatus.pending,
    };

    return Container(
      color: Colors.black.withValues(alpha: 0.34),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 48),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                    color: cs.outline,
                    borderRadius: BorderRadius.circular(99)),
              ),
              Container(
                width: 72,
                height: 72,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                        color: AmColors.accent.withValues(alpha: 0.18),
                        blurRadius: 20)
                  ],
                ),
                child: Image.asset('assets/logo/logo_t.png',
                    width: 42, height: 42),
              ),
              Text(
                l10n.feedProcessing,
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _StepRow(
                      label: l10n.feedStepGettingUrl,
                      status: step1Status,
                    ),
                    const SizedBox(height: 12),
                    _StepRow(
                      label: l10n.feedStepUploading,
                      status: step2Status,
                    ),
                    const SizedBox(height: 12),
                    _StepRow(
                      label: l10n.feedStepProcessing,
                      status: step3Status,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _StepStatus { pending, active, completed }

class _StepRow extends StatelessWidget {
  const _StepRow({required this.label, required this.status});
  final String label;
  final _StepStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget leading() {
      switch (status) {
        case _StepStatus.pending:
          return Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: cs.outlineVariant, width: 2),
            ),
          );
        case _StepStatus.active:
          return const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AmColors.accent),
            ),
          );
        case _StepStatus.completed:
          return Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF34A853),
            ),
            child: const Icon(
              Icons.check,
              size: 13,
              color: Colors.white,
            ),
          );
      }
    }

    final textColor = switch (status) {
      _StepStatus.pending => cs.tertiary,
      _StepStatus.active => cs.onSurface,
      _StepStatus.completed => cs.onSurface.withValues(alpha: 0.6),
    };

    final fontWeight = status == _StepStatus.active ? FontWeight.w600 : FontWeight.w500;

    return Row(
      children: [
        leading(),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: fontWeight,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Unified Ingest Bottom Sheet ──────────────────────────────────────────────────

class _UnifiedIngestBottomSheet extends ConsumerStatefulWidget {
  const _UnifiedIngestBottomSheet();

  @override
  ConsumerState<_UnifiedIngestBottomSheet> createState() => _UnifiedIngestBottomSheetState();
}

class _UnifiedIngestBottomSheetState extends ConsumerState<_UnifiedIngestBottomSheet> {
  @override
  Widget build(BuildContext context) {
    ref.listen<IngestState>(ingestProvider, (prev, next) {
      if (next.phase == IngestPhase.idle || next.phase == IngestPhase.knowledgeSuccess) {
        Navigator.of(context).pop();
      }
    });

    final state = ref.watch(ingestProvider);

    return PopScope(
      canPop: false,
      child: state.phase == IngestPhase.idle
          ? const SizedBox.shrink()
          : _buildContent(context, state),
    );
  }

  Widget _buildContent(BuildContext context, IngestState state) {
    final handleClose = () {
      ref.read(ingestProvider.notifier).reset();
    };

    switch (state.phase) {
      case IngestPhase.uploading:
      case IngestPhase.processing:
        return _ProcessingOverlay(
          phase: state.phase,
          statusMessageKey: state.statusMessageKey,
        );
      case IngestPhase.chatting:
        return IngestChatSheet(onClose: handleClose);
      case IngestPhase.success:
        return PolicySuccessSheet(onClose: handleClose);
      case IngestPhase.error:
        return _UnifiedErrorSheet(error: state.error ?? 'Error de procesamiento', onClose: handleClose);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Unified Error Sheet ─────────────────────────────────────────────────────────

class _UnifiedErrorSheet extends StatelessWidget {
  const _UnifiedErrorSheet({required this.error, required this.onClose});
  final String error;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: Colors.black.withValues(alpha: 0.34),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 48),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: cs.error, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error de procesamiento',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                error,
                style: TextStyle(fontSize: 14, color: cs.tertiary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: onClose,
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

// ── Data models ────────────────────────────────────────────────────────────────

class _InputType {
  const _InputType(this.key, this.icon, this.color, this.label, this.sub,
      {this.onTap});

  final String key;
  final IconData icon;
  final Color color;
  final String label;
  final String sub;
  final VoidCallback? onTap;
}

// ── Knowledge base dashboard components ──────────────────────────────────────────

class _KnowledgeDashboardView extends ConsumerWidget {
  const _KnowledgeDashboardView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(knowledgeStatsProvider);
    final searchListAsync = ref.watch(knowledgeListProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AmDimens.screenH, 0, AmDimens.screenH, AmDimens.scrollBottomPad),
      children: [
        const SizedBox(height: AmDimens.gapS),

        // ── Stats Section ────────────────────────────────────────
        AmAnimateIn(
          index: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AmSectionLabel(label: l10n.feedStatsTitle),
              const SizedBox(height: AmDimens.gapXS),
              statsAsync.when(
                loading: () => const AmLoader(),
                error: (_, __) => const SizedBox.shrink(),
                data: (stats) => GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.9,
                  children: [
                    _StatCard(
                      label: l10n.feedStatsPDFs,
                      count: stats['pdf'] ?? 0,
                      icon: Icons.description_outlined,
                      color: AmColors.srcDoc,
                    ),
                    _StatCard(
                      label: l10n.feedStatsImages,
                      count: stats['image'] ?? 0,
                      icon: Icons.image_outlined,
                      color: AmColors.srcImage,
                    ),
                    _StatCard(
                      label: l10n.feedStatsAudios,
                      count: stats['audio'] ?? 0,
                      icon: Icons.graphic_eq,
                      color: AmColors.srcWave,
                    ),
                    _StatCard(
                      label: l10n.feedStatsNotes,
                      count: stats['text'] ?? 0,
                      icon: Icons.edit_note_outlined,
                      color: AmColors.srcNote,
                    ),
                    _StatCard(
                      label: l10n.feedStatsChats,
                      count: stats['chat'] ?? 0,
                      icon: Icons.chat_bubble_outline,
                      color: AmColors.accent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Search Section ────────────────────────────────────────
        AmAnimateIn(
          index: 1,
          child: const _SearchBar(),
        ),

        const SizedBox(height: 20),

        // ── Notes List Section ────────────────────────────────────
        AmAnimateIn(
          index: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AmSectionLabel(label: l10n.feedAllNotesTitle),
              const SizedBox(height: 10),
              searchListAsync.when(
                loading: () => const AmLoader(),
                error: (e, __) => Text(
                  'Error: $e',
                  style: TextStyle(color: cs.error, fontSize: 13),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          l10n.feedSearchNoResults,
                          style: TextStyle(color: cs.tertiary, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: AmDimens.gapS),
                      child: _FeedRow(item: item),
                    )).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = Color.alphaBlend(color.withValues(alpha: 0.08), Colors.white);

    return AmCard(
      noPad: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: cs.tertiary,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends ConsumerStatefulWidget {
  const _SearchBar();

  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  final _ctrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String val) {
    setState(() {});
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(knowledgeSearchQueryProvider.notifier).updateQuery(val);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 22,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: cs.onSurfaceVariant, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _ctrl,
              onChanged: _onChanged,
              style: TextStyle(fontSize: 15, color: cs.onSurface),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: l10n.feedSearchHint,
                hintStyle: TextStyle(color: cs.tertiary),
              ),
            ),
          ),
          if (_ctrl.text.isNotEmpty) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                _ctrl.clear();
                ref.read(knowledgeSearchQueryProvider.notifier).updateQuery('');
                setState(() {});
              },
              child: Icon(Icons.close, color: cs.tertiary, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}
