import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/am_theme.dart';
import '../../../core/widgets/am_press.dart';
import '../providers/chat_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/voice_overlay.dart';
import 'widgets/chat_cards.dart';

const _chatSuggestions = [
  '¿Quién vence pronto?',
  '¿Cuánto cobra Javier?',
  'Recuérdame llamar mañana',
  '¿Pagos esta semana?',
];

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, this.initialContext});

  final AiChatContext? initialContext;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.initialContext != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(chatProvider.notifier).resetWithContext(widget.initialContext!);
        }
      });
    }
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    ref.read(chatProvider.notifier).send(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    final l10n = AppLocalizations.of(context)!;
    final chat = ref.watch(chatProvider);

    ref.listen(chatProvider, (prev, next) {
      if (next.messages.length != (prev?.messages.length ?? 0)) {
        _scrollToBottom();
      }
    });

    final showSugg = chat.messages.isEmpty && !chat.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, size: 26, color: cs.onSurface),
                    onPressed: () => context.pop(),
                  ),
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF2AB5FF), Color(0xFF007AC0)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.chatTitle,
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600,
                                color: cs.onSurface)),
                        Row(children: [
                          Container(width: 7, height: 7,
                              decoration: BoxDecoration(
                                  color: am.green, shape: BoxShape.circle)),
                          const SizedBox(width: 5),
                          Text(l10n.chatSubtitle,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                  color: am.green)),
                        ]),
                      ],
                    ),
                  ),
                  if (chat.sessionId != null)
                    IconButton(
                      icon: Icon(Icons.refresh, color: cs.tertiary, size: 20),
                      onPressed: () => ref.read(chatProvider.notifier).reset(),
                      tooltip: l10n.chatNewConversation,
                    ),
                ],
              ),
            ),

            // Messages
            Expanded(
              child: ListView.separated(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                itemCount: chat.messages.length + (chat.isLoading ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (_, i) {
                  if (i == chat.messages.length) return const _TypingBubble();
                  final msg = chat.messages[i];
                  return _Bubble(role: msg.role, text: msg.text, metadata: msg.metadata);
                },
              ),
            ),

            // Error banner
            if (chat.error != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.error.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  Icon(Icons.error_outline, color: cs.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(chat.error!,
                      style: TextStyle(fontSize: 13, color: cs.error))),
                ]),
              ),

            // Suggestions
            if (showSugg)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  children: _chatSuggestions.map((s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AmPress(
                      onTap: () { _ctrl.text = s; _send(); },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: cs.outline),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(s,
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant)),
                      ),
                    ),
                  )).toList(),
                ),
              ),

            // Input
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.055), blurRadius: 22)],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      onSubmitted: (_) => _send(),
                      enabled: !chat.isLoading,
                      style: TextStyle(fontSize: 15, color: cs.onSurface),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: l10n.chatInputHint,
                        hintStyle: TextStyle(color: cs.tertiary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ActionBtn(icon: Icons.mic_none_outlined, onTap: () => VoiceOverlay.show(context)),
                  const SizedBox(width: 6),
                  _ActionBtn(
                    icon: Icons.arrow_upward,
                    accent: true,
                    onTap: chat.isLoading ? () {} : _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.role, required this.text, this.metadata});
  final String role;
  final String text;
  final Map<String, dynamic>? metadata;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (role == 'user') {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AmColors.accent,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18), topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18), bottomRight: Radius.circular(6),
            ),
            boxShadow: [BoxShadow(color: AmColors.accent.withValues(alpha: 0.3), blurRadius: 12)],
          ),
          child: Text(text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500,
                  color: Colors.white, height: 1.45)),
        ),
      );
    }

    // Check if there's a premium card to render
    final card = metadata != null ? buildChatCard(metadata!, context) : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF2AB5FF), Color(0xFF007AC0)]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text bubble
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6), topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18),
                  ),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.055), blurRadius: 22)],
                ),
                child: Text(text,
                    style: TextStyle(fontSize: 15, color: cs.onSurface, height: 1.5)),
              ),
              // Premium card below the text bubble
              if (card != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: card,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.icon, this.accent = false, required this.onTap});
  final IconData icon;
  final bool accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AmPress(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: accent ? AmColors.accent : cs.secondaryContainer,
          borderRadius: BorderRadius.circular(13),
          boxShadow: accent
              ? [BoxShadow(color: AmColors.accent.withValues(alpha: 0.3), blurRadius: 10)]
              : null,
        ),
        child: Icon(icon, size: 20, color: accent ? Colors.white : cs.onSurfaceVariant),
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final am = context.am;
    return Row(
      children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF2AB5FF), Color(0xFF007AC0)]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 9),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6), topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18),
            ),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.055), blurRadius: 22)],
          ),
          child: Row(
            children: List.generate(3, (i) {
              final anim = CurvedAnimation(
                parent: _ctrl,
                curve: Interval(i * 0.15, i * 0.15 + 0.5, curve: Curves.easeInOut),
              );
              return AnimatedBuilder(
                animation: anim,
                builder: (_, __) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: am.muted2.withValues(alpha: 0.4 + anim.value * 0.6),
                    shape: BoxShape.circle,
                  ),
                  transform: Matrix4.translationValues(0, -anim.value * 5, 0),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
