import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StaffShell extends StatelessWidget {
  const StaffShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff')),
      body: const Center(
        child: Text('Staff shell — Dashboard · Incidents · Locations · Inbox · Profile'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 4) context.go('/staff/profile');
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), label: 'Incidents'),
          NavigationDestination(icon: Icon(Icons.place_outlined), label: 'Locations'),
          NavigationDestination(icon: Icon(Icons.inbox_outlined), label: 'Inbox'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
