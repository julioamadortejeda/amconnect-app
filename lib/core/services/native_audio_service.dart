import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final nativeAudioServiceProvider = Provider<NativeAudioService>((ref) {
  final service = NativeAudioService();
  ref.onDispose(service.dispose);
  return service;
});

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

  void dispose() {
    _audioSub?.cancel();
    _playbackFinishedController.close();
    _audioChunkController.close();
  }
}
