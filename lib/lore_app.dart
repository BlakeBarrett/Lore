import 'dart:async';
import 'dart:io';

import 'package:Lore/artifact.dart';
import 'package:Lore/artifact_details.dart';
import 'package:Lore/auth_widget.dart';
import 'package:Lore/lore_api.dart';
import 'package:Lore/md5_utils.dart';
import 'package:Lore/remark_entry_widget.dart';
import 'package:Lore/remark_list_widget.dart';
import 'package:Lore/drawer_widget.dart';
import 'package:Lore/file_drop_handlers.dart';
import 'package:Lore/main.dart';
import 'package:Lore/remark.dart';
import 'package:anim_search_bar/anim_search_bar.dart';
import 'package:app_links/app_links.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:regexpattern/regexpattern.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

// TODO: Replace "desktop_drop" and "flutter_dropzone" with https://pub.dev/packages/super_drag_and_drop
// TODO: i18n for all the Strings
// TODO: Add "Favorites" feature per user
// TODO: Add image preview for media files
class LoreApp extends StatelessWidget {
  const LoreApp({super.key});

  @override
  Widget build(final BuildContext context) {
    String title = 'LORE';

    final theme = ThemeData(
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
  bool _artifactsCalculating = false;
  List<Remark> _remarks = Remark.dummyData;
  String _title = 'LORE';

  late final StreamSubscription<Uri> _appLinksSubscription;
  late final StreamSubscription<AuthState> _authStateSubscription;

  final TextEditingController _animatedSearchBarTextConroller =
      TextEditingController();

  @override
  void initState() {
    _appLinksSubscription = AppLinks().allUriLinkStream.listen((uri) {
      // Do something (navigation, ...)
      debugPrint('app_links uri: $uri');
    });
    _authStateSubscription =
        supabaseInstance.auth.onAuthStateChange.listen((data) {
      // Handle user redirection after magic link login
      debugPrint('Supabase AuthStateChange: $data');
      setState(() => {});
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
    await LoreAPI.loadRemarks(md5sum: artifact.md5sum)
        .then((values) => setState(() {
              _artifact = artifact;
              _remarks = values;
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

  @override
  Widget build(final BuildContext context) {
    if (_artifact?.md5sum != null) {
      LoreAPI.loadRemarks(md5sum: _artifact!.md5sum).then((value) {
        setState(() {
          _remarks = value;
          _title =
              (_artifact?.name) != null ? '${_artifact?.name} - LORE' : 'LORE';
          widget.onTitleChange(_title);
        });
      });
    }

    final scaffold = SafeArea(
        child: Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: Theme.of(context).primaryIconTheme,
        title: Text(_title,
            overflow: TextOverflow.fade,
            style: Theme.of(context).primaryTextTheme.displaySmall),
        actions: [
          IconButton(
              onPressed: onOpenFileTap, icon: const Icon(Icons.folder_open)),
          AnimSearchBar(
            width: MediaQuery.of(context).size.width - 80,
            color: Theme.of(context).bannerTheme.backgroundColor,
            textController: _animatedSearchBarTextConroller,
            boxShadow: false,
            helpText: 'Search by MD5 or URL',
            onSubmitted: onSearch,
            onSuffixTap: () =>
                setState(() => _animatedSearchBarTextConroller.clear()),
          ),
        ],
      ),
      body: Flex(
        direction: Axis.vertical,
        mainAxisSize: MainAxisSize.max,
        children: [
          (_artifactsCalculating)
              ? const LinearProgressIndicator()
              : const SizedBox.shrink(),
          ArtifactDetailsWidget(
              artifact: _artifact, onOpenFileTap: onOpenFileTap),
          Expanded(
            child: RemarkListWidget(
              remarks: _remarks,
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
                  },
                ),
        ],
      ),
      drawer: DrawerWidget(
          authenticated: LoreAPI.accessToken != null,
          userEmail: LoreAPI.userEmail,
          onLogout: () => supabaseInstance.auth.signOut(),
          onShowAuthWidget: () {
            Navigator.of(context).pop();
            AuthWidget.showAuthWidget(context, supabaseInstance);
          }),
    ));

    if (kIsDesktop) {
      return DesktopFileDropHandler(
          onCalculating: onCalculating, onDrop: onDrop, child: scaffold);
    } else if (kIsWeb) {
      return WebFileDropHandler(
          onCalculating: onCalculating, onDrop: onDrop, child: scaffold);
    } else {
      return scaffold;
    }
  }
}
