import 'dart:convert';
import 'dart:io';

import 'package:Lore/app_config.dart';
import 'package:Lore/artifact.dart';
import 'package:Lore/repo/supabase_lore_repo.dart';
import 'package:Lore/remark.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nock/nock.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// [SupabaseLoreRepo] against nock-mocked Supabase REST endpoints. The repo
/// is constructed with a real [SupabaseClient] pointed at a fake project URL,
/// so the full postgrest stack (query building, response parsing, error
/// mapping) is exercised — only the HTTP transport is mocked.
void main() {
  const baseUrl = 'https://lore-repo-test.supabase.co';
  const rest = '/rest/v1';
  const testMd5 = '1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d';
  const userId = 'user-123';

  late SupabaseClient client;
  late SupabaseLoreRepo repo;

  setUpAll(nock.init);

  setUp(() {
    nock.cleanAll();
    client = SupabaseClient(
      baseUrl,
      'test-anon-key',
      // No background refresh timer: tests would hang on a pending Timer.
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    repo = SupabaseLoreRepo(AppConfig.forTesting(client));
  });

  tearDown(() async {
    nock.cleanAll();
    await client.dispose();
  });

  group('loadArtifact', () {
    test('maps a row through Artifact.fromMap', () async {
      nock(baseUrl)
          .get((final Uri uri) =>
              uri.path == '$rest/Artifacts' &&
              uri.queryParameters['md5'] == 'eq.$testMd5')
          .reply(200, [
        {'name': 'dir/file.txt', 'md5': testMd5, 'sha256': 'sha-abc'},
      ]);

      final artifact = await repo.loadArtifact(testMd5);

      expect(artifact?.path, 'dir/file.txt');
      expect(artifact?.md5sum, testMd5);
      expect(artifact?.sha256, 'sha-abc');
    });

    test('returns null when zero rows match (maybeSingle)', () async {
      nock(baseUrl)
          .get((final Uri uri) => uri.path == '$rest/Artifacts')
          .reply(200, <Object?>[]);

      expect(await repo.loadArtifact(testMd5), isNull);
    });

    test('THROWS on a 500 (never swallows)', () async {
      nock(baseUrl)
          .get((final Uri uri) => uri.path == '$rest/Artifacts')
          .reply(500, {'message': 'db exploded'});

      expect(repo.loadArtifact(testMd5), throwsA(isA<PostgrestException>()));
    });
  });

  group('saveArtifact', () {
    test('upsert payload includes sha256 when set', () async {
      Map<String, dynamic>? sent;
      final interceptor = nock(baseUrl).post('$rest/Artifacts',
          (final List<int> body, final ContentType contentType) {
        sent = jsonDecode(utf8.decode(body)) as Map<String, dynamic>;
        return true;
      })
        ..reply(201, <String, dynamic>{});

      await repo.saveArtifact(
          Artifact(path: 'file.txt', md5sum: testMd5, sha256: 'sha-abc'));

      expect(interceptor.isDone, isTrue);
      expect(sent, {
        'name': 'file.txt',
        'md5': testMd5,
        'sha256': 'sha-abc',
      });
    });

    test('upsert payload OMITS sha256 when null (never overwrites with null)',
        () async {
      Map<String, dynamic>? sent;
      final interceptor = nock(baseUrl).post('$rest/Artifacts',
          (final List<int> body, final ContentType contentType) {
        sent = jsonDecode(utf8.decode(body)) as Map<String, dynamic>;
        return true;
      })
        ..reply(201, <String, dynamic>{});

      await repo.saveArtifact(Artifact(path: 'file.txt', md5sum: testMd5));

      expect(interceptor.isDone, isTrue);
      expect(sent, {'name': 'file.txt', 'md5': testMd5});
      expect(sent?.containsKey('sha256'), isFalse);
    });

    test('THROWS on a 403 RLS rejection', () async {
      nock(baseUrl)
          .post('$rest/Artifacts',
              (final List<int> b, final ContentType contentType) => true)
          .reply(403, {'message': 'row-level security'});

      expect(repo.saveArtifact(Artifact(path: 'f', md5sum: testMd5)),
          throwsA(isA<PostgrestException>()));
    });
  });

  group('loadRemarks', () {
    test('maps rows in the server (ascending created_at) order', () async {
      // The repo requests order=created_at.asc; echo an ordered fixture and
      // assert the repo preserves it, oldest first.
      nock(baseUrl)
          .get((final Uri uri) =>
              uri.path == '$rest/Remarks' &&
              uri.queryParameters['artifact_md5'] == 'eq.$testMd5' &&
              uri.queryParameters['order'] == 'created_at.asc.nullslast')
          .reply(200, [
        {
          'id': 1,
          'remark': 'older',
          'user_id': 'a',
          'created_at': '2026-01-01T00:00:00.000Z'
        },
        {
          'id': 2,
          'remark': 'newer',
          'user_id': 'b',
          'created_at': '2026-01-02T00:00:00.000Z'
        },
      ]);

      final remarks = await repo.loadRemarks(md5sum: testMd5);

      expect(remarks.map((final r) => r.text), ['older', 'newer']);
      expect(remarks.map((final r) => r.id), [1, 2]);
      expect(remarks.first.author, 'a');
      expect(remarks.first.timestamp, DateTime.utc(2026, 1, 1).toLocal());
    });

    test('THROWS on a 400', () async {
      nock(baseUrl)
          .get((final Uri uri) => uri.path == '$rest/Remarks')
          .reply(400, {'message': 'bad request'});

      expect(repo.loadRemarks(md5sum: testMd5),
          throwsA(isA<PostgrestException>()));
    });
  });

  group('saveRemark', () {
    test('inserts artifact_md5/remark/user_id', () async {
      Map<String, dynamic>? sent;
      final interceptor = nock(baseUrl).post('$rest/Remarks',
          (final List<int> body, final ContentType contentType) {
        sent = jsonDecode(utf8.decode(body)) as Map<String, dynamic>;
        return true;
      })
        ..reply(201, <String, dynamic>{});

      await repo.saveRemark(remark: 'hello', md5sum: testMd5, userId: userId);

      expect(interceptor.isDone, isTrue);
      expect(sent, {
        'artifact_md5': testMd5,
        'remark': 'hello',
        'user_id': userId,
      });
    });

    test('makes no request when userId or md5sum is missing', () async {
      final interceptor = nock(baseUrl).post('$rest/Remarks')
        ..reply(201, <String, dynamic>{});

      await repo.saveRemark(remark: 'x', md5sum: null, userId: userId);
      await repo.saveRemark(remark: 'x', md5sum: testMd5, userId: null);
      await repo.saveRemark(remark: 'x', md5sum: testMd5, userId: '');

      expect(interceptor.isDone, isFalse);
    });

    test('THROWS on a 401', () async {
      nock(baseUrl)
          .post('$rest/Remarks',
              (final List<int> b, final ContentType contentType) => true)
          .reply(401, {'message': 'invalid token'});

      expect(repo.saveRemark(remark: 'x', md5sum: testMd5, userId: userId),
          throwsA(isA<PostgrestException>()));
    });
  });

  group('deleteRemark', () {
    test('deletes by row id', () async {
      final interceptor = nock(baseUrl).delete((final Uri uri) =>
          uri.path == '$rest/Remarks' && uri.queryParameters['id'] == 'eq.7')
        ..reply(204, '');

      await repo.deleteRemark(remark: const Remark.simple(text: 'bye', id: 7));

      expect(interceptor.isDone, isTrue);
    });

    test('makes no request for a remark without an id', () async {
      final interceptor = nock(baseUrl)
          .delete((final Uri uri) => uri.path == '$rest/Remarks')
        ..reply(204, '');

      await repo.deleteRemark(remark: const Remark.simple(text: 'unsaved'));

      expect(interceptor.isDone, isFalse);
    });

    test('THROWS on a 500', () async {
      nock(baseUrl)
          .delete((final Uri uri) => uri.path == '$rest/Remarks')
          .reply(500, {'message': 'boom'});

      expect(repo.deleteRemark(remark: const Remark.simple(text: 'x', id: 7)),
          throwsA(isA<PostgrestException>()));
    });
  });

  group('favorites', () {
    test('addToFavorites inserts user_id + artifact_md5', () async {
      Map<String, dynamic>? sent;
      final interceptor = nock(baseUrl).post('$rest/Favorites',
          (final List<int> body, final ContentType contentType) {
        sent = jsonDecode(utf8.decode(body)) as Map<String, dynamic>;
        return true;
      })
        ..reply(201, <String, dynamic>{});

      await repo.addToFavorites(
          artifact: Artifact(path: 'f.txt', md5sum: testMd5), userId: userId);

      expect(interceptor.isDone, isTrue);
      expect(sent, {'user_id': userId, 'artifact_md5': testMd5});
    });

    test('addToFavorites is a no-op without artifact or user', () async {
      final interceptor = nock(baseUrl).post('$rest/Favorites')
        ..reply(201, <String, dynamic>{});

      await repo.addToFavorites(artifact: null, userId: userId);
      await repo.addToFavorites(
          artifact: Artifact(path: 'f', md5sum: testMd5), userId: null);

      expect(interceptor.isDone, isFalse);
    });

    test('addToFavorites THROWS on a 409 duplicate', () async {
      nock(baseUrl)
          .post('$rest/Favorites',
              (final List<int> b, final ContentType contentType) => true)
          .reply(409, {'message': 'duplicate key'});

      expect(
          repo.addToFavorites(
              artifact: Artifact(path: 'f', md5sum: testMd5), userId: userId),
          throwsA(isA<PostgrestException>()));
    });

    test('removeFromFavorites deletes by user_id + artifact_md5', () async {
      final interceptor = nock(baseUrl).delete((final Uri uri) =>
          uri.path == '$rest/Favorites' &&
          uri.queryParameters['user_id'] == 'eq.$userId' &&
          uri.queryParameters['artifact_md5'] == 'eq.$testMd5')
        ..reply(204, '');

      await repo.removeFromFavorites(
          artifact: Artifact(path: 'f.txt', md5sum: testMd5), userId: userId);

      expect(interceptor.isDone, isTrue);
    });

    test('removeFromFavorites is a no-op without artifact or user', () async {
      final interceptor = nock(baseUrl)
          .delete((final Uri uri) => uri.path == '$rest/Favorites')
        ..reply(204, '');

      await repo.removeFromFavorites(artifact: null, userId: userId);
      await repo.removeFromFavorites(
          artifact: Artifact(path: 'f', md5sum: testMd5), userId: null);

      expect(interceptor.isDone, isFalse);
    });
  });

  group('loadFavoritesArtifacts', () {
    test('calls the getfavoriteartifactsfor RPC and maps rows', () async {
      Map<String, dynamic>? sent;
      final interceptor = nock(baseUrl)
          .post('$rest/rpc/getfavoriteartifactsfor',
              (final List<int> body, final ContentType contentType) {
        sent = jsonDecode(utf8.decode(body)) as Map<String, dynamic>;
        return true;
      })
        ..reply(200, [
          {'name': 'one.txt', 'md5': 'aaa'},
          {'name': 'two.txt', 'md5': 'bbb'},
        ]);

      final favorites = await repo.loadFavoritesArtifacts(userId: userId);

      expect(interceptor.isDone, isTrue);
      expect(sent, {'userid': userId});
      expect(favorites.map((final a) => a.md5sum), ['aaa', 'bbb']);
      expect(favorites.first.name, 'one.txt');
    });

    test('returns empty list without a user, hitting no endpoint', () async {
      final interceptor = nock(baseUrl)
          .post('$rest/rpc/getfavoriteartifactsfor')
        ..reply(200, <Object?>[]);

      expect(await repo.loadFavoritesArtifacts(userId: null), isEmpty);
      expect(interceptor.isDone, isFalse);
    });

    test('THROWS on a 500 from the RPC', () async {
      nock(baseUrl)
          .post('$rest/rpc/getfavoriteartifactsfor',
              (final List<int> b, final ContentType contentType) => true)
          .reply(500, {'message': 'rpc exploded'});

      expect(repo.loadFavoritesArtifacts(userId: userId),
          throwsA(isA<PostgrestException>()));
    });
  });

  group('loginWithJwt', () {
    test('exchanges a valid session JSON for the user email', () async {
      final sessionJson = jsonEncode({
        'access_token': 'opaque-access-token',
        'token_type': 'bearer',
        'user': {
          'id': 'auth-user-1',
          'email': 'jwt@example.com',
          'app_metadata': <String, dynamic>{},
          'aud': 'authenticated',
          'created_at': '2026-01-01T00:00:00.000Z',
        },
      });

      final email = await repo.loginWithJwt(sessionJson);

      expect(email, 'jwt@example.com');
      expect(repo.userEmail, 'jwt@example.com');
    });

    test('throws on a malformed session payload', () async {
      expect(repo.loginWithJwt('not-json'), throwsA(anything));
    });
  });
}
