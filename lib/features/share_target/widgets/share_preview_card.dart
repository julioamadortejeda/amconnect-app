import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_card.dart';
import '../../../l10n/app_localizations.dart';

class SharePreviewCard extends StatelessWidget {
  const SharePreviewCard({
    super.key,
    this.files,
    this.text,
  });

  final List<SharedFile>? files;
  final String? text;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final hasFiles = files != null && files!.isNotEmpty;
    final hasText = text != null && text!.trim().isNotEmpty;

    return AmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.shareTargetPreview,
            style: theme.textTheme.titleSmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AmDimens.gapM),

          if (hasFiles) ...[
            ...files!.map((file) {
              final path = file.value ?? '';
              final isImage = file.type == SharedMediaType.IMAGE ||
                  path.endsWith('.png') ||
                  path.endsWith('.jpg') ||
                  path.endsWith('.jpeg');

              return Padding(
                padding: const EdgeInsets.only(bottom: AmDimens.gapS),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AmDimens.gapS),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: isImage && path.isNotEmpty
                          ? Image.file(
                              File(path),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: FaIcon(
                                  FontAwesomeIcons.fileLines,
                                  color: cs.primary,
                                ),
                              ),
                            )
                          : Center(
                              child: FaIcon(
                                path.endsWith('.pdf')
                                    ? FontAwesomeIcons.filePdf
                                    : FontAwesomeIcons.fileLines,
                                color: cs.primary,
                              ),
                            ),
                    ),
                    const SizedBox(width: AmDimens.gapM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            path.split('/').last,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            file.type.name.toUpperCase(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          if (hasText) ...[
            Container(
              padding: const EdgeInsets.all(AmDimens.gapM),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AmDimens.gapS),
              ),
              child: Text(
                text!,
                style: theme.textTheme.bodyMedium,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
