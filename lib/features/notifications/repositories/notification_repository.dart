import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/app_firestore.dart';
import '../models/app_notification.dart';

class NotificationRepository {
  NotificationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? appFirestore();

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('notifications');

  /// Live inbox. Students see notifications addressed to them; staff also see
  /// the shared staff notifications (new reports).
  Stream<List<AppNotification>> watchInbox({
    required String uid,
    required bool isStaff,
  }) {
    final query = isStaff
        ? _collection.where('audience', isEqualTo: 'staff')
        : _collection.where('userId', isEqualTo: uid);
    return query
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map(AppNotification.fromFirestore).toList());
  }

  Stream<int> watchUnreadCount({required String uid, required bool isStaff}) {
    return watchInbox(
      uid: uid,
      isStaff: isStaff,
    ).map((items) => items.where((n) => !n.isReadBy(uid)).length);
  }

  Future<void> markRead(AppNotification n, String uid) async {
    if (n.isReadBy(uid)) return;
    await _collection
        .doc(n.id)
        .update(
          n.isForStaff
              ? {
                  'readBy': FieldValue.arrayUnion([uid]),
                }
              : {'read': true},
        );
  }

  Future<void> markAllRead(List<AppNotification> items, String uid) async {
    final batch = _firestore.batch();
    var any = false;
    for (final n in items.where((n) => !n.isReadBy(uid))) {
      any = true;
      batch.update(
        _collection.doc(n.id),
        n.isForStaff
            ? {
                'readBy': FieldValue.arrayUnion([uid]),
              }
            : {'read': true},
      );
    }
    if (any) await batch.commit();
  }
}
