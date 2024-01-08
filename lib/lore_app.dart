import 'dart:io';

import 'package:Lore/artifact.dart';
import 'package:Lore/artifact_details.dart';
import 'package:Lore/comment_widget.dart';
import 'package:Lore/md5_utils.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';

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
  int artifactsCalculating = 0;

  late DropzoneViewController dropzoneController;

  @override
  Widget build(final BuildContext context) {
    bool isDesktop = false;
    try {
      isDesktop = Platform.isWindows ||
          Platform.isLinux ||
          Platform.isFuchsia ||
          Platform.isMacOS;
    } catch (e) {
      isDesktop = false;
    }

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
            remarks: [
              Remark('Hello', 'me', DateTime.now()),
              Remark('Hi', 'them', DateTime.now()),
              Remark('How are you?', 'me', DateTime.now()),
              Remark('Fine', 'them', DateTime.now()),
              Remark(
                  'What are your lunch plans for today?', 'me', DateTime.now()),
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
            ],
          ),
          const CommentInputArea()
        ],
      )),
      drawer: const DrawerViewWidget(),
    );

    if (isDesktop) {
      return DropTarget(
          child: scaffold,
          onDragDone: (details) {
            final files = details.files;
            if (files.isNotEmpty) {
              files.forEach((element) async {
                final File file = File(element.path);
                setState(() => artifactsCalculating++);
                calculateMD5(file).then((md5sum) {
                  setState(() {
                    artifactsCalculating--;
                    artifact = Artifact(file.path, md5sum);
                  });
                  debugPrint('$artifact');
                });
              });
            }
          });
    } else if (kIsWeb) {
      return Stack(
        children: [
          DropzoneView(
              cursor: CursorType.grab,
              operation: DragOperation.all,
              onCreated: (ctrl) => dropzoneController = ctrl,
              onDrop: (value) {
                if (value is File) {
                  setState(() => artifactsCalculating++);
                  debugPrint(value.toString());
                  dropzoneController.getFileStream(value).listen((data) async {
                    var md5sum = md5Convert(data).toString();
                    var path = await dropzoneController.getFilename(value);
                    setState(() {
                      artifactsCalculating--;
                      artifact = Artifact(path, md5sum);
                    });
                  });
                } else if (value is String) {
                  debugPrint('Received String: $value');
                  setState(() => artifactsCalculating++);
                  var md5sum = md5SumFor(value);
                  setState(() {
                    artifactsCalculating--;
                    artifact = Artifact('', md5sum);
                  });
                } else {
                  debugPrint('Received unkown: $value');
                }
              }),
          scaffold,
        ],
      );
    } else {
      return scaffold;
    }
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
