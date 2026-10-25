import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen_stub.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/staff/staff_shell.dart';
import '../../features/student/student_shell.dart';

class AppRouter {
  AppRouter();

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreenStub(),
      ),
      GoRoute(
        path: '/student',
        name: 'student',
        builder: (context, state) => const StudentShell(),
      ),
      GoRoute(
        path: '/staff',
        name: 'staff',
        builder: (context, state) => const StaffShell(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(child: Text(state.error?.toString() ?? 'Unknown route')),
    ),
  );
}
