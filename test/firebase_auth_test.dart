import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lore/app_config.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'firebase_auth_test.mocks.dart';

/// [AppConfig]'s static Firebase helpers, exercised through the
/// [AppConfig.setMockServices] seam: every assertion verifies that the
/// static method delegates to the (mocked) [FirebaseAuth] / [User] instance
/// with the right arguments and returns its result — no Firebase
/// initialisation, no platform channels, no network.
@GenerateMocks([FirebaseAuth, User, UserCredential])
void main() {
  late MockFirebaseAuth auth;
  late MockUser user;
  late MockUserCredential userCredential;

  setUp(() {
    auth = MockFirebaseAuth();
    user = MockUser();
    userCredential = MockUserCredential();
    when(userCredential.user).thenReturn(user);
    AppConfig.setMockServices(auth: auth);
  });

  tearDown(() => AppConfig.clearMockServices());

  group('session state', () {
    test('isLoggedIn/uid/email/displayName/photoURL mirror the current user',
        () {
      when(auth.currentUser).thenReturn(user);
      when(user.uid).thenReturn('uid-1');
      when(user.email).thenReturn('u@example.com');
      when(user.displayName).thenReturn('Blake');
      when(user.photoURL).thenReturn('https://example.com/p.png');

      expect(AppConfig.isLoggedIn, isTrue);
      expect(AppConfig.currentUser, same(user));
      expect(AppConfig.uid, 'uid-1');
      expect(AppConfig.email, 'u@example.com');
      expect(AppConfig.displayName, 'Blake');
      expect(AppConfig.photoURL, 'https://example.com/p.png');
    });

    test('anonymous state reports nulls and isLoggedIn false', () {
      when(auth.currentUser).thenReturn(null);

      expect(AppConfig.isLoggedIn, isFalse);
      expect(AppConfig.currentUser, isNull);
      expect(AppConfig.uid, isNull);
      expect(AppConfig.email, isNull);
    });

    test('authStateChanges delegates to FirebaseAuth.authStateChanges', () {
      when(auth.authStateChanges())
          .thenAnswer((final _) => const Stream<User?>.empty());

      expect(AppConfig.authStateChanges, isA<Stream<User?>>());
    });
  });

  group('auth actions', () {
    test('createUserWithEmailAndPassword delegates and returns the result',
        () async {
      when(auth.createUserWithEmailAndPassword(
              email: 'new@example.com', password: 'pw-1'))
          .thenAnswer((final _) async => userCredential);

      final result = await AppConfig.createUserWithEmailAndPassword(
          'new@example.com', 'pw-1');

      expect(result, same(userCredential));
      verify(auth.createUserWithEmailAndPassword(
              email: 'new@example.com', password: 'pw-1'))
          .called(1);
    });

    test('signInWithEmailAndPassword delegates and returns the result',
        () async {
      when(auth.signInWithEmailAndPassword(
              email: 'u@example.com', password: 'pw-2'))
          .thenAnswer((final _) async => userCredential);

      final result =
          await AppConfig.signInWithEmailAndPassword('u@example.com', 'pw-2');

      expect(result, same(userCredential));
    });

    test('signOut delegates to FirebaseAuth.signOut', () async {
      when(auth.signOut()).thenAnswer((final _) async {});

      await AppConfig.signOut();

      verify(auth.signOut()).called(1);
    });

    test('sendPasswordResetEmail delegates with the e-mail', () async {
      when(auth.sendPasswordResetEmail(email: 'u@example.com'))
          .thenAnswer((final _) async {});

      await AppConfig.sendPasswordResetEmail('u@example.com');

      verify(auth.sendPasswordResetEmail(email: 'u@example.com')).called(1);
    });
  });

  group('profile updates (via the current user)', () {
    test('updateDisplayName updates the user', () async {
      when(auth.currentUser).thenReturn(user);
      when(user.updateDisplayName('New Name')).thenAnswer((final _) async {});

      await AppConfig.updateDisplayName('New Name');

      verify(user.updateDisplayName('New Name')).called(1);
    });

    test('updateEmail verifies before updating', () async {
      when(auth.currentUser).thenReturn(user);
      when(user.verifyBeforeUpdateEmail('new@example.com'))
          .thenAnswer((final _) async {});

      await AppConfig.updateEmail('new@example.com');

      verify(user.verifyBeforeUpdateEmail('new@example.com')).called(1);
    });

    test('reauthenticate builds an email credential and reauthenticates',
        () async {
      when(auth.currentUser).thenReturn(user);
      AuthCredential? sentCredential;
      when(user.reauthenticateWithCredential(any))
          .thenAnswer((final invocation) async {
        sentCredential =
            invocation.positionalArguments.single as AuthCredential;
        return userCredential;
      });

      await AppConfig.reauthenticate(email: 'u@example.com', password: 'pw-3');

      expect(sentCredential, isA<EmailAuthCredential>());
      verify(user.reauthenticateWithCredential(any)).called(1);
    });

    test('deleteUser deletes the current user', () async {
      when(auth.currentUser).thenReturn(user);
      when(user.delete()).thenAnswer((final _) async {});

      await AppConfig.deleteUser();

      verify(user.delete()).called(1);
    });

    test('updatePhotoURL updates the user', () async {
      when(auth.currentUser).thenReturn(user);
      when(user.updatePhotoURL('https://example.com/x.png'))
          .thenAnswer((final _) async {});

      await AppConfig.updatePhotoURL('https://example.com/x.png');

      verify(user.updatePhotoURL('https://example.com/x.png')).called(1);
    });

    test('profile helpers are no-ops when signed out', () async {
      when(auth.currentUser).thenReturn(null);

      await AppConfig.updateDisplayName('New Name');
      await AppConfig.updateEmail('new@example.com');
      await AppConfig.deleteUser();
      await AppConfig.updatePhotoURL('https://example.com/x.png');

      verifyZeroInteractions(user);
    });
  });

  group('OAuth providers', () {
    test('signInWithGoogle signs in with a Google provider', () async {
      AuthProvider? sentProvider;
      when(auth.signInWithProvider(any)).thenAnswer((final invocation) async {
        sentProvider = invocation.positionalArguments.single as AuthProvider;
        return userCredential;
      });

      final result = await AppConfig.signInWithGoogle();

      expect(result, same(userCredential));
      expect(sentProvider, isA<GoogleAuthProvider>());
    });

    test('signInWithApple signs in with an Apple provider', () async {
      AuthProvider? sentProvider;
      when(auth.signInWithProvider(any)).thenAnswer((final invocation) async {
        sentProvider = invocation.positionalArguments.single as AuthProvider;
        return userCredential;
      });

      final result = await AppConfig.signInWithApple();

      expect(result, same(userCredential));
      expect(sentProvider, isA<AppleAuthProvider>());
    });
  });

  group('email-link (passwordless) flow', () {
    test('sendSignInEmailLink sends the link with action-code settings',
        () async {
      when(auth.sendSignInLinkToEmail(
              email: anyNamed('email'),
              actionCodeSettings: anyNamed('actionCodeSettings')))
          .thenAnswer((final _) async {});

      await AppConfig.sendSignInEmailLink(email: 'u@example.com');

      verify(auth.sendSignInLinkToEmail(
              email: 'u@example.com',
              actionCodeSettings: argThat(isA<ActionCodeSettings>(),
                  named: 'actionCodeSettings')))
          .called(1);
    });

    test('isSignInWithEmailLink delegates to FirebaseAuth', () {
      when(auth.isSignInWithEmailLink('https://x'))
          .thenAnswer((final _) => true);

      expect(AppConfig.isSignInWithEmailLink('https://x'), isTrue);
    });

    test('signInWithEmailLink signs in with e-mail and link', () async {
      when(auth.signInWithEmailLink(
              email: 'u@example.com',
              emailLink: 'https://lore.app/signin?oob=x'))
          .thenAnswer((final _) async => userCredential);

      final result = await AppConfig.signInWithEmailLink(
          email: 'u@example.com', url: 'https://lore.app/signin?oob=x');

      expect(result, same(userCredential));
    });
  });

  group('persistence', () {
    test('setPersistence delegates with the strategy', () async {
      when(auth.setPersistence(Persistence.LOCAL))
          .thenAnswer((final _) async {});

      await AppConfig.setPersistence(Persistence.LOCAL);

      verify(auth.setPersistence(Persistence.LOCAL)).called(1);
    });
  });
}
