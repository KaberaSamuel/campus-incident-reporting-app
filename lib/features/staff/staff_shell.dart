import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../notifications/widgets/inbox_nav_icon.dart';

class StaffShell extends StatelessWidget {
  const StaffShell({required this.child, super.key});

  final Widget child;

  static const _routes = [
    '/staff/dashboard',
    '/staff/incidents',
    '/staff/locations',
    '/staff/inbox',
    '/staff/profile',
  ];

  static const _titles = [
    'Dashboard',
    'Incidents',
    'Locations',
    'Inbox',
    'Profile',
  ];

  int _selectedIndex(String path) {
    if (path.startsWith('/staff/incidents')) return 1;
    if (path.startsWith('/staff/locations')) return 2;
    if (path.startsWith('/staff/inbox')) return 3;
    if (path.startsWith('/staff/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final index = _selectedIndex(path);

    return Scaffold(
      appBar: AppBar(title: Text(_titles[index])),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(_routes[i]),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            label: 'Incidents',
          ),
          NavigationDestination(
            icon: Icon(Icons.place_outlined),
            label: 'Locations',
          ),
          NavigationDestination(
            icon: InboxNavIcon(),
            selectedIcon: InboxNavIcon(selected: true),
            label: 'Inbox',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
