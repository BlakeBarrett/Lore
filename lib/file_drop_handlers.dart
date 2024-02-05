import 'dart:io';

import 'package:Lore/artifact.dart';
import 'package:Lore/md5_utils.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:regexpattern/regexpattern.dart';

class DesktopFileDropHandler extends StatelessWidget {
  const DesktopFileDropHandler(
      {super.key,
      required this.onDrop,
      required this.onCalculating,
      required this.child});

  final Function(List<Artifact> values) onDrop;
  final Function(bool artifactsCalculating) onCalculating;
  final Widget child;

  @override
  Widget build(final BuildContext context) {
    return DropTarget(
        child: child,
        onDragDone: (final details) async {
          final files = details.files;
          onCalculating(files.isNotEmpty);
          if (files.isNotEmpty) {
            final List<Artifact> artifacts = [];
            final element = files.first;
            final File file = File(element.path);
            final Artifact artifact = await Artifact.fromFile(file);
            artifacts.add(artifact);
            debugPrint('$artifact');
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
  final Function(bool artifactsCalculating) onCalculating;
  final Widget child;

  @override
  Widget build(final BuildContext context) {
    late DropzoneViewController controller;
    return Stack(children: [
      DropzoneView(
          cursor: CursorType.Default,
          operation: DragOperation.all,
          onCreated: (final ctrl) => controller = ctrl,
          onDrop: (final value) async {
            debugPrint('DropzoneView.onDrop: $value');
            onCalculating(true);
            if (value is String) {
              final Artifact artifact;
              if (value.isMD5()) {
                artifact = await Artifact.fromMd5(value);
              } else if (value.isUri()) {
                artifact = Artifact.fromURI(Uri.parse(value));
              } else {
                artifact = Artifact(path: value, md5sum: md5SumFor(value));
              }
              onDrop([artifact]);
            } else if (value.toString() == '[object File]') {
              try {
                controller.createFileUrl(value);
                final path = await controller.getFilename(value);
                final bytes = await controller.getFileData(value);
                final byteStream = Stream.fromIterable([bytes]);
                final md5sum = await calculateMD5(byteStream);
                final artifact = Artifact(path: path, md5sum: md5sum);
                onDrop([artifact]);
                controller.releaseFileUrl(value);
              } catch (e) {
                debugPrint('$e');
                onCalculating(false);
              }
            } else {
              debugPrint('Received unkown: $value');
            }
          }),
      child,
    ]);
  }
}
