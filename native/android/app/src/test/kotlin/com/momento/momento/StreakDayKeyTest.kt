package com.momento.momento

import com.momento.momento.data.RoomRepository
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.ZoneOffset
import java.time.ZonedDateTime
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Pins the streak dayKey math (contract B9): dayKey = epoch day of the
 * LOCAL date (`LocalDate.toEpochDay()`), matching the intent of Dart
 * _dayKey (identify the local calendar day; keys are never persisted, so
 * the exact formula may diverge). The streak transaction compares keys:
 *   same day        -> no change (double post),
 *   today - last==1 -> currentStreak + 1,
 *   anything else   -> reset to 1.
 * So the invariants that matter are: same local day == same key, and
 * consecutive LOCAL days differ by exactly 1 — in every zone, including
 * 23h/25h DST-transition days and month/year boundaries.
 */
class StreakDayKeyTest {

    private companion object {
        val UTC: ZoneId = ZoneOffset.UTC
        val PARIS: ZoneId = ZoneId.of("Europe/Paris")
        val NEW_YORK: ZoneId = ZoneId.of("America/New_York")
        val LONDON: ZoneId = ZoneId.of("Europe/London")
    }

    private fun key(
        zone: ZoneId,
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 12,
        minute: Int = 0,
    ): Long {
        val ms = ZonedDateTime.of(year, month, day, hour, minute, 0, 0, zone)
            .toInstant()
            .toEpochMilli()
        return RoomRepository.streakDayKey(ms, zone)
    }

    // ===== Same-day double post -> same key (streak unchanged) =====

    @Test
    fun `same local day gives the same key regardless of time of day`() {
        val morning = key(PARIS, 2026, 7, 4, hour = 0, minute = 5)
        val noon = key(PARIS, 2026, 7, 4, hour = 12)
        val night = key(PARIS, 2026, 7, 4, hour = 23, minute = 55)
        assertEquals(morning, noon)
        assertEquals(morning, night)
    }

    @Test
    fun `local midnight boundary splits keys even within the same UTC day`() {
        // Paris in winter is UTC+1: 22:30Z is 23:30 local (Jan 15) but
        // 23:30Z is already 00:30 local on Jan 16 — different local days,
        // same UTC day. The key must follow the LOCAL day.
        val lateJan15 = RoomRepository.streakDayKey(
            Instant.parse("2026-01-15T22:30:00Z").toEpochMilli(), PARIS,
        )
        val earlyJan16 = RoomRepository.streakDayKey(
            Instant.parse("2026-01-15T23:30:00Z").toEpochMilli(), PARIS,
        )
        assertEquals(lateJan15 + 1, earlyJan16)
    }

    // ===== Consecutive local days -> difference exactly 1 (streak + 1) =====

    @Test
    fun `consecutive local days differ by exactly one`() {
        assertEquals(key(UTC, 2026, 7, 3) + 1, key(UTC, 2026, 7, 4))
        assertEquals(key(PARIS, 2026, 7, 3) + 1, key(PARIS, 2026, 7, 4))
        assertEquals(key(NEW_YORK, 2026, 7, 3) + 1, key(NEW_YORK, 2026, 7, 4))
    }

    // ===== Gap -> difference != 1 (streak resets to 1) =====

    @Test
    fun `a multi-day gap is never mistaken for a consecutive day`() {
        val last = key(PARIS, 2026, 7, 1)
        val today = key(PARIS, 2026, 7, 4)
        assertEquals(3L, today - last)
        assertNotEquals(1L, today - last) // transaction takes the reset branch
    }

    // ===== Month / year boundaries =====

    @Test
    fun `month boundary is consecutive`() {
        assertEquals(key(NEW_YORK, 2026, 1, 31) + 1, key(NEW_YORK, 2026, 2, 1))
        assertEquals(key(PARIS, 2026, 4, 30) + 1, key(PARIS, 2026, 5, 1))
        // Leap-year February (2028): Feb 29 exists and chains both ways.
        assertEquals(key(UTC, 2028, 2, 28) + 1, key(UTC, 2028, 2, 29))
        assertEquals(key(UTC, 2028, 2, 29) + 1, key(UTC, 2028, 3, 1))
    }

    @Test
    fun `year boundary is consecutive`() {
        assertEquals(key(PARIS, 2025, 12, 31) + 1, key(PARIS, 2026, 1, 1))
        assertEquals(key(NEW_YORK, 2025, 12, 31) + 1, key(NEW_YORK, 2026, 1, 1))
    }

    // ===== DST transitions (Europe/Paris) =====

    @Test
    fun `spring forward day (23h, Paris 2026-03-29) chains normally`() {
        // 2026-03-29 is the last Sunday of March: 02:00 CET -> 03:00 CEST,
        // so the day is only 23h long. Keys must still be consecutive on
        // both sides of the transition day.
        val sat = key(PARIS, 2026, 3, 28)
        val sun = key(PARIS, 2026, 3, 29, hour = 15) // after the jump
        val mon = key(PARIS, 2026, 3, 30)
        assertEquals(sat + 1, sun)
        assertEquals(sun + 1, mon)
    }

    @Test
    fun `posts before and after the spring-forward jump share one key`() {
        // 01:59 CET and 03:01 CEST are two minutes apart on the wall clock
        // of the same local day — a double post, not a new streak day.
        val beforeJump = key(PARIS, 2026, 3, 29, hour = 1, minute = 59)
        val afterJump = key(PARIS, 2026, 3, 29, hour = 3, minute = 1)
        assertEquals(beforeJump, afterJump)
    }

    @Test
    fun `fall back day (25h, Paris 2026-10-25) chains normally`() {
        // Last Sunday of October: 03:00 CEST -> 02:00 CET, a 25h day.
        val sat = key(PARIS, 2026, 10, 24)
        val sun = key(PARIS, 2026, 10, 25, hour = 15) // after the repeat hour
        val mon = key(PARIS, 2026, 10, 26)
        assertEquals(sat + 1, sun)
        assertEquals(sun + 1, mon)
    }

    // ===== DST transitions in a zone that straddles UTC (Europe/London) =====
    // London is UTC+0 in winter and UTC+1 (BST) in summer, so local midnight
    // sits on either side of the UTC day boundary depending on season. The
    // old floorDiv-over-local-midnight-millis formula produced key deltas of
    // 2 (fall back) and 0 (spring forward) across these transitions.

    @Test
    fun `spring forward day (23h, London 2026-03-29) chains normally`() {
        // Last Sunday of March: 01:00 GMT -> 02:00 BST, a 23h day.
        val sat = key(LONDON, 2026, 3, 28)
        val sun = key(LONDON, 2026, 3, 29, hour = 15) // after the jump
        val mon = key(LONDON, 2026, 3, 30)
        assertEquals(sat + 1, sun)
        assertEquals(sun + 1, mon)
    }

    @Test
    fun `fall back day (25h, London 2026-10-25) chains normally`() {
        // Last Sunday of October: 02:00 BST -> 01:00 GMT, a 25h day.
        val sat = key(LONDON, 2026, 10, 24)
        val sun = key(LONDON, 2026, 10, 25, hour = 15) // after the repeat hour
        val mon = key(LONDON, 2026, 10, 26)
        assertEquals(sat + 1, sun)
        assertEquals(sun + 1, mon)
    }

    // ===== Absolute anchor =====

    @Test
    fun `UTC key equals the local date's epoch day`() {
        // For UTC the Dart formula collapses to plain epochDay — anchors the
        // absolute value, not just the deltas.
        val date = LocalDate.of(2026, 7, 4)
        assertEquals(date.toEpochDay(), key(UTC, 2026, 7, 4))
        assertEquals(0L, RoomRepository.streakDayKey(0L, UTC))
    }

    @Test
    fun `keys are zone-consistent for the same wall-clock date`() {
        // The key is the LOCAL date's epoch day in every zone — offset never
        // leaks into the absolute value. Pin the absolutes so a refactor to
        // a different rounding mode (e.g. the old Dart-style floorDiv over
        // local-midnight millis, which drifted by the zone offset) fails
        // loudly.
        val epochDay = LocalDate.of(2026, 7, 4).toEpochDay()
        assertEquals(epochDay, key(PARIS, 2026, 7, 4)) // UTC+2 in July
        assertEquals(epochDay, key(NEW_YORK, 2026, 7, 4)) // UTC-4 in July
        assertTrue(key(UTC, 2026, 7, 4) == epochDay)
    }
}
