import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Reads Supabase configuration from the local `.env` file (never from
/// source code — see `.env.example` and `SUPABASE_SETUP.md`).
///
/// [load] must be awaited once, before anything else touches Supabase —
/// see `main.dart`.
class EnvConfig {
  static Future<void> load() => dotenv.load(fileName: '.env');

  static String get supabaseUrl => _require('SUPABASE_URL');
  static String get supabaseAnonKey => _require('SUPABASE_ANON_KEY');

  static String _require(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError(
        'Missing "$key" in .env. Copy .env.example to .env and fill in '
        'your Supabase project values (see SUPABASE_SETUP.md).',
      );
    }
    return value;
  }
}
