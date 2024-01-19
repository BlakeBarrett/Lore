import 'package:Lore/artifact.dart';
import 'package:file_icon/file_icon.dart';
import 'package:flutter/material.dart';

class ArtifactDetailsWidget extends StatelessWidget {
  const ArtifactDetailsWidget({super.key, this.artifact});

  final Artifact? artifact;

  @override
  Widget build(BuildContext context) {
    final String name = artifact?.name ?? '';
    final String path = artifact?.path ?? '';
    final String md5sum = artifact?.md5sum ?? '';

    return Container(
      color: Theme.of(context).primaryColor,
      padding: const EdgeInsets.all(0.0),
      alignment: Alignment.center,
      child: Row(children: [
        FileIcon(name, size: 180),
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              "Name: $name",
              style: Theme.of(context).primaryTextTheme.bodyMedium,
            ),
            Text(
              'Path: $path',
              style: Theme.of(context).primaryTextTheme.bodyMedium,
            ),
            Text(
              'md5: $md5sum',
              style: Theme.of(context).primaryTextTheme.bodyMedium,
            )
          ],
        ),
      ]),
    );
  }
}
