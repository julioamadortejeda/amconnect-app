import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/audio_playback_service.dart';
import '../../../core/services/audio_recorder_service.dart';

enum RecorderPhase { idle, permissionDenied, recording, recorded, playing }

const kAudioRecorderBarCount = 5;

class RecorderState {
  RecorderState({
    this.phase = RecorderPhase.idle,
    this.elapsed = Duration.zero,
    List<double>? amplitudeBars,
    this.filePath,
  }) : amplitudeBars =
            amplitudeBars ?? List.filled(kAudioRecorderBarCount, 0.0);

  final RecorderPhase phase;
  final Duration elapsed;

  /// 0.0–1.0 por barra, actualizada mientras se graba — anima la
  /// visualización. Cada barra reacciona de forma ligeramente independiente
  /// a la misma amplitud del micrófono (ver `AudioRecorderNotifier`), para
  /// que se vea como un ecualizador real y no un bloque simétrico rígido.
  final List<double> amplitudeBars;
  final String? filePath;

  RecorderState copyWith({
    RecorderPhase? phase,
    Duration? elapsed,
    List<double>? amplitudeBars,
    String? filePath,
  }) =>
      RecorderState(
        phase: phase ?? this.phase,
        elapsed: elapsed ?? this.elapsed,
        amplitudeBars: amplitudeBars ?? this.amplitudeBars,
        filePath: filePath ?? this.filePath,
      );
}

/// Estado de la grabadora de notas de voz para el flujo de ingesta —
/// `autoDispose` porque es puramente efímero al sheet que la muestra.
class AudioRecorderNotifier extends Notifier<RecorderState> {
  late AudioRecorderService _recorder;
  late AudioPlaybackService _player;
  Timer? _ticker;
  StreamSubscription<double>? _ampSub;
  StreamSubscription<void>? _completeSub;
  DateTime? _startedAt;

  // Espejos planos de `state` para el callback de `ref.onDispose` —
  // Riverpod prohíbe leer/escribir `state` (pasa por `Ref`) dentro de
  // callbacks de ciclo de vida, incluso solo para lectura.
  bool _isRecording = false;
  String? _filePath;
  final _random = Random();
  List<double> _bars = List.filled(kAudioRecorderBarCount, 0.0);

  @override
  RecorderState build() {
    _recorder = ref.read(audioRecorderServiceProvider);
    _player = ref.read(audioPlaybackServiceProvider);
    _completeSub = _player.onComplete.listen((_) {
      if (state.phase == RecorderPhase.playing) {
        state = state.copyWith(phase: RecorderPhase.recorded);
      }
    });
    ref.onDispose(() {
      _ticker?.cancel();
      _ampSub?.cancel();
      _completeSub?.cancel();
      if (_isRecording) {
        _recorder.cancel();
      } else if (_filePath != null) {
        _player.stop();
      }
    });
    return RecorderState();
  }

  Future<void> start() async {
    final granted = await _recorder.hasPermission();
    if (!granted) {
      state = state.copyWith(phase: RecorderPhase.permissionDenied);
      return;
    }
    await _recorder.start();
    _isRecording = true;
    _startedAt = DateTime.now();
    _bars = List.filled(kAudioRecorderBarCount, 0.0);
    state = RecorderState(phase: RecorderPhase.recording);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsed: DateTime.now().difference(_startedAt!));
    });
    _ampSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 150))
        .listen((a) {
      // Cada barra reacciona a una fracción distinta de la misma amplitud
      // (con un poco de suavizado contra su valor anterior) para que se
      // vea como un ecualizador real en vez de un bloque simétrico rígido
      // que sube y baja entero en cada muestra.
      _bars = List.generate(kAudioRecorderBarCount, (i) {
        final jitter = 0.35 + _random.nextDouble() * 0.65;
        final target = (a * jitter).clamp(0.0, 1.0);
        return (_bars[i] * 0.35 + target * 0.65).clamp(0.0, 1.0);
      });
      state = state.copyWith(amplitudeBars: List.of(_bars));
    });
  }

  Future<void> stop() async {
    _ticker?.cancel();
    await _ampSub?.cancel();
    final path = await _recorder.stop();
    _isRecording = false;
    _filePath = path;
    state = state.copyWith(
      phase: RecorderPhase.recorded,
      filePath: path,
      amplitudeBars: List.filled(kAudioRecorderBarCount, 0.0),
    );
  }

  Future<void> discard() async {
    _ticker?.cancel();
    await _ampSub?.cancel();
    if (_isRecording) {
      await _recorder.cancel();
    } else if (_filePath != null) {
      await _player.stop();
      await _recorder.deleteFile(_filePath!);
    }
    _isRecording = false;
    _filePath = null;
    state = RecorderState();
  }

  Future<void> togglePlay() async {
    final path = state.filePath;
    if (path == null) return;
    if (state.phase == RecorderPhase.playing) {
      await _player.pause();
      state = state.copyWith(phase: RecorderPhase.recorded);
    } else {
      state = state.copyWith(phase: RecorderPhase.playing);
      await _player.playFile(path);
    }
  }
}

final audioRecorderProvider =
    NotifierProvider.autoDispose<AudioRecorderNotifier, RecorderState>(
        AudioRecorderNotifier.new);
