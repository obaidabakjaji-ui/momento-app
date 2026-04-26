import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

/// User-only operations. Room and post operations live in [RoomService].
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<AppUser?> watchUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc);
    });
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  Future<List<AppUser>> getUsers(List<String> uids) async {
    if (uids.isEmpty) return [];
    final results = <AppUser>[];
    // Firestore 'in' queries limited to 30 items
    for (var i = 0; i < uids.length; i += 30) {
      final batch = uids.sublist(i, i + 30 > uids.length ? uids.length : i + 30);
      final query = await _db
          .collection('users')
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      results.addAll(query.docs.map(AppUser.fromFirestore));
    }
    return results;
  }
}
