import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SttState {
  final bool isAvailable;
  final bool isListening;
  final String transcript;
  final bool isFinal;
  final String? error;
  final bool permanentlyDenied;

  const SttState({
    this.isAvailable = false,
    this.isListening = false,
    this.transcript = '',
    this.isFinal = false,
    this.error,
    this.permanentlyDenied = false,
  });

  SttState copyWith({
    bool? isAvailable,
    bool? isListening,
    String? transcript,
    bool? isFinal,
    String? error,
    bool clearError = false,
    bool? permanentlyDenied,
  }) =>
      SttState(
        isAvailable: isAvailable ?? this.isAvailable,
        isListening: isListening ?? this.isListening,
        transcript: transcript ?? this.transcript,
        isFinal: isFinal ?? this.isFinal,
        error: clearError ? null : (error ?? this.error),
        permanentlyDenied: permanentlyDenied ?? this.permanentlyDenied,
      );
}

class SttNotifier extends Notifier<SttState> {
  final _speech = SpeechToText();

  @override
  SttState build() => const SttState();

  // speech_to_text pide DOS permisos por separado en iOS (micrófono +
  // reconocimiento de voz). Además, tras una negación previa, `initialize()`
  // puede devolver `available: true` sin que el permiso real esté concedido
  // (queda "escuchando" pero no oye nada) — por eso el estado del permiso se
  // revisa aparte con permission_handler, en vez de confiar solo en ese bool.
  Future<bool> _checkPermanentlyDenied() async {
    final micStatus = await Permission.microphone.status;
    final speechStatus = await Permission.speech.status;
    final denied = micStatus.isPermanentlyDenied || speechStatus.isPermanentlyDenied;
    state = state.copyWith(permanentlyDenied: denied);
    return denied;
  }

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

    if (!available) await _checkPermanentlyDenied();

    return available;
  }

  Future<void> startListening() async {
    // Siempre limpiar estado anterior antes de intentar
    state = state.copyWith(transcript: '', isFinal: false, clearError: true);

    // Chequeo proactivo: si el permiso ya está negado permanentemente, ni
    // siquiera intentamos inicializar/escuchar (evita el falso "escuchando").
    if (await _checkPermanentlyDenied()) return;

    final available = state.isAvailable ? true : await _initialize();
    if (!available) return;

    state = state.copyWith(isListening: true, permanentlyDenied: false);

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
        // El asesor siempre habla en español, sin importar el idioma del
        // sistema del teléfono — sin esto, speech_to_text usa el locale del
        // device y transcribe mal palabras en español si está en inglés.
        localeId: 'es-MX',
      ),
    );
  }

  Future<void> stop() async {
    await _speech.stop();
    state = state.copyWith(isListening: false);
  }

  Future<void> cancel() async {
    await _speech.cancel();
    state = SttState(
      isAvailable: state.isAvailable,
      permanentlyDenied: state.permanentlyDenied,
    );
  }

  void clear() => state = state.copyWith(
        transcript: '',
        isFinal: false,
        clearError: true,
      );
}

final sttProvider = NotifierProvider<SttNotifier, SttState>(SttNotifier.new);
