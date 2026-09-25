import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthWidget extends StatefulWidget {
  const AuthWidget({
    super.key,
    required this.onEmailSubmitted,
    required this.onOtpSubmitted,
  });
  final void Function(String email) onEmailSubmitted;
  final void Function(String otp) onOtpSubmitted;

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
        void showError(final Object error) {
          // showError runs after an async gap (signInWithOtp/verifyOTP):
          // the page may already have been popped, and its captured
          // pageBuilder context may be defunct by then.
          if (!context.mounted) return;
          // Hardcoded English for now; U6 wires the ARB keys.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sign-in failed. Please try again. $error'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(
              backgroundColor: Theme.of(context).primaryColor,
              iconTheme: Theme.of(context).primaryIconTheme,
              title: Text('Authenticate',
                  overflow: TextOverflow.fade,
                  style: Theme.of(context).primaryTextTheme.displaySmall),
            ),
            body: AuthWidget(onEmailSubmitted: (final String value) async {
              email = value;
              try {
                await supabaseInstance.auth.signInWithOtp(
                    email: value, emailRedirectTo: 'lore://auth/callback');
              } catch (e) {
                debugPrint('signInWithOtp failed: $e');
                showError(e);
              }
            }, onOtpSubmitted: (final String otp) async {
              try {
                final AuthResponse res = await supabaseInstance.auth.verifyOTP(
                  type: OtpType.magiclink,
                  token: otp,
                  email: email,
                );
                debugPrint('Signed in with OTP: $res');
              } catch (e) {
                debugPrint('verifyOTP failed: $e');
                showError(e);
                return;
              }
              if (context.mounted) {
                Navigator.of(context).pop();
              }
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
      color: Theme.of(context).colorScheme.surface,
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
                  onSubmitted: (final value) {
                    setState(() {
                      _email = value;
                    });
                    widget.onEmailSubmitted(value);
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
