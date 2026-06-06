import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL']!;
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY']!;
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:54321/functions/v1/amconnect-api';
}
