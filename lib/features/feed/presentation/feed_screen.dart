import 'dart:io';
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
import 'policy_success_sheet.dart';

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
  Future<void> _pickAndProcessPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.single.path == null) return;
    final file = File(result.files.single.path!);
    final fileName = result.files.single.name;
    await ref.read(ingestProvider.notifier).process(file, fileName);
  }

  void _handleClose() {
    ref.read(ingestProvider.notifier).reset();
    ref.invalidate(recentFeedProvider);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final ingest = ref.watch(ingestProvider);
    final recentAsync = ref.watch(recentFeedProvider);

    final feedTypes = [
      _InputType('doc', Icons.description_outlined, AmColors.srcDoc,
          l10n.feedTypePolicyPdf, l10n.feedTypePolicyPdfDesc,
          available: true),
      _InputType('image', Icons.image_outlined, AmColors.srcImage,
          l10n.feedTypePolicyPhoto, l10n.feedTypePolicyPhotoDesc),
      _InputType('wave', Icons.graphic_eq, AmColors.srcWave,
          l10n.feedTypeAudio, l10n.feedTypeAudioDesc),
      _InputType('note', Icons.edit_note_outlined, AmColors.srcNote,
          l10n.feedTypeText, l10n.feedTypeTextDesc),
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
                            .map((t) => _TypeCard(
                                  t: t,
                                  onTap: t.available ? _pickAndProcessPdf : () {},
                                ))
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
                    onTap: () {},
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

            if (ingest.phase == IngestPhase.uploading ||
                ingest.phase == IngestPhase.processing)
              _ProcessingOverlay(phase: ingest.phase),
            if (ingest.phase == IngestPhase.chatting)
              IngestChatSheet(onClose: _handleClose),
            if (ingest.phase == IngestPhase.success)
              PolicySuccessSheet(onClose: _handleClose),
          ],
        ),
      ),
    );
  }
}

// ── Type card ──────────────────────────────────────────────────────────────────

class _TypeCard extends StatelessWidget {
  const _TypeCard({required this.t, required this.onTap});

  final _InputType t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = Color.alphaBlend(t.color.withValues(alpha: 0.14), Colors.white);

    return Stack(
      children: [
        AmCard(
          onTap: t.available ? onTap : null,
          child: Opacity(
            opacity: t.available ? 1.0 : 0.55,
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
          ),
        ),
        if (!t.available)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text('Pronto',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant)),
            ),
          ),
      ],
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
  const _ProcessingOverlay({required this.phase});

  final IngestPhase phase;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isUploading = phase == IngestPhase.uploading;

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
                width: 80,
                height: 80,
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
                    width: 46, height: 46),
              ),
              Text(
                isUploading ? l10n.feedUploading : l10n.feedProcessing,
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface),
              ),
              const SizedBox(height: 6),
              Text(
                isUploading
                    ? l10n.feedUploadingDesc
                    : l10n.feedProcessingDesc,
                style: TextStyle(fontSize: 13.5, color: cs.tertiary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                    strokeWidth: 3, color: AmColors.accent),
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
      {this.available = false});

  final String key;
  final IconData icon;
  final Color color;
  final String label;
  final String sub;
  final bool available;
}
