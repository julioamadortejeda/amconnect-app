import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/am_fade_switcher.dart';
import '../../../core/widgets/am_icon_btn.dart';
import '../../../l10n/app_localizations.dart';
import 'reactive_voice_waveform.dart';

/// Composer de modo texto. A la derecha hay SIEMPRE dos botones, nunca cuatro:
/// el gris cambia entre dictar y detener, y el azul es la acción principal del
/// momento — abrir la voz Live cuando no hay nada escrito, enviar cuando sí.
///
/// | Estado    | izq  | centro | gris | azul   |
/// |-----------|------|--------|------|--------|
/// | vacío     | clip | campo  | mic  | Live   |
/// | con texto | clip | campo  | mic  | enviar |
/// | dictando  | clip | ondas  | stop | enviar |
class AssistantComposer extends StatelessWidget {
  const AssistantComposer({
    super.key,
    required this.controller,
    required this.hasText,
    required this.isLoading,
    required this.isDictating,
    required this.dictationLevel,
    required this.onChanged,
    required this.onSend,
    required this.onAttach,
    required this.onVoiceToggle,
    required this.onDictateStart,
    required this.onDictateStop,
    required this.onDictateStopAndSend,
  });

  final TextEditingController controller;
  final bool hasText;
  final bool isLoading;
  final bool isDictating;

  /// Nivel de voz 0..1 del dictado — mueve las barras del centro.
  final ValueListenable<double> dictationLevel;

  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final VoidCallback onVoiceToggle;
  final VoidCallback onDictateStart;

  /// Termina el dictado y deja el texto en el campo para revisarlo.
  final VoidCallback onDictateStop;

  /// Termina el dictado y envía de una vez.
  final VoidCallback onDictateStopAndSend;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    // Enviar cuando ya hay algo que mandar (escrito o dictándose); abrir la
    // voz Live solo desde el campo vacío.
    final primaryIsSend = hasText || isDictating;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AmShadows.card,
      ),
      child: Row(
        children: [
          AmIconBtn(
            icon: Icons.attach_file_rounded,
            tone: AmIconBtnTone.ghost,
            onTap: isDictating ? null : onAttach,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: isDictating
                ? SizedBox(
                    height: 32,
                    child: Center(
                      child: ReactiveVoiceWaveform(
                        level: dictationLevel,
                        color: cs.onSurfaceVariant,
                        maxHeight: 22,
                      ),
                    ),
                  )
                : TextField(
                    controller: controller,
                    onChanged: onChanged,
                    onSubmitted: (_) => onSend(),
                    enabled: !isLoading,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
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
          const SizedBox(width: 6),
          AmIconBtn(
            icon: isDictating ? Icons.stop_rounded : Icons.mic_none_rounded,
            tone: AmIconBtnTone.sunken,
            onTap: isLoading
                ? null
                : (isDictating ? onDictateStop : onDictateStart),
          ),
          const SizedBox(width: 6),
          AmFadeSwitcher(
            child: AmIconBtn(
              key: ValueKey(primaryIsSend),
              icon: primaryIsSend
                  ? Icons.arrow_upward_rounded
                  : Icons.graphic_eq_rounded,
              tone: AmIconBtnTone.accent,
              onTap: isLoading
                  ? null
                  : isDictating
                      ? onDictateStopAndSend
                      : (hasText ? onSend : onVoiceToggle),
            ),
          ),
        ],
      ),
    );
  }
}
