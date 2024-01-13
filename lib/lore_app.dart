import 'dart:async';

import 'package:Lore/artifact.dart';
import 'package:Lore/artifact_details.dart';
import 'package:Lore/comment_widget.dart';
import 'package:Lore/drawer_view_widget.dart';
import 'package:Lore/file_drop_handlers.dart';
import 'package:Lore/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

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
  String? _accessToken = supabaseInstance.auth.currentSession?.accessToken;

  List<Remark> _remarks = [
    Remark('Hello', 'me', DateTime.now()),
    Remark('Hi', 'them', DateTime.now()),
    Remark('How are you?', 'me', DateTime.now()),
    Remark('Fine', 'them', DateTime.now()),
    Remark('What are your lunch plans for today?', 'me', DateTime.now()),
    Remark('I am going to the park', 'them', DateTime.now()),
    Remark('That sounds lovely!', 'them', DateTime.now()),
    Remark('Yes, it is a beautiful day', 'them', DateTime.now()),
    Remark(
        'I think I will go to the park as well; if you don\'t mind me copying your idea.',
        'them',
        DateTime.now()),
    Remark('Not at all', 'me', DateTime.now()),
    Remark('Great!', 'them', DateTime.now()),
    Remark('I will see you there', 'them', DateTime.now()),
    Remark('Goodbye', 'me', DateTime.now()),
    Remark('Bye', 'them', DateTime.now()),
  ];

  late final StreamSubscription<AuthState> _authStateSubscription;

  @override
  void initState() {
    _authStateSubscription =
        supabaseInstance.auth.onAuthStateChange.listen((data) {
      // Handle user redirection after magic link login
      _accessToken = data.session?.accessToken;
    });
    super.initState();
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  Future<List<Remark>> loadRemarks() async {
    final md5sum = _artifact?.md5sum;
    if (md5sum == null) {
      return [];
    }
    return await supabaseInstance
        .from('Remarks')
        .select()
        .eq('artifact_md5', _artifact!.md5sum)
        .order('created_at', ascending: false)
        .then((value) => value
            .map((e) => Remark(e['remark'], e['user_id'], e['created_at']))
            .toList());
  }

  Future<void> saveRemark(final String remark) async {
    final userId = supabaseInstance.auth.currentUser!.id;
    if (userId.isNotEmpty) {
      await supabaseInstance.from('Remarks').insert({
        'artifact_md5': _artifact?.md5sum,
        'remark': remark,
        'user_id': userId,
      });
    }
  }

  @override
  Widget build(final BuildContext context) {
    if (_artifact?.md5sum != null) {
      loadRemarks().then((value) {
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
          CommentArea(
            remarks: _remarks,
          ),
          CommentInputArea(
            onSubmitted: (value) async {
              await saveRemark(value);
              loadRemarks().then((values) {
                setState(
                  () => _remarks = values,
                );
              });
            },
          ),
        ],
      )),
      drawer: const DrawerViewWidget(),
    );

    onDrop(values) {
      if (values.isNotEmpty) {
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
