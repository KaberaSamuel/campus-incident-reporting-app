import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/firebase_error_message.dart';
import '../providers/auth_provider.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isBusy = false;
  String? _message;

  Future<void> _resend() async {
    setState(() {
      _isBusy = true;
      _message = null;
    });
    try {
      await context.read<AuthProvider>().sendEmailVerification();
      setState(() => _message = 'Verification email sent.');
    } catch (e) {
      setState(() => _message = friendlyFirebaseAuthMessage(e));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _reload() async {
    setState(() => _isBusy = true);
    try {
      await context.read<AuthProvider>().refreshUser();
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AuthProvider>().user?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Verify email')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.mark_email_unread_outlined, size: 56),
              const SizedBox(height: 16),
              Text(
                'We sent a verification link to $email. Open it, then tap “I’ve verified”.',
                textAlign: TextAlign.center,
              ),
              if (_message != null) ...[
                const SizedBox(height: 16),
                Text(_message!, textAlign: TextAlign.center),
              ],
              const Spacer(),
              FilledButton(
                onPressed: _isBusy ? null : _reload,
                child: const Text('I’ve verified — continue'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _isBusy ? null : _resend,
                child: const Text('Resend email'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isBusy
                    ? null
                    : () => context.read<AuthProvider>().signOut(),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
