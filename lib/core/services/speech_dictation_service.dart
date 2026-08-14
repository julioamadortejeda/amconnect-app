import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'native_audio_service.dart';

final speechDictationServiceProvider = Provider<SpeechDictationService>((ref) {
  final service = SpeechDictationService(ref.read(nativeAudioServiceProvider));
  ref.onDispose(service.dispose);
  return service;
});

/// Códigos de error del dictado — se traducen con `context.translateError`.
const String kDictationPermissionDenied = 'MIC_PERMISSION_DENIED';
const String kDictationUnavailable = 'SPEECH_UNAVAILABLE';

sealed class DictationEvent {
  const DictationEvent();
}

/// Texto reconocido hasta ahora. Es acumulado, no un delta.
class DictationPartial extends DictationEvent {
  final String text;
  const DictationPartial(this.text);
}

/// La sesión terminó. Llega igual si el asesor tocó stop que si la plataforma
/// cortó sola por silencio o por límite de tiempo — el Notifier no tiene que
/// distinguir.
class DictationFinished extends DictationEvent {
  final String text;
  const DictationFinished(this.text);
}

class DictationFailed extends DictationEvent {
  final String code;
  const DictationFailed(this.code);
}

/// Dictado por voz on-device (STT del sistema): audio → texto en el campo.
///
/// No es lo mismo que [GeminiVoiceEngine]: aquí no hay WebSocket, ni modelo,
/// ni tokens. El audio no sale del teléfono, solo el texto viaja después por
/// el `POST /ai/chat` de siempre. Por eso también es gratis: la conversación
/// Live cobra el audio a ~25 tokens/segundo y recobra el contexto en cada
/// turno; esto no cuesta ni un token.
///
/// Los dos NUNCA pueden estar activos a la vez — se pelean el micrófono. El
/// candado vive en `AssistantNotifier`.
class SpeechDictationService {
  SpeechDictationService(this._audio);

  final NativeAudioService _audio;
  final SpeechToText _speech = SpeechToText();
  final StreamController<DictationEvent> _events =
      StreamController<DictationEvent>.broadcast();
  final ValueNotifier<double> _level = ValueNotifier<double>(0.0);

  bool _initialized = false;
  bool _sessionClosed = true;
  String _lastWords = '';

  /// Piso y techo observados del nivel de audio, para normalizar a 0..1.
  /// Ver [_onSoundLevel] — cada plataforma manda una escala distinta.
  double _floor = double.infinity;
  double _ceiling = double.negativeInfinity;

  Timer? _fallbackDelay;
  Timer? _syntheticLevel;
  bool _levelReported = false;

  Stream<DictationEvent> get events => _events.stream;

  /// Nivel de voz 0..1 para la onda del composer. Expuesto como
  /// [ValueListenable] y no dentro del estado del provider porque cambia
  /// decenas de veces por segundo y no debe reconstruir la pantalla.
  ValueListenable<double> get level => _level;

  bool get isListening => _speech.isListening;

  /// Arranca una sesión de dictado en [languageCode] ('es', 'en'…).
  ///
  /// La primera vez pide el permiso de micrófono y de reconocimiento de voz;
  /// las siguientes ya no. Si algo falla emite [DictationFailed] en vez de
  /// lanzar, para que el Notifier lo trate igual que cualquier otro error.
  Future<void> start(String languageCode) async {
    if (_speech.isListening) return;

    if (!_initialized) {
      try {
        _initialized = await _speech.initialize(
          onStatus: _onStatus,
          onError: _onError,
        );
      } catch (_) {
        _initialized = false;
      }
      if (!_initialized) {
        final granted = await _speech.hasPermission.catchError((_) => false);
        _events.add(DictationFailed(
            granted ? kDictationUnavailable : kDictationPermissionDenied));
        return;
      }
    }

    _lastWords = '';
    _sessionClosed = false;
    _levelReported = false;
    _level.value = 0.0;

    // ANTES de `listen`, nunca después: el plugin instala su tap y arranca su
    // engine dentro de esa llamada, y en iOS ese tap no entrega un solo buffer
    // si la entrada es Bluetooth. Cambiar la ruta ya empezado tampoco sirve —
    // el tap se queda con un formato que ya no corresponde.
    await _audio.useBuiltInMic();

    try {
      await _speech.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          if (result.finalResult) {
            _finish();
          } else {
            _events.add(DictationPartial(_lastWords));
          }
        },
        onSoundLevelChange: _onSoundLevel,
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
          autoPunctuation: true,
          // Tres segundos de silencio cierran el dictado solo — el asesor no
          // tiene que acordarse de tocar stop. El tope de dos minutos es red
          // de seguridad por si el micrófono queda abierto en la bolsa.
          pauseFor: const Duration(seconds: 3),
          listenFor: const Duration(minutes: 2),
          localeId: await _resolveLocaleId(languageCode),
        ),
      );
    } catch (_) {
      _fail(kDictationUnavailable);
      return;
    }

    // Si en dos segundos la plataforma no reportó un solo nivel de audio, la
    // onda se quedaría plana y parecería que no está oyendo. Ahí se cambia a
    // una animación decorativa: miente sobre el volumen, no sobre el estado.
    _fallbackDelay = Timer(const Duration(seconds: 2), () {
      if (!_levelReported && !_sessionClosed) _startSyntheticLevel();
    });
  }

  /// Cierra la sesión y entrega el texto final vía [DictationFinished].
  Future<void> stop() async {
    if (_sessionClosed) {
      // La sesión todavía no alcanzó a abrirse (el permiso del sistema puede
      // tardar segundos). Hay que avisar igual: si no, la UI se queda en modo
      // dictado para siempre porque nunca llega un evento de cierre.
      _events.add(const DictationFinished(''));
      return;
    }
    try {
      await _speech.stop();
    } catch (_) {
      /* la sesión ya estaba cerrada por la plataforma */
    }
    _finish();
  }

  /// Aborta sin entregar texto ni emitir evento — para cuando el dictado se
  /// interrumpe por algo que el Notifier ya sabe (arrancar voz Live, salir de
  /// la pantalla).
  Future<void> cancel() async {
    _sessionClosed = true;
    _stopLevelTimers();
    _level.value = 0.0;
    _lastWords = '';
    try {
      await _speech.cancel();
    } catch (_) {
      /* nada que cancelar */
    }
  }

  void dispose() {
    _stopLevelTimers();
    _speech.cancel().catchError((_) {});
    _events.close();
    _level.dispose();
  }

  // ── Interno ────────────────────────────────────────────────────────────────

  /// Que no se oiga nada NO es un error que valga la pena mostrar: se cierra
  /// la sesión con lo que haya (normalmente vacío) y el campo queda como
  /// estaba. Solo el permiso negado y el reconocedor inservible se reportan.
  void _onError(SpeechRecognitionError error) {
    final msg = error.errorMsg.toLowerCase();
    if (msg.contains('no_match') || msg.contains('speech_timeout')) {
      _finish();
      return;
    }
    _fail(msg.contains('permission')
        ? kDictationPermissionDenied
        : kDictationUnavailable);
  }

  void _onStatus(String status) {
    // 'done' / 'notListening': la plataforma cerró la sesión por su cuenta
    // (silencio, timeout). Sin esto, un dictado sin una sola palabra dejaría
    // la UI en modo escuchando para siempre.
    if (status == 'done' || status == 'notListening') _finish();
  }

  void _finish() {
    if (_sessionClosed) return;
    _sessionClosed = true;
    _stopLevelTimers();
    _level.value = 0.0;
    _events.add(DictationFinished(_lastWords.trim()));
  }

  void _fail(String code) {
    if (_sessionClosed) return;
    _sessionClosed = true;
    _stopLevelTimers();
    _level.value = 0.0;
    _events.add(DictationFailed(code));
  }

  /// Normaliza el nivel crudo a 0..1 contra el rango realmente observado.
  ///
  /// Hace falta porque cada plataforma manda una escala distinta: Android
  /// entrega el `rmsdB` del reconocedor (≈ -2 a 10) y iOS entrega dBFS
  /// (≈ -60 a 0, y -infinito en silencio absoluto). Un mapeo fijo se vería
  /// bien en una y plano o saturado en la otra, así que el piso y el techo se
  /// aprenden solos: saltan de inmediato al ver un valor más extremo y se
  /// arrastran de vuelta despacio para adaptarse al ruido del lugar.
  void _onSoundLevel(double raw) {
    if (!raw.isFinite) return;
    _levelReported = true;
    _stopSyntheticLevel();

    _floor = raw < _floor ? raw : _floor + (raw - _floor) * 0.02;
    _ceiling = raw > _ceiling ? raw : _ceiling - (_ceiling - raw) * 0.02;

    final span = _ceiling - _floor;
    _level.value = span < 1.0 ? 0.0 : ((raw - _floor) / span).clamp(0.0, 1.0);
  }

  void _startSyntheticLevel() {
    // Se registra porque desde la pantalla la onda decorativa es idéntica a la
    // real: sin esta línea, "las barras se mueven" no dice si el micrófono
    // está entregando algo o no.
    debugPrint('[Dictation] Sin niveles de audio en 2 s — onda decorativa. '
        'El micrófono NO está reportando volumen.');
    _syntheticLevel?.cancel();
    var tick = 0;
    _syntheticLevel = Timer.periodic(const Duration(milliseconds: 90), (_) {
      tick++;
      _level.value = 0.35 + math.sin(tick * 0.35) * 0.18;
    });
  }

  void _stopSyntheticLevel() {
    _syntheticLevel?.cancel();
    _syntheticLevel = null;
  }

  void _stopLevelTimers() {
    _fallbackDelay?.cancel();
    _fallbackDelay = null;
    _stopSyntheticLevel();
  }

  /// El primer locale instalado que hable ese idioma. Devuelve null si no hay
  /// ninguno, y entonces la plataforma usa el suyo — mejor eso que forzar un
  /// 'es' pelón, que en algunos dispositivos hace fallar el reconocedor.
  Future<String?> _resolveLocaleId(String languageCode) async {
    try {
      final locales = await _speech.locales();
      for (final locale in locales) {
        final id = locale.localeId.replaceAll('-', '_');
        if (id.toLowerCase().startsWith('${languageCode.toLowerCase()}_')) {
          return locale.localeId;
        }
      }
    } catch (_) {
      /* sin lista de locales — que decida la plataforma */
    }
    return null;
  }
}
