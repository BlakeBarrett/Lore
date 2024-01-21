import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher_string.dart';

class DrawerWidget extends StatelessWidget {
  const DrawerWidget(
      {super.key,
      this.userEmail = '',
      this.authenticated = true,
      required this.onLogout,
      required this.onShowAuthWidget});

  final bool authenticated;
  final String? userEmail;
  final Function() onLogout;
  final Function() onShowAuthWidget;

  @override
  Widget build(final BuildContext context) {
    return Drawer(
        child: ListView(padding: EdgeInsets.zero, shrinkWrap: true, children: [
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
                    SvgPicture.asset(
                      'assets/account-outline.svg',
                      // ignore: deprecated_member_use
                      color: Theme.of(context)
                              .primaryTextTheme
                              .titleSmall
                              ?.color ??
                          Colors.white,
                    ),
                    Text(userEmail ?? '',
                        style: Theme.of(context).primaryTextTheme.titleSmall),
                  ])))),
      ListTile(
        enabled: authenticated,
        title: const Text("Logout"),
        onTap: () {
          Navigator.of(context).pop(context);
          onLogout();
        },
      ),
      AboutListTile(
        applicationName: 'Lore',
        aboutBoxChildren: [
          const Text('Lore Ⓒ 2024 Blake Barrett.'),
          const Text('Lore is Open Source, available on GitHub.'),
          GestureDetector(
            onTap: () async {
              if (await canLaunchUrlString(
                  'https://github.com/BlakeBarrett/Lore')) {
                await launchUrlString('https://github.com/BlakeBarrett/Lore');
              }
            },
            child: const Text('https://github.com/BlakeBarrett/Lore'),
          ),
        ],
      ),
    ]));
  }
}
