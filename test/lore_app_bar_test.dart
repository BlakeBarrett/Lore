import 'package:lore/artifact.dart';
import 'package:anim_search_bar/anim_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:lore/lore_app_bar.dart';
import 'package:lore/l10n/app_localizations.dart';
import 'package:like_button/like_button.dart';

void main() {
  group('LoreAppBar', () {
    testWidgets('renders correctly', (final WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                LoreAppBar(
                  artifact: Artifact(path: '', md5sum: ''),
                  onOpenFileTap: () {},
                  onSearch: (final String query) {},
                  onFavoriteTap: () {},
                  isFavorite: false,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(LoreAppBar), findsOneWidget);
    });

    testWidgets('calls onOpenFileTap when file icon is tapped',
        (final WidgetTester tester) async {
      bool isOpenFileTapCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                LoreAppBar(
                  artifact: Artifact(path: '', md5sum: ''),
                  onOpenFileTap: () {
                    isOpenFileTapCalled = true;
                  },
                  onSearch: (final String query) {},
                  onFavoriteTap: () {},
                  isFavorite: false,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.folder_open));
      expect(isOpenFileTapCalled, true);
    });

    testWidgets('calls onSearch when search icon is tapped',
        (final WidgetTester tester) async {
      String searchQuery = '';

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                LoreAppBar(
                  artifact: Artifact(path: '', md5sum: ''),
                  onOpenFileTap: () {},
                  onSearch: (final String query) {
                    searchQuery = query;
                  },
                  onFavoriteTap: () {},
                  isFavorite: false,
                ),
              ],
            ),
          ),
        ),
      );

      final Finder searchIcon =
          find.byType(AnimSearchBar, skipOffstage: false).last;
      await tester.tap(searchIcon);
      final Finder searchField = find.byType(TextField);
      await tester.enterText(searchField, 'test');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      await tester.pumpAndSettle();

      expect(searchQuery, 'test');
    });

    testWidgets('calls onFavoriteTap when favorite icon is tapped',
        (final WidgetTester tester) async {
      bool isFavoriteTapCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                LoreAppBar(
                  artifact: Artifact(path: '', md5sum: ''),
                  onOpenFileTap: () {},
                  onSearch: (final String query) {},
                  onFavoriteTap: () {
                    isFavoriteTapCalled = true;
                  },
                  isFavorite: false,
                ),
              ],
            ),
          ),
        ),
      );

      final Finder favoriteIcon =
          find.byType(LikeButton, skipOffstage: false).last;
      await tester.tap(favoriteIcon);

      await tester.pumpAndSettle();

      expect(isFavoriteTapCalled, true);
    });

    testWidgets('favorite toggle exposes an accessible label (WCAG 4.1.2)',
        (final WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                LoreAppBar(
                  artifact: Artifact(path: '', md5sum: ''),
                  onOpenFileTap: () {},
                  onSearch: (final String query) {},
                  onFavoriteTap: () {},
                  isFavorite: false,
                ),
              ],
            ),
          ),
        ),
      );

      // Exactly one node must carry the accessible name: the Semantics
      // wrapper names the merged node and the heart Icon deliberately has
      // no semanticLabel (a second label would merge into
      // "Add to favorites\nAdd to favorites" and double-read).
      expect(find.bySemanticsLabel('Add to favorites', skipOffstage: false),
          findsOneWidget);

      // State-aware (WCAG 4.1.2): when the artifact IS a favorite the
      // toggle removes it, so the name must say "Remove from favorites".
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                LoreAppBar(
                  artifact: Artifact(path: '', md5sum: ''),
                  onOpenFileTap: () {},
                  onSearch: (final String query) {},
                  onFavoriteTap: () {},
                  isFavorite: true,
                ),
              ],
            ),
          ),
        ),
      );
      expect(
          find.bySemanticsLabel('Remove from favorites', skipOffstage: false),
          findsOneWidget);
      expect(find.bySemanticsLabel('Add to favorites', skipOffstage: false),
          findsNothing);
      semantics.dispose();
    });

    testWidgets('favorite toggle is keyboard-activatable (WCAG 2.1.1)',
        (final WidgetTester tester) async {
      bool isFavoriteTapCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                LoreAppBar(
                  artifact: Artifact(path: '', md5sum: ''),
                  onOpenFileTap: () {},
                  onSearch: (final String query) {},
                  onFavoriteTap: () {
                    isFavoriteTapCalled = true;
                  },
                  isFavorite: false,
                ),
              ],
            ),
          ),
        ),
      );

      // The LikeButton itself is not focusable; its Focus wrapper (nearest
      // Focus ancestor) is what the keyboard handler lives on.
      final Element buttonElement =
          find.byType(LikeButton, skipOffstage: false).last.evaluate().single;
      Focus.of(buttonElement).requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(isFavoriteTapCalled, true);
    });
  });
}
