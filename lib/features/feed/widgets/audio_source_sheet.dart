import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/am_icons.dart';
import '../../../core/theme/am_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_card.dart';
import '../../../l10n/app_localizations.dart';
import '../presentation/ingest_file_preview_sheet.dart';
import '../providers/ingest_provider.dart';
import 'audio_recorder_sheet.dart';

/// Elegir entre subir un archivo de audio existente o grabar uno nuevo —
/// se abre al tocar la tile "Audio / nota voz" del picker de ingesta.
///
/// Recibe datos planos (no callbacks capturados del picker que la abrió):
/// ese picker ya se cerró (pop) antes de mostrar este sheet, así que
/// cualquier closure atada a su State quedaría huérfana en cuanto el
/// usuario tocara una opción — cada acción usa el `context`/`ref` propios
/// de este widget, que sí siguen vivos al momento del tap.
class AudioSourceSheet extends ConsumerStatefulWidget {
  const AudioSourceSheet({
    super.key,
    this.contactId,
    this.policyId,
    this.reminderId,
    this.makeGeneral = false,
  });

  final String? contactId;
  final String? policyId;
  final String? reminderId;
  final bool makeGeneral;

  @override
  ConsumerState<AudioSourceSheet> createState() => _AudioSourceSheetState();
}

class _AudioSourceSheetState extends ConsumerState<AudioSourceSheet> {
  bool _isPicking = false;

  Future<void> _pickFile() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['mp3', 'wav', 'm4a', 'aac'],
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('file picker timeout'),
      );
      if (result == null || !mounted) return;
      final path = result.files.single.path;
      if (path == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.errFilePathUnavailable),
            backgroundColor: context.am.amber,
            behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }
      final file = File(path);
      final fileName = result.files.single.name;
      final fileSize = result.files.single.size;
      final contactId = widget.contactId;
      final policyId = widget.policyId;
      final reminderId = widget.reminderId;
      final makeGeneral = widget.makeGeneral;
      final notifier = ref.read(ingestProvider.notifier);

      if (mounted) Navigator.of(context).pop();

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
          isImage: false,
          sourceType: 'audio',
          onConfirm: () => notifier.processKnowledgeFile(
            file,
            fileName,
            contactId: contactId,
            policyId: policyId,
            reminderId: reminderId,
            makeGeneral: makeGeneral,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e is TimeoutException
              ? l10n.errFilePickerTimeout
              : l10n.errFilePickerOpen),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _openRecorder() {
    Navigator.of(context).pop();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AudioRecorderSheet(
        contactId: widget.contactId,
        policyId: widget.policyId,
        reminderId: widget.reminderId,
        makeGeneral: widget.makeGeneral,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            AmDimens.screenH, 14, AmDimens.screenH, 32),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
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
            Text(
              l10n.feedAudioSourceTitle,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface),
            ),
            const SizedBox(height: AmDimens.gapM),
            Opacity(
              opacity: _isPicking ? 0.5 : 1.0,
              child: AmCard(
                onTap: _isPicking ? null : _pickFile,
                child: _SourceRow(
                  icon: AmIcons.audio,
                  color: AmColors.srcWave,
                  label: l10n.feedAudioSourceFile,
                  sub: l10n.feedAudioSourceFileDesc,
                ),
              ),
            ),
            const SizedBox(height: 10),
            AmCard(
              onTap: _isPicking ? null : _openRecorder,
              child: _SourceRow(
                icon: Icons.mic_none_outlined,
                color: AmColors.srcWave,
                label: l10n.feedAudioSourceRecord,
                sub: l10n.feedAudioSourceRecordDesc,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.sub,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Color.alphaBlend(color.withValues(alpha: 0.14), cs.surface),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, size: 22, color: color),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface)),
              const SizedBox(height: 2),
              Text(sub, style: TextStyle(fontSize: 12.5, color: cs.tertiary)),
            ],
          ),
        ),
        Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 18),
      ],
    );
  }
}
