import 'dart:async';

import 'package:Lore/artifact.dart';
import 'package:Lore/artifact_details.dart';
import 'package:Lore/auth_widget.dart';
import 'package:Lore/remark_entry_widget.dart';
import 'package:Lore/remark_list_widget.dart';
import 'package:Lore/drawer_widget.dart';
import 'package:Lore/file_drop_handlers.dart';
import 'package:Lore/main.dart';
import 'package:Lore/remark.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

// TODO: Integrate app_links to finish the magic link login flow: https://pub.dev/packages/app_links
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
  int _artifactsCalculating = 0;
  String? get _accessToken => supabaseInstance.auth.currentSession?.accessToken;

  List<Remark> _remarks = Remark.dummyData;

  late final StreamSubscription<AuthState> _authStateSubscription;
  final _appLinks = AppLinks();

  String _title = 'LORE';

  @override
  void initState() {
    _appLinks.allUriLinkStream.listen((uri) {
      // Do something (navigation, ...)
      debugPrint('app_links uri: $uri');
    });
    _authStateSubscription =
        supabaseInstance.auth.onAuthStateChange.listen((data) {
      // Handle user redirection after magic link login
      debugPrint('Supabase AuthStateChange: $data');
    });
    super.initState();
  }

  @override
  void dispose() {
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

  @override
  Widget build(final BuildContext context) {
    if (_artifact?.md5sum != null) {
      loadRemarks(md5sum: _artifact!.md5sum).then((value) {
        setState(() {
          _remarks = value;
        });
      });
    }

    final scaffold = Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Row(children: [
          Text(_title, style: Theme.of(context).primaryTextTheme.displaySmall),
        ]),
      ),
      body: SafeArea(
          child: Column(
        children: [
          (_artifactsCalculating > 0)
              ? const LinearProgressIndicator()
              : const SizedBox.shrink(),
          ArtifactDetailsWidget(artifact: _artifact),
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
                  remark: value,
                  md5sum: _artifact?.md5sum,
                  userId: supabaseInstance.auth.currentUser?.id);
              loadRemarks(md5sum: _artifact!.md5sum).then((values) {
                setState(
                  () => _remarks = values,
                );
              });
            },
          ),
        ],
      )),
      drawer: DrawerWidget(
        authenticated: _accessToken != null,
        userEmail: supabaseInstance.auth.currentUser?.email,
        onLogout: () => supabaseInstance.auth.signOut(),
        onShowAuthWidget: () =>
            AuthWidget.showAuthWidget(context, supabaseInstance),
      ),
    );

    onDrop(values) async {
      if (values.isNotEmpty) {
        await saveArtifact(values.first);
        setState(() {
          _artifact = values.first;
          _artifactsCalculating = 0;
          _title = '${_artifact?.name} - LORE';
          widget.onTitleChange(_title);
        });
      }
    }

    onCalculating(artifactsCalculating) {
      setState(() {
        _artifactsCalculating = artifactsCalculating;
      });
    }

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
