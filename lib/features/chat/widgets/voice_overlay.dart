import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:amconnect/core/widgets/am_aurora.dart';
import 'package:amconnect/features/chat/widgets/voice_pulsing_mic.dart';
import 'package:amconnect/features/chat/widgets/voice_waveform_bars.dart';
import 'package:amconnect/l10n/app_localizations.dart';

class VoiceOverlay extends StatefulWidget {
  const VoiceOverlay({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'voice',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, _, __) => const VoiceOverlay(),
      transitionBuilder: (ctx, anim, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
    );
  }

  @override
  State<VoiceOverlay> createState() => _VoiceOverlayState();
}

class _VoiceOverlayState extends State<VoiceOverlay> {
  String _transcript = '';
  final _textCtrl = TextEditingController();
  bool _hasText = false;

  static const _mockPhrase = 'Busca el contrato de Mariana Torres';

  @override
  void initState() {
    super.initState();
    _startMockTyping();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _startMockTyping() async {
    await Future.delayed(const Duration(milliseconds: 1100));
    for (var i = 1; i <= _mockPhrase.length; i++) {
      if (!mounted) return;
      setState(() => _transcript = _mockPhrase.substring(0, i));
      await Future.delayed(const Duration(milliseconds: 52));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            FocusScope.of(context).unfocus();
            Navigator.of(context).pop();
          },
          child: Container(
            color: const Color(0xFF003B7A).withValues(alpha: 0.52),
            child: Stack(
              children: [
                const AmAurora(delay: Duration(milliseconds: 300)),

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

                            // Mic + waveform — IgnorePointer so taps fall through to close
                            IgnorePointer(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Spacer(flex: 5),
                                  const VoicePulsingMic(),
                                  const SizedBox(height: 28),
                                  Text(
                                    l10n.voiceListening,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.white.withValues(alpha: 0.6),
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 36),
                                  const VoiceWaveformBars(),
                                  const SizedBox(height: 32),
                                  SizedBox(
                                    height: 88,
                                    child: AnimatedOpacity(
                                      opacity: _transcript.isNotEmpty ? 1.0 : 0.0,
                                      duration: const Duration(milliseconds: 220),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 36),
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: Text(
                                            _transcript,
                                            textAlign: TextAlign.center,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 23,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Spacer(flex: 4),
                                ],
                              ),
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
        ),
      ),
    );
  }

  void _sendText() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    setState(() => _hasText = false);
    FocusScope.of(context).unfocus();
    // TODO: wire up to AI chat
  }
}
