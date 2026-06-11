import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:amconnect/features/chat/widgets/voice_edge_glow.dart';
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

  static const _mockPhrase = 'Busca el contrato de Mariana Torres';

  @override
  void initState() {
    super.initState();
    _startMockTyping();
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

    return Material(
      color: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            color: const Color(0xFF0A1829).withValues(alpha: 0.58),
            child: Stack(
              children: [
                // Animated colored edge glow
                const VoiceEdgeGlow(),

                SafeArea(
                  child: Stack(
                    children: [
                      // Close button — its own GestureDetector stops propagation
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

                      // Content — IgnorePointer lets background GestureDetector receive taps
                      IgnorePointer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Spacer(flex: 5),

                            // Pulsing mic
                            const VoicePulsingMic(),
                            const SizedBox(height: 28),

                            // Status label
                            Text(
                              l10n.voiceListening,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white.withValues(alpha: 0.6),
                                letterSpacing: 0.4,
                              ),
                            ),

                            const SizedBox(height: 36),

                            // Waveform bars
                            const VoiceWaveformBars(),

                            const SizedBox(height: 32),

                            // Transcript — fixed height to prevent layout shift.
                            // SizedBox(width: inf) forces full width so textAlign:center works.
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

                            // Hint
                            Padding(
                              padding: const EdgeInsets.only(bottom: 32),
                              child: Text(
                                l10n.voiceTapToClose,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.35),
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
        ),
      ),
    );
  }
}
