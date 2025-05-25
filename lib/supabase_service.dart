import 'package:supabase/supabase.dart';
import 'package:dotenv/dotenv.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseClient? _client;

  SupabaseService._();

  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  SupabaseClient get client {
    if (_client == null) {
      throw StateError(
          'SupabaseService not initialized. Call initialize() first.');
    }
    return _client!;
  }

  /// Initialize for console applications (using dotenv)
  Future<void> initializeForConsole() async {
    if (_client != null) return; // Already initialized

    final env = DotEnv(includePlatformEnvironment: true)
      ..load(['supabase.env']);

    _client = SupabaseClient(
      env['SUPABASE_URL']!,
      env['SUPABASE_ANON_KEY']!,
    );
  }

  /// Initialize for Flutter applications (using external client)
  void initializeForFlutter(SupabaseClient client) {
    _client = client;
  }

  /// Cleanup method to dispose of the client (important for console apps)
  Future<void> dispose() async {
    if (_client != null) {
      await _client!.dispose();
      _client = null;
    }
  }

  bool get isInitialized => _client != null;
}
