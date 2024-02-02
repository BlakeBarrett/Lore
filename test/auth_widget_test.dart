import 'package:Lore/auth_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/material.dart';

abstract class StringFunction {
  dynamic call(String value);
}

class MockStringFunction extends Mock implements StringFunction {}

void main() {
  group('AuthWidget', () {
    testWidgets('calls onEmailSubmitted when email is submitted',
        (final WidgetTester tester) async {
      final mockOnEmailSubmitted = MockStringFunction();
      final mockOnOtpSubmitted = MockStringFunction();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AuthWidget(
            onEmailSubmitted: mockOnEmailSubmitted.call,
            onOtpSubmitted: mockOnOtpSubmitted.call,
          ),
        ),
      ));

      // Enter text into the email TextField.
      await tester.enterText(find.byType(TextField).first, 'test@example.com');

      // Submit the email.
      await tester.testTextInput.receiveAction(TextInputAction.send);

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
            onEmailSubmitted: mockOnEmailSubmitted.call,
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
      await tester.enterText(find.byWidgetPredicate((widget) => widget is TextField && widget.decoration?.hintText == 'One Time Password...'), '123456');

      // Submit the OTP.
      await tester.testTextInput.receiveAction(TextInputAction.send);

      // Verify that onOtpSubmitted was called with the correct OTP.
      verify(mockOnOtpSubmitted('123456')).called(1);
    });
  });
}
