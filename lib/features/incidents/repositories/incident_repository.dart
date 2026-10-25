import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/incident.dart';
import '../models/incident_category.dart';
import '../models/incident_query_params.dart';
import '../models/incident_status.dart';
import '../models/status_history_entry.dart';

class IncidentRepositoryException implements Exception {
  IncidentRepositoryException(this.message);
  final String message;

  @override
  String toString() => message;
}

class IncidentCreateInput {
  const IncidentCreateInput({
    required this.reporterId,
    required this.reporterName,
    required this.category,
    required this.title,
    required this.description,
    required this.locationId,
    required this.locationName,
    this.detailNote,
    this.imageUrls = const [],
  });

  final String reporterId;
  final String reporterName;
  final IncidentCategory category;
  final String title;
  final String description;
  final String locationId;
  final String locationName;
  final String? detailNote;
  final List<String> imageUrls;
}

class IncidentStaffUpdateInput {
  const IncidentStaffUpdateInput({
    required this.status,
    this.staffNote,
    required this.changedByUid,
    required this.changedByName,
  });

  final IncidentStatus status;
  final String? staffNote;
  final String changedByUid;
  final String changedByName;
}

class IncidentRepository {
  IncidentRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('incidents');

  Stream<Incident?> watchById(String id) {
    return _collection.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Incident.fromFirestore(doc);
    });
  }

  Future<Incident?> getById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Incident.fromFirestore(doc);
  }

  Future<String> create(IncidentCreateInput input) async {
    final now = DateTime.now();
    final title = input.title.trim();
    final incident = Incident(
      id: '',
      reporterId: input.reporterId,
      reporterName: input.reporterName,
      category: input.category,
      title: title,
      description: input.description.trim(),
      titleLowercase: title.toLowerCase(),
      locationId: input.locationId,
      locationName: input.locationName,
      detailNote: input.detailNote?.trim(),
      imageUrls: input.imageUrls,
      status: IncidentStatus.submitted,
      createdAt: now,
      updatedAt: now,
      statusHistory: [
        StatusHistoryEntry(status: IncidentStatus.submitted, changedAt: now),
      ],
    );
    final doc = await _collection.add(incident.toFirestore());
    return doc.id;
  }

  Future<IncidentQueryPage> queryIncidents(IncidentQueryParams params) async {
    if (params.mineOnly && (params.reporterId == null || params.reporterId!.isEmpty)) {
      throw IncidentRepositoryException('reporterId is required when mineOnly is true.');
    }

    Query<Map<String, dynamic>> query = _collection;

    if (params.mineOnly) {
      query = query.where('reporterId', isEqualTo: params.reporterId);
    }
    if (params.category != null) {
      query = query.where('category', isEqualTo: params.category!.firestoreValue);
    }
    if (params.status != null) {
      query = query.where('status', isEqualTo: params.status!.firestoreValue);
    }
    if (params.locationId != null && params.locationId!.isNotEmpty) {
      query = query.where('locationId', isEqualTo: params.locationId);
    }

    final term = params.q?.trim().toLowerCase();
    final hasSearch = term != null && term.isNotEmpty;

    if (hasSearch) {
      query = query
          .where('titleLowercase', isGreaterThanOrEqualTo: term)
          .where('titleLowercase', isLessThanOrEqualTo: '$term\uf8ff')
          .orderBy('titleLowercase')
          .orderBy('createdAt', descending: true);
    } else {
      query = query.orderBy('createdAt', descending: true);
    }

    if (params.startAfter != null) {
      query = query.startAfterDocument(params.startAfter!);
    }

    final snapshot = await query.limit(params.limit).get();
    final incidents = snapshot.docs.map(Incident.fromFirestore).toList();
    final lastDoc = snapshot.docs.isEmpty ? null : snapshot.docs.last;
    return IncidentQueryPage(incidents: incidents, lastDocument: lastDoc);
  }

  Future<void> updateByStaff({
    required String incidentId,
    required IncidentStaffUpdateInput input,
    required List<StatusHistoryEntry> existingHistory,
  }) async {
    final now = DateTime.now();
    final history = List<StatusHistoryEntry>.from(existingHistory);
    history.add(
      StatusHistoryEntry(
        status: input.status,
        changedAt: now,
        changedByUid: input.changedByUid,
        changedByName: input.changedByName,
      ),
    );

    await _collection.doc(incidentId).update({
      'status': input.status.firestoreValue,
      'staffNote': input.staffNote,
      'updatedAt': Timestamp.fromDate(now),
      'statusHistory': history.map((e) => e.toMap()).toList(),
    });
  }

  Future<void> deleteForStudent({
    required String incidentId,
    required String uid,
  }) async {
    final incident = await getById(incidentId);
    if (incident == null) return;
    if (incident.reporterId != uid) {
      throw IncidentRepositoryException('You can only delete your own reports.');
    }
    if (incident.status != IncidentStatus.submitted) {
      throw IncidentRepositoryException(
        'You can only delete reports that are still submitted.',
      );
    }
    await _collection.doc(incidentId).delete();
    await _deleteStorageImages(incident.imageUrls);
  }

  Future<void> deleteForStaff(String incidentId) async {
    final incident = await getById(incidentId);
    if (incident == null) return;
    await _collection.doc(incidentId).delete();
    await _deleteStorageImages(incident.imageUrls);
  }

  Future<void> _deleteStorageImages(List<String> urls) async {
    for (final url in urls) {
      try {
        await _storage.refFromURL(url).delete();
      } catch (_) {
        // Best-effort cleanup; incident doc is already removed.
      }
    }
  }
}
