package com.momento.momento.data.model

import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentSnapshot
import java.util.Date

// Mirror of lib/models/join_request.dart — a pending request to join a
// permission room, stored at rooms/{roomId}/join_requests/{userId}. The doc
// id equals the requesting userId (dedupe: re-requesting overwrites rather
// than duplicating).
data class JoinRequest(
    val id: String,
    val roomId: String = "",
    val userId: String = "",
    val userName: String = "",
    val userPhotoUrl: String? = null,
    val createdAt: Date = Date(),
) {

    // Exact shape the Dart app writes (join_request.dart toMap) — including
    // the explicit null for userPhotoUrl.
    fun toMap(): Map<String, Any?> = mapOf(
        "roomId" to roomId,
        "userId" to userId,
        "userName" to userName,
        "userPhotoUrl" to userPhotoUrl,
        "createdAt" to Timestamp(createdAt),
    )

    companion object {
        // Missing fields degrade to the same defaults the Dart model uses:
        // strings -> "", createdAt -> now.
        fun fromSnapshot(doc: DocumentSnapshot): JoinRequest? {
            val data = doc.data ?: return null

            return JoinRequest(
                id = doc.id,
                roomId = data["roomId"] as? String ?: "",
                userId = data["userId"] as? String ?: "",
                userName = data["userName"] as? String ?: "",
                userPhotoUrl = data["userPhotoUrl"] as? String,
                createdAt = (data["createdAt"] as? Timestamp)?.toDate() ?: Date(),
            )
        }
    }
}
