import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/router/app_router.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'features/incidents/repositories/incident_repository.dart';
import 'features/locations/repositories/location_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final authRepository = AuthRepository();
  final authProvider = AuthProvider(authRepository);
  final incidentRepository = IncidentRepository();
  final locationRepository = LocationRepository();
  final appRouter = AppRouter(authProvider: authProvider);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        Provider<AuthRepository>.value(value: authRepository),
        Provider<IncidentRepository>.value(value: incidentRepository),
        Provider<LocationRepository>.value(value: locationRepository),
      ],
      child: CampusIncidentsApp(appRouter: appRouter),
    ),
  );
}
