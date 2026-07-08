import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reproduce clips cortos de audio (WAV en base64) recibidos del backend —
/// usado por el chat de voz turn-based para la respuesta hablada de la IA.
class AudioPlaybackService {
  final _player = AudioPlayer();

  /// Reproduce el clip y espera a que TERMINE de sonar (no solo a que inicie
  /// — `AudioPlayer.play()` únicamente arranca la reproducción).
  ///
  /// `mimeType` es obligatorio en iOS: audioplayers_darwin escribe los bytes
  /// a un archivo temporal en caché sin extensión, y sin mimeType AVPlayer no
  /// puede determinar el tipo de archivo (falla con "Failed to set playerItem").
  Future<void> playBase64(String base64Audio, {required String mimeType}) async {
    final done = _player.onPlayerComplete.first;
    await _player.play(BytesSource(base64Decode(base64Audio), mimeType: mimeType));
    await done;
  }

  Future<void> stop() => _player.stop();

  void dispose() => _player.dispose();
}

final audioPlaybackServiceProvider = Provider<AudioPlaybackService>((ref) {
  final service = AudioPlaybackService();
  ref.onDispose(service.dispose);
  return service;
});
