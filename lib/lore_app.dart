import 'package:Lore/app_config.dart';
import 'package:Lore/auth_widget.dart';
import 'package:Lore/drawer_widget.dart';
import 'package:Lore/file_drop_handlers.dart';
import 'package:Lore/lore_app_bar.dart';
import 'package:Lore/lore_controller.dart';
import 'package:Lore/repo/lore_repo.dart';
import 'package:Lore/repo/supabase_lore_repo.dart';
import 'package:Lore/remark.dart';
import 'package:Lore/remark_entry_widget.dart';
import 'package:Lore/remark_list_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:Lore/l10n/app_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class LoreApp extends StatelessWidget {
  const LoreApp({super.key});

  @override
  Widget build(final BuildContext context) {
    const String title = 'LORE';

    final theme = ThemeData(
      useMaterial3: true,
      primarySwatch: Colors.blueGrey,
      primaryColor: Colors.deepOrange,
      primaryTextTheme: const TextTheme(
        bodyMedium: TextStyle(
          color: Colors.white70,
          fontSize: 18,
        ),
      ),
    );

    // Remove the splash screen once the app is fully loaded
    FlutterNativeSplash.remove();

    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      title: title,
      theme: theme,
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: theme.primaryColor,
        primaryTextTheme: theme.primaryTextTheme,
      ),
      themeMode: ThemeMode.system,
      home: const LoreScaffoldWidget(),
    );
  }
}

/// The app's root screen. Pure view: all domain state lives in
/// [LoreController]; this widget owns one controller instance (created in
/// `initState`, disposed in `dispose`) and rebuilds via [ListenableBuilder].
class LoreScaffoldWidget extends StatefulWidget {
  const LoreScaffoldWidget({super.key});

  @override
  State<StatefulWidget> createState() => _LoreScaffoldWidgetState();
}

class _LoreScaffoldWidgetState extends State<LoreScaffoldWidget> {
  late final LoreController _controller;
  int _lastShownErrorSerial = 0;

  @override
  void initState() {
    super.initState();
    final LoreRepo repo = SupabaseLoreRepo(AppConfig.instance);
    _controller = LoreController(
      repo: repo,
      initialSession: AppConfig.instance.supabase.auth.currentSession,
      authEvents: AppConfig.instance.supabase.auth.onAuthStateChange,
    );
    _controller.addListener(_showErrorIfNeeded);
  }

  @override
  void dispose() {
    _controller.removeListener(_showErrorIfNeeded);
    _controller.dispose();
    super.dispose();
  }

  /// Surfaces each controller failure exactly once via a SnackBar.
  /// (Hardcoded English for now; U6 wires the ARB keys.)
  void _showErrorIfNeeded() {
    final error = _controller.lastError;
    if (error == null || _controller.errorSerial == _lastShownErrorSerial) {
      return;
    }
    _lastShownErrorSerial = _controller.errorSerial;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (final BuildContext context, final Widget? _) {
        final repo = _controller.repo;
        final artifact = _controller.artifact;
        final scaffold = Scaffold(
          drawer: DrawerWidget(
            authenticated: repo.accessToken != null,
            userEmail: repo.userEmail,
            favorites: _controller.favorites,
            onLogout: () => AppConfig.instance.supabase.auth.signOut(),
            onShowAuthWidget: () {
              Navigator.of(context).pop();
              AuthWidget.showAuthWidget(context, AppConfig.instance.supabase);
            },
            onShowArtifact: (final artifact) async {
              Navigator.of(context).pop();
              await _controller.select(artifact);
            },
          ),
          body: CustomScrollView(
            slivers: [
              LoreAppBar(
                artifact: artifact,
                onOpenFileTap: _controller.openFile,
                onSearch: _controller.search,
                onFavoriteTap: _controller.toggleFavorite,
                isFavorite: artifact != null &&
                    _controller.favorites.contains(artifact),
              ),
              if (_controller.isCalculating)
                const SliverToBoxAdapter(
                  child: LinearProgressIndicator(),
                ),
              RemarkList(
                remarks: artifact == null ? Remark.dummyData : artifact.remarks,
                userId: repo.userId,
                onDeleteRemark: _controller.deleteRemark,
              ),
            ],
          ),
          floatingActionButton: RemarkEntryWidget(
            enabled: repo.accessToken != null,
            onLogin: () =>
                AuthWidget.showAuthWidget(context, AppConfig.instance.supabase),
            onSubmitted: _controller.addRemark,
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
        );

        return (AppConfig.instance.isDesktop)
            ? DesktopFileDropHandler(
                onCalculating: _controller.setCalculating,
                onDrop: _controller.drop,
                child: scaffold)
            : (kIsWeb)
                ? WebFileDropHandler(
                    onCalculating: _controller.setCalculating,
                    onDrop: _controller.drop,
                    child: scaffold)
                : scaffold;
      },
    );
  }
}
