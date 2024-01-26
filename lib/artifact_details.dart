import 'package:Lore/artifact.dart';
import 'package:file_icon/file_icon.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/services.dart';

class ArtifactDetailsWidget extends StatelessWidget {
  const ArtifactDetailsWidget(
      {super.key,
      this.artifact,
      required this.onOpenFileTap,
      this.isFavorite = false,
      this.onFavoriteTap});

  final Function onOpenFileTap;
  final Function(bool)? onFavoriteTap;
  final Artifact? artifact;
  final bool isFavorite;

  @override
  Widget build(final BuildContext context) {
    final String name = artifact?.name ?? 'NAME';
    final String path = artifact?.path ?? 'PATH';
    final String md5sum = artifact?.md5sum ?? 'MD5';
    const Size size = Size(180, 180);
    Image? image;

    if (artifact?.file != null) {
      image = Image.file(
        artifact!.file!,
        fit: BoxFit.cover,
        colorBlendMode: BlendMode.darken,
        color: Theme.of(context).primaryColor,
      );
    }

    return Container(
      color: Theme.of(context).primaryColor,
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(8.0),
      alignment: Alignment.center,
      child: Row(mainAxisSize: MainAxisSize.max, children: [
        GestureDetector(
            onTap: () {
              onOpenFileTap();
            },
            child: Tooltip(
                message: 'Browse for file',
                child: SizedBox(
                    width: size.width,
                    height: size.height,
                    child: Stack(
                      alignment: const Alignment(0, 0),
                      fit: StackFit.expand,
                      children: [
                        FileIcon(name, size: size.height),
                        (image != null)
                            ? Image(
                                image: image.image,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox.shrink(),
                              )
                            : const SizedBox.shrink(),
                      ],
                    )))),
        Flexible(
          flex: 2,
          fit: FlexFit.tight,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
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
                  child: AutoSizeText(
                    path,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).primaryTextTheme.bodyMedium,
                  )),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    SelectableText(
                      md5sum,
                      style: Theme.of(context).primaryTextTheme.bodyMedium,
                    ),
                    const Spacer(flex: 2),
                    (artifact?.md5sum == null || artifact!.md5sum.isEmpty)
                        ? const SizedBox.shrink()
                        : Tooltip(
                            message: 'Copy to clipboard',
                            child: IconButton(
                              color: Theme.of(context).primaryIconTheme.color,
                              icon: const Icon(Icons.copy),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: md5sum));
                              },
                            ),
                          ),
                    // add to Favorites
                    // Tooltip(
                    //     message: 'Add to favorites',
                    //     child: IconButton(
                    //       color: Theme.of(context).primaryIconTheme.color,
                    //       icon: Icon((isFavorite)
                    //       ? Icons.favorite
                    //       : Icons.favorite_outline),
                    //       onPressed: () {
                    //         onFavoriteTap?.call(true);
                    //       },
                    //     ),
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}
