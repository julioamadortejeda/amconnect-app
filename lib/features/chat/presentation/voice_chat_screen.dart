import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/am_aurora.dart';
import '../providers/voice_chat_provider.dart';
import '../widgets/voice_waveform_bars.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_translator.dart';
import '../../../l10n/app_localizations.dart';

class VoiceChatScreen extends ConsumerStatefulWidget {
  const VoiceChatScreen({super.key});

  @override
  ConsumerState<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends ConsumerState<VoiceChatScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _badgePulse;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _badgePulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(voiceChatProvider.notifier).connect('America/Mexico_City');
    });
  }

  @override
  void dispose() {
    _badgePulse.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _endSession() {
    ref.read(voiceChatProvider.notifier).endSession();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(voiceChatProvider);

    // Auto-scroll to keep the latest content visible — both when a new turn is
    // committed AND while the live transcript streams in (token by token). Uses
    // jumpTo for the live updates so many rapid changes don't queue competing
    // animations; the list still follows smoothly.
    ref.listen(voiceChatProvider, (prev, next) {
      final contentGrew = prev?.turns.length != next.turns.length ||
          prev?.liveModelText != next.liveModelText ||
          prev?.liveUserText != next.liveUserText;
      if (contentGrew) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollCtrl.hasClients) {
            _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
          }
        });
      }
      // Auto-close when session ends
      if (prev?.status != VoiceChatStatus.closed &&
          next.status == VoiceChatStatus.closed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.pop();
        });
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF001829),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (state.status == VoiceChatStatus.modelSpeaking) {
            ref.read(voiceChatProvider.notifier).interrupt();
          }
        },
        child: Stack(
          children: [
            // Aurora background
            const Positioned.fill(
                child: AmAurora(delay: Duration(milliseconds: 200))),

            // Darkening overlay so text stays readable
            Positioned.fill(
              child: Container(
                color: const Color(0xFF001829).withValues(alpha: 0.55),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // ── Top bar ───────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        _VoiceBadge(pulse: _badgePulse),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'AMCONNECT VOICE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.5),
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Transcript list / Active Orb ──────────────────────────
                  Expanded(
                    child: state.turns.isEmpty &&
                            state.liveUserText.isEmpty &&
                            state.liveModelText.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _VoiceActiveOrb(status: state.status),
                                const SizedBox(height: 24),
                                Text(
                                  _statusLabel(state, l10n),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                            children: [
                              ...state.turns.map((t) => _TurnBubble(turn: t)),
                              // Live user transcript
                              if (state.liveUserText.isNotEmpty)
                                _TurnBubble(
                                  turn: VoiceChatTurn(
                                      isUser: true, text: state.liveUserText),
                                  isLive: true,
                                ),
                              // Live model transcript
                              if (state.liveModelText.isNotEmpty)
                                _TurnBubble(
                                  turn: VoiceChatTurn(
                                      isUser: false, text: state.liveModelText),
                                  isLive: true,
                                ),
                            ],
                          ),
                  ),

                  // ── Sleek Bottom Bar ─────────────────────────────────────────
                  Container(
                    height: 76,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00111E).withValues(alpha: 0.8),
                      border: Border(
                        top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08)),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Status & Active Skill info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _statusLabel(state, l10n),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: state.status == VoiceChatStatus.error
                                      ? Colors.redAccent
                                      : Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              if (state.activeSkill != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '${l10n.voiceChatSkillActive} (${state.activeSkill})',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.5),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ] else if (state.status ==
                                  VoiceChatStatus.modelSpeaking) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Toca la pantalla para interrumpir',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ] else if (state.error != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  context.translateError(state.error!),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Compact Waveform Visualizer
                        if (state.status == VoiceChatStatus.listening ||
                            state.status == VoiceChatStatus.modelSpeaking)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: VoiceWaveformBars(maxHeight: 28.0),
                          ),

                        // Close / End Session button (X)
                        GestureDetector(
                          onTap: _endSession,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFCC0000)
                                  .withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFCC0000)
                                    .withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFFFF4D4D),
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(VoiceChatState state, AppLocalizations l10n) {
    return switch (state.status) {
      VoiceChatStatus.connecting => l10n.voiceChatConnecting,
      VoiceChatStatus.ready => l10n.voiceChatSessionReady,
      VoiceChatStatus.listening => l10n.voiceChatListening,
      VoiceChatStatus.modelSpeaking => l10n.voiceChatModelSpeaking,
      VoiceChatStatus.error => l10n.voiceChatError,
      VoiceChatStatus.closed => l10n.voiceChatClosed,
    };
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _VoiceBadge extends StatelessWidget {
  const _VoiceBadge({required this.pulse});
  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) {
        final glow = 0.5 + pulse.value * 0.5;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFCC0000),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFCC0000).withValues(alpha: glow * 0.7),
                blurRadius: 10 + pulse.value * 8,
                spreadRadius: pulse.value * 2,
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: Colors.white, size: 7),
              SizedBox(width: 5),
              Text(
                'VOICE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TurnBubble extends StatelessWidget {
  const _TurnBubble({required this.turn, this.isLive = false});
  final VoiceChatTurn turn;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final isUser = turn.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF007AC0).withValues(alpha: isLive ? 0.55 : 0.85)
              : Colors.white.withValues(alpha: isLive ? 0.08 : 0.14),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          turn.text,
          style: TextStyle(
            fontSize: 15,
            height: 1.45,
            color: Colors.white.withValues(alpha: isLive ? 0.65 : 1.0),
            fontWeight: isLive ? FontWeight.w400 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _VoiceActiveOrb extends StatefulWidget {
  const _VoiceActiveOrb({required this.status});
  final VoiceChatStatus status;

  @override
  State<_VoiceActiveOrb> createState() => _VoiceActiveOrbState();
}

class _VoiceActiveOrbState extends State<_VoiceActiveOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t1 = Curves.easeOut.transform(_ctrl.value);
        final t2 = Curves.easeOut.transform((_ctrl.value + 0.5).remainder(1.0));

        final isError = widget.status == VoiceChatStatus.error;
        final isConnecting = widget.status == VoiceChatStatus.connecting ||
            widget.status == VoiceChatStatus.ready;

        final circleColor = isError ? Colors.red : AmColors.accent;
        final iconData = isError
            ? Icons.error_outline_rounded
            : (isConnecting ? Icons.wifi_tethering_rounded : Icons.mic_rounded);

        final iconColor = isError ? Colors.redAccent : Colors.white;

        return SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (!isError) ...[
                // Ring 1
                Container(
                  width: 80 + 56 * t1,
                  height: 80 + 56 * t1,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AmColors.accent.withValues(alpha: 0.18 * (1 - t1)),
                  ),
                ),
                // Ring 2
                Container(
                  width: 80 + 56 * t2,
                  height: 80 + 56 * t2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AmColors.accent.withValues(alpha: 0.18 * (1 - t2)),
                  ),
                ),
                // Static halo
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AmColors.accent.withValues(alpha: 0.2),
                  ),
                ),
              ],
              // Main connecting circle
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isError
                      ? Colors.red.withValues(alpha: 0.15)
                      : circleColor,
                  border: isError
                      ? Border.all(color: Colors.red.withValues(alpha: 0.4))
                      : null,
                  boxShadow: isError
                      ? null
                      : [
                          BoxShadow(
                            color: AmColors.accent.withValues(alpha: 0.55),
                            blurRadius: 32,
                            spreadRadius: 2,
                          ),
                        ],
                ),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: isError ? 34 : 38,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
