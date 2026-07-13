import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/theme/am_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../chat/presentation/widgets/chat_cards.dart';

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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AiAvatar(),
        const SizedBox(width: 10),
        Expanded(
          child: Opacity(
            opacity: isLive ? 0.6 : 1.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
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
        ),
      ],
    );
  }
}

class _AiAvatar extends StatelessWidget {
  const _AiAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AmColors.accent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Image.asset(
          'assets/logo/logo.png',
          color: Colors.white,
          width: 17,
          height: 17,
        ),
      ),
    );
  }
}

/// Indicador de "escribiendo…" mientras `isLoading` (envío de texto en
/// curso).
class AssistantTypingBubble extends StatefulWidget {
  const AssistantTypingBubble({super.key});

  @override
  State<AssistantTypingBubble> createState() => _AssistantTypingBubbleState();
}

class _AssistantTypingBubbleState extends State<AssistantTypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<Animation<double>> _anims = [];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));

    for (int i = 0; i < 3; i++) {
      _anims.add(CurvedAnimation(
        parent: _ctrl,
        curve: Interval(i * 0.15, i * 0.15 + 0.5, curve: Curves.easeInOut),
      ));
    }

    _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const _AiAvatar(),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            boxShadow: AmShadows.card,
          ),
          child: Row(
            children: List.generate(3, (i) {
              final anim = _anims[i];
              return AnimatedBuilder(
                animation: anim,
                builder: (_, __) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: am.muted2.withValues(alpha: 0.5 + anim.value * 0.5),
                    shape: BoxShape.circle,
                  ),
                  transform:
                      Matrix4.translationValues(0, -anim.value * 5, 0),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
