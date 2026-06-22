import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SttState {
  final bool isAvailable;
  final bool isListening;
  final String transcript;
  final bool isFinal;
  final String? error;

  const SttState({
    this.isAvailable = false,
    this.isListening = false,
    this.transcript = '',
    this.isFinal = false,
    this.error,
  });

  SttState copyWith({
    bool? isAvailable,
    bool? isListening,
    String? transcript,
    bool? isFinal,
    String? error,
    bool clearError = false,
  }) =>
      SttState(
        isAvailable: isAvailable ?? this.isAvailable,
        isListening: isListening ?? this.isListening,
        transcript: transcript ?? this.transcript,
        isFinal: isFinal ?? this.isFinal,
        error: clearError ? null : (error ?? this.error),
      );
}

class SttNotifier extends Notifier<SttState> {
  final _speech = SpeechToText();

  @override
  SttState build() => const SttState();

  Future<bool> _initialize() async {
    final available = await _speech.initialize(
      onError: (err) {
        debugPrint('[STT] error: ${err.errorMsg} permanent=${err.permanent}');
        state = state.copyWith(isListening: false, error: err.errorMsg);
      },
      onStatus: (status) {
        debugPrint('[STT] status: $status');
        if (status == 'done' || status == 'notListening') {
          state = state.copyWith(isListening: false);
        }
      },
    );
    debugPrint('[STT] initialize → available=$available');
    state = state.copyWith(isAvailable: available);
    return available;
  }

  Future<void> startListening() async {
    // Siempre limpiar estado anterior antes de intentar
    state = state.copyWith(transcript: '', isFinal: false, clearError: true);

    final available = state.isAvailable ? true : await _initialize();
    if (!available) return;

    state = state.copyWith(isListening: true);

    await _speech.listen(
      onResult: (result) {
        state = state.copyWith(
          transcript: result.recognizedWords,
          isFinal: result.finalResult,
          isListening: !result.finalResult,
        );
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        pauseFor: Duration(seconds: 2),
      ),
    );
  }

  Future<void> stop() async {
    await _speech.stop();
    state = state.copyWith(isListening: false);
  }

  Future<void> cancel() async {
    await _speech.cancel();
    final wasAvailable = state.isAvailable;
    state = SttState(isAvailable: wasAvailable);
  }

  void clear() => state = state.copyWith(
        transcript: '',
        isFinal: false,
        clearError: true,
      );
}

final sttProvider = NotifierProvider<SttNotifier, SttState>(SttNotifier.new);
