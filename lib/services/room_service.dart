import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room.dart';
import '../models/join_request.dart';
import '../models/room_post.dart';

/// Summary of a multi-room post — how many went live vs need approval.
class PostResult {
  final int live;
  final int pending;
  const PostResult({required this.live, required this.pending});
  int get total => live + pending;
}

/// Handles all room and post operations: create/join/leave rooms,
/// approve join requests, promote/kick members, post photos to rooms.
class RoomService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _rooms => _db.collection('rooms');
  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  // ===== Room CRUD =====

  /// Create a new room. Creator becomes the first admin and member.
  /// Generates a unique 6-char uppercase code; retries on collision.
  Future<Room> createRoom({
    required String name,
    required RoomVisibility visibility,
    required String creatorUid,
    String? photoUrl,
  }) async {
    final code = await _generateUniqueCode();
    final now = DateTime.now();

    final room = Room(
      id: '',
      name: name,
      code: code,
      visibility: visibility,
      photoUrl: photoUrl,
      createdBy: creatorUid,
      createdAt: now,
      adminIds: [creatorUid],
      memberIds: [creatorUid],
    );

    final ref = await _rooms.add(room.toMap());

    // Add room to user's roomIds and activeRoomIds (default active for creator)
    await _users.doc(creatorUid).update({
      'roomIds': FieldValue.arrayUnion([ref.id]),
      'activeRoomIds': FieldValue.arrayUnion([ref.id]),
    });

    return Room(
      id: ref.id,
      name: room.name,
      code: room.code,
      visibility: room.visibility,
      photoUrl: room.photoUrl,
      createdBy: room.createdBy,
      createdAt: room.createdAt,
      adminIds: room.adminIds,
      memberIds: room.memberIds,
    );
  }

  /// Look up a room by its code (case-insensitive).
  Future<Room?> findRoomByCode(String code) async {
    final query = await _rooms
        .where('code', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return Room.fromFirestore(query.docs.first);
  }

  Stream<Room?> watchRoom(String roomId) {
    return _rooms.doc(roomId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Room.fromFirestore(doc);
    });
  }

  Future<List<Room>> getRooms(List<String> roomIds) async {
    if (roomIds.isEmpty) return [];
    final results = <Room>[];
    for (var i = 0; i < roomIds.length; i += 30) {
      final batch =
          roomIds.sublist(i, i + 30 > roomIds.length ? roomIds.length : i + 30);
      final query = await _rooms
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      results.addAll(query.docs.map(Room.fromFirestore));
    }
    return results;
  }

  // ===== Joining =====

  /// Public room: instant join. Permission room: creates a JoinRequest.
  /// Returns true if joined immediately, false if request was created.
  Future<bool> requestOrJoinRoom({
    required Room room,
    required String userId,
    required String userName,
    String? userPhotoUrl,
  }) async {
    if (room.isMember(userId)) return true;

    if (room.visibility == RoomVisibility.public) {
      await _addMember(room.id, userId);
      return true;
    }

    // Permission room — create a join request (doc id = userId to dedupe)
    await _rooms
        .doc(room.id)
        .collection('join_requests')
        .doc(userId)
        .set(JoinRequest(
          id: userId,
          roomId: room.id,
          userId: userId,
          userName: userName,
          userPhotoUrl: userPhotoUrl,
          createdAt: DateTime.now(),
        ).toMap());
    return false;
  }

  Stream<List<JoinRequest>> watchJoinRequests(String roomId) {
    return _rooms
        .doc(roomId)
        .collection('join_requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(JoinRequest.fromFirestore).toList());
  }

  /// Any admin can approve. Adds the user as a member and removes the request.
  Future<void> approveJoinRequest({
    required String roomId,
    required String userId,
  }) async {
    final batch = _db.batch();
    batch.update(_rooms.doc(roomId), {
      'memberIds': FieldValue.arrayUnion([userId]),
    });
    batch.update(_users.doc(userId), {
      'roomIds': FieldValue.arrayUnion([roomId]),
    });
    batch.delete(_rooms.doc(roomId).collection('join_requests').doc(userId));
    await batch.commit();
  }

  Future<void> denyJoinRequest({
    required String roomId,
    required String userId,
  }) async {
    await _rooms
        .doc(roomId)
        .collection('join_requests')
        .doc(userId)
        .delete();
  }

  Future<void> _addMember(String roomId, String userId) async {
    final batch = _db.batch();
    batch.update(_rooms.doc(roomId), {
      'memberIds': FieldValue.arrayUnion([userId]),
    });
    batch.update(_users.doc(userId), {
      'roomIds': FieldValue.arrayUnion([roomId]),
    });
    await batch.commit();
  }

  // ===== Membership management =====

  /// User leaves a room voluntarily. If they were the creator and there are
  /// other admins, the room continues; if they were the only member, the
  /// room is deleted.
  Future<void> leaveRoom({
    required String roomId,
    required String userId,
  }) async {
    final roomDoc = await _rooms.doc(roomId).get();
    if (!roomDoc.exists) return;
    final room = Room.fromFirestore(roomDoc);

    if (room.memberIds.length <= 1) {
      // Last member — delete the room entirely
      await deleteRoom(roomId);
      return;
    }

    final batch = _db.batch();
    batch.update(_rooms.doc(roomId), {
      'memberIds': FieldValue.arrayRemove([userId]),
      'adminIds': FieldValue.arrayRemove([userId]),
    });
    batch.update(_users.doc(userId), {
      'roomIds': FieldValue.arrayRemove([roomId]),
      'activeRoomIds': FieldValue.arrayRemove([roomId]),
      'favoriteRoomIds': FieldValue.arrayRemove([roomId]),
    });
    await batch.commit();
  }

  /// Admin kicks a member.
  Future<void> kickMember({
    required String roomId,
    required String userId,
  }) async {
    final batch = _db.batch();
    batch.update(_rooms.doc(roomId), {
      'memberIds': FieldValue.arrayRemove([userId]),
      'adminIds': FieldValue.arrayRemove([userId]),
    });
    batch.update(_users.doc(userId), {
      'roomIds': FieldValue.arrayRemove([roomId]),
      'activeRoomIds': FieldValue.arrayRemove([roomId]),
      'favoriteRoomIds': FieldValue.arrayRemove([roomId]),
    });
    await batch.commit();
  }

  Future<void> promoteToAdmin({
    required String roomId,
    required String userId,
  }) async {
    await _rooms.doc(roomId).update({
      'adminIds': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> demoteAdmin({
    required String roomId,
    required String userId,
  }) async {
    await _rooms.doc(roomId).update({
      'adminIds': FieldValue.arrayRemove([userId]),
    });
  }

  /// Only the creator can rename. Enforced by security rules as well.
  /// Writes both `name` and `nameLower` so search results stay in sync.
  Future<void> renameRoom({
    required String roomId,
    required String newName,
  }) async {
    await _rooms.doc(roomId).update({
      'name': newName,
      'nameLower': newName.toLowerCase(),
    });
  }

  /// Case-insensitive prefix search across **public** rooms by name.
  /// Returns up to [limit] matches. Callers typically filter out rooms the
  /// current user is already a member of.
  Future<List<Room>> searchPublicRooms(String query, {int limit = 15}) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final snap = await _rooms
        .where('visibility', isEqualTo: 'public')
        .where('nameLower', isGreaterThanOrEqualTo: q)
        .where('nameLower', isLessThan: '$q')
        .orderBy('nameLower')
        .limit(limit)
        .get();
    return snap.docs.map(Room.fromFirestore).toList();
  }

  /// Update the room's photo URL. Allowed for any admin.
  Future<void> updateRoomPhoto({
    required String roomId,
    required String? photoUrl,
  }) async {
    await _rooms.doc(roomId).update({'photoUrl': photoUrl});
  }

  Future<void> deleteRoom(String roomId) async {
    // Best-effort: remove room from every member's user doc, then delete the room.
    // Posts under rooms/{roomId}/posts are left for a cleanup function (TTL or
    // a Cloud Function) since client-side recursive deletes aren't supported.
    final roomDoc = await _rooms.doc(roomId).get();
    if (!roomDoc.exists) return;
    final room = Room.fromFirestore(roomDoc);

    final batch = _db.batch();
    for (final uid in room.memberIds) {
      batch.update(_users.doc(uid), {
        'roomIds': FieldValue.arrayRemove([roomId]),
        'activeRoomIds': FieldValue.arrayRemove([roomId]),
        'favoriteRoomIds': FieldValue.arrayRemove([roomId]),
      });
    }
    batch.delete(_rooms.doc(roomId));
    await batch.commit();
  }

  // ===== Active / favorite rooms (per-user) =====

  Future<void> setActiveRooms(String userId, List<String> roomIds) async {
    await _users.doc(userId).update({'activeRoomIds': roomIds});
  }

  Future<void> toggleFavoriteRoom({
    required String userId,
    required String roomId,
    required bool favorite,
  }) async {
    await _users.doc(userId).update({
      'favoriteRoomIds':
          favorite ? FieldValue.arrayUnion([roomId]) : FieldValue.arrayRemove([roomId]),
    });
  }

  // ===== Posts =====

  /// Post the same image to multiple rooms. One doc is written per room
  /// (sharing the same imageUrl) so each room's post stream is independent
  /// and security rules can be checked per-room.
  ///
  /// If a target room requires approval and the sender is neither an admin
  /// nor a trusted user, the post is written with `pending: true` and won't
  /// appear in the feed until an admin approves it.
  ///
  /// Returns a [PostResult] summarizing how many posts went live immediately
  /// vs how many are pending approval, so the caller can show a helpful
  /// snackbar.
  Future<PostResult> postToRooms({
    required List<String> roomIds,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required String imageUrl,
    String? videoUrl,
    PostMediaType mediaType = PostMediaType.photo,
    String? caption,
  }) async {
    if (roomIds.isEmpty) return const PostResult(live: 0, pending: 0);

    // Fetch each target room so we know its approval policy.
    final rooms = await getRooms(roomIds);
    final roomMap = {for (final r in rooms) r.id: r};

    final now = DateTime.now();
    final expires = now.add(const Duration(hours: 6));
    final batch = _db.batch();
    var live = 0;
    var pending = 0;

    for (final roomId in roomIds) {
      final room = roomMap[roomId];
      if (room == null) continue;
      final isPending = room.requiresApprovalFor(senderId);
      if (isPending) {
        pending++;
      } else {
        live++;
      }
      final ref = _rooms.doc(roomId).collection('posts').doc();
      batch.set(
        ref,
        RoomPost(
          id: ref.id,
          roomId: roomId,
          senderId: senderId,
          senderName: senderName,
          senderPhotoUrl: senderPhotoUrl,
          imageUrl: imageUrl,
          videoUrl: videoUrl,
          mediaType: mediaType,
          caption: caption,
          createdAt: now,
          expiresAt: expires,
          pending: isPending,
        ).toMap(),
      );
    }
    await batch.commit();
    // Update posting streak in a separate transaction so that if the streak
    // update fails, the posts themselves still land.
    unawaited(_bumpStreak(senderId));
    return PostResult(live: live, pending: pending);
  }

  /// Admin approves a pending post — flips its `pending` field to false so
  /// it shows up in the feed.
  Future<void> approvePost({
    required String roomId,
    required String postId,
  }) async {
    await _rooms
        .doc(roomId)
        .collection('posts')
        .doc(postId)
        .update({'pending': false});
  }

  /// Admin rejects a pending post — deletes it. Same as deletePost but named
  /// for clarity at the call site.
  Future<void> rejectPost({
    required String roomId,
    required String postId,
  }) async {
    await deletePost(roomId: roomId, postId: postId);
  }

  /// Watch all pending posts in a room. Admin-only (security rules enforce).
  Stream<List<RoomPost>> watchPendingPosts(String roomId, {int limit = 50}) {
    return _rooms
        .doc(roomId)
        .collection('posts')
        .where('pending', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(RoomPost.fromFirestore).toList());
  }

  /// Admin toggles the room's post-approval requirement.
  Future<void> setRequiresPostApproval({
    required String roomId,
    required bool requires,
  }) async {
    await _rooms.doc(roomId).update({'requiresPostApproval': requires});
  }

  /// Admin marks a user as trusted (bypasses post approval).
  Future<void> setUserTrusted({
    required String roomId,
    required String userId,
    required bool trusted,
  }) async {
    await _rooms.doc(roomId).update({
      'trustedUserIds':
          trusted ? FieldValue.arrayUnion([userId]) : FieldValue.arrayRemove([userId]),
    });
  }

  /// Read the current user doc and update `currentStreak` / `longestStreak`
  /// / `lastPostDate` based on whether the last post was today, yesterday,
  /// or earlier (or never).
  Future<void> _bumpStreak(String userId) async {
    try {
      await _db.runTransaction((tx) async {
        final ref = _users.doc(userId);
        final snap = await tx.get(ref);
        if (!snap.exists) return;
        final data = snap.data() as Map<String, dynamic>;
        final lastTs = data['lastPostDate'] as Timestamp?;
        final current = (data['currentStreak'] ?? 0) as int;
        final longest = (data['longestStreak'] ?? 0) as int;

        final today = _dayKey(DateTime.now());
        final last = lastTs == null ? null : _dayKey(lastTs.toDate());

        int newStreak;
        if (last == today) {
          // Already posted today — no change.
          return;
        } else if (last != null && today - last == 1) {
          newStreak = current + 1;
        } else {
          newStreak = 1;
        }

        tx.update(ref, {
          'currentStreak': newStreak,
          'longestStreak': newStreak > longest ? newStreak : longest,
          'lastPostDate': Timestamp.fromDate(DateTime.now()),
        });
      });
    } catch (_) {
      // Streak bookkeeping is best-effort. Never fail a post over it.
    }
  }

  /// Days since epoch in local time, used to compare dates ignoring time.
  int _dayKey(DateTime d) {
    final local = DateTime(d.year, d.month, d.day);
    return local.millisecondsSinceEpoch ~/ (24 * 60 * 60 * 1000);
  }

  /// Watch the latest non-expired posts from a single room.
  /// Expired and still-pending posts are filtered client-side so we don't
  /// need a composite Firestore index.
  Stream<List<RoomPost>> watchRoomPosts(String roomId, {int limit = 50}) {
    return _rooms
        .doc(roomId)
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map(RoomPost.fromFirestore)
            .where((p) => !p.isExpired && !p.pending)
            .toList());
  }

  Future<void> deletePost({
    required String roomId,
    required String postId,
  }) async {
    await _rooms.doc(roomId).collection('posts').doc(postId).delete();
  }

  /// Toggle a like on a post. Adds the userId to `likedBy` if not present,
  /// otherwise removes it.
  Future<void> toggleLike({
    required String roomId,
    required String postId,
    required String userId,
    required bool like,
  }) async {
    await _rooms.doc(roomId).collection('posts').doc(postId).update({
      'likedBy':
          like ? FieldValue.arrayUnion([userId]) : FieldValue.arrayRemove([userId]),
    });
  }

  // ===== Helpers =====

  static const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // omits 0/O/1/I
  static final _rng = Random.secure();

  String _randomCode() {
    return List.generate(6, (_) => _codeChars[_rng.nextInt(_codeChars.length)])
        .join();
  }

  Future<String> _generateUniqueCode() async {
    for (var attempt = 0; attempt < 8; attempt++) {
      final candidate = _randomCode();
      final existing = await _rooms
          .where('code', isEqualTo: candidate)
          .limit(1)
          .get();
      if (existing.docs.isEmpty) return candidate;
    }
    throw Exception('Could not generate a unique room code');
  }
}
