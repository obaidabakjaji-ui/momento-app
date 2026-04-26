# CLAUDE.md — iOS Widget Setup (Mac)

This file provides guidance to Claude Code for completing the iOS widget extension setup on macOS.

## Context

Momento is a Flutter app with a native iOS home screen widget. The Flutter app and widget Swift code are already written and working on Android. The iOS widget extension target has been added to Xcode and all setup steps below are complete.

## What's Already Done

- Flutter app is complete and working (auth, camera, feed, linking, account)
- `ios/MomentoWidget/MomentoWidget.swift` — full widget code (photo rotation, sender names, page indicators)
- `ios/MomentoWidget/Info.plist` — widget extension plist
- Firebase is configured (Auth, Firestore, Storage)
- `home_widget` Flutter package handles Flutter-to-native widget communication
- Android widget is fully working
- **Flutter dependencies installed** (`flutter pub get` completed)
- **CocoaPods installed** via Homebrew (`brew install cocoapods`)
- **Podfile updated** — iOS deployment target set to 15.0 (required by cloud_firestore/Firebase SDK 12.9.0)
- **`flutter precache --ios` run** — downloaded Flutter.xcframework needed by pod install
- **`pod install` completed** successfully
- **Xcode Widget Extension target created** — MomentoWidgetExtension, deployment target iOS 17.0
- **Auto-generated Swift files deleted** from MomentoWidgetExtension group
- **MomentoWidget.swift added** to MomentoWidgetExtension target
- **App Groups enabled** on Runner target: `group.com.momento.momento`
- **App Groups enabled** on MomentoWidgetExtension target: `group.com.momento.momento`
- **Signing configured** — Apple ID added to Xcode, team set to Personal Team on both targets
- **Bundle IDs changed** for Personal Team development (see below)

## Completed Setup Steps (for reference)

### Step 1: Dependencies (DONE)

```bash
# Install CocoaPods (requires Homebrew — install Homebrew first if missing)
brew install cocoapods

# Install Flutter dependencies
cd app
flutter pub get

# Download Flutter engine artifacts (required before pod install)
flutter precache --ios

# Install iOS pods
cd ios && pod install && cd ..
```

**Podfile changes made** (`ios/Podfile`):
- Set `platform :ios, '15.0'` at the top (cloud_firestore requires iOS 15.0 minimum)
- Added `config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'` in the `post_install` block

### Step 2: Xcode Setup (DONE)

All steps below were completed manually in Xcode via `ios/Runner.xcworkspace`:

1. **File → New → Target → Widget Extension**
   - Product Name: `MomentoWidgetExtension`
   - Unchecked "Include Live Activity" and "Include Configuration App Intent"
   - Clicked Finish, then "Activate" scheme
   - Changed deployment target to iOS 17.0 (Xcode auto-set it too high)

2. **Deleted auto-generated Swift files** in the MomentoWidgetExtension group

3. **Added MomentoWidget.swift** to MomentoWidgetExtension target:
   - Right-click MomentoWidgetExtension in sidebar → Add Files to "Runner"
   - Selected `ios/MomentoWidget/MomentoWidget.swift`
   - Checked "MomentoWidgetExtension" target in the dialog

4. **Enabled App Groups on Runner target:**
   - Runner → Signing & Capabilities → + Capability → App Groups → added `group.com.momento.momento`

5. **Enabled App Groups on MomentoWidgetExtension target:**
   - MomentoWidgetExtension → Signing & Capabilities → + Capability → App Groups → added `group.com.momento.momento`

6. **Signing configured on both targets:**
   - Added Apple ID via Xcode → Settings → Accounts
   - Team: M BAK4 (Personal Team) on both Runner and MomentoWidgetExtension

7. **Bundle IDs changed for Personal Team** (original `com.momento.momento` is registered to a different Apple account):
   - Runner: `com.mbak4.momento`
   - MomentoWidgetExtension: `com.mbak4.momento.MomentoWidgetExtension`

### Step 3: Build and run (DONE)

The "Cycle inside Runner" build error is fixed. Root cause and fix:

**Root cause:** Thin Binary phase had `${TARGET_BUILD_DIR}/${INFOPLIST_PATH}` as an inputPath, creating a dependency cycle when Embed Foundation Extensions is present.

**Fix applied (project.pbxproj):**
1. Moved `Embed Foundation Extensions` BEFORE `Thin Binary` in Runner build phases
2. Removed `${TARGET_BUILD_DIR}/${INFOPLIST_PATH}` from Thin Binary's `inputPaths` (set to empty array)

The app builds and installs on the physical iPhone successfully.

### Step 4: Fix app crash on launch (DONE)

The crash had two root causes, both fixed:

1. **Missing iOS permission strings** — `Info.plist` had no `NSCameraUsageDescription` or `NSPhotoLibraryUsageDescription`. iOS silently freezes the app when an image picker is opened without these declarations. **Fix:** added both to `ios/Runner/Info.plist`.

2. **Firestore rules not deployed** — the new Rooms-model rules existed in `firestore.rules` but the old friend-graph rules were still active in Firebase. The feed query failed with "Missing or insufficient permissions" causing infinite loading on the white screen. **Fix:** published `firestore.rules` to the Firebase Console.

Also fixed:
- **Composite-index requirement** — `watchRoomPosts` originally used `where expiresAt > now` + `orderBy expiresAt` + `orderBy createdAt`, requiring a composite index per room. Simplified to `orderBy createdAt desc` with client-side expired filtering, no index needed.

### Step 5: Test the widget (next session)

The app launches, builds, posts, likes, blocks, and onboards correctly on iPhone 13. Widget testing on the physical device is the only thing left:

1. Long-press the home screen → tap "+" (top left)
2. Search "Momento" in the widget gallery
3. Add the small or medium widget
4. Post a photo from another logged-in account to a room you both belong to
5. Verify the photo appears in the widget without opening the app
6. Verify favorite-room posts get the star overlay (iOS) / "★ " prefix (Android)

### Step 6: iOS Simulator setup (DONE — verified on iPhone 17 Pro / iOS 26.1)

Three simulator-specific issues had to be fixed before sign-in worked:

1. **Firebase Auth `keychain-error`** — root cause was building with `flutter build ios --simulator --debug --no-codesign`. `Runner.entitlements` declares `keychain-access-groups = $(AppIdentifierPrefix)com.mbak4.momento`. The `$(AppIdentifierPrefix)` macro is only substituted by `codesign`, so with `--no-codesign` the entitlement got embedded as the literal `$(AppIdentifierPrefix)com.mbak4.momento` string and iOS rejected every `SecItem*` call with `errSecMissingEntitlement`, which Firebase wraps as `keychain-error`. **Fix:** always build the simulator binary WITHOUT `--no-codesign` so the ad-hoc signing step substitutes the macro to the real team prefix `357VDTVW3T`. Verify embedded entitlements with:
   ```bash
   codesign -d --entitlements - --xml build/ios/iphonesimulator/Runner.app
   # Should NOT be empty <dict></dict> — must contain application-groups + keychain-access-groups
   ```
   Or check the simulator-substituted form Xcode generates per build:
   ```bash
   strings ~/Library/Developer/Xcode/DerivedData/Runner-*/Build/Intermediates.noindex/Runner.build/Debug-iphonesimulator/Runner.build/Runner.app-Simulated.xcent.der
   ```

2. **Widget didn't appear in the gallery** — widget extension `MinimumOSVersion` was 26.4 (auto-set by newer Xcode) but the simulator was running iOS 26.1. iOS hides widgets whose min OS isn't met. **Fix:** lowered widget target's `IPHONEOS_DEPLOYMENT_TARGET` from `26.4` to `17.0` in `Runner.xcodeproj/project.pbxproj` (3 occurrences in the widget target's build configs). Main Runner target stays at 13.0; pods enforce 15.0.

3. **Sandbox out-of-sync** error from Xcode — `Podfile.lock` got out of sync. **Fix:** `cd ios && pod install`. (Don't trust Xcode's UI showing "Build Failed" in stale state — `flutter build ios --simulator --debug` from CLI bypasses Xcode UI cache.)

After those: reset the simulator keychain (clears any stale entries from prior failed attempts), then install + launch:
```bash
SIM=$(xcrun simctl list devices booted | grep -oE '[0-9A-F-]{36}' | head -1)
xcrun simctl uninstall "$SIM" com.mbak4.momento
xcrun simctl keychain "$SIM" reset
xcrun simctl install "$SIM" build/ios/iphonesimulator/Runner.app
xcrun simctl launch "$SIM" com.mbak4.momento
```

### Step 7: Widget visual refinement (DONE)

Modern WidgetKit applies default content margins (~16pt insets), which made photos look bordered. Removed via `.contentMarginsDisabled()` on the `WidgetConfiguration` (in `MomentoWidget.swift`). But this surfaced a SwiftUI sizing quirk:

- `Image.aspectRatio(.fill)` lets the image overflow its parent for cropping.
- That oversized image was driving the `ZStack`'s size, pushing the text overlay outside the visible widget shape — sender names showed up clipped on the left.
- **Fix:** wrap the `SmallPhotoView` body in `GeometryReader { geo in ... }`, set the image `.frame(width: geo.size.width, height: geo.size.height).clipped()`, and lock the outer ZStack to the same frame. Now padding works normally.

Typography is intentionally light: 9pt medium chip text, 11pt medium sender name, 9pt regular room/likes line — see `BottomLabel` and `Chip` in `MomentoWidget.swift`. iOS aggressively caches widget rendering — after any code change the user must remove the widget from the home screen and re-add it to see updates.

### Reminder for future sessions

- **There are two copies** of the widget Swift file: `ios/MomentoWidget/MomentoWidget.swift` and `ios/MomentoWidgetExtension/MomentoWidget.swift`. The extension target is the one that builds, but historically both have been edited together — keep them in sync until one is removed.
- **App Group ID is `group.com.momento.momento`** (note: matches the production prefix even though dev bundle ID is `com.mbak4.momento` — this is intentional, the App Group has its own identifier and doesn't need to follow the bundle ID).

### Step 8: Cloud Functions for email code verification

**Status (2026-04-26): functions deployed and rules published, but the Trigger Email extension's Gmail SMTP auth is rejecting credentials, so emails aren't being delivered yet. See "Resuming where we left off" at the end of this section.**

The 6-digit email verification flow needs two callable Cloud Functions deployed to Firebase, plus the **Trigger Email from Firestore** extension installed in the same project. Until SMTP delivery works, sign-up creates the Auth account and the verify screen requests a code (the function generates one and queues an email doc), but Gmail bounces the SMTP delivery, so the user never receives the code.

**One-time tooling setup (Mac):**
```bash
# Install the Firebase CLI globally
npm install -g firebase-tools

# Sign in (browser opens)
firebase login

# From the app dir, link the local repo to the Firebase project
cd /Users/m.bak4/Desktop/momento/app
firebase use momento-app-64950

# Install function dependencies
cd functions && npm install && cd ..
```

**Deploy the functions:**
```bash
cd /Users/m.bak4/Desktop/momento/app
firebase deploy --only functions
```
You should see `requestEmailCode` and `verifyEmailCode` listed under "us-central1" when it finishes. If the project hasn't enabled the Blaze (pay-as-you-go) plan, the deploy fails with a billing prompt — Cloud Functions require Blaze, but the free tier is generous (2M invocations/mo) and verification calls are tiny.

**Install the Trigger Email extension:**
1. Firebase Console → Extensions → Browse → install **Trigger Email from Firestore** (`firestore-send-email`).
2. During config: collection path `mail`, SMTP — easiest is a **Gmail App Password** (Google Account → Security → 2-step verification → App passwords) or a free **SendGrid** / **Mailgun** account. Use `smtps://USERNAME:PASSWORD@smtp.gmail.com:465` for Gmail.
3. Set `from` to something like `Momento <noreply@gmail-account-you-used>`.
4. Wait ~2 minutes for the install to finish, then sign up in the app — a code email should arrive within seconds.

**Re-publish Firestore rules** (the rules now lock down `email_verifications/*` and `mail/*` so only the Admin SDK / extension can touch them):
- Firebase Console → Firestore Database → Rules → paste contents of `firestore.rules` → Publish.

**Test from the simulator:** sign up with a brand-new email, check inbox, paste the 6 digits — should drop you straight onto the home screen. Test the resend cooldown by tapping resend immediately (should be locked for 30s).

### Resuming where we left off (2026-04-26)

What's already done in the project:
- Functions deployed: `requestEmailCode` and `verifyEmailCode` are live in `us-central1` (verified via `firebase functions:log` showing them invoked).
- Trigger Email extension installed and accepting docs from the `mail` collection — function logs show it picks up each queued email and starts the SMTP delivery attempt.
- Firestore rules re-published with the `email_verifications/*` and `mail/*` lockdowns.
- Dart side: `VerifyEmailScreen` is wired up as a hard gate, auto-requests a code on entry, has 30s resend cooldown + iOS one-time-code autofill. AuthGate uses `userChanges()` so verification flips re-route correctly.

What's blocking real delivery:
- Gmail SMTP keeps returning `535 5.7.8 Username and Password not accepted` (visible in `firebase functions:log` under `ext-firestore-send-email-processqueue`). The App Password in the extension config is wrong (most likely was pasted with spaces from Gmail's UI).

**Next session, before testing:**
1. Confirm 2-Step Verification is enabled at https://myaccount.google.com/security.
2. https://myaccount.google.com/apppasswords — delete the old "Momento Firebase" entry, create a fresh one. Gmail shows it grouped as `xxxx xxxx xxxx xxxx`; **strip all spaces** so it's a single 16-char string.
3. Firebase Console → Extensions → **Trigger Email from Firestore** → ⋮ → **Reconfigure extension** → SMTP password → "Create new secret" with the spaceless string → Save. Wait ~1 minute for the redeploy.
4. In the simulator, sign up or sign in with a real reachable email (Gmail aliases like `you+test1@gmail.com` work fine). Within ~10s an email titled "Your Momento verification code" should arrive. Enter the 6 digits → land on home screen.
5. If delivery still fails, run `firebase functions:log` and look for `ext-firestore-send-email-processqueue` errors — different SMTP error codes hint at different fixes (`Less secure access disabled` ≠ `Bad credentials` ≠ `Daily sending quota exceeded`).

## Key Details

- **App Group ID**: `group.com.momento.momento` — must match exactly on both targets and in `widget_service.dart`
- **Development Bundle ID (Personal Team)**: `com.mbak4.momento` / `com.mbak4.momento.MomentoWidgetExtension`
- **Production Bundle ID**: `com.momento.momento` (registered to a different Apple Developer account — needs that team's credentials)
- **Firebase project**: `momento-app-64950`
- **iOS deployment target**: 15.0 (required by Firebase/cloud_firestore)
- **Widget deployment target**: 17.0
- **Widget families**: .systemSmall, .systemMedium
- **Photo rotation**: 3-second intervals via WidgetKit timeline entries (60 entries = 3 min cycle)
- **Data sharing**: UserDefaults via App Group — keys: `momento_image_paths`, `momento_senders`, `momento_count`

## Files That Matter

```
ios/Runner.xcworkspace          — open this in Xcode (NOT .xcodeproj)
ios/Podfile                     — iOS deployment target set to 15.0
ios/MomentoWidget/MomentoWidget.swift  — widget code (already written)
ios/MomentoWidget/Info.plist    — widget extension plist (already written)
lib/services/widget_service.dart — Flutter side that pushes data to widget
```

## Do NOT

- Do not modify MomentoWidget.swift unless the user reports a bug
- Do not change Firebase configuration
- Do not recreate the widget extension target — it already exists
- Do not change the App Group ID — it must match exactly on both targets and in widget_service.dart
- Do not change the iOS deployment target below 15.0 — cloud_firestore requires it
- Do not build with the MomentoWidgetExtensionExtension scheme — always use Runner scheme
