import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/am_icons.dart';
import '../../../core/theme/app_dimensions.dart';
import '../providers/ingest_provider.dart';
import '../../../l10n/app_localizations.dart';

class TextIngestSheet extends ConsumerStatefulWidget {
  const TextIngestSheet({super.key, required this.sourceType});

  final String sourceType; // 'text' | 'whatsapp'

  @override
  ConsumerState<TextIngestSheet> createState() => _TextIngestSheetState();
}

class _TextIngestSheetState extends ConsumerState<TextIngestSheet> {
  final _ctrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _submitting = true);
    // Capturar el notifier ANTES del pop para evitar uso de ref en widget disposed
    final notifier = ref.read(ingestProvider.notifier);
    Navigator.of(context).pop();
    await Future.delayed(const Duration(milliseconds: 350));
    await notifier.processKnowledgeText(text, widget.sourceType);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isWhatsapp = widget.sourceType == 'whatsapp';
    final srcColor = isWhatsapp ? AmColors.srcWhatsApp : AmColors.srcNote;
    final title =
        isWhatsapp ? l10n.feedWhatsappInputTitle : l10n.feedTextInputTitle;

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
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                      srcColor.withValues(alpha: 0.14),
                      cs.surface,
                    ),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    isWhatsapp ? AmIcons.whatsapp : AmIcons.text,
                    size: 20,
                    color: srcColor,
                  ),
                ),
                const SizedBox(width: AmDimens.gapS),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AmDimens.gapM),
            TextField(
              controller: _ctrl,
              maxLines: 7,
              minLines: 4,
              autofocus: true,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: l10n.feedTextInputHint,
                hintStyle: TextStyle(color: cs.tertiary, fontSize: 14),
                filled: true,
                fillColor: cs.secondaryContainer,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AmDimens.cardRadius - 4),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(AmDimens.gapS),
              ),
            ),
            const SizedBox(height: AmDimens.gapM),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AmColors.accent,
                  foregroundColor: AmColors.onAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AmDimens.cardRadius),
                  ),
                ),
                child: Text(
                  l10n.feedTextInputSubmit,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
