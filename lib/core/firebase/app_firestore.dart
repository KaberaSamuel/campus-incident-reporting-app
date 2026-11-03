import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Must match the **Database ID** in Firebase Console → Firestore (not the display name).

const String kFirestoreDatabaseId = '(default)';

FirebaseFirestore appFirestore() {
  return FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: kFirestoreDatabaseId,
  );
}
