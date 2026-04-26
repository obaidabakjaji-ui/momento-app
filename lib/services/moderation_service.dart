import 'package:cloud_firestore/cloud_firestore.dart';

/// Block / unblock users and submit reports for manual review.
///
/// Reports are written to a top-level `reports` collection that is intentionally
/// readable only via the Firebase Console (no client read access).
class ModerationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('reports');

  Future<void> blockUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    await _users.doc(currentUserId).update({
      'blockedUserIds': FieldValue.arrayUnion([targetUserId]),
    });
  }

  Future<void> unblockUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    await _users.doc(currentUserId).update({
      'blockedUserIds': FieldValue.arrayRemove([targetUserId]),
    });
  }

  /// Report a user. Optionally tied to a specific post / room for context.
  Future<void> reportUser({
    required String reporterId,
    required String reportedUserId,
    String? roomId,
    String? postId,
    String? reason,
  }) async {
    await _reports.add({
      'type': 'user',
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'roomId': roomId,
      'postId': postId,
      'reason': reason,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Report a specific post. Stores both the post id and the sender id so a
  /// reviewer can act on either.
  Future<void> reportPost({
    required String reporterId,
    required String reportedUserId,
    required String roomId,
    required String postId,
    String? reason,
  }) async {
    await _reports.add({
      'type': 'post',
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'roomId': roomId,
      'postId': postId,
      'reason': reason,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
