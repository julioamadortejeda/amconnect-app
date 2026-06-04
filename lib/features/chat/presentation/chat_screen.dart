import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:amconnect/core/theme/app_colors.dart';
import 'package:amconnect/core/mock/mock_data.dart';
import 'package:amconnect/core/widgets/am_press.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class _ChatMsg {
  _ChatMsg({required this.id, required this.role, required this.text,
      this.big, this.card, this.bullets});
  final String id;
  final String role;
  final String text;
  final String? big;
  final MockMsgCard? card;
  final List<List<String>>? bullets;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _typing = false;
  List<_ChatMsg> _msgs = [
    _ChatMsg(id: 'm0', role: 'ai',
        text: '¡Hola! Soy tu asistente. Tengo acceso a todos tus clientes, pólizas y recordatorios. ¿En qué te ayudo?'),
  ];

  void _ask(String q) {
    if (q.trim().isEmpty) return;
    _ctrl.clear();
    final userMsg = _ChatMsg(id: 'u${DateTime.now().millisecondsSinceEpoch}', role: 'user', text: q);
    setState(() { _msgs = [..._msgs, userMsg]; _typing = true; });
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 1300), () {
      if (!mounted) return;
      final reply = _answerFor(q);
      setState(() { _msgs = [..._msgs, reply]; _typing = false; });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  _ChatMsg _answerFor(String q) {
    final lower = q.toLowerCase();
    if (lower.contains('mariana') || lower.contains('auto')) {
      return _ChatMsg(
        id: 'a${DateTime.now().millisecondsSinceEpoch}',
        role: 'ai',
        text: 'Mariana Torres paga',
        big: '\$11,300 / año',
        card: MockMsgCard(
          ramo: 'Auto · GNP', numero: 'AUT-552190',
          rows: [['Prima anual', '\$11,300'], ['Deducible', '\$22,500'],
                 ['Suma asegurada', '\$450,000'], ['Vence', '4 jun 2026']],
        ),
      );
    }
    if (lower.contains('semana') || lower.contains('pago')) {
      return _ChatMsg(
        id: 'a${DateTime.now().millisecondsSinceEpoch}',
        role: 'ai',
        text: 'Tienes 2 pagos programados esta semana:',
        bullets: [
          ['Auto — Mariana Torres', 'GNP · \$11,300 · hoy'],
          ['Renovación GMM — Javier', 'GNP · en 9 días'],
        ],
      );
    }
    return _ChatMsg(
      id: 'a${DateTime.now().millisecondsSinceEpoch}',
      role: 'ai',
      text: 'Entendido. Revisé tu base de datos y no encontré información específica sobre eso. ¿Quieres que te ayude con algo más?',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final msgs = _msgs;
    final showSugg = msgs.length <= 3 && !_typing;

    return Scaffold(
      backgroundColor: AmColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 26, color: AmColors.inkLight),
                    onPressed: () => context.pop(),
                  ),
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2AB5FF), Color(0xFF007AC0)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Asistente',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600,
                                color: AmColors.inkLight)),
                        Row(children: [
                          Container(width: 7, height: 7,
                              decoration: const BoxDecoration(color: AmColors.greenLight, shape: BoxShape.circle)),
                          const SizedBox(width: 5),
                          const Text('Conectado a tu base',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                  color: AmColors.greenLight)),
                        ]),
                      ],
                    ),
                  ),
                  const Icon(Icons.more_horiz, color: AmColors.inkLight),
                ],
              ),
            ),
            // Thread
            Expanded(
              child: ListView.separated(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                itemCount: msgs.length + (_typing ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (_, i) {
                  if (i == msgs.length) return const _TypingBubble();
                  return _MessageBubble(m: msgs[i]);
                },
              ),
            ),
            // Suggestions
            if (showSugg)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  children: mockSuggestions.map((s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AmPress(
                      onTap: () => _ask(s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AmColors.lineLight),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(s,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                                color: AmColors.inkSoftLight)),
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
                      onSubmitted: _ask,
                      style: const TextStyle(fontSize: 15, color: AmColors.inkLight),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'Pregúntale a tu asistente…',
                        hintStyle: TextStyle(color: AmColors.mutedLight),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ActionBtn(icon: Icons.mic_none_outlined, onTap: () {}),
                  const SizedBox(width: 6),
                  _ActionBtn(
                    icon: Icons.arrow_upward,
                    accent: true,
                    onTap: () => _ask(_ctrl.text),
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

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.icon, this.accent = false, required this.onTap});
  final IconData icon;
  final bool accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AmPress(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: accent ? AmColors.accent : AmColors.cardSunkenLight,
          borderRadius: BorderRadius.circular(13),
          boxShadow: accent
              ? [BoxShadow(color: AmColors.accent.withValues(alpha: 0.3), blurRadius: 10)]
              : null,
        ),
        child: Icon(icon, size: 20, color: accent ? Colors.white : AmColors.inkSoftLight),
      ),
    );
  }
}

// ── Message Bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.m});
  final _ChatMsg m;

  @override
  Widget build(BuildContext context) {
    if (m.role == 'user') {
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
          child: Text(m.text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500,
                  color: Colors.white, height: 1.45)),
        ),
      );
    }
    // AI
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
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6), topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18), bottomRight: Radius.circular(18),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.055), blurRadius: 22)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.text,
                    style: const TextStyle(fontSize: 15, color: AmColors.inkLight, height: 1.5)),
                if (m.big != null) ...[
                  const SizedBox(height: 8),
                  Text(m.big!,
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600,
                          letterSpacing: -0.02, color: AmColors.accentInk)),
                ],
                if (m.card != null) ...[
                  const SizedBox(height: 12),
                  _MsgCard(card: m.card!),
                ],
                if (m.bullets != null) ...[
                  const SizedBox(height: 12),
                  ...m.bullets!.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22, height: 22,
                          decoration: BoxDecoration(
                            color: AmColors.accentWash,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          alignment: Alignment.center,
                          child: Text('${e.key + 1}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                  color: AmColors.accentInk)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.value[0],
                                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500,
                                      color: AmColors.inkLight)),
                              Text(e.value[1],
                                  style: const TextStyle(fontSize: 13, color: AmColors.mutedLight)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MsgCard extends StatelessWidget {
  const _MsgCard({required this.card});
  final MockMsgCard card;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
      decoration: BoxDecoration(
        color: AmColors.cardSunkenLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(card.ramo,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: AmColors.inkLight)),
              const Spacer(),
              Text(card.numero,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500,
                      color: AmColors.mutedLight)),
            ],
          ),
          ...card.rows.asMap().entries.map((e) => Padding(
            padding: EdgeInsets.only(top: e.key > 0 ? 6 : 10),
            child: Container(
              padding: e.key > 0 ? const EdgeInsets.only(top: 6) : null,
              decoration: e.key > 0
                  ? const BoxDecoration(border: Border(top: BorderSide(color: AmColors.lineSoftLight)))
                  : null,
              child: Row(
                children: [
                  Text(e.value[0],
                      style: const TextStyle(fontSize: 13.5, color: AmColors.mutedLight)),
                  const Spacer(),
                  Text(e.value[1],
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500,
                          color: AmColors.inkLight)),
                ],
              ),
            ),
          )),
        ],
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
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    color: AmColors.muted2Light.withValues(alpha: 0.4 + anim.value * 0.6),
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
