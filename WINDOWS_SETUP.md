# Huddlex — Windows Development Setup (Handoff)

Guide for continuing development on a Windows machine. Written 2026-06-14 when
the Mac ran out of disk space mid-session. Android-only: iOS work still needs
the Mac (Xcode).

## 1. Install prerequisites

1. **Git for Windows** — https://git-scm.com/download/win
2. **Flutter SDK** — https://docs.flutter.dev/get-started/install/windows
   (extract e.g. to `C:\src\flutter`, add `C:\src\flutter\bin` to PATH)
3. **Android Studio** — https://developer.android.com/studio
   (bundles the JDK and Android SDK; during setup install "Android SDK
   Platform-Tools" so `adb` is available)
4. **Claude Code** — https://claude.com/claude-code
5. Run `flutter doctor` and fix anything it flags (accept Android licenses
   with `flutter doctor --android-licenses`).
6. Phone connection: enable USB debugging on the S23 Ultra (already on),
   plug in, accept the new computer's debugging prompt. If `adb devices`
   shows nothing, install the Samsung USB driver:
   https://developer.samsung.com/android-usb-driver

## 2. Clone and restore secrets

```bat
git clone https://github.com/obaidabakjaji-ui/momento-app.git
cd momento-app
flutter pub get
```

Three files are **deliberately NOT in git** (secrets). Copy them from the Mac
(USB stick / private cloud) into the same relative paths:

| Copy from Mac                                        | Place in clone at                       |
|------------------------------------------------------|-----------------------------------------|
| `app/android/app/upload-keystore.jks`                | `android/app/upload-keystore.jks`        |
| `app/android/key.properties`                         | `android/key.properties`                 |
| `app/android/app/google-services.json`               | `android/app/google-services.json`       |

Notes:
- Mac project root is `/Users/m.bak4/Desktop/momento/app/`.
- `key.properties` uses a relative `storeFile=upload-keystore.jks`, so it
  works unchanged on Windows.
- The keystore password is in `key.properties` (and should also be in your
  password manager). **If the keystore is lost, release builds get a new
  signature: Google sign-in breaks until new SHA fingerprints are added in
  Firebase, and testers must uninstall/reinstall.**
- Without `google-services.json` the Android build fails at the
  `processReleaseGoogleServices` step.

## 3. Build / install / iterate

```bat
:: analyze
flutter analyze

:: release build (the one testers + the widget get)
flutter build apk --release

:: install + launch on the S23 Ultra
adb install -r build\app\outputs\flutter-apk\app-release.apk
adb shell monkey -p com.momento.momento -c android.intent.category.LAUNCHER 1

:: watch widget/app logs
adb logcat | findstr /i "HuddlexWidget WidgetService flutter"
```

## 4. ⚠ Current state — read before doing anything

### TESTING values left in the code (revert before any tester build!)
Post expiry is temporarily **30 seconds** instead of 6 hours, in two places,
both marked `TESTING ONLY`:
- `lib/services/room_service.dart` → `Duration(seconds: 30)` → revert to
  `Duration(hours: 6)`
- `android/app/src/main/kotlin/com/momento/momento/MomentoWidgetReceiver.kt`
  → `30L * 1000L` → revert to `6L * 60L * 60L * 1000L`

### Open bug (unresolved at handoff)
**Posting fails with "Firebase Storage: unknown error".** Appeared on the
last installed build; not yet diagnosed. Top suspect: App Check enforcement
was flipped on for Cloud Storage in Firebase Console (sideloaded release
builds fail Play Integrity attestation). Check Firebase Console → App Check →
APIs → Cloud Storage; if "Enforced", set to Unenforced and retry posting.
If that's not it: reproduce while running `adb logcat` and look for
`StorageException` / HTTP status lines.

### Not-yet-verified on device
- The widget fix "photos not appearing until 3rd post" (download-retry +
  force-refresh after posting) — built + installed but blocked from testing
  by the Storage bug above.

### Deliberate decisions (don't "fix")
- Whole-widget tap opens the app. No tap zones, no double-tap-to-like
  (removed on request).
- No push notifications, no comments (product decisions).
- Widget bitmaps are downsampled to 400px RGB_565, max 5 cards — this is a
  hard RemoteViews ~1MB binder-limit constraint. Never ship full-res
  bitmaps to the widget (that was the root cause of weeks of silent widget
  failures).
- Bundle IDs stay `com.momento.momento` (Android) / `com.mbak4.momento`
  (iOS dev). UI brand name is "Huddlex"; internal identifiers stay
  "momento".

### Pending before beta invite
- Revert the 30-second expiry (above).
- Resolve the Storage posting bug.
- Bump version in `pubspec.yaml` (still `1.0.0+1`) so Crashlytics can tell
  builds apart.
- App Check: registered, debug token added, **enforcement intentionally
  OFF** — flip Firestore + Storage to Enforced only at ship time, and be
  aware sideloaded builds may then need the debug provider or a Play
  Internal Testing track.
- Firestore/Storage rules: any edits to `firestore.rules` / `storage.rules`
  must be manually pasted + published in Firebase Console (no CLI set up).

## 5. Firebase quick reference

- Project: `momento-app-64950` (console.firebase.google.com)
- Auth: email+code verification via Cloud Functions (us-central1) + Google
  sign-in (SHA-1/SHA-256 registered for BOTH debug and release keystores)
- Crashlytics: wired, collection enabled in release builds only
- Widget data flow: Firestore → `WidgetService.refreshForUser()` (Dart,
  throttled 5s, signature-deduped) → SharedPreferences via home_widget →
  `MomentoWidgetReceiver.kt` (hash-deduped, `last_data_hash_v5`) →
  RemoteViews. Background refresh: hourly workmanager job + app-foreground
  hook + force-refresh after posting.
