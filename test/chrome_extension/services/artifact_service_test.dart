import 'package:flutter_test/flutter_test.dart';
import 'package:Lore/md5_utils.dart';

import '../mocks/mock_artifact_service.dart';
import '../test_setup.dart';

void main() {
  late MockArtifactService mockArtifactService;

  setUp(() async {
    // Initialize test services
    await setupTestServices();
    mockArtifactService = testServiceLocator<MockArtifactService>();
  });

  group('ArtifactService', () {
    test('creates artifact from URL', () {
      // Arrange
      const testUrl = 'https://example.com';
      final expectedMd5 = md5SumFor(testUrl);
      
      // Act
      final artifact = mockArtifactService.createArtifactFromUrl(testUrl);
      
      // Assert
      expect(artifact, isNotNull);
      expect(artifact.path, equals(testUrl));
      expect(artifact.md5sum, equals(expectedMd5));
    });
    
    test('loads remarks for existing artifact', () async {
      // Arrange
      const testUrl = 'https://example.com';
      final testMd5 = md5SumFor(testUrl);
      
      // Act
      final remarks = await mockArtifactService.loadRemarks(testMd5);
      
      // Assert
      expect(remarks, isNotEmpty);
      expect(remarks.length, equals(2)); // Our mock has 2 remarks pre-populated
    });
    
    test('loads empty list for non-existing artifact', () async {
      // Arrange
      const nonExistingMd5 = 'non_existing_md5';
      
      // Act
      final remarks = await mockArtifactService.loadRemarks(nonExistingMd5);
      
      // Assert
      expect(remarks, isEmpty);
    });
    
    test('saves remark and can be retrieved', () async {
      // Arrange
      const testUrl = 'https://test-save.com';
      final testMd5 = md5SumFor(testUrl);
      const testRemark = 'This is a new test remark';
      const testUserId = 'test_user';
      
      // Act - Save the remark
      await mockArtifactService.saveRemark(
        remark: testRemark,
        md5sum: testMd5,
        userId: testUserId,
      );
      
      // Act - Load the remarks
      final remarks = await mockArtifactService.loadRemarks(testMd5);
      
      // Assert
      expect(remarks, isNotEmpty);
      expect(remarks.first.text, equals(testRemark));
      expect(remarks.first.author, equals(testUserId));
    });
    
    test('deletes remark', () async {
      // Arrange
      const testUrl = 'https://example.com';
      final testMd5 = md5SumFor(testUrl);
      final initialRemarks = await mockArtifactService.loadRemarks(testMd5);
      expect(initialRemarks.isNotEmpty, isTrue); // Ensure we have remarks to delete
      
      // Take the first remark to delete
      final remarkToDelete = initialRemarks.first;
      
      // Act
      await mockArtifactService.deleteRemark(remarkToDelete);
      final remarksAfterDelete = await mockArtifactService.loadRemarks(testMd5);
      
      // Assert
      expect(remarksAfterDelete.length, equals(initialRemarks.length - 1));
      expect(remarksAfterDelete.contains(remarkToDelete), isFalse);
    });
  });
}