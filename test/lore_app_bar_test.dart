import 'package:Lore/artifact.dart';
import 'package:anim_search_bar/anim_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Lore/lore_app_bar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:like_button/like_button.dart';

void main() {
  group('LoreAppBar', () {
    testWidgets('renders correctly', (WidgetTester tester) async {
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
                  onSearch: (String query) {},
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
        (WidgetTester tester) async {
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
                  onSearch: (String query) {},
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
        (WidgetTester tester) async {
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
        (WidgetTester tester) async {
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
                  onSearch: (String query) {},
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
  });
}
