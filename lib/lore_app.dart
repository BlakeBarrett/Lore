import 'dart:async';
import 'dart:io';

import 'package:Lore/artifact.dart';
import 'package:Lore/artifact_details.dart';
import 'package:Lore/auth_widget.dart';
import 'package:Lore/drawer_widget.dart';
import 'package:Lore/file_drop_handlers.dart';
import 'package:Lore/lore_api.dart';
import 'package:Lore/main.dart';
import 'package:Lore/md5_utils.dart';
import 'package:Lore/remark.dart';
import 'package:Lore/remark_entry_widget.dart';
import 'package:Lore/remark_list_widget.dart';
import 'package:anim_search_bar/anim_search_bar.dart';
import 'package:app_links/app_links.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:regexpattern/regexpattern.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// TODO: i18n for all the Strings: https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization
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
          color: Colors.white,
          fontSize: 18,
        ),
      ),
    );

    return MaterialApp(
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
  bool _artifactsCalculating = false;

  late final StreamSubscription<Uri> _appLinksSubscription;
  late final StreamSubscription<AuthState> _authStateSubscription;

  final TextEditingController _animatedSearchBarTextConroller =
      TextEditingController();

  @override
  void initState() {
    _appLinksSubscription = AppLinks().allUriLinkStream.listen((uri) {
      // TODO: Handle incoming app links
      debugPrint('app_links uri: $uri');
      final String value = ('${uri.path.replaceFirst('/', '')}?${uri.query}');
      debugPrint('app_links value: $value');
      if (value != '?') {
        onArtifactSelected(value);
      }
    });
    _authStateSubscription =
        supabaseInstance.auth.onAuthStateChange.listen((data) async {
      // Handle user redirection after magic link login
      debugPrint('Supabase AuthStateChange: $data');
      await loadFavorites();
      setState(() => {});
    });
    loadFavorites();
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
          final byteStream = Stream.fromIterable([bytes]);
          final md5sum = await calculateMD5(byteStream);
          artifact = Artifact(path: value.name, md5sum: md5sum);
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
        artifact = await Artifact.fromMd5(value);
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
    await LoreAPI.saveArtifact(artifact);
    await artifact.refreshRemarks().then((values) => setState(() {
          _artifact = artifact;
        }));
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

  Future<void> onFavoriteTap(final bool isFavorite) async {
    if (_artifact == null || LoreAPI.userId == null) return;

    if (_favorites.contains(_artifact)) {
      await LoreAPI.removeFromFavorites(
          artifact: _artifact!, userId: LoreAPI.userId);
      setState(() {
        _favorites.remove(_artifact);
      });
    } else {
      await LoreAPI.addToFavorites(
          artifact: _artifact!, userId: LoreAPI.userId);
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
    setState(() {
      _artifactsCalculating = artifactsCalculating;
    });
  }

  Future<void> loadFavorites() async {
    if (LoreAPI.userId == null) return;
    final List<Artifact> favorites =
        await LoreAPI.loadFavoritesArtifacts(userId: LoreAPI.userId);
    setState(() {
      _favorites.clear();
      _favorites.addAll(favorites);
    });
  }

  @override
  Widget build(final BuildContext context) {
    final scaffold = Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: Theme.of(context).primaryIconTheme,
        title: Text("LORE",
            overflow: TextOverflow.fade,
            style: Theme.of(context).primaryTextTheme.displaySmall),
        actions: [
          Tooltip(
            message: 'Browse for file',
            child: IconButton(
                onPressed: onOpenFileTap, icon: const Icon(Icons.folder_open)),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Tooltip(
              message: 'Search by MD5 or URL',
              child: AnimSearchBar(
                width: MediaQuery.of(context).size.width - 100,
                color: Theme.of(context).colorScheme.background,
                textFieldIconColor: Theme.of(context).primaryColor,
                textFieldColor: Theme.of(context).colorScheme.surface,
                searchIconColor: Theme.of(context).primaryColor,
                textController: _animatedSearchBarTextConroller,
                boxShadow: false,
                helpText: 'Search by MD5 or URL',
                onSubmitted: onSearch,
                style: Theme.of(context).textTheme.titleMedium,
                onSuffixTap: () =>
                    setState(() => _animatedSearchBarTextConroller.clear()),
              ),
            ),
          ),
        ],
      ),
      body: Flex(
        direction: Axis.vertical,
        mainAxisSize: MainAxisSize.max,
        children: [
          (_artifactsCalculating)
              ? LinearProgressIndicator(
                  color: Theme.of(context).colorScheme.onPrimary,
                  backgroundColor: Theme.of(context).primaryColor,
                )
              : const SizedBox.shrink(),
          ArtifactDetailsWidget(
            artifact: _artifact,
            isFavorite: _artifact != null && _favorites.contains(_artifact!),
            onOpenFileTap: onOpenFileTap,
            onFavoriteTap: onFavoriteTap,
          ),
          Expanded(
            child: RemarkListWidget(
              remarks:
                  (_artifact != null) ? _artifact?.remarks : Remark.dummyData,
              currentUser: LoreAPI.userId,
              onDeleteRemark: (final Remark deleteMe) async {
                await LoreAPI.deleteRemark(remark: deleteMe).then((value) {
                  _artifact?.remarks?.remove(deleteMe);
                  setState(() {});
                });
              },
            ),
          ),
          (_artifact == null)
              ? const SizedBox.shrink()
              : RemarkEntryWidget(
                  enabled: LoreAPI.accessToken != null,
                  onLogin: () =>
                      AuthWidget.showAuthWidget(context, supabaseInstance),
                  onSubmitted: (value) async {
                    await LoreAPI.saveRemark(
                        remark: value,
                        md5sum: _artifact?.md5sum,
                        userId: LoreAPI.userId);
                    await _artifact?.refreshRemarks();
                    setState(() {});
                  },
                ),
        ],
      ),
      drawer: DrawerWidget(
        authenticated: LoreAPI.accessToken != null,
        userEmail: LoreAPI.userEmail,
        favorites: _favorites,
        onLogout: () => supabaseInstance.auth.signOut(),
        onShowAuthWidget: () {
          Navigator.of(context).pop();
          AuthWidget.showAuthWidget(context, supabaseInstance);
        },
        onShowArtifact: (final Artifact artifact) async {
          Navigator.of(context).pop();
          await onArtifactSelected(artifact);
        },
      ),
    );

    return (kIsDesktop)
        ? DesktopFileDropHandler(
            onCalculating: onCalculating, onDrop: onDrop, child: scaffold)
        : (kIsWeb)
            ? WebFileDropHandler(
                onCalculating: onCalculating, onDrop: onDrop, child: scaffold)
            : scaffold;
  }
}
