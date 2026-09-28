import 'package:lore/remark.dart';
import 'package:lore/remark_entry_widget.dart';
import 'package:lore/remark_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:lore/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'test_utils.dart';

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
                onDeleteRemark: (final _) {},
              ),
            ],
          ),
        ),
      ));

      // Verify that the RemarkList is rendered.
      expect(find.byType(RemarkList), findsOneWidget);
    });

    testWidgets('shows the localized no-remarks empty state',
        (final WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              RemarkList(
                remarks: const <Remark>[],
                userId: 'user-id',
                onDeleteRemark: (final _) {},
                emptyMessage: 'No remarks yet.',
              ),
            ],
          ),
        ),
      ));

      expect(find.text('No remarks yet.'), findsOneWidget);
    });

    testWidgets('localizes the onboarding dummy conversation',
        (final WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (final context) {
              final remarks =
                  localizedOnboardingRemarks(AppLocalizations.of(context)!);
              expect(remarks.length, Remark.dummyData.length);
              expect(remarks.first.text, 'First!');
              expect(remarks[3].text, contains('Drop a file'));
              return const SizedBox.shrink();
            },
          ),
        ),
      ));
    });

    testWidgets('delete menu button exposes a tooltip label (WCAG 4.1.2)',
        (final WidgetTester tester) async {
      final Remark own = Remark('mine', 'me', DateTime.utc(2026), 1);

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              RemarkList(
                remarks: <Remark>[own],
                userId: 'me',
                onDeleteRemark: (final _) {},
              ),
            ],
          ),
        ),
      ));

      final PopupMenuButton<String> menu =
          tester.widget<PopupMenuButton<String>>(
              find.byType(PopupMenuButton<String>));
      // The icon-only menu button carries the required accessible tooltip.
      expect(menu.tooltip, 'Delete remark');
    });

    testWidgets('delete asks for confirmation before calling onDeleteRemark',
        (final WidgetTester tester) async {
      final Remark own = Remark('mine', 'me', DateTime.utc(2026), 1);
      final List<Remark> deleted = <Remark>[];

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              RemarkList(
                remarks: <Remark>[own],
                userId: 'me',
                onDeleteRemark: deleted.add,
              ),
            ],
          ),
        ),
      ));

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      // The confirm dialog is up, nothing deleted yet.
      expect(find.text('Delete this remark?'), findsOneWidget);
      expect(deleted, isEmpty);

      // Cancel aborts.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(deleted, isEmpty);

      // Confirm goes through.
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(deleted, [own]);
    });

    group('CommentInputArea', () {
      testWidgets('CommentInputArea calls onSubmitted with correct value',
          (final WidgetTester tester) async {
        String testValue = '';
        String onSubmitted(final String value) => testValue = value;

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
              onSubmitted: (final _) => onSubmitted.call, // Mocked function
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
