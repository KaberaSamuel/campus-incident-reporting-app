import 'package:cloud_firestore/cloud_firestore.dart';

class CampusLocation {
  const CampusLocation({
    required this.id,
    required this.name,
    required this.createdAt,
    this.sortOrder,
  });

  final String id;
  final String name;
  final int? sortOrder;
  final DateTime createdAt;

  factory CampusLocation.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return CampusLocation(
      id: doc.id,
      name: data['name'] as String? ?? '',
      sortOrder: data['sortOrder'] as int?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      if (sortOrder != null) 'sortOrder': sortOrder,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
