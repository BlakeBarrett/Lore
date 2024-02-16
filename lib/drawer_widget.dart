import 'package:Lore/artifact.dart';
import 'package:Lore/md5_utils.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
  final Function() onLogout;
  final Function() onShowAuthWidget;
  final Function(Artifact artifact) onShowArtifact;

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
          size: 100, color: Theme.of(context).primaryIconTheme.color);
    }
    return ClipOval(
      child: Tooltip(
        message: 'Avarars by Gravatar',
        child: Image.network(
          'https://www.gravatar.com/avatar/${md5SumFor(email)}?s=100',
          fit: BoxFit.cover,
          width: 100,
          height: 100,
        ),
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).drawerTheme.backgroundColor,
      child: ListView(
        padding: EdgeInsets.zero,
        shrinkWrap: false,
        children: [
          DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: InkWell(
                  onTap: () => authenticated ? null : onShowAuthWidget(),
                  child: Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        getAvatarFor(userEmail, context),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(userEmail ?? '',
                              style: Theme.of(context)
                                  .primaryTextTheme
                                  .titleSmall),
                        )
                      ])))),
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
            applicationName: 'Lore',
            aboutBoxChildren: [
              GestureDetector(
                onTap: () async {
                  if (await canLaunchUrlString(
                      'https://github.com/BlakeBarrett/Lore')) {
                    await launchUrlString(
                        'https://github.com/BlakeBarrett/Lore');
                  }
                },
                child: Image.asset('assets/Lore_app_icon.png',
                    width: 100, height: 100),
              ),
              const Text('Lore Ⓒ 2024 Blake Barrett.'),
              const Text('Lore is Open Source, available on GitHub.'),
              GestureDetector(
                onTap: () async {
                  if (await canLaunchUrlString(
                      'https://github.com/BlakeBarrett/Lore')) {
                    await launchUrlString(
                        'https://github.com/BlakeBarrett/Lore');
                  }
                },
                child: const Text('https://github.com/BlakeBarrett/Lore'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
