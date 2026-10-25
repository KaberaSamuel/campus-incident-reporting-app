import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/loading_view.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bootstrapping = context.watch<AuthProvider>().isBootstrapping;
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
              const Spacer(),
              if (bootstrapping) const LoadingView(message: 'Loading…'),
            ],
          ),
        ),
      ),
    );
  }
}
