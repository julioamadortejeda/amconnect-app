import 'dart:io';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return Scaffold(
      appBar: AmTopBar(
        title: l10n.feedSubtitle,
        subtitle: l10n.feedTitle,
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
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
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.1,
                        children: feedTypes
                            .map((t) => _TypeCard(t: t))
                            .toList(),
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
                              const SizedBox(height: 10),
                              AmCard(
                                noPad: true,
                                child: Column(
                                  children: items.asMap().entries.map((e) {
                                    final isLast = e.key == items.length - 1;
                                    return _FeedRow(
                                        item: e.value, isLast: isLast);
                                  }).toList(),
                                ),
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
            ),

          ],
        ),
      ),
    );
  }
}

// ── Type card ──────────────────────────────────────────────────────────────────

class _TypeCard extends StatelessWidget {
  const _TypeCard({required this.t});

  final _InputType t;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = Color.alphaBlend(t.color.withValues(alpha: 0.14), Colors.white);

    return AmCard(
      onTap: t.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(13)),
            child: Icon(t.icon, size: 22, color: t.color),
          ),
          const SizedBox(height: 10),
          Text(t.label,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface)),
          const SizedBox(height: 3),
          Flexible(
            child: Text(t.sub,
                style: TextStyle(
                    fontSize: 12, color: cs.tertiary, height: 1.35),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ── Feed row ───────────────────────────────────────────────────────────────────

class _FeedRow extends StatelessWidget {
  const _FeedRow({required this.item, required this.isLast});

  final FeedItem item;
  final bool isLast;

  static (IconData, Color, String) _typeInfo(String sourceType) =>
      switch (sourceType) {
        'pdf' || 'doc' => (
            Icons.description_outlined,
            AmColors.srcDoc,
            'PDF'
          ),
        'audio' || 'wave' => (
            Icons.graphic_eq,
            AmColors.srcWave,
            'Audio'
          ),
        'image' || 'photo' => (
            Icons.image_outlined,
            AmColors.srcImage,
            'Imagen'
          ),
        _ => (Icons.edit_note_outlined, AmColors.srcNote, 'Nota'),
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (icon, color, typeLabel) = _typeInfo(item.sourceType);
    final bg = Color.alphaBlend(color.withValues(alpha: 0.14), Colors.white);
    final name = item.fileName ?? 'Documento';
    final date = _relativeDate(item.createdAt);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 13, 18, 13),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(bottom: BorderSide(color: cs.outlineVariant))),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  [
                    if (item.contactName != null) item.contactName!,
                    date,
                  ].join(' · '),
                  style: TextStyle(fontSize: 12, color: cs.tertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Color.alphaBlend(color.withValues(alpha: 0.12), Colors.white),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(typeLabel,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color)),
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
