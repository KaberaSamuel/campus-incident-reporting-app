import 'package:cloud_firestore/cloud_firestore.dart';

enum AppNotificationType {
  newIncident('new_incident'),
  statusUpdate('status_update');

  const AppNotificationType(this.firestoreValue);
  final String firestoreValue;

  static AppNotificationType fromFirestore(String value) {
    return AppNotificationType.values.firstWhere(
      (t) => t.firestoreValue == value,
      orElse: () => AppNotificationType.statusUpdate,
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.incidentId,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final AppNotificationType type;
  final String title;
  final String body;
  final String incidentId;
  final bool read;
  final DateTime createdAt;

  factory AppNotification.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppNotification(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      type: AppNotificationType.fromFirestore(data['type'] as String? ?? 'status_update'),
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      incidentId: data['incidentId'] as String? ?? '',
      read: data['read'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.firestoreValue,
      'title': title,
      'body': body,
      'incidentId': incidentId,
      'read': read,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
