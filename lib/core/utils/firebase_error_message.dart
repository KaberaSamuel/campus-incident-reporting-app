import 'package:firebase_auth/firebase_auth.dart';

String friendlyFirebaseAuthMessage(Object error) {
  if (error is FirebaseAuthException) {
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
      case 'invalid-email-domain':
      case 'invalid-full-name':
        return error.message ?? 'Invalid input.';
      default:
        return error.message ?? 'Authentication failed.';
    }
  }
  return error.toString();
}
