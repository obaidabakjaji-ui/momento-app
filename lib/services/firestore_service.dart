import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/momento.dart';
import '../models/link_request.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- User operations ---

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

  Future<AppUser?> findUserByInviteCode(String code) async {
    final query = await _db
        .collection('users')
        .where('inviteCode', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return AppUser.fromFirestore(query.docs.first);
  }

  // --- Link request operations ---

  Future<void> sendLinkRequest({
    required String fromUserId,
    required String fromUserName,
    required String toUserId,
  }) async {
    // Check if a pending request already exists in either direction
    final existing = await _db
        .collection('link_requests')
        .where('fromUserId', isEqualTo: fromUserId)
        .where('toUserId', isEqualTo: toUserId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('You already sent a request to this user');
    }

    final reverse = await _db
        .collection('link_requests')
        .where('fromUserId', isEqualTo: toUserId)
        .where('toUserId', isEqualTo: fromUserId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (reverse.docs.isNotEmpty) {
      // They already sent us a request — auto-accept
      await acceptLinkRequest(reverse.docs.first.id);
      return;
    }

    await _db.collection('link_requests').add(LinkRequest(
      id: '',
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      toUserId: toUserId,
      status: 'pending',
      createdAt: DateTime.now(),
    ).toMap());
  }

  Stream<List<LinkRequest>> watchPendingRequests(String userId) {
    return _db
        .collection('link_requests')
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(LinkRequest.fromFirestore).toList());
  }

  Stream<List<LinkRequest>> watchSentRequests(String userId) {
    return _db
        .collection('link_requests')
        .where('fromUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map(LinkRequest.fromFirestore).toList());
  }

  Future<void> acceptLinkRequest(String requestId) async {
    final doc = await _db.collection('link_requests').doc(requestId).get();
    if (!doc.exists) return;
    final request = LinkRequest.fromFirestore(doc);

    final batch = _db.batch();

    // Update request status
    batch.update(_db.collection('link_requests').doc(requestId), {
      'status': 'accepted',
    });

    // Add each user to the other's linkedUserIds
    batch.update(_db.collection('users').doc(request.fromUserId), {
      'linkedUserIds': FieldValue.arrayUnion([request.toUserId]),
    });
    batch.update(_db.collection('users').doc(request.toUserId), {
      'linkedUserIds': FieldValue.arrayUnion([request.fromUserId]),
    });

    await batch.commit();
  }

  Future<void> rejectLinkRequest(String requestId) async {
    await _db.collection('link_requests').doc(requestId).update({
      'status': 'rejected',
    });
  }

  Future<void> unlinkUser(String currentUserId, String targetUserId) async {
    final batch = _db.batch();
    batch.update(_db.collection('users').doc(currentUserId), {
      'linkedUserIds': FieldValue.arrayRemove([targetUserId]),
    });
    batch.update(_db.collection('users').doc(targetUserId), {
      'linkedUserIds': FieldValue.arrayRemove([currentUserId]),
    });
    await batch.commit();
  }

  // --- Momento operations ---

  Future<void> createMomento({
    required String senderId,
    required String receiverId,
    required String imageUrl,
  }) async {
    final now = DateTime.now();
    final momento = Momento(
      id: '',
      senderId: senderId,
      receiverId: receiverId,
      imageUrl: imageUrl,
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 6)),
    );
    await _db.collection('momentos').add(momento.toMap());
  }

  Stream<List<Momento>> watchMomentosForUser(String userId) {
    return _db
        .collection('momentos')
        .where('receiverId', isEqualTo: userId)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt', descending: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Momento.fromFirestore).toList());
  }
}
