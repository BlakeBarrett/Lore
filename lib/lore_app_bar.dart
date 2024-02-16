import 'dart:io';

import 'package:Lore/artifact.dart';
import 'package:anim_search_bar/anim_search_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:like_button/like_button.dart';
import 'package:regexpattern/regexpattern.dart';

class LoreAppBar extends StatefulWidget {
  LoreAppBar(
      {super.key,
      required this.artifact,
      required this.onOpenFileTap,
      required this.onSearch,
      required this.onFavoriteTap,
      required this.isFavorite});

  final Artifact? artifact;
  final Function() onOpenFileTap;
  final Function(String) onSearch;
  final Function() onFavoriteTap;
  bool isFavorite = false;

  @override
  State<LoreAppBar> createState() => _LoreAppBarState();
}

class _LoreAppBarState extends State<LoreAppBar> {
  late Widget? previewBackgroundImage;

  final TextEditingController _animatedSearchBarTextConroller =
      TextEditingController();

  Widget? getBackgroundImage(final BuildContext context) {
    if (previewBackgroundImage is SizedBox) return null;
    return ClipRRect(
      child: Stack(
        children: [
          SizedBox.expand(
            child: previewBackgroundImage!,
          ),
          SizedBox.expand(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Theme.of(context).colorScheme.inverseSurface,
                    Colors.transparent,
                    Colors.transparent,
                    Colors.transparent,
                    Theme.of(context).colorScheme.inverseSurface,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? getFlexibleSpace(
      final BuildContext context,
      final Artifact? artifact,
      final bool hasImagePreview,
      final bool isFavorite,
      final Function? onFavoriteTap) {
    final String name = artifact?.name ?? '';
    final String md5sum = artifact?.md5sum ?? '';
    return FlexibleSpaceBar(
      // stretchModes: const [StretchMode.blurBackground, StretchMode.zoomBackground],
      collapseMode: CollapseMode.parallax,
      expandedTitleScale: 1.0,
      titlePadding: const EdgeInsets.all(8),
      centerTitle: false,
      title: ListTile(
        iconColor: Theme.of(context).appBarTheme.toolbarTextStyle?.color,
        title: Text(
          maxLines: 2,
          overflow: TextOverflow.visible,
          name,
          style: Theme.of(context).primaryTextTheme.titleMedium,
        ),
        subtitle: SelectableText(
          md5sum,
          style: Theme.of(context).primaryTextTheme.titleSmall,
        ),
        trailing: (artifact != null)
            ? SizedBox(
                width: 41,
                height: 41,
                child: LikeButton(
                  // circleSize: 24,
                  // bubblesSize: 30,
                  padding: const EdgeInsets.fromLTRB(0, 0, 8.0, 0),
                  circleColor: CircleColor(
                    start: Theme.of(context).iconTheme.color!,
                    end: Theme.of(context).primaryIconTheme.color!,
                  ),
                  bubblesColor: BubblesColor(
                    dotPrimaryColor: Theme.of(context).primaryIconTheme.color!,
                    dotSecondaryColor:
                        Theme.of(context).primaryIconTheme.color!,
                  ),
                  animationDuration: const Duration(milliseconds: 666),
                  likeBuilder: (final bool isLiked) {
                    return Icon(
                      (isLiked) ? Icons.favorite : Icons.favorite_outline,
                      color: Theme.of(context).primaryIconTheme.color,
                    );
                  },
                  isLiked: widget.isFavorite,
                  onTap: (final bool isLiked) async {
                    onFavoriteTap?.call();
                    return !isLiked;
                  },
                ),
              )
            : null,
      ),
      background: (hasImagePreview) ? getBackgroundImage(context) : null,
    );
  }

  @override
  Widget build(final BuildContext context) {
    final double fullHeight = MediaQuery.of(context).size.height;
    final double fullWidth = MediaQuery.of(context).size.width;

    const double minHeight = 150.0;
    final double maxHeight = fullHeight * 0.7;
    final Size minSize = Size(fullWidth, minHeight);
    Size maxSize = Size(fullWidth, minHeight);

    bool hasImagePreview = false;

    final File? artifactFile = widget.artifact?.file;
    final bool isImage = artifactFile?.path.toLowerCase().isImage() ?? false;
    final bool fileExists = artifactFile?.existsSync() == true;

    if (!kIsWeb && isImage == true && fileExists) {
      try {
        hasImagePreview = true;
        maxSize = Size(fullWidth, maxHeight);
        previewBackgroundImage = Image.file(
          widget.artifact!.file!,
          fit: BoxFit.cover,
          height: fullHeight * 3,
          errorBuilder: (final _, final __, final ___) {
            maxSize = Size(fullWidth, minHeight);
            hasImagePreview = false;
            return const SizedBox.shrink();
          },
        );
      } catch (e) {
        maxSize = Size(fullWidth, minHeight);
        hasImagePreview = true;
        previewBackgroundImage = null;
      }
    } else {
      maxSize = Size(fullWidth, minHeight);
      previewBackgroundImage = null;
    }

    return SliverAppBar(
      backgroundColor: Theme.of(context).primaryColor,
      iconTheme: Theme.of(context).primaryIconTheme,
      titleTextStyle: Theme.of(context).primaryTextTheme.titleLarge,
      shape: Theme.of(context).appBarTheme.shape,
      pinned: true,
      snap: true,
      floating: true,
      expandedHeight: maxSize.height,
      collapsedHeight: minSize.height,
      clipBehavior: Clip.antiAlias,
      title: Text(
        'LORE',
        overflow: TextOverflow.fade,
        style: Theme.of(context).primaryTextTheme.displayLarge,
      ),
      actions: [
        Tooltip(
          message: AppLocalizations.of(context)?.browseForFile,
          child: IconButton(
            onPressed: widget.onOpenFileTap,
            icon: const Icon(Icons.folder_open),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Tooltip(
            message: AppLocalizations.of(context)?.searchByMd5OrURL,
            child: AnimSearchBar(
              width: maxSize.width - 100,
              color: Theme.of(context).colorScheme.surface,
              textFieldIconColor: Theme.of(context).primaryColor,
              textFieldColor: Theme.of(context).colorScheme.surface,
              searchIconColor: Theme.of(context).primaryColor,
              textController: _animatedSearchBarTextConroller,
              boxShadow: false,
              helpText: AppLocalizations.of(context)?.searchByMd5OrURL ?? '',
              onSubmitted: widget.onSearch,
              style: Theme.of(context).textTheme.titleMedium,
              onSuffixTap: () =>
                  setState(() => _animatedSearchBarTextConroller.clear()),
            ),
          ),
        ),
      ],
      flexibleSpace: getFlexibleSpace(context, widget.artifact, hasImagePreview,
          widget.isFavorite, widget.onFavoriteTap),
    );
  }
}
