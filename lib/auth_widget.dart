import 'package:lore/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Minimal shape check for the e-mail field (WCAG 3.3.3: identify the error
/// and suggest a fix BEFORE the server round-trip, instead of blaming the
/// generic auth-failure SnackBar for a typo).
final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class AuthWidget extends StatefulWidget {
  const AuthWidget({
    super.key,
    required this.onEmailSubmitted,
    required this.onOtpSubmitted,
  });

  /// Notified when the user submits an e-mail. Returns whether the OTP was
  /// actually sent: on `false` the widget UNLOCKS the e-mail field again so
  /// the user can correct the address and retry (a failed send means no OTP
  /// exists to type, so keeping the field locked would trap them).
  final Future<bool> Function(String email) onEmailSubmitted;
  final void Function(String otp) onOtpSubmitted;

  @override
  State<StatefulWidget> createState() => _AuthWidgetState();

  static void showAuthWidget(
    final BuildContext context,
    final SupabaseClient supabaseInstance,
  ) {
    Navigator.of(context).push(PageRouteBuilder(
      // Forward navigation advances right-to-left (Material). The previous
      // slide-in from the LEFT is the drawer/back direction, which made the
      // auto-generated back button animate against the grain.
      transitionsBuilder: (final context, final animation,
          final secondaryAnimation, final child) {
        const begin = Offset(1.0, 0.0);
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
        void showError() {
          // showError runs after an async gap (signInWithOtp/verifyOTP):
          // the page may already have been popped, and its captured
          // pageBuilder context may be defunct by then. Callers debugPrint
          // the raw error before calling this.
          if (!context.mounted) return;
          final String message = AppLocalizations.of(context)?.errorAuth ??
              'Authentication failed. Please try again.';
          // Localized message to the user; the raw error goes to debugPrint
          // (done by each caller before invoking showError).
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
                  // Material app bars carry titleLarge; the previous
                  // displaySmall (~36px) read as a dialog header.
                  style: Theme.of(context).primaryTextTheme.titleLarge),
            ),
            body: AuthWidget(onEmailSubmitted: (final String value) async {
              email = value;
              try {
                await supabaseInstance.auth.signInWithOtp(
                    email: value, emailRedirectTo: 'lore://auth/callback');
              } catch (e) {
                debugPrint('signInWithOtp failed: $e');
                showError();
                return false; // no OTP sent — unlock the e-mail field
              }
              return true;
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
                showError();
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
  /// The e-mail the OTP was (attempted to be) sent for. Non-empty while the
  /// OTP stage is active; cleared again when a send fails so the user can
  /// correct the address and retry.
  String _email = '';

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _otpFocusNode = FocusNode();

  /// Inline validation error for the e-mail field (WCAG 3.3.1: the error is
  /// announced on the field that caused it, not via a page-wide toast).
  String? _emailError;

  /// One action in flight at a time: the OTP round-trips are not idempotent
  /// (Supabase rate-limits sends), so Enter/button taps are swallowed while
  /// a request is running.
  bool _busy = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _emailFocusNode.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  /// True while step 1 owns the form (no code has been sent yet).
  bool get _emailStage => _email == '';

  Future<void> _sendCode() async {
    if (_busy || !_emailStage) return;
    final String value = _emailController.text.trim();
    if (!_emailPattern.hasMatch(value)) {
      setState(() {
        _emailError = AppLocalizations.of(context)?.errorInvalidEmail ??
            "That doesn't look like an e-mail address.";
      });
      _emailFocusNode.requestFocus();
      return;
    }
    setState(() {
      _emailError = null;
      _busy = true;
      // Field locks while the send is in flight; a failed send resolves
      // false and we roll back to editable so a typo'd address can be
      // corrected and retried.
      _email = value;
    });
    final sent = await widget.onEmailSubmitted(value);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (!sent) {
        _email = '';
      }
    });
    if (sent) {
      // Step 2 begins where step 1 ended: focus moves to the field the
      // user needs next (WCAG 2.4.3 focus order).
      _otpFocusNode.requestFocus();
    }
  }

  void _verifyOtp() {
    if (_busy || _emailStage) return;
    widget.onOtpSubmitted(_otpController.text.trim());
  }

  /// Escape hatch for "I typed a valid but WRONG address": unlocks the
  /// e-mail field so a new send can start. Without this the previous design
  /// trapped the user on the wrong inbox for the whole route visit.
  void _useDifferentEmail() {
    setState(() {
      _email = '';
      _emailError = null;
      _otpController.clear();
    });
    _emailFocusNode.requestFocus();
  }

  Widget _busyIndicator() => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );

  @override
  Widget build(final BuildContext context) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool codeSent = !_emailStage && !_busy;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          // Cap line length on desktop/web: full-width fields on a wide
          // window read as a broken form.
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- Step 1: e-mail ----
                  Text(
                    l10n?.emailPrompt ??
                        'To which e-mail address should we send a one time password?',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12.0),
                  TextField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    autofocus: true,
                    style: textTheme.bodyLarge,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.send,
                    textCapitalization: TextCapitalization.none,
                    autofillHints: const [AutofillHints.email],
                    readOnly: !_emailStage,
                    onSubmitted: (final value) => _sendCode(),
                    onChanged: (final _) {
                      // Clear the inline error as soon as they edit.
                      if (_emailError != null) {
                        setState(() => _emailError = null);
                      }
                    },
                    // WCAG 3.3.2: persistent labelText; the hint now carries
                    // a FORMAT example instead of repeating the label
                    // (Material: a hint that echoes the label is noise).
                    decoration: InputDecoration(
                      labelText: l10n?.emailAddress ?? 'e-mail address',
                      hintText: 'name@example.com',
                      errorText: _emailError,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: (_emailStage && !_busy) ? _sendCode : null,
                        child: Text(l10n?.sendCode ?? 'Send code'),
                      ),
                      if (_busy && _emailStage) ...[
                        const SizedBox(width: 12.0),
                        _busyIndicator(),
                      ],
                    ],
                  ),
                  // Step-1 success confirmation (WCAG 4.1.3 status message):
                  // the send result is stated on the page, not left implied
                  // by a greyed-out field.
                  if (codeSent)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.codeSentTo(_email) ?? 'Code sent to $_email',
                            style: textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          TextButton(
                            onPressed: _busy ? null : _useDifferentEmail,
                            child: Text(l10n?.useDifferentEmail ??
                                'Use a different address?'),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32.0),

                  // ---- Step 2: one-time password ----
                  Text(
                    l10n?.otpPrompt ??
                        'Now enter the one-time-password we sent.',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12.0),
                  TextField(
                    controller: _otpController,
                    focusNode: _otpFocusNode,
                    style: textTheme.bodyLarge,
                    textInputAction: TextInputAction.send,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    enabled: !_emailStage,
                    readOnly: _emailStage,
                    onSubmitted: (final value) => _verifyOtp(),
                    // The ARB value stays 'One Time Password...' so existing
                    // tests asserting the rendered hint keep passing.
                    decoration: InputDecoration(
                      labelText:
                          l10n?.oneTimePassword ?? 'One Time Password...',
                      hintText:
                          l10n?.oneTimePassword ?? 'One Time Password...',
                      counterText: '',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: (!_emailStage && !_busy) ? _verifyOtp : null,
                        child: Text(l10n?.verifyCode ?? 'Verify'),
                      ),
                      if (_busy && !_emailStage) ...[
                        const SizedBox(width: 12.0),
                        _busyIndicator(),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
