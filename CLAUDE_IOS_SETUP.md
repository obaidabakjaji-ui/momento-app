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

### Step 4: Fix app crash on launch (NEXT STEP — IN PROGRESS)

The app is installed on the iPhone ("Mbak", iOS 26.3.1) but crashes immediately on open.

**What's been done:**
- App installed on physical device
- Developer profile trusted (Settings → General → VPN & Device Management)
- Crash reason not yet captured — wireless connection dropped before we could get logs

**Next step:** Connect iPhone via USB cable and run:
```bash
cd ~/Desktop/momento/app && flutter run
```
This will print the crash stack trace so we can diagnose the cause.

**Likely causes to investigate:**
- Firebase iosBundleId mismatch: `firebase_options.dart` has `iosBundleId: 'com.momento.momento'` but app runs as `com.mbak4.momento`
- App Groups entitlement issue (Personal Team provisioning)
- Missing GoogleService-Info.plist (no iOS plist found in project — but firebase_options.dart is used instead, so may not be the issue)

### Step 5: Test the widget

After the crash is fixed:
1. Long-press the home screen → tap "+" (top left)
2. Search "Momento" in the widget gallery
3. Add the small or medium widget
4. Send a photo from another account to verify it appears without opening the app

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
