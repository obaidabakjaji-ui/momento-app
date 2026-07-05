package com.momento.momento.data.model

import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentSnapshot
import java.util.Date
import kotlin.math.PI
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.sqrt

// Firestore stores visibility as the strings "public" / "permission".
// Dart parse rule (room.dart): anything that isn't exactly "permission"
// (including a missing field) is public.
enum class RoomVisibility(val firestoreValue: String) {
    PUBLIC("public"),
    PERMISSION("permission");

    companion object {
        fun fromFirestore(value: Any?): RoomVisibility =
            if (value == PERMISSION.firestoreValue) PERMISSION else PUBLIC
    }
}

// Mirror of lib/models/room.dart — Firestore field names, defaults, and null
// tolerance must stay identical so the Flutter and native clients can read
// each other's room docs during the migration (missing arrays -> empty,
// missing bools -> false).
data class Room(
    val id: String,
    val name: String = "",
    val code: String = "",
    val visibility: RoomVisibility = RoomVisibility.PUBLIC,
    val photoUrl: String? = null,
    val createdBy: String = "",
    val createdAt: Date = Date(),
    val adminIds: List<String> = emptyList(),
    val memberIds: List<String> = emptyList(),
    val requiresPostApproval: Boolean = false,
    val trustedUserIds: List<String> = emptyList(),
    // Location lock: when enabled, posts from outside the pinned circle are
    // auto-pended for admin approval. Admin sets the pin + radius from the
    // room settings screen. clearLocationLock only flips
    // locationLockEnabled=false — pin + radius are kept so re-enabling
    // restores them (contract B3).
    val locationLockEnabled: Boolean = false,
    val locationLat: Double? = null,
    val locationLng: Double? = null,
    val locationRadiusM: Int? = null,
) {

    // Exact shape the Dart app writes (room.dart toMap) — including the
    // explicit nulls and the derived nameLower used by the public-room
    // prefix search.
    fun toMap(): Map<String, Any?> = mapOf(
        "name" to name,
        "nameLower" to name.lowercase(),
        "code" to code,
        "visibility" to visibility.firestoreValue,
        "photoUrl" to photoUrl,
        "createdBy" to createdBy,
        "createdAt" to Timestamp(createdAt),
        "adminIds" to adminIds,
        "memberIds" to memberIds,
        "requiresPostApproval" to requiresPostApproval,
        "trustedUserIds" to trustedUserIds,
        "locationLockEnabled" to locationLockEnabled,
        "locationLat" to locationLat,
        "locationLng" to locationLng,
        "locationRadiusM" to locationRadiusM,
    )

    val memberCount: Int get() = memberIds.size
    fun isMember(uid: String): Boolean = memberIds.contains(uid)
    fun isAdmin(uid: String): Boolean = adminIds.contains(uid)
    fun isCreator(uid: String): Boolean = createdBy == uid
    fun isTrusted(uid: String): Boolean = trustedUserIds.contains(uid)

    // True if the lock is configured (enabled + pin + radius all present).
    val hasActiveLocationLock: Boolean
        get() = locationLockEnabled &&
            locationLat != null &&
            locationLng != null &&
            locationRadiusM != null

    /**
     * Whether a post by [uid] from [senderLat]/[senderLng] should land
     * `pending: true`. Admins bypass everything (including the geofence);
     * trusted users bypass the approval requirement but still get geofenced.
     * A missing GPS reading while the lock is active is treated as
     * out-of-area (fail CLOSED — contract B3).
     *
     * Verbatim port of room.dart requiresApprovalFor. The Firestore rules
     * (firestore.rules posts create) and this computation MUST agree: a post
     * create is allowed only when pending == true OR !requiresPostApproval
     * OR sender in adminIds OR sender in trustedUserIds. postToRooms writes
     * all posts in ONE atomic WriteBatch — one mismatched pending rejects
     * the entire multi-room post (contract B2).
     */
    fun requiresApprovalFor(
        uid: String,
        senderLat: Double? = null,
        senderLng: Double? = null,
    ): Boolean {
        if (isAdmin(uid)) return false
        val needsApproval = requiresPostApproval && !isTrusted(uid)
        if (needsApproval) return true
        return isOutsideGeofence(senderLat, senderLng)
    }

    private fun isOutsideGeofence(senderLat: Double?, senderLng: Double?): Boolean {
        // Lock not fully configured -> not outside (no geofence to enforce).
        if (!hasActiveLocationLock) return false
        // Active lock but no GPS fix -> outside (fail closed, B3).
        if (senderLat == null || senderLng == null) return true
        val dist = haversineMeters(
            senderLat,
            senderLng,
            locationLat!!,
            locationLng!!,
        )
        return dist > locationRadiusM!!
    }

    companion object {

        // Returns null for a missing doc (Dart callers check doc.exists
        // first; here the null return carries that case). Missing fields
        // degrade to the same defaults the Dart model uses.
        fun fromSnapshot(doc: DocumentSnapshot): Room? {
            val data = doc.data ?: return null

            fun strings(key: String): List<String> =
                (data[key] as? List<*>)?.filterIsInstance<String>() ?: emptyList()

            return Room(
                id = doc.id,
                name = data["name"] as? String ?: "",
                code = data["code"] as? String ?: "",
                visibility = RoomVisibility.fromFirestore(data["visibility"]),
                photoUrl = data["photoUrl"] as? String,
                createdBy = data["createdBy"] as? String ?: "",
                createdAt = (data["createdAt"] as? Timestamp)?.toDate() ?: Date(),
                adminIds = strings("adminIds"),
                memberIds = strings("memberIds"),
                requiresPostApproval = data["requiresPostApproval"] as? Boolean ?: false,
                trustedUserIds = strings("trustedUserIds"),
                locationLockEnabled = data["locationLockEnabled"] as? Boolean ?: false,
                // Firestore hands numbers back as Long or Double — go
                // through Number so both decode (Dart: `as num?`).
                locationLat = (data["locationLat"] as? Number)?.toDouble(),
                locationLng = (data["locationLng"] as? Number)?.toDouble(),
                locationRadiusM = (data["locationRadiusM"] as? Number)?.toInt(),
            )
        }

        private const val EARTH_RADIUS_M = 6371000.0

        private fun haversineMeters(
            lat1: Double,
            lng1: Double,
            lat2: Double,
            lng2: Double,
        ): Double {
            val dLat = deg2rad(lat2 - lat1)
            val dLng = deg2rad(lng2 - lng1)
            val a = sin(dLat / 2) * sin(dLat / 2) +
                cos(deg2rad(lat1)) *
                cos(deg2rad(lat2)) *
                sin(dLng / 2) *
                sin(dLng / 2)
            val c = 2 * atan2(sqrt(a), sqrt(1 - a))
            return EARTH_RADIUS_M * c
        }

        private fun deg2rad(deg: Double): Double = deg * (PI / 180)
    }
}
