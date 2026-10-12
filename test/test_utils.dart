import 'package:firebase_auth/firebase_auth.dart';
import 'package:lore/artifact.dart';
import 'package:lore/repo/lore_repo.dart';
import 'package:lore/remark.dart';
import 'package:mockito/mockito.dart';

/// Shared no-arg call recorder for widget tests. Lives in a helper (not in
/// another test file) so importing it from a test never pulls in a second
/// `main()` — no test file imports another test file.
class MockFunction extends Mock {
  void call();
}

/// Hand-written fake of [FirebaseAuth] for widget tests: reports the scripted
/// [currentUser] and nothing else. Injected via `AppConfig.setMockServices`
/// so the static accessors never touch the (un-initialised) FirebaseAuth
/// singleton. Un-stubbed members throw loudly rather than silently default —
/// the scaffold build path only reads [currentUser].
class FakeFirebaseAuth implements FirebaseAuth {
  FakeFirebaseAuth({this.currentUser});

  @override
  final User? currentUser;

  @override
  Stream<User?> authStateChanges() => const Stream<User?>.empty();

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      throw UnimplementedError('FakeFirebaseAuth: $invocation not stubbed');
}

/// Hand-written fake of [LoreRepo]: scripted return values, scripted failures,
/// and call recording. No mocks, no network. Shared by the controller tests
/// and the root-view (LoreScaffoldWidget) tests.
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

  /// When set, [loadRemarks] awaits this future before returning — lets a
  /// test hold the load open across a concurrent select (stale-write race).
  Future<void>? loadRemarksGate;

  /// When set, [loadFavoritesArtifacts] awaits this future before returning
  /// — lets a test hold the load open across a sign-out (stale-favorites
  /// race).
  Future<void>? loadFavoritesGate;

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
    if (loadRemarksGate != null) await loadRemarksGate;
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
    if (loadFavoritesGate != null) await loadFavoritesGate;
    return favoritesToReturn;
  }

  @override
  Future<String?> loginWithJwt(final String jwt) async => userEmail;
}
