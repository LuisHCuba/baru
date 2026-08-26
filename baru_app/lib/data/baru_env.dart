import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Lê URL/anon em runtime: `--dart-define` ganha de `.env` (asset), que ganha de `.env.example`.
/// Este código nunca imprime os valores.
class BaruEnv {
  BaruEnv._();

  static const _defineUrl = String.fromEnvironment('SUPABASE_URL');
  static const _defineAnon = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const _defineEnabled = String.fromEnvironment('SUPABASE_ENABLED');

  static Future<void> load() async {
    try {
      await dotenv.load(
        fileName: '.env.example',
        overrideWithFiles: const ['.env'],
        isOptional: true,
      );
    } catch (_) {}
  }

  static String get supabaseUrl {
    if (_defineUrl.isNotEmpty) return _defineUrl;
    return _dotenv('SUPABASE_URL');
  }

  static String get supabaseAnonKey {
    if (_defineAnon.isNotEmpty) return _defineAnon;
    return _dotenv('SUPABASE_ANON_KEY');
  }

  static String _dotenv(String key) {
    try {
      return dotenv.maybeGet(key) ?? '';
    } catch (_) {
      return '';
    }
  }

  static bool get isPlaceholder {
    final url = supabaseUrl;
    final anon = supabaseAnonKey;
    if (url.isEmpty || anon.isEmpty) return true;
    if (url.contains('YOUR_PROJECT')) return true;
    if (anon == 'your-anon-key') return true;
    return false;
  }

  /// Credenciais reais ligam o banco; `SUPABASE_ENABLED=false` desliga.
  ///
  /// Lido do `--dart-define` **e** do `.env`, nessa ordem. Antes só o define
  /// era consultado, então a linha no `.env` — que o próprio `.env.example`
  /// sugere — não fazia nada.
  static bool get supabaseEnabled {
    if (_defineEnabled.isNotEmpty) return _defineEnabled != 'false';
    if (_dotenv('SUPABASE_ENABLED').toLowerCase() == 'false') return false;
    return !isPlaceholder;
  }
}
