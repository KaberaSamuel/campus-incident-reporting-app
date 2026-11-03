import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/auth_constants.dart';
import '../../../core/firebase/app_firestore.dart';
import '../../profile/models/user_profile.dart';
import '../../profile/models/user_role.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? appFirestore();

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
    final docRef = _firestore.collection('users').doc(uid);
    final doc = await docRef.get();
    if (doc.exists) return UserProfile.fromFirestore(doc);

    // Repair accounts whose profile write never landed (for example when the
    // Firestore rules were not deployed yet at sign-up time).
    final user = _auth.currentUser;
    if (user == null || user.uid != uid || user.email == null) return null;

    final email = user.email!.toLowerCase();
    final fullName = (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim()
        : email.split('@').first;
    final profile = UserProfile(
      uid: uid,
      email: email,
      fullName: fullName,
      role: roleFromEmail(email),
    );
    await docRef.set(profile.toFirestore());
    return profile;
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

  Future<void> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    roleFromEmail(normalizedEmail);
    if (newPassword.length < 6) {
      throw FirebaseAuthException(
        code: 'weak-password',
        message: 'Choose a stronger password (at least 6 characters).',
      );
    }
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('resetSchoolPassword');
      await callable.call<void>({
        'email': normalizedEmail,
        'newPassword': newPassword,
      });
    } on FirebaseFunctionsException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: e.message ?? 'Could not reset password.',
      );
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Sign in to change your password.',
      );
    }
    if (newPassword.length < 6) {
      throw FirebaseAuthException(
        code: 'weak-password',
        message: 'Choose a stronger password (at least 6 characters).',
      );
    }
    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  Future<void> saveFcmToken(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    // Make sure users/{uid} exists first. Updating a missing document is
    // treated by the rules as a create, which the create rule rejects because
    // the payload has no email/fullName/role.
    try {
      await fetchUserProfile(uid);
      await _firestore.collection('users').doc(uid).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });
    } on FirebaseException catch (e) {
      debugPrint('Could not save FCM token: ${e.message}');
    }
  }
}
