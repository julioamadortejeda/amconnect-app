import 'package:flutter/material.dart';
import '../../../core/theme/am_theme.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/skill_l10n.dart';
import '../../../core/widgets/am_ai_backend_badge.dart';
import '../../../core/widgets/am_fade_switcher.dart';
import '../../../core/widgets/am_icon_btn.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/assistant_provider.dart';

/// Header de la pantalla única de asistente. El indicador de estado (punto +
/// label) cambia de "en línea" (verde) a "Voz activa" (rojo) según el modo;
/// en voz, mientras el modelo llama una skill, el subtítulo muestra qué está
/// haciendo (ej. "Buscando cliente…", vía [SkillL10n] — nunca el nombre
/// técnico crudo). Es el único cambio visible en el header al activar la voz,
/// el resto de la pantalla se mantiene igual (mismo tema claro/oscuro, mismo
/// layout).
class AssistantHeader extends StatelessWidget {
  const AssistantHeader({
    super.key,
    required this.mode,
    required this.sessionActive,
    required this.activeSkill,
    required this.onBack,
    required this.onReset,
  });

  final AssistantMode mode;
  final bool sessionActive;

  /// Nombre técnico de la skill en vuelo durante la voz (o null). Se traduce
  /// con [SkillL10n.skillActivity] — nunca se muestra tal cual.
  final String? activeSkill;
  final VoidCallback onBack;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    final l10n = AppLocalizations.of(context)!;
    final isVoice = mode == AssistantMode.voice;
    final subtitleText = isVoice
        ? (activeSkill != null ? l10n.skillActivity(activeSkill!) : l10n.assistantVoiceActive)
        : l10n.chatSubtitle;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, AmDimens.screenH, 12),
      child: Row(
        children: [
          AmIconBtn(
            icon: Icons.chevron_left,
            tone: AmIconBtnTone.ghost,
            onTap: onBack,
          ),
          const SizedBox(width: 4),
          Image.asset(
            'assets/logo/logo.png',
            width: 38,
            height: 38,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.chatTitle,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface),
                ),
                Row(children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                        color: isVoice ? cs.error : am.green,
                        shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: AmFadeSwitcher(
                      child: Text(
                        subtitleText,
                        key: ValueKey(subtitleText),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isVoice ? cs.error : am.green),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
          const AmAiBackendBadge(),
          if (!isVoice) ...[
            const SizedBox(width: 8),
            AmIconBtn(
              icon: Icons.refresh_rounded,
              tone: AmIconBtnTone.sunken,
              size: 18,
              onTap: onReset,
            ),
          ],
        ],
      ),
    );
  }
}
