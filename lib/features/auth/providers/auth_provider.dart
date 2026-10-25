import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../profile/models/user_profile.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository) {
    _subscription = _repository.authStateChanges().listen(_onAuthUserChanged);
  }

  final AuthRepository _repository;
  late final StreamSubscription<User?> _subscription;

  bool isBootstrapping = true;
  User? user;
  UserProfile? profile;

  bool get isSignedIn => user != null;
  bool get isEmailVerified => user?.emailVerified ?? false;

  Future<void> _onAuthUserChanged(User? firebaseUser) async {
    user = firebaseUser;
    if (firebaseUser == null) {
      profile = null;
    } else {
      profile = await _repository.fetchUserProfile(firebaseUser.uid);
    }
    isBootstrapping = false;
    notifyListeners();
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await _repository.signUp(
      fullName: fullName,
      email: email,
      password: password,
    );
    await _repository.reloadUser();
    user = _repository.currentUser;
    if (user != null) {
      profile = await _repository.fetchUserProfile(user!.uid);
    }
    notifyListeners();
  }

  Future<void> signIn({required String email, required String password}) async {
    await _repository.signIn(email: email, password: password);
    await _repository.reloadUser();
    user = _repository.currentUser;
    if (user != null) {
      profile = await _repository.fetchUserProfile(user!.uid);
    }
    notifyListeners();
  }

  Future<void> signOut() => _repository.signOut();

  Future<void> sendPasswordReset(String email) =>
      _repository.sendPasswordReset(email);

  Future<void> sendEmailVerification() => _repository.sendEmailVerification();

  Future<void> refreshUser() async {
    await _repository.reloadUser();
    user = _repository.currentUser;
    if (user != null) {
      profile = await _repository.fetchUserProfile(user!.uid);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
