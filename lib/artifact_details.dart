import 'package:Lore/artifact.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:file_icon/file_icon.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:like_button/like_button.dart';

class ArtifactDetailsWidget extends StatelessWidget {
  const ArtifactDetailsWidget(
      {super.key,
      this.artifact,
      required this.isFavorite,
      required this.onOpenFileTap,
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
    const Size size = Size(100, 100);
    Image? image;

    if ((artifact?.file?.existsSync() == true) && !kIsWeb) {
      image = Image.file(
        artifact!.file!,
        fit: BoxFit.cover,
        colorBlendMode: BlendMode.darken,
        color: Theme.of(context).primaryColor,
      );
    }

    return Container(
        decoration: image != null
            ? BoxDecoration(
                image: DecorationImage(
                    image: image.image, fit: BoxFit.cover, colorFilter: null),
                borderRadius: BorderRadius.zero,
              )
            : BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.zero,
              ),
        child: Container(
          decoration: image != null
              ? BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).primaryColor,
                      Colors.transparent,
                    ],
                  ),
                )
              : null,
          child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                    flex: 1,
                    fit: FlexFit.loose,
                    child: GestureDetector(
                        onTap: () {
                          onOpenFileTap();
                        },
                        child: Tooltip(
                            message: 'Browse for file',
                            child: Container(
                                alignment: Alignment.center,
                                constraints: BoxConstraints(
                                  minHeight: size.height,
                                  minWidth: size.width,
                                ),
                                child: Center(
                                  child: FileIcon(name, size: size.height),
                                ))))),
                Flexible(
                  flex: 3,
                  fit: FlexFit.tight,
                  child: GestureDetector(
                    onDoubleTap: () {
                      onFavoriteTap?.call(!isFavorite);
                    },
                    child: Container(
                        alignment: Alignment.centerLeft,
                        constraints: BoxConstraints(
                          minHeight: size.height,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style:
                                  Theme.of(context).primaryTextTheme.bodyLarge,
                            ),
                            AutoSizeText(
                              path,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  Theme.of(context).primaryTextTheme.bodySmall,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SelectionArea(
                                    child: AutoSizeText(
                                  md5sum,
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .bodyMedium,
                                )),
                                (artifact?.md5sum == null ||
                                        artifact!.md5sum.isEmpty)
                                    ? const SizedBox.shrink()
                                    : Row(children: [
                                        Tooltip(
                                          message: 'Add to favorites',
                                          child: // add to Favorites
                                              LikeButton(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          0, 0, 8.0, 0),
                                                  circleColor: CircleColor(
                                                      start: Theme.of(context)
                                                          .iconTheme
                                                          .color!,
                                                      end: Theme.of(context)
                                                          .primaryIconTheme
                                                          .color!),
                                                  bubblesColor: BubblesColor(
                                                    dotPrimaryColor:
                                                        Theme.of(context)
                                                            .primaryIconTheme
                                                            .color!,
                                                    dotSecondaryColor:
                                                        Theme.of(context)
                                                            .primaryIconTheme
                                                            .color!,
                                                  ),
                                                  animationDuration:
                                                      const Duration(
                                                          milliseconds: 666),
                                                  likeBuilder:
                                                      (final bool isLiked) {
                                                    return Icon(
                                                      (isLiked)
                                                          ? Icons.favorite
                                                          : Icons
                                                              .favorite_outline,
                                                      color: Theme.of(context)
                                                          .primaryIconTheme
                                                          .color,
                                                    );
                                                  },
                                                  isLiked: isFavorite,
                                                  onTap: (final bool isLiked) {
                                                    onFavoriteTap
                                                        ?.call(isLiked);
                                                    return Future.value(
                                                        !isLiked);
                                                  }),
                                        ),
                                      ]),
                              ],
                            ),
                          ],
                        )),
                  ),
                ),
              ]),
        ));
  }
}
