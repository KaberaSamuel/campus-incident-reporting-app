import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/auth_audience.dart';
import '../widgets/centered_auth_form.dart';

class AuthEntryScreen extends StatelessWidget {
  const AuthEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Campus Incidents')),
      body: SafeArea(
        child: CenteredAuthForm(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sign in or create an account',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              for (final audience in AuthAudience.values) ...[
                _AudienceCard(audience: audience),
                if (audience != AuthAudience.values.last) const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AudienceCard extends StatelessWidget {
  const _AudienceCard({required this.audience});

  final AuthAudience audience;

  @override
  Widget build(BuildContext context) {
    final segment = audience.routeSegment;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              audience.entryLabel,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
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
    );
  }
}
