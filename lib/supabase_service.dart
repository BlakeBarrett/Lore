import 'package:supabase/supabase.dart';
// import 'package:dotenv/dotenv.dart'; // dotenv is no longer needed here
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

  /// Initialize for console applications.
  /// TODO: This should be replaced with initialization for the selected backend
  /// using the new abstraction layer.
  Future<void> initializeForConsole() async {
    // Configuration should be loaded by the new backend abstraction
    // and passed to the specific backend implementation (SupabaseBackendAdapter)
    // This console-specific initialization should be removed eventually.
    _client = SupabaseClient(
      'SUPABASE_URL_PLACEHOLDER', // Replace with actual value from config
      'SUPABASE_ANON_KEY_PLACEHOLDER', // Replace with actual value from config
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
