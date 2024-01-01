import 'dart:io';

import 'package:Lore/artifact.dart';
import 'package:Lore/artifact_details.dart';
import 'package:Lore/comment_widget.dart';
import 'package:Lore/md5_utils.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

class LoreApp extends StatelessWidget {
  const LoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
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

  @override
  Widget build(final BuildContext context) {
    return DropTarget(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('LORE'),
          ),
          body: SafeArea(
              child: Column(
            children: [
              ArtifactDetailsWidget(artifact: artifact),
              const CommentArea(),
              const CommentInputArea()
            ],
          )),
          drawer: const DrawerViewWidget(),
        ),
        onDragDone: (details) {
          final files = details.files;
          if (files.isNotEmpty) {
            files.forEach((element) async {
              final File file = File(element.path);
              final String md5sum = await calculateMD5(file);
              setState(() {
                artifact = Artifact(element.path, md5sum);
              });
              // artifact = Artifact(element.path, md5sum);
              print(artifact);
            });
          }
        });
  }
}

class DrawerViewWidget extends StatelessWidget {
  const DrawerViewWidget({super.key});

  @override
  Widget build(final BuildContext context) {
    return Drawer(
        child: ListView(padding: EdgeInsets.zero, children: [
      const DrawerHeader(child: Text("User Profile")),
      ListTile(
        title: const Text("Logout"),
        onTap: () {
          Navigator.pop(context);
        },
      )
    ]));
  }
}
