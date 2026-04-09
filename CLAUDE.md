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

# Build iOS (debug)
flutter build ios --debug

# Clean and rebuild
flutter clean && flutter pub get && cd ios && pod install && cd ..

# iOS pod install (after adding dependencies)
cd ios && pod install && cd ..
```

Flutter is installed at `~/flutter/bin` — if `flutter` command is not found:
```bash
export PATH="$PATH:$HOME/flutter/bin"
```

## Architecture

The app is a Flutter social photo-sharing app ("Momento") with Firebase backend.

**Auth flow**: `main.dart` uses `StreamBuilder` on `FirebaseAuth.authStateChanges()` — unauthenticated users land on auth screens, authenticated users on the home feed.

**Service layer** (`lib/services/`):
- `auth_service.dart` — Firebase Auth + Google Sign-In
- `firestore_service.dart` — all Firestore reads/writes (users, moments, link requests)
- `storage_service.dart` — Firebase Storage for photo uploads
- `widget_service.dart` — pushes data to iOS/Android home screen widget via `home_widget` package using App Group `group.com.momento.momento`

**Models** (`lib/models/`): `app_user.dart`, `momento.dart`, `link_request.dart` — plain Dart classes with `fromJson`/`toJson`.

**Screens** (`lib/screens/`): organized by feature — `auth/`, `home/`, `camera/`, `link/`, `account/`.

**Widget bridge**: `widget_service.dart` writes to shared UserDefaults (App Group) using keys `momento_image_paths`, `momento_senders`, `momento_count`. The native iOS widget (`ios/MomentoWidget/MomentoWidget.swift`) reads these keys and renders photos with WidgetKit.

## iOS Widget Setup

The iOS widget extension setup is fully documented in `CLAUDE_IOS_SETUP.md`. Summary of current state:
- All Xcode configuration is done (target created, App Groups set, signing configured)
- Development bundle IDs use Personal Team: `com.mbak4.momento` / `com.mbak4.momento.MomentoWidgetExtension`
- Build is working — app installs on physical device. Current issue: app crashes on launch (see CLAUDE_IOS_SETUP.md Step 4)
- Always open `ios/Runner.xcworkspace` in Xcode (never `Runner.xcodeproj`)
- Always build with the **Runner** scheme (not MomentoWidgetExtensionExtension)
- **Do not re-add** `${TARGET_BUILD_DIR}/${INFOPLIST_PATH}` to Thin Binary inputPaths — it was intentionally removed to fix a build cycle

## Firebase

- Project: `momento-app-64950`
- Config: `lib/firebase_options.dart` (auto-generated, do not edit manually)
- Firestore rules: `firestore.rules`
- Storage rules: `storage.rules`
- iOS deployment target must stay at 15.0+ (cloud_firestore requirement)
