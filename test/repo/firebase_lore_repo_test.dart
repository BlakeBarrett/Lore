import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore/app_config.dart';
import 'package:lore/artifact.dart';
import 'package:lore/remark.dart';
import 'package:lore/repo/firebase_lore_repo.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'firebase_lore_repo_test.mocks.dart';

/// Firestore's untyped document shape, spelled shortly for the typed mocks.
typedef FirestoreMap = Map<String, dynamic>;

/// [FirebaseLoreRepo] against mockito-codegen mocks of the Firebase SDK:
/// every Firestore/Firebase-Auth call the repo makes is scripted, and the
/// repository logic (document mapping, query chains, batch reads, duplicate
/// suppression, stale-id parsing, error propagation) is asserted directly.
/// The mocks are wired through [AppConfig.setMockServices], the repo's own
/// test seam — no platform channels, no network.
///
/// Fixture helpers below build and stub mock documents; they MUST be invoked
/// at stubbing time (before/around `when(...)`, never inside a `thenAnswer`
/// closure) — mockito's global call registry corrupts if `when()` runs while
/// an answer is executing, which leaks SmartFakes into later stubs.
@GenerateMocks([
  FirebaseAuth,
  FirebaseFirestore,
  CollectionReference,
  Query,
  DocumentReference,
  DocumentSnapshot,
  QueryDocumentSnapshot,
  QuerySnapshot,
  User,
  UserCredential,
])
void main() {
  const testMd5 = '1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d';
  const userId = 'user-123';

  late MockFirebaseAuth auth;
  late MockFirebaseFirestore firestore;
  late MockCollectionReference<FirestoreMap> artifacts;
  late MockCollectionReference<FirestoreMap> remarks;
  late MockCollectionReference<FirestoreMap> favorites;
  late MockQuery<FirestoreMap> query;
  late MockQuery<FirestoreMap> query2;
  late FirebaseLoreRepo repo;

  setUp(() {
    auth = MockFirebaseAuth();
    firestore = MockFirebaseFirestore();
    artifacts = MockCollectionReference<FirestoreMap>();
    remarks = MockCollectionReference<FirestoreMap>();
    favorites = MockCollectionReference<FirestoreMap>();
    query = MockQuery<FirestoreMap>();
    query2 = MockQuery<FirestoreMap>();
    when(firestore.collection('artifacts')).thenReturn(artifacts);
    when(firestore.collection('remarks')).thenReturn(remarks);
    when(firestore.collection('favorites')).thenReturn(favorites);
    AppConfig.setMockServices(auth: auth, firestore: firestore);
    repo = FirebaseLoreRepo();
  });

  tearDown(() => AppConfig.clearMockServices());

  // --- Fixture builders (call at stubbing time only — see note above) ---

  MockDocumentSnapshot<FirestoreMap> artifactDoc(
    final String id, {
    required final String name,
    final String? sha256,
  }) {
    final doc = MockDocumentSnapshot<FirestoreMap>();
    when(doc.id).thenReturn(id);
    when(doc.exists).thenReturn(true);
    when(doc.data()).thenReturn({
      'name': name,
      'md5': id,
      'sha256': sha256,
      'path': name,
    });
    return doc;
  }

  MockDocumentSnapshot<FirestoreMap> missingDoc() {
    final doc = MockDocumentSnapshot<FirestoreMap>();
    when(doc.exists).thenReturn(false);
    return doc;
  }

  MockQueryDocumentSnapshot<FirestoreMap> remarkDoc({
    required final String id,
    required final String text,
    final String? author,
    final DateTime? createdAt,
  }) {
    final doc = MockQueryDocumentSnapshot<FirestoreMap>();
    when(doc.id).thenReturn(id);
    when(doc.data()).thenReturn({
      'text': text,
      'userId': author,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt),
    });
    return doc;
  }

  MockQueryDocumentSnapshot<FirestoreMap> favoriteDoc(final String md5) {
    final doc = MockQueryDocumentSnapshot<FirestoreMap>();
    when(doc['artifactMd5']).thenReturn(md5);
    return doc;
  }

  MockQuerySnapshot<FirestoreMap> snapshotOf(
      final List<QueryDocumentSnapshot<FirestoreMap>> docs) {
    final snap = MockQuerySnapshot<FirestoreMap>();
    when(snap.docs).thenReturn(docs);
    return snap;
  }

  MockDocumentReference<FirestoreMap> documentRef() =>
      MockDocumentReference<FirestoreMap>();

  group('loadArtifact', () {
    test('maps a document to Artifact (id is the md5sum, name the path)',
        () async {
      final docRef = documentRef();
      final doc = artifactDoc(testMd5, name: 'dir/file.txt', sha256: 'sha-abc');
      when(artifacts.doc(testMd5)).thenReturn(docRef);
      when(docRef.get()).thenAnswer((final _) async => doc);

      final artifact = await repo.loadArtifact(testMd5);

      expect(artifact?.path, 'dir/file.txt');
      expect(artifact?.md5sum, testMd5);
      expect(artifact?.sha256, 'sha-abc');
    });

    test('returns null when the document does not exist', () async {
      final docRef = documentRef();
      final doc = missingDoc();
      when(artifacts.doc(testMd5)).thenReturn(docRef);
      when(docRef.get()).thenAnswer((final _) async => doc);

      expect(await repo.loadArtifact(testMd5), isNull);
    });

    test('treats a null sha256 as an unset value', () async {
      final docRef = documentRef();
      final doc = artifactDoc(testMd5, name: 'f.txt');
      when(artifacts.doc(testMd5)).thenReturn(docRef);
      when(docRef.get()).thenAnswer((final _) async => doc);

      final artifact = await repo.loadArtifact(testMd5);

      expect(artifact?.sha256, isNull);
    });

    test('THROWS on a Firestore failure (never swallows)', () async {
      final docRef = documentRef();
      when(artifacts.doc(testMd5)).thenReturn(docRef);
      when(docRef.get()).thenThrow(FirebaseException(
          plugin: 'cloud-firestore',
          code: 'unavailable',
          message: 'db exploded'));

      expect(repo.loadArtifact(testMd5), throwsA(isA<FirebaseException>()));
    });
  });

  group('saveArtifact', () {
    test('writes the full payload to the document keyed by md5sum', () async {
      final docRef = documentRef();
      when(artifacts.doc(testMd5)).thenReturn(docRef);
      FirestoreMap? sent;
      when(docRef.set(any, any)).thenAnswer((final invocation) async {
        sent = invocation.positionalArguments.first as FirestoreMap;
      });

      await repo.saveArtifact(
          Artifact(path: 'file.txt', md5sum: testMd5, sha256: 'sha-abc'));

      expect(sent, {
        'name': 'file.txt',
        'md5': testMd5,
        'sha256': 'sha-abc',
        'path': 'file.txt',
      });
    });

    test('stores a null sha256 as null (older rows may not carry one)',
        () async {
      final docRef = documentRef();
      when(artifacts.doc(testMd5)).thenReturn(docRef);
      FirestoreMap? sent;
      when(docRef.set(any, any)).thenAnswer((final invocation) async {
        sent = invocation.positionalArguments.first as FirestoreMap;
      });

      await repo.saveArtifact(Artifact(path: 'file.txt', md5sum: testMd5));

      expect(sent?['sha256'], isNull);
    });

    test('THROWS when the write fails', () async {
      final docRef = documentRef();
      when(artifacts.doc(testMd5)).thenReturn(docRef);
      when(docRef.set(any, any)).thenThrow(FirebaseException(
          plugin: 'cloud-firestore',
          code: 'permission-denied',
          message: 'rule rejected the write'));

      expect(repo.saveArtifact(Artifact(path: 'f', md5sum: testMd5)),
          throwsA(isA<FirebaseException>()));
    });
  });

  group('loadRemarks', () {
    test('maps documents in server order with parsed ids and local times',
        () async {
      final snap = snapshotOf([
        remarkDoc(
            id: '1',
            text: 'older',
            author: 'a',
            createdAt: DateTime.utc(2026, 1, 1)),
        remarkDoc(
            id: '2',
            text: 'newer',
            author: 'b',
            createdAt: DateTime.utc(2026, 1, 2)),
      ]);
      when(remarks.where('artifactMd5', isEqualTo: testMd5)).thenReturn(query);
      when(query.orderBy('createdAt', descending: true)).thenReturn(query);
      when(query.get()).thenAnswer((final _) async => snap);

      final remarksList = await repo.loadRemarks(md5sum: testMd5);

      expect(remarksList.map((final r) => r.text), ['older', 'newer']);
      expect(remarksList.map((final r) => r.id), [1, 2]);
      expect(remarksList.first.author, 'a');
      expect(remarksList.first.timestamp, DateTime.utc(2026, 1, 1).toLocal());
    });

    test('returns an empty list when no remarks match', () async {
      final snap = snapshotOf([]);
      when(remarks.where('artifactMd5', isEqualTo: testMd5)).thenReturn(query);
      when(query.orderBy('createdAt', descending: true)).thenReturn(query);
      when(query.get()).thenAnswer((final _) async => snap);

      expect(await repo.loadRemarks(md5sum: testMd5), isEmpty);
    });

    test('leaves id null when the document id is not numeric', () async {
      final snap =
          snapshotOf([remarkDoc(id: 'abc-uuid', text: 'no-numeric-id')]);
      when(remarks.where('artifactMd5', isEqualTo: testMd5)).thenReturn(query);
      when(query.orderBy('createdAt', descending: true)).thenReturn(query);
      when(query.get()).thenAnswer((final _) async => snap);

      final remarksList = await repo.loadRemarks(md5sum: testMd5);

      expect(remarksList.single.id, isNull);
    });

    test('THROWS on a Firestore failure (never swallows)', () async {
      when(remarks.where('artifactMd5', isEqualTo: testMd5)).thenReturn(query);
      when(query.orderBy('createdAt', descending: true)).thenReturn(query);
      when(query.get()).thenThrow(FirebaseException(
          plugin: 'cloud-firestore',
          code: 'unavailable',
          message: 'query failed'));

      expect(
          repo.loadRemarks(md5sum: testMd5), throwsA(isA<FirebaseException>()));
    });
  });

  group('saveRemark', () {
    test('inserts artifactMd5/userId/text with a server timestamp', () async {
      final newDoc = documentRef();
      when(remarks.doc()).thenReturn(newDoc);
      FirestoreMap? sent;
      when(newDoc.set(any, any)).thenAnswer((final invocation) async {
        sent = invocation.positionalArguments.first as FirestoreMap;
      });

      await repo.saveRemark(remark: 'hello', md5sum: testMd5, userId: userId);

      expect(sent?['artifactMd5'], testMd5);
      expect(sent?['userId'], userId);
      expect(sent?['text'], 'hello');
      expect(sent?['createdAt'], isA<FieldValue>());
    });

    test('falls back to the current user uid when userId is null', () async {
      final currentUser = MockUser();
      when(currentUser.uid).thenReturn('uid-from-auth');
      when(auth.currentUser).thenReturn(currentUser);

      final newDoc = documentRef();
      when(remarks.doc()).thenReturn(newDoc);
      FirestoreMap? sent;
      when(newDoc.set(any, any)).thenAnswer((final invocation) async {
        sent = invocation.positionalArguments.first as FirestoreMap;
      });

      await repo.saveRemark(remark: 'x', md5sum: testMd5, userId: null);

      expect(sent?['userId'], 'uid-from-auth');
    });

    test('stores an empty artifactMd5 when the md5sum is null', () async {
      final newDoc = documentRef();
      when(remarks.doc()).thenReturn(newDoc);
      FirestoreMap? sent;
      when(newDoc.set(any, any)).thenAnswer((final invocation) async {
        sent = invocation.positionalArguments.first as FirestoreMap;
      });

      await repo.saveRemark(remark: 'x', md5sum: null, userId: userId);

      expect(sent?['artifactMd5'], '');
    });

    test('THROWS when the write fails', () async {
      final newDoc = documentRef();
      when(remarks.doc()).thenReturn(newDoc);
      when(newDoc.set(any, any)).thenThrow(FirebaseException(
          plugin: 'cloud-firestore',
          code: 'unavailable',
          message: 'insert denied'));

      expect(repo.saveRemark(remark: 'x', md5sum: testMd5, userId: userId),
          throwsA(isA<FirebaseException>()));
    });
  });

  group('deleteRemark', () {
    test('deletes the first document matching the remark text', () async {
      final target = MockQueryDocumentSnapshot<FirestoreMap>();
      final targetRef = documentRef();
      final snap = snapshotOf([target]);
      when(target.reference).thenReturn(targetRef);
      when(remarks.where('text', isEqualTo: 'bye')).thenReturn(query);
      when(query.limit(1)).thenReturn(query2);
      when(query2.get()).thenAnswer((final _) async => snap);
      when(targetRef.delete()).thenAnswer((final _) async {});

      await repo.deleteRemark(remark: const Remark.simple(text: 'bye', id: 7));

      verify(targetRef.delete()).called(1);
    });

    test('makes no delete call when no document matches', () async {
      final targetRef = documentRef();
      final snap = snapshotOf([]);
      when(remarks.where('text', isEqualTo: 'nothing')).thenReturn(query);
      when(query.limit(1)).thenReturn(query2);
      when(query2.get()).thenAnswer((final _) async => snap);

      await repo.deleteRemark(
          remark: const Remark.simple(text: 'nothing', id: 8));

      verifyNever(targetRef.delete());
    });

    test('THROWS when the lookup fails', () async {
      when(remarks.where('text', isEqualTo: 'x')).thenReturn(query);
      when(query.limit(1)).thenReturn(query2);
      when(query2.get()).thenThrow(FirebaseException(
          plugin: 'cloud-firestore',
          code: 'unavailable',
          message: 'lookup failed'));

      expect(repo.deleteRemark(remark: const Remark.simple(text: 'x', id: 7)),
          throwsA(isA<FirebaseException>()));
    });
  });

  group('favorites', () {
    test('addToFavorites inserts when no favorite exists yet', () async {
      final emptySnap = snapshotOf([]);
      when(favorites.where('userId', isEqualTo: userId)).thenReturn(query);
      when(query.where('artifactMd5', isEqualTo: testMd5)).thenReturn(query2);
      when(query2.limit(1)).thenReturn(query);
      when(query.get()).thenAnswer((final _) async => emptySnap);
      FirestoreMap? sent;
      when(favorites.add(any)).thenAnswer((final invocation) async {
        sent = invocation.positionalArguments.first as FirestoreMap;
        return documentRef();
      });

      await repo.addToFavorites(
          artifact: Artifact(path: 'f.txt', md5sum: testMd5), userId: userId);

      expect(sent?['userId'], userId);
      expect(sent?['artifactMd5'], testMd5);
      expect(sent?['createdAt'], isA<FieldValue>());
    });

    test('addToFavorites skips the insert when the favorite already exists',
        () async {
      final existingSnap = snapshotOf([favoriteDoc(testMd5)]);
      when(favorites.where('userId', isEqualTo: userId)).thenReturn(query);
      when(query.where('artifactMd5', isEqualTo: testMd5)).thenReturn(query2);
      when(query2.limit(1)).thenReturn(query);
      when(query.get()).thenAnswer((final _) async => existingSnap);

      await repo.addToFavorites(
          artifact: Artifact(path: 'f.txt', md5sum: testMd5), userId: userId);

      verifyNever(favorites.add(any));
    });

    test('addToFavorites is a no-op without an artifact or a user', () async {
      await repo.addToFavorites(artifact: null, userId: userId);
      await repo.addToFavorites(
          artifact: Artifact(path: 'f', md5sum: testMd5), userId: null);

      verifyNever(favorites.where(any, isEqualTo: anyNamed('isEqualTo')));
      verifyNever(favorites.add(any));
    });

    test('addToFavorites THROWS when the lookup fails', () async {
      when(favorites.where('userId', isEqualTo: userId)).thenReturn(query);
      when(query.where('artifactMd5', isEqualTo: testMd5)).thenReturn(query2);
      when(query2.limit(1)).thenReturn(query);
      when(query.get()).thenThrow(FirebaseException(
          plugin: 'cloud-firestore',
          code: 'unavailable',
          message: 'lookup failed'));

      expect(
          repo.addToFavorites(
              artifact: Artifact(path: 'f', md5sum: testMd5), userId: userId),
          throwsA(isA<FirebaseException>()));
    });

    test('removeFromFavorites deletes every matching document', () async {
      final refA = documentRef();
      final refB = documentRef();
      final docA = MockQueryDocumentSnapshot<FirestoreMap>();
      final docB = MockQueryDocumentSnapshot<FirestoreMap>();
      final snap = snapshotOf([docA, docB]);
      when(docA.reference).thenReturn(refA);
      when(docB.reference).thenReturn(refB);
      when(favorites.where('userId', isEqualTo: userId)).thenReturn(query);
      when(query.where('artifactMd5', isEqualTo: testMd5)).thenReturn(query2);
      when(query2.get()).thenAnswer((final _) async => snap);
      when(refA.delete()).thenAnswer((final _) async {});
      when(refB.delete()).thenAnswer((final _) async {});

      await repo.removeFromFavorites(
          artifact: Artifact(path: 'f.txt', md5sum: testMd5), userId: userId);

      verify(refA.delete()).called(1);
      verify(refB.delete()).called(1);
    });

    test('removeFromFavorites is a no-op without an artifact or a user',
        () async {
      await repo.removeFromFavorites(artifact: null, userId: userId);
      await repo.removeFromFavorites(
          artifact: Artifact(path: 'f', md5sum: testMd5), userId: null);

      verifyNever(favorites.where(any, isEqualTo: anyNamed('isEqualTo')));
    });

    test('isFavorite reflects whether a matching document exists', () async {
      final existing = MockQueryDocumentSnapshot<FirestoreMap>();
      final responses = [
        snapshotOf([existing]),
        snapshotOf([])
      ];
      var responseIndex = 0;
      when(favorites.where('userId', isEqualTo: userId)).thenReturn(query);
      when(query.where('artifactMd5', isEqualTo: testMd5)).thenReturn(query2);
      when(query2.limit(1)).thenReturn(query);
      when(query.get())
          .thenAnswer((final _) async => responses[responseIndex++]);

      expect(await repo.isFavorite(userId, testMd5), isTrue);
      expect(await repo.isFavorite(userId, testMd5), isFalse);
    });
  });

  group('loadFavoritesArtifacts', () {
    test('batch-loads the favorited artifacts and skips missing documents',
        () async {
      final favSnap = snapshotOf(
          [favoriteDoc('aaa'), favoriteDoc('bbb'), favoriteDoc('ccc')]);
      final docA = documentRef();
      final docB = documentRef();
      final docC = documentRef();
      final snapA = artifactDoc('aaa', name: 'one.txt', sha256: 'sha-1');
      final snapB = artifactDoc('bbb', name: 'two.txt');
      final snapC = missingDoc();
      when(favorites.where('userId', isEqualTo: userId)).thenReturn(query);
      when(query.get()).thenAnswer((final _) async => favSnap);
      when(artifacts.doc('aaa')).thenReturn(docA);
      when(artifacts.doc('bbb')).thenReturn(docB);
      when(artifacts.doc('ccc')).thenReturn(docC);
      when(docA.get()).thenAnswer((final _) async => snapA);
      when(docB.get()).thenAnswer((final _) async => snapB);
      when(docC.get()).thenAnswer((final _) async => snapC);

      final favoriteArtifacts =
          await repo.loadFavoritesArtifacts(userId: userId);

      expect(favoriteArtifacts.map((final a) => a.md5sum), ['aaa', 'bbb']);
      expect(favoriteArtifacts.first.path, 'one.txt');
      expect(favoriteArtifacts.first.sha256, 'sha-1');
      expect(favoriteArtifacts.last.sha256, isNull);
    });

    test('returns an empty list without a user, hitting no collection',
        () async {
      expect(await repo.loadFavoritesArtifacts(userId: null), isEmpty);
      verifyNever(favorites.where(any, isEqualTo: anyNamed('isEqualTo')));
    });

    test('returns an empty list when the user has no favorites', () async {
      final emptySnap = snapshotOf([]);
      when(favorites.where('userId', isEqualTo: userId)).thenReturn(query);
      when(query.get()).thenAnswer((final _) async => emptySnap);

      expect(await repo.loadFavoritesArtifacts(userId: userId), isEmpty);
      verifyNever(artifacts.doc(any));
    });

    test('THROWS when the favorites query fails', () async {
      when(favorites.where('userId', isEqualTo: userId)).thenReturn(query);
      when(query.get()).thenThrow(FirebaseException(
          plugin: 'cloud-firestore',
          code: 'unavailable',
          message: 'query failed'));

      expect(repo.loadFavoritesArtifacts(userId: userId),
          throwsA(isA<FirebaseException>()));
    });
  });

  group('auth passthrough', () {
    test('loginWithJwt signs in via a Google credential and returns the email',
        () async {
      final user = MockUser();
      when(user.email).thenReturn('jwt@example.com');
      when(auth.currentUser).thenReturn(user);
      final userCredential = MockUserCredential();
      when(userCredential.user).thenReturn(user);
      AuthCredential? sentCredential;
      when(auth.signInWithCredential(any)).thenAnswer((final invocation) async {
        sentCredential =
            invocation.positionalArguments.single as AuthCredential;
        return userCredential;
      });

      final email = await repo.loginWithJwt('opaque-jwt');

      expect(email, 'jwt@example.com');
      expect(sentCredential, isA<GoogleAuthCredential>());
      expect((sentCredential! as GoogleAuthCredential).idToken, 'opaque-jwt');
      expect(repo.userEmail, 'jwt@example.com');
    });

    test('loginWithJwt THROWS on an invalid token', () async {
      when(auth.signInWithCredential(any)).thenThrow(FirebaseException(
          plugin: 'firebase_auth',
          code: 'invalid-credential',
          message: 'token expired'));

      expect(
          repo.loginWithJwt('not-a-token'), throwsA(isA<FirebaseException>()));
    });

    test('userId and userEmail mirror the current auth user', () async {
      final user = MockUser();
      when(user.uid).thenReturn('uid-1');
      when(user.email).thenReturn('u@example.com');
      when(auth.currentUser).thenReturn(user);

      expect(repo.userId, 'uid-1');
      expect(repo.userEmail, 'u@example.com');
    });

    test('userId and userEmail are null when signed out', () async {
      when(auth.currentUser).thenReturn(null);

      expect(repo.userId, isNull);
      expect(repo.userEmail, isNull);
    });

    test('accessToken is null while signed out', () async {
      when(auth.currentUser).thenReturn(null);

      expect(repo.accessToken, isNull);
      expect(await repo.accessTokenAsync, isNull);
    });

    test('accessTokenAsync returns the cached id token', () async {
      final user = MockUser();
      when(auth.currentUser).thenReturn(user);
      when(user.getIdToken(false))
          .thenAnswer((final _) async => 'cached-token');

      expect(await repo.accessTokenAsync, 'cached-token');
    });
  });

  group('streams', () {
    test('remarksStream emits the mapped remark list', () async {
      final snap = snapshotOf([
        remarkDoc(
            id: '1',
            text: 'live',
            author: 'a',
            createdAt: DateTime.utc(2026, 1, 1))
      ]);
      when(remarks.where('artifactMd5', isEqualTo: testMd5)).thenReturn(query);
      when(query.orderBy('createdAt', descending: true)).thenReturn(query);
      when(query.snapshots()).thenAnswer((final _) => Stream.value(snap));

      final remarksList = await repo.remarksStream(md5sum: testMd5).first;

      expect(remarksList.single.text, 'live');
      expect(remarksList.single.author, 'a');
    });

    test('artifactsStream emits the mapped artifact list', () async {
      final doc = MockQueryDocumentSnapshot<FirestoreMap>();
      final snap = snapshotOf([doc]);
      when(doc.id).thenReturn('aaa');
      when(doc.exists).thenReturn(true);
      when(doc.data()).thenReturn({
        'name': 'streamed.txt',
        'md5': 'aaa',
        'sha256': 'sha-s',
        'path': 'streamed.txt',
      });
      when(artifacts.snapshots()).thenAnswer((final _) => Stream.value(snap));

      final artifactsList = await repo.artifactsStream().first;

      expect(artifactsList.single.path, 'streamed.txt');
      expect(artifactsList.single.md5sum, 'aaa');
      expect(artifactsList.single.sha256, 'sha-s');
    });
  });
}
