import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/am_aurora.dart';
import '../providers/chat_provider.dart';
import '../providers/stt_provider.dart';
import 'voice_pulsing_mic.dart';
import 'voice_waveform_bars.dart';
import '../../../l10n/app_localizations.dart';

class VoiceOverlay extends ConsumerStatefulWidget {
  const VoiceOverlay({
    super.key,
    this.initialContext,
    this.continueSession = false,
    this.navigateToChat = true,
  });

  final AiChatContext? initialContext;
  final bool continueSession;

  /// Si es false, al enviar solo cierra el overlay sin navegar a /chat.
  /// Usar cuando el overlay ya se abrió desde la pantalla de chat.
  final bool navigateToChat;

  static Future<void> show(
    BuildContext context, {
    AiChatContext? initialContext,
    bool continueSession = false,
    bool navigateToChat = true,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'voice',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, _, __) => VoiceOverlay(
        initialContext: initialContext,
        continueSession: continueSession,
        navigateToChat: navigateToChat,
      ),
      transitionBuilder: (ctx, anim, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
    );
  }

  @override
  ConsumerState<VoiceOverlay> createState() => _VoiceOverlayState();
}

class _VoiceOverlayState extends ConsumerState<VoiceOverlay> {
  final _textCtrl = TextEditingController();
  bool _hasText = false;

  // Guardamos referencias en initState para poder usarlas en dispose
  // sin tocar ref (unsafe después de unmount).
  late final SttNotifier _stt;
  late final ChatNotifier _chat;

  @override
  void initState() {
    super.initState();
    _stt = ref.read(sttProvider.notifier);
    _chat = ref.read(chatProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (widget.initialContext != null) {
        await _chat.resetWithContext(widget.initialContext!);
      } else if (!widget.continueSession) {
        await _chat.reset();
      }
      if (!mounted) return;
      _stt.startListening();
    });
  }

  @override
  void dispose() {
    _stt.cancel(); // sin ref — seguro en dispose
    _textCtrl.dispose();
    super.dispose();
  }

  void _onMicTap(SttState stt) {
    if (stt.transcript.isNotEmpty && !stt.isListening) {
      _submitToChat(stt.transcript);
    } else if (stt.isListening) {
      _stt.stop();
    } else {
      _stt.startListening();
    }
  }

  void _submitToChat(String text) {
    if (text.trim().isEmpty) return;
    _stt.cancel();
    _chat.send(text.trim());
    Navigator.of(context).pop();
    if (widget.navigateToChat) {
      GoRouter.of(context).push('/chat');
    }
  }

  void _sendText() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    setState(() => _hasText = false);
    FocusScope.of(context).unfocus();
    _submitToChat(text);
  }

  String _statusText(SttState stt, AppLocalizations l10n) {
    if (stt.error != null) return l10n.voiceNotAvailable;
    if (stt.transcript.isNotEmpty && !stt.isListening) return l10n.voiceTapToSend;
    if (stt.isListening) return l10n.voiceListening;
    return l10n.voiceTapToStart;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final stt = ref.watch(sttProvider);

    return Material(
      color: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Stack(
          children: [
            // Capa de fondo — cierra el overlay al tocar fuera del contenido
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  Navigator.of(context).pop();
                },
                child: Container(
                  color: const Color(0xFF003B7A).withValues(alpha: 0.52),
                ),
              ),
            ),

            const AmAurora(delay: Duration(milliseconds: 300)),

            // Contenido — captura sus propios taps sin dejar pasar al fondo
            SafeArea(
              child: Column(
                children: [
                      // ── Main content area ─────────────────────────────
                      Expanded(
                        child: Stack(
                          children: [
                            // Close button
                            Positioned(
                              top: 8,
                              right: 16,
                              child: GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),

                            // Mic + waveform + transcript
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Spacer(flex: 5),

                                GestureDetector(
                                  onTap: () => _onMicTap(stt),
                                  child: const VoicePulsingMic(),
                                ),
                                const SizedBox(height: 28),

                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Text(
                                    _statusText(stt, l10n),
                                    key: ValueKey(_statusText(stt, l10n)),
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: (stt.transcript.isNotEmpty && !stt.isListening)
                                          ? Colors.white.withValues(alpha: 0.9)
                                          : Colors.white.withValues(alpha: 0.6),
                                      fontWeight: (stt.transcript.isNotEmpty && !stt.isListening)
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 36),
                                const VoiceWaveformBars(),
                                const SizedBox(height: 32),

                                // Transcript
                                AnimatedOpacity(
                                  opacity: stt.transcript.isNotEmpty ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 280),
                                  child: SizedBox(
                                    height: 96,
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 36),
                                        child: GestureDetector(
                                          onTap: () {
                                            if (stt.transcript.isNotEmpty && !stt.isListening) {
                                              _submitToChat(stt.transcript);
                                            }
                                          },
                                          child: AnimatedSwitcher(
                                            duration: const Duration(milliseconds: 180),
                                            transitionBuilder: (child, anim) =>
                                                FadeTransition(opacity: anim, child: child),
                                            child: Text(
                                              stt.transcript,
                                              key: ValueKey(stt.transcript),
                                              textAlign: TextAlign.center,
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 23,
                                                fontWeight: FontWeight.w600,
                                                color: !stt.isListening
                                                    ? Colors.white
                                                    : Colors.white.withValues(alpha: 0.75),
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const Spacer(flex: 4),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ── Text input bar ────────────────────────────────
                      GestureDetector(
                        onTap: () {}, // absorb taps so overlay doesn't close
                        child: AnimatedPadding(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _textCtrl,
                                    onChanged: (v) =>
                                        setState(() => _hasText = v.trim().isNotEmpty),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 16),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      hintText: l10n.voiceInputHint,
                                      hintStyle: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.38),
                                        fontSize: 16,
                                      ),
                                    ),
                                    textInputAction: TextInputAction.send,
                                    onSubmitted: (_) => _sendText(),
                                    cursorColor: Colors.white,
                                  ),
                                ),
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOut,
                                  child: _hasText
                                      ? GestureDetector(
                                          onTap: _sendText,
                                          child: Container(
                                            margin: const EdgeInsets.only(left: 8),
                                            width: 34,
                                            height: 34,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF007AC0),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.arrow_upward_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
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
}
