import 'dart:async';
import 'package:Lore/artifact.dart';
import 'package:Lore/remark.dart';

/// Authentication result from a backend provider
class AuthResult {
  final bool success;
  final String? userId;
  final String? email;
  final String? error;
  final Map<String, dynamic>? metadata;

  AuthResult({
    required this.success,
    this.userId,
    this.email,
    this.error,
    this.metadata,
  });
}

/// Configuration for backend initialization
class BackendConfig {
  final String type; // 'firebase', 'supabase', 'local'
  final Map<String, dynamic> config;

  BackendConfig({
    required this.type,
    required this.config,
  });

  factory BackendConfig.firebase({
    required String projectId,
    required String apiKey,
    String? authDomain,
  }) {
    return BackendConfig(
      type: 'firebase',
      config: {
        'project_id': projectId,
        'api_key': apiKey,
        'auth_domain': authDomain,
      },
    );
  }

  factory BackendConfig.supabase({
    required String url,
    required String anonKey,
  }) {
    return BackendConfig(
      type: 'supabase',
      config: {
        'url': url,
        'anon_key': anonKey,
      },
    );
  }

  factory BackendConfig.local({
    String dbPath = '~/.lore/local.db',
  }) {
    return BackendConfig(
      type: 'local',
      config: {
        'db_path': dbPath,
      },
    );
  }
}

/// Abstract interface for Lore backend implementations
///
/// This allows the Lore app to work with multiple database backends
/// including Firebase, Supabase, local SQLite, or any future provider.
abstract class LoreBackend {
  /// Initialize the backend with the given configuration
  Future<void> initialize(BackendConfig config);

  /// Check if the backend is properly initialized and connected
  Future<bool> isConnected();

  /// Get current user ID if authenticated, null otherwise
  String? get currentUserId;

  /// Get current user email if authenticated, null otherwise
  String? get currentUserEmail;

  /// Load an artifact by its MD5 hash
  /// Returns null if not found
  Future<Artifact?> loadArtifact(String md5);

  /// Load all remarks for a given MD5 hash
  /// Returns empty list if none found
  Future<List<Remark>> loadRemarks({required String md5sum});

  /// Save a new remark for an artifact
  Future<void> saveRemark({
    required String remark,
    required String md5sum,
    required String userId,
  });

  /// Load favorite artifacts for a specific user
  Future<List<Artifact>> loadFavoritesArtifacts({required String userId});

  /// Authenticate with an external provider (GitHub, Google, etc.)
  /// Returns authentication result
  Future<AuthResult> authenticateWithProvider(String provider);

  /// Authenticate with email/password
  Future<AuthResult> authenticateWithEmail(String email, String password);

  /// Sign out current user
  Future<void> signOut();

  /// Get authentication URL for web-based login
  /// Used by console app for browser-based authentication
  Future<String> getAuthUrl({
    required String provider,
    String? redirectUrl,
  });

  /// Process authentication callback (for web-based flows)
  Future<AuthResult> handleAuthCallback(String callbackData);

  /// Clean up resources and close connections
  Future<void> dispose();

  /// Get backend type identifier
  String get backendType;

  /// Get human-readable backend name
  String get backendName;

  /// Check if backend supports real-time updates
  bool get supportsRealtime;

  /// Subscribe to real-time updates for artifacts (if supported)
  Stream<Artifact>? subscribeToArtifactUpdates(String md5);

  /// Subscribe to real-time updates for remarks (if supported)
  Stream<List<Remark>>? subscribeToRemarkUpdates(String md5);
}

/// Factory for creating backend instances
class LoreBackendFactory {
  static LoreBackend create(BackendConfig config) {
    switch (config.type.toLowerCase()) {
      case 'firebase':
        // return FirebaseBackend();
        throw UnimplementedError('Firebase backend not yet implemented');

      case 'supabase':
        // return SupabaseBackend();
        throw UnimplementedError('Supabase backend not yet implemented');

      case 'local':
        // return LocalBackend();
        throw UnimplementedError('Local backend not yet implemented');

      case 'mock':
        // return MockBackend();
        throw UnimplementedError('Mock backend not yet implemented');

      default:
        throw ArgumentError('Unknown backend type: ${config.type}');
    }
  }

  /// Get list of available backend types
  static List<String> get availableBackends => [
        'firebase',
        'supabase',
        'local',
        'mock',
      ];
}

/// Exception thrown when backend operations fail
class LoreBackendException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  LoreBackendException(this.message, {this.code, this.originalError});

  @override
  String toString() {
    if (code != null) {
      return 'LoreBackendException [$code]: $message';
    }
    return 'LoreBackendException: $message';
  }
}
