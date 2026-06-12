import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/am_press.dart';
import '../providers/ingest_provider.dart';

class IngestChatSheet extends ConsumerStatefulWidget {
  const IngestChatSheet({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  ConsumerState<IngestChatSheet> createState() => _IngestChatSheetState();
}

class _IngestChatSheetState extends ConsumerState<IngestChatSheet> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    ref.read(ingestProvider.notifier).sendMessage(text);
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
    final state = ref.watch(ingestProvider);

    ref.listen(ingestProvider, (prev, next) {
      if (next.messages.length != (prev?.messages.length ?? 0)) _scrollToBottom();
    });

    final extraction = state.extraction ?? {};
    final policyNumber = extraction['policyNumber'] as String?;
    final carrierName = extraction['carrierName'] as String?;
    final holderName = extraction['holderName'] as String?;
    final premium = extraction['premium'];

    return Container(
      color: Colors.black.withValues(alpha: 0.34),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.82,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28), topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              // Handle + header
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                child: Column(
                  children: [
                    Container(
                      width: 44, height: 5,
                      decoration: BoxDecoration(
                        color: cs.outline,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2AB5FF), Color(0xFF007AC0)]),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Confirmar póliza',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                                      color: cs.onSurface)),
                              if (policyNumber != null || carrierName != null)
                                Text(
                                  [if (carrierName != null) carrierName,
                                   if (policyNumber != null) '# $policyNumber'].join(' · '),
                                  style: TextStyle(fontSize: 12.5, color: cs.tertiary),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: cs.tertiary, size: 20),
                          onPressed: widget.onClose,
                        ),
                      ],
                    ),
                    // Extraction summary chips
                    if (holderName != null || premium != null) ...[
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (holderName != null) _Chip(label: holderName),
                            if (premium != null) _Chip(label: 'Prima: \$$premium'),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Divider(height: 1, color: cs.outlineVariant),
                  ],
                ),
              ),

              // Messages
              Expanded(
                child: ListView.separated(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: state.messages.length + (state.isSending ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    if (i == state.messages.length) return const _TypingDots();
                    final msg = state.messages[i];
                    return _ChatBubble(role: msg.role, text: msg.text);
                  },
                ),
              ),

              // Error
              if (state.error != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: cs.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(state.error!,
                      style: TextStyle(fontSize: 12.5, color: cs.error)),
                ),

              // Input
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        onSubmitted: (_) => _send(),
                        enabled: !state.isSending,
                        style: TextStyle(fontSize: 15, color: cs.onSurface),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: 'Confirma o corrige los datos…',
                          hintStyle: TextStyle(color: cs.tertiary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AmPress(
                      onTap: state.isSending ? () {} : _send,
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AmColors.accent,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(Icons.arrow_upward, size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500,
              color: cs.onPrimaryContainer)),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.role, required this.text});
  final String role;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (role == 'user') {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: AmColors.accent,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16), topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16), bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(text,
              style: const TextStyle(fontSize: 14.5, color: Colors.white, height: 1.45)),
        ),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cs.secondaryContainer,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4), topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16),
          ),
        ),
        child: Text(text,
            style: TextStyle(fontSize: 14.5, color: cs.onSurface, height: 1.5)),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
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
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cs.secondaryContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final anim = CurvedAnimation(
              parent: _ctrl,
              curve: Interval(i * 0.15, i * 0.15 + 0.5, curve: Curves.easeInOut),
            );
            return AnimatedBuilder(
              animation: anim,
              builder: (_, __) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 7, height: 7,
                decoration: BoxDecoration(
                  color: cs.tertiary.withValues(alpha: 0.4 + anim.value * 0.6),
                  shape: BoxShape.circle,
                ),
                transform: Matrix4.translationValues(0, -anim.value * 4, 0),
              ),
            );
          }),
        ),
      ),
    );
  }
}
