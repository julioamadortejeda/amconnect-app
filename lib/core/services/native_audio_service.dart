import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final nativeAudioServiceProvider = Provider<NativeAudioService>((ref) {
  final service = NativeAudioService();
  ref.onDispose(service.dispose);
  return service;
});

/// Dispositivo de salida de audio disponible durante la sesión de voz.
/// Contrato compartido iOS/Android — ver getAudioDevices en AudioManager.swift
/// y MainActivity.kt.
class AudioOutputDevice {
  const AudioOutputDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.selected,
  });

  final String id;

  /// Nombre del dispositivo tal como lo reporta el sistema (vacío para la
  /// bocina — la UI usa su propia etiqueta localizada según [type]).
  final String name;

  /// speaker | bluetooth | wired | other
  final String type;
  final bool selected;

  factory AudioOutputDevice.fromMap(Map<dynamic, dynamic> map) =>
      AudioOutputDevice(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        type: map['type'] as String? ?? 'other',
        selected: map['selected'] as bool? ?? false,
      );
}

class NativeAudioService {
  static const MethodChannel _audioControl =
      MethodChannel('com.amconnect/audio');
  static const EventChannel _audioInput =
      EventChannel('com.amconnect/audio_input');

  final _playbackFinishedController = StreamController<void>.broadcast();
  Stream<void> get onPlaybackFinished => _playbackFinishedController.stream;

  final _audioChunkController = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get onAudioChunk => _audioChunkController.stream;

  StreamSubscription? _audioSub;

  NativeAudioService() {
    _audioControl.setMethodCallHandler(_handleNativeCall);
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method == 'playbackFinished') {
      debugPrint('[NativeAudioService] Playback finished event from native.');
      _playbackFinishedController.add(null);
    } else if (call.method == 'nativeLog') {
      // Diagnóstico del engine de audio nativo (iOS no muestra print() de
      // Swift en la consola de flutter run con dispositivo físico).
      debugPrint('[VoiceAudio] ${call.arguments}');
    }
  }

  Future<void> startAudio() async {
    try {
      await _audioControl.invokeMethod<void>('startAudio');
      debugPrint('[NativeAudioService] Native mic stream started.');

      _audioSub?.cancel();
      _audioSub = _audioInput.receiveBroadcastStream().listen((dynamic data) {
        if (data is Uint8List) {
          _audioChunkController.add(data);
        }
      }, onError: (Object e) {
        debugPrint('[NativeAudioService] Mic input error: $e');
      });
    } catch (e) {
      debugPrint('[NativeAudioService] startAudio error: $e');
      rethrow;
    }
  }

  Future<void> stopAudio() async {
    try {
      await _audioSub?.cancel();
      _audioSub = null;
      await _audioControl.invokeMethod<void>('stopAudio');
      debugPrint('[NativeAudioService] Native mic stream stopped.');
    } catch (e) {
      debugPrint('[NativeAudioService] stopAudio error: $e');
    }
  }

  Future<void> playPcm(String base64PcmAudio) async {
    if (base64PcmAudio.isEmpty) return;
    try {
      await _audioControl
          .invokeMethod<void>('playPcm', {'data': base64PcmAudio});
    } catch (e) {
      debugPrint('[NativeAudioService] playPcm error: $e');
    }
  }

  Future<void> stopPlayback() async {
    try {
      await _audioControl.invokeMethod<void>('stopPlayback');
      debugPrint('[NativeAudioService] Native audio playback stopped.');
    } catch (e) {
      debugPrint('[NativeAudioService] stopPlayback error: $e');
    }
  }

  /// Dispositivos de salida disponibles para la sesión de voz activa.
  Future<List<AudioOutputDevice>> getAudioDevices() async {
    try {
      final res =
          await _audioControl.invokeMethod<List<dynamic>>('getAudioDevices');
      return (res ?? [])
          .whereType<Map<dynamic, dynamic>>()
          .map(AudioOutputDevice.fromMap)
          .toList();
    } catch (e) {
      debugPrint('[NativeAudioService] getAudioDevices error: $e');
      return const [];
    }
  }

  /// Fuerza la entrada al micrófono integrado. Solo iOS hoy; en Android es un
  /// no-op silencioso (`MissingPluginException` capturado abajo).
  ///
  /// Lo usa el dictado: `speech_to_text` configura la sesión de audio con
  /// A2DP permitido y sin forma de cambiarlo, y con audífonos Bluetooth eso
  /// deja el mic en una ruta que no captura. Ver `useBuiltInMic` en
  /// AudioManager.swift.
  Future<void> useBuiltInMic() async {
    try {
      await _audioControl.invokeMethod<void>('useBuiltInMic');
    } catch (e) {
      debugPrint('[NativeAudioService] useBuiltInMic error: $e');
    }
  }

  /// Cambia la salida (y el mic asociado) de la sesión de voz. El nativo se
  /// encarga del re-ruteo; en iOS el cambio de ruta reconstruye el engine.
  Future<void> selectAudioDevice(String id) async {
    try {
      await _audioControl.invokeMethod<void>('selectAudioDevice', {'id': id});
    } catch (e) {
      debugPrint('[NativeAudioService] selectAudioDevice error: $e');
    }
  }

  void dispose() {
    _audioSub?.cancel();
    _playbackFinishedController.close();
    _audioChunkController.close();
  }
}
