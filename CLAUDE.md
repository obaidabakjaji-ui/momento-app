# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Quick Reference

```bash
# Install Flutter dependencies
flutter pub get

# Run on simulator (open Simulator app first)
open -a Simulator
flutter run

# Run on connected device
flutter run

# Build iOS for simulator (MUST NOT use --no-codesign — see iOS Simulator section)
flutter build ios --simulator --debug

# Build iOS for device (debug)
flutter build ios --debug

# Clean and rebuild
flutter clean && flutter pub get && cd ios && pod install && cd ..

# iOS pod install (after adding dependencies)
cd ios && pod install && cd ..

# Install + launch built simulator binary on a booted simulator
SIM=$(xcrun simctl list devices booted | grep -oE '[0-9A-F-]{36}' | head -1)
xcrun simctl uninstall "$SIM" com.mbak4.momento
xcrun simctl install   "$SIM" build/ios/iphonesimulator/Runner.app
xcrun simctl launch    "$SIM" com.mbak4.momento
```

Flutter is installed at `~/flutter/bin` — if `flutter` command is not found:
```bash
export PATH="$PATH:$HOME/flutter/bin"
```

## Architecture

The app is a Flutter social photo-sharing app ("Momento") with Firebase backend. Sharing model is **Rooms** — users create or join group "rooms" by code, post photos that expire after 6 hours, and see a merged feed from their active rooms. There is no friend graph.

**Auth + onboarding flow**: `main.dart`'s `AuthGate` uses `StreamBuilder` on `FirebaseAuth.userChanges()` (NOT `authStateChanges()` — see note below), then routes:
1. unauthenticated → `AuthScreen`
2. authenticated but `emailVerified == false` (email/password accounts only — Google sign-ins come back verified) → `VerifyEmailScreen` (hard gate, no app access until 6-digit code is entered)
3. verified but `hasSeenOnboarding == false` → `OnboardingScreen`
4. otherwise → `HomeScreen`

**Why `userChanges()` instead of `authStateChanges()`**: when the verify Cloud Function flips `emailVerified` to true and the client calls `User.reload()`, only `userChanges()` (and `idTokenChanges()`) re-emit the user. `authStateChanges()` only fires on sign-in/out, so the gate would never re-route after verification.

**Service layer** (`lib/services/`):
- `auth_service.dart` — Firebase Auth + Google Sign-In; creates user doc on first sign-in. Auth methods: `sendPasswordResetEmail`, `reloadCurrentUser`, `isEmailVerified`, `deleteAccount` (cascades through `leaveRoom` for each membership before calling `user.delete()`; throws `requires-recent-login` if Firebase needs reauth — UI handles). Email-code verification: `requestEmailCode()` and `verifyEmailCode(code)` call the matching Cloud Functions in `us-central1`; specific failure modes are mapped to `EmailCodeException` (`cooldown`, `wrong-code`, `expired`, `attempts-exhausted`, `no-pending`, `already-verified`).
- `firestore_service.dart` — user-doc reads only (slimmed down after the Rooms refactor)
- `room_service.dart` — room operations: create, find by code, join (public) / request (permission), approve/deny, leave, kick, promote/demote, rename (creator only), delete, post to multiple rooms (returns `PostResult` with `live` and `pending` counts), watch posts, toggle favorites, toggle likes. Plus: `searchPublicRooms` (Firestore prefix search via `nameLower` + `` upper bound), `setRequiresPostApproval`/`setUserTrusted` (admin moderation), `approvePost`/`rejectPost`/`watchPendingPosts`, `_bumpStreak` transaction (day-key compare → updates `currentStreak`/`longestStreak`/`lastPostDate`).
- `storage_service.dart` — Firebase Storage uploads for `momentos/` (post images), `room_photos/` (room avatars), and `profile_photos/` (user avatars).
- `moderation_service.dart` — block/unblock users, submit reports (write-only top-level `reports` collection, reviewed manually in Firebase Console)
- `widget_service.dart` — pushes data to iOS/Android home screen widget via `home_widget` package using App Group `group.com.momento.momento`. `WidgetPost` DTO carries `imageUrl, senderName, roomName, isFavoriteRoom, caption, likeCount, createdAtMs`.

**Models** (`lib/models/`): `app_user.dart`, `room.dart`, `room_post.dart`, `join_request.dart` — plain Dart classes with Firestore serialization. Notable fields:
- `AppUser`: `blockedUserIds`, `hasSeenOnboarding`, `currentStreak`, `longestStreak`, `lastPostDate`
- `Room`: `requiresPostApproval`, `trustedUserIds`, `nameLower` (for prefix search). Helpers: `isAdmin(uid)`, `isTrusted(uid)`, `requiresApprovalFor(uid)`.
- `RoomPost`: `caption`, `pending` (single posts collection — `pending=true` posts are filtered out of feed except for admins and the sender).

**Screens** (`lib/screens/`): `auth/auth_screen.dart` (sign in/up + Google), `auth/verify_email_screen.dart` (6-cell code field with iOS one-time-code autofill, auto-requests a code on entry, 30s resend cooldown, sign-out escape hatch), `home/` (bottom-nav with Feed/Rooms/Account tabs; offline banner pinned above feed), `rooms/` (list, create, join with debounced search, detail, settings with moderation card, pending_posts review screen), `camera/` (photo + multi-room target picker + caption input), `account/` (profile card with edit avatar+name, streak card, blocked users, legal links, delete-account flow with reauth handling), `onboarding/`.

**Reusable widgets** (`lib/widgets/`): `like_button.dart` (heart bounce + optimistic update + long-press → liked-by sheet), `liked_by_sheet.dart` (FutureBuilder<List<AppUser>>), `post_actions_sheet.dart` (long-press post → block/report), `shimmer_placeholder.dart`, `error_view.dart`, `photo_viewer.dart` (pinch-zoom with hero, plays video posts via `video_player`), `offline_banner.dart` (driven by `connectivity_plus`). The earlier `email_verification_banner.dart` was removed when verification became a hard gate — it's redundant now that unverified users can't reach the home screen.

**Widget bridge**: `widget_service.dart` writes to shared UserDefaults (App Group) using keys `momento_image_paths`, `momento_senders`, `momento_rooms`, `momento_favorites`, `momento_count`, `momento_captions`, `momento_likes`, `momento_created_ats`. The native iOS widget (`ios/MomentoWidgetExtension/MomentoWidget.swift`) and Android receiver (`android/.../MomentoWidgetReceiver.kt`) read these and render photos with sender + room + caption + like count + relative time + favorite-room accent. iOS widget is edge-to-edge (uses `.contentMarginsDisabled()` + `GeometryReader` to lock ZStack to widget bounds — see iOS Setup doc).

## Data model (Firestore)

- `users/{uid}` — `email`, `displayName`, `photoUrl`, `roomIds`, `activeRoomIds`, `favoriteRoomIds`, `blockedUserIds`, `hasSeenOnboarding`, `currentStreak`, `longestStreak`, `lastPostDate`, `createdAt`
- `rooms/{roomId}` — `name`, `nameLower` (lowercased copy for prefix search), `code` (6-char unique), `visibility` (`public` | `permission`), `photoUrl`, `createdBy`, `adminIds`, `memberIds`, `requiresPostApproval` (bool), `trustedUserIds` (allow-list to bypass approval), `createdAt`
- `rooms/{roomId}/join_requests/{userId}` — pending requests for permission rooms
- `rooms/{roomId}/posts/{postId}` — `senderId`, `senderName`, `senderPhotoUrl`, `imageUrl`, `caption?`, `pending` (bool), `createdAt`, `expiresAt` (now+6h), `likedBy`
- `reports/{reportId}` — write-only from clients, read-only via Firebase Console

**Pending-post pattern**: there is no separate pending subcollection. Posts have a `pending` flag enforced by Firestore rules:
- On create: `pending` must equal `room.requiresPostApproval && !isAdmin && !trusted` (members can't bypass).
- On read: `pending == false` posts visible to all members; `pending == true` visible only to admins and the original sender.
- On update: members may toggle `likedBy` only; admins may flip `pending → false` to approve.

## iOS Widget Setup

The iOS widget extension setup is fully documented in `CLAUDE_IOS_SETUP.md`. Current state:
- App **runs on physical iPhone 13** — auth, rooms, posting, likes, blocks, and onboarding all work
- Development bundle IDs use Personal Team: `com.mbak4.momento` / `com.mbak4.momento.MomentoWidgetExtension`
- Always open `ios/Runner.xcworkspace` in Xcode (never `Runner.xcodeproj`)
- Always build with the **Runner** scheme (not MomentoWidgetExtensionExtension)
- **Do not re-add** `${TARGET_BUILD_DIR}/${INFOPLIST_PATH}` to Thin Binary inputPaths — it was intentionally removed to fix a build cycle (Flutter's pod install may try to add it back; if a cycle re-appears, remove again)
- **Info.plist must contain** `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` — without them iOS silently freezes when the image picker is opened
- Widget rendering on physical device is the only thing left untested (see CLAUDE_IOS_SETUP.md Step 5)

## Firebase

- Project: `momento-app-64950`
- Config: `lib/firebase_options.dart` (auto-generated, do not edit manually)
- Firestore rules: `firestore.rules` — **must be re-published manually via the Firebase Console after any change** (no Firebase CLI installed locally)
- Storage rules: `storage.rules` — same: re-publish via Firebase Console after any change
- Cloud Functions: `functions/index.js` — `requestEmailCode` and `verifyEmailCode` (callable, region us-central1) drive the 6-digit email verification flow. See [CLAUDE_IOS_SETUP.md](CLAUDE_IOS_SETUP.md) §Step 8 for one-time setup (firebase CLI, Trigger Email extension, deploy).
- iOS deployment target must stay at 15.0+ (cloud_firestore requirement)
- `firebase_options.dart` has `iosBundleId: 'com.momento.momento'` but the device builds with `com.mbak4.momento` (Personal Team). This logs a warning but doesn't break Firebase — the API key/app ID are what matter.

## Roadmap status (April 2026)

Built and verified on iPhone 13:
- Rooms model (create, join, leave, kick, promote/demote, rename, delete)
- Public + permission-based rooms with join request approval
- Multi-room post targeting (active / all / pick)
- Merged feed with favorite-room bubbling
- Per-user active rooms and favorite rooms
- Room photos / avatars
- Likes (heart toggle with bounce animation)
- Block / report users (long-press post → bottom sheet)
- Onboarding tutorial (3-card carousel, shown on first sign-in)
- Polish: shimmer loading states, error views, pull-to-refresh, fade-in images, hero transitions, fullscreen photo viewer with pinch-zoom

Built recently (verified on iOS Simulator iPhone 17 Pro / iOS 26.1 unless noted):
- Phase 1: post captions, edit-profile screen (avatar + display name), liked-by bottom sheet (long-press heart), delete-account with cascade + reauth handling, room name search (prefix via `nameLower`), posting streak (current + longest, day-key transaction)
- Phase 2 / pre-MVP: offline banner (connectivity_plus), photo approval workflow (per-room toggle + admin pending review screen), trusted users (allow-list to bypass approval), legal URLs file, account-screen polish (streak card, blocked users section, legal links)
- Widget redesign (iOS + Android): edge-to-edge photo, soft chips for time + page counter, sender + room + like count + caption overlay, coral favorite accent, scaled-down typography for legibility on small widget. iOS widget uses `.contentMarginsDisabled()` + `GeometryReader` to keep text inside visible bounds.
- Cross-platform parity (2026-04-26): Android widget Kotlin reads all the same fields iOS does (caption, likes, time-ago, video flag); Android `AndroidManifest.xml` permissions added for video recording (CAMERA, RECORD_AUDIO, READ_MEDIA_VIDEO/IMAGES, INTERNET); iOS `NSMicrophoneUsageDescription` added so video recording isn't silently blocked.
- 6-second video posts (2026-04-26): record/pick video, audio stripped via `video_compress`, mid-frame poster extracted via `video_thumbnail`, both files uploaded to `momentos/{senderId}/`. Feed shows poster + translucent play badge; full-screen viewer plays the clip muted-on-loop. Widget renders the same poster + smaller play glyph (no playback in widget — that's a hard WidgetKit/RemoteViews limitation).
- Email-code verification (2026-04-26, **partially live** — see below): Cloud Functions `requestEmailCode` / `verifyEmailCode` deployed in `us-central1`; Firebase "Trigger Email from Firestore" extension installed; new `VerifyEmailScreen` is a hard gate after sign-up / unverified sign-in. **Blocked on**: Gmail SMTP authentication failing with `535 5.7.8 Username and Password not accepted` — App Password needs to be regenerated and pasted into the extension config without spaces. Once SMTP auth works, the rest of the pipeline is verified end-to-end via the function logs (codes are generated and queued correctly).

Explicitly not building (user said no):
- Comments
- Push notifications

Pre-launch deferred work:
- Set real Privacy Policy + Terms of Service URLs in `lib/legal_urls.dart`
- Re-publish `firestore.rules` to Firebase Console after the rewrite (covers pending posts + trusted users + reports collection)
- Re-publish `storage.rules` if changed
- Enable Firebase App Check
- Apple Developer Program enrollment ($99/yr) to ship the production bundle ID
- App Store listing assets (screenshots, copy)

Known limitation:
- Android SDK not installed locally — Android version can't be built/tested from this machine yet
