import 'package:Lore/app_config.dart';
import 'package:Lore/auth_widget.dart';
import 'package:Lore/drawer_widget.dart';
import 'package:Lore/file_drop_handlers.dart';
import 'package:Lore/lore_app_bar.dart';
import 'package:Lore/lore_controller.dart';
import 'package:Lore/repo/lore_repo.dart';
import 'package:Lore/repo/supabase_lore_repo.dart';
import 'package:Lore/remark_entry_widget.dart';
import 'package:Lore/remark_list_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:Lore/l10n/app_localizations.dart';
import 'package:Lore/l10n/app_localizations_en.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class LoreApp extends StatelessWidget {
  const LoreApp({super.key});

  /// App-bar / header surface. WCAG 2.1 AA (1.4.3) needs >= 4.5:1 for the
  /// small text rendered on it (md5 subtitle at titleSmall, 12–14px).
  /// White on plain deepOrange (Colors.deepOrange, #FF5722) is only ~2.2:1
  /// and even opaque white on deepOrange.shade700 (#E64A19) is ~3.9:1 —
  /// both fail AA for normal text. deepOrange.shade900 (#BF360C) with
  /// opaque white measures (1.0+.05)/(0.1414+.05) ≈ 5.6:1: AA for normal
  /// text and AAA for large text. (Contrast math: relative luminance per
  /// WCAG, L = 0.2126R'+0.7152G'+0.0722B' with sRGB linearization.)
  static const Color primarySurface = Color(0xFFBF360C); // deepOrange.shade900

  /// Text drawn on [primarySurface]. Previously Colors.white70, whose 70%
  /// alpha blended into the orange drops the effective contrast to ~2.2:1.
  /// Opaque white keeps every on-primary style at the 5.6:1 measured above.
  static const TextTheme onPrimaryTextTheme =
      TextTheme(bodyMedium: TextStyle(color: Colors.white, fontSize: 18));

  @override
  Widget build(final BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      primarySwatch: Colors.blueGrey,
      primaryColor: primarySurface,
      // onPrimary drives AppBar foreground/icons so its text and the md5
      // subtitle inherit the AA-passing opaque-white scheme.
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySurface,
        primary: primarySurface,
        onPrimary: Colors.white,
      ),
      primaryTextTheme: onPrimaryTextTheme.copyWith(
        titleSmall: const TextStyle(color: Colors.white),
        titleMedium: const TextStyle(color: Colors.white),
        titleLarge: const TextStyle(color: Colors.white),
        displayLarge: const TextStyle(color: Colors.white),
        displaySmall: const TextStyle(color: Colors.white),
      ),
    );

    // Remove the splash screen once the app is fully loaded
    FlutterNativeSplash.remove();

    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // The delegate is not in scope above MaterialApp; the OS window title
      // uses the template (English) value from the generated class.
      title: AppLocalizationsEn().appTitle,
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
  /// When [controller] is provided the widget uses it as-is and does NOT
  /// dispose it — ownership (and disposal) stays with the injector. This is
  /// the seam for widget tests (U7). With no controller injected, the
  /// State creates and owns a live one exactly as before.
  const LoreScaffoldWidget({super.key, this.controller});

  final LoreController? controller;

  @override
  State<StatefulWidget> createState() => _LoreScaffoldWidgetState();
}

class _LoreScaffoldWidgetState extends State<LoreScaffoldWidget> {
  late final LoreController _controller;
  bool _ownsController = true;
  int _lastShownErrorSerial = 0;

  @override
  void initState() {
    super.initState();
    final injected = widget.controller;
    if (injected != null) {
      _controller = injected;
      _ownsController = false;
    } else {
      final LoreRepo repo = SupabaseLoreRepo(AppConfig.instance);
      _controller = LoreController(
        repo: repo,
        initialSession: AppConfig.instance.supabase.auth.currentSession,
        authEvents: AppConfig.instance.supabase.auth.onAuthStateChange,
      );
    }
    _controller.addListener(_showErrorIfNeeded);
  }

  @override
  void dispose() {
    _controller.removeListener(_showErrorIfNeeded);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  /// Maps a controller failure kind to its localized message.
  /// [LoreController.lastError] carries the developer-facing detail (kept
  /// for debugPrint); the SnackBar shows the ARB string for the failure
  /// class, per U6: the view owns localization, the controller stays
  /// BuildContext-free.
  String _localizedError(final AppLocalizations? l10n) {
    switch (_controller.lastErrorKind) {
      case LoreErrorKind.load:
        return l10n?.errorLoading ?? 'Could not load.';
      case LoreErrorKind.save:
        return l10n?.errorSaving ?? 'Could not save. Please try again.';
      case LoreErrorKind.delete:
        return l10n?.errorDeleting ?? 'Could not delete.';
      case LoreErrorKind.auth:
        return l10n?.errorAuth ?? 'Authentication failed. Please try again.';
      case LoreErrorKind.unknown:
        // Unknown failures get the generic load message, not an auth
        // mislabel (review follow-up: don't imply a login problem).
        return l10n?.errorLoading ?? 'Could not load.';
    }
  }

  /// Surfaces each controller failure exactly once via a SnackBar.
  void _showErrorIfNeeded() {
    final error = _controller.lastError;
    if (error == null || _controller.errorSerial == _lastShownErrorSerial) {
      return;
    }
    _lastShownErrorSerial = _controller.errorSerial;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_localizedError(AppLocalizations.of(context))),
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
                // Announce the busy state (WCAG 4.1.3 status messages);
                // the indicator itself is announced live so screen readers
                // pick it up without stealing focus.
                SliverToBoxAdapter(
                  child: Semantics(
                    liveRegion: true,
                    label: AppLocalizations.of(context)?.loadingArtifact,
                    child: const LinearProgressIndicator(),
                  ),
                ),
              RemarkList(
                remarks: artifact == null
                    ? localizedOnboardingRemarks(AppLocalizations.of(context)!)
                    : artifact.remarks,
                userId: repo.userId,
                onDeleteRemark: _controller.deleteRemark,
                emptyMessage: artifact == null
                    ? null
                    : AppLocalizations.of(context)!.noRemarksYet,
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
                onDrop: (final values) => _controller.drop(values),
                child: scaffold)
            : (kIsWeb)
                ? WebFileDropHandler(
                    onCalculating: _controller.setCalculating,
                    onDrop: (final value) => _controller.drop([value]),
                    child: scaffold)
                : scaffold;
      },
    );
  }
}
