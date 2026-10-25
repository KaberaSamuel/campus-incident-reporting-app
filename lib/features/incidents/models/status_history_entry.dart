import 'package:cloud_firestore/cloud_firestore.dart';

import 'incident_status.dart';

class StatusHistoryEntry {
  const StatusHistoryEntry({
    required this.status,
    required this.changedAt,
    this.changedByUid,
    this.changedByName,
  });

  final IncidentStatus status;
  final DateTime changedAt;
  final String? changedByUid;
  final String? changedByName;

  factory StatusHistoryEntry.fromMap(Map<String, dynamic> map) {
    return StatusHistoryEntry(
      status: IncidentStatus.fromFirestore(map['status'] as String? ?? 'submitted'),
      changedAt: (map['changedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      changedByUid: map['changedByUid'] as String?,
      changedByName: map['changedByName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.firestoreValue,
      'changedAt': Timestamp.fromDate(changedAt),
      if (changedByUid != null) 'changedByUid': changedByUid,
      if (changedByName != null) 'changedByName': changedByName,
    };
  }
}
