import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleKey = 'app_locale';

/// Idiomas que la app y el backend entienden (`agents.locale`).
const kSupportedLanguageCodes = ['es', 'en'];

/// Idioma efectivo de la app: el que eligió el asesor o, si no eligió, el del
/// dispositivo. Si el dispositivo está en un idioma no soportado Flutter cae al
/// primero de `supportedLocales` (en), así que aquí se resuelve igual.
String resolveLanguageCode(Locale? chosen, Locale device) {
  final code = (chosen ?? device).languageCode;
  return kSupportedLanguageCodes.contains(code) ? code : 'en';
}

/// Locale elegido a mano en Cuenta. `null` = seguir el idioma del dispositivo.
class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kLocaleKey);
      if (saved != null && kSupportedLanguageCodes.contains(saved)) {
        state = Locale(saved);
      }
    } catch (_) {
      // Sin preferencias se queda en el idioma del dispositivo.
    }
  }

  Future<void> setLanguage(String code) async {
    if (!kSupportedLanguageCodes.contains(code)) return;
    state = Locale(code);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLocaleKey, code);
    } catch (_) {
      // No interrumpir la UI por no poder persistir.
    }
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);
