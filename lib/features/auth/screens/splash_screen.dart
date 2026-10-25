import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.school_outlined, size: 72, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Campus Incidents',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Report campus issues and track progress.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go('/login'),
                child: const Text('Go to login'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/student'),
                child: const Text('Student shell (placeholder)'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => context.go('/staff'),
                child: const Text('Staff shell (placeholder)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
