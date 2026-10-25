import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class CampusIncidentsApp extends StatelessWidget {
  const CampusIncidentsApp({required AppRouter appRouter, super.key}) : _router = appRouter;

  final AppRouter _router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Campus Incidents',
      theme: AppTheme.light(),
      themeMode: ThemeMode.light,
      routerConfig: _router.router,
    );
  }
}
