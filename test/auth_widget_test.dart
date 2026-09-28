import 'package:lore/auth_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/material.dart';
import 'package:lore/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, GoTrueClient, OtpType, SupabaseClient;

import 'test_utils.dart';

abstract class StringFunction {
  dynamic call(final String value);
}

class MockStringFunction extends Mock implements StringFunction {}

/// [SupabaseClient] stand-in exposing only `auth` — the single member
/// `AuthWidget.showAuthWidget` touches. Anything else called would hit
/// Mock.noSuchMethod and fail loudly.
class FakeSupabaseClient extends Mock implements SupabaseClient {
  FakeSupabaseClient(this.authClient);
  final FakeGoTrueClient authClient;

  @override
  GoTrueClient get auth => authClient;
}

void main() {
  group('AuthWidget', () {
    testWidgets('calls onEmailSubmitted when email is submitted',
        (final WidgetTester tester) async {
      final mockOnEmailSubmitted = MockStringFunction();
      final mockOnOtpSubmitted = MockStringFunction();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AuthWidget(
            onEmailSubmitted: (final String value) async {
              mockOnEmailSubmitted(value);
              return true;
            },
            onOtpSubmitted: mockOnOtpSubmitted.call,
          ),
        ),
      ));

      // Enter text into the email TextField.
      await tester.enterText(find.byType(TextField).first, 'test@example.com');

      // Submit the email.
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();

      // Verify that onEmailSubmitted was called with the correct email.
      verify(mockOnEmailSubmitted('test@example.com')).called(1);

      // Verify that onOtpSubmitted was not called.
      verifyNever(mockOnOtpSubmitted.call('test@example.com'));
    });

    testWidgets('calls onOtpSubmitted when OTP is submitted',
        (final WidgetTester tester) async {
      final mockOnEmailSubmitted = MockStringFunction();
      final mockOnOtpSubmitted = MockStringFunction();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AuthWidget(
            onEmailSubmitted: (final String value) async {
              mockOnEmailSubmitted(value);
              return true;
            },
            onOtpSubmitted: (final String value) async {
              mockOnOtpSubmitted(value);
            },
          ),
        ),
      ));

      await tester.enterText(find.byType(TextField).first, 'test@example.com');

      // Submit the email.
      await tester.testTextInput.receiveAction(TextInputAction.send);

      // Pump the widget tree to allow it to update.
      await tester.pump();

      // Enter text into the OTP TextField.
      await tester.enterText(
          find.byWidgetPredicate((final widget) =>
              widget is TextField &&
              widget.decoration?.hintText == 'One Time Password...'),
          '123456');

      // Submit the OTP.
      await tester.testTextInput.receiveAction(TextInputAction.send);

      // Verify that onOtpSubmitted was called with the correct OTP.
      verify(mockOnOtpSubmitted('123456')).called(1);
    });
  });

  // The tests below drive the full `AuthWidget.showAuthWidget` route against
  // a scripted GoTrue fake — the deepest cut available without a refactor:
  // showAuthWidget takes a SupabaseClient, whose `.auth` is the only seam it
  // uses, so a client stub returning a fake GoTrueClient covers the whole
  // page-builder closure ( signInWithOtp / verifyOTP wiring, the
  // readOnly/enabled state machine, the error SnackBar path, and the pop on
  // success). What stays UNCOVERED: the real HTTP layer inside gotrue
  // (covered upstream by supabase's own tests), the slide-transition
  // visuals, and the context.mounted==false early-return in showError
  // (needs the route popped during the async gap — inherently racy to
  // provoke; it is a one-line guard).
  group('AuthWidget.showAuthWidget OTP flow', () {
    late FakeGoTrueClient auth;

    Future<void> openAuthRoute(final WidgetTester tester) async {
      auth = FakeGoTrueClient();
      final client = FakeSupabaseClient(auth);
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (final BuildContext context) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => AuthWidget.showAuthWidget(context, client),
                child: const Text('open-auth'),
              ),
            ),
          );
        }),
      ));
      await tester.tap(find.text('open-auth'));
      await tester.pumpAndSettle(); // slide-in transition
      expect(find.byType(AuthWidget), findsOneWidget);
    }

    Future<void> submitEmail(
        final WidgetTester tester, final String email) async {
      await tester.enterText(find.byType(TextField).first, email);
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump(); // run the async handler + setState
    }

    Future<void> submitOtp(final WidgetTester tester, final String otp) async {
      await tester.enterText(
          find.byWidgetPredicate((final widget) =>
              widget is TextField &&
              widget.decoration?.hintText == 'One Time Password...'),
          otp);
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
    }

    TextField otpField(final WidgetTester tester) =>
        tester.widget(find.byWidgetPredicate((final widget) =>
                widget is TextField &&
                widget.decoration?.hintText == 'One Time Password...'))
            as TextField;

    testWidgets('initially the OTP field is locked and the email field is open',
        (final WidgetTester tester) async {
      await openAuthRoute(tester);

      expect(otpField(tester).enabled, isFalse);
      expect(otpField(tester).readOnly, isTrue);
      final emailField =
          tester.widget(find.byType(TextField).first) as TextField;
      expect(emailField.readOnly, isFalse);
      // No auth call has been made yet.
      expect(auth.signInEmails, isEmpty);
    });

    testWidgets(
        'submitting an email calls signInWithOtp with the lore:// '
        'redirect, then unlocks the OTP field and locks the email field',
        (final WidgetTester tester) async {
      await openAuthRoute(tester);

      await submitEmail(tester, 'test@example.com');

      expect(auth.signInEmails, ['test@example.com']);
      expect(auth.signInRedirects, ['lore://auth/callback']);
      // State machine: email consumed (readOnly) and OTP unlocked.
      final emailField =
          tester.widget(find.byType(TextField).first) as TextField;
      expect(emailField.readOnly, isTrue);
      expect(otpField(tester).enabled, isTrue);
      expect(otpField(tester).readOnly, isFalse);
      // No error surfaced, route stays open.
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(AuthWidget), findsOneWidget);
    });

    testWidgets(
        'a failing signInWithOtp surfaces the localized error '
        'SnackBar without popping the route or crashing',
        (final WidgetTester tester) async {
      await openAuthRoute(tester);
      auth.signInError = const AuthException('rate limited');

      await submitEmail(tester, 'test@example.com');

      expect(find.text('Authentication failed. Please try again.'),
          findsOneWidget);
      // The sheet survives the failure: still on screen, no unhandled throw.
      expect(find.byType(AuthWidget), findsOneWidget);
      // A failed send means NO OTP exists: the email field must unlock for a
      // corrected retry, and the OTP field must lock again.
      final emailField =
          tester.widget(find.byType(TextField).first) as TextField;
      expect(emailField.readOnly, isFalse);
      expect(otpField(tester).enabled, isFalse);
      expect(otpField(tester).readOnly, isTrue);
      // Let the SnackBar auto-dismiss so no timer is pending at teardown.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets(
        'a failing verifyOTP surfaces the localized error SnackBar, '
        'keeps the route open, and forwards email + magiclink type',
        (final WidgetTester tester) async {
      await openAuthRoute(tester);
      await submitEmail(tester, 'test@example.com');
      auth.verifyError = const AuthException('invalid otp');

      await submitOtp(tester, '123456');

      expect(auth.verifyTokens, ['123456']);
      expect(auth.verifyEmails, ['test@example.com']);
      expect(auth.verifyTypes, [OtpType.magiclink]);
      expect(find.text('Authentication failed. Please try again.'),
          findsOneWidget);
      expect(find.byType(AuthWidget), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('a successful verifyOTP pops the auth route',
        (final WidgetTester tester) async {
      await openAuthRoute(tester);
      await submitEmail(tester, 'test@example.com');

      await submitOtp(tester, '123456');
      await tester.pumpAndSettle(); // slide-out transition

      expect(find.byType(AuthWidget), findsNothing);
      expect(find.text('open-auth'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets(
        'a malformed e-mail is rejected inline without calling '
        'signInWithOtp (WCAG 3.3.1/3.3.3)',
        (final WidgetTester tester) async {
      await openAuthRoute(tester);

      await submitEmail(tester, 'not-an-email');
      await tester.pump();

      // The field-level error is shown; the server is never consulted.
      expect(
          find.text("That doesn't look like an e-mail address."),
          findsOneWidget);
      expect(auth.signInEmails, isEmpty);
      // And the failure is NOT the generic auth SnackBar.
      expect(find.byType(SnackBar), findsNothing);
      // The step-1 button is still there to retry after correcting.
      expect(find.widgetWithText(FilledButton, 'Send code'), findsOneWidget);
    });

    testWidgets('the Send code button drives the send (visible primary action)',
        (final WidgetTester tester) async {
      await openAuthRoute(tester);

      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.tap(find.widgetWithText(FilledButton, 'Send code'));
      await tester.pump();

      expect(auth.signInEmails, ['test@example.com']);
      // Success confirmation names the address (WCAG 4.1.3) and offers the
      // change-address escape hatch.
      expect(find.text('Code sent to test@example.com'), findsOneWidget);
      expect(find.text('Use a different address?'), findsOneWidget);
    });

    testWidgets(
        '"Use a different address?" unlocks the e-mail field again so a '
        'corrected address can be sent',
        (final WidgetTester tester) async {
      await openAuthRoute(tester);
      await submitEmail(tester, 'wrong@example.com');

      await tester.tap(find.text('Use a different address?'));
      await tester.pump();

      final emailField =
          tester.widget(find.byType(TextField).first) as TextField;
      expect(emailField.readOnly, isFalse);
      // OTP stage is over: the field re-locks and the send is repeatable.
      expect(otpField(tester).enabled, isFalse);

      await submitEmail(tester, 'right@example.com');
      expect(auth.signInEmails, ['wrong@example.com', 'right@example.com']);
    });

    testWidgets('the Verify button drives verifyOTP',
        (final WidgetTester tester) async {
      await openAuthRoute(tester);
      await submitEmail(tester, 'test@example.com');

      await tester.enterText(
          find.byWidgetPredicate((final widget) =>
              widget is TextField &&
              widget.decoration?.hintText == 'One Time Password...'),
          '123456');
      await tester.tap(find.widgetWithText(FilledButton, 'Verify'));
      await tester.pumpAndSettle();

      expect(auth.verifyTokens, ['123456']);
      expect(find.byType(AuthWidget), findsNothing); // popped on success
    });
  });
}
