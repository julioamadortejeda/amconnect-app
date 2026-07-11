import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_translator.dart';
import '../../../l10n/app_localizations.dart';
import '../../chat/widgets/voice_waveform_bars.dart';
import '../providers/assistant_provider.dart';

/// Barra inferior en modo voz — reemplaza el composer de texto. Onda + estado
/// + botón de cerrar, dentro de un pill de acento fijo (mismo azul de marca
/// que el resto de la app) para que las barras blancas de [VoiceWaveformBars]
/// siempre se vean bien, sin necesidad de oscurecer el resto de la pantalla.
class AssistantVoiceBar extends StatelessWidget {
  const AssistantVoiceBar({
    super.key,
    required this.status,
    required this.activeSkill,
    required this.error,
    required this.onClose,
  });

  final VoiceStatus status;
  final String? activeSkill;
  final String? error;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isActive =
        status == VoiceStatus.listening || status == VoiceStatus.modelSpeaking;

    final label = error != null
        ? context.translateError(error)
        : activeSkill != null
            ? l10n.voiceChatSkillActive
            : switch (status) {
                VoiceStatus.connecting => l10n.voiceChatConnecting,
                VoiceStatus.listening => l10n.voiceChatListening,
                VoiceStatus.modelSpeaking => l10n.voiceChatModelSpeaking,
                VoiceStatus.error => l10n.voiceChatError,
              };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AmColors.accent,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
              color: AmColors.accent.withValues(alpha: 0.32),
              blurRadius: 18,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                final Set<Key> seenKeys = {};
                if (currentChild?.key != null) {
                  seenKeys.add(currentChild!.key!);
                }
                final List<Widget> safePrevious = [];
                for (final child in previousChildren) {
                  final key = child.key;
                  if (key == null || !seenKeys.contains(key)) {
                    if (key != null) seenKeys.add(key);
                    safePrevious.add(child);
                  }
                }
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    ...safePrevious,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              child: Text(
                label,
                key: ValueKey(label),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: error != null
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ),
          ),
          if (isActive) ...[
            const SizedBox(width: 12),
            const VoiceWaveformBars(maxHeight: 24),
          ],
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
