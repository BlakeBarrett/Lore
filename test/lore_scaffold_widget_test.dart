import 'dart:async';

import 'package:lore/app_config.dart';
import 'package:lore/artifact.dart';
import 'package:lore/lore_app.dart';
import 'package:lore/lore_controller.dart';
import 'package:lore/l10n/app_localizations.dart';
import 'package:lore/remark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthClientOptions, SupabaseClient;

import 'test_utils.dart';

// Root-view tests for LoreScaffoldWidget: the widget is pumped with an
// injected LoreController built on the hand-written FakeLoreRepo, so nothing
// but the (inert) SupabaseClient handed to AppConfig.forTesting is real.
// The injection seam is the `controller:` param (the widget does not dispose
// injected controllers). Platform-bound paths (FilePicker, desktop/web drop
// handlers) are deliberately not exercised: AppConfig.forTesting reports
// isDesktop=false/isWeb=false, so the bare Scaffold is built.
void main() {
  // AppConfig.instance is read unconditionally during build (platform flags,
  // drawer/logout closures). Assign the test singleton exactly once —
  // `static late final` tolerates a single assignment per isolate.
  final client = SupabaseClient(
    'https://lore-scaffold-test.supabase.co',
    'test-anon-key',
    // No background refresh timer: tests would hang on a pending Timer.
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  AppConfig.instance = AppConfig.forTesting(client);
  tearDownAll(client.dispose);

  late FakeLoreRepo repo;
  late LoreController controller;

  Future<void> pumpScaffold(final WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: LoreScaffoldWidget(controller: controller),
    ));
    await tester.pumpAndSettle();
  }

  setUp(() {
    repo = FakeLoreRepo();
    controller = LoreController(repo: repo);
  });

  tearDown(() => controller.dispose);

  group('LoreScaffoldWidget (root view)', () {
    testWidgets('initial render: app bar + search bar and onboarding remarks',
        (final WidgetTester tester) async {
      await pumpScaffold(tester);

      // App chrome: title in the app bar, search field present.
      expect(find.text('Lore'), findsWidgets);
      expect(find.byTooltip('Search by MD5 or URL'), findsOneWidget);

      // artifact == null → the localized onboarding conversation renders.
      expect(find.text('First!'), findsOneWidget);
      expect(find.text('How did I get here?'), findsOneWidget);
    });

    testWidgets('controller.select updates the title area and remarks list',
        (final WidgetTester tester) async {
      repo.remarksToReturn = [
        const Remark.simple(text: 'a great find', id: 1),
        const Remark.simple(text: 'agreed', id: 2),
      ];
      await pumpScaffold(tester);

      await controller.select('hello lore');
      await tester.pumpAndSettle();

      // FlexibleSpaceBar title shows the artifact name, subtitle its md5.
      expect(find.text('hello lore'), findsWidgets);
      // The artifact's remarks render in the thread.
      expect(find.text('a great find'), findsOneWidget);
      expect(find.text('agreed'), findsOneWidget);
      // Onboarding copy is gone once something is selected.
      expect(find.text('First!'), findsNothing);
    });

    testWidgets('a failed select shows the localized load-error SnackBar',
        (final WidgetTester tester) async {
      await pumpScaffold(tester);

      repo.throwOnSaveArtifact = StateError('db down');
      await controller.select('hello lore');
      await tester.pump(); // let the listener fire the SnackBar

      // LoreErrorKind.load → ARB errorLoading.
      expect(find.text('Could not load.'), findsOneWidget);
      // One SnackBar per errorSerial: no duplicate while it is on screen.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets(
        'a failed favorite shows the save-error SnackBar and a failed '
        'delete shows the delete-error SnackBar (kind → ARB mapping)',
        (final WidgetTester tester) async {
      void dismissSnackBar() {
        // ScaffoldMessenger QUEUES a second SnackBar while one is on screen;
        // remove the current one deterministically (and with it its pending
        // dismiss timer) before raising the next error.
        ScaffoldMessenger.of(tester.element(find.byType(Scaffold)))
            .removeCurrentSnackBar();
      }

      await pumpScaffold(tester);
      await controller.select(Artifact(path: 'known.txt', md5sum: 'deadbeef'));

      repo.throwOnAddToFavorites = StateError('nope');
      await controller.toggleFavorite();
      await tester.pump();
      // LoreErrorKind.save → ARB errorSaving.
      expect(find.text('Could not save. Please try again.'), findsOneWidget);
      dismissSnackBar();
      await tester.pumpAndSettle();
      expect(find.text('Could not save. Please try again.'), findsNothing);

      repo.throwOnDeleteRemark = StateError('no');
      await controller.deleteRemark(const Remark.simple(text: 'x', id: 1));
      await tester.pump();
      // LoreErrorKind.delete → ARB errorDeleting.
      expect(find.text('Could not delete.'), findsOneWidget);
      dismissSnackBar();
      await tester.pumpAndSettle();
    });

    testWidgets(
        'isCalculating shows the LinearProgressIndicator, and it '
        'disappears when the load finishes', (final WidgetTester tester) async {
      final gate = Completer<void>();
      repo.loadRemarksGate = gate.future;
      await pumpScaffold(tester);
      expect(find.byType(LinearProgressIndicator), findsNothing);

      final pending = controller.select('hello lore');
      await tester.pump(); // busy flag published

      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      gate.complete();
      await pending;
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('drawer shows the favorites empty state',
        (final WidgetTester tester) async {
      // Anonymous repo: no Gravatar fetch and the sign-in header path.
      repo = FakeLoreRepo(userId: null);
      controller.dispose();
      controller = LoreController(repo: repo);
      await pumpScaffold(tester);

      tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsOneWidget);
      expect(find.text('No favorite artifacts yet.'), findsOneWidget);
    });
  });
}
