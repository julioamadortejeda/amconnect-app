import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/chat_cards.dart';
import 'thinking_pulse.dart';

/// Burbuja de mensaje — la misma para texto y voz, sin distinción visual de
/// origen. `isLive` se usa solo para el texto que aún se está transcribiendo
/// en modo voz (opacidad reducida, sin card), antes de que el turno se fije
/// al historial.
class AssistantBubble extends StatelessWidget {
  const AssistantBubble({
    super.key,
    required this.role,
    required this.text,
    this.metadata,
    this.isLive = false,
  });

  final String role;
  final String text;
  final Map<String, dynamic>? metadata;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (role == 'user') {
      return Align(
        alignment: Alignment.centerRight,
        child: Opacity(
          opacity: isLive ? 0.6 : 1.0,
          child: Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AmColors.accent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(6),
              ),
              boxShadow: [
                BoxShadow(
                    color: AmColors.accent.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Text(text,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    height: 1.45)),
          ),
        ),
      );
    }

    final card = (!isLive && metadata != null) ? buildChatCard(metadata!, context) : null;

    return Align(
      alignment: Alignment.centerLeft,
      child: Opacity(
        opacity: isLive ? 0.6 : 1.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(6),
                  bottomRight: Radius.circular(18),
                ),
                boxShadow: AmShadows.card,
              ),
              child: MarkdownBody(
                data: text,
                shrinkWrap: true,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                  p: TextStyle(fontSize: 15, color: cs.onSurface, height: 1.5),
                  strong: const TextStyle(fontWeight: FontWeight.bold),
                  listBullet: const TextStyle(color: AmColors.accent),
                ),
              ),
            ),
            if (card != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: card,
              ),
          ],
        ),
      ),
    );
  }
}

/// Indicador de "pensando…" mientras `isLoading` (envío de texto en curso).
/// Mismo lenguaje visual que en la barra de voz (glow que respira) en vez de
/// los 3 puntos rebotando de antes — consistencia entre texto y voz al
/// mostrar "la IA está trabajando". Sin card/burbuja blanca envolvente a
/// propósito: flota directo sobre el fondo, como el indicador de
/// "pensando" de ChatGPT/Gemini.
class AssistantTypingBubble extends StatelessWidget {
  const AssistantTypingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: ThinkingPulse(color: AmColors.accent, size: 16),
      ),
    );
  }
}
