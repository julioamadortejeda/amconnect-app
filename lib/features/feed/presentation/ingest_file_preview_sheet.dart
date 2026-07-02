import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/am_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../l10n/app_localizations.dart';

class IngestFilePreviewSheet extends StatelessWidget {
  const IngestFilePreviewSheet({
    super.key,
    required this.file,
    required this.fileName,
    required this.fileSize,
    required this.isImage,
    required this.sourceType,
    required this.onConfirm,
  });

  final File file;
  final String fileName;
  final int? fileSize;
  final bool isImage;
  final String sourceType;
  final VoidCallback onConfirm;

  String _fmtSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final sizeLabel = _fmtSize(fileSize);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(AmDimens.screenH, 14, AmDimens.screenH, 32),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: AmDimens.gapM),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Text(
              l10n.feedPreviewTitle,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
            ),
            const SizedBox(height: AmDimens.gapM),
            if (isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(AmDimens.cardRadius),
                child: Image.file(
                  file,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Color.alphaBlend(AmColors.srcDoc.withValues(alpha: 0.14), cs.surface),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(AmIcons.forSourceType(sourceType), size: 32, color: AmColors.srcDoc),
              ),
            const SizedBox(height: AmDimens.gapM),
            Text(
              fileName,
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: cs.onSurface),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (sizeLabel.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(sizeLabel, style: TextStyle(fontSize: 12.5, color: cs.tertiary)),
            ],
            const SizedBox(height: AmDimens.gapL),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: cs.outlineVariant),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      l10n.commonCancel,
                      style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onConfirm();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AmColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      l10n.feedPreviewConfirm,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
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
