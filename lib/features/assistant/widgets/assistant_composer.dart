import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/am_icon_btn.dart';
import '../../../l10n/app_localizations.dart';

/// Composer de modo texto — TextField + adjuntar + toggle a voz + enviar.
/// Sin botón de "+" ni de mic-solo-dictado adicionales: el único control
/// nuevo respecto al chat de texto de siempre es [onVoiceToggle].
class AssistantComposer extends StatelessWidget {
  const AssistantComposer({
    super.key,
    required this.controller,
    required this.hasText,
    required this.isLoading,
    required this.onChanged,
    required this.onSend,
    required this.onAttach,
    required this.onVoiceToggle,
  });

  final TextEditingController controller;
  final bool hasText;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final VoidCallback onVoiceToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AmShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onSubmitted: (_) => onSend(),
              enabled: !isLoading,
              minLines: 1,
              maxLines: 4,
              style: TextStyle(fontSize: 15, color: cs.onSurface),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                hintText: l10n.chatInputHint,
                hintStyle: TextStyle(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                    fontSize: 15),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AmIconBtn(
            icon: Icons.attach_file_rounded,
            tone: AmIconBtnTone.sunken,
            onTap: onAttach,
          ),
          const SizedBox(width: 6),
          AmIconBtn(
            icon: Icons.graphic_eq_rounded,
            tone: AmIconBtnTone.accent,
            onTap: onVoiceToggle,
          ),
          const SizedBox(width: 6),
          AnimatedScale(
            scale: hasText ? 1.0 : 0.85,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: AmIconBtn(
              icon: Icons.arrow_upward_rounded,
              tone: hasText ? AmIconBtnTone.accent : AmIconBtnTone.sunken,
              onTap: (isLoading || !hasText) ? null : onSend,
            ),
          ),
        ],
      ),
    );
  }
}
