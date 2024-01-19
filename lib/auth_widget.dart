import 'package:Lore/main.dart';
import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

class AuthWidget extends StatefulWidget {
  const AuthWidget({super.key});

  @override
  State<StatefulWidget> createState() => _AuthWidgetState();

  static void showAuthWidget(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Authenticate')),
              body: const AuthWidget(),
            )));
  }
}

class _AuthWidgetState extends State<AuthWidget> {
  @override
  Widget build(BuildContext context) {
    String email = '';
    pop() => Navigator.of(context).pop();
    return Material(
      color: Theme.of(context).colorScheme.background,
        child: Container(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'To which e-mail address should we send a one time password?'),
                TextField(
                  textInputAction: TextInputAction.send,
                  readOnly: email != '',
                  onSubmitted: (value) async {
                    email = value;
                    await supabaseInstance.auth.signInWithOtp(
                        email: value, emailRedirectTo: 'lore://auth/callback');
                    setState(() {});
                  },
                  decoration: const InputDecoration(
                    hintText: 'e-mail address',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Now enter the one-time-password we sent.'),
                TextField(
                  textInputAction: TextInputAction.send,
                  enabled: email != '',
                  readOnly: email != '',
                  onSubmitted: (value) async {
                    final AuthResponse res =
                        await supabaseInstance.auth.verifyOTP(
                      type: OtpType.magiclink,
                      token: value,
                      email: email,
                    );
                    debugPrint('$res');
                    setState(() {});
                    pop();
                  },
                  decoration: const InputDecoration(
                    hintText: 'One Time Password...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40.0),
          ],
        ),
      ),
    );
  }
}

// SupaMagicAuth(
//   onSuccess: (Session response) {
//     debugPrint('$response');
//     Navigator.of(context).pop();
//   },
//   onError: (error) {
//     debugPrint('$error');
//     Navigator.of(context).pop();
//   },
// )
