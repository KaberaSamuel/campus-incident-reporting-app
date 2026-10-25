import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Phase 1 placeholder; replaced in Phase 2 with full login flow.
class LoginScreenStub extends StatelessWidget {
  const LoginScreenStub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Authentication UI arrives in the next phase.'),
              const SizedBox(height: 16),
              TextButton(onPressed: () => context.go('/'), child: const Text('Back to splash')),
            ],
          ),
        ),
      ),
    );
  }
}
