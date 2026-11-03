import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/models/auth_audience.dart';
import '../../features/auth/screens/auth_entry_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/profile/screens/change_password_screen.dart';
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
          path: '/login/student',
          builder: (context, state) =>
              const LoginScreen(audience: AuthAudience.student),
        ),
        GoRoute(
          path: '/login/instructor',
          builder: (context, state) =>
              const LoginScreen(audience: AuthAudience.instructor),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const AuthEntryScreen(),
        ),
        GoRoute(
          path: '/register/student',
          builder: (context, state) =>
              const RegisterScreen(audience: AuthAudience.student),
        ),
        GoRoute(
          path: '/register/instructor',
          builder: (context, state) =>
              const RegisterScreen(audience: AuthAudience.instructor),
        ),
        GoRoute(
          path: '/register',
          redirect: (context, state) => '/login',
        ),
        GoRoute(
          path: '/reset-password',
          name: 'resetPassword',
          builder: (context, state) => const ResetPasswordScreen(),
        ),
        GoRoute(
          path: '/change-password',
          builder: (context, state) => const ChangePasswordScreen(),
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

  static bool _isPublicAuthPath(String location) {
    if (location == '/login' || location == '/reset-password') return true;
    if (location.startsWith('/login/')) return true;
    if (location.startsWith('/register/')) return true;
    return false;
  }

  String? _redirect(BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;

    if (_auth.isBootstrapping) {
      if (location == '/') return null;
      return '/';
    }

    if (!_auth.isSignedIn) {
      if (location == '/change-password') return '/login';
      if (_isPublicAuthPath(location)) return null;
      return '/login';
    }

    final role = _auth.profile?.role ?? UserRole.student;
    final home = role == UserRole.staff ? '/staff/dashboard' : '/student/home';

    if (location == '/change-password') return null;

    if (_isPublicAuthPath(location) || location == '/') {
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
