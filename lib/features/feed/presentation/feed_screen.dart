import 'dart:io';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/am_theme.dart';
import '../../../core/theme/am_icons.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/error_translator.dart';
import '../../../core/widgets/am_badge.dart';
import '../../../core/widgets/am_card.dart';
import '../../../core/widgets/am_keyboard_dismiss.dart';
import '../../../core/widgets/am_loader.dart';
import '../../../core/widgets/am_section_label.dart';
import '../../../core/widgets/am_stagger.dart';
import '../../../core/widgets/am_top_bar.dart';
import '../data/feed_input_type.dart';
import '../providers/ingest_provider.dart';
import '../providers/knowledge_dashboard_provider.dart';
import '../../clients/providers/clients_provider.dart';
import '../../home/providers/home_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/audio_source_sheet.dart';
import '../widgets/feed_row.dart';
import '../widgets/feed_type_card.dart';
import '../widgets/knowledge_dashboard_view.dart';
import 'ingest_file_preview_sheet.dart';
import 'text_ingest_sheet.dart';

// ── Screen ─────────────────────────────────────────────────────────────────────

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  bool _isPickingFile = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(knowledgeListProvider.notifier).loadMore();
    }
  }

  Future<void> _safePick(Future<void> Function() action) async {
    if (_isPickingFile) return;
    setState(() => _isPickingFile = true);
    try {
      await action().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException(null),
      );
    } catch (e) {
      debugPrint('Error picking file: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is TimeoutException
                ? l10n.errFilePickerTimeout
                : l10n.errFilePickerOpen),
            backgroundColor: Theme.of(context).colorScheme.error,
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

  Future<void> _pickAndPreview({
    required FileType type,
    List<String>? extensions,
    required bool isPolicy,
    required String sourceType,
  }) =>
      _safePick(() async {
        final result = await FilePicker.pickFiles(
          type: type,
          allowedExtensions: extensions,
        );
        if (result == null) return;
        final path = result.files.single.path;
        if (path == null) {
          _showNullPathAlert();
          return;
        }
        final file = File(path);
        final fileName = result.files.single.name;
        final fileSize = result.files.single.size;
        final isImage = type == FileType.image;
        final notifier = ref.read(ingestProvider.notifier);

        if (!mounted) return;
        showModalBottomSheet(
          context: context,
          useRootNavigator: true,
          isScrollControlled: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => IngestFilePreviewSheet(
            file: file,
            fileName: fileName,
            fileSize: fileSize,
            isImage: isImage,
            sourceType: sourceType,
            onConfirm: () {
              if (isPolicy) {
                notifier.processPolicy(file, fileName);
              } else {
                notifier.processKnowledgeFile(file, fileName);
              }
            },
          ),
        );
      });

  Future<void> _pickPolicyPdf() => _pickAndPreview(
      type: FileType.custom,
      extensions: ['pdf'],
      isPolicy: true,
      sourceType: 'pdf');

  Future<void> _pickPolicyImage() => _pickAndPreview(
      type: FileType.image, isPolicy: true, sourceType: 'image');

  Future<void> _pickKnowledgeImage() => _pickAndPreview(
      type: FileType.image, isPolicy: false, sourceType: 'image');

  void _openAudioSource() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AudioSourceSheet(),
    );
  }

  Future<void> _pickKnowledgeDocument() => _pickAndPreview(
      type: FileType.custom,
      extensions: ['pdf'],
      isPolicy: false,
      sourceType: 'pdf');

  void _showNullPathAlert() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.errFilePathUnavailable),
          backgroundColor: context.am.amber,
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
    ref.invalidate(knowledgeListProvider);
    ref.invalidate(knowledgeStatsProvider);
    ref.invalidate(clientsProvider);
    ref.invalidate(policiesProvider);
    ref.invalidate(policiesCountProvider);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final ingest = ref.watch(ingestProvider);
    final recentAsync = ref.watch(knowledgeListProvider);

    final feedTypes = [
      FeedInputType('policyPdf', AmIcons.pdf, AmColors.srcDoc,
          l10n.feedTypePolicyPdf, l10n.feedTypePolicyPdfDesc,
          onTap: _pickPolicyPdf),
      FeedInputType('policyPhoto', AmIcons.camera, AmColors.srcImage,
          l10n.feedTypePolicyPhoto, l10n.feedTypePolicyPhotoDesc,
          onTap: _pickPolicyImage),
      FeedInputType('audio', AmIcons.audio, AmColors.srcWave,
          l10n.feedTypeAudio, l10n.feedTypeAudioDesc,
          onTap: _openAudioSource),
      FeedInputType('text', AmIcons.text, AmColors.srcNote, l10n.feedTypeText,
          l10n.feedTypeTextDesc,
          onTap: () => _openTextInput('text')),
      FeedInputType('image', AmIcons.image, AmColors.srcImage,
          l10n.feedTypeKnowledgeImage, l10n.feedTypeKnowledgeImageDesc,
          onTap: _pickKnowledgeImage),
      FeedInputType('document', AmIcons.document, AmColors.srcDoc,
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
        child: AmKeyboardDismiss(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AmDimens.screenH, 12, AmDimens.screenH, 4),
                child: CupertinoSlidingSegmentedControl<FeedViewMode>(
                  groupValue: viewMode,
                  children: {
                    FeedViewMode.knowledge: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
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
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(AmDimens.screenH, 0,
                            AmDimens.screenH, AmDimens.scrollBottomPad),
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
                                    final cols =
                                        constraints.maxWidth < 340 ? 2 : 3;
                                    return GridView.count(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      crossAxisCount: cols,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      childAspectRatio: cols == 3 ? 0.95 : 1.1,
                                      children: feedTypes
                                          .map((t) => FeedTypeCard(
                                              t: t, compact: cols == 3))
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
                                          AmColors.srcWhatsApp
                                              .withValues(alpha: 0.14),
                                          Colors.white),
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: const Icon(AmIcons.whatsapp,
                                        size: 24, color: AmColors.srcWhatsApp),
                                  ),
                                  const SizedBox(width: 13),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(l10n.feedTypeWhatsapp,
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: cs.onSurface)),
                                        const SizedBox(height: 2),
                                        Text(l10n.feedTypeWhatsappDesc,
                                            style: TextStyle(
                                                fontSize: 12.5,
                                                color: cs.tertiary)),
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
                                  AmSectionLabel(
                                      label: l10n.feedRecentlyUploaded),
                                  const SizedBox(height: 10),
                                  const AmLoader(),
                                ],
                              ),
                              error: (_, __) => const SizedBox.shrink(),
                              data: (listState) => listState.items.isEmpty
                                  ? const SizedBox.shrink()
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AmSectionLabel(
                                          label: l10n.feedRecentlyUploaded,
                                          trailing: AmBadge(
                                              label:
                                                  '${listState.items.length}',
                                              tone: AmBadgeTone.accent),
                                        ),
                                        Column(
                                          children: listState.items
                                              .map((item) => Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom:
                                                                AmDimens.gapS),
                                                    child: FeedRow(item: item),
                                                  ))
                                              .toList(),
                                        ),
                                        if (listState.isLoadingMore)
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 16),
                                            child: AmLoader(),
                                          ),
                                      ],
                                    ),
                            ),
                          ),

                          // ── Error state ──────────────────────────────────────────
                          if (ingest.phase == IngestPhase.error &&
                              ingest.error != null)
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
                                  Icon(Icons.error_outline,
                                      color: cs.error, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: Text(
                                          context.translateError(ingest.error),
                                          style: TextStyle(
                                              fontSize: 13.5,
                                              color: cs.error))),
                                  TextButton(
                                    onPressed: _handleClose,
                                    child: Text(l10n.commonClose,
                                        style: TextStyle(
                                            color: cs.error, fontSize: 13)),
                                  ),
                                ]),
                              ),
                            ),
                        ],
                      )
                    else
                      const KnowledgeDashboardView(),
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
