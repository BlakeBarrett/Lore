import 'dart:io';

import 'package:Lore/artifact.dart';
import 'package:Lore/lore_console.dart';
import 'package:Lore/repo/lore_repo.dart';
import 'package:Lore/remark.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'lore_console_test.mocks.dart';

@GenerateMocks([LoreRepo, IOSink])
void main() {
  late MockLoreRepo mockApi;
  late MockIOSink mockStdout;

  setUp(() {
    mockApi = MockLoreRepo();
    mockStdout = MockIOSink();

    LoreConsole.api = mockApi; // Replace the repo seam with a mock
    LoreConsole.stdout = mockStdout; // Replace stdout with a mock
  });

  test('prints usage when no arguments provided', () async {
    // Override exit function to avoid test termination
    final originalExit = LoreConsole.exit;
    LoreConsole.exit = (final int code) {};

    try {
      await LoreConsole([]).done;

      verify(mockStdout.writeln(
              'Lore - The shared, single source of truth for everything.'))
          .called(1);
      verify(mockStdout.writeln(contains('Available commands:'))).called(1);
    } finally {
      LoreConsole.exit = originalExit;
    }
  });

  test('get command with MD5 hash fetches artifact correctly', () async {
    // Override exit function
    final originalExit = LoreConsole.exit;
    LoreConsole.exit = (final int code) {};

    // A real 32-hex-char MD5 so the console treats it as a hash, not text.
    const testMd5 = '1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d';
    final testArtifact = Artifact(
      path: 'test/path.txt',
      md5sum: testMd5,
      remarks: [const Remark.simple(text: 'Test remark', author: 'user123')],
    );

    when(mockApi.loadArtifact(testMd5))
        .thenAnswer((final _) async => testArtifact);

    try {
      await LoreConsole(['get', testMd5]).done;

      verify(mockApi.loadArtifact(testMd5)).called(1);
      verify(mockStdout.writeln(contains('Fetching artifact: $testMd5')))
          .called(1);
      verify(mockStdout.writeln(contains('Artifact: test/path.txt'))).called(1);
      verify(mockStdout.writeln(contains('Test remark'))).called(1);
    } finally {
      LoreConsole.exit = originalExit;
    }
  });

  test('add-remark command adds remark to artifact', () async {
    // Override exit function
    final originalExit = LoreConsole.exit;
    LoreConsole.exit = (final int code) {};

    const testMd5 = '1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d';
    const testRemark = 'This is a test remark';
    const testUserId = 'user123';

    // Set mock userId
    when(mockApi.userId).thenReturn(testUserId);

    // Mock saveRemark success
    when(mockApi.saveRemark(
            remark: testRemark, md5sum: testMd5, userId: testUserId))
        .thenAnswer((final _) async {});

    try {
      await LoreConsole(['add-remark', testMd5, testRemark]).done;

      verify(mockApi.saveRemark(
              remark: testRemark, md5sum: testMd5, userId: testUserId))
          .called(1);
      verify(mockStdout.writeln(contains('Remark added successfully')))
          .called(1);
    } finally {
      LoreConsole.exit = originalExit;
    }
  });

  test('list-favorites command shows user favorites', () async {
    // Override exit function
    final originalExit = LoreConsole.exit;
    LoreConsole.exit = (final int code) {};

    const testUserId = 'user123';
    final testArtifacts = [
      Artifact(path: 'test/path1.txt', md5sum: '123'),
      Artifact(path: 'test/path2.txt', md5sum: '456'),
    ];

    // Set mock userId
    when(mockApi.userId).thenReturn(testUserId);

    // Mock loadFavoritesArtifacts
    when(mockApi.loadFavoritesArtifacts(userId: testUserId))
        .thenAnswer((final _) async => testArtifacts);

    try {
      await LoreConsole(['list-favorites']).done;

      verify(mockApi.loadFavoritesArtifacts(userId: testUserId)).called(1);
      verify(mockStdout.writeln(contains('Your favorites:'))).called(1);
      verify(mockStdout.writeln(contains('test/path1.txt'))).called(1);
      verify(mockStdout.writeln(contains('test/path2.txt'))).called(1);
    } finally {
      LoreConsole.exit = originalExit;
    }
  });

  test('unknown command shows usage', () async {
    // Override exit function
    final originalExit = LoreConsole.exit;
    LoreConsole.exit = (final int code) {};

    try {
      await LoreConsole(['unknown-command']).done;

      verify(mockStdout.writeln('Unknown command: unknown-command')).called(1);
      verify(mockStdout.writeln(contains('Available commands:'))).called(1);
    } finally {
      LoreConsole.exit = originalExit;
    }
  });
}
