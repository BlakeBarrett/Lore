import 'package:lore/app_config.dart';
import 'package:lore/artifact.dart';
import 'package:lore/repo/lore_repo.dart';
import 'package:lore/remark.dart';
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:supabase_flutter/supabase_flutter.dart';

/// [LoreRepo] backed by Supabase. Owns all table names (`Artifacts`,
/// `Remarks`, `Favorites`) and the `getfavoriteartifactsfor` RPC.
///
/// Every call propagates backend failures to the caller — the old
/// `.catchError(debugPrint)` swallowing is intentionally gone.
class SupabaseLoreRepo implements LoreRepo {
  SupabaseLoreRepo(this.config);

  final AppConfig config;

  SupabaseClient get _client => config.supabase;

  /// Whether the live `Artifacts` schema has accepted the additive `sha256`
  /// column. Starts optimistically true; set false on the first PGRST204
  /// (unknown column) so we degrade to `{name, md5}` payloads instead of
  /// failing every artifact save. Self-heals on app restart once the column
  /// migration lands server-side.
  @visibleForTesting
  bool sha256ColumnSupported = true;

  @override
  String? get accessToken => _client.auth.currentSession?.accessToken;

  @override
  String? get userId => _client.auth.currentUser?.id;

  @override
  String? get userEmail => _client.auth.currentUser?.email;

  @override
  Future<Artifact?> loadArtifact(final String md5sum) async {
    final row = await _client
        .from('Artifacts')
        .select()
        .eq('md5', md5sum)
        .maybeSingle();
    return row == null ? null : Artifact.fromMap(row);
  }

  @override
  Future<void> saveArtifact(final Artifact artifact) async {
    final Map<String, dynamic> payload = {
      'name': artifact.name,
      'md5': artifact.md5sum,
      // Additive column prepared for the future MD5 -> SHA-256 migration;
      // MD5 remains the join key everywhere. Omit when unknown so we never
      // overwrite a stored hash with null on re-save.
      if (artifact.sha256 != null && sha256ColumnSupported)
        'sha256': artifact.sha256,
    };
    try {
      await _client.from('Artifacts').upsert(payload);
    } on PostgrestException catch (e) {
      // PGRST204: the live schema cache does not have the column we tried to
      // write. If (and only if) that column was our optional sha256, retry
      // once without it and remember to stop sending it. All other failures
      // still propagate — the no-swallow contract holds.
      if (e.code == 'PGRST204' &&
          sha256ColumnSupported &&
          payload.containsKey('sha256')) {
        sha256ColumnSupported = false;
        debugPrint(
          'Artifacts.sha256 column not in schema yet; '
          'continuing with {name, md5} payloads. $e',
        );
        await _client
            .from('Artifacts')
            .upsert({'name': artifact.name, 'md5': artifact.md5sum});
      } else {
        rethrow;
      }
    }
  }

  @override
  Future<List<Remark>> loadRemarks({required final String md5sum}) async {
    final rows = await _client
        .from('Remarks')
        .select()
        .eq('artifact_md5', md5sum)
        .order('created_at', ascending: true);
    return rows.map((final row) => Remark.fromMap(row)).toList();
  }

  @override
  Future<void> saveRemark({
    required final String remark,
    required final String? md5sum,
    required final String? userId,
  }) async {
    if ((userId?.isNotEmpty ?? false) && (md5sum?.isNotEmpty ?? false)) {
      await _client.from('Remarks').insert({
        'artifact_md5': md5sum,
        'remark': remark,
        'user_id': userId,
      });
    }
  }

  @override
  Future<void> deleteRemark({required final Remark remark}) async {
    final int? id = remark.id;
    if (id == null) return;
    await _client.from('Remarks').delete().eq('id', id);
  }

  @override
  Future<void> addToFavorites({
    required final Artifact? artifact,
    required final String? userId,
  }) async {
    if (artifact == null || userId == null) return;
    await _client
        .from('Favorites')
        .insert({'user_id': userId, 'artifact_md5': artifact.md5sum});
  }

  @override
  Future<void> removeFromFavorites({
    required final Artifact? artifact,
    required final String? userId,
  }) async {
    if (artifact == null || userId == null) return;
    await _client
        .from('Favorites')
        .delete()
        .eq('user_id', userId)
        .eq('artifact_md5', artifact.md5sum);
  }

  @override
  Future<List<Artifact>> loadFavoritesArtifacts(
      {required final String? userId}) async {
    if (userId == null) return [];
    final results = await _client
        .rpc('getfavoriteartifactsfor', params: {'userid': userId});
    return (results as List<dynamic>)
        .map((final row) => Artifact.fromMap(
            Map<String, dynamic>.from(row as Map<dynamic, dynamic>)))
        .toList();
  }

  @override
  Future<String?> loginWithJwt(final String jwt) async {
    final response = await _client.auth.recoverSession(jwt);
    return response.user?.email;
  }
}
