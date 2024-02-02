import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:Lore/drawer_widget.dart';
import 'package:mockito/mockito.dart';

class MockFunction extends Mock {
  void call();
}

void main() {
  group('DrawerViewWidget', () {
    testWidgets(
        'DrawerViewWidget shows correct email and calls functions correctly',
        (WidgetTester tester) async {
      final MockFunction onLogout = MockFunction();
      const String testEmail = 'test@example.com';

      // Build the DrawerViewWidget in a testable widget.
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DrawerWidget(
            userEmail: testEmail,
            authenticated: true,
            favorites: const [],
            onLogout: onLogout.call,
            onShowAuthWidget: MockFunction().call,
            onShowArtifact: (_) => MockFunction().call,
          ),
        ),
      ));

      // Find the email widget.
      final emailFinder = find.text(testEmail);

      // Verify that the email is found.
      expect(emailFinder, findsOneWidget);

      // Tap the Logout list tile and verify onLogout is called.
      await tester.tap(find.text('Logout'));
      verify(onLogout()).called(1);
    });
    testWidgets(
        'DrawerViewWidget shows AuthWidget when header is tapped and user is not authenticated',
        (WidgetTester tester) async {
      final MockFunction onShowAuthWidget = MockFunction();
      const String testEmail = 'test@example.com';

      // Build the DrawerViewWidget in a testable widget.
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DrawerWidget(
            userEmail: testEmail,
            authenticated: false, // User is not authenticated
            favorites: const [],
            onShowAuthWidget: onShowAuthWidget.call, // Mocked function
            onLogout: MockFunction().call,
            onShowArtifact: (_) => MockFunction().call,
          ),
        ),
      ));

      // Tap the header.
      await tester.tap(find.byType(DrawerHeader));

      // Verify that the onShowAuthWidget function is called.
      verify(onShowAuthWidget()).called(1);
    });
    testWidgets(
        'DrawerViewWidget does not show AuthWidget when header is tapped and user is authenticated',
        (WidgetTester tester) async {
      final MockFunction onShowAuthWidget = MockFunction();
      const String testEmail = 'test@example.com';

      // Build the DrawerViewWidget in a testable widget.
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DrawerWidget(
            userEmail: testEmail,
            authenticated: true, // User is authenticated
            favorites: const [],
            onLogout: MockFunction().call,
            onShowAuthWidget: onShowAuthWidget.call, // Mocked function
            onShowArtifact: (_) => MockFunction().call,
          ),
        ),
      ));

      // Tap the header.
      await tester.tap(find.byType(DrawerHeader));

      // Verify that the onShowAuthWidget function is not called.
      verifyNever(onShowAuthWidget());
    });
  });
}
