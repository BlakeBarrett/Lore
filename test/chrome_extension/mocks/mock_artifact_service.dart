import 'package:Lore/artifact.dart';
import 'package:Lore/md5_utils.dart';
import 'package:Lore/remark.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../chrome_extension/lib/services/artifact_service.dart';

// Generate a Mock class
@GenerateMocks([ArtifactService])
class MockArtifactService extends Mock implements ArtifactService {
  final Map<String, List<Remark>> _remarks = {};
  
  // Pre-populate with some test remarks
  MockArtifactService() {
    final testMd5 = md5SumFor('https://example.com');
    _remarks[testMd5] = [
      Remark('This is a test remark', 'test_user', DateTime.now().subtract(const Duration(days: 1)), 1),
      Remark('Another test remark', 'another_user', DateTime.now(), 2),
    ];
  }

  @override
  Artifact createArtifactFromUrl(String url) {
    return Artifact.fromURI(Uri.parse(url));
  }
  
  @override
  Future<List<Remark>> loadRemarks(String md5sum) async {
    return _remarks[md5sum] ?? [];
  }
  
  @override
  Future<void> saveRemark({
    required String remark,
    required String md5sum,
    required String? userId,
  }) async {
    if (!_remarks.containsKey(md5sum)) {
      _remarks[md5sum] = [];
    }
    
    final newRemark = Remark(
      remark,
      userId ?? 'anonymous',
      DateTime.now(),
      _remarks[md5sum]!.length + 1,
    );
    
    _remarks[md5sum]!.add(newRemark);
  }
  
  @override
  Future<void> deleteRemark(Remark remark) async {
    for (final key in _remarks.keys) {
      _remarks[key] = _remarks[key]!.where((r) => r.id != remark.id).toList();
    }
  }
}