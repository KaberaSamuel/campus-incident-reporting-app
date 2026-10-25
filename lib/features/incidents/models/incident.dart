import 'package:cloud_firestore/cloud_firestore.dart';

import 'incident_category.dart';
import 'incident_status.dart';
import 'status_history_entry.dart';

class Incident {
  const Incident({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.category,
    required this.title,
    required this.description,
    required this.titleLowercase,
    required this.locationId,
    required this.locationName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.detailNote,
    this.imageUrls = const [],
    this.staffNote,
    this.statusHistory = const [],
  });

  final String id;
  final String reporterId;
  final String reporterName;
  final IncidentCategory category;
  final String title;
  final String description;
  final String titleLowercase;
  final String locationId;
  final String locationName;
  final String? detailNote;
  final List<String> imageUrls;
  final IncidentStatus status;
  final String? staffNote;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<StatusHistoryEntry> statusHistory;

  factory Incident.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final historyRaw = data['statusHistory'] as List<dynamic>? ?? [];
    return Incident(
      id: doc.id,
      reporterId: data['reporterId'] as String? ?? '',
      reporterName: data['reporterName'] as String? ?? '',
      category: IncidentCategory.fromFirestore(data['category'] as String? ?? 'other'),
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      titleLowercase: data['titleLowercase'] as String? ?? '',
      locationId: data['locationId'] as String? ?? '',
      locationName: data['locationName'] as String? ?? '',
      detailNote: data['detailNote'] as String?,
      imageUrls: List<String>.from(data['imageUrls'] as List<dynamic>? ?? []),
      status: IncidentStatus.fromFirestore(data['status'] as String? ?? 'submitted'),
      staffNote: data['staffNote'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      statusHistory: historyRaw
          .map((e) => StatusHistoryEntry.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reporterId': reporterId,
      'reporterName': reporterName,
      'category': category.firestoreValue,
      'title': title,
      'description': description,
      'titleLowercase': titleLowercase,
      'locationId': locationId,
      'locationName': locationName,
      if (detailNote != null) 'detailNote': detailNote,
      'imageUrls': imageUrls,
      'status': status.firestoreValue,
      if (staffNote != null) 'staffNote': staffNote,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'statusHistory': statusHistory.map((e) => e.toMap()).toList(),
    };
  }
}
