import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/incident_constants.dart';
import 'incident.dart';
import 'incident_category.dart';
import 'incident_status.dart';

class IncidentQueryParams {
  const IncidentQueryParams({
    this.q,
    this.category,
    this.status,
    this.locationId,
    this.mineOnly = false,
    this.openOnly = false,
    this.reporterId,
    this.limit = kIncidentsPageSize,
    this.startAfter,
  });

  final String? q;
  final IncidentCategory? category;
  final IncidentStatus? status;
  final String? locationId;
  final bool mineOnly;
  final bool openOnly;
  final String? reporterId;
  final int limit;
  final DocumentSnapshot<Map<String, dynamic>>? startAfter;
}

class IncidentQueryPage {
  const IncidentQueryPage({
    required this.incidents,
    this.lastDocument,
  });

  final List<Incident> incidents;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
}
