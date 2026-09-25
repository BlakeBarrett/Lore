import 'package:Lore/artifact.dart';
import 'package:Lore/remark.dart';

/// Data-access seam for all Lore persistence and auth state.
///
/// Implementations MUST throw on backend failure (no silent error swallowing)
/// so callers can decide how to surface errors. The concrete Supabase
/// implementation lives in [SupabaseLoreRepo] (`lib/repo/supabase_lore_repo.dart`);
/// tests inject a generated mock instead.
abstract class LoreRepo {
  Future<Artifact?> loadArtifact(String md5sum);

  Future<void> saveArtifact(Artifact artifact);

  Future<List<Remark>> loadRemarks({required String md5sum});

  Future<void> saveRemark({
    required String remark,
    required String? md5sum,
    required String? userId,
  });

  Future<void> deleteRemark({required Remark remark});

  Future<void> addToFavorites({
    required Artifact? artifact,
    required String? userId,
  });

  Future<void> removeFromFavorites({
    required Artifact? artifact,
    required String? userId,
  });

  Future<List<Artifact>> loadFavoritesArtifacts({required String? userId});

  /// Exchanges a JWT recovery token for a session; returns the signed-in
  /// user's e-mail address. Throws if the token is invalid.
  Future<String?> loginWithJwt(String jwt);

  String? get userId;

  String? get userEmail;

  String? get accessToken;
}
