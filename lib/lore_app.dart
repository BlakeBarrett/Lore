import 'dart:async';
import 'dart:io';

import 'package:Lore/app_config.dart';
import 'package:Lore/artifact.dart';
import 'package:Lore/auth_widget.dart';
import 'package:Lore/drawer_widget.dart';
import 'package:Lore/file_drop_handlers.dart';
import 'package:Lore/hash_utils.dart';
import 'package:Lore/lore_app_bar.dart';
import 'package:Lore/md5_utils.dart';
import 'package:Lore/repo/lore_repo.dart';
import 'package:Lore/repo/supabase_lore_repo.dart';
import 'package:Lore/remark.dart';
import 'package:Lore/remark_entry_widget.dart';
import 'package:Lore/remark_list_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:Lore/l10n/app_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:regexpattern/regexpattern.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoreApp extends StatelessWidget {
  const LoreApp({super.key});

  @override
  Widget build(final BuildContext context) {
    String title = 'LORE';

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
      home: LoreScaffoldWidget(
        onTitleChange: (final String value) {
          title = value;
        },
      ),
    );
  }
}

class LoreScaffoldWidget extends StatefulWidget {
  const LoreScaffoldWidget({super.key, required this.onTitleChange});

  final Function(String title) onTitleChange;

  @override
  State<StatefulWidget> createState() => _LoreScaffoldWidgetState();
}

class _LoreScaffoldWidgetState extends State<LoreScaffoldWidget> {
  Artifact? _artifact;
  final List<Artifact> _favorites = [];

  AppConfig get _config => AppConfig.instance;
  LoreRepo get _repo => SupabaseLoreRepo(_config);

  late final StreamSubscription<Uri> _appLinksSubscription;
  late final StreamSubscription<AuthState> _authStateSubscription;

  @override
  void initState() {
    // _appLinksSubscription = AppLinks().allUriLinkStream.listen((uri) {
    //   // TODO: Handle incoming app links
    //   debugPrint('app_links uri: $uri');
    //   final String value = ('${uri.path.replaceFirst('/', '')}?${uri.query}');
    //   debugPrint('app_links value: $value');
    //   if (value != '?') {
    //     onArtifactSelected(value);
    //   }
    // });
    _authStateSubscription =
        _config.supabase.auth.onAuthStateChange.listen((data) async {
      debugPrint('Supabase AuthChangeEvent: ${data.event}');
      if (data.event == AuthChangeEvent.initialSession ||
          data.event == AuthChangeEvent.signedIn) {
        () async {
          try {
            await loadFavorites();
          } catch (e) {
            debugPrint('Error loading favorites: $e');
          }
          setState(() => {});
        }();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _appLinksSubscription.cancel();
    _authStateSubscription.cancel();
    super.dispose();
  }

  Future<void> onArtifactSelected(final dynamic value) async {
    onCalculating(true);
    Artifact artifact;
    if (value is Artifact) {
      artifact = value;
    } else if (value is PlatformFile) {
      try {
        if (value.bytes != null) {
          final bytes = value.bytes!;
          final md5sum = await calculateMD5(Stream.fromIterable([bytes]));
          final sha256sum =
              await sha256FromStream(Stream.fromIterable([bytes]));
          artifact =
              Artifact(path: value.name, md5sum: md5sum, sha256: sha256sum);
        } else {
          final File file = File(value.path!);
          artifact = await Artifact.fromFile(file);
        }
      } catch (e) {
        debugPrint('Error opening file: $e');
        onCalculating(false);
        return;
      }
    } else if (value is String) {
      if (value.isMD5()) {
        artifact = await _repo.loadArtifact(value) ??
            Artifact(path: '', md5sum: value);
      } else if (value.isUri()) {
        artifact = Artifact.fromURI(Uri.parse(value));
      } else {
        artifact = Artifact(path: value, md5sum: md5SumFor(value));
      }
    } else if (value is List) {
      artifact = value.first;
    } else {
      artifact = Artifact(path: value, md5sum: md5SumFor(value));
    }
    await _repo.saveArtifact(artifact);
    artifact.remarks = await _repo.loadRemarks(md5sum: artifact.md5sum);
    setState(() {
      _artifact = artifact;
    });
    onCalculating(false);
  }

  Future<void> onSearch(final String value) async {
    return await onArtifactSelected(value);
  }

  Future<void> onOpenFileTap() async {
    final FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.any, allowMultiple: false);
    if (result == null) {
      return;
    }
    final PlatformFile first = result.files.first;
    return await onArtifactSelected(first);
  }

  Future<void> onFavoriteTap() async {
    if (_artifact == null || _repo.userId == null) return;

    if (_favorites.contains(_artifact)) {
      await _repo.removeFromFavorites(
          artifact: _artifact!, userId: _repo.userId);
      setState(() {
        _favorites.remove(_artifact);
      });
    } else {
      await _repo.addToFavorites(artifact: _artifact!, userId: _repo.userId);
      setState(() {
        _favorites.add(_artifact!);
      });
    }
  }

  Future<void> onDrop(final dynamic values) async {
    if (values.isNotEmpty) {
      return await onArtifactSelected(values.first);
    }
  }

  Future<void> onCalculating(final bool artifactsCalculating) async {
    setState(() {});
  }

  Future<void> loadFavorites() async {
    if (_repo.userId == null) return;
    final List<Artifact> favorites =
        await _repo.loadFavoritesArtifacts(userId: _repo.userId);
    setState(() {
      _favorites.clear();
      _favorites.addAll(favorites);
    });
  }

  @override
  Widget build(final BuildContext context) {
    final scaffold = Scaffold(
      drawer: DrawerWidget(
        authenticated: _repo.accessToken != null,
        userEmail: _repo.userEmail,
        favorites: _favorites,
        onLogout: () => _config.supabase.auth.signOut(),
        onShowAuthWidget: () {
          Navigator.of(context).pop();
          AuthWidget.showAuthWidget(context, _config.supabase);
        },
        onShowArtifact: (final Artifact artifact) async {
          Navigator.of(context).pop();
          await onArtifactSelected(artifact);
        },
      ),
      body: CustomScrollView(
        slivers: [
          LoreAppBar(
            artifact: _artifact,
            onOpenFileTap: onOpenFileTap,
            onSearch: onSearch,
            onFavoriteTap: onFavoriteTap,
            isFavorite: _artifact != null && _favorites.contains(_artifact!),
          ),
          RemarkList(
            remarks: _artifact == null ? Remark.dummyData : _artifact?.remarks,
            userId: _repo.userId,
            onDeleteRemark: (final Remark deleteMe) async {
              await _repo.deleteRemark(remark: deleteMe).then((value) {
                setState(() {
                  _artifact?.remarks?.remove(deleteMe);
                });
              });
            },
          ),
        ],
      ),
      floatingActionButton: RemarkEntryWidget(
        enabled: _repo.accessToken != null,
        onLogin: () => AuthWidget.showAuthWidget(context, _config.supabase),
        onSubmitted: (final value) async {
          await _repo.saveRemark(
              remark: value, md5sum: _artifact?.md5sum, userId: _repo.userId);
          _artifact?.remarks =
              await _repo.loadRemarks(md5sum: _artifact!.md5sum);
          setState(() {});
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );

    return (_config.isDesktop)
        ? DesktopFileDropHandler(
            onCalculating: onCalculating, onDrop: onDrop, child: scaffold)
        : (kIsWeb)
            ? WebFileDropHandler(
                onCalculating: onCalculating, onDrop: onDrop, child: scaffold)
            : scaffold;
  }
}
