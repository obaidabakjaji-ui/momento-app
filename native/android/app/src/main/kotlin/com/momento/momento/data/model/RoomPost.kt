package com.momento.momento.data.model

import com.google.firebase.Timestamp
import com.momento.momento.core.POST_LIFETIME_MS
import java.util.Date

// Mirror of lib/models/room_post.dart — a photo post inside a room. Posts
// expire POST_LIFETIME_MS (6h) after creation. When a user posts to multiple
// rooms, one RoomPost doc is written per room (all sharing the same image
// URL).
//
// Times are held as epoch MILLIS (Long) rather than Date: the widget
// pipeline contract (B4/B11) is millis-based (`momento_created_ats`, widget
// receiver expiry math), and Long round-trips without timezone surprises.
// Serialization still writes Firestore Timestamp fields exactly like the
// Dart app.
data class RoomPost(
    val id: String,
    val roomId: String = "",
    val senderId: String = "",
    val senderName: String = "",
    val senderPhotoUrl: String? = null,
    val imageUrl: String = "",
    val caption: String? = null,
    val createdAtMs: Long = System.currentTimeMillis(),
    // B4 convention: expiresAt = createdAt + 6h, written at post creation.
    val expiresAtMs: Long = createdAtMs + POST_LIFETIME_MS,
    val likedBy: List<String> = emptyList(),
    val pending: Boolean = false,
) {

    // Exact shape the Dart app writes (room_post.dart toMap) — including the
    // explicit nulls for senderPhotoUrl / caption, with createdAt/expiresAt
    // as Firestore Timestamps.
    fun toMap(): Map<String, Any?> = mapOf(
        "roomId" to roomId,
        "senderId" to senderId,
        "senderName" to senderName,
        "senderPhotoUrl" to senderPhotoUrl,
        "imageUrl" to imageUrl,
        "caption" to caption,
        "createdAt" to Timestamp(Date(createdAtMs)),
        "expiresAt" to Timestamp(Date(expiresAtMs)),
        "likedBy" to likedBy,
        "pending" to pending,
    )

    // Feed filters expired posts CLIENT-SIDE (B4) — expired docs still exist
    // in Firestore; there is deliberately no composite index for this.
    val isExpired: Boolean get() = System.currentTimeMillis() > expiresAtMs

    val likeCount: Int get() = likedBy.size
    fun likedByUser(uid: String): Boolean = likedBy.contains(uid)

    companion object {
        // Missing fields degrade to the same defaults the Dart model uses:
        // strings -> "", arrays -> empty, bools -> false, timestamps -> now.
        fun fromSnapshot(doc: com.google.firebase.firestore.DocumentSnapshot): RoomPost? {
            val data = doc.data ?: return null
            val nowMs = System.currentTimeMillis()

            return RoomPost(
                id = doc.id,
                roomId = data["roomId"] as? String ?: "",
                senderId = data["senderId"] as? String ?: "",
                senderName = data["senderName"] as? String ?: "",
                senderPhotoUrl = data["senderPhotoUrl"] as? String,
                imageUrl = data["imageUrl"] as? String ?: "",
                caption = data["caption"] as? String,
                createdAtMs = (data["createdAt"] as? Timestamp)?.toDate()?.time ?: nowMs,
                expiresAtMs = (data["expiresAt"] as? Timestamp)?.toDate()?.time ?: nowMs,
                likedBy = (data["likedBy"] as? List<*>)?.filterIsInstance<String>() ?: emptyList(),
                pending = data["pending"] as? Boolean ?: false,
            )
        }
    }
}
