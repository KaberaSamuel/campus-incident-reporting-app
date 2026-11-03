import '../../../core/constants/auth_constants.dart';
import '../../profile/models/user_role.dart';

/// Student vs instructor entry points in the auth UI (instructor = staff role).
enum AuthAudience {
  student,
  instructor;

  UserRole get userRole => switch (this) {
        AuthAudience.student => UserRole.student,
        AuthAudience.instructor => UserRole.staff,
      };

  String get routeSegment => switch (this) {
        AuthAudience.student => 'student',
        AuthAudience.instructor => 'instructor',
      };

  String get emailSuffix => switch (this) {
        AuthAudience.student => kStudentEmailSuffix,
        AuthAudience.instructor => kStaffEmailSuffix,
      };

  String get signInTitle => switch (this) {
        AuthAudience.student => 'Student sign in',
        AuthAudience.instructor => 'Instructor sign in',
      };

  String get registerTitle => switch (this) {
        AuthAudience.student => 'Student registration',
        AuthAudience.instructor => 'Instructor registration',
      };

  String get entryLabel => switch (this) {
        AuthAudience.student => 'Student',
        AuthAudience.instructor => 'Instructor',
      };

  String wrongEmailDomainMessage() => 'Use a $emailSuffix email address.';
}

AuthAudience? authAudienceFromSegment(String? segment) {
  switch (segment) {
    case 'student':
      return AuthAudience.student;
    case 'instructor':
      return AuthAudience.instructor;
    default:
      return null;
  }
}
