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

/// Horizontal budget the app-bar actions row must keep for itself: drawer
/// button (~56) + browse button (~48) + the "Lore" title + paddings. The
/// search bar may claim everything left over, down to a legible floor.
const double _kActionsRowReservedWidth = 240.0;

/// Floor for the search bar: below this the bar is unusable, and letting it
/// shrink further only defers the overflow.
const double _kSearchBarMinWidth = 140.0;

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

  /// True while the favorite toggle has keyboard focus — drives the focus
  /// ring (WCAG 2.4.7) because Focus itself paints nothing.
  bool _favoriteFocused = false;

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

  /// Heart toggle with an accessible name, tooltip, >=44px target, keyboard
  /// activation, AND a visible focus ring (WCAG 2.1.1 / 2.4.7 / 2.5.5 /
  /// 4.1.2). The LikeButton keeps its animation; the Focus wrapper carries
  /// the keyboard contract and drives the ring, and the Semantics wrapper
  /// remains the single name source (the Tooltip is excluded from
  /// semantics so the label is never merged twice onto one node).
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
        // Hover hint only: Tooltip would otherwise inject a second copy of
        // the same string as semantics, double-reading the merged node.
        excludeFromSemantics: true,
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
          // WCAG 2.4.7: Focus paints nothing, so mirror focus into state
          // and draw a 2px ring in the foreground icon colour.
          onFocusChange: (final hasFocus) =>
              setState(() => _favoriteFocused = hasFocus),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: _favoriteFocused
                  ? Border.all(color: iconColor ?? Colors.white, width: 2)
                  : null,
            ),
            child: Semantics(
            label: label,
            button: true,
            container: true,
            enabled: true,
            child: LikeButton(
              key: ValueKey<String>(
                  // Controlled heart: remount on artifact change or when
                  // the MODEL's favorite state flips, so LikeButton's
                  // internal animation state can never drift from
                  // widget.isFavorite (e.g. after a failed save the icon
                  // reverts with the SnackBar instead of staying liked).
                  '${widget.artifact?.md5sum ?? ''}|${widget.isFavorite}'),
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
      ),
    );
  }

  /// Search-bar width that leaves the rest of the actions row its budget.
  double _searchBarWidth(final double fullWidth) {
    final double available = fullWidth - _kActionsRowReservedWidth;
    return available < _kSearchBarMinWidth
        ? _kSearchBarMinWidth
        : available;
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
        // Ellipsize (not `visible`): with maxLines:2 + visible, a 3rd line
        // PAINTED OVER the md5 subtitle (measured at 360px width). Tooltip
        // carries the full name for pointer users.
        title: Tooltip(
          // No tooltip affordance when there is no name to reveal.
          message: name.isEmpty ? ' ' : name,
          excludeFromSemantics: true, // the Text node already names itself
          child: Text(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            name,
            style: Theme.of(context).primaryTextTheme.titleMedium,
          ),
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
        // Preview is NOT available on failure — the old `true` here made
        // getBackgroundImage paint the fade gradient over a null image.
        debugPrint('artifact preview failed: $e');
        maxSize = Size(fullWidth, _kCollapsedAppBarHeight);
        hasImagePreview = false;
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
        // Material app bars use titleLarge; displayLarge (~57px) ate ~140px
        // of the actions row, crowding the search bar into overflow on
        // narrow windows.
        style: Theme.of(context).primaryTextTheme.titleLarge,
      ),
      actions: [
        // IconButton.tooltip names the button (WCAG 4.1.2) AND shows the
        // hover hint — the previous outer Tooltip duplicated both (two
        // overlapping tooltips on hover, double-read label on the node).
        IconButton(
          onPressed: widget.onOpenFileTap,
          icon: const Icon(Icons.folder_open),
          tooltip: l10n?.browseForFile,
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          // The Tooltip names the composite control (WCAG 4.1.2) and the
          // AnimSearchBar's internal labelText carries the same string as
          // the field's own label — the previous outer Semantics(label:)
          // wrapper merged a THIRD copy onto the node (screen readers read
          // "Search by MD5 or URL" repeatedly).
          child: Tooltip(
            message: l10n?.searchByMd5OrURL,
            child: AnimSearchBar(
              // The actions Row lays children out unbounded in the main
              // axis, so a claimed width of screenWidth-100 overflowed on
              // narrow screens once the drawer button, browse button,
              // app title and paddings took their share (~220px total).
              width: _searchBarWidth(fullWidth),
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
      ],
      flexibleSpace:
          getFlexibleSpace(context, widget.artifact, hasImagePreview),
    );
  }
}
