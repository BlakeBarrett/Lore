import 'package:lore/artifact.dart';
import 'package:lore/repo/lore_repo.dart';
import 'package:lore/remark.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthResponse, GoTrueClient, OtpChannel, OtpType, Session;

/// Shared no-arg call recorder for widget tests. Lives in a helper (not in
/// another test file) so importing it from a test never pulls in a second
/// `main()` — no test file imports another test file.
class MockFunction extends Mock {
  void call();
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

/// Hand-written fake of [GoTrueClient] for the auth-widget tests: scripts
/// success/failure for the two calls the OTP flow makes ([signInWithOtp] and
/// [verifyOTP]) and records the arguments of every call. Extends the real
/// client (rather than `implements`, which mockito can't back without codegen)
/// so it stays a drop-in `auth` value; `autoRefreshToken: false` keeps it
/// timer-free (no "pending timer" teardown errors) and no HTTP ever leaves
/// the process because both network methods are overridden.
class FakeGoTrueClient extends GoTrueClient {
  FakeGoTrueClient() : super(autoRefreshToken: false);

  /// When set, [signInWithOtp] throws it instead of succeeding.
  Object? signInError;

  /// When set, [verifyOTP] throws it instead of succeeding.
  Object? verifyError;

  /// Session returned by a successful [verifyOTP] (may stay null: the widget
  /// only cares that the call resolves without throwing).
  Session? sessionToReturn;

  final List<String?> signInEmails = [];
  final List<String?> signInRedirects = [];
  final List<String?> verifyTokens = [];
  final List<String?> verifyEmails = [];
  final List<OtpType> verifyTypes = [];

  @override
  Future<void> signInWithOtp({
    final String? email,
    final String? phone,
    final String? emailRedirectTo,
    final bool? shouldCreateUser,
    final Map<String, dynamic>? data,
    final String? captchaToken,
    final OtpChannel channel = OtpChannel.sms,
  }) async {
    signInEmails.add(email);
    signInRedirects.add(emailRedirectTo);
    if (signInError != null) throw signInError!;
  }

  @override
  Future<AuthResponse> verifyOTP({
    final String? email,
    final String? phone,
    final String? token,
    required final OtpType type,
    final String? redirectTo,
    final String? captchaToken,
    final String? tokenHash,
  }) async {
    verifyTokens.add(token);
    verifyEmails.add(email);
    verifyTypes.add(type);
    if (verifyError != null) throw verifyError!;
    return AuthResponse(session: sessionToReturn);
  }
}
