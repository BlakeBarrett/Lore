// Firebase-backed implementation of LoreRepo, using Firestore for persistence
// and firebase_auth for authentication. Replaces SupabaseLoreRepo.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../app_config.dart' show AppConfig;
import 'package:lore/artifact.dart';
import 'package:lore/remark.dart';
import 'lore_repo.dart';

/// Firestore-backed repository that replaces SupabaseLoreRepo.
///
/// Data model mapping (Supabase → Firestore):
/// - Artifacts table       → collection `artifacts`, document ID = md5sum
/// - Remarks table         → collection `remarks` with fields: artifactMd5, userId, text, createdAt
/// - Favorites (RPC)       → collection `favorites` with fields: userId, artifactMd5
class FirebaseLoreRepo implements LoreRepo {
  // Firestore instance from AppConfig (overridable via [AppConfig.setMockServices])
  FirebaseFirestore get _firestore => AppConfig.firestore;

  /// Auth instance from AppConfig (overridable via [AppConfig.setMockServices])
  FirebaseAuth get _auth => AppConfig.auth;

  // --- Artifact operations ---

  @override
  Future<Artifact?> loadArtifact(String md5sum) async {
    try {
      final doc = await _firestore.collection('artifacts').doc(md5sum).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      // Map Firestore document → Artifact model
      return Artifact(
        path: data['name'] as String, // Stored as 'name' in Firestore
        md5sum: doc.id,               // Document ID is the md5sum
        sha256: data['sha256'] as String?,
      );
    } catch (e) {
      rethrow; // Throw on backend failure — don't swallow errors
    }
  }

  @override
  Future<void> saveArtifact(Artifact artifact) async {
    try {
      await _firestore.collection('artifacts').doc(artifact.md5sum).set({
        'name': artifact.path,     // Firebase path = document ID + stored name
        'md5': artifact.md5sum,    // Redundant but matches Supabase convention
        'sha256': artifact.sha256, // Nullable SHA-256 (older rows may not have it)
        'path': artifact.path,     // Full file path for display
      });
    } catch (e) {
      rethrow;
    }
  }

  // --- Remark operations ---

  @override
  Future<List<Remark>> loadRemarks({required String md5sum}) async {
    try {
      // Firestore doesn't support JOINs — query remarks where artifactMd5 == md5sum
      final snapshot = await _firestore
          .collection('remarks')
          .where('artifactMd5', isEqualTo: md5sum)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Map Firestore document → Remark model (using the positional ctor)
        final effectiveId = int.tryParse(doc.id); // Firestore auto-generated IDs are UUIDs/strings
        return Remark(
          data['text'] as String,
          data['userId'] as String?,  // Firebase user ID or username
          (data['createdAt'] as Timestamp?)?.toDate(),
          effectiveId,                // Nullable — only valid if doc ID parses as int
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> saveRemark({
    required String remark,
    required String? md5sum,
    required String? userId,
  }) async {
    try {
      final docRef = _firestore.collection('remarks').doc(); // Auto-generate ID
      await docRef.set({
        'artifactMd5': md5sum ?? '',
        'userId': userId ?? AppConfig.uid ?? '', // Fall back to current user UID
        'text': remark,
        'createdAt': FieldValue.serverTimestamp(), // Firestore server timestamp
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteRemark({required Remark remark}) async {
    try {
      // Find the document by its ID or search via composite key
      final snapshot = await _firestore
          .collection('remarks')
          .where('text', isEqualTo: remark.text)
          // Note: In production, store the docRef ID alongside remarks for efficient deletion
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.delete();
      }
    } catch (e) {
      rethrow;
    }
  }

  // --- Favorite operations (replaces getfavoriteartifactsfor RPC) ---

  @override
  Future<void> addToFavorites({
    required Artifact? artifact,
    required String? userId,
  }) async {
    try {
      if (artifact == null || userId == null) return;

      // Check for existing favorite first to avoid duplicates
      final existing = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .where('artifactMd5', isEqualTo: artifact.md5sum)
          .limit(1)
          .get();

      if (existing.docs.isEmpty) {
        // Create new favorite entry with auto-generated document ID
        await _firestore.collection('favorites').add({
          'userId': userId,
          'artifactMd5': artifact.md5sum,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> removeFromFavorites({
    required Artifact? artifact,
    required String? userId,
  }) async {
    try {
      if (artifact == null || userId == null) return;

      final snapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .where('artifactMd5', isEqualTo: artifact.md5sum)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Artifact>> loadFavoritesArtifacts({required String? userId}) async {
    try {
      if (userId == null) return [];

      // Step 1: Query favorites for this user — replaces the Supabase RPC call
      final favSnap = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .get();

      // Step 2: Extract artifact md5sums and batch-load each Artifact
      final md5SumList = favSnap.docs.map((doc) => doc['artifactMd5'] as String).toList();

      if (md5SumList.isEmpty) return [];

      // Firestore client-side `get` has a limit of 10 documents per call
      // — if the user has >10 favorites, paginate or use getAll() for batches of 10
      final artifacts = <Artifact>[];

      const batchSize = 10; // Firestore client-side get() limit
      for (var i = 0; i < md5SumList.length; i += batchSize) {
        final batch = md5SumList.skip(i).take(batchSize).toList();
        // Batch-read artifact documents by their md5sum IDs (Firestore document IDs)
        final docs = await Future.wait(
          batch.map((md5) => _firestore.collection('artifacts').doc(md5).get()),
        );

        for (final doc in docs) {
          if (!doc.exists) continue; // Skip deleted artifacts

          final data = doc.data()!;
          artifacts.add(Artifact(
            path: data['name'] as String,
            md5sum: doc.id,
            sha256: data['sha256'] as String?,
          ));
        }
      }

      return artifacts;
    } catch (e) {
      rethrow;
    }
  }

  // --- Authentication operations (replaces Supabase auth methods) ---

  @override
  Future<String?> loginWithJwt(String jwtToken) async {
    try {
      // Firebase Auth does NOT use JWT recovery tokens like Supabase.
      // Instead, we accept custom tokens from a trusted backend or use email-link flow.
      // 
      // Option A: If jwtToken is a Firebase custom token (signed by Admin SDK):
      final credential = GoogleAuthProvider.credential(
        idToken: jwtToken, // Treat JWT as a Firebase-compatible ID token
      );
      
      final userCred = await _auth.signInWithCredential(credential);
      return userCred.user?.email;

    } catch (e) {
      rethrow; // Token is invalid — throw to let caller handle the error
    }
  }

  @override
  String? get userId => AppConfig.uid;

  @override
  String? get userEmail => AppConfig.email;

  @override
  String? get accessToken {
    // Firebase ID tokens are JWTs. Since the abstract interface requires a sync getter,
    // we use the current user's token synchronously. getIdToken(true) forces a refresh
    // and is async, so we fall back to the cached token (valid ~1h) for this getter.
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      
      // getIdToken() is async — we can't await in a sync getter, so just check
       // whether we have a user. The caller should use accessTokenAsync when they need the
       // actual token string. See lore_app.dart for the isLoggedIn pattern using currentUser directly.
       return null; 
    } catch (e) {
      rethrow;
    }
  }

  /// Async version of accessToken for callers that can await.
  Future<String?> get accessTokenAsync async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      // forceRefresh = false uses cached token (~1h validity)
      return await user.getIdToken(false);
    } catch (e) {
      rethrow;
    }
  }

  // --- Additional convenience methods for Firebase-specific features ---

  /// Subscribe to real-time changes on artifact remarks (Firestore snapshot listener).
  Stream<List<Remark>> remarksStream({required String md5sum}) {
    return _firestore
        .collection('remarks')
        .where('artifactMd5', isEqualTo: md5sum)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              // Map Firestore document → Remark model (positional ctor)
              return Remark(
                data['text'] as String,
                data['userId'] as String?,  // Firebase user ID or username
                (data['createdAt'] as Timestamp?)?.toDate(),
              );
            }).toList());
  }

  /// Subscribe to real-time changes on all artifacts.
  Stream<List<Artifact>> artifactsStream() {
    return _firestore.collection('artifacts').snapshots().map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          return Artifact(
            path: data['name'] as String,
            md5sum: doc.id,
            sha256: data['sha256'] as String?,
          );
        }).toList());
  }

  /// Check if a specific user has favorited a specific artifact.
  Future<bool> isFavorite(String userId, String md5sum) async {
    try {
      final snapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .where('artifactMd5', isEqualTo: md5sum)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      rethrow;
    }
  }
}
