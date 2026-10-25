import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/repositories/auth_repository.dart';
import '../../features/profile/models/user_role.dart';

class FcmService {
  FcmService({
    required AuthRepository authRepository,
    required GoRouter router,
  })  : _authRepository = authRepository,
        _router = router;

  final AuthRepository _authRepository;
  final GoRouter _router;

  Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      _handleMessage(initial);
    }

    final token = await messaging.getToken();
    if (token != null) {
      await _authRepository.saveFcmToken(token);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen(_authRepository.saveFcmToken);
  }

  Future<void> _handleMessage(RemoteMessage message) async {
    final incidentId = message.data['incidentId'];
    if (incidentId == null || incidentId.isEmpty) return;

    final uid = _authRepository.currentUser?.uid;
    UserRole role = UserRole.student;
    if (uid != null) {
      final profile = await _authRepository.fetchUserProfile(uid);
      role = profile?.role ?? UserRole.student;
    }
    final prefix =
        role == UserRole.staff ? '/staff/incident' : '/student/incident';
    _router.go('$prefix/$incidentId');
  }

  @pragma('vm:entry-point')
  static Future<void> backgroundHandler(RemoteMessage message) async {
    debugPrint('FCM background: ${message.messageId}');
  }
}
