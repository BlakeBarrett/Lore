import 'package:Lore/file_drop_handlers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Build-shape smoke tests for the drop-handler wrappers. The actual drag
/// events come from the platform (desktop_drop / flutter_dropzone JS glue)
/// and can't be synthesized in a widget test — what IS testable is that the
/// wrappers render their child (the controller pipeline hangs off them), and
/// that on the VM (kIsWeb == false) the web handler degrades to a passthrough.
void main() {
  group('drop handler wrappers', () {
    testWidgets(
        'DesktopFileDropHandler renders its child inside a '
        'DropTarget', (final WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DesktopFileDropHandler(
            onDrop: (final _) {},
            onCalculating: (final _) {},
            child: const Text('droppable'),
          ),
        ),
      ));
      expect(find.text('droppable'), findsOneWidget);
    });

    testWidgets(
        'WebFileDropHandler is a passthrough off the web (renders '
        'its child)', (final WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WebFileDropHandler(
            onDrop: (final _) {},
            onCalculating: (final _) {},
            child: const Text('droppable'),
          ),
        ),
      ));
      expect(find.text('droppable'), findsOneWidget);
    });
  });
}
