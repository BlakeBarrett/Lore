import 'package:Lore/artifact.dart';
import 'package:Lore/remark.dart';

/// Data-access seam for all Lore persistence and auth state.
///
/// Implementations MUST throw on backend failure (no silent error swallowing)
/// so callers can decide how to surface errors. The concrete Supabase
/// implementation lives in [SupabaseLoreRepo] (`lib/repo/supabase_lore_repo.dart`);
/// tests inject a generated mock instead.
abstract class LoreRepo {
  Future<Artifact?> loadArtifact(final String md5sum);

  Future<void> saveArtifact(final Artifact artifact);

  Future<List<Remark>> loadRemarks({required final String md5sum});

  Future<void> saveRemark({
    required final String remark,
    required final String? md5sum,
    required final String? userId,
  });

  Future<void> deleteRemark({required final Remark remark});

  Future<void> addToFavorites({
    required final Artifact? artifact,
    required final String? userId,
  });

  Future<void> removeFromFavorites({
    required final Artifact? artifact,
    required final String? userId,
  });

  Future<List<Artifact>> loadFavoritesArtifacts(
      {required final String? userId});

  /// Exchanges a JWT recovery token for a session; returns the signed-in
  /// user's e-mail address. Throws if the token is invalid.
  Future<String?> loginWithJwt(final String jwt);

  String? get userId;

  String? get userEmail;

  String? get accessToken;
}
