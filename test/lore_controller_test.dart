import 'dart:async';
import 'dart:typed_data';

import 'package:Lore/artifact.dart';
import 'package:Lore/lore_controller.dart';
import 'package:Lore/md5_utils.dart';
import 'package:Lore/repo/lore_repo.dart';
import 'package:Lore/remark.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState;

/// Hand-written fake of [LoreRepo]: scripted return values, scripted failures,
/// and call recording. No mocks, no network.
class FakeLoreRepo implements LoreRepo {
  FakeLoreRepo({this.userId = 'user-1'});

  @override
  String? userId;

  // Scripted failures: set a field to an error and the call throws it.
  Object? throwOnLoadArtifact;
  Object? throwOnSaveArtifact;
  Object? throwOnLoadRemarks;
  Object? throwOnSaveRemark;
  Object? throwOnDeleteRemark;
  Object? throwOnAddToFavorites;
  Object? throwOnRemoveFromFavorites;
  Object? throwOnLoadFavorites;

  Artifact? artifactToReturn;
  List<Remark> remarksToReturn = [];
  List<Artifact> favoritesToReturn = [];

  final List<String> loadedMd5s = [];
  final List<Artifact> savedArtifacts = [];
  final List<Remark> savedRemarks = [];
  final List<Remark> deletedRemarks = [];
  final List<Artifact> addedToFavorites = [];
  final List<Artifact> removedFavorites = [];
  int loadFavoritesCalls = 0;

  @override
  String? get accessToken => userId == null ? null : 'token';

  @override
  String? get userEmail => userId == null ? null : 'test@example.com';

  @override
  Future<Artifact?> loadArtifact(final String md5sum) async {
    if (throwOnLoadArtifact != null) throw throwOnLoadArtifact!;
    loadedMd5s.add(md5sum);
    return artifactToReturn;
  }

  @override
  Future<void> saveArtifact(final Artifact artifact) async {
    if (throwOnSaveArtifact != null) throw throwOnSaveArtifact!;
    savedArtifacts.add(artifact);
  }

  @override
  Future<List<Remark>> loadRemarks({required final String md5sum}) async {
    if (throwOnLoadRemarks != null) throw throwOnLoadRemarks!;
    return remarksToReturn;
  }

  @override
  Future<void> saveRemark({
    required final String remark,
    required final String? md5sum,
    required final String? userId,
  }) async {
    if (throwOnSaveRemark != null) throw throwOnSaveRemark!;
    savedRemarks.add(Remark.simple(text: remark, author: userId));
  }

  @override
  Future<void> deleteRemark({required final Remark remark}) async {
    if (throwOnDeleteRemark != null) throw throwOnDeleteRemark!;
    deletedRemarks.add(remark);
  }

  @override
  Future<void> addToFavorites({
    required final Artifact? artifact,
    required final String? userId,
  }) async {
    if (throwOnAddToFavorites != null) throw throwOnAddToFavorites!;
    if (artifact != null) addedToFavorites.add(artifact);
  }

  @override
  Future<void> removeFromFavorites({
    required final Artifact? artifact,
    required final String? userId,
  }) async {
    if (throwOnRemoveFromFavorites != null) {
      throw throwOnRemoveFromFavorites!;
    }
    if (artifact != null) removedFavorites.add(artifact);
  }

  @override
  Future<List<Artifact>> loadFavoritesArtifacts(
      {required final String? userId}) async {
    if (throwOnLoadFavorites != null) throw throwOnLoadFavorites!;
    loadFavoritesCalls++;
    return favoritesToReturn;
  }

  @override
  Future<String?> loginWithJwt(final String jwt) async => userEmail;
}

void main() {
  final knownMd5 = md5SumFor('known artifact');
  final knownArtifact = Artifact(path: 'known.txt', md5sum: 'deadbeef');

  group('artifactFromInput', () {
    test('Artifact passes straight through', () async {
      final repo = FakeLoreRepo();
      expect(await artifactFromInput(knownArtifact, repo), same(knownArtifact));
      expect(repo.loadedMd5s, isEmpty);
    });

    test('PlatformFile with bytes hashes the bytes', () async {
      final repo = FakeLoreRepo();
      final file = PlatformFile(
          name: 'dropped.png',
          bytes: Uint8List.fromList([1, 2, 3, 4]),
          size: 4);
      final artifact = await artifactFromInput(file, repo);
      expect(artifact.path, 'dropped.png');
      expect(artifact.md5sum, isNotEmpty);
      expect(artifact.sha256, isNotEmpty);
    });

    test('String md5 loads from repo, falls back to empty-path artifact',
        () async {
      final repo = FakeLoreRepo()..artifactToReturn = knownArtifact;
      final found = await artifactFromInput(knownMd5, repo);
      expect(found, same(knownArtifact));
      expect(repo.loadedMd5s, [knownMd5]);

      final missRepo = FakeLoreRepo();
      final miss = await artifactFromInput(knownMd5, missRepo);
      expect(miss.md5sum, knownMd5);
      expect(miss.path, '');
    });

    test('String uri becomes an Artifact from its URI', () async {
      final repo = FakeLoreRepo();
      final artifact =
          await artifactFromInput('https://example.com/thing', repo);
      expect(artifact.path, 'https://example.com/thing');
      expect(artifact.md5sum, md5SumFor('https://example.com/thing'));
    });

    test('plain String is hashed as text', () async {
      final repo = FakeLoreRepo();
      final artifact = await artifactFromInput('hello lore', repo);
      expect(artifact.path, 'hello lore');
      expect(artifact.md5sum, md5SumFor('hello lore'));
    });

    test('List takes the first Artifact', () async {
      final repo = FakeLoreRepo();
      final other = Artifact(path: 'b.txt', md5sum: 'b');
      final artifact =
          await artifactFromInput(<Artifact>[knownArtifact, other], repo);
      expect(artifact, same(knownArtifact));
    });
  });

  group('LoreController', () {
    test('select happy path saves artifact, loads remarks, clears error',
        () async {
      final repo = FakeLoreRepo()
        ..remarksToReturn = [Remark.simple(text: 'nice', id: 1)];
      final controller = LoreController(repo: repo);
      addTearDown(controller.dispose);

      await controller.select('hello lore');

      expect(controller.artifact?.path, 'hello lore');
      expect(controller.artifact?.remarks, hasLength(1));
      expect(repo.savedArtifacts, hasLength(1));
      expect(controller.lastError, isNull);
      expect(controller.isCalculating, isFalse);
    });

    test('select error sets lastError and leaves state untouched', () async {
      final repo = FakeLoreRepo();
      final controller = LoreController(repo: repo);
      addTearDown(controller.dispose);

      await controller.select('hello lore');
      final before = controller.artifact;
      final beforeRemarks = controller.artifact?.remarks;

      repo.throwOnSaveArtifact = StateError('boom');
      await controller.select('other thing');

      expect(controller.lastError, contains('boom'));
      expect(controller.errorSerial, 1);
      expect(controller.artifact, same(before));
      expect(controller.artifact?.remarks, equals(beforeRemarks));
      expect(controller.isCalculating, isFalse);
    });

    test('toggleFavorite adds then removes', () async {
      final repo = FakeLoreRepo();
      final controller = LoreController(repo: repo);
      addTearDown(controller.dispose);

      await controller.select(knownArtifact);

      await controller.toggleFavorite();
      expect(repo.addedToFavorites, [knownArtifact]);
      expect(controller.favorites, [knownArtifact]);

      await controller.toggleFavorite();
      expect(repo.removedFavorites, [knownArtifact]);
      expect(controller.favorites, isEmpty);
    });

    test('toggleFavorite failure surfaces error, list unchanged', () async {
      final repo = FakeLoreRepo()..throwOnAddToFavorites = StateError('nope');
      final controller = LoreController(repo: repo);
      addTearDown(controller.dispose);

      await controller.select(knownArtifact);
      await controller.toggleFavorite();

      expect(controller.lastError, contains('nope'));
      expect(controller.favorites, isEmpty);
    });

    test('toggleFavorite without artifact or user is a no-op', () async {
      final repo = FakeLoreRepo();
      final controller = LoreController(repo: repo);
      addTearDown(controller.dispose);

      await controller.toggleFavorite(); // no artifact selected
      expect(repo.addedToFavorites, isEmpty);

      repo.userId = null;
      await controller.select(knownArtifact);
      await controller.toggleFavorite();
      expect(repo.addedToFavorites, isEmpty);
    });

    test('addRemark updates remarks only on success', () async {
      final repo = FakeLoreRepo()..remarksToReturn = [];
      final controller = LoreController(repo: repo);
      addTearDown(controller.dispose);

      await controller.select(knownArtifact);
      final remarksAfterSelect = controller.artifact?.remarks;

      repo.throwOnSaveRemark = StateError('deny');
      await controller.addRemark('failed remark');
      expect(controller.lastError, contains('deny'));
      expect(controller.artifact?.remarks, same(remarksAfterSelect));
      expect(repo.savedRemarks, isEmpty);

      repo.throwOnSaveRemark = null;
      repo.remarksToReturn = [Remark.simple(text: 'saved', id: 7)];
      await controller.addRemark('saved');
      expect(controller.lastError, isNull);
      expect(repo.savedRemarks, hasLength(1));
      expect(
          controller.artifact?.remarks, [Remark.simple(text: 'saved', id: 7)]);
    });

    test('deleteRemark removes locally only after the repo succeeds', () async {
      final remark = Remark.simple(text: 'delete me', id: 3);
      final repo = FakeLoreRepo()..remarksToReturn = [remark];
      final controller = LoreController(repo: repo);
      addTearDown(controller.dispose);

      await controller.select(knownArtifact);
      expect(controller.artifact?.remarks, [remark]);

      repo.throwOnDeleteRemark = StateError('no');
      await controller.deleteRemark(remark);
      expect(controller.lastError, contains('no'));
      expect(controller.artifact?.remarks, [remark]);

      repo.throwOnDeleteRemark = null;
      await controller.deleteRemark(remark);
      expect(controller.artifact?.remarks, isEmpty);
    });

    test('loadFavorites populates list; anonymous is a no-op', () async {
      final repo = FakeLoreRepo()..favoritesToReturn = [knownArtifact];
      final controller = LoreController(repo: repo);
      addTearDown(controller.dispose);

      await controller.loadFavorites();
      expect(controller.favorites, [knownArtifact]);

      repo.userId = null;
      await controller.loadFavorites();
      expect(repo.loadFavoritesCalls, 1); // not called while anonymous
      expect(controller.favorites, [knownArtifact]); // unchanged
    });

    test('drop selects the first artifact', () async {
      final repo = FakeLoreRepo();
      final controller = LoreController(repo: repo);
      addTearDown(controller.dispose);

      final second = Artifact(path: 'second.txt', md5sum: 'second');
      await controller.drop([knownArtifact, second]);
      expect(controller.artifact, same(knownArtifact));

      await controller.drop([]); // empty drop is ignored
      expect(controller.artifact, same(knownArtifact));
    });

    test(
        'auth events drive session state and loadFavorites, and dispose '
        'cancels the subscription without crashing', () async {
      final repo = FakeLoreRepo();
      final auth = StreamController<AuthState>();
      final controller = LoreController(repo: repo, authEvents: auth.stream);

      auth.add(const AuthState(AuthChangeEvent.signedIn, null));
      await Future<void>.microtask(() {});
      await Future<void>.microtask(() {});
      expect(controller.session, isNull); // session payload was null
      expect(repo.loadFavoritesCalls, 1);

      // Disposing cancels the subscription: further events are inert and
      // dispose itself must not throw.
      controller.dispose();
      auth.add(const AuthState(AuthChangeEvent.signedOut, null));
      await Future<void>.microtask(() {});
      expect(repo.loadFavoritesCalls, 1);
      await auth.close();
    });

    test('setCalculating notifies listeners with the busy flag', () async {
      final controller = LoreController(repo: FakeLoreRepo());
      addTearDown(controller.dispose);

      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.setCalculating(true);
      expect(controller.isCalculating, isTrue);
      controller.setCalculating(true); // no-op, no notification
      expect(notifications, 1);
      controller.setCalculating(false);
      expect(notifications, 2);
    });
  });
}
