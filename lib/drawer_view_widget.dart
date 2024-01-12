import 'package:Lore/main.dart';
import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

class DrawerViewWidget extends StatelessWidget {
  const DrawerViewWidget({super.key});

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
                    if (supabaseInstance.auth.currentSession?.accessToken ==
                        null)
                      {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => Scaffold(
                                appBar:
                                    AppBar(title: const Text('Authenticate')),
                                body: Material(
                                    child: SupaMagicAuth(
                                  onSuccess: (Session response) {
                                    debugPrint('$response');
                                    Navigator.of(context).pop();
                                  },
                                  onError: (error) {
                                    debugPrint('$error');
                                    Navigator.of(context).pop();
                                  },
                                )))))
                      }
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
      )
    ]));
  }
}
