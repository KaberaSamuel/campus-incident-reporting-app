import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/incident_constants.dart';
import '../../../core/firebase/app_firestore.dart';
import '../../../core/services/image_storage_service.dart';
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

class CampusIncidentStats {
  const CampusIncidentStats({
    required this.submitted,
    required this.inProgress,
    required this.resolved,
  });

  final int submitted;
  final int inProgress;
  final int resolved;

  int get total => submitted + inProgress + resolved;
  int get open => submitted + inProgress;
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
    ImageStorageService? imageStorage,
  })  : _firestore = firestore ?? appFirestore(),
        _imageStorage = imageStorage ?? ImageStorageService();

  final FirebaseFirestore _firestore;
  final ImageStorageService _imageStorage;

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
    return createWithImages(input: input, imageBytes: const []);
  }

  Future<List<String>> uploadIncidentImages({
    required String incidentId,
    required List<Uint8List> images,
  }) async {
    if (images.length > kMaxIncidentPhotos) {
      throw IncidentRepositoryException(
        'You can attach at most $kMaxIncidentPhotos photos.',
      );
    }
    final urls = <String>[];
    for (var i = 0; i < images.length; i++) {
      urls.add(await _imageStorage.upload(
        incidentId: incidentId,
        bytes: images[i],
        index: i,
      ));
    }
    return urls;
  }

  Future<String> createWithImages({
    required IncidentCreateInput input,
    required List<Uint8List> imageBytes,
  }) async {
    if (imageBytes.length > kMaxIncidentPhotos) {
      throw IncidentRepositoryException(
        'You can attach at most $kMaxIncidentPhotos photos.',
      );
    }

    final docRef = _collection.doc();
    final id = docRef.id;
    final imageUrls = imageBytes.isEmpty
        ? <String>[]
        : await uploadIncidentImages(incidentId: id, images: imageBytes);

    final now = DateTime.now();
    final title = input.title.trim();
    final incident = Incident(
      id: id,
      reporterId: input.reporterId,
      reporterName: input.reporterName,
      category: input.category,
      title: title,
      description: input.description.trim(),
      titleLowercase: title.toLowerCase(),
      locationId: input.locationId,
      locationName: input.locationName,
      detailNote: input.detailNote?.trim(),
      imageUrls: imageUrls,
      status: IncidentStatus.submitted,
      createdAt: now,
      updatedAt: now,
      statusHistory: [
        StatusHistoryEntry(status: IncidentStatus.submitted, changedAt: now),
      ],
    );
    await docRef.set(incident.toFirestore());
    return id;
  }

  Future<CampusIncidentStats> fetchCampusStats() async {
    final submitted = await _countWhere('status', IncidentStatus.submitted.firestoreValue);
    final inProgress =
        await _countWhere('status', IncidentStatus.inProgress.firestoreValue);
    final resolved = await _countWhere('status', IncidentStatus.resolved.firestoreValue);
    return CampusIncidentStats(
      submitted: submitted,
      inProgress: inProgress,
      resolved: resolved,
    );
  }

  Future<int> _countWhere(String field, String value) async {
    final snapshot = await _collection.where(field, isEqualTo: value).count().get();
    return snapshot.count ?? 0;
  }

  Future<IncidentQueryPage> queryOpenIncidents({int limit = 10}) {
    return queryIncidents(IncidentQueryParams(openOnly: true, limit: limit));
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
    if (params.openOnly) {
      query = query.where(
        'status',
        whereIn: [
          IncidentStatus.submitted.firestoreValue,
          IncidentStatus.inProgress.firestoreValue,
        ],
      );
    } else if (params.status != null) {
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
  }) async {
    final current = await getById(incidentId);
    if (current == null) return;

    final now = DateTime.now();
    final history = List<StatusHistoryEntry>.from(current.statusHistory);
    if (current.status != input.status) {
      history.add(
        StatusHistoryEntry(
          status: input.status,
          changedAt: now,
          changedByUid: input.changedByUid,
          changedByName: input.changedByName,
        ),
      );
    }

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
      await _imageStorage.deleteByUrl(url);
    }
  }
}
