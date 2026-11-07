import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/firebase_error_message.dart';
import '../providers/auth_provider.dart';
import '../widgets/centered_auth_form.dart';

/// Blocks access to the app until the user's ALU email is verified.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _poll;
  bool _busy = false;
  String? _message;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    // Re-check every few seconds so the app continues once the link is tapped.
    _poll = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _check(silent: true),
    );
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _check({bool silent = false}) async {
    final auth = context.read<AuthProvider>();
    try {
      await auth.refreshUser();
      if (!silent && mounted && !auth.isEmailVerified) {
        setState(() {
          _isError = true;
          _message = 'Not verified yet. Open the link in the email we sent.';
        });
      }
    } catch (_) {}
  }

  Future<void> _resend() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await context.read<AuthProvider>().resendVerificationEmail();
      if (mounted) {
        setState(() {
          _isError = false;
          _message = 'Verification email sent. Check your inbox and spam.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _message = friendlyFirebaseAuthMessage(e);
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = context.watch<AuthProvider>().user?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Verify your email')),
      body: SafeArea(
        child: CenteredAuthForm(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.mark_email_unread_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Check your inbox',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a verification link to $email. Open it, then come back here.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : () => _check(),
                child: const Text("I've verified my email"),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _busy ? null : _resend,
                child: const Text('Resend email'),
              ),
              TextButton(
                onPressed: () => context.read<AuthProvider>().signOut(),
                child: const Text('Use a different account'),
              ),
              if (_message != null) ...[
                const SizedBox(height: 12),
                Text(
                  _message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isError
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
