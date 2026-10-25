enum UserRole {
  student('student'),
  staff('staff');

  const UserRole(this.firestoreValue);
  final String firestoreValue;

  static UserRole fromFirestore(String value) {
    return UserRole.values.firstWhere(
      (r) => r.firestoreValue == value,
      orElse: () => UserRole.student,
    );
  }
}
