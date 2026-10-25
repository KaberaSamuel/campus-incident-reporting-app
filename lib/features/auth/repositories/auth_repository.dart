import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/auth_constants.dart';
import '../../profile/models/user_profile.dart';
import '../../profile/models/user_role.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  UserRole roleFromEmail(String email) {
    final normalized = email.trim().toLowerCase();
    if (normalized.endsWith(kStudentEmailSuffix)) {
      return UserRole.student;
    }
    if (normalized.endsWith(kStaffEmailSuffix)) {
      return UserRole.staff;
    }
    throw FirebaseAuthException(
      code: 'invalid-email-domain',
      message:
          'Use a $kStudentEmailSuffix or $kStaffEmailSuffix email address.',
    );
  }

  Future<UserProfile?> fetchUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromFirestore(doc);
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final trimmedName = fullName.trim();
    if (trimmedName.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-full-name',
        message: 'Enter your full name.',
      );
    }
    final normalizedEmail = email.trim().toLowerCase();
    final role = roleFromEmail(normalizedEmail);

    final credential = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Could not create account.',
      );
    }

    final profile = UserProfile(
      uid: user.uid,
      email: normalizedEmail,
      fullName: trimmedName,
      role: role,
    );
    await _firestore.collection('users').doc(user.uid).set(profile.toFirestore());
    await user.sendEmailVerification();
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.sendEmailVerification();
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }
}
