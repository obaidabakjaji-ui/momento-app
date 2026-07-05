package com.momento.momento.data

import android.util.Log
import com.google.firebase.Timestamp
import com.google.firebase.firestore.FieldPath
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Query
import com.momento.momento.core.POST_LIFETIME_MS
import com.momento.momento.data.model.JoinRequest
import com.momento.momento.data.model.PostResult
import com.momento.momento.data.model.Room
import com.momento.momento.data.model.RoomPost
import com.momento.momento.data.model.RoomVisibility
import java.security.SecureRandom
import java.time.Instant
import java.time.ZoneId
import java.util.Date
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await

/**
 * All room and post operations — mirror of lib/services/room_service.dart
 * (587 LOC), method-for-method: create/join/leave rooms, approve join
 * requests, promote/kick members, post photos to rooms.
 *
 * Every mutation here must be legal under the UNCHANGED firestore.rules
 * (target: zero rules changes). The two easiest ways to break that:
 *  - Cross-user user-doc writes (approveJoinRequest, public join, kick,
 *    leave, deleteRoom) are allowed ONLY because the users rules permit
 *    non-self updates whose affected keys are a subset of
 *    ['roomIds', 'activeRoomIds', 'favoriteRoomIds']. Never add any other
 *    field to those batch entries (contract B13).
 *  - postToRooms' per-room `pending` flag must agree with the rules'
 *    create condition (contract B2) — one mismatched flag rejects the
 *    entire atomic WriteBatch.
 */
object RoomRepository {

    private const val TAG = "RoomRepository"

    private val db: FirebaseFirestore get() = FirebaseFirestore.getInstance()
    private val rooms get() = db.collection("rooms")
    private val users get() = db.collection("users")

    // Fire-and-forget work that must outlive the caller (streak bookkeeping
    // after a post). Supervisor so one failure never poisons the scope.
    private val repoScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    // ===== Room CRUD =====

    /**
     * Create a new room. Creator becomes the first admin and member.
     * Generates a unique 6-char uppercase code; retries on collision.
     *
     * Rules: room create requires createdBy == auth.uid && adminIds ==
     * [auth.uid] && memberIds == [auth.uid]; the follow-up user-doc write is
     * self and touches only roomIds/activeRoomIds.
     */
    suspend fun createRoom(
        name: String,
        visibility: RoomVisibility,
        creatorUid: String,
        photoUrl: String? = null,
    ): Room {
        val code = generateUniqueCode()

        val room = Room(
            id = "",
            name = name,
            code = code,
            visibility = visibility,
            photoUrl = photoUrl,
            createdBy = creatorUid,
            createdAt = Date(),
            adminIds = listOf(creatorUid),
            memberIds = listOf(creatorUid),
        )

        val ref = rooms.add(room.toMap()).await()

        // Add room to user's roomIds and activeRoomIds (default active for
        // the creator).
        users.document(creatorUid).update(
            mapOf(
                "roomIds" to FieldValue.arrayUnion(ref.id),
                "activeRoomIds" to FieldValue.arrayUnion(ref.id),
            )
        ).await()

        return room.copy(id = ref.id)
    }

    /** Look up a room by its code (case-insensitive — input is uppercased, B13). */
    suspend fun findRoomByCode(code: String): Room? {
        val query = rooms
            .whereEqualTo("code", code.uppercase())
            .limit(1)
            .get()
            .await()
        val doc = query.documents.firstOrNull() ?: return null
        return Room.fromSnapshot(doc)
    }

    // Live rooms/{roomId} stream. Emits null for a missing doc. Listener
    // errors are folded to a logged null emission (house rule from Phase 1:
    // a listener error must never crash the app — see UserRepository.watchUser).
    fun watchRoom(roomId: String): Flow<Room?> = callbackFlow {
        val registration = rooms.document(roomId)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    Log.w(TAG, "rooms/$roomId snapshot listener error", error)
                    trySend(null)
                    return@addSnapshotListener
                }
                trySend(snapshot?.let { Room.fromSnapshot(it) })
            }
        awaitClose { registration.remove() }
    }

    /** Fetch rooms by id, chunked to respect Firestore's whereIn limit of 30. */
    suspend fun getRooms(roomIds: List<String>): List<Room> {
        if (roomIds.isEmpty()) return emptyList()
        val results = mutableListOf<Room>()
        for (chunk in roomIds.chunked(30)) {
            val query = rooms
                .whereIn(FieldPath.documentId(), chunk)
                .get()
                .await()
            results += query.documents.mapNotNull { Room.fromSnapshot(it) }
        }
        return results
    }

    // ===== Joining =====

    /**
     * Public room: instant join. Permission room: creates a JoinRequest.
     * Returns true if joined immediately, false if a request was created.
     *
     * Rules: the join-request doc id equals the requesting userId (dedupe;
     * also what lets the rules check isSelf on the subcollection doc).
     */
    suspend fun requestOrJoinRoom(
        room: Room,
        userId: String,
        userName: String,
        userPhotoUrl: String? = null,
    ): Boolean {
        if (room.isMember(userId)) return true

        if (room.visibility == RoomVisibility.PUBLIC) {
            addMember(room.id, userId)
            return true
        }

        // Permission room — create a join request (doc id = userId to dedupe).
        rooms.document(room.id)
            .collection("join_requests")
            .document(userId)
            .set(
                JoinRequest(
                    id = userId,
                    roomId = room.id,
                    userId = userId,
                    userName = userName,
                    userPhotoUrl = userPhotoUrl,
                    createdAt = Date(),
                ).toMap()
            )
            .await()
        return false
    }

    fun watchJoinRequests(roomId: String): Flow<List<JoinRequest>> = callbackFlow {
        val registration = rooms.document(roomId)
            .collection("join_requests")
            .orderBy("createdAt", Query.Direction.DESCENDING)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    Log.w(TAG, "rooms/$roomId/join_requests listener error", error)
                    trySend(emptyList())
                    return@addSnapshotListener
                }
                trySend(
                    snapshot?.documents.orEmpty().mapNotNull { JoinRequest.fromSnapshot(it) }
                )
            }
        awaitClose { registration.remove() }
    }

    /**
     * Any admin can approve. Adds the user as a member and removes the request.
     *
     * Rules (B13): the users/{userId} entry is a CROSS-USER write — legal
     * only because it touches roomIds alone. Do not add fields to it.
     */
    suspend fun approveJoinRequest(roomId: String, userId: String) {
        val batch = db.batch()
        batch.update(
            rooms.document(roomId),
            mapOf("memberIds" to FieldValue.arrayUnion(userId)),
        )
        batch.update(
            users.document(userId),
            mapOf("roomIds" to FieldValue.arrayUnion(roomId)),
        )
        batch.delete(rooms.document(roomId).collection("join_requests").document(userId))
        batch.commit().await()
    }

    suspend fun denyJoinRequest(roomId: String, userId: String) {
        rooms.document(roomId)
            .collection("join_requests")
            .document(userId)
            .delete()
            .await()
    }

    // Public-room self-join. Rules: memberIds-only diff on a public room
    // adding exactly [auth.uid]; users entry is self + roomIds only.
    private suspend fun addMember(roomId: String, userId: String) {
        val batch = db.batch()
        batch.update(
            rooms.document(roomId),
            mapOf("memberIds" to FieldValue.arrayUnion(userId)),
        )
        batch.update(
            users.document(userId),
            mapOf("roomIds" to FieldValue.arrayUnion(roomId)),
        )
        batch.commit().await()
    }

    // ===== Membership management =====

    /**
     * User leaves a room voluntarily. If they were the creator and there are
     * other admins, the room continues; if they were the only member, the
     * room is deleted (B13).
     *
     * Rules: for a non-admin leaver the adminIds arrayRemove is a no-op, so
     * the diff's affected keys collapse to ['memberIds'] removing exactly
     * [auth.uid] (self-leave branch); an admin leaver matches the isAdmin
     * branch instead. Same batch shape as the Dart app — keep it.
     */
    suspend fun leaveRoom(roomId: String, userId: String) {
        val roomDoc = rooms.document(roomId).get().await()
        val room = Room.fromSnapshot(roomDoc) ?: return

        if (room.memberIds.size <= 1) {
            // Last member — delete the room entirely.
            deleteRoom(roomId)
            return
        }

        val batch = db.batch()
        batch.update(
            rooms.document(roomId),
            mapOf(
                "memberIds" to FieldValue.arrayRemove(userId),
                "adminIds" to FieldValue.arrayRemove(userId),
            )
        )
        batch.update(
            users.document(userId),
            mapOf(
                "roomIds" to FieldValue.arrayRemove(roomId),
                "activeRoomIds" to FieldValue.arrayRemove(roomId),
                "favoriteRoomIds" to FieldValue.arrayRemove(roomId),
            )
        )
        batch.commit().await()
    }

    /** Admin kicks a member. Cross-user user-doc write: the 3 arrays ONLY (B13). */
    suspend fun kickMember(roomId: String, userId: String) {
        val batch = db.batch()
        batch.update(
            rooms.document(roomId),
            mapOf(
                "memberIds" to FieldValue.arrayRemove(userId),
                "adminIds" to FieldValue.arrayRemove(userId),
            )
        )
        batch.update(
            users.document(userId),
            mapOf(
                "roomIds" to FieldValue.arrayRemove(roomId),
                "activeRoomIds" to FieldValue.arrayRemove(roomId),
                "favoriteRoomIds" to FieldValue.arrayRemove(roomId),
            )
        )
        batch.commit().await()
    }

    suspend fun promoteToAdmin(roomId: String, userId: String) {
        rooms.document(roomId)
            .update("adminIds", FieldValue.arrayUnion(userId))
            .await()
    }

    suspend fun demoteAdmin(roomId: String, userId: String) {
        rooms.document(roomId)
            .update("adminIds", FieldValue.arrayRemove(userId))
            .await()
    }

    /**
     * Only the creator can rename (enforced by the rules' isCreator branch,
     * the only one allowing name/nameLower). Writes both `name` and
     * `nameLower` so search results stay in sync.
     */
    suspend fun renameRoom(roomId: String, newName: String) {
        rooms.document(roomId).update(
            mapOf(
                "name" to newName,
                "nameLower" to newName.lowercase(),
            )
        ).await()
    }

    /**
     * Case-insensitive prefix search across **public** rooms by name
     * (nameLower >= q, < q + '\uf8ff', limit 15 — B13). Returns up to [limit]
     * matches. Callers typically filter out rooms the current user is
     * already a member of.
     */
    suspend fun searchPublicRooms(query: String, limit: Int = 15): List<Room> {
        val q = query.trim().lowercase()
        if (q.isEmpty()) return emptyList()
        val snap = rooms
            .whereEqualTo("visibility", "public")
            .whereGreaterThanOrEqualTo("nameLower", q)
            .whereLessThan("nameLower", q + '\uf8ff')
            .orderBy("nameLower")
            .limit(limit.toLong())
            .get()
            .await()
        return snap.documents.mapNotNull { Room.fromSnapshot(it) }
    }

    /** Update the room's photo URL (null clears it). Allowed for any admin. */
    suspend fun updateRoomPhoto(roomId: String, photoUrl: String?) {
        // Two-arg overload: the map overload rejects null values in Kotlin.
        rooms.document(roomId).update("photoUrl", photoUrl).await()
    }

    /**
     * Best-effort: remove the room from every member's user doc, then delete
     * the room. Posts under rooms/{roomId}/posts are left for a cleanup
     * function (TTL or a Cloud Function) since client-side recursive deletes
     * aren't supported.
     *
     * Rules: delete allowed for admins or a sole member; each user entry is
     * a cross-user write scrubbing the 3 allowed arrays ONLY (B13).
     */
    suspend fun deleteRoom(roomId: String) {
        val roomDoc = rooms.document(roomId).get().await()
        val room = Room.fromSnapshot(roomDoc) ?: return

        val batch = db.batch()
        for (uid in room.memberIds) {
            batch.update(
                users.document(uid),
                mapOf(
                    "roomIds" to FieldValue.arrayRemove(roomId),
                    "activeRoomIds" to FieldValue.arrayRemove(roomId),
                    "favoriteRoomIds" to FieldValue.arrayRemove(roomId),
                )
            )
        }
        batch.delete(rooms.document(roomId))
        batch.commit().await()
    }

    // ===== Active / favorite rooms (per-user) =====

    suspend fun setActiveRooms(userId: String, roomIds: List<String>) {
        users.document(userId).update("activeRoomIds", roomIds).await()
    }

    suspend fun toggleFavoriteRoom(userId: String, roomId: String, favorite: Boolean) {
        users.document(userId).update(
            "favoriteRoomIds",
            if (favorite) FieldValue.arrayUnion(roomId) else FieldValue.arrayRemove(roomId),
        ).await()
    }

    // ===== Posts =====

    /**
     * Post the same image to multiple rooms (contract B9). One doc is written
     * per room (sharing the same imageUrl) so each room's post stream is
     * independent and security rules can be checked per-room — all in ONE
     * atomic WriteBatch.
     *
     * If a target room requires approval and the sender is neither an admin
     * nor a trusted user — or the sender is outside (or without GPS inside)
     * an active location lock (B2/B3) — the post is written with
     * `pending: true` and won't appear in the feed until an admin approves it.
     *
     * Returns a [PostResult] summarizing how many posts went live immediately
     * vs how many are pending approval, so the caller can show a helpful
     * snackbar. Room ids that don't resolve are skipped.
     */
    suspend fun postToRooms(
        roomIds: List<String>,
        senderId: String,
        senderName: String,
        senderPhotoUrl: String? = null,
        imageUrl: String,
        caption: String? = null,
        senderLat: Double? = null,
        senderLng: Double? = null,
    ): PostResult {
        if (roomIds.isEmpty()) return PostResult(live = 0, pending = 0)

        // Fetch each target room so we know its approval + geofence policy.
        val roomMap = getRooms(roomIds).associateBy { it.id }

        val nowMs = System.currentTimeMillis()
        val batch = db.batch()
        var live = 0
        var pending = 0

        for (roomId in roomIds) {
            val room = roomMap[roomId] ?: continue
            val isPending = room.requiresApprovalFor(
                senderId,
                senderLat = senderLat,
                senderLng = senderLng,
            )
            if (isPending) pending++ else live++

            val ref = rooms.document(roomId).collection("posts").document()
            batch.set(
                ref,
                RoomPost(
                    id = ref.id,
                    roomId = roomId,
                    senderId = senderId,
                    senderName = senderName,
                    senderPhotoUrl = senderPhotoUrl,
                    imageUrl = imageUrl,
                    caption = caption,
                    createdAtMs = nowMs,
                    // B4: expiresAt = createdAt + 6h, written at creation.
                    expiresAtMs = nowMs + POST_LIFETIME_MS,
                    pending = isPending,
                ).toMap(),
            )
        }
        batch.commit().await()
        // Update the posting streak in a separate transaction, fire-and-forget,
        // so that if the streak update fails the posts themselves still land
        // (Dart: unawaited(_bumpStreak(senderId))).
        repoScope.launch { bumpStreak(senderId) }
        return PostResult(live = live, pending = pending)
    }

    /**
     * Admin approves a pending post — flips its `pending` field to false so
     * it shows up in the feed (the only post-field update rules allow admins).
     */
    suspend fun approvePost(roomId: String, postId: String) {
        rooms.document(roomId)
            .collection("posts")
            .document(postId)
            .update("pending", false)
            .await()
    }

    /**
     * Admin rejects a pending post — deletes it. Same as deletePost but named
     * for clarity at the call site.
     */
    suspend fun rejectPost(roomId: String, postId: String) {
        deletePost(roomId = roomId, postId = postId)
    }

    /** Watch all pending posts in a room. Admin-only (security rules enforce). */
    fun watchPendingPosts(roomId: String, limit: Int = 50): Flow<List<RoomPost>> = callbackFlow {
        val registration = rooms.document(roomId)
            .collection("posts")
            .whereEqualTo("pending", true)
            .orderBy("createdAt", Query.Direction.DESCENDING)
            .limit(limit.toLong())
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    Log.w(TAG, "rooms/$roomId pending posts listener error", error)
                    trySend(emptyList())
                    return@addSnapshotListener
                }
                trySend(
                    snapshot?.documents.orEmpty().mapNotNull { RoomPost.fromSnapshot(it) }
                )
            }
        awaitClose { registration.remove() }
    }

    /** Admin toggles the room's post-approval requirement. */
    suspend fun setRequiresPostApproval(roomId: String, requires: Boolean) {
        rooms.document(roomId).update("requiresPostApproval", requires).await()
    }

    /**
     * Admin enables the geofence lock for a room with a pinned center and
     * allowed radius. Posts from outside the circle land in the pending queue.
     */
    suspend fun setLocationLock(roomId: String, lat: Double, lng: Double, radiusM: Int) {
        rooms.document(roomId).update(
            mapOf(
                "locationLockEnabled" to true,
                "locationLat" to lat,
                "locationLng" to lng,
                "locationRadiusM" to radiusM,
            )
        ).await()
    }

    /**
     * Admin disables the geofence lock. The pin/radius are kept in Firestore
     * so re-enabling restores the previous setup without re-pinning (B3).
     */
    suspend fun clearLocationLock(roomId: String) {
        rooms.document(roomId).update("locationLockEnabled", false).await()
    }

    /** Admin marks a user as trusted (bypasses post approval, NOT the geofence). */
    suspend fun setUserTrusted(roomId: String, userId: String, trusted: Boolean) {
        rooms.document(roomId).update(
            "trustedUserIds",
            if (trusted) FieldValue.arrayUnion(userId) else FieldValue.arrayRemove(userId),
        ).await()
    }

    /**
     * Read the current user doc and update `currentStreak` / `longestStreak`
     * / `lastPostDate` based on whether the last post was today, yesterday,
     * or earlier (or never). Streak bookkeeping is best-effort — never fail
     * a post over it (B9), hence the swallow-all catch.
     */
    private suspend fun bumpStreak(userId: String) {
        try {
            db.runTransaction { tx ->
                val ref = users.document(userId)
                val snap = tx.get(ref)
                if (!snap.exists()) return@runTransaction null
                val lastTs = snap.getTimestamp("lastPostDate")
                val current = (snap.get("currentStreak") as? Number)?.toInt() ?: 0
                val longest = (snap.get("longestStreak") as? Number)?.toInt() ?: 0

                val zone = ZoneId.systemDefault()
                val nowMs = System.currentTimeMillis()
                val today = streakDayKey(nowMs, zone)
                val last = lastTs?.toDate()?.time?.let { streakDayKey(it, zone) }

                val newStreak: Int
                if (last == today) {
                    // Already posted today — no change.
                    return@runTransaction null
                } else if (last != null && today - last == 1L) {
                    newStreak = current + 1
                } else {
                    newStreak = 1
                }

                tx.update(
                    ref,
                    mapOf(
                        "currentStreak" to newStreak,
                        "longestStreak" to if (newStreak > longest) newStreak else longest,
                        "lastPostDate" to Timestamp(Date(nowMs)),
                    )
                )
                null
            }.await()
        } catch (t: Throwable) {
            // Streak bookkeeping is best-effort. Never fail a post over it.
            Log.w(TAG, "streak bump for $userId failed (ignored)", t)
        }
    }

    /**
     * Epoch day of the LOCAL date, used to compare dates ignoring time
     * (same intent as Dart _dayKey: identify the local calendar day).
     * LocalDate.toEpochDay guarantees consecutive local days are exactly
     * 1 apart and same local day collides, in every zone — including
     * 23h/25h DST-transition days in zones that straddle UTC
     * (Europe/London), where the Dart-style floorDiv over local-midnight
     * millis drifts by the offset and breaks the ±1 invariant. Safe to
     * diverge from Dart's ~/ formula: dayKeys are never persisted (only
     * lastPostDate is stored); each client recomputes both keys with its
     * own formula inside the transaction.
     *
     * Pure function (no clock, no Firebase) so the streak math is
     * unit-testable — see StreakDayKeyTest.
     */
    internal fun streakDayKey(epochMs: Long, zone: ZoneId): Long =
        Instant.ofEpochMilli(epochMs)
            .atZone(zone)
            .toLocalDate()
            .toEpochDay()

    /**
     * Watch the latest non-expired posts from a single room. Expired and
     * still-pending posts are filtered CLIENT-SIDE — exactly like the Dart
     * feed — so we don't need a composite Firestore index (B4).
     */
    fun watchRoomPosts(roomId: String, limit: Int = 50): Flow<List<RoomPost>> = callbackFlow {
        val registration = rooms.document(roomId)
            .collection("posts")
            .orderBy("createdAt", Query.Direction.DESCENDING)
            .limit(limit.toLong())
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    Log.w(TAG, "rooms/$roomId posts listener error", error)
                    trySend(emptyList())
                    return@addSnapshotListener
                }
                trySend(
                    snapshot?.documents.orEmpty()
                        .mapNotNull { RoomPost.fromSnapshot(it) }
                        .filter { !it.isExpired && !it.pending }
                )
            }
        awaitClose { registration.remove() }
    }

    /**
     * One-shot fetch of recent visible posts in a room. Used by the
     * widget-refresh background task (no listener — we just want a snapshot).
     */
    suspend fun getRoomPostsOnce(roomId: String, limit: Int = 50): List<RoomPost> {
        val snap = rooms.document(roomId)
            .collection("posts")
            .orderBy("createdAt", Query.Direction.DESCENDING)
            .limit(limit.toLong())
            .get()
            .await()
        return snap.documents
            .mapNotNull { RoomPost.fromSnapshot(it) }
            .filter { !it.isExpired && !it.pending }
    }

    suspend fun deletePost(roomId: String, postId: String) {
        rooms.document(roomId)
            .collection("posts")
            .document(postId)
            .delete()
            .await()
    }

    /**
     * Toggle a like on a post. Adds [userId] to `likedBy` if [like],
     * otherwise removes it. [userId] MUST be the caller's own uid — the rules
     * only accept a likedBy diff of exactly [auth.uid] added or removed (B13).
     */
    suspend fun toggleLike(roomId: String, postId: String, userId: String, like: Boolean) {
        rooms.document(roomId).collection("posts").document(postId).update(
            "likedBy",
            if (like) FieldValue.arrayUnion(userId) else FieldValue.arrayRemove(userId),
        ).await()
    }

    // ===== Helpers =====

    // Room codes (B13): 6 chars from an alphabet omitting the confusable
    // 0/O/1/I, SecureRandom, uniqueness-checked with 8 retries.
    private const val CODE_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    private val secureRandom = SecureRandom()

    private fun randomCode(): String = buildString {
        repeat(6) { append(CODE_CHARS[secureRandom.nextInt(CODE_CHARS.length)]) }
    }

    private suspend fun generateUniqueCode(): String {
        repeat(8) {
            val candidate = randomCode()
            val existing = rooms
                .whereEqualTo("code", candidate)
                .limit(1)
                .get()
                .await()
            if (existing.isEmpty) return candidate
        }
        throw Exception("Could not generate a unique room code")
    }
}
