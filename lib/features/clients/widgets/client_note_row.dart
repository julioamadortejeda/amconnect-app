import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/am_icons.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/models/agent_note.dart';
import '../../../l10n/app_localizations.dart';

class ClientNoteRow extends StatefulWidget {
  const ClientNoteRow({super.key, required this.note});

  final AgentNote note;

  @override
  State<ClientNoteRow> createState() => _ClientNoteRowState();
}

class _ClientNoteRowState extends State<ClientNoteRow> {
  bool _expanded = false;
  bool _loadingFile = false;

  bool get _hasFile =>
      widget.note.storagePath != null &&
      (widget.note.sourceType == 'pdf' ||
          widget.note.sourceType == 'document' ||
          widget.note.sourceType == 'image' ||
          widget.note.sourceType == 'audio');

  (Color, IconData) get _typeStyle => (
    switch (widget.note.sourceType) {
      'pdf' || 'document' => AmColors.srcDoc,
      'audio'             => AmColors.srcWave,
      'image'             => AmColors.srcImage,
      _                   => AmColors.srcWhatsApp,
    },
    AmIcons.forSourceType(widget.note.sourceType),
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final (color, icon) = _typeStyle;
    final bg = Color.alphaBlend(color.withValues(alpha: 0.1), cs.surface);
    final hasSummary = widget.note.summary != null && widget.note.summary!.isNotEmpty;

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
              BoxShadow(color: Color(0x0D141E1A), blurRadius: 2, offset: Offset(0, 1)),
              BoxShadow(color: Color(0x0A141E1A), blurRadius: 10, offset: Offset(0, 3)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary — expandable for all note types
                    if (hasSummary) ...[
                      Text(
                        widget.note.summary!,
                        maxLines: _expanded ? null : 2,
                        overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: cs.onSurface, height: 1.4),
                      ),
                      // Full verbatim content only for text notes (not file notes)
                      if (!_hasFile && _expanded) ...[
                        const SizedBox(height: AmDimens.gapXS),
                        Container(height: 1, color: cs.outlineVariant),
                        const SizedBox(height: AmDimens.gapXS),
                        Text(
                          widget.note.content,
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ] else if (!_hasFile)
                      // No summary: show raw content (text notes only)
                      Text(
                        widget.note.content,
                        maxLines: _expanded ? null : 2,
                        overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: cs.onSurface, height: 1.4),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _buildSubtitle(l10n),
                            style: TextStyle(fontSize: 12, color: cs.tertiary),
                          ),
                        ),
                        if (_hasFile)
                          // Absorb tap so opening the file doesn't collapse the card
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openFile() async {
    if (_loadingFile) return;
    setState(() => _loadingFile = true);
    try {
      final signedUrl = await Supabase.instance.client.storage
          .from('policies')
          .createSignedUrl(widget.note.storagePath!, 3600);
      final uri = Uri.parse(signedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // signed URL generation failed — silently ignore
    } finally {
      if (mounted) setState(() => _loadingFile = false);
    }
  }

  String _buildSubtitle(AppLocalizations l10n) {
    final label = switch (widget.note.sourceType) {
      'pdf' || 'document' => l10n.clientsNoteTypePdf,
      'audio'             => l10n.clientsNoteTypeAudio,
      'image'             => l10n.clientsNoteTypeImage,
      'text' || _         => l10n.clientsNoteTypeText,
    };
    final dt = DateTime.tryParse(widget.note.createdAt)?.toLocal();
    if (dt == null) return label;
    return '$label · ${DateFormat.MMMd().format(dt)}';
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
                Icon(Icons.open_in_new_rounded, size: 12, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
    );
  }
}
