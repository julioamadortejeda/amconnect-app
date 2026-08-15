import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL']!;
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY']!;
  // Sin fallback a localhost: un .env incompleto debe fallar en el arranque,
  // no apuntar silenciosamente a un backend local que no existe en release.
  static String get apiBaseUrl => dotenv.env['API_BASE_URL']!;

  /// 'live' (default) — Gemini Live API, WebSocket bidireccional, conversación fluida.
  /// 'turn_based' — walkie-talkie: STT on-device → texto → /ai/chat/tts → TTS.
  static String get voiceMode => dotenv.env['VOICE_MODE'] ?? 'live';
  static bool get isTurnBasedVoice => voiceMode == 'turn_based';
}
