import 'dart:async';
import 'dart:io';

import 'package:Lore/artifact.dart';
import 'package:Lore/artifact_details.dart';
import 'package:Lore/auth_widget.dart';
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
class LoreApp extends StatelessWidget {
  const LoreApp({super.key});

  @override
  Widget build(final BuildContext context) {
    String title = 'LORE';
    return MaterialApp(
      title: title,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        primaryColor: Colors.deepOrange,
        primaryTextTheme: const TextTheme(
          bodyMedium: TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      ),
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
  String? get _accessToken => supabaseInstance.auth.currentSession?.accessToken;
  String? get _userId => supabaseInstance.auth.currentUser?.id;
  String? get _userEmail => supabaseInstance.auth.currentUser?.email;
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

  Future<void> saveArtifact(final Artifact artifact) async {
    await supabaseInstance.from('Artifacts').upsert({
      'name': artifact.name,
      'md5': artifact.md5sum,
    }).catchError((error) {
      debugPrint('Error saving Artifact: $error');
    });
  }

  Future<List<Remark>> loadRemarks({required final String md5sum}) async {
    return await supabaseInstance
        .from('Remarks')
        .select()
        .eq('artifact_md5', md5sum)
        .order('created_at', ascending: true)
        .then((value) =>
            value.map((item) => Remark.fromAPIResponse(item)).toList());
  }

  Future<void> saveRemark(
      {required final String remark,
      required final String? md5sum,
      required final String? userId}) async {
    if ((userId?.isNotEmpty ?? false) && (md5sum?.isNotEmpty ?? false)) {
      final Map<String, dynamic> payload = {
        'artifact_md5': md5sum,
        'remark': remark,
        'user_id': userId,
      };
      await supabaseInstance
          .from('Remarks')
          .insert(payload)
          .catchError((error) {
        debugPrint('Error saving remark: $error');
      });
    }
  }

  Future<void> onSearch(final String value) async {
    onCalculating(true);
    Artifact artifact;
    if (value.isMD5()) {
      artifact = Artifact.fromMd5(value);
    } else if (value.isUri()) {
      artifact = Artifact.fromURI(Uri.parse(value));
    } else {
      artifact = Artifact(path: value, md5sum: md5SumFor(value));
    }
    await saveArtifact(artifact);
    await loadRemarks(md5sum: value).then((values) => setState(() {
          _artifact = artifact;
          _remarks = values;
          _title = '${_artifact?.name} - LORE';
        }));
    onCalculating(false);
  }

  Future<void> onOpenFileTap() async {
    final FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.any, allowMultiple: false);
    if (result == null) {
      return;
    }
    await onCalculating(true);
    final PlatformFile first = result.files.first;
    try {
      if (first.bytes != null) {
        final bytes = first.bytes!;
        final byteStream = Stream.fromIterable([bytes]);
        final md5sum = await calculateMD5(byteStream);
        _artifact = Artifact(path: first.name, md5sum: md5sum);
      } else {
        final File file = File(first.path!);
        _artifact = await Artifact.fromFile(file);
      }
    } catch (e) {
      debugPrint('Error opening file: $e');
      onCalculating(false);
      return;
    }
    await saveArtifact(_artifact!);
    await loadRemarks(md5sum: _artifact!.md5sum).then((values) {
      setState(() {
        _remarks = values;
      });
      onCalculating(false);
    });
  }

  Future<void> onDrop(final dynamic values) async {
    if (values.isNotEmpty) {
      await saveArtifact(values.first);
      setState(() {
        _artifact = values.first;
        _title = '${_artifact?.name} - LORE';
        widget.onTitleChange(_title);
      });
      onCalculating(false);
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
      loadRemarks(md5sum: _artifact!.md5sum).then((value) {
        setState(() {
          _remarks = value;
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
          RemarkEntryWidget(
            enabled: _accessToken != null,
            onLogin: () => AuthWidget.showAuthWidget(context, supabaseInstance),
            onSubmitted: (value) async {
              await saveRemark(
                  remark: value, md5sum: _artifact?.md5sum, userId: _userId);
              loadRemarks(md5sum: _artifact!.md5sum).then((values) {
                setState(
                  () => _remarks = values,
                );
              });
            },
          ),
        ],
      ),
      drawer: DrawerWidget(
          authenticated: _accessToken != null,
          userEmail: _userEmail,
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
