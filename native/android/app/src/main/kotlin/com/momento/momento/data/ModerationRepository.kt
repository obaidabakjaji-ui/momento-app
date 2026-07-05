package com.momento.momento.data

import com.google.firebase.Timestamp
import com.google.firebase.firestore.CollectionReference
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import java.util.Date
import kotlinx.coroutines.tasks.await

// Block / unblock users and submit reports for manual review — mirror of
// lib/services/moderation_service.dart.
//
// Reports go to a top-level `reports` collection that is intentionally
// WRITE-ONLY for clients (firestore.rules: read false, create only when
// reporterId == auth.uid and type in ['user','post','room']); reviewers read
// it via the Firebase Console. Field shapes below must stay byte-identical to
// what the Dart client writes — including the explicit nulls — so both clients
// produce interchangeable report docs during the migration.
object ModerationRepository {

    private val db: FirebaseFirestore get() = FirebaseFirestore.getInstance()

    private val users: CollectionReference get() = db.collection("users")
    private val reports: CollectionReference get() = db.collection("reports")

    // Rules note: blockedUserIds is only writable through the isSelf branch of
    // the users rules (the cross-user branch allows roomIds/activeRoomIds/
    // favoriteRoomIds ONLY) — currentUserId must be the signed-in uid.
    suspend fun blockUser(currentUserId: String, targetUserId: String) {
        users.document(currentUserId)
            .update("blockedUserIds", FieldValue.arrayUnion(targetUserId))
            .await()
    }

    suspend fun unblockUser(currentUserId: String, targetUserId: String) {
        users.document(currentUserId)
            .update("blockedUserIds", FieldValue.arrayRemove(targetUserId))
            .await()
    }

    // Report a user. Optionally tied to a specific post / room for context.
    // reporterId must be the caller's own uid (rules enforce it).
    suspend fun reportUser(
        reporterId: String,
        reportedUserId: String,
        roomId: String? = null,
        postId: String? = null,
        reason: String? = null,
    ) {
        reports.add(
            mapOf(
                "type" to "user",
                "reporterId" to reporterId,
                "reportedUserId" to reportedUserId,
                "roomId" to roomId,
                "postId" to postId,
                "reason" to reason,
                "createdAt" to Timestamp(Date()),
            )
        ).await()
    }

    // Report a community for manual review.
    suspend fun reportRoom(
        reporterId: String,
        roomId: String,
        reason: String? = null,
    ) {
        reports.add(
            mapOf(
                "type" to "room",
                "reporterId" to reporterId,
                "roomId" to roomId,
                "reason" to reason,
                "createdAt" to Timestamp(Date()),
            )
        ).await()
    }

    // Report a specific post. Stores both the post id and the sender id so a
    // reviewer can act on either.
    suspend fun reportPost(
        reporterId: String,
        reportedUserId: String,
        roomId: String,
        postId: String,
        reason: String? = null,
    ) {
        reports.add(
            mapOf(
                "type" to "post",
                "reporterId" to reporterId,
                "reportedUserId" to reportedUserId,
                "roomId" to roomId,
                "postId" to postId,
                "reason" to reason,
                "createdAt" to Timestamp(Date()),
            )
        ).await()
    }
}
