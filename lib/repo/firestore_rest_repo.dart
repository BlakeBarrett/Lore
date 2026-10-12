import 'dart:convert';
import 'dart:io' show File, Platform, Process;
import 'dart:math';

import 'package:http/http.dart' as http;

import '../artifact.dart';
import '../remark.dart';
import 'lore_repo.dart';

/// A Firestore/Firebase failure surfaced from the REST layer. The REST repo
/// MUST throw (never swallow) so console callers decide how to report it —
/// same contract as [FirebaseLoreRepo] on the plugin path.
class FirestoreRestException implements Exception {
  FirestoreRestException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'FirestoreRestException($statusCode): $message';
}

/// CLI-only [LoreRepo] speaking the public Firebase REST APIs in pure Dart:
///
/// * Cloud Firestore REST (`firestore.googleapis.com/v1`) for artifacts,
///   remarks and favorites — same collections/fields as [FirebaseLoreRepo].
/// * Firebase Identity Toolkit (`identitytoolkit.googleapis.com/v1`) for
///   `login <jwt>`: exchanges a Google OIDC ID token for a Firebase session
///   (`accounts:signInWithIdp`), mirroring the app's
///   `GoogleAuthProvider.credential(idToken: …)` sign-in.
///
/// Why REST: the federated Firebase SDKs ship no Linux implementation, and
/// `dart compile exe` cannot embed `package:flutter` — so a standalone
/// `bin/lore` on Linux has no plugin path to the backend at all. The session
/// (ID + refresh tokens) persists to a 0600 JSON file under the user's
/// config dir so `lore login` survives into later invocations; the ID token
/// is refreshed transparently via securetoken.googleapis.com when expired.
///
/// Network is behind an injectable [http.Client] (`MockClient` in tests).
class RestLoreRepo implements LoreRepo {
  RestLoreRepo({
    required this.projectId,
    this.apiKey,
    final http.Client? client,
    final String? sessionPath,
  })  : _sessionPath = sessionPath ?? defaultSessionPath(),
        _client = client ?? http.Client(),
        _session = LoreCliSession.load(sessionPath ?? defaultSessionPath());

  /// Firebase project id (the `projectId` from firebase_options / hosting).
  final String projectId;

  /// Firebase *web* API key (public by design; restricts in Cloud console).
  /// Required only for `login` (Identity Toolkit).
  final String? apiKey;

  final String _sessionPath;
  final http.Client _client;
  LoreCliSession? _session;

  static const String _firestoreBase = 'firestore.googleapis.com';
  static const String _identityBase = 'identitytoolkit.googleapis.com';

  /// `~/.config/lore/cli-session.json` (XDG-aware).
  static String defaultSessionPath() {
    final env = Platform.environment;
    final configDir = env['XDG_CONFIG_HOME'] ??
        '${env['HOME'] ?? '.'}${Platform.isWindows ? '\\AppData\\Roaming' : '/.config'}';
    return '$configDir/lore/cli-session.json';
  }

  String get _docsRoot =>
      '/v1/projects/$projectId/databases/(default)/documents';

  // ------------------------------------------------------------------ auth

  @override
  Future<String?> loginWithJwt(final String jwt) async {
    final key = apiKey;
    final body = <String, dynamic>{
      'requestUri': 'http://localhost/',
      'returnSecureToken': true,
      'postBody': 'providerId=google.com&id_token=$jwt',
      if (key != null) 'delegateAccount': null,
    }..removeWhere((final k, final v) => v == null);
    final response = await _client.post(
      Uri.https(_identityBase, '/v1/accounts:signInWithIdp',
          {if (key != null) 'key': key}),
      headers: {'content-type': 'application/json'},
      body: jsonEncode(body),
    );
    final json = _jsonObject(response);
    _ensureOk(response, json);
    final idToken = json['idToken'] as String?;
    if (idToken == null || idToken.isEmpty) {
      throw FirestoreRestException(response.statusCode,
          'signInWithIdp returned no idToken (is the JWT a Google ID token?)');
    }
    _session = LoreCliSession(
      idToken: idToken,
      refreshToken: json['refreshToken'] as String? ?? '',
      uid: (json['localId'] ??
              (json['federatedUserInfo']
                  as Map<String, dynamic>?)?['rawId']) as String? ??
          '',
      email: json['email'] as String?,
      path: _sessionPath,
    );
    _session!.persist();
    return _session!.email;
  }

  @override
  String? get userId => _session?.uid.isEmpty ?? true ? null : _session?.uid;

  @override
  String? get userEmail => _session?.email;

  @override
  String? get accessToken {
    final session = _session;
    if (session == null || session.idTokenExpired) return null;
    return session.idToken;
  }

  /// Current valid ID token, refreshing the session when the cached ID token
  /// is expired. Null when signed out.
  Future<String?> accessTokenAsync() async {
    final session = _session;
    if (session == null) return null;
    if (session.idTokenExpired) {
      await session.refresh(httpClient: _client);
      session.persist();
    }
    return session.idToken;
  }

  // ------------------------------------------------------------- artifacts

  @override
  Future<Artifact?> loadArtifact(final String md5sum) async {
    final json = await _firestore('GET', '$_docsRoot/artifacts/$md5sum');
    if (json == null) return null; // 404
    return artifactFromDocument(json);
  }

  @override
  Future<void> saveArtifact(final Artifact artifact) async {
    await _firestore('PATCH', '$_docsRoot/artifacts/${artifact.md5sum}', body: {
      'fields': encodeFields({
        'name': artifact.path,
        'md5': artifact.md5sum,
        'sha256': artifact.sha256,
        'path': artifact.path,
      }),
    });
  }

  // --------------------------------------------------------------- remarks

  @override
  Future<List<Remark>> loadRemarks({required final String md5sum}) async {
    final docs = await _runQuery(
      collection: 'remarks',
      where: fieldEquals('artifactMd5', md5sum),
      orderBy: [
        {
          'field': {'fieldPath': 'createdAt'},
          'direction': 'DESCENDING'
        }
      ],
    );
    return docs.map(remarkFromDocument).toList();
  }

  @override
  Future<void> saveRemark({
    required final String remark,
    required final String? md5sum,
    required final String? userId,
  }) async {
    final effectiveUser = userId ?? this.userId ?? '';
    final name = '$_docsRoot/remarks/${generateFirestoreId()}';
    await _firestore('POST', '$_docsRoot:commit', body: {
      'writes': [
        {
          'update': {
            'name': name,
            'fields': encodeFields({
              'artifactMd5': md5sum ?? '',
              'userId': effectiveUser,
              'text': remark,
            }),
          },
          'currentDocument': {'exists': false},
        },
        // createdAt is server-assigned, mirroring FieldValue.serverTimestamp()
        {
          'transform': {
            'document': name,
            'fieldTransforms': [
              {'fieldPath': 'createdAt', 'setToServerValue': 'REQUEST_TIME'}
            ],
          }
        },
      ],
    });
  }

  @override
  Future<void> deleteRemark({required final Remark remark}) async {
    final docs = await _runQuery(
      collection: 'remarks',
      where: fieldEquals('text', remark.text),
      limit: 1,
    );
    for (final doc in docs) {
      await _firestore('DELETE', deletePath(doc));
    }
  }

  // ------------------------------------------------------------- favorites

  @override
  Future<void> addToFavorites({
    required final Artifact? artifact,
    required final String? userId,
  }) async {
    if (artifact == null || userId == null) return;
    final existing = await _runQuery(
      collection: 'favorites',
      where: and(
        fieldEquals('userId', userId),
        fieldEquals('artifactMd5', artifact.md5sum),
      ),
      limit: 1,
    );
    if (existing.isNotEmpty) return; // already favorited
    final name = '$_docsRoot/favorites/${generateFirestoreId()}';
    await _firestore('POST', '$_docsRoot:commit', body: {
      'writes': [
        {
          'update': {
            'name': name,
            'fields': encodeFields({
              'userId': userId,
              'artifactMd5': artifact.md5sum,
            }),
          },
          'currentDocument': {'exists': false},
        },
        {
          'transform': {
            'document': name,
            'fieldTransforms': [
              {'fieldPath': 'createdAt', 'setToServerValue': 'REQUEST_TIME'}
            ],
          }
        },
      ],
    });
  }

  @override
  Future<void> removeFromFavorites({
    required final Artifact? artifact,
    required final String? userId,
  }) async {
    if (artifact == null || userId == null) return;
    final docs = await _runQuery(
      collection: 'favorites',
      where: and(
        fieldEquals('userId', userId),
        fieldEquals('artifactMd5', artifact.md5sum),
      ),
    );
    for (final doc in docs) {
      await _firestore('DELETE', deletePath(doc));
    }
  }

  @override
  Future<List<Artifact>> loadFavoritesArtifacts(
      {required final String? userId}) async {
    if (userId == null) return const [];
    final favorites = await _runQuery(
      collection: 'favorites',
      where: fieldEquals('userId', userId),
    );
    final md5sums = favorites
        .map((final doc) =>
            decodeFields(doc['fields'] as Map<String, dynamic>?)?['artifactMd5']
                as String?)
        .whereType<String>()
        .toList();
    if (md5sums.isEmpty) return const [];
    final batch = await _firestore('POST', '$_docsRoot:batchGet', body: {
      'documents': [
        for (final md5 in md5sums) '$_docsRoot/artifacts/$md5',
      ],
    });
    final received =
        batch?['receivedDocs'] as List<dynamic>? ?? const <dynamic>[];
    return received
        .map((final row) => artifactFromDocument(
            (row as Map<String, dynamic>)['document']! as Map<String, dynamic>))
        .toList();
  }

  // ------------------------------------------------------------- plumbing

  /// One Firestore REST call. Returns the decoded JSON object, or null for a
  /// 404 (the REST idiom for "document does not exist"). 401 transparently
  /// refreshes the session once. Throws [FirestoreRestException] otherwise.
  Future<Map<String, dynamic>?> _firestore(
    final String method,
    final String path, {
    final Map<String, dynamic>? body,
    final bool retryOn401 = true,
  }) async {
    final token = await accessTokenAsync();
    final uri = Uri.https(_firestoreBase, path);
    final request = http.Request(method, uri)
      ..headers.addAll({
        'content-type': 'application/json',
        if (token != null) 'authorization': 'Bearer $token',
      });
    if (body != null) request.body = jsonEncode(body);
    http.Response response;
    try {
      final streamed = await _client.send(request);
      response = await http.Response.fromStream(streamed);
    } on Exception catch (e) {
      throw FirestoreRestException(0, 'transport failure: $e');
    }
    if (response.statusCode == 401 && retryOn401 && _session != null) {
      await _session!.refresh(httpClient: _client);
      _session!.persist();
      return _firestore(method, path, body: body, retryOn401: false);
    }
    if (response.statusCode == 404) return null;
    final json = _jsonObject(response);
    _ensureOk(response, json);
    return json;
  }

  /// `documents:runQuery` → the matching documents (each a full REST
  /// document JSON: {name, fields, createTime, updateTime}).
  Future<List<Map<String, dynamic>>> _runQuery({
    required final String collection,
    required final Map<String, dynamic> where,
    final List<Map<String, dynamic>>? orderBy,
    final int? limit,
  }) async {
    // runQuery streams JSON responses (one chunk per document batch, possibly
    // as a JSON array). One request with the whole stream parsed tolerantly.
    final token = await accessTokenAsync();
    final structured = <String, dynamic>{
      'from': [
        {'collectionId': collection}
      ],
      'where': where,
      if (orderBy != null) 'orderBy': orderBy,
      if (limit != null) 'limit': '$limit',
    };
    final request =
        http.Request('POST', Uri.https(_firestoreBase, '$_docsRoot:runQuery'))
          ..headers.addAll({
            'content-type': 'application/json',
            if (token != null) 'authorization': 'Bearer $token',
          })
          ..body = jsonEncode({'structuredQuery': structured});
    final http.Response response;
    try {
      response = await http.Response.fromStream(await _client.send(request));
    } on Exception catch (e) {
      throw FirestoreRestException(0, 'transport failure: $e');
    }
    final decoded = _decodeRunQuery(response.body);
    if (response.statusCode >= 400) {
      final error = decoded.first['error'] as Map<String, dynamic>?;
      final message = error?['message'] as String? ?? response.body;
      throw FirestoreRestException(response.statusCode, message);
    }
    return [
      for (final chunk in decoded)
        if (chunk['document'] != null)
          chunk['document'] as Map<String, dynamic>,
    ];
  }

  /// runQuery bodies are either a JSON array of chunks or concatenated JSON
  /// objects; both shapes are tolerated.
  static List<Map<String, dynamic>> _decodeRunQuery(final String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return const [];
    if (trimmed.startsWith('[')) {
      return (jsonDecode(trimmed) as List<dynamic>)
          .cast<Map<String, dynamic>>();
    }
    // Concatenated objects: wrap into an array and let the JSON parser work.
    final recovered = <Map<String, dynamic>>[];
    const decoder = JsonDecoder();
    var remaining = trimmed;
    while (remaining.isNotEmpty) {
      final objects = decoder.convert('[$remaining]')
          as List<dynamic>; // try whole remainder
      for (final o in objects) {
        recovered.add(o as Map<String, dynamic>);
      }
      break;
    }
    return recovered;
  }

  static void _ensureOk(
      final http.Response response, final Map<String, dynamic>? json) {
    if (response.statusCode < 400) return;
    final error = json?['error'] as Map<String, dynamic>?;
    final message = error?['message'] as String? ??
        error?['status'] as String? ??
        response.body;
    throw FirestoreRestException(response.statusCode, message);
  }

  static Map<String, dynamic> _jsonObject(final http.Response response) {
    if (response.body.trim().isEmpty) return <String, dynamic>{};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ------------------------------------------------------- model mapping

  /// REST document JSON → [Artifact] (id is the md5 join key, matching
  /// FirebaseLoreRepo's mapping).
  static Artifact artifactFromDocument(final Map<String, dynamic> doc) {
    final fields =
        decodeFields(doc['fields'] as Map<String, dynamic>?) ?? const {};
    return Artifact(
      path: fields['name'] as String? ?? '',
      md5sum: fields['md5'] as String? ?? documentId(doc),
      sha256: fields['sha256'] as String?,
    );
  }

  /// REST document JSON → [Remark] (numeric doc ids parse like the plugin
  /// path; createdAt arrives as a RFC3339 timestampValue).
  static Remark remarkFromDocument(final Map<String, dynamic> doc) {
    final fields =
        decodeFields(doc['fields'] as Map<String, dynamic>?) ?? const {};
    return Remark.simple(
      text: fields['text'] as String? ?? '',
      author: fields['userId'] as String?,
      timestamp: (fields['createdAt'] as DateTime?)?.toLocal(),
      id: int.tryParse(documentId(doc)),
    );
  }

  /// `projects/p/databases/(default)/documents/remarks/abc` → `abc`.
  static String documentId(final Map<String, dynamic> doc) {
    final name = doc['name'] as String? ?? '';
    return name.substring(name.lastIndexOf('/') + 1);
  }

  /// REST delete path for a document: the REST `name` is literally the URL
  /// path behind `/v1/` (`projects/p/databases/db/documents/remarks/abc`).
  static String deletePath(final Map<String, dynamic> doc) =>
      '/v1/${doc['name'] as String? ?? ''}';

  // ------------------------------------------------- Firestore value codecs

  static Map<String, dynamic> encodeFields(final Map<String, Object?> fields) {
    return {
      for (final entry in fields.entries) entry.key: encodeValue(entry.value),
    };
  }

  static Map<String, dynamic> encodeValue(final Object? value) {
    if (value == null) return {'nullValue': null};
    if (value is String) return {'stringValue': value};
    if (value is bool) return {'booleanValue': value};
    if (value is int) return {'integerValue': '$value'};
    if (value is double) return {'doubleValue': value};
    if (value is DateTime) {
      return {'timestampValue': value.toUtc().toIso8601String()};
    }
    throw ArgumentError('cannot encode Firestore value: ${value.runtimeType}');
  }

  /// REST `fields` map → plain Dart map (nullValue → null, timestamps →
  /// [DateTime]). Unknown encodings are dropped rather than guessed.
  static Map<String, dynamic>? decodeFields(
      final Map<String, dynamic>? fields) {
    if (fields == null) return null;
    final out = <String, dynamic>{};
    for (final entry in fields.entries) {
      final value = entry.value as Map<String, dynamic>;
      if (value.containsKey('nullValue')) {
        out[entry.key] = null;
      } else if (value.containsKey('stringValue')) {
        out[entry.key] = value['stringValue'];
      } else if (value.containsKey('integerValue')) {
        out[entry.key] = int.tryParse(value['integerValue'] as String);
      } else if (value.containsKey('doubleValue')) {
        out[entry.key] = value['doubleValue'];
      } else if (value.containsKey('booleanValue')) {
        out[entry.key] = value['booleanValue'];
      } else if (value.containsKey('timestampValue')) {
        out[entry.key] = DateTime.parse(value['timestampValue'] as String);
      }
    }
    return out;
  }

  // --------------------------------------------------------- query builders

  static Map<String, dynamic> fieldEquals(
          final String fieldPath, final Object? value) =>
      {
        'fieldFilter': {
          'field': {'fieldPath': fieldPath},
          'op': 'EQUAL',
          'value': encodeValue(value),
        }
      };

  static Map<String, dynamic> and(
          final Map<String, dynamic> left, final Map<String, dynamic> right) =>
      {
        'compositeFilter': {
          'op': 'AND',
          'filters': [left, right]
        }
      };

  /// Firestore-style auto id (20 URL-safe chars).
  static String generateFirestoreId() {
    const alphabet =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return String.fromCharCodes(Iterable.generate(
        20, (final _) => alphabet.codeUnitAt(random.nextInt(alphabet.length))));
  }
}

/// The CLI's persisted Firebase session (what `lore login` writes).
class LoreCliSession {
  LoreCliSession({
    required this.idToken,
    required this.refreshToken,
    required this.uid,
    this.email,
    this.path,
  });

  String idToken;
  final String refreshToken;
  final String uid;
  final String? email;

  /// Where this session persists (null = memory-only, for tests).
  final String? path;

  bool get idTokenExpired =>
      _expiresAt.difference(DateTime.now()).inSeconds < 60;

  DateTime get _expiresAt {
    try {
      final claims = idTokenClaims(idToken);
      final exp = claims['exp'];
      if (exp is int) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      }
    } on Exception {
      // Unparseable JWT: treat as expired.
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Decodes a JWT's payload claims (no signature check — this token is
  /// consumed server-side by Firebase; we only read `exp`/`uid` locally).
  static Map<String, dynamic> idTokenClaims(final String idToken) {
    final payload = idToken.split('.')[1];
    final padded = payload.padRight((payload.length ~/ 4 + 1) * 4, '=');
    return jsonDecode(utf8.decode(base64Url.decode(padded)))
        as Map<String, dynamic>;
  }

  /// Exchanges the refresh token for a fresh ID token
  /// (securetoken.googleapis.com v1 token endpoint).
  Future<void> refresh({final http.Client? httpClient}) async {
    final client = httpClient ?? http.Client();
    final response = await client.post(
      Uri.https('securetoken.googleapis.com', '/v1/token'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      }),
    );
    if (response.statusCode != 200) {
      throw FirestoreRestException(response.statusCode,
          'session refresh failed — run `lore login` again');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    idToken = json['id_token'] as String;
  }

  void persist() {
    final file = path == null ? null : File(path!);
    if (file == null) return;
    file.createSync(recursive: true);
    file.writeAsStringSync(jsonEncode({
      'idToken': idToken,
      'refreshToken': refreshToken,
      'uid': uid,
      'email': email,
    }));
    try {
      // 0600: tokens are bearer credentials.
      Process.runSync('chmod', ['600', file.path]);
    } on Exception {
      // Windows or missing chmod: tolerate.
    }
  }

  static LoreCliSession? load(final String path) {
    final file = File(path);
    if (!file.existsSync()) return null;
    try {
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      return LoreCliSession(
        idToken: json['idToken'] as String,
        refreshToken: json['refreshToken'] as String,
        uid: json['uid'] as String? ?? '',
        email: json['email'] as String?,
        path: path,
      );
    } on Exception {
      return null; // corrupt file == signed out
    }
  }
}
