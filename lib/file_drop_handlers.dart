import 'dart:io';

import 'package:Lore/artifact.dart';
import 'package:Lore/md5_utils.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';

class DesktopFileDropHandler extends StatelessWidget {
  const DesktopFileDropHandler(
      {super.key,
      required this.onDrop,
      required this.onCalculating,
      required this.child});

  final Function(List<Artifact> values) onDrop;
  final Function(int artifactsCalculating) onCalculating;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
        child: child,
        onDragDone: (details) async {
          final files = details.files;
          onCalculating(files.length);
          if (files.isNotEmpty) {
            final List<Artifact> artifacts = [];
            for (var i = 0; i < files.length; i++) {
              final element = files[i];
              final File file = File(element.path);
              final md5sum = await calculateMD5(file);
              final Artifact artifact = Artifact(file.path, md5sum);
              artifacts.add(artifact);
              debugPrint('$artifact');
            }
            onDrop(artifacts);
          }
        });
  }
}

class WebFileDropHandler extends StatelessWidget {
  const WebFileDropHandler(
      {super.key,
      required this.onDrop,
      required this.onCalculating,
      required this.child});

  final Function(List<Artifact> values) onDrop;
  final Function(int artifactsCalculating) onCalculating;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    DropzoneViewController? dropzoneController;
    return Stack(children: [
      DropzoneView(
          cursor: CursorType.grab,
          operation: DragOperation.all,
          onCreated: (ctrl) => dropzoneController = ctrl,
          onDrop: (value) {
            if (value is File) {
              onCalculating(1);
              debugPrint(value.toString());
              dropzoneController?.getFileStream(value).listen((data) async {
                var md5sum = md5Convert(data).toString();
                var path = await dropzoneController?.getFilename(value) ?? '';
                onDrop([Artifact(path, md5sum)]);
              });
            } else if (value is String) {
              debugPrint('Received String: $value');
              onCalculating(1);
              var md5sum = md5SumFor(value);
              onDrop([Artifact('', md5sum)]);
            } else {
              debugPrint('Received unkown: $value');
            }
          }),
      child,
    ]);
  }
}
