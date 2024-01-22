import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

class AuthWidget extends StatefulWidget {
  final Function(String email) onEmailSubmitted;
  final Function(String otp) onOtpSubmitted;

  const AuthWidget({
    super.key,
    required this.onEmailSubmitted,
    required this.onOtpSubmitted,
  });

  @override
  State<StatefulWidget> createState() => _AuthWidgetState();

  static void showAuthWidget(
    final BuildContext context,
    final SupabaseClient supabaseInstance,
  ) {
    Navigator.of(context).push(PageRouteBuilder(
      transitionsBuilder: (final context, final animation,
          final secondaryAnimation, final child) {
        const begin = Offset(-1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      pageBuilder: (final context, final animation, final secondaryAnimation) {
        String email = '';
        return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.background,
            appBar: AppBar(
              backgroundColor: Theme.of(context).primaryColor,
              iconTheme: Theme.of(context).primaryIconTheme,
              title: Text('Authenticate',
                  overflow: TextOverflow.fade,
                  style: Theme.of(context).primaryTextTheme.displaySmall),
            ),
            body: AuthWidget(onEmailSubmitted: (final String value) async {
              email = value;
              await supabaseInstance.auth.signInWithOtp(
                  email: value, emailRedirectTo: 'lore://auth/callback');
            }, onOtpSubmitted: (final String otp) async {
              final AuthResponse res = await supabaseInstance.auth.verifyOTP(
                type: OtpType.magiclink,
                token: otp,
                email: email,
              );
              debugPrint('Signed in with OTP: $res');
              // ignore: use_build_context_synchronously
              Navigator.of(context).pop();
            }));
      },
    ));
  }
}

class _AuthWidgetState extends State<AuthWidget> {
  String _email = '';

  @override
  Widget build(final BuildContext context) {
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
                Text(
                  'To which e-mail address should we send a one time password?',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                TextField(
                  style: Theme.of(context).textTheme.labelLarge,
                  textInputAction: TextInputAction.send,
                  readOnly: _email != '',
                  onSubmitted: (value) async {
                    setState(() {
                      _email = value;
                    });
                    await widget.onEmailSubmitted(value);
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
                Text(
                  'Now enter the one-time-password we sent.',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                TextField(
                  style: Theme.of(context).textTheme.labelLarge,
                  textInputAction: TextInputAction.send,
                  enabled: _email != '',
                  readOnly: _email == '',
                  onSubmitted: widget.onOtpSubmitted,
                  decoration: const InputDecoration(
                    hintText: 'One Time Password...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
