import 'package:Lore/artifact.dart';
import 'package:file_icon/file_icon.dart';
import 'package:flutter/material.dart';

class ArtifactDetailsWidget extends StatelessWidget {
  const ArtifactDetailsWidget({super.key, this.artifact});

  final Artifact? artifact;

  @override
  Widget build(BuildContext context) {
    final String name = artifact?.name ?? 'NAME';
    final String path = artifact?.path ?? 'PATH';
    final String md5sum = artifact?.md5sum ?? 'MD5';

    return Container(
      color: Theme.of(context).primaryColor,
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(0.0),
      alignment: Alignment.center,
      child: Row(children: [
        FileIcon(name, size: 180),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    name,
                    style: Theme.of(context).primaryTextTheme.bodyMedium,
                  )),
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    path,
                    style: Theme.of(context).primaryTextTheme.bodyMedium,
                  )),
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    md5sum,
                    style: Theme.of(context).primaryTextTheme.bodyMedium,
                  )),
            ],
          ),
        ),
      ]),
    );
  }
}
