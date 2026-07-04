package com.momento.momento.data.model

import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentSnapshot
import java.util.Date

// Mirror of lib/models/app_user.dart — Firestore field names, defaults, and
// null tolerance must stay identical so the Flutter and native clients can
// read each other's user docs during the migration.
data class AppUser(
    val uid: String,
    val email: String = "",
    val displayName: String = "",
    val photoUrl: String? = null,
    val roomIds: List<String> = emptyList(),
    val activeRoomIds: List<String> = emptyList(),
    val favoriteRoomIds: List<String> = emptyList(),
    val blockedUserIds: List<String> = emptyList(),
    val hasSeenOnboarding: Boolean = false,
    val currentStreak: Int = 0,
    val longestStreak: Int = 0,
    val lastPostDate: Date? = null,
    val createdAt: Date = Date(),
) {

    val hasRooms: Boolean get() = roomIds.isNotEmpty()

    fun hasBlocked(uid: String): Boolean = blockedUserIds.contains(uid)

    // Exact shape the Dart app writes (app_user.dart toMap) — including the
    // explicit nulls for photoUrl / lastPostDate.
    fun toMap(): Map<String, Any?> = mapOf(
        "email" to email,
        "displayName" to displayName,
        "photoUrl" to photoUrl,
        "roomIds" to roomIds,
        "activeRoomIds" to activeRoomIds,
        "favoriteRoomIds" to favoriteRoomIds,
        "blockedUserIds" to blockedUserIds,
        "hasSeenOnboarding" to hasSeenOnboarding,
        "currentStreak" to currentStreak,
        "longestStreak" to longestStreak,
        "lastPostDate" to lastPostDate?.let { Timestamp(it) },
        "createdAt" to Timestamp(createdAt),
    )

    companion object {
        // Returns null for a missing doc (Dart callers check doc.exists first;
        // here the null return carries that case). Missing fields degrade to
        // the same defaults the Dart model uses: arrays -> empty, bools ->
        // false, ints -> 0, createdAt -> now.
        fun fromSnapshot(doc: DocumentSnapshot): AppUser? {
            val data = doc.data ?: return null

            fun strings(key: String): List<String> =
                (data[key] as? List<*>)?.filterIsInstance<String>() ?: emptyList()

            return AppUser(
                uid = doc.id,
                email = data["email"] as? String ?: "",
                displayName = data["displayName"] as? String ?: "",
                photoUrl = data["photoUrl"] as? String,
                roomIds = strings("roomIds"),
                activeRoomIds = strings("activeRoomIds"),
                favoriteRoomIds = strings("favoriteRoomIds"),
                blockedUserIds = strings("blockedUserIds"),
                hasSeenOnboarding = data["hasSeenOnboarding"] as? Boolean ?: false,
                // Firestore hands numbers back as Long — go through Number so
                // both Long and Int decode.
                currentStreak = (data["currentStreak"] as? Number)?.toInt() ?: 0,
                longestStreak = (data["longestStreak"] as? Number)?.toInt() ?: 0,
                lastPostDate = (data["lastPostDate"] as? Timestamp)?.toDate(),
                createdAt = (data["createdAt"] as? Timestamp)?.toDate() ?: Date(),
            )
        }
    }
}
