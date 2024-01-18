import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Lore/comment_widget.dart';
import 'package:Lore/remark.dart';

void main() {
  group('CommentArea', () {
    testWidgets('displays remarks', (WidgetTester tester) async {
      final remarks = [
        Remark('Remark 1', '', DateTime.now()),
        Remark('Remark 2', '', DateTime.now())
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CommentArea(remarks: remarks),
        ),
      ));

      expect(find.text('Remark 1'), findsOneWidget);
      expect(find.text('Remark 2'), findsOneWidget);
    });
  });

  group('CommentInputArea', () {
    testWidgets('calls onSubmitted when text is submitted',
        (WidgetTester tester) async {
      var submittedText = '';
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CommentInputArea(
            onSubmitted: (value) {
              submittedText = value;
            },
          ),
        ),
      ));

      await tester.enterText(find.byType(TextField), 'Test remark');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      expect(submittedText, 'Test remark');
    });
  });
}
