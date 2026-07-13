import 'package:flutter/material.dart';
import '../../../core/theme/am_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_ai_backend_badge.dart';
import '../../../core/widgets/am_icon_btn.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/assistant_provider.dart';

/// Header de la pantalla única de asistente. El indicador de estado (punto +
/// label) cambia de "en línea" (verde) a "Voz activa" (rojo) según el modo —
/// es el único cambio visible en el header al activar la voz, el resto de la
/// pantalla se mantiene igual (mismo tema claro/oscuro, mismo layout).
class AssistantHeader extends StatelessWidget {
  const AssistantHeader({
    super.key,
    required this.mode,
    required this.sessionActive,
    required this.onBack,
    required this.onReset,
  });

  final AssistantMode mode;
  final bool sessionActive;
  final VoidCallback onBack;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    final l10n = AppLocalizations.of(context)!;
    final isVoice = mode == AssistantMode.voice;

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
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AmColors.accent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Image.asset(
                'assets/logo/logo.png',
                color: Colors.white,
                width: 22,
                height: 22,
              ),
            ),
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
                  Text(
                    isVoice ? l10n.assistantVoiceActive : l10n.chatSubtitle,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isVoice ? cs.error : am.green),
                  ),
                ]),
              ],
            ),
          ),
          const AmAiBackendBadge(),
          if (sessionActive && !isVoice) ...[
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
