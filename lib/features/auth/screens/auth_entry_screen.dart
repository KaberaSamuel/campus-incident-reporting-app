import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/auth_audience.dart';
import '../widgets/centered_auth_form.dart';

class AuthEntryScreen extends StatefulWidget {
  const AuthEntryScreen({super.key});

  @override
  State<AuthEntryScreen> createState() => _AuthEntryScreenState();
}

class _AuthEntryScreenState extends State<AuthEntryScreen> {
  AuthAudience _audience = AuthAudience.student;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final segment = _audience.routeSegment;

    return Scaffold(
      appBar: AppBar(title: const Text('Campus Incidents')),
      body: SafeArea(
        child: CenteredAuthForm(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your role to sign in or create an account.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SegmentedButton<AuthAudience>(
                segments: [
                  for (final a in AuthAudience.values)
                    ButtonSegment(
                      value: a,
                      label: Text(a.entryLabel),
                      icon: Icon(
                        a == AuthAudience.student
                            ? Icons.school_outlined
                            : Icons.badge_outlined,
                      ),
                    ),
                ],
                selected: {_audience},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _audience = s.first),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      key: ValueKey(_audience),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${_audience.entryLabel} account',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Use your ${_audience.emailSuffix} email address.',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => context.push('/login/$segment'),
                          child: const Text('Sign in'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => context.push('/register/$segment'),
                          child: const Text('Create account'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
