import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/am_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_card.dart';
import '../../../core/widgets/am_section_label.dart';
import '../../../l10n/app_localizations.dart';
import '../presentation/text_ingest_sheet.dart';
import '../providers/ingest_provider.dart';

class IngestTypePicker extends ConsumerStatefulWidget {
  const IngestTypePicker({super.key, this.contactId, this.policyId});

  final String? contactId;
  final String? policyId;

  static Future<void> show(
    BuildContext context, {
    String? contactId,
    String? policyId,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => IngestTypePicker(contactId: contactId, policyId: policyId),
    );
  }

  @override
  ConsumerState<IngestTypePicker> createState() => _IngestTypePickerState();
}

class _IngestTypePickerState extends ConsumerState<IngestTypePicker> {
  bool _isPicking = false;
  bool _makeGeneral = false;

  Future<void> _safePick(Future<void> Function() action) async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      await action().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('La selección tardó demasiado.'),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is TimeoutException ? (e.message ?? 'Timeout') : 'Error: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _openText(String sourceType) {
    Navigator.of(context).pop();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => TextIngestSheet(
        sourceType: sourceType,
        contactId: widget.contactId,
        policyId: widget.policyId,
        makeGeneral: _makeGeneral,
      ),
    );
  }

  Future<void> _pickFile({
    required FileType type,
    List<String>? extensions,
    required bool isPolicy,
  }) =>
      _safePick(() async {
        final result = await FilePicker.pickFiles(
          type: type,
          allowedExtensions: extensions,
        );
        if (result == null || !mounted) return;
        final path = result.files.single.path;
        if (path == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('No se pudo obtener la ruta del archivo.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ));
          }
          return;
        }
        final notifier = ref.read(ingestProvider.notifier);
        if (mounted) Navigator.of(context).pop();
        if (isPolicy) {
          await notifier.processPolicy(
            File(path),
            result.files.single.name,
            contactId: widget.contactId,
          );
        } else {
          await notifier.processKnowledgeFile(
            File(path),
            result.files.single.name,
            contactId: widget.contactId,
            policyId: widget.policyId,
            makeGeneral: _makeGeneral,
          );
        }
      });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final types = [
      _PickerType(
        icon: AmIcons.pdf,
        color: AmColors.srcDoc,
        label: l10n.feedTypePolicyPdf,
        sub: l10n.feedTypePolicyPdfDesc,
        onTap: () => _pickFile(
          type: FileType.custom,
          extensions: ['pdf'],
          isPolicy: true,
        ),
      ),
      _PickerType(
        icon: AmIcons.camera,
        color: AmColors.srcImage,
        label: l10n.feedTypePolicyPhoto,
        sub: l10n.feedTypePolicyPhotoDesc,
        onTap: () => _pickFile(type: FileType.image, isPolicy: true),
      ),
      _PickerType(
        icon: AmIcons.audio,
        color: AmColors.srcWave,
        label: l10n.feedTypeAudio,
        sub: l10n.feedTypeAudioDesc,
        onTap: () => _pickFile(
          type: FileType.custom,
          extensions: ['mp3', 'm4a', 'wav', 'aac', 'ogg'],
          isPolicy: false,
        ),
      ),
      _PickerType(
        icon: AmIcons.text,
        color: AmColors.srcNote,
        label: l10n.feedTypeText,
        sub: l10n.feedTypeTextDesc,
        onTap: () => _openText('text'),
      ),
      _PickerType(
        icon: AmIcons.image,
        color: AmColors.srcImage,
        label: l10n.feedTypeKnowledgeImage,
        sub: l10n.feedTypeKnowledgeImageDesc,
        onTap: () => _pickFile(type: FileType.image, isPolicy: false),
      ),
      _PickerType(
        icon: AmIcons.document,
        color: AmColors.srcDoc,
        label: l10n.feedTypeDocument,
        sub: l10n.feedTypeDocumentDesc,
        onTap: () => _pickFile(
          type: FileType.custom,
          extensions: ['pdf'],
          isPolicy: false,
        ),
      ),
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            AmDimens.screenH, 14, AmDimens.screenH, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: AmDimens.gapM),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            AmSectionLabel(label: l10n.feedQuestion),
            if (widget.contactId != null) ...[
              const SizedBox(height: AmDimens.gapS),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Hacer conocimiento general',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'El archivo estará disponible de forma global para la IA',
                  style: TextStyle(fontSize: 12),
                ),
                value: _makeGeneral,
                onChanged: (val) => setState(() => _makeGeneral = val),
              ),
            ],
            const SizedBox(height: AmDimens.gapXS),
            LayoutBuilder(
              builder: (context, constraints) {
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.95,
                  children: types
                      .map((t) => _PickerCard(t: t, disabled: _isPicking))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 10),
            AmCard(
              onTap: _isPicking ? null : () => _openText('whatsapp'),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color.alphaBlend(
                          AmColors.srcWhatsApp.withValues(alpha: 0.14),
                          cs.surface),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(AmIcons.whatsapp,
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
                            style:
                                TextStyle(fontSize: 12.5, color: cs.tertiary)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: cs.onSurfaceVariant, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerCard extends StatelessWidget {
  const _PickerCard({required this.t, required this.disabled});

  final _PickerType t;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = Color.alphaBlend(t.color.withValues(alpha: 0.14), Colors.white);

    return AmCard(
      onTap: disabled ? null : t.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(t.icon, size: 18, color: t.color),
          ),
          const SizedBox(height: 7),
          Text(t.label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface)),
          const SizedBox(height: 3),
          Flexible(
            child: Text(t.sub,
                style: TextStyle(
                    fontSize: 11, color: cs.tertiary, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _PickerType {
  const _PickerType({
    required this.icon,
    required this.color,
    required this.label,
    required this.sub,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String sub;
  final VoidCallback onTap;
}
