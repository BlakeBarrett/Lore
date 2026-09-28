import 'package:lore/artifact.dart';
import 'package:lore/md5_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show KeyDownEvent, LogicalKeyboardKey;
import 'package:url_launcher/url_launcher_string.dart';
import 'package:lore/l10n/app_localizations.dart';

/// Avatar diameter in the drawer header. 64 px, not the old 100:
/// DrawerHeader reserves 160 - 8 margin - 16*2 padding = 120 px, and avatar
/// + 16 px gaps + one e-mail line must fit — a 100 px avatar overflowed
/// even WITHOUT an e-mail (measured "BOTTOM OVERFLOWED BY 1.00 PIXELS" on
/// the live web build).
const double _kAvatarSize = 64.0;

/// Gravatar request size — larger than [_kAvatarSize] so the avatar stays
/// crisp on HiDPI displays.
const double _kAvatarRequestSize = 100.0;

/// Lore source/release page, linked from the drawer footer.
const String _kGitHubUrl = 'https://github.com/BlakeBarrett/Lore';

Future<void> _launchGitHub() async {
  if (await canLaunchUrlString(_kGitHubUrl)) {
    await launchUrlString(_kGitHubUrl);
  } else {
    // Surface the failure (review follow-up): a silent no-op made broken
    // link handlers undiagnosable. No user-facing dialog at this size.
    debugPrint('Could not launch $_kGitHubUrl');
  }
}

class DrawerWidget extends StatelessWidget {
  const DrawerWidget(
      {super.key,
      this.userEmail = '',
      this.authenticated = true,
      required this.favorites,
      required this.onLogout,
      required this.onShowAuthWidget,
      required this.onShowArtifact});

  final bool authenticated;
  final String? userEmail;
  final List<Artifact> favorites;
  final void Function() onLogout;
  final void Function() onShowAuthWidget;
  final void Function(Artifact artifact) onShowArtifact;

  List<Widget> getFavoriteWidgets(
      final BuildContext context, final List<Artifact> favorites) {
    final List<Widget> widgets = <Widget>[];
    for (final Artifact artifact in favorites) {
      widgets.add(ListTile(
        leading: Icon(Icons.favorite, color: Theme.of(context).primaryColor),
        title:
            Text(artifact.name, style: Theme.of(context).textTheme.bodyLarge),
        onTap: () => onShowArtifact(artifact),
      ));
    }
    return widgets;
  }

  Widget getAvatarFor(final String? email, final BuildContext context) {
    if (email == null || email.isEmpty) {
      return Icon(Icons.account_circle,
          size: _kAvatarSize, color: Theme.of(context).primaryIconTheme.color);
    }
    return ClipOval(
      child: Tooltip(
        message: AppLocalizations.of(context)?.avatarsByGravatar,
        child: Image.network(
          'https://www.gravatar.com/avatar/'
          '${md5SumFor(email)}?s=${_kAvatarRequestSize.toInt()}',
          fit: BoxFit.cover,
          width: _kAvatarSize,
          height: _kAvatarSize,
          // WCAG 1.1.1: the avatar stands in for the account identity.
          semanticLabel: AppLocalizations.of(context)?.avatarsByGravatar,
        ),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    return Drawer(
      backgroundColor: Theme.of(context).drawerTheme.backgroundColor,
      child: ListView(
        padding: EdgeInsets.zero,
        shrinkWrap: false,
        children: [
          // WCAG 2.1.1/4.1.2: when unauthenticated the header is the sign-in
          // control — make it focusable (focus node + keyboard activation)
          // and announce it as a labelled button.
          Semantics(
            button: !authenticated,
            label: (!authenticated) ? l10n?.signIn : null,
            child: Focus(
              canRequestFocus: !authenticated,
              onKeyEvent: (final node, final event) {
                if (!authenticated &&
                    event is KeyDownEvent &&
                    (event.logicalKey == LogicalKeyboardKey.enter ||
                        event.logicalKey == LogicalKeyboardKey.space)) {
                  onShowAuthWidget();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: DrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                  ),
                  child: InkWell(
                          // Authenticated: no action — pass a null callback so
                          // InkWell paints no splash and is not a11y-focusable
                          // (a no-op splash reads as a live control that lies).
                          onTap: authenticated ? null : onShowAuthWidget,
                          child: Center(
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                getAvatarFor(userEmail, context),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  // DrawerHeader is a fixed height; a long
                                  // e-mail wrapped onto extra lines and the
                                  // column overflowed the header's bottom
                                  // (measured: RenderFlex +80px at 360px wide
                                  // with a 71-char address). One ellipsized
                                  // line, with the full address as tooltip
                                  // (only when non-empty: Tooltip asserts on
                                  // an empty message).
                                  child: (userEmail ?? '').isEmpty
                                      ? const SizedBox.shrink()
                                      : Tooltip(
                                          message: userEmail!,
                                          child: Text(
                                            userEmail!,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .primaryTextTheme
                                                .titleSmall,
                                          ),
                                        ),
                                )
                              ])))),
            ),
          ),
          if (favorites.isEmpty)
            ListTile(
              enabled: false,
              title: Text(
                l10n?.noFavoritesYet ?? '',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: getFavoriteWidgets(context, favorites),
            ),
          ListTile(
            enabled: authenticated,
            title: Text(AppLocalizations.of(context)!.logout),
            onTap: () {
              Navigator.of(context).pop(context);
              onLogout();
            },
          ),
          AboutListTile(
            applicationName: l10n?.appTitle ?? 'Lore',
            aboutBoxChildren: [
              // WCAG 2.1.1: these launch affordances were raw
              // GestureDetectors — screen readers announced a button that
              // no keyboard could press. InkWell is focusable and
              // Enter-activatable on its own.
              InkWell(
                onTap: _launchGitHub,
                child: Column(
                  children: [
                    Image.asset('assets/Lore_app_icon.png',
                        width: _kAvatarSize,
                        height: _kAvatarSize,
                        semanticLabel: l10n?.appTitle),
                    Text(l10n?.copyright ?? ''),
                    Text(l10n?.openSourceNote ?? ''),
                  ],
                ),
              ),
              InkWell(
                onTap: _launchGitHub,
                // Underline + click cursor: the link is not signalled by
                // colour alone (WCAG 1.4.1).
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Text(_kGitHubUrl,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          decoration: TextDecoration.underline)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
