import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_dimensions.dart';
import '../providers/clients_provider.dart';
import '../../../l10n/app_localizations.dart';

class ClientNoteRow extends StatelessWidget {
  const ClientNoteRow({super.key, required this.note});

  final AgentNote note;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (color, icon) = switch (note.sourceType) {
      'pdf' || 'document' => (const Color(0xFFD8453F), Icons.article_outlined),
      'audio'             => (const Color(0xFFB9791A), Icons.volume_up_outlined),
      'image'             => (const Color(0xFF007AC0), Icons.image_outlined),
      'text' || _         => (const Color(0xFF0E7C42), Icons.chat_bubble_outline),
    };

    final bg = Color.alphaBlend(color.withValues(alpha: 0.1), cs.surface);

    return Container(
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
                Text(
                  note.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurface,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _buildSubtitle(AppLocalizations.of(context)!),
                  style: TextStyle(fontSize: 12, color: cs.tertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildSubtitle(AppLocalizations l10n) {
    final label = switch (note.sourceType) {
      'pdf' || 'document' => l10n.clientsNoteTypePdf,
      'audio'             => l10n.clientsNoteTypeAudio,
      'image'             => l10n.clientsNoteTypeImage,
      'text' || _         => l10n.clientsNoteTypeText,
    };
    final dt = DateTime.tryParse(note.createdAt);
    if (dt == null) return label;
    return '$label · ${DateFormat.MMMd().format(dt)}';
  }
}
