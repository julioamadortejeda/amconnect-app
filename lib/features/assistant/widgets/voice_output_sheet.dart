import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/native_audio_service.dart';
import '../../../core/widgets/am_loader.dart';
import '../../../core/widgets/am_press.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/assistant_provider.dart';

/// Bottom sheet para elegir la salida de audio durante la sesión de voz
/// (bocina, audífonos Bluetooth, cableados) — equivalente al botoncito de
/// salida del modo voz de ChatGPT. Lee los dispositivos del nativo vía
/// [AssistantNotifier.audioOutputDevices].
class VoiceOutputSheet extends ConsumerWidget {
  const VoiceOutputSheet({super.key});

  static Future<void> show(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const VoiceOutputSheet(),
    );
  }

  IconData _iconFor(String type) => switch (type) {
        'bluetooth' => Icons.bluetooth_rounded,
        'wired' => Icons.headphones_rounded,
        'speaker' => Icons.volume_up_rounded,
        _ => Icons.speaker_rounded,
      };

  String _labelFor(AudioOutputDevice d, AppLocalizations l10n) {
    if (d.type == 'speaker') return l10n.voiceOutputSpeaker;
    if (d.name.isNotEmpty) return d.name;
    return switch (d.type) {
      'bluetooth' => l10n.voiceOutputBluetooth,
      'wired' => l10n.voiceOutputWired,
      _ => l10n.voiceOutputOther,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final notifier = ref.read(assistantProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.voiceOutputTitle,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 14),
            FutureBuilder<List<AudioOutputDevice>>(
              future: notifier.audioOutputDevices(),
              builder: (context, snap) {
                final devices = snap.data ?? const <AudioOutputDevice>[];
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: AmLoader(),
                  );
                }
                if (devices.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      l10n.voiceOutputNone,
                      style: TextStyle(fontSize: 13.5, color: cs.tertiary),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final d in devices)
                      AmPress(
                        onTap: () {
                          final nav = Navigator.of(context);
                          notifier.selectAudioOutput(d.id);
                          nav.pop();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 13),
                          decoration: BoxDecoration(
                            color: d.selected
                                ? cs.primaryContainer
                                : cs.secondaryContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _iconFor(d.type),
                                size: 20,
                                color: d.selected
                                    ? cs.onPrimaryContainer
                                    : cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _labelFor(d, l10n),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: d.selected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: d.selected
                                        ? cs.onPrimaryContainer
                                        : cs.onSurface,
                                  ),
                                ),
                              ),
                              if (d.selected)
                                Icon(Icons.check_circle_rounded,
                                    size: 19, color: cs.primary),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
