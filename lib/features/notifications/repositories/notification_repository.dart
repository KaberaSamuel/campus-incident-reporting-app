import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/app_firestore.dart';

import '../models/app_notification.dart';

class NotificationRepository {
  NotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? appFirestore();

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('notifications');

  Stream<List<AppNotification>> watchForUser(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs.map(AppNotification.fromFirestore).toList(),
        );
  }

  Future<void> markRead(String notificationId) async {
    await _collection.doc(notificationId).update({'read': true});
  }

  Future<void> markAllRead(String userId) async {
    final snap = await _collection
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}
