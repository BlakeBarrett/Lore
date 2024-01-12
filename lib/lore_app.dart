import 'dart:async';

import 'package:Lore/artifact.dart';
import 'package:Lore/artifact_details.dart';
import 'package:Lore/comment_widget.dart';
import 'package:Lore/drawer_view_widget.dart';
import 'package:Lore/file_drop_handlers.dart';
import 'package:Lore/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
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
  Artifact? artifact;
  int artifactsCalculating = 0;
  String? accessToken = supabaseInstance.auth.currentSession?.accessToken;

  late DropzoneViewController dropzoneController;
  final List<Remark> remarks = [
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
      accessToken = data.session?.accessToken;
    });
    super.initState();
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final scaffold = Scaffold(
      appBar: AppBar(
        title: const Text('LORE'),
      ),
      body: SafeArea(
          child: Column(
        children: [
          (artifactsCalculating > 0)
              ? const LinearProgressIndicator()
              : const SizedBox.shrink(),
          ArtifactDetailsWidget(artifact: artifact),
          CommentArea(
            remarks: remarks,
          ),
          const CommentInputArea()
        ],
      )),
      drawer: const DrawerViewWidget(),
    );

    if (kIsDesktop) {
      return DesktopFileDropHandler(
          onCalculating: (artifactsCalculating) {
            setState(() {
              this.artifactsCalculating = artifactsCalculating;
            });
          },
          onDrop: (values) {
            if (values.isNotEmpty) {
              setState(() {
                artifact = values.first;
                artifactsCalculating = 0;
              });
            }
          },
          child: scaffold);
    } else if (kIsWeb) {
      return WebFileDropHandler(
          onCalculating: (artifactsCalculating) {
            setState(() {
              this.artifactsCalculating = artifactsCalculating;
            });
          },
          onDrop: (values) {
            if (values.isNotEmpty) {
              setState(() {
                artifact = values.first;
                artifactsCalculating = 0;
              });
            }
          },
          child: scaffold);
    } else {
      return scaffold;
    }
  }
}
