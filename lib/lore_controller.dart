import 'dart:async';
import 'dart:io';

import 'package:lore/artifact.dart';
import 'package:lore/hash_utils.dart';
import 'package:lore/md5_utils.dart';
import 'package:lore/repo/lore_repo.dart';
import 'package:lore/remark.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:regexpattern/regexpattern.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Resolves the loosely-typed `dynamic` that arrives from the UI (search bar,
/// app links, file pickers, drag-and-drop) into an [Artifact].
///
/// Pure extraction of the old 5-way type cascade in
/// `_LoreScaffoldWidgetState.onArtifactSelected`, so it is unit-testable
/// without any widgets: the only collaborator is [repo], which is consulted
/// solely for the "string that looks like an MD5" branch. Throws whatever the
/// repo/hashing layer throws — callers decide how to surface failures.
Future<Artifact> artifactFromInput(
    final dynamic value, final LoreRepo repo) async {
  if (value is Artifact) {
    return value;
  } else if (value is PlatformFile) {
    if (value.bytes != null) {
      final bytes = value.bytes!;
      final md5sum = await calculateMD5(Stream.fromIterable([bytes]));
      final sha256sum = await sha256FromStream(Stream.fromIterable([bytes]));
      return Artifact(path: value.name, md5sum: md5sum, sha256: sha256sum);
    } else {
      return Artifact.fromFile(File(value.path!));
    }
  } else if (value is String) {
    if (value.isMD5()) {
      return await repo.loadArtifact(value) ??
          Artifact(path: '', md5sum: value);
    } else if (value.isUri()) {
      return Artifact.fromURI(Uri.parse(value));
    } else {
      return Artifact(path: value, md5sum: md5SumFor(value));
    }
  } else if (value is List) {
    return value.first as Artifact;
  } else if (value is Future<({String name, Uint8List bytes})>) {
    // Web dropzone JS `File` handle, already reshaped by the handler into a
    // name+bytes future. Awaiting it *inside* select's try block means a
    // failed file read (or a rejected future handed over by the widget)
    // surfaces as a controller error and resets isCalculating.
    final file = await value;
    final md5sum = await calculateMD5(Stream.fromIterable([file.bytes]));
    final sha256sum = await sha256FromStream(Stream.fromIterable([file.bytes]));
    return Artifact(path: file.name, md5sum: md5sum, sha256: sha256sum);
  } else {
    // Unrecognisable drop payload: fail loudly instead of minting a
    // meaningless hash artifact from `value.toString()`.
    throw ArgumentError('Cannot open dropped value: $value');
  }
}

/// What the user should be told, classically, when a controller operation
/// fails. The view maps these to ARB keys (errorLoading / errorSaving /
/// errorDeleting / errorAuth); [LoreController.lastError] stays a
/// context+detail English string so unit tests and debug logs keep the
/// actionable specifics without needing a BuildContext.
enum LoreErrorKind { load, save, delete, auth, unknown }

/// View-model for the whole Lore scaffold: owns the selected [artifact],
/// the [favorites] list, the [isCalculating] flag, and the latest repo
/// failure ([lastError]) — state the god-widget used to own.
///
/// Design notes:
/// * `repo` is constructor-injected ([LoreRepo]); the auth event stream is
///   injected as a plain `Stream<AuthState>` seam so unit tests never touch
///   Supabase. The view wires it from `AppConfig.instance.supabase
///   .auth.onAuthStateChange`, replacing the manual subscription that used to
///   live in `_LoreScaffoldWidgetState.initState`.
/// * Every repo call is wrapped in try/catch. On failure the controller sets
///   [lastError] (a human-readable message; the view shows it verbatim for
///   now — U6 swaps in localized keys) and increments [errorSerial] without
///   mutating any optimistic state. On success the error is cleared.
/// * The view listens via `ListenableBuilder` and disposes this controller.
class LoreController extends ChangeNotifier {
  LoreController({
    required this.repo,
    final Stream<AuthState>? authEvents,
    final Session? initialSession,
  }) : session = initialSession {
    // The gotrue auth stream (a ReplaySubject) rethrows as an *unhandled
    // zone exception* — i.e. a crash — when a listener omits onError, which
    // happens on network errors during offline token refresh. Swallow the
    // error with the same semantics as every other failure path here
    // ([lastError] + [errorSerial], no optimistic state touched); the
    // subscription stays alive unless the source itself closes.
    _authSubscription = authEvents?.listen(
      _onAuthEvent,
      onError: (final Object e, final StackTrace st) {
        _fail('Auth event stream error.', LoreErrorKind.auth, e);
      },
      cancelOnError: false,
    );
  }

  final LoreRepo repo;

  /// Latest auth session, kept in sync from [authEvents]. The view still
  /// reads e-mail/token through [repo] (unchanged behaviour); this is the
  /// reactive hook that replaces the widget-level subscription.
  Session? session;

  Artifact? _artifact;
  Artifact? get artifact => _artifact;

  final List<Artifact> _favorites = [];
  List<Artifact> get favorites => List<Artifact>.unmodifiable(_favorites);

  bool _isCalculating = false;
  bool get isCalculating => _isCalculating;

  String? _lastError;
  String? get lastError => _lastError;

  LoreErrorKind _lastErrorKind = LoreErrorKind.unknown;
  LoreErrorKind get lastErrorKind => _lastErrorKind;

  /// Monotonically increasing counter, bumped on every failure even when the
  /// message repeats, so the view can show one SnackBar per error.
  int _errorSerial = 0;
  int get errorSerial => _errorSerial;

  StreamSubscription<AuthState>? _authSubscription;
  bool _disposed = false;

  void _onAuthEvent(final AuthState data) {
    debugPrint('Supabase AuthChangeEvent: ${data.event}');
    session = data.session;
    if (data.event == AuthChangeEvent.initialSession ||
        data.event == AuthChangeEvent.signedIn) {
      // Fire-and-forget, like the old widget listener; loadFavorites
      // captures its own failures into [lastError].
      loadFavorites();
    }
    _notify();
  }

  /// Selects an artifact from any of the loose UI input shapes
  /// (see [artifactFromInput]): resolves it, saves it, loads its remarks,
  /// and publishes it. On any failure [lastError] is set and the previously
  /// selected artifact stays untouched.
  Future<void> select(final dynamic value) async {
    setCalculating(true);
    try {
      final artifact = await artifactFromInput(value, repo);
      await repo.saveArtifact(artifact);
      artifact.remarks = await repo.loadRemarks(md5sum: artifact.md5sum);
      _artifact = artifact;
      _lastError = null;
    } catch (e) {
      _fail('Could not open that artifact.', LoreErrorKind.load, e);
    } finally {
      setCalculating(false);
    }
  }

  Future<void> search(final String value) => select(value);

  /// Opens the platform file picker and selects the chosen file.
  Future<void> openFile() async {
    try {
      final result = await FilePicker.platform
          .pickFiles(type: FileType.any, allowMultiple: false);
      if (result == null) return;
      await select(result.files.first);
    } catch (e) {
      _fail('Could not open the file picker.', LoreErrorKind.load, e);
    }
  }

  /// Adds/removes the current artifact from favorites. The backend call
  /// happens first; the local list only changes after it succeeds.
  Future<void> toggleFavorite() async {
    final artifact = _artifact;
    final userId = repo.userId;
    if (artifact == null || userId == null) return;

    try {
      if (_favorites.contains(artifact)) {
        await repo.removeFromFavorites(artifact: artifact, userId: userId);
        _favorites.remove(artifact);
      } else {
        await repo.addToFavorites(artifact: artifact, userId: userId);
        _favorites.add(artifact);
      }
      _lastError = null;
    } catch (e) {
      _fail('Could not update favorites.', LoreErrorKind.save, e);
    }
    _notify();
  }

  /// Saves [text] as a remark on the current artifact, then reloads the
  /// artifact's remarks. Remarks change only on success.
  Future<void> addRemark(final String text) async {
    final artifact = _artifact;
    if (artifact == null) return;
    // Capture the join key up front: every call below targets THIS artifact,
    // even if the selection changes mid-flight.
    final md5sum = artifact.md5sum;

    try {
      await repo.saveRemark(
        remark: text,
        md5sum: md5sum,
        userId: repo.userId,
      );
      final remarks = await repo.loadRemarks(md5sum: md5sum);
      // Stale-write guard: if the user selected a different artifact while
      // the awaits ran, don't publish remarks onto a selection that already
      // moved on (the server-side write against [md5sum] is still correct).
      if (identical(_artifact, artifact)) {
        artifact.remarks = remarks;
      }
      _lastError = null;
    } catch (e) {
      _fail('Could not save your remark.', LoreErrorKind.save, e);
    }
    _notify();
  }

  Future<void> deleteRemark(final Remark remark) async {
    try {
      await repo.deleteRemark(remark: remark);
      _artifact?.remarks?.remove(remark);
      _lastError = null;
    } catch (e) {
      _fail('Could not delete the remark.', LoreErrorKind.delete, e);
    }
    _notify();
  }

  Future<void> loadFavorites() async {
    if (repo.userId == null) return;
    try {
      final favorites = await repo.loadFavoritesArtifacts(userId: repo.userId);
      _favorites
        ..clear()
        ..addAll(favorites);
      _lastError = null;
    } catch (e) {
      _fail('Could not load favorites.', LoreErrorKind.load, e);
    }
    _notify();
  }

  /// Drop-target entry point. The handlers forward their raw dropped
  /// objects (desktop `desktop_drop` items, web dropzone values, or plain
  /// artifacts/strings); the first one wins and every shape is resolved by
  /// [select], whose try/finally guarantees `isCalculating` resets even when
  /// hashing, the repo, or the file itself blows up.
  Future<void> drop(final List<dynamic> values) async {
    if (values.isNotEmpty) {
      await select(values.first);
    }
  }

  /// Exposed so the drop handlers can drive the busy indicator while they
  /// hash a dropped file before [drop] runs.
  void setCalculating(final bool value) {
    if (_isCalculating != value) {
      _isCalculating = value;
      _notify();
    }
  }

  void _fail(
      final String context, final LoreErrorKind kind, final Object error) {
    _lastErrorKind = kind;
    _lastError = '$context $error';
    _errorSerial++;
    debugPrint(_lastError);
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _authSubscription?.cancel();
    _authSubscription = null;
    super.dispose();
  }
}
