package com.momento.momento.core

/**
 * Post lifetime — the 6-hour expiry (contract B4).
 *
 * This single constant is the source of truth for all three sites that used
 * to hold their own copy of "6 hours" in the Flutter app:
 *  1. Post creation: `expiresAt = createdAt + POST_LIFETIME_MS` (RoomRepository.postToRooms;
 *     was `Duration(hours: 6)` in room_service.dart).
 *  2. Feed filter: expired posts are dropped CLIENT-SIDE from `expiresAt`
 *     (deliberate — avoids a composite Firestore index; expired docs remain
 *     in Firestore).
 *  3. Widget receiver: computes expiry as `createdAtMs + POST_LIFETIME_MS`
 *     (it never sees the `expiresAt` field).
 * Change it here or nowhere — a drift silently desyncs feed vs widget expiry.
 */
const val POST_LIFETIME_MS = 6L * 60L * 60L * 1000L
