import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/verify_email_screen.dart';
import '../../features/profile/models/user_role.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/staff/staff_shell.dart';
import '../../features/student/student_shell.dart';

class AppRouter {
  AppRouter({required AuthProvider authProvider}) : _auth = authProvider {
    router = GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: _auth,
      redirect: _redirect,
      routes: [
        GoRoute(
          path: '/',
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          name: 'forgotPassword',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/verify-email',
          name: 'verifyEmail',
          builder: (context, state) => const VerifyEmailScreen(),
        ),
        GoRoute(
          path: '/student',
          name: 'student',
          builder: (context, state) => const StudentShell(),
          routes: [
            GoRoute(
              path: 'profile',
              name: 'studentProfile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/staff',
          name: 'staff',
          builder: (context, state) => const StaffShell(),
          routes: [
            GoRoute(
              path: 'profile',
              name: 'staffProfile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Not found')),
        body: Center(child: Text(state.error?.toString() ?? 'Unknown route')),
      ),
    );
  }

  final AuthProvider _auth;
  late final GoRouter router;

  static const _publicPaths = {'/login', '/register', '/forgot-password'};

  String? _redirect(BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;

    if (_auth.isBootstrapping) {
      if (location == '/') return null;
      return '/';
    }

    if (!_auth.isSignedIn) {
      if (_publicPaths.contains(location)) return null;
      return '/login';
    }

    if (!_auth.isEmailVerified) {
      if (location == '/verify-email') return null;
      return '/verify-email';
    }

    final role = _auth.profile?.role ?? UserRole.student;
    final home = role == UserRole.staff ? '/staff' : '/student';

    if (_publicPaths.contains(location) ||
        location == '/verify-email' ||
        location == '/') {
      return home;
    }

    if (role == UserRole.staff && location.startsWith('/student')) {
      return '/staff';
    }
    if (role == UserRole.student && location.startsWith('/staff')) {
      return '/student';
    }

    return null;
  }
}
