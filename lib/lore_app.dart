import 'dart:async';

import 'package:Lore/artifact.dart';
import 'package:Lore/artifact_details.dart';
import 'package:Lore/comment_widget.dart';
import 'package:Lore/drawer_view_widget.dart';
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
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'LORE',
      home: LoreScaffoldWidget(),
    );
  }
}

class LoreScaffoldWidget extends StatefulWidget {
  const LoreScaffoldWidget({super.key});

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
        title: const Text('LORE'),
      ),
      body: SafeArea(
          child: Column(
        children: [
          (_artifactsCalculating > 0)
              ? const LinearProgressIndicator()
              : const SizedBox.shrink(),
          ArtifactDetailsWidget(artifact: _artifact),
          Expanded(
            child: CommentArea(
              remarks: _remarks,
            ),
          ),
          CommentInputArea(
            enabled: _accessToken != null,
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
      drawer: DrawerViewWidget(
        authenticated: _accessToken != null,
      ),
    );

    onDrop(values) async {
      if (values.isNotEmpty) {
        try {
          await saveArtifact(values.first);
        } catch (error) {
          debugPrint('$error');
        }
        setState(() {
          _artifact = values.first;
          _artifactsCalculating = 0;
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
