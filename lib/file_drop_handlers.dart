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
  Widget build(final BuildContext context) {
    return DropTarget(
        child: child,
        onDragDone: (final details) async {
          final files = details.files;
          onCalculating(files.length);
          if (files.isNotEmpty) {
            final List<Artifact> artifacts = [];
            for (var i = 0; i < files.length; i++) {
              final element = files[i];
              final File file = File(element.path);
              final byteStream = file.openRead();
              final md5sum = await calculateMD5(byteStream);
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
  Widget build(final BuildContext context) {
    late DropzoneViewController controller;
    return Stack(children: [
      DropzoneView(
          cursor: CursorType.grabbing,
          operation: DragOperation.all,
          onCreated: (final ctrl) => controller = ctrl,
          onDrop: (final value) async {
            debugPrint('DropzoneView.onDrop: $value');
            onCalculating(1);
            if (value is String) {
              var md5sum = '';
              try {
                final uri = Uri.parse(value);
                md5sum = md5SumFor(uri.toString());
              } catch (e) {
                debugPrint('$e');
                md5sum = md5SumFor(value);
              }
              onDrop([Artifact('', md5sum)]);
            } else if (value.toString() == '[object File]') {
              try {
                final path = await controller.getFilename(value);
                controller.createFileUrl(value);
                final bytes = await controller.getFileData(value);
                final byteStream = Stream.fromIterable([bytes]);
                final md5sum = await calculateMD5(byteStream);
                onDrop([Artifact(path, md5sum)]);
                controller.releaseFileUrl(value);
              } catch (e) {
                debugPrint('$e');
              }
            } else {
              debugPrint('Received unkown: $value');
            }
          }),
      child,
    ]);
  }
}
