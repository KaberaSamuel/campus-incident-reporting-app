import 'package:firebase_auth/firebase_auth.dart';

import '../services/image_storage_service.dart';

String friendlyFirebaseAuthMessage(Object error) {
  if (error is ImageStorageException) {
    return error.message;
  }
  if (error is FirebaseAuthException) {
    final message = error.message ?? '';
    if (message.contains('CONFIGURATION_NOT_FOUND')) {
      return 'Firebase Auth is not fully set up for this app. In Firebase Console, enable Email/Password sign-in, add your Android app SHA-1 fingerprint, then re-download google-services.json.';
    }
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'weak-password':
        return 'Choose a stronger password (at least 6 characters).';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'configuration-not-found':
        return 'Firebase Auth is not fully set up for this app. In Firebase Console, enable Email/Password sign-in, add your Android app SHA-1 fingerprint, then re-download google-services.json.';
      case 'invalid-email-domain':
      case 'invalid-full-name':
      case 'invalid-argument':
      case 'not-found':
        return error.message ?? 'Invalid input.';
      case 'unavailable':
      case 'internal':
        return error.message ??
            'Server error. Deploy Cloud Functions (resetSchoolPassword) and try again.';
      default:
        return error.message ?? 'Authentication failed.';
    }
  }
  return error.toString();
}
