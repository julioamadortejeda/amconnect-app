import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/error_translator.dart';
import '../../../core/widgets/am_ai_backend_badge.dart';
import '../../../core/widgets/am_aurora.dart';
import '../../../l10n/app_localizations.dart';
import '../../chat/providers/stt_provider.dart';
import '../../chat/widgets/voice_pulsing_mic.dart';
import '../providers/chat_tts_provider.dart';
import '../widgets/chat_tts_bubble.dart';

/// Chat de voz "turn-based" (walkie-talkie): STT on-device (sttProvider) →
/// texto → /ai/chat/tts → reproduce la respuesta. Feature aislado — no
/// comparte sesión/estado ni con el chat de texto ni con el Live API
/// (mismo principio que ya separa esos dos entre sí). Se activa con
/// VOICE_MODE=turn_based (ver core/config/env.dart).
class ChatTtsScreen extends ConsumerStatefulWidget {
  const ChatTtsScreen({super.key});

  @override
  ConsumerState<ChatTtsScreen> createState() => _ChatTtsScreenState();
}

class _ChatTtsScreenState extends ConsumerState<ChatTtsScreen> {
  @override
  void initState() {
    super.initState();
    // Escucha el resultado final del STT y dispara el turno de chat+TTS.
    ref.listenManual(sttProvider, (prev, next) {
      final justFinalized = next.isFinal && next.transcript.isNotEmpty && !(prev?.isFinal ?? false);
      if (justFinalized) {
        ref.read(chatTtsProvider.notifier).send(next.transcript);
        ref.read(sttProvider.notifier).clear();
      }
    });
  }

  @override
  void dispose() {
    ref.read(sttProvider.notifier).cancel();
    ref.read(chatTtsProvider.notifier).reset();
    super.dispose();
  }

  void _onMicTap(SttState stt, ChatTtsState chatTts) {
    if (stt.isListening) {
      ref.read(sttProvider.notifier).stop();
    } else if (chatTts.phase == ChatTtsPhase.idle) {
      ref.read(sttProvider.notifier).startListening();
    }
  }

  String _statusLabel(SttState stt, ChatTtsState chatTts, AppLocalizations l10n) {
    if (chatTts.phase == ChatTtsPhase.error) return context.translateError(chatTts.error!);
    if (stt.error != null) return l10n.voiceNotAvailable;
    if (stt.isListening) return l10n.voiceChatListening;
    if (chatTts.phase == ChatTtsPhase.thinking) return l10n.voiceChatThinking;
    if (chatTts.phase == ChatTtsPhase.speaking) return l10n.voiceChatModelSpeaking;
    return l10n.voiceTapToStart;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stt = ref.watch(sttProvider);
    final chatTts = ref.watch(chatTtsProvider);
    final busy = stt.isListening || chatTts.phase != ChatTtsPhase.idle;

    return Scaffold(
      backgroundColor: const Color(0xFF001829),
      body: Stack(
        children: [
          const Positioned.fill(child: AmAurora(delay: Duration(milliseconds: 200))),
          Positioned.fill(
            child: Container(color: const Color(0xFF001829).withValues(alpha: 0.55)),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
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
                      const AmAiBackendBadge(),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: chatTts.lastUserText.isEmpty && chatTts.lastAiText.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => _onMicTap(stt, chatTts),
                                child: const VoicePulsingMic(),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                _statusLabel(stt, chatTts, l10n),
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
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                          children: [
                            ChatTtsBubble(text: chatTts.lastUserText, isUser: true),
                            if (chatTts.lastAiText.isNotEmpty)
                              ChatTtsBubble(text: chatTts.lastAiText, isUser: false),
                          ],
                        ),
                ),
                Container(
                  height: 76,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00111E).withValues(alpha: 0.8),
                    border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _statusLabel(stt, chatTts, l10n),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: chatTts.phase == ChatTtsPhase.error
                                ? Colors.redAccent
                                : Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: busy ? null : () => _onMicTap(stt, chatTts),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: (stt.isListening ? Colors.redAccent : const Color(0xFF007AC0))
                                .withValues(alpha: busy && !stt.isListening ? 0.3 : 1.0),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            stt.isListening ? Icons.stop_rounded : Icons.mic_rounded,
                            color: Colors.white,
                            size: 26,
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
    );
  }
}
