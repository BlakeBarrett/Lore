import 'dart:io';

import 'package:lore/artifact.dart';
import 'package:anim_search_bar/anim_search_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show KeyDownEvent, LogicalKeyboardKey;
import 'package:lore/l10n/app_localizations.dart';
import 'package:like_button/like_button.dart';
import 'package:regexpattern/regexpattern.dart';

/// Collapsed app-bar height.
const double _kCollapsedAppBarHeight = 150.0;

/// Share of the viewport height the expanded image preview may occupy.
const double _kExpandedAppBarHeightFactor = 0.7;

/// Oversampling factor for the parallax background image height.
const double _kPreviewParallaxHeightFactor = 3.0;

/// Touch-target size for the favorite toggle. WCAG 2.5.5 asks for >= 44x44
/// logical px (this supersedes the old 41x41).
const double _kFavoriteButtonSize = 44.0;

/// Horizontal slack kept to the right of the search bar so the bar never
/// collides with the trailing edge while expanded.
const double _kSearchBarTrailingInset = 100.0;

class LoreAppBar extends StatefulWidget {
  const LoreAppBar(
      {super.key,
      required this.artifact,
      required this.onOpenFileTap,
      required this.onSearch,
      required this.onFavoriteTap,
      required this.isFavorite});

  final Artifact? artifact;
  final void Function() onOpenFileTap;
  final void Function(String query) onSearch;
  final void Function() onFavoriteTap;
  final bool isFavorite;

  @override
  State<LoreAppBar> createState() => _LoreAppBarState();
}

class _LoreAppBarState extends State<LoreAppBar> {
  late Widget? previewBackgroundImage;

  final TextEditingController _animatedSearchBarController =
      TextEditingController();

  @override
  void dispose() {
    _animatedSearchBarController.dispose();
    super.dispose();
  }

  Widget? getBackgroundImage(final BuildContext context) {
    if (previewBackgroundImage is SizedBox || previewBackgroundImage == null) {
      return null;
    }
    final Color fadeColor = Theme.of(context).colorScheme.inverseSurface;

    return ClipRRect(
      child: Stack(
        children: [
          SizedBox.expand(
            child: previewBackgroundImage,
          ),
          SizedBox.expand(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    fadeColor,
                    Colors.transparent,
                    Colors.transparent,
                    Colors.transparent,
                    fadeColor,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Heart toggle with an accessible name, tooltip, >=44px target, and
  /// keyboard activation (WCAG 2.1.1 / 2.5.5 / 4.1.2). The LikeButton keeps
  /// its animation; the wrapping Semantics/Focus carry the a11y contract,
  /// so Enter/Space toggle exactly like a pointer tap.
  Widget _buildFavoriteToggle(final BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    // State-aware name (WCAG 4.1.2): activation toggles, so the label must
    // describe the action that WILL happen — "Remove..." when favorited.
    final String label = widget.isFavorite
        ? l10n?.removeFromFavorites ?? 'Remove from favorites'
        : l10n?.addToFavorites ?? 'Add to favorites';
    final Color? iconColor = Theme.of(context).primaryIconTheme.color;

    return SizedBox(
      width: _kFavoriteButtonSize,
      height: _kFavoriteButtonSize,
      child: Tooltip(
        message: label,
        child: Semantics(
          label: label,
          button: true,
          container: true,
          enabled: true,
          child: Focus(
            // Keyboard: activate the same callback the pointer tap runs.
            onKeyEvent: (final node, final event) {
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.space)) {
                widget.onFavoriteTap();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: LikeButton(
              padding: const EdgeInsets.fromLTRB(0, 0, 8.0, 0),
              circleColor: CircleColor(
                start: Theme.of(context).iconTheme.color ??
                    iconColor ??
                    Colors.white,
                end: iconColor ?? Colors.white,
              ),
              bubblesColor: BubblesColor(
                dotPrimaryColor: iconColor ?? Colors.white,
                dotSecondaryColor: iconColor ?? Colors.white,
              ),
              animationDuration: const Duration(milliseconds: 666),
              likeBuilder: (final bool isLiked) {
                return Icon(
                  (isLiked) ? Icons.favorite : Icons.favorite_outline,
                  color: iconColor,
                  // No semanticLabel here: the enclosing Semantics wrapper
                  // names the merged node (a second label would merge into
                  // "Add to favorites\nAdd to favorites" and double-read).
                );
              },
              isLiked: widget.isFavorite,
              onTap: (final bool isLiked) async {
                widget.onFavoriteTap();
                return !isLiked;
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget? getFlexibleSpace(final BuildContext context, final Artifact? artifact,
      final bool hasImagePreview) {
    final String name = artifact?.name ?? '';
    final String md5sum = artifact?.md5sum ?? '';
    return FlexibleSpaceBar(
      stretchModes: const [
        StretchMode.blurBackground,
        StretchMode.zoomBackground
      ],
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
        trailing: (artifact != null) ? _buildFavoriteToggle(context) : null,
      ),
      background: (hasImagePreview) ? getBackgroundImage(context) : null,
    );
  }

  @override
  Widget build(final BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final double fullHeight = MediaQuery.of(context).size.height;
    final double fullWidth = MediaQuery.of(context).size.width;

    final double maxHeight = fullHeight * _kExpandedAppBarHeightFactor;
    Size maxSize = Size(fullWidth, _kCollapsedAppBarHeight);

    bool hasImagePreview = false;

    final File? artifactFile = widget.artifact?.file;
    final bool isImage = artifactFile?.path.toLowerCase().isImage() ?? false;

    if (kIsWeb) {
      maxSize = Size(fullWidth, _kCollapsedAppBarHeight);
      previewBackgroundImage = null;
    } else if (isImage && artifactFile != null && artifactFile.existsSync()) {
      try {
        hasImagePreview = true;
        maxSize = Size(fullWidth, maxHeight);
        previewBackgroundImage = Image.file(
          artifactFile,
          fit: BoxFit.cover,
          height: fullHeight * _kPreviewParallaxHeightFactor,
          // WCAG 1.1.1/4.1.2: the decorative preview needs a name tied to
          // the artifact it illustrates.
          semanticLabel: l10n?.imagePreviewLabel(widget.artifact?.name ?? '') ??
              '${widget.artifact?.name ?? ''} preview',
          errorBuilder: (final _, final __, final ___) {
            maxSize = Size(fullWidth, _kCollapsedAppBarHeight);
            hasImagePreview = false;
            return const SizedBox.shrink();
          },
        );
      } catch (e) {
        maxSize = Size(fullWidth, _kCollapsedAppBarHeight);
        hasImagePreview = true;
        previewBackgroundImage = null;
      }
    } else {
      maxSize = Size(fullWidth, _kCollapsedAppBarHeight);
      previewBackgroundImage = null;
    }

    return SliverAppBar(
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      backgroundColor: Theme.of(context).primaryColor,
      iconTheme: Theme.of(context).primaryIconTheme,
      titleTextStyle: Theme.of(context).primaryTextTheme.titleLarge,
      shape: Theme.of(context).appBarTheme.shape,
      pinned: true,
      snap: true,
      floating: true,
      expandedHeight: maxSize.height,
      collapsedHeight: Size(fullWidth, _kCollapsedAppBarHeight).height,
      clipBehavior: Clip.antiAlias,
      systemOverlayStyle: Theme.of(context).appBarTheme.systemOverlayStyle,
      title: Text(
        l10n?.appTitle ?? 'Lore',
        overflow: TextOverflow.fade,
        style: Theme.of(context).primaryTextTheme.displayLarge,
      ),
      actions: [
        Tooltip(
          message: l10n?.browseForFile,
          child: IconButton(
            onPressed: widget.onOpenFileTap,
            icon: const Icon(Icons.folder_open),
            tooltip: l10n?.browseForFile,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          // WCAG 4.1.2: AnimSearchBar maps helpText to its internal
          // labelText; the Semantics wrapper names the composite control
          // independently of the placeholder.
          child: Semantics(
            container: true,
            textField: true,
            label: l10n?.searchByMd5OrURL,
            child: Tooltip(
              message: l10n?.searchByMd5OrURL,
              child: AnimSearchBar(
                width: maxSize.width - _kSearchBarTrailingInset,
                color: Theme.of(context).colorScheme.surface,
                textFieldIconColor: Theme.of(context).primaryColor,
                textFieldColor: Theme.of(context).colorScheme.surface,
                searchIconColor: Theme.of(context).primaryColor,
                textController: _animatedSearchBarController,
                boxShadow: false,
                helpText: l10n?.searchByMd5OrURL ?? '',
                onSubmitted: widget.onSearch,
                style: Theme.of(context).textTheme.titleMedium,
                onSuffixTap: () =>
                    setState(() => _animatedSearchBarController.clear()),
              ),
            ),
          ),
        ),
      ],
      flexibleSpace:
          getFlexibleSpace(context, widget.artifact, hasImagePreview),
    );
  }
}
