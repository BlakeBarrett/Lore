import 'dart:async';
import 'dart:io';

import 'package:Lore/artifact.dart';
import 'package:Lore/hash_utils.dart';
import 'package:Lore/md5_utils.dart';
import 'package:Lore/repo/lore_repo.dart';
import 'package:Lore/remark.dart';
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
  } else {
    return Artifact(path: value, md5sum: md5SumFor(value));
  }
}

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
    Stream<AuthState>? authEvents,
    Session? initialSession,
  }) : session = initialSession {
    _authSubscription = authEvents?.listen(_onAuthEvent);
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
      _fail('Could not open that artifact.', e);
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
      _fail('Could not open the file picker.', e);
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
      _fail('Could not update favorites.', e);
    }
    _notify();
  }

  /// Saves [text] as a remark on the current artifact, then reloads the
  /// artifact's remarks. Remarks change only on success.
  Future<void> addRemark(final String text) async {
    final artifact = _artifact;
    if (artifact == null) return;

    try {
      await repo.saveRemark(
        remark: text,
        md5sum: artifact.md5sum,
        userId: repo.userId,
      );
      artifact.remarks = await repo.loadRemarks(md5sum: artifact.md5sum);
      _lastError = null;
    } catch (e) {
      _fail('Could not save your remark.', e);
    }
    _notify();
  }

  Future<void> deleteRemark(final Remark remark) async {
    try {
      await repo.deleteRemark(remark: remark);
      _artifact?.remarks?.remove(remark);
      _lastError = null;
    } catch (e) {
      _fail('Could not delete the remark.', e);
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
      _fail('Could not load favorites.', e);
    }
    _notify();
  }

  /// Drop-target entry point. The handlers already collapse the drop to a
  /// single [Artifact]; the first one wins, matching the old contract.
  Future<void> drop(final List<Artifact> values) async {
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

  void _fail(final String context, final Object error) {
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
