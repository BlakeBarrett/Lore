import 'dart:io';

import 'package:Lore/app_config.dart';
import 'package:Lore/artifact.dart';
import 'package:Lore/hash_utils.dart';
import 'package:Lore/md5_utils.dart';
import 'package:Lore/repo/supabase_lore_repo.dart';
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

  final void Function(List<Artifact> values) onDrop;
  final void Function(bool artifactsCalculating) onCalculating;
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

  final void Function(List<Artifact> values) onDrop;
  final void Function(bool artifactsCalculating) onCalculating;
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
                final repo = SupabaseLoreRepo(AppConfig.instance);
                artifact = await repo.loadArtifact(value) ??
                    Artifact(path: '', md5sum: value);
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
                final md5sum = await calculateMD5(Stream.fromIterable([bytes]));
                final sha256sum =
                    await sha256FromStream(Stream.fromIterable([bytes]));
                final artifact =
                    Artifact(path: path, md5sum: md5sum, sha256: sha256sum);
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
