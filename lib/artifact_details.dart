import 'package:Lore/artifact.dart';
import 'package:file_icon/file_icon.dart';
import 'package:flutter/material.dart';

class ArtifactDetailsWidget extends StatelessWidget {
  const ArtifactDetailsWidget(
      {super.key, this.artifact, required this.onOpenFileTap});

  final Function onOpenFileTap;
  final Artifact? artifact;

  @override
  Widget build(final BuildContext context) {
    final String name = artifact?.name ?? 'NAME';
    final String path = artifact?.path ?? 'PATH';
    final String md5sum = artifact?.md5sum ?? 'MD5';
    Image? image;

    if (artifact?.file != null) {
      image = Image.file(
        artifact!.file!,
        fit: BoxFit.cover,
        colorBlendMode: BlendMode.darken,
        color: Theme.of(context).primaryColor,
      );
    }
    final bool hasImage = (image != null);

    return Container(
        color: Theme.of(context).primaryColor,
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(0.0),
        margin: const EdgeInsets.all(0.0),
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.all(0.0),
          alignment: Alignment.center,
          decoration: (hasImage)
              ? BoxDecoration(
                  image: DecorationImage(
                    image: image.image,
                    fit: BoxFit.cover,
                  ),
                )
              : null,
          child: Row(mainAxisSize: MainAxisSize.max, children: [
            GestureDetector(
                onTap: () {
                  onOpenFileTap();
                },
                child: Tooltip(
                    message: 'Browse for file',
                    child: SizedBox(
                      width: 180,
                      height: 180,
                      child: FileIcon(name, size: 180),
                    ))),
            Flexible(
              flex: 2,
              fit: FlexFit.loose,
              child: Container(
                margin: const EdgeInsets.all(0.0),
                padding: const EdgeInsets.all(0.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      // Theme.of(context).primaryColor.withOpacity(0.0),
                      Theme.of(context).primaryColor.withOpacity(0.8),
                      Theme.of(context).primaryColor.withOpacity(0.8),
                      Theme.of(context).primaryColor.withOpacity(0.8),
                      Theme.of(context).primaryColor.withOpacity(0.0),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
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
                        child: SelectableText(
                          md5sum,
                          style: Theme.of(context).primaryTextTheme.bodyMedium,
                        )),
                  ],
                ),
              ),
            ),
          ]),
        ));
  }
}
