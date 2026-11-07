import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../notifications/widgets/inbox_nav_icon.dart';

class StudentShell extends StatelessWidget {
  const StudentShell({required this.child, super.key});

  final Widget child;

  static const _routes = [
    '/student/home',
    '/student/reports',
    '/student/report',
    '/student/inbox',
    '/student/profile',
  ];

  static const _titles = ['Home', 'Reports', 'Report', 'Inbox', 'Profile'];

  int _selectedIndex(String path) {
    if (path.startsWith('/student/reports')) return 1;
    if (path.startsWith('/student/report')) return 2;
    if (path.startsWith('/student/inbox')) return 3;
    if (path.startsWith('/student/profile')) return 4;
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
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            label: 'Report',
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
