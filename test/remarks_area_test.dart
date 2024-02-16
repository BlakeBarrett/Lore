import 'package:Lore/remark.dart';
import 'package:Lore/remark_entry_widget.dart';
import 'package:Lore/remark_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'drawer_widget_test.dart';

void main() {
  group('RemarkList', () {
    testWidgets('renders correctly', (final WidgetTester tester) async {
      // Build the RemarkList in a testable widget.
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              RemarkList(
                remarks: const <Remark>[],
                userId: 'user-id',
                onDeleteRemark: (_) {},
              ),
            ],
          ),
        ),
      ));

      // Verify that the RemarkList is rendered.
      expect(find.byType(RemarkList), findsOneWidget);
    });

    group('CommentInputArea', () {
      testWidgets('CommentInputArea calls onSubmitted with correct value',
          (final WidgetTester tester) async {
        String testValue = '';
        onSubmitted(final String value) => testValue = value;

        // Build the CommentInputArea in a testable widget.
        await tester.pumpWidget(MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: RemarkEntryWidget(
              onSubmitted: onSubmitted,
            ),
          ),
        ));

        // Enter text into the CommentInputArea.
        await tester.enterText(find.byType(TextField), 'Test remark');

        // Submit the remark.
        await tester.testTextInput.receiveAction(TextInputAction.done);

        // Verify that onSubmitted was called with the correct value.
        expect(testValue, 'Test remark');
      });
      testWidgets(
          'CommentInputArea calls onLogin when tapped and enabled is false',
          (final WidgetTester tester) async {
        final MockFunction onLogin = MockFunction();
        final MockFunction onSubmitted = MockFunction();

        // Build the CommentInputArea in a testable widget.
        await tester.pumpWidget(MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: RemarkEntryWidget(
              enabled: false, // CommentInputArea is disabled
              onLogin: onLogin.call,
              onSubmitted: (_) => onSubmitted.call, // Mocked function
            ),
          ),
        ));

        // Tap the CommentInputArea.
        await tester.tap(find.byType(TextField));

        // Verify that the onLogin function is called.
        verify(onLogin()).called(1);

        // Verify that onSubmitted is not called.
        verifyNever(onSubmitted());
      });
    });
  });
}
