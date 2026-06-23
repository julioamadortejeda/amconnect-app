import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/am_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/am_icon_btn.dart';
import '../../../core/widgets/am_press.dart';
import '../providers/chat_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/voice_overlay.dart';
import 'widgets/chat_cards.dart';
import '../../../core/config/features.dart';

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
  bool _hasText = false;

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
    setState(() => _hasText = false);
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
      backgroundColor: am.bg,
      body: SafeArea(
        child: Column(
          children: [
            _ChatHeader(
              sessionActive: chat.sessionId != null,
              onBack: () => context.pop(),
              onReset: () => ref.read(chatProvider.notifier).reset(),
            ),

            Expanded(
              child: ListView.separated(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(
                    AmDimens.screenH, 8, AmDimens.screenH, 16),
                itemCount: chat.messages.length + (chat.isLoading ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  if (i == chat.messages.length) return const _TypingBubble();
                  final msg = chat.messages[i];
                  return _Bubble(
                      role: msg.role, text: msg.text, metadata: msg.metadata);
                },
              ),
            ),

            if (chat.error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AmDimens.screenH, 0, AmDimens.screenH, 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    Icon(Icons.error_outline_rounded,
                        color: cs.onErrorContainer, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(chat.error!,
                          style: TextStyle(
                              fontSize: 13, color: cs.onErrorContainer)),
                    ),
                  ]),
                ),
              ),

            if (showSugg)
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(
                      AmDimens.screenH, 0, AmDimens.screenH, 6),
                  children: _chatSuggestions
                      .map((s) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: AmPress(
                              onTap: () {
                                _ctrl.text = s;
                                _send();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: cs.surface,
                                  border:
                                      Border.all(color: cs.outlineVariant),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Color(0x0D141E1A),
                                        blurRadius: 2,
                                        offset: Offset(0, 1)),
                                  ],
                                ),
                                child: Text(s,
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        color: cs.onSurfaceVariant)),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AmDimens.screenH, 6, AmDimens.screenH, 12),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x0D141E1A),
                        blurRadius: 2,
                        offset: Offset(0, 1)),
                    BoxShadow(
                        color: Color(0x0A141E1A),
                        blurRadius: 10,
                        offset: Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        onChanged: (v) =>
                            setState(() => _hasText = v.trim().isNotEmpty),
                        onSubmitted: (_) => _send(),
                        enabled: !chat.isLoading,
                        minLines: 1,
                        maxLines: 4,
                        style:
                            TextStyle(fontSize: 15, color: cs.onSurface),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 6),
                          hintText: l10n.chatInputHint,
                          hintStyle: TextStyle(
                              color: cs.onSurfaceVariant
                                  .withValues(alpha: 0.55),
                              fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AmIconBtn(
                      icon: Icons.mic_none_rounded,
                      tone: AmIconBtnTone.sunken,
                      onTap: () {
                        if (kVoiceChatEnabled) {
                          GoRouter.of(context).push('/voice-chat');
                        } else {
                          VoiceOverlay.show(context,
                              continueSession: true, navigateToChat: false);
                        }
                      },
                    ),
                    const SizedBox(width: 6),
                    AnimatedScale(
                      scale: _hasText ? 1.0 : 0.85,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      child: AmIconBtn(
                        icon: Icons.arrow_upward_rounded,
                        tone: _hasText
                            ? AmIconBtnTone.accent
                            : AmIconBtnTone.sunken,
                        onTap:
                            (chat.isLoading || !_hasText) ? null : _send,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.sessionActive,
    required this.onBack,
    required this.onReset,
  });

  final bool sessionActive;
  final VoidCallback onBack;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final am = context.am;
    final l10n = AppLocalizations.of(context)!;

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
              boxShadow: [
                BoxShadow(
                    color: AmColors.accent.withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 4)),
              ],
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
                        color: am.green, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    l10n.chatSubtitle,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: am.green),
                  ),
                ]),
              ],
            ),
          ),
          if (sessionActive)
            AmIconBtn(
              icon: Icons.refresh_rounded,
              tone: AmIconBtnTone.sunken,
              size: 18,
              onTap: onReset,
            ),
        ],
      ),
    );
  }
}

// ── Bubble ─────────────────────────────────────────────────────────────────

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
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      );
    }

    final card = metadata != null ? buildChatCard(metadata!, context) : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AiAvatar(),
        const SizedBox(width: 10),
        Expanded(
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
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x0D141E1A),
                        blurRadius: 2,
                        offset: Offset(0, 1)),
                    BoxShadow(
                        color: Color(0x0A141E1A),
                        blurRadius: 10,
                        offset: Offset(0, 3)),
                  ],
                ),
                child: Text(text,
                    style: TextStyle(
                        fontSize: 15, color: cs.onSurface, height: 1.5)),
              ),
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

// ── AI avatar ──────────────────────────────────────────────────────────────

class _AiAvatar extends StatelessWidget {
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

// ── Typing indicator ───────────────────────────────────────────────────────

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
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
        _AiAvatar(),
        const SizedBox(width: 10),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0D141E1A),
                  blurRadius: 2,
                  offset: Offset(0, 1)),
              BoxShadow(
                  color: Color(0x0A141E1A),
                  blurRadius: 10,
                  offset: Offset(0, 3)),
            ],
          ),
          child: Row(
            children: List.generate(3, (i) {
              final anim = CurvedAnimation(
                parent: _ctrl,
                curve: Interval(i * 0.15, i * 0.15 + 0.5,
                    curve: Curves.easeInOut),
              );
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
