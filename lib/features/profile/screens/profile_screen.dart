import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/providers/auth_provider.dart';
import '../models/user_role.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;
    final roleLabel = profile?.role == UserRole.staff ? 'Staff' : 'Student';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                ListTile(
                  title: const Text('Full name'),
                  subtitle: Text(profile.fullName),
                ),
                ListTile(
                  title: const Text('Email'),
                  subtitle: Text(profile.email),
                ),
                ListTile(
                  title: const Text('Role'),
                  subtitle: Text(roleLabel),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => auth.signOut(),
                  child: const Text('Sign out'),
                ),
              ],
            ),
    );
  }
}
