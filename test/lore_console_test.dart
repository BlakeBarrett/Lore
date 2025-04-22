import 'dart:async';
import 'dart:io';

import 'package:Lore/artifact.dart';
import 'package:Lore/lore_api.dart';
import 'package:Lore/lore_console.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nock/nock.dart';

import 'lore_console_test.mocks.dart';

@GenerateMocks([LoreAPI, IOSink])
void main() {
  late MockLoreAPI mockApi;
  late MockIOSink mockStdout;
  late StreamController<String> outputController;

  setUp(() {
    mockApi = MockLoreAPI();
    mockStdout = MockIOSink();
    outputController = StreamController<String>();

    LoreConsole.api = mockApi; // Replace with static api in LoreConsole
    LoreConsole.stdout = mockStdout; // Replace stdout in LoreConsole

    when(mockStdout.writeln(any)).thenAnswer((invocation) {
      outputController.add(invocation.positionalArguments[0] as String);
      return null;
    });
  });

  tearDown(() {
    outputController.close();
  });

  test('prints usage when no arguments provided', () async {
    // Override exit function to avoid test termination
    final originalExit = LoreConsole.exit;
    LoreConsole.exit = (int code) {};

    try {
      LoreConsole([]);

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
    LoreConsole.exit = (int code) {};

    const testMd5 = '1a2b3c4d5e6f7g8h9i0j';
    final testArtifact = Artifact(
      path: 'test/path.txt',
      md5sum: testMd5,
      remarks: [Remark(text: 'Test remark', userId: 'user123')],
    );

    when(mockApi.loadArtifact(testMd5)).thenAnswer((_) async => testArtifact);

    try {
      LoreConsole(['get', testMd5]);

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
    LoreConsole.exit = (int code) {};

    const testMd5 = '1a2b3c4d5e6f7g8h9i0j';
    const testRemark = 'This is a test remark';
    const testUserId = 'user123';

    // Set mock userId
    when(mockApi.userId).thenReturn(testUserId);

    // Mock saveRemark success
    when(mockApi.saveRemark(
            remark: testRemark, md5sum: testMd5, userId: testUserId))
        .thenAnswer((_) async => true);

    try {
      LoreConsole(['add-remark', testMd5, testRemark]);

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
    LoreConsole.exit = (int code) {};

    const testUserId = 'user123';
    final testArtifacts = [
      Artifact(path: 'test/path1.txt', md5sum: '123'),
      Artifact(path: 'test/path2.txt', md5sum: '456'),
    ];

    // Set mock userId
    when(mockApi.userId).thenReturn(testUserId);

    // Mock loadFavoritesArtifacts
    when(mockApi.loadFavoritesArtifacts(userId: testUserId))
        .thenAnswer((_) async => testArtifacts);

    try {
      LoreConsole(['list-favorites']);

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
    LoreConsole.exit = (int code) {};

    try {
      LoreConsole(['unknown-command']);

      verify(mockStdout.writeln('Unknown command: unknown-command')).called(1);
      verify(mockStdout.writeln(contains('Available commands:'))).called(1);
    } finally {
      LoreConsole.exit = originalExit;
    }
  });
}
