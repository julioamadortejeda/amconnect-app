import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/audio_recorder_provider.dart';
import '../providers/ingest_provider.dart';

/// Graba una nota de voz con el micrófono del dispositivo y la entrega
/// lista para subir — mismo sheet transformándose por fase (idle → grabando
/// → lista para escuchar/aceptar), sin navegar a otra pantalla.
///
/// Recibe datos planos (no un callback capturado del picker que la abrió):
/// ese picker ya se cerró (pop) antes de mostrar este sheet, así que llama
/// directo a `ingestProvider` con su propio `ref` al aceptar.
class AudioRecorderSheet extends ConsumerWidget {
  const AudioRecorderSheet({
    super.key,
    this.contactId,
    this.policyId,
    this.reminderId,
    this.makeGeneral = false,
  });

  final String? contactId;
  final String? policyId;
  final String? reminderId;
  final bool makeGeneral;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(audioRecorderProvider);
    final notifier = ref.read(audioRecorderProvider.notifier);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
            AmDimens.screenH, 14, AmDimens.screenH, 32),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: AmDimens.gapM),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Text(
              l10n.feedRecorderTitle,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface),
            ),
            const SizedBox(height: AmDimens.gapL),
            switch (state.phase) {
              RecorderPhase.permissionDenied =>
                _PermissionDenied(l10n: l10n, cs: cs),
              RecorderPhase.recording =>
                _Recording(state: state, l10n: l10n, cs: cs),
              RecorderPhase.recorded ||
              RecorderPhase.playing =>
                _Recorded(state: state, l10n: l10n, cs: cs),
              RecorderPhase.idle => _Idle(l10n: l10n, cs: cs),
            },
            const SizedBox(height: AmDimens.gapL),
            _Actions(
              state: state,
              notifier: notifier,
              l10n: l10n,
              cs: cs,
              onAccept: (file, fileName) =>
                  ref.read(ingestProvider.notifier).processKnowledgeFile(
                        file,
                        fileName,
                        contactId: contactId,
                        policyId: policyId,
                        reminderId: reminderId,
                        makeGeneral: makeGeneral,
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Idle extends StatelessWidget {
  const _Idle({required this.l10n, required this.cs});
  final AppLocalizations l10n;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.mic_none_outlined, size: 56, color: cs.tertiary),
        const SizedBox(height: AmDimens.gapS),
        Text(l10n.feedRecorderTapToStart,
            style: TextStyle(fontSize: 14, color: cs.tertiary)),
      ],
    );
  }
}

class _Recording extends StatelessWidget {
  const _Recording({required this.state, required this.l10n, required this.cs});
  final RecorderState state;
  final AppLocalizations l10n;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AmplitudeBars(amplitudes: state.amplitudeBars, color: cs.error),
        const SizedBox(height: AmDimens.gapS),
        Text(
          fmtElapsed(state.elapsed),
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w700, color: cs.onSurface),
        ),
        const SizedBox(height: 4),
        Text(l10n.feedRecorderRecording,
            style: TextStyle(fontSize: 13, color: cs.error)),
      ],
    );
  }
}

class _Recorded extends StatelessWidget {
  const _Recorded({required this.state, required this.l10n, required this.cs});
  final RecorderState state;
  final AppLocalizations l10n;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final playing = state.phase == RecorderPhase.playing;
    return Column(
      children: [
        Icon(Icons.graphic_eq, size: 40, color: cs.primary),
        const SizedBox(height: AmDimens.gapS),
        Text(
          fmtElapsed(state.elapsed),
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w700, color: cs.onSurface),
        ),
        const SizedBox(height: 4),
        Text(
          playing ? l10n.feedRecorderPlaying : l10n.feedRecorderReady,
          style: TextStyle(fontSize: 13, color: cs.tertiary),
        ),
      ],
    );
  }
}

class _PermissionDenied extends StatelessWidget {
  const _PermissionDenied({required this.l10n, required this.cs});
  final AppLocalizations l10n;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.mic_off_outlined, size: 40, color: cs.error),
        const SizedBox(height: AmDimens.gapS),
        Text(
          l10n.feedRecorderPermissionDenied,
          style: TextStyle(fontSize: 14, color: cs.onSurface),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Barras animadas reactivas a la amplitud del micrófono — no es un
/// osciloscopio real, solo feedback visual de que se está captando audio.
/// Cada valor de [amplitudes] ya viene con su propio jitter independiente
/// (ver `AudioRecorderNotifier.start`), por eso no se aplica ningún peso
/// fijo aquí — mostrarlas tal cual es lo que da el look de ecualizador.
class _AmplitudeBars extends StatelessWidget {
  const _AmplitudeBars({required this.amplitudes, required this.color});
  final List<double> amplitudes;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < amplitudes.length; i++) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 6,
              height: 6 + (34 * amplitudes[i]),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            if (i != amplitudes.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.state,
    required this.notifier,
    required this.l10n,
    required this.cs,
    required this.onAccept,
  });

  final RecorderState state;
  final AudioRecorderNotifier notifier;
  final AppLocalizations l10n;
  final ColorScheme cs;
  final void Function(File file, String fileName) onAccept;

  @override
  Widget build(BuildContext context) {
    switch (state.phase) {
      case RecorderPhase.permissionDenied:
        return SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: openAppSettings,
            style: FilledButton.styleFrom(
              backgroundColor: AmColors.accent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(l10n.feedRecorderOpenSettings,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        );

      case RecorderPhase.idle:
        return _RecordButton(recording: false, cs: cs, onTap: notifier.start);

      case RecorderPhase.recording:
        return _RecordButton(recording: true, cs: cs, onTap: notifier.stop);

      case RecorderPhase.recorded:
      case RecorderPhase.playing:
        final playing = state.phase == RecorderPhase.playing;
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: notifier.discard,
                icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
                label: Text(l10n.feedRecorderDiscard,
                    style: TextStyle(
                        color: cs.error, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: cs.error.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: notifier.togglePlay,
                icon: Icon(playing ? Icons.pause : Icons.play_arrow,
                    size: 20, color: cs.primary),
                label: Text(
                    playing ? l10n.feedRecorderPause : l10n.feedRecorderPlay,
                    style: TextStyle(
                        color: cs.primary, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: cs.outlineVariant),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  final path = state.filePath;
                  if (path == null) return;
                  final fileName = 'Nota de voz ${fmtDate(DateTime.now())}.m4a';
                  Navigator.of(context).pop();
                  onAccept(File(path), fileName);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AmColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(l10n.feedRecorderAccept,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        );
    }
  }
}

class _RecordButton extends StatelessWidget {
  const _RecordButton(
      {required this.recording, required this.cs, required this.onTap});
  final bool recording;
  final ColorScheme cs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: recording ? cs.error : AmColors.accent,
            // BoxShape.circle no puede combinarse con borderRadius —
            // AnimatedContainer no puede interpolar entre ambos (assertion
            // error a mitad de la animación). Círculo = borderRadius de la
            // mitad del lado, así ambos estados usan la misma propiedad.
            borderRadius: BorderRadius.circular(recording ? 18 : 36),
            boxShadow: [
              BoxShadow(
                color: (recording ? cs.error : AmColors.accent)
                    .withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            recording ? Icons.stop_rounded : Icons.mic,
            color: Colors.white,
            size: recording ? 28 : 30,
          ),
        ),
      ),
    );
  }
}
