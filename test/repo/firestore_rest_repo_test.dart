import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lore/artifact.dart';
import 'package:lore/remark.dart';
import 'package:lore/repo/firestore_rest_repo.dart';

/// [RestLoreRepo] against a scripted [MockClient]: every REST call shape the
/// standalone CLI depends on (Firestore document/runQuery/commit/batchGet +
/// Identity Toolkit login + securetoken refresh + on-disk session) is
/// asserted directly. Same wire format the real Firebase REST endpoints use.
void main() {
  const projectId = 'lore-test-project';
  const testMd5 = '1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d';

  late List<http.Request> sent;
  late List<String> bodies;

  /// Builds repo + handler from a scripted (status, body) queue per path
  /// suffix; `respondWith` overrides per call index.
  RestLoreRepo buildRepo(
    final List<(int, String)> Function(String pathSuffix)? responses, {
    final String? sessionPath,
    final http.Client? client,
  }) {
    sent = [];
    bodies = [];
    final callCounts = <String, int>{};
    final mock = client ??
        MockClient((final request) async {
          sent.add(request);
          bodies.add(request.body);
          final suffix =
              request.url.path.replaceAll(RegExp(r'^/v1/projects/[^/]+'), '');
          final index =
              callCounts.update(suffix, (final n) => n + 1, ifAbsent: () => 1);
          final scripted = responses?.call(suffix);
          if (scripted == null || scripted.isEmpty) {
            return http.Response('{}', 200);
          }
          final (status, body) = scripted[(index - 1) % scripted.length];
          return http.Response(body, status,
              headers: {'content-type': 'application/json'});
        });
    return RestLoreRepo(
      projectId: projectId,
      apiKey: 'test-web-key',
      client: mock,
      sessionPath: sessionPath,
    );
  }

  String artifactDocJson(final String md5,
      {final String? sha256, final String name = 'dir/file.txt'}) {
    return jsonEncode({
      'name':
          'projects/$projectId/databases/(default)/documents/artifacts/$md5',
      'fields': {
        'name': {'stringValue': name},
        'md5': {'stringValue': md5},
        'sha256': {
          if (sha256 != null) 'stringValue': sha256,
          if (sha256 == null) 'nullValue': null
        },
        'path': {'stringValue': name},
      },
    });
  }

  late Directory tempDir;
  String sessionPathFor(final String label) =>
      '${tempDir.path}/session-$label.json';

  setUp(() => tempDir = Directory.systemTemp.createTempSync('lore-rest-test'));
  tearDown(() => tempDir.deleteSync(recursive: true));

  group('loadArtifact', () {
    test(
        'maps a REST document to Artifact and sends no auth header when '
        'signed out', () async {
      final repo = buildRepo(
        (final s) => s.contains('artifacts')
            ? [(200, artifactDocJson(testMd5, sha256: 'sha-abc'))]
            : [],
      );

      final artifact = await repo.loadArtifact(testMd5);

      expect(artifact?.path, 'dir/file.txt');
      expect(artifact?.md5sum, testMd5);
      expect(artifact?.sha256, 'sha-abc');
      expect(sent.single.method, 'GET');
      expect(sent.single.url.path,
          '/v1/projects/$projectId/databases/(default)/documents/artifacts/$testMd5');
      expect(sent.single.headers.containsKey('authorization'), isFalse);
    });

    test('returns null on 404 (document does not exist)', () async {
      final repo =
          buildRepo((final s) => [(404, '{"error":{"message":"not found"}}')]);
      expect(await repo.loadArtifact(testMd5), isNull);
    });

    test('THROWS with the server message on failure', () async {
      final repo = buildRepo((final s) => [
            (
              500,
              '{"error":{"code":500,"message":"backend exploded","status":"INTERNAL"}}'
            )
          ]);
      expect(
        repo.loadArtifact(testMd5),
        throwsA(isA<FirestoreRestException>()
            .having((final e) => e.statusCode, 'statusCode', 500)
            .having((final e) => e.message, 'message', contains('exploded'))),
      );
    });
  });

  group('saveArtifact', () {
    test('PATCHes the full encoded field payload', () async {
      final repo = buildRepo((final s) => [(200, '{}')]);

      await repo.saveArtifact(
          Artifact(path: 'file.txt', md5sum: testMd5, sha256: 'sha-abc'));

      final request = sent.single;
      expect(request.method, 'PATCH');
      expect(request.url.path.endsWith('/artifacts/$testMd5'), isTrue);
      final body = jsonDecode(bodies.single) as Map<String, dynamic>;
      final fields = body['fields'] as Map<String, dynamic>;
      expect(fields['name'], {'stringValue': 'file.txt'});
      expect(fields['md5'], {'stringValue': testMd5});
      expect(fields['sha256'], {'stringValue': 'sha-abc'});
    });

    test('encodes a missing sha256 as nullValue', () async {
      final repo = buildRepo((final s) => [(200, '{}')]);

      await repo.saveArtifact(Artifact(path: 'file.txt', md5sum: testMd5));

      final body = jsonDecode(bodies.single) as Map<String, dynamic>;
      expect((body['fields'] as Map<String, dynamic>)['sha256'],
          contains('nullValue'));
    });

    test('THROWS on a rule rejection', () async {
      final repo = buildRepo((final s) => [
            (
              403,
              '{"error":{"code":403,"message":"Missing or invalid credentials."}}'
            )
          ]);
      expect(repo.saveArtifact(Artifact(path: 'f', md5sum: testMd5)),
          throwsA(isA<FirestoreRestException>()));
    });
  });

  group('loadRemarks', () {
    String remarkDoc(final String id, final String text,
            {final String? author, final String? createdAt}) =>
        jsonEncode({
          'readTime': '2026-10-11T00:00:00Z',
          'document': {
            'name':
                'projects/$projectId/databases/(default)/documents/remarks/$id',
            'fields': {
              'text': {'stringValue': text},
              'userId': {
                if (author != null) 'stringValue': author,
                if (author == null) 'nullValue': null
              },
              if (createdAt != null)
                'createdAt': {'timestampValue': createdAt}
              else
                'createdAt': {'nullValue': null},
            },
          },
        });

    test(
        'sends the structured query (artifactMd5 ==, createdAt DESC) and '
        'maps documents', () async {
      final repo = buildRepo((final s) => [
            (
              200,
              '[${remarkDoc('7', 'older', author: 'a', createdAt: '2026-01-01T00:00:00Z')},'
                  '${remarkDoc('8', 'newer', author: 'b', createdAt: '2026-01-02T00:00:00Z')}]'
            )
          ]);

      final remarks = await repo.loadRemarks(md5sum: testMd5);

      final queryBody = jsonDecode(bodies.single) as Map<String, dynamic>;
      final structured = queryBody['structuredQuery'] as Map<String, dynamic>;
      expect(structured['from'], [
        {'collectionId': 'remarks'}
      ]);
      final fieldFilter =
          ((structured['where']! as Map<String, dynamic>)['fieldFilter']!
              as Map<String, dynamic>)['field'] as Map<String, dynamic>;
      expect(fieldFilter['fieldPath'], 'artifactMd5');
      final orderByEntry =
          (structured['orderBy']! as List<dynamic>)[0] as Map<String, dynamic>;
      expect(orderByEntry['direction'], 'DESCENDING');
      expect(remarks.map((final r) => r.text), ['older', 'newer']);
      expect(remarks.map((final r) => r.id), [7, 8]);
      expect(remarks.first.author, 'a');
      expect(remarks.first.timestamp,
          DateTime.parse('2026-01-01T00:00:00Z').toLocal());
    });

    test('returns an empty list when nothing matches', () async {
      final repo = buildRepo((final s) => [(200, '[]')]);
      expect(await repo.loadRemarks(md5sum: testMd5), isEmpty);
    });

    test('tolerates concatenated (non-array) chunk bodies', () async {
      final repo =
          buildRepo((final s) => [(200, '${remarkDoc('1', 'chunky')}\n')]);
      final remarks = await repo.loadRemarks(md5sum: testMd5);
      expect(remarks.single.text, 'chunky');
    });

    test('THROWS on query failure', () async {
      final repo = buildRepo(
          (final s) => [(400, '{"error":{"message":"no such index exists"}}')]);
      expect(repo.loadRemarks(md5sum: testMd5),
          throwsA(isA<FirestoreRestException>()));
    });
  });

  group('saveRemark', () {
    test('commits a create + server-timestamp transform', () async {
      final repo = buildRepo((final s) => [(200, '{"writeResults":[{}]}')]);

      await repo.saveRemark(remark: 'hello', md5sum: testMd5, userId: 'u-1');

      final request = sent.single;
      expect(request.method, 'POST');
      expect(request.url.path.endsWith('documents:commit'), isTrue);
      final writes = ((jsonDecode(bodies.single)
              as Map<String, dynamic>)['writes'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(writes, hasLength(2));
      final update = writes[0]['update'] as Map<String, dynamic>;
      expect(update['name'], contains('/remarks/'));
      expect((update['fields'] as Map<String, dynamic>)['text'],
          {'stringValue': 'hello'});
      expect((update['fields'] as Map<String, dynamic>)['userId'],
          {'stringValue': 'u-1'});
      expect(writes[0]['currentDocument'], {'exists': false});
      final transform = writes[1]['transform'] as Map<String, dynamic>;
      expect(transform['document'], update['name']);
      expect(
          (transform['fieldTransforms']! as List<dynamic>).first
              is Map<String, dynamic>,
          isTrue);
      expect(
          ((transform['fieldTransforms']! as List<dynamic>).first
              as Map<String, dynamic>)['setToServerValue'],
          'REQUEST_TIME');
    });

    test('stores an empty artifactMd5 when the md5sum is null', () async {
      final repo = buildRepo((final s) => [(200, '{}')]);

      await repo.saveRemark(remark: 'x', md5sum: null, userId: 'u-1');

      final writes = ((jsonDecode(bodies.single)
              as Map<String, dynamic>)['writes'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final update = writes[0]['update'] as Map<String, dynamic>;
      expect((update['fields'] as Map<String, dynamic>)['artifactMd5'],
          {'stringValue': ''});
    });

    test('THROWS on a write rejection', () async {
      final repo = buildRepo(
          (final s) => [(403, '{"error":{"message":"rule denied"}}')]);
      expect(repo.saveRemark(remark: 'x', md5sum: testMd5, userId: 'u'),
          throwsA(isA<FirestoreRestException>()));
    });
  });

  group('deleteRemark', () {
    test('deletes the first matching document', () async {
      final repo = buildRepo((final s) => s.endsWith('documents:runQuery')
          ? [
              (
                200,
                '[{"document":{"name":"projects/$projectId/databases/(default)/documents/remarks/42","fields":{}}}]'
              )
            ]
          : [(200, '{}')]);

      await repo.deleteRemark(remark: const Remark.simple(text: 'bye', id: 7));

      expect(sent, hasLength(2));
      expect(sent[0].method, 'POST');
      expect(sent[1].method, 'DELETE');
      expect(sent[1].url.path,
          '/v1/projects/$projectId/databases/(default)/documents/remarks/42');
    });

    test('makes no DELETE when nothing matches', () async {
      final repo = buildRepo((final s) => [(200, '[]')]);

      await repo.deleteRemark(remark: const Remark.simple(text: 'gone', id: 7));

      expect(sent, hasLength(1));
      expect(sent.single.method, 'POST');
    });
  });

  group('favorites', () {
    test('addToFavorites commits only when no favorite exists yet', () async {
      final repo = buildRepo((final s) => s.endsWith('documents:runQuery')
          ? [(200, '[]')]
          : [(200, '{"writeResults":[{}]}')]);

      await repo.addToFavorites(
          artifact: Artifact(path: 'f.txt', md5sum: testMd5), userId: 'u-1');

      expect(sent, hasLength(2));
      final structured = (jsonDecode(bodies.first)
          as Map<String, dynamic>)['structuredQuery'] as Map<String, dynamic>;
      final composite =
          ((structured['where']! as Map<String, dynamic>)['compositeFilter']!
              as Map<String, dynamic>)['filters']! as List<dynamic>;
      expect(composite, hasLength(2));
      expect(sent[1].url.path.endsWith('documents:commit'), isTrue);
      final writes = ((jsonDecode(bodies[1]) as Map<String, dynamic>)['writes']
              as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final fields = (writes[0]['update'] as Map<String, dynamic>)['fields']
          as Map<String, dynamic>;
      expect(fields['userId'], {'stringValue': 'u-1'});
      expect(fields['artifactMd5'], {'stringValue': testMd5});
    });

    test('addToFavorites skips the commit when the favorite exists', () async {
      final repo = buildRepo((final s) => [
            (
              200,
              '[{"document":{"name":"projects/$projectId/databases/(default)/documents/favorites/zz","fields":{}}}]'
            )
          ]);

      await repo.addToFavorites(
          artifact: Artifact(path: 'f.txt', md5sum: testMd5), userId: 'u-1');

      expect(sent, hasLength(1)); // query only, no commit
    });

    test('addToFavorites/removeFromFavorites are no-ops without artifact/user',
        () async {
      final repo = buildRepo((final s) => [(200, '[]')]);

      await repo.addToFavorites(artifact: null, userId: 'u');
      await repo.addToFavorites(
          artifact: Artifact(path: 'f', md5sum: testMd5), userId: null);
      await repo.removeFromFavorites(artifact: null, userId: null);

      expect(sent, isEmpty);
    });

    test('removeFromFavorites deletes every matching document', () async {
      final repo = buildRepo((final s) => s.endsWith('documents:runQuery')
          ? [
              (
                200,
                '[{"document":{"name":"projects/$projectId/databases/(default)/documents/favorites/a","fields":{}}},'
                    '{"document":{"name":"projects/$projectId/databases/(default)/documents/favorites/b","fields":{}}}]'
              )
            ]
          : [(200, '{}')]);

      await repo.removeFromFavorites(
          artifact: Artifact(path: 'f.txt', md5sum: testMd5), userId: 'u-1');

      expect(sent.where((final r) => r.method == 'DELETE'), hasLength(2));
    });
  });

  group('loadFavoritesArtifacts', () {
    test('batchGets the favorited artifacts, skipping missing documents',
        () async {
      String fav(final String md5) => jsonEncode({
            'document': {
              'name':
                  'projects/$projectId/databases/(default)/documents/favorites/x-$md5',
              'fields': {
                'artifactMd5': {'stringValue': md5}
              },
            }
          });
      final repo = buildRepo((final s) {
        if (s.endsWith('documents:runQuery')) {
          return [(200, '[${fav('aaa')},${fav('bbb')}]')];
        }
        if (s.endsWith('documents:batchGet')) {
          return [
            (
              200,
              jsonEncode({
                'receivedDocs': [
                  {
                    'document':
                        jsonDecode(artifactDocJson('aaa', name: 'one.txt'))
                  }
                ],
                'missingDocs': [
                  'projects/$projectId/databases/(default)/documents/artifacts/bbb'
                ],
              })
            )
          ];
        }
        return [(200, '{}')];
      });

      final favorites = await repo.loadFavoritesArtifacts(userId: 'u-1');

      expect(favorites.map((final a) => a.md5sum), ['aaa']);
      expect(favorites.single.path, 'one.txt');
    });

    test('returns empty without a user and without any request', () async {
      final repo = buildRepo((final s) => [(200, '{}')]);

      expect(await repo.loadFavoritesArtifacts(userId: null), isEmpty);
      expect(sent, isEmpty);
    });

    test('skips batchGet when the user has no favorites', () async {
      final repo = buildRepo((final s) => [(200, '[]')]);

      expect(await repo.loadFavoritesArtifacts(userId: 'u-1'), isEmpty);
      expect(sent, hasLength(1)); // favorites query only
    });
  });

  group('login + session persistence', () {
    String fakeJwt({required final int expiresInSecs}) {
      final payload = base64Url
          .encode(utf8.encode(jsonEncode({
            'exp':
                DateTime.now().millisecondsSinceEpoch ~/ 1000 + expiresInSecs,
            'user_id': 'jwt-uid',
          })))
          .replaceAll('=', '');
      return 'header.$payload.signature';
    }

    test(
        'loginWithJwt exchanges the Google ID token, persists the session, '
        'and returns the e-mail', () async {
      final path = sessionPathFor('login');
      final repo = buildRepo(
          (final s) => [
                (
                  200,
                  jsonEncode({
                    'idToken': fakeJwt(expiresInSecs: 3600),
                    'refreshToken': 'refresh-1',
                    'localId': 'jwt-uid',
                    'email': 'jwt@example.com',
                  })
                )
              ],
          sessionPath: path);

      final email = await repo.loginWithJwt('google-id-token');

      expect(email, 'jwt@example.com');
      expect(sent.single.url.host, 'identitytoolkit.googleapis.com');
      expect((jsonDecode(bodies.single) as Map<String, dynamic>)['postBody'],
          contains('providerId=google.com'));
      expect(File(path).existsSync(), isTrue);
      expect(repo.userId, 'jwt-uid');
      expect(repo.userEmail, 'jwt@example.com');
      expect(repo.accessToken, isNotNull);

      // A fresh repo instance reads the session back from disk.
      final reloaded = buildRepo((final s) => [(200, '{}')], sessionPath: path);
      expect(reloaded.userEmail, 'jwt@example.com');
      expect(reloaded.accessToken, isNotNull);
    });

    test('loginWithJwt THROWS on an invalid token', () async {
      final repo = buildRepo((final s) => [
            (
              400,
              '{"error":{"code":400,"message":"INVALID_CREDENTIAL","message1":"INVALID_LOGIN"}}'
            )
          ]);
      expect(
          repo.loginWithJwt('garbage'), throwsA(isA<FirestoreRestException>()));
    });

    test('an expired ID token is refreshed through securetoken before use',
        () async {
      final path = sessionPathFor('refresh');
      // Persist a session whose id token is already expired.
      File(path)
        ..createSync(recursive: true)
        ..writeAsStringSync(jsonEncode({
          'idToken': fakeJwt(expiresInSecs: -60),
          'refreshToken': 'refresh-1',
          'uid': 'u-1',
          'email': 'u@example.com',
        }));

      final repo = buildRepo((final s) {
        if (s == '/v1/token') {
          return [
            (200, jsonEncode({'id_token': fakeJwt(expiresInSecs: 3600)}))
          ];
        }
        return [(200, artifactDocJson(testMd5, name: 'after-refresh.txt'))];
      }, sessionPath: path);

      final artifact = await repo.loadArtifact(testMd5);

      expect(artifact?.path, 'after-refresh.txt');
      expect(
          sent.map((final r) => r.url.host),
          containsAllInOrder(
              ['securetoken.googleapis.com', 'firestore.googleapis.com']));
      final firestoreAuth = sent
          .lastWhere((final r) => r.url.host == 'firestore.googleapis.com')
          .headers['authorization'];
      expect(firestoreAuth, isNotNull);
    });

    test('a 401 mid-request triggers one refresh-and-retry', () async {
      final path = sessionPathFor('retry');
      File(path)
        ..createSync(recursive: true)
        ..writeAsStringSync(jsonEncode({
          'idToken': fakeJwt(expiresInSecs: 3600), // not expired, but revoked
          'refreshToken': 'refresh-1',
          'uid': 'u-1',
          'email': 'u@example.com',
        }));

      var firestoreCalls = 0;
      final mock = MockClient((final request) async {
        if (request.url.host == 'securetoken.googleapis.com') {
          return http.Response(
              jsonEncode({'id_token': fakeJwt(expiresInSecs: 3600)}), 200,
              headers: {'content-type': 'application/json'});
        }
        firestoreCalls++;
        if (firestoreCalls == 1) {
          return http.Response('{"error":{"message":"token revoked"}}', 401,
              headers: {'content-type': 'application/json'});
        }
        return http.Response(artifactDocJson(testMd5), 200,
            headers: {'content-type': 'application/json'});
      });

      final repo =
          RestLoreRepo(projectId: projectId, client: mock, sessionPath: path);
      final artifact = await repo.loadArtifact(testMd5);

      expect(artifact?.md5sum, testMd5);
      expect(firestoreCalls, 2);
    });

    test('a corrupt session file means signed out, not a crash', () async {
      final path = sessionPathFor('corrupt');
      File(path)
        ..createSync(recursive: true)
        ..writeAsStringSync('not json at all {{{');

      final repo = buildRepo((final s) => [(200, '{}')], sessionPath: path);

      expect(repo.userId, isNull);
      expect(repo.userEmail, isNull);
      expect(repo.accessToken, isNull);
    });
  });

  group('value codecs', () {
    test('encodeValue covers the used Firestore types', () {
      expect(RestLoreRepo.encodeValue('s'), {'stringValue': 's'});
      expect(RestLoreRepo.encodeValue(7), {'integerValue': '7'});
      expect(RestLoreRepo.encodeValue(true), {'booleanValue': true});
      expect(RestLoreRepo.encodeValue(null), {'nullValue': null});
      expect(RestLoreRepo.encodeValue(DateTime.utc(2026, 1, 1)),
          {'timestampValue': '2026-01-01T00:00:00.000Z'});
      expect(() => RestLoreRepo.encodeValue(Object()),
          throwsA(isA<ArgumentError>()));
    });

    test('decodeFields decodes and drops unknown encodings', () {
      final decoded = RestLoreRepo.decodeFields({
        'a': {'stringValue': 'x'},
        'b': {'integerValue': '42'},
        'c': {'timestampValue': '2026-02-03T04:05:06Z'},
        'd': {'nullValue': null},
        'e': {
          'geoPointValue': {'latitude': 1, 'longitude': 2}
        },
      });
      expect(decoded, {
        'a': 'x',
        'b': 42,
        'c': DateTime.utc(2026, 2, 3, 4, 5, 6),
        'd': null
      });
    });

    test('generateFirestoreId yields 20 URL-safe chars, unique enough', () {
      final ids = {
        for (var i = 0; i < 50; i++) RestLoreRepo.generateFirestoreId()
      };
      expect(ids, hasLength(50));
      for (final id in ids) {
        expect(id, matches(RegExp(r'^[A-Za-z0-9]{20}$')));
      }
    });
  });
}
