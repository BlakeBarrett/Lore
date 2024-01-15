import 'package:Lore/auth_widget.dart';
import 'package:Lore/main.dart';
import 'package:flutter/material.dart';

class DrawerViewWidget extends StatelessWidget {
  const DrawerViewWidget({super.key, this.authenticated = true});

  final bool authenticated;

  @override
  Widget build(final BuildContext context) {
    return Drawer(
        child: ListView(padding: EdgeInsets.zero, children: [
      DrawerHeader(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
          ),
          child: InkWell(
              onTap: () => {
                    if (!authenticated)
                      {AuthWidget.showAuthWidget(context)}
                  },
              child: const Center(
                child: Text('ಠ_ಠ'),
              ))),
      ListTile(
        title: const Text("Logout"),
        onTap: () {
          supabaseInstance.auth.signOut();
          Navigator.pop(context);
        },
      ),
      const AboutListTile(
        applicationName: 'Lore',
      ),
    ]));
  }
}