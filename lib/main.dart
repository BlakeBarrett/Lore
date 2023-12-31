import 'dart:io';

import 'package:Lore/md5_utils.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:desktop_window/desktop_window.dart' as window_size;
import 'package:file_icon/file_icon.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    window_size.DesktopWindow.setWindowSize(const Size(600, 1000));
  }
  runApp(const LoreApp());
}

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
  Widget build(BuildContext context) {
    return DropTarget(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('LORE'),
          ),
          body: SafeArea(
              child: Expanded(
                  child: Column(
            children: [
              ArtifactViewWidget(artifact: artifact),
              const CommentArea(),
              const CommentInputArea()
            ],
          ))),
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

class Artifact {
  final String path;
  final String md5sum;

  final String? mimeType;
  final int? length;

  const Artifact(this.path, this.md5sum, {this.mimeType, this.length});

  String get name => path.substring(path.lastIndexOf('/'));

  @override
  String toString() {
    return '$md5sum $path';
  }
}

class DrawerViewWidget extends StatelessWidget {
  const DrawerViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
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

class ArtifactViewWidget extends StatelessWidget {
  const ArtifactViewWidget({super.key, this.artifact});

  final Artifact? artifact;

  @override
  Widget build(BuildContext context) {
    if (artifact == null) {
      return const Spacer();
    }

    return Container(
        color: Colors.blue,
        padding: const EdgeInsets.all(36.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FileIcon('${artifact?.name}', size: 180),
            Text('File path: ${artifact?.path}'),
            Text('md5: ${artifact?.md5sum}')
          ],
        ));
  }
}

class ArtifactSliverScrollViewWidget extends StatelessWidget {
  const ArtifactSliverScrollViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: CustomScrollView(
      slivers: <Widget>[
        SliverPersistentHeader(
            pinned: true,
            floating: false,
            delegate: ArtifactPersistentHeaderDelegate()),
        const CommentArea()
      ],
    ));
  }
}

class ArtifactPersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return const Expanded(child: ArtifactViewWidget());
  }

  @override
  double get maxExtent => 300.0;

  @override
  double get minExtent => 50.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

class CommentBottomSheet extends StatefulWidget {
  const CommentBottomSheet({super.key});

  @override
  createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 400,
      child: const Expanded(
        child: CommentInputArea(),
      ),
    );
  }
}

class CommentArea extends StatelessWidget {
  const CommentArea({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return const ListTile(
            leading: Icon(Icons.comment),
            title: Text('Comment'),
          );
        },
      ),
    );
  }
}

class CommentInputArea extends StatelessWidget {
  const CommentInputArea({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[200],
      child: const TextField(
        decoration: InputDecoration(
          hintText: 'Write a comment...',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
