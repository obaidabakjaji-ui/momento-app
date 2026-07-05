# Huddlex (momento) — Flutter → Kotlin/Jetpack Compose Migration Map

**Status:** Single source of truth for the native Android rewrite.
**Source tree:** `app/lib/` (Flutter/Dart) + `app/android/.../MomentoWidgetReceiver.kt` (already native, 418 LOC — keep as-is).
**Target tree:** `app/native/` — Kotlin, Jetpack Compose, MVVM with Repository layer, Kotlin Flows, Hilt DI, Coil, Firebase KTX.

Totals: **37 hand-written Dart files, 8,279 LOC** (+ 9 generated l10n files, 8,412 LOC; + `firebase_options.dart`, 68 LOC generated). Grand total `lib/`: 16,691 LOC.

---

## 1. INVENTORY

### 1.1 Entry point & infrastructure

| Dart file | LOC | Purpose | Native equivalent | Plugins → native replacement |
|---|---|---|---|---|
| `lib/main.dart` | 146 | Firebase init, Crashlytics wiring, App Check activation, WidgetService init, LocaleService load, Workmanager 15-min periodic widget refresh, `MomentoApp` + `AuthGate` routing (auth → verify → onboarding → home) | `HuddlexApplication.kt` (Firebase/Crashlytics/AppCheck/WorkManager init) + `MainActivity.kt` (single-Activity Compose host) + `ui/AuthGate.kt` (composable routing on `authFlow` + `userDocFlow`) | `firebase_core`→Firebase BoM; `firebase_crashlytics`→Crashlytics SDK (`Thread.setDefaultUncaughtExceptionHandler` is automatic); `firebase_app_check`→Play Integrity / Debug provider; `workmanager`→**androidx.work WorkManager** (native, `PeriodicWorkRequest` 15 min, `NetworkType.CONNECTED`, `ExistingPeriodicWorkPolicy.REPLACE`) |
| `lib/theme.dart` | 71 | Brand colors (coral `#FF6B6B`, warmOrange `#FF9A56`, softPink `#FFB7B2`, deepPlum `#2D2337`, seashell `#FFF5EE`), Material 3 light theme, button/input themes | `ui/theme/Theme.kt` + `Color.kt` + `Type.kt` — Material 3 `lightColorScheme(primary=coral, secondary=warmOrange, tertiary=softPink, surface=seashell, onSurface=deepPlum)`; 52dp-high full-width filled/outlined buttons r16; white filled text fields r12, coral 2dp focus border | — |
| `lib/legal_urls.dart` | 8 | `kTermsOfServiceUrl` / `kPrivacyPolicyUrl` → `https://huddlex.app/{terms,privacy}.html` | `core/LegalUrls.kt` (const vals) | — |
| `lib/firebase_options.dart` | 68 | Generated Firebase config (project `momento-app-64950`) | `google-services.json` + Gradle plugin (no code) | — |

### 1.2 Models (`lib/models/`)

| Dart file | LOC | Purpose | Native equivalent |
|---|---|---|---|
| `app_user.dart` | 71 | `AppUser`: email, displayName, photoUrl, roomIds, activeRoomIds, favoriteRoomIds, blockedUserIds, hasSeenOnboarding, currentStreak, longestStreak, lastPostDate, createdAt; helpers `hasRooms`, `hasBlocked` | `data/model/AppUser.kt` — `data class` with manual `fromSnapshot(DocumentSnapshot)`/`toMap()` (keep null-tolerant defaults identical: missing arrays → empty, missing bools → false) |
| `room.dart` | 147 | `Room` + `RoomVisibility` enum; requiresPostApproval, trustedUserIds, location lock fields (locationLockEnabled/Lat/Lng/RadiusM); helpers `isAdmin/isCreator/isTrusted/isMember`, `hasActiveLocationLock`, **`requiresApprovalFor(uid, lat, lng)`** with haversine geofence | `data/model/Room.kt` — port haversine and `requiresApprovalFor` verbatim (see contract B2/B3). `toMap()` must write `nameLower = name.lowercase()` |
| `room_post.dart` | 66 | `RoomPost`: senderId/Name/PhotoUrl, imageUrl, caption?, createdAt, **expiresAt (= created+6h)**, likedBy, **pending**; helpers `isExpired`, `likeCount`, `likedByUser` | `data/model/RoomPost.kt` — `isExpired` = `System.currentTimeMillis() > expiresAt` |
| `join_request.dart` | 39 | `JoinRequest`: roomId, userId, userName, userPhotoUrl, createdAt (doc id == userId for dedupe) | `data/model/JoinRequest.kt` |

### 1.3 Services (`lib/services/`)

| Dart file | LOC | Purpose | Native equivalent | Plugins → native replacement |
|---|---|---|---|---|
| `auth_service.dart` | 201 | Email/Google sign-in+up, user-doc creation on first sign-in, password reset, `userChanges()`-backed stream (see B1), email-code verify via Cloud Functions us-central1 (`requestEmailCode`/`verifyEmailCode`) with `EmailCodeException` mapping, `deleteAccount()` cascade | `data/AuthRepository.kt` — `authFlow: Flow<FirebaseUser?>` via `callbackFlow` + **manual re-emit trigger after `reload()`** (see B1); Functions KTX `FirebaseFunctions.getInstance("us-central1")`; sealed `EmailCodeException(code)` | `google_sign_in`→**Credential Manager API** (`GetGoogleIdOption`, serverClientId `149110523075-d3dkatbv890ibpm6vtb6rd3p470j3bbm.apps.googleusercontent.com`); `cloud_functions`→Functions KTX |
| `firestore_service.dart` | 35 | User-doc reads: `watchUser`, `getUser`, `getUsers` (chunked `whereIn` ≤30) | `data/UserRepository.kt` — `watchUser(uid): Flow<AppUser?>` (`snapshots()` KTX), `getUsers` keeps 30-chunking | `cloud_firestore`→Firestore KTX |
| `room_service.dart` | 587 | All room/post ops: create (unique 6-char code, alphabet omits `0/O/1/I`, `Random.secure`, 8 retries), findByCode (uppercased), join/request, approve/deny join, leave/kick/promote/demote, rename (name+nameLower), `searchPublicRooms` (prefix `nameLower >= q < q+''`), photo update, delete (batch scrub member docs), active/favorite toggles, **`postToRooms` multi-room batch + PostResult{live,pending}**, approve/reject/watch pending posts, `setRequiresPostApproval`, `setLocationLock`/`clearLocationLock`, `setUserTrusted`, **`_bumpStreak` transaction**, `watchRoomPosts` (client-side expiry+pending filter), `getRoomPostsOnce`, deletePost, toggleLike | `data/RoomRepository.kt` with Kotlin Flows — streams as `Flow<List<T>>` via `snapshots()`; batch = `WriteBatch`; streak = `runTransaction`; `SecureRandom` for codes | `cloud_firestore`→Firestore KTX (`FieldValue.arrayUnion/Remove`, `whereIn` 30-chunk) |
| `storage_service.dart` | 41 | Uploads: `momentos/{senderId}/{uuid}.jpg`, `room_photos/{uploaderId}/{uuid}.jpg` (contentType image/jpeg) | `data/StorageRepository.kt` — Storage KTX `putFile` + `downloadUrl.await()`; `UUID.randomUUID()` | `firebase_storage`→Storage KTX; `uuid`→`java.util.UUID` |
| `moderation_service.dart` | 86 | block/unblock (arrayUnion/Remove on `blockedUserIds`), reportUser/reportRoom/reportPost → write-only top-level `reports` collection with `type` in {user,post,room} | `data/ModerationRepository.kt` | Firestore KTX |
| `location_service.dart` | 65 | Permission ladder (service enabled → check → request), high-accuracy fix with **10s timeout**, typed `LocationResult`/`LocationFailure` (servicesDisabled, permissionDenied, permissionDeniedForever, timeout, unknown) | `data/LocationRepository.kt` | `geolocator`→**FusedLocationProviderClient** (`getCurrentLocation(PRIORITY_HIGH_ACCURACY, cancellationToken)` + `withTimeoutOrNull(10_000)`); permission via Accompanist/`rememberLauncherForActivityResult` |
| `locale_service.dart` | 79 | Persisted locale override (`SharedPreferences` key `app_locale`, null = system), 8 selectable locales (en ar fr es it ko ja zh), display names | `data/LocaleRepository.kt` | `shared_preferences`→**AppCompatDelegate.setApplicationLocales / `LocaleManager`** (per-app language, API 33+) with DataStore fallback for <33; keep the picker order |
| `widget_service.dart` | 372 | Widget push pipeline: `refreshForUser` (throttle 5s + force + in-flight guard), Firestore pull (active rooms else all → posts → block filter → favorite-first sort → take 20), image download to per-index files, **persisted signature dedup `momento_signature`**, write 12 SharedPreferences keys, trigger widget update, `clearWidget` | `widget/WidgetUpdater.kt` — same algorithm; writes **directly** into `HomeWidgetPreferences` SharedPreferences (keep prefs filename so existing receiver keeps working during transition) then `sendBroadcast(ACTION_APPWIDGET_UPDATE)` / `AppWidgetManager.updateAppWidget` | `home_widget`→**RemoteViews direct** (SharedPreferences + AppWidgetManager); `http`→OkHttp; `path_provider`→`context.filesDir` |
| `widget_background_task.dart` | 35 | Workmanager background entry: init Firebase, `refreshForUser(currentUser.uid)`; task name `huddlex-widget-refresh` | `widget/WidgetRefreshWorker.kt` — `CoroutineWorker` (Hilt), same unique name | `workmanager`→**WorkManager** |

### 1.4 Screens (`lib/screens/`)

| Dart file | LOC | Purpose | Native equivalent | Plugins |
|---|---|---|---|---|
| `auth/auth_screen.dart` | 321 | Sign in/up toggle form, Google button, forgot-password dialog, legal footer with tappable Terms/Privacy links | `ui/auth/AuthScreen.kt` + `AuthViewModel` | `url_launcher`→**CustomTabs** (`CustomTabsIntent`) |
| `auth/verify_email_screen.dart` | 335 | Hard gate: 6-cell code field (hidden field + drawn boxes), auto-request code on entry, 30s resend cooldown (server cooldown parsed via regex `(\d+)s`), sign-out escape hatch | `ui/auth/VerifyEmailScreen.kt` + `VerifyEmailViewModel` (cooldown as `countDownFlow`) | OTP autofill → **SMS-less**: `autofillHints = AutofillType.SmsOtpCode` / `BasicTextField` with 6 drawn boxes |
| `home/home_screen.dart` | 534 | Bottom nav (Feed/Rooms/Account); `_FeedTab`: combineLatest of per-room post streams, block filter, favorite-first sort, `PageView` of post cards, push-to-widget side effect, lifecycle-resume widget refresh, empty states, offline banner, fake pull-to-refresh | `ui/home/HomeScreen.kt` (`NavigationBar` + 3 tabs), `ui/home/FeedScreen.kt` + `FeedViewModel` (`combine()` of room flows), `VerticalPager`; widget push moved from build() into ViewModel `collect` side effect; `LifecycleResumeEffect` → `widgetUpdater.refreshForUser(uid)` | `cached_network_image`→**Coil** (`AsyncImage`, crossfade 350ms) |
| `camera/camera_screen.dart` | 872 | Locket-style capture: live preview, flash torch toggle, camera flip, gallery pick, center-square crop honoring EXIF, review screen with caption + target pills (active/all/pick) + custom room chips + gradient send, GPS-conditional geofence fetch, post + force widget refresh + result snackbar | `ui/camera/CameraScreen.kt` + `CameraViewModel` | `camera`→**CameraX** (`Preview` + `ImageCapture`, `CameraSelector`, torch via `CameraControl.enableTorch`); `image_picker`→**PhotoPicker** (`PickVisualMedia`); `image`→Android `BitmapFactory` + **ExifInterface** rotation + center-crop + JPEG q88; `path_provider`→`cacheDir`; HapticFeedback→`HapticFeedbackType` |
| `onboarding/onboarding_screen.dart` | 211 | 5-card carousel (welcome, rooms, expiry, widget, location lock), skip always available, writes `hasSeenOnboarding=true` (navigation driven by user-doc stream, not local nav) | `ui/onboarding/OnboardingScreen.kt` (`HorizontalPager` + animated dots) | — |
| `rooms/rooms_screen.dart` | 342 | My-rooms list (favorites first then newest), star toggle + active (bell) toggle per tile, empty state, FAB create, search icon → join | `ui/rooms/RoomsScreen.kt` + `RoomsViewModel` | Coil for room avatars |
| `rooms/create_room_screen.dart` | 274 | Name (≤40), photo pick+upload, public/permission visibility cards, create → replace-navigate to detail | `ui/rooms/CreateRoomScreen.kt` | PhotoPicker |
| `rooms/join_room_screen.dart` | 301 | Join by 6-char code (uppercased, must be exactly 6) + debounced (300ms) prefix search of public rooms, filters out rooms already joined; public = instant join, permission = join request + snackbar | `ui/rooms/JoinRoomScreen.kt` + `JoinRoomViewModel` (debounce via `snapshotFlow().debounce(300)`) | — |
| `rooms/room_detail_screen.dart` | 254 | Single-room feed (`PageView` of post cards, block-filtered), settings gear | `ui/rooms/RoomDetailScreen.kt` | Coil |
| `rooms/room_settings_screen.dart` | 980 | Header (photo edit for admins), gradient code card (copy + share), admin moderation card (approval toggle + pending review link), **location-lock card** (toggle auto-pins current location, pin display, radius chips 50/200/500/1000/5000 m, default 200), join requests (approve/deny), member list (creator/admin/trusted badges, popup: promote/demote/trust/untrust/kick), leave (hidden if last member), report room, delete room (admin) | `ui/rooms/RoomSettingsScreen.kt` + `RoomSettingsViewModel` | `share_plus`→**ShareSheet** (`Intent.ACTION_SEND`); Clipboard→`ClipboardManager`; FusedLocationProvider for pinning |
| `rooms/pending_posts_screen.dart` | 162 | Admin review queue: sender chip, square image, caption, Reject (delete) / Approve (pending→false) | `ui/rooms/PendingPostsScreen.kt` | Coil |
| `account/account_screen.dart` | 631 | Profile card + edit, streak card (fire gradient, shown when streak>0), active/favorite room lists, blocked users + unblock, language picker sheet, feedback mailto (hand-rolled `%20` encoding to `obaidabakjaji@gmail.com`), legal links, sign out, delete account (requires-recent-login snackbar) | `ui/account/AccountScreen.kt` + `AccountViewModel` | `url_launcher`→CustomTabs (legal) + `Intent.ACTION_SENDTO` mailto (feedback) |
| `account/edit_profile_screen.dart` | 195 | Avatar pick → upload `profile_photos/{uid}/{uuid}.jpg`, display name (≤40), diff-only Firestore update | `ui/account/EditProfileScreen.kt` | PhotoPicker, Storage KTX |

### 1.5 Reusable widgets (`lib/widgets/`)

| Dart file | LOC | Purpose | Native equivalent | Plugins |
|---|---|---|---|---|
| `like_button.dart` | 148 | Heart pill: optimistic toggle + rollback on failure, bounce 1.0→1.35→1.0 (280ms) on like only, count hidden at 0, long-press → liked-by sheet (only when non-empty), external-change sync guarded by `_busy` | `ui/components/LikeButton.kt` — `Animatable` scale keyframes; optimistic state in composable + rollback | — |
| `liked_by_sheet.dart` | 116 | Draggable bottom sheet (0.3–0.9, initial 0.5) listing likers (batched `getUsers`) | `ui/components/LikedBySheet.kt` (`ModalBottomSheet`) | — |
| `post_actions_sheet.dart` | 191 | Long-press sheet: others' posts → report (reason dialog) + block (confirm); own posts → delete (confirm) | `ui/components/PostActionsSheet.kt` | — |
| `photo_viewer.dart` | 84 | Fullscreen black viewer: hero-style transition, pinch-zoom 1–4×, tap or fling-vertical (>300 velocity) to dismiss, caption pill bottom | `ui/components/PhotoViewer.kt` — shared-element (`SharedTransitionLayout`) + `Modifier.transformable` zoom + vertical-drag dismiss | Coil |
| `offline_banner.dart` | 66 | deepPlum banner pinned above feed; offline iff **every** connectivity result == none; animated size 200ms | `ui/components/OfflineBanner.kt` | `connectivity_plus`→**ConnectivityManager** (`registerDefaultNetworkCallback` → `callbackFlow`) |
| `shimmer_placeholder.dart` | 92 | Sliding softPink gradient placeholder (1200ms loop) + `ShimmerList` | `ui/components/Shimmer.kt` (`rememberInfiniteTransition` gradient offset) | — |
| `error_view.dart` | 53 | cloud-off icon + message + optional retry button | `ui/components/ErrorView.kt` | — |

### 1.6 Localization

| Files | LOC | Purpose | Native equivalent |
|---|---|---|---|
| `lib/l10n/app_*.arb` (8 locales) + generated `app_localizations*.dart` (9 files) | 8,412 (generated) | ~130 keys × 8 locales: en, ar, es, fr, it, ja, ko, zh; plural/params (e.g. `homeTimeRemaining(h,m)`, `cameraPostedTo(n)`) | `res/values[-ar,-es,-fr,-it,-ja,-ko,-zh]/strings.xml` — convert ARB → `strings.xml`/`plurals`; RTL support for `ar` (`supportsRtl`, use `start/end` everywhere — Dart code already uses `AlignmentDirectional` in the language sheet) |

### 1.7 Already-native (keep, do not rewrite)

| File | LOC | Notes |
|---|---|---|
| `android/.../MomentoWidgetReceiver.kt` | 418 | Home-screen widget receiver: ViewFlipper rotation, active-subset hash dedup, self-armed expiry alarm, RGB_565 400px decode, 5-card cap. Only change needed: read prefs written by the native `WidgetUpdater` (same file/keys → **zero change** if keys preserved) |
| `android/.../MainActivity.kt` | 5 | Replace `FlutterActivity` with `ComponentActivity` Compose host |

### 1.8 Plugin → native replacement summary

| Flutter plugin | Native replacement |
|---|---|
| `camera` | CameraX (`camera-camera2`, `camera-lifecycle`, `camera-view`) |
| `image_picker` | Android Photo Picker (`ActivityResultContracts.PickVisualMedia`) |
| `image` (Dart decode/crop) | `BitmapFactory` + `ExifInterface` + `Bitmap.createBitmap` center-crop + JPEG compress q88 |
| `geolocator` | FusedLocationProviderClient (play-services-location) |
| `home_widget` | Direct SharedPreferences (`HomeWidgetPreferences`) + `AppWidgetManager`/RemoteViews (receiver already native) |
| `workmanager` | androidx.work WorkManager (`CoroutineWorker`) |
| `share_plus` | `Intent.ACTION_SEND` ShareSheet |
| `url_launcher` | CustomTabs (web) / `ACTION_SENDTO` (mailto) |
| `connectivity_plus` | ConnectivityManager network callback |
| `cached_network_image` | Coil (`AsyncImage`, memory+disk cache, crossfade) |
| `shared_preferences` | Jetpack DataStore (locale via AppCompatDelegate) |
| `path_provider` | `context.filesDir` / `context.cacheDir` |
| `http` | OkHttp |
| `uuid` | `java.util.UUID` |
| `google_sign_in` | Credential Manager + Google ID |
| firebase_* | Firebase Android BoM (auth, firestore, storage, functions, app-check, crashlytics) |

---

## 2. BEHAVIORAL CONTRACTS

These are the load-bearing subtleties. Each one has caused (or prevented) a real bug. **Any native implementation must reproduce these exactly.**

### B1. Auth gate listens to `userChanges()`, NOT `authStateChanges()`
`AuthService.authStateChanges` is a deliberately misnamed getter backed by `FirebaseAuth.userChanges()` (auth_service.dart:27-31). Reason: after `verifyEmailCode` succeeds, the client calls `user.reload()`; only `userChanges()`/`idTokenChanges()` re-emit on property changes — `authStateChanges()` fires only on sign-in/out, so the gate would never leave `VerifyEmailScreen`.
**Native trap:** Android's `FirebaseAuth.AuthStateListener` ≙ `authStateChanges()` — it does **not** fire after `reload()`. The native `authFlow` must merge the AuthStateListener with an explicit re-emit trigger fired after every `reloadCurrentUser()` (e.g. a `MutableSharedFlow<Unit>` combined with `flowOf(auth.currentUser)`), or use `addIdTokenListener`. **Acceptance:** entering a correct 6-digit code routes to onboarding/home within one emission, no app restart.

Gate order (main.dart AuthGate): loading → `AuthScreen` (null user) → `VerifyEmailScreen` (`!emailVerified` — Google accounts arrive verified and skip) → spinner while user doc is null (**do not flash onboarding during the sign-up doc-creation race**) → `OnboardingScreen` (`!hasSeenOnboarding`) → `HomeScreen`. Onboarding finishes by writing `hasSeenOnboarding=true` and letting the user-doc stream re-route — it never navigates directly.

### B2. Pending-post rules contract (client and rules must agree)
Firestore rules (firestore.rules:125-133) allow a post create only when:
`pending == true` **OR** `!room.requiresPostApproval` **OR** sender ∈ `adminIds` **OR** sender ∈ `trustedUserIds`.
i.e. **pending must equal `room.requiresPostApproval && !isAdmin && !isTrusted`** for the approval dimension — the sender may additionally self-mark `pending=true` (rules can't evaluate the geofence; the client honor-marks it).
Client computation is `Room.requiresApprovalFor(uid, lat, lng)` (room.dart:105-114): admin → `false` (bypasses *everything* including geofence); `requiresPostApproval && !trusted` → `true`; otherwise → geofence result.
**Native trap:** `postToRooms` writes all posts in **one atomic WriteBatch** — if the native port computes `pending` differently for even one room, the rules reject that doc and **the entire multi-room post fails**. Port `requiresApprovalFor` verbatim and unit-test it against the rules truth table (admin/trusted/member × approval on/off × in/out/no-GPS).
Read visibility: `pending==false` → all members; `pending==true` → admins + original sender only. Update: members may touch only `likedBy` (add/remove **own uid only**); admins may flip `pending true→false` only (approval); nobody else edits posts. Delete: sender or admin.

### B3. Geofence fails CLOSED when GPS is missing
`Room._isOutsideGeofence` (room.dart:116-126): lock not fully configured → `false`; **senderLat/Lng null while lock active → `true` (out of area → pending)**. Camera flow (camera_screen.dart:283-299): GPS is requested **only** if some target room `hasActiveLocationLock && !isAdmin(uid)` — never prompt for location otherwise; if the lookup fails (denied/timeout/disabled) the post proceeds with null coords and lands pending. Trusted users bypass approval but are **still geofenced**; admins bypass both. `clearLocationLock` only flips `locationLockEnabled=false` — pin+radius are kept so re-enabling restores them. Haversine with R=6,371,000 m; radius options 50/200/500/1000/5000 m, default 200.

### B4. The 6-hour expiry lives in THREE places — keep them in lockstep
1. **Post creation** — `RoomService.postToRooms`: `expiresAt = now + 6h` written on the doc (room_service.dart:352).
2. **Feed filter** — `watchRoomPosts` / `getRoomPostsOnce` filter `!isExpired && !pending` **client-side** (deliberate: avoids a composite Firestore index). Expired docs still exist in Firestore.
3. **Widget receiver** — `MomentoWidgetReceiver.POST_LIFETIME_MS = 6L*60*60*1000` computes expiry from `createdAtMs` (**not** `expiresAt` — it never sees that field), with the comment "must match `Duration(hours: 6)` in room_service.dart".
Change one → change all three. Native: define a single `POST_LIFETIME` constant in a `:core` module consumed by repository, feed filter, and widget receiver.

### B5. Widget binder-limit constraints (silent-failure territory)
RemoteViews bundles ride a ~1 MB binder transaction; **the launcher silently rejects oversized updates**, leaving the widget frozen on its previous (often empty) render — no exception, no log. Hence in the receiver: `MAX_BITMAP_EDGE = 400` px longest edge, `RGB_565` (2 B/px, ~320 KB/card), two-pass decode (`inJustDecodeBounds` then `inSampleSize`), and `MAX_CARDS = 5` in the ViewFlipper. Memory MEMORY.md rule: *silent widget-update failures → check bitmap size FIRST.* Do not "improve" quality, add cards, or switch to ARGB_8888.

### B6. Persisted widget push-signature dedup (`momento_signature`)
`WidgetService.updateWidgetWithPosts` fingerprints the push as `posts.map { "${imageUrl}|${createdAtMs}" }.join(";")` and stores it under key **`momento_signature`** in the widget prefs (**persisted**, never an in-memory static). Why persisted: the background worker runs in a fresh process/isolate each time; an in-memory cache caused two real bugs — (a) every BG run re-downloaded all images, (b) when all posts expired the clear was skipped, leaving dead photos up indefinitely.
Semantics to preserve exactly:
- signature unchanged → skip push entirely (no downloads, no broadcast);
- empty post list + empty signature → no-op; empty list + non-empty signature → `clearWidget()`;
- **partial download failure → persist `''`** (not the full signature) so the next refresh retries the failed images (the "photo doesn't show until the 3rd post" bug); full success → persist signature;
- all downloads failed → `clearWidget()` (resets signature so next refresh retries);
- `clearWidget()` always persists `''` and zeroes all 12 keys.

### B7. Expiry alarm re-arming semantics (receiver — keep verbatim)
- Re-arm on **every** `onUpdate`, including hash-deduped no-op updates: alarms die on reboot/force-stop, and the system delivers `APPWIDGET_UPDATE` after both — re-arming there restores the alarm without needing changed data.
- One-shot **inexact, non-waking** `AlarmManager.RTC` + `setAndAllowWhileIdle`; `FLAG_UPDATE_CURRENT` on request code 9001 ensures a single outstanding alarm.
- Trigger = earliest active `createdAt` + 6h + **5s buffer** (clock-skew guard against a zero-delay re-render loop); clamp to `now + 5s` if already past due; **cancel** the alarm when nothing on the widget can expire (legacy rows with `createdAt <= 0` never expire).
- The rebuild hash (`last_data_hash_v6` in `home_widget_prefs`) is computed over the **active (unexpired) subset** of paths+createdAts — that's what lets an expiry tick reuse the ordinary deduped update path (subset shrinks → hash changes → rebuild). The `_v6` suffix is a cache-buster: bump it whenever a render-affecting change ships, or stale "success" hashes will mask rejected renders.

### B8. `refreshForUser` throttle + force semantics
(widget_service.dart:99-114) Two guards: (1) `_refreshInFlight` — **always** respected, even with `force=true`, so two refreshes never race; (2) 5-second throttle since last *successful* run — bypassed only by `force=true`. Call sites: after posting (**force=true** — the user just created content and expects the widget to update now, even if a passive refresh ran a second ago), app-resume (`ON_RESUME`, non-forced), and the 15-min background worker (non-forced). Failures are logged and swallowed — a widget-refresh failure must never tank posting or resume. Content dedup does NOT live here (see B6). Native: `Mutex.tryLock` or an atomic in-flight flag inside a singleton `WidgetUpdater`.

### B9. Multi-room post batching + streak transaction
`postToRooms`: fetch target rooms first (approval/geofence policy), then **one WriteBatch** writing one post doc per room sharing the same `imageUrl` (per-room stream independence + per-room rules checks), counting live vs pending → `PostResult`. UI message logic: all-live / all-pending / mixed. Streak is bumped **after** the batch commit, `unawaited`, in a **separate Firestore transaction**, wrapped in a swallow-all catch: *"never fail a post over streak bookkeeping."*
Streak transaction: dayKey = days since epoch of **local midnight**; same day → no change; `today - last == 1` → `currentStreak+1`; else → 1; `longestStreak = max`; `lastPostDate = now`. Room fetch skips ids that don't resolve (`roomMap[roomId] == null → continue`).

### B10. Blocked-user filtering points (client-side only, three places)
Rules do **not** filter blocked senders — the client must, at exactly these points:
1. Home merged feed (`home_screen.dart:240-244`),
2. Room detail feed (`room_detail_screen.dart:71-84`),
3. Widget refresh (`widget_service.dart:165-168`).
Deliberately NOT filtered: pending-posts admin queue and liked-by sheet. Blocking is one-directional (viewer's `blockedUserIds`).

### B11. Widget receiver SharedPreferences contract (exact keys)
Receiver reads from prefs file **`HomeWidgetPreferences`** (the home_widget plugin's filename — the native writer must keep it):
`momento_image_paths`, `momento_senders`, `momento_rooms`, `momento_favorites`, `momento_captions`, `momento_likes`, `momento_created_ats` — all JSON-encoded arrays, index-aligned.
Also written by Dart (not currently read by the receiver, keep writing them): `momento_post_ids`, `momento_room_ids` (reserved for widget tap actions), `momento_count` (string), legacy single-item `momento_image_path`, `momento_sender`, `momento_timestamp`, plus dedup key `momento_signature` (B6).
Receiver-owned prefs file **`home_widget_prefs`**: `last_data_hash_v6`.
Image files: `widget_momento_{i}.jpg` in app documents dir (index-addressed, overwritten each push). Feed/widget cap: Dart pushes `take(20)`; receiver renders ≤5 (B5).

### B12. Widget data pipeline ordering
Source rooms = `activeRoomIds` if non-empty **else all** `roomIds` (same rule in feed and widget refresh). Sort: favorite-room posts first (0/1 bucket), then `createdAt` desc within buckets. The feed pushes to the widget as a side effect of every stream emission (`_pushToWidget` — cheap because of B6); an empty feed emission flows through too (clears once). No user doc or no rooms → `clearWidget()`.

### B13. Other contracts worth preserving
- **Room codes**: 6 chars from `ABCDEFGHJKLMNPQRSTUVWXYZ23456789` (no 0/O/1/I), `Random.secure`, uniqueness-checked with 8 retries; lookups uppercase the input.
- **Cross-user user-doc writes**: `approveJoinRequest` (admin's client updates the *requester's* `roomIds`) and public-join batches are legal only because users-rules allow non-self updates touching **only** `['roomIds','activeRoomIds','favoriteRoomIds']`. Don't add extra fields to those batches.
- **leaveRoom**: last member → `deleteRoom` (batch-scrubs the room from every member's 3 arrays, deletes room doc; posts are orphaned for TTL/Function cleanup). Otherwise batch-remove from `memberIds`+`adminIds` and the user's 3 arrays.
- **deleteAccount cascade**: leaveRoom per membership (continue on individual failure), delete user doc, `user.delete()` (may throw `requires-recent-login` → UI snackbar), best-effort Google sign-out.
- **Email-code error mapping**: `resource-exhausted` → `attempts-exhausted` if message contains "attempts" else `cooldown`; `deadline-exceeded` → `expired`; `permission-denied` → `wrong-code`; `failed-precondition` → `no-pending`. Verify screen parses server cooldown seconds from the message via regex `(\d+)s`. `verifyEmailCode` success → `reloadCurrentUser()` (→ B1 re-emit).
- **Square crop honors EXIF**: Dart `image.decodeImage` auto-applies EXIF orientation before center-crop — the reason portrait photos stopped rendering sideways in the widget (widget-process `BitmapFactory` does NOT apply EXIF). Native: apply `ExifInterface` rotation before cropping, or decode via `ImageDecoder`.
- **Like rules**: `likedBy` diffs must be exactly `[myUid]` added or removed; optimistic UI with rollback.
- **WorkManager**: unique name `huddlex-widget-refresh`, 15-min period (WorkManager minimum), `NetworkType.CONNECTED`, **REPLACE** policy (comment: a policy/period change only takes effect if the existing task is replaced).
- **Offline detection**: offline iff *every* connectivity result is `none` (multi-transport safe).
- **Language picker quirk** (account_screen.dart:331): dismissing the sheet returns null, which — when a language override is set — resets to system default. Known quirk; decide consciously (recommend: use a sentinel for "System" and no-op on dismiss; document the change).
- **Locale persistence**: key `app_locale`, null = follow device.
- **mailto encoding**: hand-rolled query encoding replacing `+` with `%20` (Gmail/Mail compat).
- **App Check**: debug providers in debug builds (token must be registered in console), Play Integrity in release.
- **firestore.rules deploys are manual** via Firebase Console (no CLI configured).
- **Current code is photo-only.** CLAUDE.md mentions a 6-sec video experiment; none of it is in the present `lib/` — do not port video.

---

## 3. SCREEN-BY-SCREEN UI SPEC

Brand palette (everywhere): coral `#FF6B6B` (primary/action), warmOrange `#FF9A56` (gradient partner, favorite star), softPink `#FFB7B2` (avatar bg, placeholders), deepPlum `#2D2337` (text; opacities .05–.85 for hierarchy), seashell `#FFF5EE` (scaffold bg). Signature gradient: coral→warmOrange (logo, shutter, send button, code card, streak card, onboarding icon tiles). Cards: white, radius 12–20, faint black shadow. Buttons: 52dp full-width, radius 16.

### AuthScreen
Centered scroll column on seashell: 80dp coral→warmOrange gradient rounded-square (r20) logo w/ white camera icon → "Huddlex" headline (bold, deepPlum) → tagline (deepPlum 60%) → \[name field, sign-up only] → email → password (min 6) → coral filled submit (spinner-in-button while loading) → "Forgot password?" right-aligned text button (sign-in only; dialog w/ email field) → outlined Google button → mode-toggle text button → 11sp legal footer with underlined coral Terms/Privacy links (CustomTabs). Errors via snackbar.

### VerifyEmailScreen
Seashell, left-aligned column, 28/32 padding: sign-out icon top-left → "Verify your email" 28sp w700 → description w/ email address (deepPlum 70%) → **6 code boxes** 46×56dp, white r12, 1dp plum-12% border, active box coral 2dp border, 22sp w700 digits; hidden input captures digits (numeric only, OTP autofill) and auto-submits at 6 → coral error / plum-70% info text → Spacer → centered resend button ("Resend in Ns" countdown, disabled while verifying) → spinner under it when verifying. Auto-requests a code on first entry; wrong code clears field and refocuses.

### OnboardingScreen
Skip top-right → HorizontalPager of 5 cards: 140dp gradient tile (r40) w/ 64dp white icon (celebration, meeting-room, timer, widgets, place), 26sp bold title, 15sp/1.5 body (plum 70%) → animated dot indicators (selected: 18×8 coral pill; rest: 8×8 plum-20%) → full-width coral button "Next"/"Get started" (spinner while finishing).

### HomeScreen + FeedTab
Material 3 `NavigationBar`: Feed (home), Rooms (meeting_room), Account (person). Feed scaffold: transparent centered app bar, **coral camera icon as `leading` (top-left)** — deliberately not a FAB, so the countdown chip is never covered — title "Huddlex" bold. Body: `OfflineBanner` pinned above content → pull-to-refresh (coral) → states: no rooms (100dp softPink-30% r30 tile + meeting-room icon + copy), empty feed (80dp camera-outline plum-20% + copy), else **vertical pager**, one post per page.
**Post card**: header row centered — optional warmOrange star (favorite room) + "Sender · Room" 16sp w600 → photo fills remaining height, r24 clip, Coil crossfade 350ms, softPink-30% placeholder w/ spinner, broken-image fallback; tap → PhotoViewer (shared-element `post_{id}`), long-press → post actions sheet → optional caption 14sp centered (plum 85%) → bottom row centered: LikeButton + **countdown chip** (coral-10% pill r20, timer icon + "Xh Ym remaining"/"Expired" in coral w600).

### CameraScreen (Locket-style — see MEMORY: minimal Locket UI preferred)
Background `#0B0B0E` (cinema dark, not pure black). **Live mode**: centered 3:2 preview card r28 (padding 16,72,16,200), cover-fit preview; "Huddlex" wordmark top-center (white 60%, 14sp w700, letterSpacing 1.2); **glassy circular buttons** (translucent white-10% disc, white-18% 0.5dp border, backdrop blur ~14): close top-left (44dp), flash top-right (coral tint when torch on), gallery (52dp) / **shutter** / flip (52dp) evenly spaced along bottom (28dp inset). **Shutter**: 84dp circle, 4dp white ring, 5dp gap, coral→warmOrange gradient core (topLeft→bottomRight); scales to 0.9 on press (120ms easeOut); capture = medium haptic + white full-screen flash overlay spiking to 70% opacity then fading ~140ms. No-rooms state: dark screen + centered white-70% copy.
**Review mode**: photo stays in the same 3:2 r28 card (continuous transition; bottom padding grows to 280); close/retake glassy button top-left (discards + re-inits camera on the same lens); bottom **glass panel** — backdrop blur 16, black-35% fill, hairline white-8% top border, padding (20,16,20,24) — containing: caption field (white-8% fill r18, white-12% hairline border, coral 1dp focus, white 15sp text, white-45% hint, max 140 chars 2 lines, no counter) → target pills (Wrap, centered): "Active (n)" / "All rooms (n)" / "Pick rooms" — selected pill coral filled white text, unselected white-8% + white-18% border, animate 150ms → if Pick: room-name chips same pill style, multi-select → **send button** 54dp full-width r18, coral→warmOrange horizontal gradient, coral-40% glow shadow (blur 18, offset y6), "Post" 16sp w700 + arrow icon, spinner while sending. Result snackbar (live/pending/mixed) then pop.

### RoomsScreen
App bar "My Rooms" bold + search action (→ Join). List (16 padding) sorted favorites-first-then-newest of white r16 tiles: 26dp-radius avatar (photo or softPink circle w/ coral initial) · name 16sp w700 + tiny public/lock icon · "N members · Code: XXXXXX" 12sp plum-60% · star toggle (warmOrange when fav) · bell toggle (coral `notifications_active` when active, muted `notifications_off` otherwise). Empty state mirrors feed's, plus outlined "Join" + filled "Create" buttons. Coral extended FAB "Create room".

### CreateRoomScreen
Scroll form: centered 48-radius avatar picker (softPink-40% bg, coral camera icon, coral edit badge bottom-right) + helper text → "Name" title + text field (≤40) → "Who can join" + two selectable cards (Public/globe, Permission/lock): white r14, coral 2dp border + coral check icon when selected → full-width create button w/ spinner. On success **replace**-navigate to RoomDetail.

### JoinRoomScreen
List: white card "Have a code?" — centered 24sp bold letter-spaced 6-char field (auto-caps) + "Join by code" button → "Search public rooms" section: search field (white fill r14, search icon), 300ms debounce → spinner / "No results" / result tiles (avatar + name + member count + compact coral "Join" `FilledButton`) → footer hint about permission rooms. Public: instant join → RoomDetail (replace). Permission: request-sent snackbar → pop.

### RoomDetailScreen
App bar: room name + settings gear (tooltip differs admin/member). Body: vertical pager of post cards — same as feed card minus the room name/star (sender only, hero tag `roompost_{id}`). Empty state camera-icon + copy. Blocked senders filtered.

### RoomSettingsScreen
App bar "Settings" + rename pencil (creator only → dialog, writes name+nameLower). ListView:
1. **Header card** — 32-radius avatar (admins tap to change; upload spinner overlay; coral edit badge), name 20sp bold, visibility icon+label.
2. **Code card** — coral→warmOrange gradient r16: "Room code" white-70, code 32sp bold white letter-spacing 8, Copy (clipboard+snackbar) and Share (system ShareSheet w/ localized message) text buttons in white-70.
3. *(admin)* **Moderation card** — white r12: "Require post approval" switch (coral thumb) + subtitle; when on, divider + "Review pending posts" row (coral inbox icon, chevron) → PendingPostsScreen.
4. *(admin)* **Location lock card** — switch (enabling with no pin immediately pins current location); pin row (coral place icon + "lat, lng" 5-dp or "not set" w/ location_disabled); "Use my current location" text button w/ spinner; "Radius" label + ChoiceChips `50 m / 200 m / 500 m / 1 km / 5 km` (disabled until pinned). Typed failure snackbars per LocationFailure.
5. *(admin, permission rooms)* **Join requests** — white cards: avatar + name + green check / red cancel icon buttons; "No pending requests" empty card.
6. **Members (N)** — white cards: avatar + name + "Creator" (coral 11sp) / "Admin" (plum-60%) sublabel; coral `verified` icon for trusted non-admins (tooltip); admin popup menu on others (never creator): Make/Remove admin, Mark/Remove trusted (non-admins), Remove from room (red, confirm dialog).
7. Footer: Leave room (red outlined; hidden when sole member), Report room (muted text button → reason dialog ≤280), Delete room (red outlined, admin, confirm) — leave/delete pop to root.

### PendingPostsScreen
App bar "Pending · {room}". List of white r16 cards: sender chip (14-radius avatar + name) → square (1:1) image → caption → Reject (red outlined, deletes) / Approve (coral filled, flips pending=false) side by side. Empty: centered muted copy.

### AccountScreen
App bar "Account". List (20 padding):
1. **Profile card** white r20 soft shadow: 30-radius avatar (coral bg white initial fallback), name 20sp bold, email plum-60%, "N rooms" 12sp, coral edit icon → EditProfile.
2. **Streak card** (only if `currentStreak > 0`): coral→warmOrange gradient r16, white 36dp fire icon, "N-day streak" 18sp bold white, subtitle "Best: M days" if best > current else "Keep it going!".
3. **Active rooms** / **Favorite rooms** sections (title 18sp bold + 12sp description): white r12 rows (avatar, name, letter-spaced code) or muted empty card.
4. **Blocked users**: rows w/ "Unblock" text button, or empty card.
5. **Language**: white r12 ListTile (language icon, current display name subtitle, chevron) → bottom sheet: drag handle, title, "System default" + 8 languages, coral check on current.
6. **Feedback**: coral feedback icon ListTile → mailto `obaidabakjaji@gmail.com` (encoded subject/body), failure snackbar.
7. **Legal**: Terms / Privacy ListTiles (open-in-new 16dp) → CustomTabs.
8. Sign out (red outlined, icon) → AuthScreen clearing back stack; Delete account (dim red text button) → confirm dialog → cascade; `requires-recent-login` → reauth snackbar.

### EditProfileScreen
App bar + "Save" text action (spinner when saving). Body: 56-radius avatar picker (coral edit badge, initial fallback) + "Tap to change" hint → display-name field (≤40, word caps) → email shown read-only (plum-50%). Save = optional upload to `profile_photos/{uid}/` + diff-only update; pop on success.

### Shared components
- **LikeButton**: pill r20 (coral-15% when liked, plum-6% otherwise), 16dp heart (filled coral / outline plum-60%), count ≥1 in 13sp w600; like triggers 1.0→1.35→1.0 bounce (280ms easeOut); long-press (when likedBy non-empty) opens LikedBySheet.
- **LikedBySheet**: modal sheet r20 top, drag handle 36×4, "❤ Liked by N" header, avatar+name list; draggable 0.3–0.9, initial 0.5.
- **PostActionsSheet**: r20 top sheet — others: Report (flag, reason dialog ≤200) + Block (block icon, confirm, "{name} blocked" snackbar); own: Delete (confirm) — all destructive icons red.
- **PhotoViewer**: black fullscreen, shared-element hero, pinch-zoom 1–4×, tap or fast vertical fling (>300) dismiss, white close top-right, caption in black-50% r12 pill bottom.
- **OfflineBanner**: deepPlum full-width strip, cloud-off + "You're offline" white 13sp, 200ms animated size collapse.
- **Shimmer**: softPink alpha .15/.35/.15 gradient sweeping horizontally, 1200ms loop, list variant 5 × r12 tiles.
- **ErrorView**: 64dp cloud-off plum-30%, message plum-70% 15sp, optional outlined retry.

---

## 4. MIGRATION CHECKLIST

### Phase 1 — Project skeleton + Auth
- [ ] New Compose app module: Kotlin 2.x, Compose BOM, Hilt, Navigation-Compose, Coil, Firebase BoM, google-services.json for `momento-app-64950`, applicationId `com.momento.momento` (keep — widget receiver package + Firebase android app depend on it)
- [ ] Port theme (colors/typography/shapes per §3 header); seashell scaffold; 52dp button styles
- [ ] Convert 8 ARB files → `strings.xml` per locale (incl. plurals + positional args); enable `supportsRtl`; audit `start/end` usage for `ar`
- [ ] `AuthRepository` with **`userChanges`-equivalent flow (B1)**: AuthStateListener merged with post-`reload()` re-emit; unit test: reload after emailVerified flip re-emits
- [ ] Email sign-up (create user doc via `AppUser.toMap()` defaults), sign-in, password reset, Google sign-in via Credential Manager (serverClientId from §1.3), first-time doc creation
- [ ] `requestEmailCode`/`verifyEmailCode` callable wrappers + `EmailCodeException` mapping table (B13); `verify` calls reload
- [ ] AuthScreen, VerifyEmailScreen (6-box field, auto-request, cooldown regex, sign-out), AuthGate composable with the 4-way route + user-doc-null spinner
- [ ] App Check (debug provider registered in console; Play Integrity release), Crashlytics
- **Parity acceptance:** email sign-up lands on Verify; correct code routes onward without restart; Google sign-in skips Verify; unverified relaunch re-gates; wrong/expired/cooldown codes show mapped messages; onboarding flash never appears during doc-creation race.

### Phase 2 — Data layer (repositories + models)
- [ ] Port 4 models with identical Firestore field names/defaults; **unit-test `Room.requiresApprovalFor` truth table** (admin/trusted/member × approval × geofence in/out/null-GPS) (B2/B3)
- [ ] `UserRepository` (watchUser flow, getUsers 30-chunk), `RoomRepository` (all 25+ ops of §1.3), `StorageRepository` (3 upload paths), `ModerationRepository`, `LocationRepository` (FusedLocation, 10s timeout, typed failures), `LocaleRepository`
- [ ] `postToRooms`: single WriteBatch, per-room pending computation, `PostResult`, streak transaction fired after commit, non-blocking, swallow-all (B9); unit-test dayKey math incl. DST/local-midnight and month boundaries
- [ ] Room code generator (alphabet, secure random, 8 retries, uppercase lookup)
- [ ] `searchPublicRooms` prefix query with `` upper bound + limit 15
- [ ] Verify every mutation against `firestore.rules` (esp. cross-user array-only updates in join/approve/kick batches — B13)
- **Parity acceptance:** posting to N mixed rooms from the native client is accepted by the *unchanged* production rules for every role combination; Flutter client can read everything the native client writes and vice versa.

### Phase 3 — Home shell + Feed
- [ ] HomeScreen bottom nav (3 tabs, state preserved per tab)
- [ ] `FeedViewModel`: watchUser → source rooms (active-else-all) → `combine()` of per-room `watchRoomPosts` flows (each already filtering expired+pending) → block filter → favorite-first sort (B10/B12)
- [ ] Post card (header/star, photo r24 crossfade, caption, LikeButton, countdown chip), vertical pager, empty + no-rooms states, ErrorView, ShimmerList
- [ ] OfflineBanner via ConnectivityManager callback flow (all-none = offline)
- [ ] LikeButton (optimistic + rollback + bounce), LikedBySheet, PostActionsSheet (report/block/delete), PhotoViewer (zoom + fling dismiss + shared element)
- [ ] Pull-to-refresh (coral) — recollect streams
- [ ] Countdown chip ticks (recompose ≥1/min) and shows "Expired" for negative remaining
- **Parity acceptance:** two devices in one room see each other's posts live; expired posts vanish without restart (on next emission/tick); blocked sender disappears from feed+room detail immediately; like from device A bounces count on device B; long-press flows all work.

### Phase 4 — Camera + posting
- [ ] CameraX: rear-default, flip cycles lenses, torch toggle (coral tint), 3:2 preview card cover-fit, capture w/ haptic + white flash overlay
- [ ] Photo Picker gallery path (≤1080px q85 downscale)
- [ ] EXIF-honoring center-square crop → JPEG q88 to cache (B13 crop contract)
- [ ] Review screen: glass panel, caption ≤140, target pills + custom chips, gradient send button
- [ ] Conditional GPS: only when a target room has an active lock and sender isn't its admin; failure → null coords → pending (fail-closed, B3)
- [ ] Upload → `postToRooms` → `PostResult` snackbar (3 message variants) → **`widgetUpdater.refreshForUser(uid, force = true)`** fire-and-forget (B8) → pop
- [ ] Camera lifecycle: release on review/exit, re-init same lens on retake
- **Parity acceptance:** portrait/landscape captures render upright and square in feed AND widget; posting to a locked room from outside (or with GPS denied) lands pending and shows "sent for approval"; admin posting anywhere is always live; widget shows the new photo within seconds of posting.

### Phase 5 — Rooms (list/create/join/detail/settings/pending)
- [ ] RoomsScreen (sort, star + bell toggles writing favorite/active arrays), empty state, FAB
- [ ] CreateRoomScreen (photo upload, visibility cards, replace-nav)
- [ ] JoinRoomScreen (code path w/ exact-6 validation + uppercase; debounced search excluding joined rooms; public join vs permission request flows)
- [ ] RoomDetailScreen (block-filtered pager)
- [ ] RoomSettingsScreen: header/avatar change, code card (copy + ShareSheet), moderation card, **location-lock card** (auto-pin on enable, radius chips, typed error snackbars, clearLocationLock keeps pin), join requests, member management menu (promote/demote/trust/untrust/kick w/ confirm), leave/report/delete flows w/ pop-to-root
- [ ] PendingPostsScreen (approve flips pending=false; reject deletes)
- **Parity acceptance:** permission-room request → admin approve adds member and removes request (rules accept the cross-user batch); trusted member posts live in approval-gated room; untrusted member's post appears in admin queue and (after approve) in members' feeds; kick removes room from kicked user's lists in real time; sole-member leave deletes the room.

### Phase 6 — Account, onboarding, i18n polish
- [ ] AccountScreen (profile, streak card, room lists, blocked+unblock, language sheet, feedback mailto w/ `%20` encoding, legal CustomTabs, sign out, delete-account w/ reauth snackbar)
- [ ] EditProfileScreen (avatar upload, diff-only save)
- [ ] OnboardingScreen (5 cards, skip, `hasSeenOnboarding` write; stream-driven nav)
- [ ] Locale override via AppCompatDelegate + persisted choice; decide on the dismiss-resets-to-system quirk (B13) and document
- [ ] RTL pass on every screen with `ar`
- **Parity acceptance:** delete-account on a user in 3 rooms (one as sole member) scrubs all memberships, deletes the solo room, removes user doc + auth; fresh sign-in shows onboarding exactly once; streak card matches Firestore after posting across two days.

### Phase 7 — Widget pipeline (highest-risk phase — see MEMORY: binder limit first)
- [ ] `WidgetUpdater` (singleton): port `refreshForUser`/`updateWidgetWithPosts`/`clearWidget` with throttle+force+in-flight (B8), persisted signature semantics incl. partial-failure `''` (B6), all 12+1 prefs keys byte-compatible into `HomeWidgetPreferences` (B11), per-index `widget_momento_{i}.jpg` files, OkHttp downloads
- [ ] Trigger receiver via `AppWidgetManager.notifyAppWidgetViewDataChanged`/update broadcast equivalent to `HomeWidget.updateWidget`
- [ ] `WidgetRefreshWorker` (CoroutineWorker + Hilt): unique periodic work `huddlex-widget-refresh`, 15 min, CONNECTED, REPLACE (B13)
- [ ] App-resume hook (`ON_RESUME` observer) → non-forced refresh
- [ ] Feed collection side effect → `updateWidgetWithPosts(take(20))` (B12)
- [ ] Keep `MomentoWidgetReceiver` untouched; confirm `POST_LIFETIME` constant now shared from one module (B4); bump hash key to `_v7` **only if** any render-affecting change ships
- [ ] Test matrix: reboot re-arms alarm; force-stop then widget-update re-arms; all-expired overnight → widget clears without app open; airplane-mode partial downloads retry next cycle; 5+ posts → exactly 5 cards; single post → static card (no flipper); no binder rejection at 400px/RGB_565
- **Parity acceptance:** signature-unchanged refresh performs zero downloads and zero widget broadcasts (verify via logs); posting force-refreshes through the 5s throttle; expired photo leaves the widget within ~6h+5s+doze-window with the app closed.

### Phase 8 — Release
- [ ] Firestore + Storage rules re-published (manual, Firebase Console) if any rule change was needed — target: **zero rule changes**
- [ ] App Check enforced; release signing; Play Integrity verified on a real device
- [ ] Crashlytics symbol upload; ProGuard/R8 rules for Firebase + model classes (keep `fromSnapshot` reflection-free so R8 is safe)
- [ ] Permissions audit in manifest: CAMERA, ACCESS_FINE/COARSE_LOCATION, INTERNET, POST_NOTIFICATIONS **not** needed (no push), photo-picker needs no storage perms
- [ ] Migration path for existing installs: same applicationId + same prefs keys ⇒ widget keeps rendering across the app update; verify update-in-place from the Flutter build on a device with a live widget
- [ ] Locale strings proofread per language; legal URLs live (`huddlex.app`)
- [ ] Side-by-side regression: run Flutter iOS build against native Android build in the same rooms for a full 6h post lifecycle
- [ ] Store listing assets; versionCode continues from Flutter build number

---

## 5. RISK REGISTER — top 10 regressions

| # | Risk | Why it will bite | Mitigation |
|---|---|---|---|
| 1 | **Auth gate never re-routes after email verification** (B1) | Android `AuthStateListener` ≙ `authStateChanges()` — the exact API the Dart code deliberately avoids. Users get stuck on VerifyEmailScreen forever. | Build `authFlow` on userChanges semantics (merge listener + post-reload re-emit or IdTokenListener); instrumented test: verify → auto-route without restart. |
| 2 | **Widget updates silently rejected over binder limit** (B5) | Coil/native decode defaults to ARGB_8888 and full resolution; the launcher gives no error. Weeks of "widget randomly stuck" reports. | Never touch the receiver's decode path; keep 400px/RGB_565/5 cards; log payload size in debug; MEMORY rule: bitmap size is the FIRST suspect. |
| 3 | **Pending flag computed differently from rules → whole multi-room post batch rejected** (B2) | One atomic WriteBatch; a single mismatched `pending` fails every room's post with a permission error. | Port `requiresApprovalFor` verbatim; truth-table unit tests + Firestore rules emulator tests before Phase 4 ships. |
| 4 | **Signature dedup semantics drift** (B6) | Easy to "simplify" into an in-memory cache or persist the signature on partial download failure — both were real production bugs (image re-download storms; expired photos never clearing; photos not appearing until the 3rd post). | Port `updateWidgetWithPosts` line-for-line incl. the `''`-on-partial-failure branch; tests for: unchanged skip, empty-already-cleared skip, partial-failure retry, all-failed clear. |
| 5 | **Expiry alarm not re-armed after reboot/force-stop** (B7) | If the native writer stops triggering `APPWIDGET_UPDATE` the way home_widget did, the receiver never gets its re-arm opportunity; expired photos linger indefinitely. | Keep the receiver untouched and ensure every data push lands as a real `onUpdate`; reboot + force-stop test in Phase 7 matrix. |
| 6 | **Geofence fail-open** (B3) | The intuitive native default ("no GPS → just post") inverts the security posture of locked rooms. | Preserve null-coords→pending; test with location permission denied, services off, and 10s timeout; keep "skip GPS when no locked target" to avoid permission-prompt regressions. |
| 7 | **6h constant drifts between the three sites** (B4) | Feed uses `expiresAt`, widget uses `createdAt + POST_LIFETIME_MS` — a change to one silently desyncs feed vs widget expiry. | Single `POST_LIFETIME` in `:core` consumed by repository, feed filter, and receiver; comment cross-references; assertion test `expiresAt - createdAt == POST_LIFETIME`. |
| 8 | **Cross-user Firestore writes rejected by rules** (B13) | Join/approve/kick batches update *another user's* doc; rules only allow `roomIds/activeRoomIds/favoriteRoomIds`. Adding any field (e.g. a timestamp) breaks joins in production, and rules deploys are manual. | Rules-emulator integration tests for join, approve, kick, leave, delete-room; freeze batch payloads; target zero rules changes. |
| 9 | **EXIF orientation lost in native crop → sideways widget photos** (B13) | `BitmapFactory` ignores EXIF (the original bug); Dart's `image` package fixed it by decoding+applying orientation before crop. | Apply ExifInterface rotation (or `ImageDecoder`) before center-crop; device test portrait + landscape + front camera, verify in feed **and** widget. |
| 10 | **Throttle/force refresh races** (B8) | Naive coroutine port can let camera-post and app-resume refreshes interleave → duplicated downloads or a stale final state; or force can be dropped by the throttle. | Single `WidgetUpdater` with `Mutex.tryLock` in-flight guard; force bypasses only the time throttle, never the in-flight guard; concurrency test firing resume+post+worker simultaneously. |
| 11 | **Repo `firestore.rules` would break the feed if published as-is** (found in Phase 2 review) | Both clients (Dart `watchRoomPosts` and the Kotlin port) issue an UNFILTERED posts query; the rewritten-but-unpublished rules file gates post reads on `pending`/`senderId`, and Firestore "rules are not filters" would deny the whole listen for non-admin members — a permanently empty feed in BOTH apps the moment the repo rules are published. The apps work today only because the DEPLOYED rules differ from the repo file. | Before re-publishing rules (deferred pre-launch task): either make the feed query provable (client adds `whereEqualTo("pending", false)` + composite index in both apps simultaneously) or rewrite the posts read rule so a member listen is allowed wholesale. Same review also noted: re-requesting to join while a request is pending hits `allow update: if false` (minor, inherited). |

---
*Cross-references: `app/firestore.rules` (authoritative access contract), `app/android/.../MomentoWidgetReceiver.kt` (authoritative widget render contract), memory notes: rooms pivot, minimal Locket UI, widget bitmaps/binder limit.*
