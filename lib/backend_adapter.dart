import 'dart:io';
import 'package:Lore/lore_backend.dart';
import 'package:Lore/supabase_service.dart';
import 'package:Lore/artifact.dart';
import 'package:Lore/remark.dart';

/// Adapter that wraps the existing Supabase implementation
/// to conform to the new LoreBackend interface.
///
/// This allows gradual migration to the new architecture
/// while maintaining compatibility with existing code.
class SupabaseBackendAdapter implements LoreBackend {
  @override
  String get backendType => 'supabase';

  @override
  String get backendName => 'Supabase (Legacy Adapter)';

  @override
  bool get supportsRealtime => true;

  @override
  String? get currentUserId {
    try {
      return SupabaseService.instance.client.auth.currentUser?.id;
    } catch (e) {
      return null;
    }
  }

  @override
  String? get currentUserEmail {
    try {
      return SupabaseService.instance.client.auth.currentUser?.email;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> initialize(BackendConfig config) async {
    if (config.type != 'supabase') {
      throw LoreBackendException(
          'Invalid config type for Supabase backend: ${config.type}');
    }

    try {
      // The existing SupabaseService handles initialization
      await SupabaseService.instance.initializeForConsole();
    } catch (e) {
      throw LoreBackendException(
        'Failed to initialize Supabase backend',
        originalError: e,
      );
    }
  }

  @override
  Future<bool> isConnected() async {
    try {
      // Test connection by attempting a simple query
      final response = await SupabaseService.instance.client
          .from('artifacts')
          .select('id')
          .limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Artifact?> loadArtifact(String md5) async {
    try {
      // Use existing LoreAPI implementation
      // This would need to be refactored to use SupabaseService directly
      throw UnimplementedError(
          'loadArtifact needs to be migrated from LoreAPI');
    } catch (e) {
      throw LoreBackendException('Failed to load artifact', originalError: e);
    }
  }

  @override
  Future<List<Remark>> loadRemarks({required String md5sum}) async {
    try {
      // Use existing LoreAPI implementation
      throw UnimplementedError('loadRemarks needs to be migrated from LoreAPI');
    } catch (e) {
      throw LoreBackendException('Failed to load remarks', originalError: e);
    }
  }

  @override
  Future<void> saveRemark({
    required String remark,
    required String md5sum,
    required String userId,
  }) async {
    try {
      // Use existing LoreAPI implementation
      throw UnimplementedError('saveRemark needs to be migrated from LoreAPI');
    } catch (e) {
      throw LoreBackendException('Failed to save remark', originalError: e);
    }
  }

  @override
  Future<List<Artifact>> loadFavoritesArtifacts(
      {required String userId}) async {
    try {
      // Use existing LoreAPI implementation
      throw UnimplementedError(
          'loadFavoritesArtifacts needs to be migrated from LoreAPI');
    } catch (e) {
      throw LoreBackendException('Failed to load favorites', originalError: e);
    }
  }

  @override
  Future<AuthResult> authenticateWithProvider(String provider) async {
    try {
      final response = await SupabaseService.instance.client.auth
          .signInWithOAuth(provider: provider);

      return AuthResult(
        success: response.user != null,
        userId: response.user?.id,
        email: response.user?.email,
        error: response.user == null ? 'Authentication failed' : null,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  @override
  Future<AuthResult> authenticateWithEmail(
      String email, String password) async {
    try {
      final response = await SupabaseService.instance.client.auth
          .signInWithPassword(email: email, password: password);

      return AuthResult(
        success: response.user != null,
        userId: response.user?.id,
        email: response.user?.email,
        error: response.user == null ? 'Authentication failed' : null,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await SupabaseService.instance.client.auth.signOut();
    } catch (e) {
      throw LoreBackendException('Failed to sign out', originalError: e);
    }
  }

  @override
  Future<String> getAuthUrl({
    required String provider,
    String? redirectUrl,
  }) async {
    try {
      // Read Supabase URL from environment file directly
      String? supabaseUrl;
      final envFile = File('supabase.env');
      if (envFile.existsSync()) {
        final lines = await envFile.readAsLines();
        for (final line in lines) {
          if (line.startsWith('SUPABASE_URL=')) {
            supabaseUrl = line
                .split('=')[1]
                .replaceAll("'", "")
                .replaceAll('"', '')
                .trim();
            break;
          }
        }
      }

      if (supabaseUrl == null || supabaseUrl.isEmpty) {
        throw LoreBackendException('SUPABASE_URL not found in supabase.env');
      }

      final authUrl = '$supabaseUrl/auth/v1/authorize?provider=$provider';

      if (redirectUrl != null) {
        return '$authUrl&redirect_to=$redirectUrl';
      }

      return authUrl;
    } catch (e) {
      throw LoreBackendException('Failed to generate auth URL',
          originalError: e);
    }
  }

  @override
  Future<AuthResult> handleAuthCallback(String callbackData) async {
    try {
      // Parse JWT from callback and recover session
      final response = await SupabaseService.instance.client.auth
          .recoverSession(callbackData);

      return AuthResult(
        success: response.user != null,
        userId: response.user?.id,
        email: response.user?.email,
        error: response.user == null ? 'Session recovery failed' : null,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await SupabaseService.instance.dispose();
    } catch (e) {
      // Ignore disposal errors
    }
  }

  @override
  Stream<Artifact>? subscribeToArtifactUpdates(String md5) {
    try {
      return SupabaseService.instance.client
          .from('artifacts')
          .stream(primaryKey: ['md5sum'])
          .eq('md5sum', md5)
          .map((data) {
            if (data.isEmpty) return null;
            return Artifact.fromMap(data.first);
          })
          .where((artifact) => artifact != null)
          .cast<Artifact>();
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<List<Remark>>? subscribeToRemarkUpdates(String md5) {
    try {
      return SupabaseService.instance.client
          .from('remarks')
          .stream(primaryKey: ['id'])
          .eq('md5sum', md5)
          .map((data) => data.map((item) => Remark.fromMap(item)).toList());
    } catch (e) {
      return null;
    }
  }
}

/// Factory method to create a working backend instance
/// based on current configuration
LoreBackend createDefaultBackend() {
  // For now, return the Supabase adapter
  // In the future, this could read from configuration files
  // to determine which backend to use
  return SupabaseBackendAdapter();
}

/// Configuration loader that reads from various sources
class BackendConfigLoader {
  /// Load configuration from supabase.env file (legacy)
  static Future<BackendConfig?> loadSupabaseConfig() async {
    try {
      final envFile = File('supabase.env');
      if (!envFile.existsSync()) return null;

      final content = await envFile.readAsString();
      final lines = content.split('\n');

      String? url;
      String? anonKey;

      for (final line in lines) {
        if (line.startsWith('SUPABASE_URL=')) {
          url = line.split('=')[1].replaceAll("'", "").replaceAll('"', '');
        } else if (line.startsWith('SUPABASE_ANON_KEY=')) {
          anonKey = line.split('=')[1].replaceAll("'", "").replaceAll('"', '');
        }
      }

      if (url != null && anonKey != null) {
        return BackendConfig.supabase(url: url, anonKey: anonKey);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Load configuration from backend_config.yaml (future)
  static Future<BackendConfig?> loadFromConfigFile() async {
    // TODO: Implement YAML configuration loading
    throw UnimplementedError('YAML config loading not yet implemented');
  }

  /// Load the best available configuration
  static Future<BackendConfig?> loadBestAvailable() async {
    // Try Supabase first (for backward compatibility)
    final supabaseConfig = await loadSupabaseConfig();
    if (supabaseConfig != null) return supabaseConfig;

    // Try YAML config file
    try {
      return await loadFromConfigFile();
    } catch (e) {
      // Fall back to local backend
      return BackendConfig.local();
    }
  }
}
