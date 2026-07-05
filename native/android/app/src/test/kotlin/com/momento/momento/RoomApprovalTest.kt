package com.momento.momento

import com.momento.momento.core.POST_LIFETIME_MS
import com.momento.momento.data.model.PostResult
import com.momento.momento.data.model.Room
import com.momento.momento.data.model.RoomPost
import com.momento.momento.data.model.RoomVisibility
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Truth-table tests for Room.requiresApprovalFor — the client-side pending
 * computation that MUST agree with firestore.rules (contract B2): a post
 * create is allowed only when pending == true OR !room.requiresPostApproval
 * OR sender in adminIds OR sender in trustedUserIds. postToRooms writes all
 * posts in ONE atomic WriteBatch, so one mismatched pending rejects the
 * entire multi-room post.
 *
 * Also pins the B3 geofence semantics (fail CLOSED on missing GPS, fail
 * OPEN on an unconfigured lock) and the B4 expiry convention
 * (expiresAt - createdAt == POST_LIFETIME_MS).
 */
class RoomApprovalTest {

    private companion object {
        const val ADMIN = "admin-uid"
        const val TRUSTED = "trusted-uid"
        const val MEMBER = "member-uid"

        // Lock pin + a point ~1 degree of latitude away (~111.19 km).
        const val PIN_LAT = 37.0
        const val PIN_LNG = -122.0
        const val RADIUS_M = 200
        const val INSIDE_LAT = PIN_LAT // distance 0 from the pin
        const val INSIDE_LNG = PIN_LNG
        const val OUTSIDE_LAT = PIN_LAT + 1.0
        const val OUTSIDE_LNG = PIN_LNG
    }

    private fun room(
        approval: Boolean = false,
        lockEnabled: Boolean = false,
        lat: Double? = null,
        lng: Double? = null,
        radiusM: Int? = null,
    ) = Room(
        id = "room-1",
        name = "Test Room",
        code = "ABC234",
        visibility = RoomVisibility.PUBLIC,
        createdBy = ADMIN,
        adminIds = listOf(ADMIN),
        memberIds = listOf(ADMIN, TRUSTED, MEMBER),
        requiresPostApproval = approval,
        trustedUserIds = listOf(TRUSTED),
        locationLockEnabled = lockEnabled,
        locationLat = lat,
        locationLng = lng,
        locationRadiusM = radiusM,
    )

    private fun lockedRoom(approval: Boolean) =
        room(approval, lockEnabled = true, lat = PIN_LAT, lng = PIN_LNG, radiusM = RADIUS_M)

    // Geofence scenarios: (room, senderLat, senderLng) per approval setting.
    private enum class Geo { NO_LOCK, INSIDE, OUTSIDE, LOCK_NULL_GPS }

    private fun check(uid: String, approval: Boolean, geo: Geo, expected: Boolean) {
        val (r, lat, lng) = when (geo) {
            Geo.NO_LOCK -> Triple(room(approval), INSIDE_LAT, INSIDE_LNG)
            Geo.INSIDE -> Triple(lockedRoom(approval), INSIDE_LAT, INSIDE_LNG)
            Geo.OUTSIDE -> Triple(lockedRoom(approval), OUTSIDE_LAT, OUTSIDE_LNG)
            Geo.LOCK_NULL_GPS -> Triple(lockedRoom(approval), null, null)
        }
        assertEquals(
            "uid=$uid approval=$approval geo=$geo",
            expected,
            r.requiresApprovalFor(uid, senderLat = lat, senderLng = lng),
        )
    }

    // ===== Full truth table: role x approval x geofence (24 combinations) =====

    @Test
    fun `admin never requires approval - bypasses approval AND geofence`() {
        for (approval in listOf(true, false)) {
            for (geo in Geo.values()) {
                check(ADMIN, approval, geo, expected = false)
            }
        }
    }

    @Test
    fun `trusted bypasses approval requirement but is STILL geofenced`() {
        // Identical outcomes whether approval is on or off: trust neutralizes
        // the approval dimension, never the geofence.
        for (approval in listOf(true, false)) {
            check(TRUSTED, approval, Geo.NO_LOCK, expected = false)
            check(TRUSTED, approval, Geo.INSIDE, expected = false)
            check(TRUSTED, approval, Geo.OUTSIDE, expected = true)
            check(TRUSTED, approval, Geo.LOCK_NULL_GPS, expected = true)
        }
    }

    @Test
    fun `plain member with approval ON always pends - geofence never rescues`() {
        // needsApproval short-circuits before the geofence: even a member
        // standing on the pin is pended.
        for (geo in Geo.values()) {
            check(MEMBER, approval = true, geo = geo, expected = true)
        }
    }

    @Test
    fun `plain member with approval OFF follows the geofence`() {
        check(MEMBER, approval = false, geo = Geo.NO_LOCK, expected = false)
        check(MEMBER, approval = false, geo = Geo.INSIDE, expected = false)
        check(MEMBER, approval = false, geo = Geo.OUTSIDE, expected = true)
        check(MEMBER, approval = false, geo = Geo.LOCK_NULL_GPS, expected = true)
    }

    // ===== B3: explicit fail-closed / fail-open pins =====

    @Test
    fun `B3 - active lock with null GPS fails CLOSED (pending)`() {
        // Camera flow: GPS denied/timeout/disabled -> post proceeds with
        // null coords and must land pending, never live.
        assertTrue(lockedRoom(approval = false).requiresApprovalFor(MEMBER))
        assertTrue(
            lockedRoom(approval = false)
                .requiresApprovalFor(TRUSTED, senderLat = null, senderLng = null),
        )
    }

    @Test
    fun `B3 - admin bypasses the geofence even outside with null GPS`() {
        assertFalse(lockedRoom(approval = true).requiresApprovalFor(ADMIN))
        assertFalse(
            lockedRoom(approval = true)
                .requiresApprovalFor(ADMIN, senderLat = OUTSIDE_LAT, senderLng = OUTSIDE_LNG),
        )
    }

    @Test
    fun `B3 - partially configured lock is inert (enabled but no pin or radius)`() {
        // Lock enabled but radius missing -> hasActiveLocationLock false ->
        // not outside, even with null GPS.
        val noRadius = room(lockEnabled = true, lat = PIN_LAT, lng = PIN_LNG, radiusM = null)
        assertFalse(noRadius.hasActiveLocationLock)
        assertFalse(noRadius.requiresApprovalFor(MEMBER))

        val noPin = room(lockEnabled = true, lat = null, lng = null, radiusM = RADIUS_M)
        assertFalse(noPin.hasActiveLocationLock)
        assertFalse(noPin.requiresApprovalFor(MEMBER))
    }

    @Test
    fun `B3 - cleared lock (disabled, pin and radius kept) stops geofencing`() {
        // clearLocationLock only flips locationLockEnabled=false — pin +
        // radius are retained. The kept values must not keep enforcing.
        val cleared = room(lockEnabled = false, lat = PIN_LAT, lng = PIN_LNG, radiusM = RADIUS_M)
        assertFalse(cleared.hasActiveLocationLock)
        assertFalse(
            cleared.requiresApprovalFor(MEMBER, senderLat = OUTSIDE_LAT, senderLng = OUTSIDE_LNG),
        )
        assertFalse(cleared.requiresApprovalFor(MEMBER)) // null GPS is fine too
    }

    // ===== Haversine sanity: ~111.19 km per degree of latitude =====

    @Test
    fun `haversine - one degree of latitude is about 111_195 m`() {
        // R=6371000 m -> 1 deg latitude = 6371000 * pi/180 = 111194.93 m.
        // Bracket it via the geofence: radius one meter below -> outside,
        // one meter above -> inside.
        val justUnder = room(lockEnabled = true, lat = PIN_LAT, lng = PIN_LNG, radiusM = 111_194)
        val justOver = room(lockEnabled = true, lat = PIN_LAT, lng = PIN_LNG, radiusM = 111_195)
        assertTrue(
            justUnder.requiresApprovalFor(MEMBER, senderLat = OUTSIDE_LAT, senderLng = OUTSIDE_LNG),
        )
        assertFalse(
            justOver.requiresApprovalFor(MEMBER, senderLat = OUTSIDE_LAT, senderLng = OUTSIDE_LNG),
        )
    }

    // ===== B4: expiry convention =====

    @Test
    fun `B4 - POST_LIFETIME_MS is exactly six hours`() {
        assertEquals(21_600_000L, POST_LIFETIME_MS)
    }

    @Test
    fun `B4 - expiresAt minus createdAt equals POST_LIFETIME_MS by construction`() {
        val createdAtMs = 1_750_000_000_000L
        val post = RoomPost(id = "p1", roomId = "room-1", createdAtMs = createdAtMs)
        assertEquals(POST_LIFETIME_MS, post.expiresAtMs - post.createdAtMs)
    }

    @Test
    fun `B4 - isExpired flips strictly after expiresAt`() {
        val now = System.currentTimeMillis()
        val fresh = RoomPost(id = "p1", roomId = "room-1", createdAtMs = now)
        val stale = RoomPost(id = "p2", roomId = "room-1", createdAtMs = now - POST_LIFETIME_MS - 1_000)
        assertFalse(fresh.isExpired)
        assertTrue(stale.isExpired)
    }

    // ===== RoomPost like helpers + PostResult shape =====

    @Test
    fun `likedBy helpers mirror the Dart model`() {
        val post = RoomPost(id = "p1", roomId = "room-1", likedBy = listOf(MEMBER, TRUSTED))
        assertEquals(2, post.likeCount)
        assertTrue(post.likedByUser(MEMBER))
        assertFalse(post.likedByUser(ADMIN))

        val unliked = RoomPost(id = "p2", roomId = "room-1")
        assertEquals(0, unliked.likeCount)
        assertFalse(unliked.likedByUser(MEMBER))
    }

    @Test
    fun `PostResult carries live and pending counts`() {
        val result = PostResult(live = 2, pending = 1)
        assertEquals(2, result.live)
        assertEquals(1, result.pending)
    }
}
