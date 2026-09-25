import 'package:Lore/app_config.dart';
import 'package:Lore/artifact.dart';
import 'package:Lore/repo/lore_repo.dart';
import 'package:Lore/remark.dart';
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
    await _client.from('Artifacts').upsert({
      'name': artifact.name,
      'md5': artifact.md5sum,
      // Additive column prepared for the future MD5 -> SHA-256 migration;
      // MD5 remains the join key everywhere. Omit when unknown so we never
      // overwrite a stored hash with null on re-save.
      if (artifact.sha256 != null) 'sha256': artifact.sha256,
    });
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
