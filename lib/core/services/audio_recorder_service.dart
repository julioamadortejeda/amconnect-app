import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Graba notas de voz a un archivo M4A local — usado por el flujo de
/// ingesta (Feed / adjuntar a recordatorio) para "Grabar audio".
class AudioRecorderService {
  final _recorder = AudioRecorder();

  Future<bool> hasPermission() => _recorder.hasPermission();

  /// Arranca la grabación en un archivo temporal nuevo y devuelve su ruta.
  Future<String> start() async {
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path);
    return path;
  }

  Future<String?> stop() => _recorder.stop();

  /// Detiene y borra el archivo — usado al descartar una grabación en curso.
  Future<void> cancel() => _recorder.cancel();

  /// Amplitud normalizada 0.0–1.0 (el dBFS crudo del plugin va de -160 a 0;
  /// -50dB para abajo es prácticamente silencio de micrófono ambiente).
  Stream<double> onAmplitudeChanged(Duration interval) {
    return _recorder.onAmplitudeChanged(interval).map((a) {
      final normalized = (a.current + 50) / 50;
      return normalized.clamp(0.0, 1.0);
    });
  }

  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  Future<void> dispose() => _recorder.dispose();
}

final audioRecorderServiceProvider = Provider<AudioRecorderService>((ref) {
  final service = AudioRecorderService();
  ref.onDispose(service.dispose);
  return service;
});
