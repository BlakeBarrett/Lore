import 'package:Lore/artifact.dart';
import 'package:Lore/lore_api.dart';
import 'package:Lore/remark.dart';

/// Service for handling Artifact operations
class ArtifactService {
  /// Create an artifact from a URL
  Artifact createArtifactFromUrl(String url) {
    return Artifact.fromURI(Uri.parse(url));
  }
  
  /// Load remarks for an artifact
  Future<List<Remark>> loadRemarks(String md5sum) async {
    return await LoreAPI.loadRemarks(md5sum: md5sum);
  }
  
  /// Save a remark for an artifact
  Future<void> saveRemark({
    required String remark,
    required String md5sum,
    required String? userId,
  }) async {
    await LoreAPI.saveRemark(
      remark: remark,
      md5sum: md5sum,
      userId: userId,
    );
  }
  
  /// Delete a remark
  Future<void> deleteRemark(Remark remark) async {
    await LoreAPI.deleteRemark(remark: remark);
  }
}