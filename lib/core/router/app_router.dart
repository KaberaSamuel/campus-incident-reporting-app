import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/verify_email_screen.dart';
import '../../features/incidents/screens/incident_detail_screen.dart';
import '../../features/incidents/screens/incident_list_screen.dart';
import '../../features/locations/screens/manage_locations_screen.dart';
import '../../features/notifications/screens/inbox_screen.dart';
import '../../features/profile/models/user_role.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/staff/screens/staff_dashboard_screen.dart';
import '../../features/staff/staff_shell.dart';
import '../../features/student/screens/report_incident_screen.dart';
import '../../features/student/screens/student_home_screen.dart';
import '../../features/student/student_shell.dart';

class AppRouter {
  AppRouter({required AuthProvider authProvider}) : _auth = authProvider {
    router = GoRouter(
      navigatorKey: rootNavigatorKey,
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
          redirect: (context, state) =>
              state.uri.path == '/student' ? '/student/home' : null,
          routes: [
            ShellRoute(
              builder: (context, state, child) => StudentShell(child: child),
              routes: [
                GoRoute(
                  path: 'home',
                  builder: (context, state) => const StudentHomeScreen(),
                ),
                GoRoute(
                  path: 'reports',
                  builder: (context, state) => const IncidentListScreen(
                    title: 'Reports',
                    incidentRoutePrefix: '/student/incident',
                  ),
                ),
                GoRoute(
                  path: 'report',
                  builder: (context, state) => const ReportIncidentScreen(),
                ),
                GoRoute(
                  path: 'inbox',
                  builder: (context, state) => const InboxScreen(
                    incidentRoutePrefix: '/student/incident',
                  ),
                ),
                GoRoute(
                  path: 'profile',
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
            GoRoute(
              parentNavigatorKey: rootNavigatorKey,
              path: 'incident/:id',
              builder: (context, state) => IncidentDetailScreen(
                incidentId: state.pathParameters['id']!,
                isStaffView: false,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/staff',
          redirect: (context, state) =>
              state.uri.path == '/staff' ? '/staff/dashboard' : null,
          routes: [
            ShellRoute(
              builder: (context, state, child) => StaffShell(child: child),
              routes: [
                GoRoute(
                  path: 'dashboard',
                  builder: (context, state) => const StaffDashboardScreen(),
                ),
                GoRoute(
                  path: 'incidents',
                  builder: (context, state) => const IncidentListScreen(
                    title: 'All incidents',
                    incidentRoutePrefix: '/staff/incident',
                    showMineOnlyToggle: false,
                  ),
                ),
                GoRoute(
                  path: 'locations',
                  builder: (context, state) => const ManageLocationsScreen(),
                ),
                GoRoute(
                  path: 'inbox',
                  builder: (context, state) => const InboxScreen(
                    incidentRoutePrefix: '/staff/incident',
                  ),
                ),
                GoRoute(
                  path: 'profile',
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
            GoRoute(
              parentNavigatorKey: rootNavigatorKey,
              path: 'incident/:id',
              builder: (context, state) => IncidentDetailScreen(
                incidentId: state.pathParameters['id']!,
                isStaffView: true,
              ),
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

  static final rootNavigatorKey = GlobalKey<NavigatorState>();

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
    final home = role == UserRole.staff ? '/staff/dashboard' : '/student/home';

    if (_publicPaths.contains(location) ||
        location == '/verify-email' ||
        location == '/') {
      return home;
    }

    if (role == UserRole.staff && location.startsWith('/student')) {
      return '/staff/dashboard';
    }
    if (role == UserRole.student && location.startsWith('/staff')) {
      return '/student/home';
    }

    return null;
  }
}
