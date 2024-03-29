import 'package:Lore/artifact.dart';
import 'package:Lore/main.dart';
import 'package:Lore/remark.dart';
import 'package:flutter/foundation.dart';

abstract class LoreAPI {
  static String? get accessToken =>
      supabaseInstance.auth.currentSession?.accessToken;
  static String? get userId => supabaseInstance.auth.currentUser?.id;
  static String? get userEmail => supabaseInstance.auth.currentUser?.email;

  static Future<Artifact?> loadArtifact(final String md5sum) async {
    return await supabaseInstance
        .from('Artifacts')
        .select()
        .eq('md5', md5sum)
        .single()
        .then((value) => Artifact.fromAPIResponse(value));
  }

  static Future<void> saveArtifact(final Artifact artifact) async {
    await supabaseInstance.from('Artifacts').upsert({
      'name': artifact.name,
      'md5': artifact.md5sum,
    }).catchError((error) {
      debugPrint('Error saving Artifact: $error');
    });
  }

  static Future<List<Remark>> loadRemarks(
      {required final String md5sum}) async {
    return await supabaseInstance
        .from('Remarks')
        .select()
        .eq('artifact_md5', md5sum)
        .order('created_at', ascending: true)
        .then((value) =>
            value.map((item) => Remark.fromAPIResponse(item)).toList());
  }

  static Future<void> saveRemark(
      {required final String remark,
      required final String? md5sum,
      required final String? userId}) async {
    if ((userId?.isNotEmpty ?? false) && (md5sum?.isNotEmpty ?? false)) {
      final Map<String, dynamic> payload = {
        'artifact_md5': md5sum,
        'remark': remark,
        'user_id': userId,
      };
      await supabaseInstance
          .from('Remarks')
          .insert(payload)
          .catchError((error) {
        debugPrint('Error saving remark: $error');
      });
    }
  }

  static Future<void> deleteRemark({required final Remark remark}) async {
    if (remark.id == null) return;
    await supabaseInstance
        .from('Remarks')
        .delete()
        .eq('id', remark.id?.toInt() ?? -1)
        .catchError((error) {
      debugPrint('Error deleting remark: $error');
    });
  }

  static Future<void> addToFavorites(
      {required final Artifact? artifact,
      required final String? userId}) async {
    if (artifact == null || userId == null) return;
    await supabaseInstance
        .from('Favorites')
        .insert({'user_id': userId, 'artifact_md5': artifact.md5sum})
        .then((value) => debugPrint('Added to favorites: $value'))
        .catchError((error) {
          debugPrint('Error adding to favorites: $error');
        });
  }

  static Future<void> removeFromFavorites(
      {required final Artifact? artifact,
      required final String? userId}) async {
    if (artifact == null || userId == null) return;
    await supabaseInstance
        .from('Favorites')
        .delete()
        .eq('user_id', userId)
        .eq('artifact_md5', artifact.md5sum)
        .then((value) => debugPrint('Removed from favorites: $value'))
        .catchError((error) {
      debugPrint('Error removing from favorites: $error');
    });
  }

  static Future<List<Artifact>> loadFavoritesArtifacts(
      {required final String? userId}) async {
    if (userId == null) return [];
    final results = await supabaseInstance
        .rpc('getfavoriteartifactsfor', params: {'userid': userId});
    final List<Artifact> artifacts = [];
    results.forEach((element) {
      artifacts.add(Artifact.fromAPIResponse(element));
    });
    return artifacts;
  }
}
