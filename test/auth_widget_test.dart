import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/auth_widget.dart';

void main() {
  group('AuthWidget (raw UI)', () {
    // NOTE: AuthWidget now uses Firebase email-link auth. There is no OTP field
    // in the current implementation — the user submits an e-mail, receives a
    // magic link by email, and taps it to complete sign-in on another device. The tests
    // below verify the visible UI (single TextField → success banner).

    testWidgets('renders a single TextField with sendable action', (tester) async {
      await tester.pumpWidget(
           MaterialApp(home: Scaffold(body: AuthWidget(onEmailSubmitted: (_) => Future.value(true), onOtpSubmitted: (String _) {}))));

       expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('calls onEmailSubmitted when the e-mail field is submitted', (tester) async {
       var called = false;
       String? lastCalledValue;
       final callback = (String v) => Future.value(true).then((_) { called = true; lastCalledValue = v; });

       await tester.pumpWidget(
           MaterialApp(home: Scaffold(body: AuthWidget(onEmailSubmitted: callback, onOtpSubmitted: (_) {}))));

       // Enter text into the e-mail TextField.
      await tester.enterText(find.byType(TextField).first, 'test@example.com');

      // Submit the email (enter key).
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();

      expect(called, isTrue);
      expect(lastCalledValue, equals('test@example.com'));
    });

    testWidgets(
        'when onEmailSubmitted returns false the field re-opens (failed send)', (tester) async {
      await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: AuthWidget(onEmailSubmitted: (_) => Future.value(false), onOtpSubmitted: (String _) {}))));

      // Enter + submit — the callback returns false.
      await tester.enterText(find.byType(TextField).first, 'fail@example.com');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      // The field should be re-openable: still readable and editable.
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('when onEmailSubmitted returns true a confirmation banner appears', (tester) async {
      await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: AuthWidget(onEmailSubmitted: (_) => Future.value(true), onOtpSubmitted: (String _) {}))));

      // Enter + submit — the callback returns true.
      await tester.enterText(find.byType(TextField).first, 'ok@example.com');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      expect(find.text('Sign-in link sent'), findsOneWidget);
    });

    testWidgets('showFirebaseAuthWidget opens a push route with the AuthWidget', (tester) async {
      await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ElevatedButton(
                onPressed: () => AuthWidget.showFirebaseAuthWidget(tester.element(find.byType(Scaffold))),
                child: const Text('open-auth'),
              ),
            ),
          ));

      await tester.tap(find.text('open-auth'));
      await tester.pumpAndSettle();

      expect(find.byType(AuthWidget), findsOneWidget);
    });
  });
}
