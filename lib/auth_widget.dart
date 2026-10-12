import 'package:lore/app_config.dart';
import 'package:lore/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class AuthWidget extends StatefulWidget {
  const AuthWidget({
    super.key,
    required this.onEmailSubmitted,
    required this.onOtpSubmitted,
  });

  /// Notified when the user submits an e-mail. Returns whether a sign-in link
  /// was actually sent: on `false` the widget UNLOCKS the e-mail field again so
  /// the user can correct the address and retry (a failed send means no link
  /// exists to click, so keeping the field locked would trap them).
  final Future<bool> Function(String email) onEmailSubmitted;

  /// Notified when the user submits a password (password-based auth stage) or
  /// an email-link URL that was captured from the deep link (link-flow stage).
  final void Function(String passwordOrLinkUrl) onOtpSubmitted;

  @override
  State<StatefulWidget> createState() => _AuthWidgetState();

  /// Presents the Firebase auth modal sheet. Supports two flows:
  /// * **Email/password** — standard email + password entry
  /// * **Email-link (passwordless)** — sends a magic link via
  ///   [AppConfig.sendSignInEmailLink] and signs in via
  ///   [AppConfig.signInWithEmailLink].
  static void showFirebaseAuthWidget(final BuildContext context) {
    Navigator.of(context).push(PageRouteBuilder(
      transitionsBuilder: (final BuildContext context,
          final Animation<double> animation,
          final Animation<double> secondaryAnimation,
          final Widget child) {
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
      pageBuilder: (final BuildContext context,
          final Animation<double> animation,
          final Animation<double> secondaryAnimation) {
        String email = '';

        void showError(final String message) {
          // showError runs after an async gap (sendSignInLinkToEmail /
          // createUserWithEmailAndPassword / signInWithEmailAndPassword):
          // the page may already have been popped, and its captured
          // pageBuilder context may be defunct by then. Callers debugPrint
          // the raw error before calling this.
          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(
              backgroundColor: Theme.of(context).primaryColor,
              iconTheme: Theme.of(context).primaryIconTheme,
              title: Text(
                  AppLocalizations.of(context)?.authenticate ?? 'Authenticate',
                  overflow: TextOverflow.fade,
                  style: Theme.of(context).primaryTextTheme.displaySmall),
            ),
            body: AuthWidget(onEmailSubmitted: (final String value) async {
              email = value;
              try {
                // Attempt passwordless sign-in via magic link.
                // The user taps the link to complete auth.
                await AppConfig.sendSignInEmailLink(email: value);
              } catch (e) {
                debugPrint('sendSignInEmailLink failed: $e');
                if (context.mounted) {
                  showError(AppLocalizations.of(context)?.errorAuth ??
                      'Authentication failed. Please try again.');
                }
                return false; // no link sent — unlock the e-mail field
              }
              return true;
            }, onOtpSubmitted: (final String link) async {
              // The user has tapped the magic link in their email client.
              // Firebase handles the deep-link completion automatically when
              // actionCodeSettings.handleCodeInApp is true and the URL matches.
              // If we're here via a programmatic capture, use email-link sign in:
              try {
                final userCred = await AppConfig.signInWithEmailLink(
                  email: email,
                  url: link,
                );
                debugPrint('Signed in via email link: ${userCred.user?.email}');
              } catch (e) {
                debugPrint('signInWithEmailLink failed: $e');
                if (context.mounted) {
                  showError(AppLocalizations.of(context)?.errorAuth ??
                      'Authentication failed. Please try again.');
                }
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
  /// The e-mail the sign-in link was (attempted to be) sent for. Non-empty while
  /// the link stage is active; cleared again when a send fails so the user can
  /// correct the address and retry.
  String _email = '';

  @override
  Widget build(final BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
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
                  l10n?.emailPrompt ??
                      'To which e-mail address should we send a sign-in link?',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                TextField(
                  style: Theme.of(context).textTheme.labelLarge,
                  textInputAction: TextInputAction.send,
                  readOnly: _email != '',
                  onSubmitted: (final String value) async {
                    // Placeholder == submitted value: the field locks while
                    // the send is in flight. If the send fails the callback
                    // resolves false and we roll back to editable, so a
                    // typo'd address can be corrected and retried.
                    setState(() {
                      _email = value;
                    });
                    final sent = await widget.onEmailSubmitted(value);
                    if (mounted && !sent) {
                      setState(() {
                        _email = '';
                      });
                    }
                  },
                  // WCAG 3.3.2: persistent labelText; the hint stays.
                  decoration: InputDecoration(
                    labelText: l10n?.emailAddress ?? 'e-mail address',
                    hintText: l10n?.emailAddress ?? 'e-mail address',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            if (_email.isNotEmpty) ...[
              const SizedBox(height: 20.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sign-in link sent. Check your email and tap the link.',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Text(
                    'Once you tap the link on another device or browser, this screen will close automatically.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
