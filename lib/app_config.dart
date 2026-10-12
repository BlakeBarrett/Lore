// Firebase configuration module — initializes firebase_core and provides access to Auth and Firestore.
// Replaces the previous Supabase client wrapper in lib/app_config.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Import the generated firebase_options file (run `flutterfire configure` to generate)
import 'firebase_options.dart';

/// Provides initialized Firebase services and high-level auth helpers.
class AppConfig {
  AppConfig._({required this.isDesktop, required this.isWeb});

  /// Test seam: construct a config object without Firebase init.
  AppConfig.forTesting({this.isDesktop = false, this.isWeb = false});

  /// Test seam: construct with injected mockable [FirebaseAuth] and
  /// [FirebaseFirestore] instances. Used by unit tests so the static
  /// singletons are bypassed entirely (see `test/firebase_auth_test.dart`).
  AppConfig.mockable({required this.isDesktop, required this.isWeb, FirebaseAuth? auth, FirebaseFirestore? firestore}) {
    _authOverride = auth;
    _firestoreOverride = firestore;
  }

  final bool isDesktop;
  final bool isWeb;

  // --- Injected test overrides (non-null during unit tests) ---
  static FirebaseAuth? _authOverride;
  static FirebaseFirestore? _firestoreOverride;

  /// Set mockable services for unit tests. Call before exercising static
  /// helpers that delegate to FirebaseAuth/FirebaseFirestore singletons.
  static void setMockServices({
    required FirebaseAuth auth,
    FirebaseFirestore? firestore,
  }) {
    _authOverride = auth;
    _firestoreOverride = firestore;
  }

  /// Clear any injected test overrides. Reset after each test group.
  static void clearMockServices() {
    _authOverride = null;
    _firestoreOverride = null;
  }

  static late final AppConfig instance;

  // --- Firebase service accessors (replacement for Supabase.instance.client) ---

  /// The Firebase Auth service instance. May be overridden by [setMockServices]
  /// for unit testing.
  static FirebaseAuth get auth => _authOverride ?? FirebaseAuth.instance;

  /// The Firestore database instance. May be overridden by [setMockServices]
  /// for unit testing.
  static FirebaseFirestore get firestore => _firestoreOverride ?? FirebaseFirestore.instance;

  /// Current logged-in user, or null if not signed in.
  static User? get currentUser => auth.currentUser;

  /// Stream of authentication state changes (replaces Supabase's `auth.onAuthStateChange`).
  static Stream<User?> get authStateChanges => auth.authStateChanges();

  /// True if the user is currently signed in.
  static bool get isLoggedIn => currentUser != null;

  /// The UID of the current user (safe to call after logging in).
  static String? get uid => currentUser?.uid;

  /// The email of the current user.
  static String? get email => currentUser?.email;

  /// The display name of the current user.
  static String? get displayName => currentUser?.displayName;

  /// The profile photo URL of the current user.
  static String? get photoURL => currentUser?.photoURL;

  // --- Initialization (replaces Supabase.initialize) ---

  /// Initialize Firebase with platform-specific options.
  static Future<void> init({final bool desktop = false}) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    instance = AppConfig._(
      isDesktop: desktop,
      isWeb: kIsWeb,
    );
  }

  // --- Auth helpers (replaces Supabase auth API) ---

  /// Creates a new user account with email and password.
  static Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) {
    return auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Signs in with an existing email and password.
  static Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) {
    return auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Signs out the current user.
  static Future<void> signOut() async {
    await auth.signOut();
  }

  /// Sends a password-reset email.
  static Future<void> sendPasswordResetEmail(String email) async {
    await auth.sendPasswordResetEmail(email: email);
  }

  /// Updates the current user's display name.
  static Future<void> updateDisplayName(String name) async {
    await auth.currentUser?.updateDisplayName(name);
  }

  /// Updates the current user's email address.
  /// Note: requires re-authentication before this call in most cases.
  static Future<void> updateEmail(String newEmail) async {
    // Firebase requires re-auth before email change in production;
    // see: https://firebase.google.com/docs/auth/web/manage-users#update_an_user's_email_address
    await auth.currentUser?.verifyBeforeUpdateEmail(newEmail);
  }

  /// Re-authenticates the user before a sensitive operation.
  static Future<void> reauthenticate({required String email, required String password}) async {
    final cred = EmailAuthProvider.credential(email: email, password: password);
    await auth.currentUser?.reauthenticateWithCredential(cred);
  }

  /// Deletes the current user's account.
  static Future<void> deleteUser() async {
    await auth.currentUser?.delete();
  }

  /// Updates the user's profile photo URL.
  static Future<void> updatePhotoURL(String url) async {
    await auth.currentUser?.updatePhotoURL(url);
  }

  // --- Google / Apple OAuth sign-in ---

  /// Signs in via Google OAuth (works on mobile and web).
  static Future<UserCredential> signInWithGoogle() async {
    final GoogleAuthProvider provider = GoogleAuthProvider();
    return await auth.signInWithProvider(provider);
  }

  /// Signs in via Apple OAuth (iOS / macOS only).
  static Future<UserCredential> signInWithApple() async {
    final AppleAuthProvider provider = AppleAuthProvider();
    return await auth.signInWithProvider(provider);
  }

  // --- Email-Link (passwordless) Auth — replaces Supabase JWT recoverSession flow ---

  /// Sends a sign-in magic link to the given email.
  /// The user taps the link and Flutter handles it via dynamic links / deep linking.
  static Future<void> sendSignInEmailLink({required String email}) async {
    final ActionCodeSettings actionCodeSettings = ActionCodeSettings(
      url: 'https://lore.app/signin', // Replace with your authorized domain + route
      handleCodeInApp: true,
      iOSBundleId: 'com.yourbundleid.lore', // Override with actual bundle ID
      androidPackageName: 'com.yourpackage.lore', // Override with actual package name
      androidInstallApp: true,
      androidMinimumVersion: '12',
    );

    await auth.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: actionCodeSettings,
    );
  }

  /// Checks whether the provided URL is an email-link sign-in link.
  static bool isSignInWithEmailLink(String url) {
    return auth.isSignInWithEmailLink(url);
  }

  /// Completes sign-in using the email link that was sent to the user.
  static Future<UserCredential> signInWithEmailLink({
    required String email,
    required String url, // Full deep-link URL including the action code
  }) {
    return auth.signInWithEmailLink(email: email, emailLink: url);
  }

  // --- Session persistence (replaces Supabase `recoverSession`) ---

  /// Sets the auth persistence strategy.
  /// LOCAL = persisted across app restarts (mobile: encrypted storage; web: indexedDB)
  /// NONE = only lives in memory
  static Future<void> setPersistence(Persistence persistence) {
    return auth.setPersistence(persistence);
  }
}
