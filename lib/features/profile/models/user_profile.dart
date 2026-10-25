import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_role.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    this.fcmTokens = const [],
  });

  final String uid;
  final String email;
  final String fullName;
  final UserRole role;
  final List<String> fcmTokens;

  factory UserProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserProfile(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      role: UserRole.fromFirestore(data['role'] as String? ?? 'student'),
      fcmTokens: List<String>.from(data['fcmTokens'] as List<dynamic>? ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'fullName': fullName,
      'role': role.firestoreValue,
      'fcmTokens': fcmTokens,
    };
  }
}
