import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/am_fade_switcher.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/assistant_provider.dart';
import 'model_speaking_pulse.dart';
import 'reactive_voice_waveform.dart';
import 'thinking_pulse.dart';
import 'voice_mic_indicator.dart';

/// Barra inferior en modo voz — reemplaza el composer de texto. Animación +
/// estado + botón de cerrar, dentro de un pill de acento fijo (mismo azul de
/// marca que el resto de la app). Tres animaciones distintas a propósito:
/// [ThinkingPulse] mientras hay una skill en vuelo (tool call — casi siempre
/// ocurre con status todavía `listening`, por eso va primero en la
/// prioridad), [ReactiveVoiceWaveform] (barras) cuando habla el usuario, y
/// [ModelSpeakingPulse] (blob reactivo a audio real) cuando responde el
/// modelo — para que de un vistazo quede claro qué está pasando, sin
/// depender solo del texto.
class AssistantVoiceBar extends StatelessWidget {
  const AssistantVoiceBar({
    super.key,
    required this.status,
    required this.activeSkill,
    required this.error,
    required this.onClose,
    required this.onOutput,
    required this.micLevel,
    required this.modelLevel,
  });

  final VoiceStatus status;
  final String? activeSkill;
  final String? error;
  final VoidCallback onClose;

  /// Abre el selector de salida de audio (bocina / audífonos).
  final VoidCallback onOutput;

  /// Nivel de audio en vivo (0..1) del mic y de la salida del modelo — ver
  /// [GeminiVoiceEngine.micLevel]/[modelLevel].
  final ValueListenable<double> micLevel;
  final ValueListenable<double> modelLevel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // El detalle del error (y el tap para abrir Ajustes si aplica) ya se
    // muestra en el banner rojo arriba del composer — aquí solo un status
    // corto, igual que el resto de los estados.
    final label = error != null
        ? l10n.voiceChatError
        : activeSkill != null
            ? l10n.voiceChatSkillActive
            : switch (status) {
                VoiceStatus.connecting => l10n.voiceChatConnecting,
                VoiceStatus.listening => l10n.voiceChatListening,
                VoiceStatus.modelSpeaking => l10n.voiceChatModelSpeaking,
                VoiceStatus.error => l10n.voiceChatError,
              };

    // Azul SOLO cuando el usuario puede hablar (escuchando, sin skill en
    // vuelo ni error) — gris el resto del tiempo: conectando, IA
    // respondiendo, o resolviendo una skill. Así el color solo, sin leer el
    // texto, ya dice si es tu turno.
    final canUserSpeak =
        error == null && activeSkill == null && status == VoiceStatus.listening;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: canUserSpeak ? AmColors.accent : AmColors.accentMuted,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          // Deja explícito cuándo el usuario aún NO puede hablar (conectando:
          // ícono atenuado + anillo pulsante) y el instante exacto en que ya
          // sí (rebote + destello + haptic) — antes solo cambiaba el texto y
          // la transición pasaba desapercibida.
          VoiceMicIndicator(status: status),
          const SizedBox(width: 10),
          Expanded(
            child: AmFadeSwitcher(
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
          if (activeSkill != null) ...[
            const SizedBox(width: 12),
            const ThinkingPulse(color: Colors.white, size: 18),
          ] else if (status == VoiceStatus.listening) ...[
            const SizedBox(width: 12),
            ReactiveVoiceWaveform(level: micLevel, color: Colors.white, maxHeight: 24),
          ] else if (status == VoiceStatus.modelSpeaking) ...[
            const SizedBox(width: 12),
            ModelSpeakingPulse(level: modelLevel, size: 22),
          ],
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onOutput,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.volume_up_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
