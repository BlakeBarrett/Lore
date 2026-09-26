import 'dart:io';

import 'package:lore/artifact.dart';
import 'package:lore/lore_console.dart';
import 'package:lore/repo/lore_repo.dart';
import 'package:lore/remark.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'lore_console_test.mocks.dart';

@GenerateMocks([LoreRepo, IOSink])
void main() {
  late MockLoreRepo mockApi;
  late MockIOSink mockStdout;
  late List<int> exitCodes;

  setUp(() {
    mockApi = MockLoreRepo();
    mockStdout = MockIOSink();
    exitCodes = <int>[];

    LoreConsole.api = mockApi; // Replace the repo seam with a mock
    LoreConsole.stdout = mockStdout; // Replace stdout with a mock
    // Capture exit calls instead of terminating the test process. With the
    // single-exit-point console, exactly one code is recorded per command.
    LoreConsole.exit = exitCodes.add;
  });

  tearDown(() {
    // Never leave the real seam pointing at collectors.
    LoreConsole.exit = (final int code) => exit(code);
  });

  group('exit codes', () {
    test('no arguments prints usage and exits 0', () async {
      await LoreConsole([]).done;

      verify(mockStdout.writeln(
              'Lore - The shared, single source of truth for everything.'))
          .called(1);
      verify(mockStdout.writeln(contains('Available commands:'))).called(1);
      expect(exitCodes, <int>[0]);
    });

    test('help exits 0', () async {
      await LoreConsole(['help']).done;
      expect(exitCodes, <int>[0]);
    });

    test('unknown command exits 1', () async {
      await LoreConsole(['unknown-command']).done;

      verify(mockStdout.writeln('Unknown command: unknown-command')).called(1);
      verify(mockStdout.writeln(contains('Available commands:'))).called(1);
      expect(exitCodes, <int>[1]);
    });

    test('get without an identifier exits 1 with command usage', () async {
      await LoreConsole(['get']).done;

      verify(mockStdout.writeln('Error: Missing artifact identifier'))
          .called(1);
      verify(mockStdout.writeln('Usage: lore get <md5|text>')).called(1);
      expect(exitCodes, <int>[1]);
    });

    test('add-remark without arguments exits 1 with command usage', () async {
      await LoreConsole(['add-remark', 'only-md5']).done;

      verify(mockStdout.writeln('Error: Missing md5sum or remark text'))
          .called(1);
      verify(mockStdout.writeln(startsWith('Usage: lore add-remark')))
          .called(1);
      expect(exitCodes, <int>[1]);
    });

    test('login without a token exits 1 with command usage', () async {
      await LoreConsole(['login']).done;

      verify(mockStdout.writeln('Error: Missing JWT token')).called(1);
      verify(mockStdout.writeln(startsWith('Usage: lore login'))).called(1);
      expect(exitCodes, <int>[1]);
    });

    test('repo failure during get surfaces the error and exits 1', () async {
      when(mockApi.loadArtifact(any)).thenThrow(StateError('supabase is down'));

      await LoreConsole(['get', '1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d']).done;

      verify(mockStdout.writeln(contains('Error executing command:')))
          .called(1);
      expect(exitCodes, <int>[1]);
    });
  });

  group('get', () {
    // A real 32-hex-char MD5 so the console treats it as a hash, not text.
    const testMd5 = '1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d';

    test('with an MD5 hash fetches the artifact and exits 0', () async {
      final testArtifact = Artifact(
        path: 'test/path.txt',
        md5sum: testMd5,
        remarks: [const Remark.simple(text: 'Test remark', author: 'user123')],
      );
      when(mockApi.loadArtifact(testMd5))
          .thenAnswer((final _) async => testArtifact);

      await LoreConsole(['get', testMd5]).done;

      verify(mockApi.loadArtifact(testMd5)).called(1);
      verify(mockStdout.writeln(contains('Fetching artifact: $testMd5')))
          .called(1);
      verify(mockStdout.writeln(contains('Artifact: test/path.txt'))).called(1);
      verify(mockStdout.writeln(contains('Test remark'))).called(1);
      expect(exitCodes, <int>[0]);
    });

    test('with plain text hashes it first', () async {
      when(mockApi.loadArtifact(any)).thenAnswer((final _) async => null);

      await LoreConsole(['get', 'hello lore']).done;

      verify(mockStdout.writeln(contains('Calculated MD5:'))).called(1);
      verify(mockApi.loadArtifact(any)).called(1);
      expect(exitCodes, <int>[0]);
    });
  });

  group('add-remark', () {
    const testMd5 = '1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d';
    const testRemark = 'This is a test remark';
    const testUserId = 'user123';

    test('adds the remark and exits 0', () async {
      when(mockApi.userId).thenReturn(testUserId);
      when(mockApi.saveRemark(
              remark: testRemark, md5sum: testMd5, userId: testUserId))
          .thenAnswer((final _) async {});

      await LoreConsole(['add-remark', testMd5, testRemark]).done;

      verify(mockApi.saveRemark(
              remark: testRemark, md5sum: testMd5, userId: testUserId))
          .called(1);
      verify(mockStdout.writeln(contains('Remark added successfully')))
          .called(1);
      expect(exitCodes, <int>[0]);
    });

    test('joins multi-word remark text', () async {
      when(mockApi.userId).thenReturn(testUserId);
      when(mockApi.saveRemark(
              remark: 'two words here', md5sum: testMd5, userId: testUserId))
          .thenAnswer((final _) async {});

      await LoreConsole(['add-remark', testMd5, 'two', 'words', 'here']).done;

      verify(mockApi.saveRemark(
              remark: 'two words here', md5sum: testMd5, userId: testUserId))
          .called(1);
      expect(exitCodes, <int>[0]);
    });

    test('without a logged-in user exits 1 and saves nothing', () async {
      when(mockApi.userId).thenReturn(null);

      await LoreConsole(['add-remark', testMd5, testRemark]).done;

      verify(mockStdout.writeln('Error: You must be logged in to add remarks.'))
          .called(1);
      verifyNever(mockApi.saveRemark(
          remark: anyNamed('remark'),
          md5sum: anyNamed('md5sum'),
          userId: anyNamed('userId')));
      // Regression: the inner exit(1) used to fall through to a trailing
      // exit(0) when exit was stubbed; exactly [1] must be recorded.
      expect(exitCodes, <int>[1]);
    });

    test('repo failure prints the error and exits 1', () async {
      when(mockApi.userId).thenReturn(testUserId);
      when(mockApi.saveRemark(
              remark: anyNamed('remark'),
              md5sum: anyNamed('md5sum'),
              userId: anyNamed('userId')))
          .thenThrow(StateError('insert denied'));

      await LoreConsole(['add-remark', testMd5, testRemark]).done;

      verify(mockStdout.writeln(contains('Failed to add remark:'))).called(1);
      expect(exitCodes, <int>[1]);
    });
  });

  group('login', () {
    test('successful login prints the user and exits 0', () async {
      when(mockApi.loginWithJwt('jwt-token'))
          .thenAnswer((final _) async => 'user@example.com');

      await LoreConsole(['login', 'jwt-token']).done;

      verify(mockApi.loginWithJwt('jwt-token')).called(1);
      verify(mockStdout.writeln('Login successful!')).called(1);
      verify(mockStdout.writeln('User: user@example.com')).called(1);
      expect(exitCodes, <int>[0]);
    });

    test('successful login with a null email prints Unknown', () async {
      when(mockApi.loginWithJwt(any)).thenAnswer((final _) async => null);

      await LoreConsole(['login', 'jwt-token']).done;

      verify(mockStdout.writeln('User: Unknown')).called(1);
      expect(exitCodes, <int>[0]);
    });

    test('failed login prints the failure and exits 1', () async {
      when(mockApi.loginWithJwt(any)).thenThrow(StateError('token expired'));

      await LoreConsole(['login', 'jwt-token']).done;

      verify(mockStdout.writeln(contains('Login failed:'))).called(1);
      // Regression: the inner exit(1) used to fall through to a trailing
      // exit(0) when exit was stubbed; exactly [1] must be recorded.
      expect(exitCodes, <int>[1]);
    });
  });

  group('list-favorites', () {
    test('shows the user favorites and exits 0', () async {
      const testUserId = 'user123';
      final testArtifacts = [
        Artifact(path: 'test/path1.txt', md5sum: '123'),
        Artifact(path: 'test/path2.txt', md5sum: '456'),
      ];
      when(mockApi.userId).thenReturn(testUserId);
      when(mockApi.loadFavoritesArtifacts(userId: testUserId))
          .thenAnswer((final _) async => testArtifacts);

      await LoreConsole(['list-favorites']).done;

      verify(mockApi.loadFavoritesArtifacts(userId: testUserId)).called(1);
      verify(mockStdout.writeln(contains('Your favorites:'))).called(1);
      verify(mockStdout.writeln(contains('test/path1.txt'))).called(1);
      verify(mockStdout.writeln(contains('test/path2.txt'))).called(1);
      expect(exitCodes, <int>[0]);
    });

    test('empty favorites prints the empty state and exits 0', () async {
      when(mockApi.userId).thenReturn('user123');
      when(mockApi.loadFavoritesArtifacts(userId: 'user123'))
          .thenAnswer((final _) async => <Artifact>[]);

      await LoreConsole(['list-favorites']).done;

      verify(mockStdout.writeln('You have no favorite artifacts.')).called(1);
      expect(exitCodes, <int>[0]);
    });

    test('anonymous exits 1 without calling the repo', () async {
      when(mockApi.userId).thenReturn(null);

      await LoreConsole(['list-favorites']).done;

      verify(mockStdout
              .writeln('Error: You must be logged in to list favorites.'))
          .called(1);
      verifyNever(mockApi.loadFavoritesArtifacts(userId: anyNamed('userId')));
      expect(exitCodes, <int>[1]);
    });

    test('repo failure exits 1', () async {
      when(mockApi.userId).thenReturn('user123');
      when(mockApi.loadFavoritesArtifacts(userId: 'user123'))
          .thenThrow(StateError('rpc failed'));

      await LoreConsole(['list-favorites']).done;

      verify(mockStdout.writeln(contains('Failed to fetch favorites:')))
          .called(1);
      expect(exitCodes, <int>[1]);
    });
  });
}
