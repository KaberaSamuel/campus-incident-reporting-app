import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/app_firestore.dart';

import '../models/location.dart';

class LocationRepositoryException implements Exception {
  LocationRepositoryException(this.message);
  final String message;

  @override
  String toString() => message;
}

class LocationRepository {
  LocationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? appFirestore();

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('locations');

  Stream<List<CampusLocation>> watchAll() {
    return _collection.orderBy('name').snapshots().map(
          (snap) => snap.docs.map(CampusLocation.fromFirestore).toList(),
        );
  }

  Future<List<CampusLocation>> fetchAll() async {
    final snap = await _collection.orderBy('name').get();
    return snap.docs.map(CampusLocation.fromFirestore).toList();
  }

  Future<String> create({
    required String name,
    int? sortOrder,
  }) async {
    final now = DateTime.now();
    final location = CampusLocation(
      id: '',
      name: name.trim(),
      sortOrder: sortOrder,
      createdAt: now,
    );
    final doc = await _collection.add(location.toFirestore());
    return doc.id;
  }

  Future<void> update({
    required String id,
    required String name,
    int? sortOrder,
  }) async {
    await _collection.doc(id).update({
      'name': name.trim(),
      'sortOrder': ?sortOrder,
    });
  }

  Future<void> delete(String id) async {
    final inUse = await _firestore
        .collection('incidents')
        .where('locationId', isEqualTo: id)
        .limit(1)
        .get();
    if (inUse.docs.isNotEmpty) {
      throw LocationRepositoryException(
        'Cannot delete a location that is used by incidents.',
      );
    }
    await _collection.doc(id).delete();
  }
}
