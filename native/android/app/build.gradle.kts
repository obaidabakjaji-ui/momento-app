plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

android {
    namespace = "com.momento.momento"
    compileSdk = 35

    defaultConfig {
        // Same applicationId as the Flutter app so the Firebase registration,
        // SHA fingerprints, and Google sign-in carry over unchanged. Installing
        // this build REPLACES the Flutter app on a device (and vice versa) —
        // acceptable during migration; at cutover this becomes the only app.
        applicationId = "com.momento.momento"
        minSdk = 24
        targetSdk = 35
        // Native line starts at versionCode 100 so it always upgrades over
        // the Flutter builds (which are stuck at 1).
        versionCode = 100
        versionName = "2.0.0-native"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    buildTypes {
        release {
            // Release signing gets wired at cutover (android/key.properties
            // pattern, same keystore as the Flutter app). Debug-signed until
            // then so `assembleRelease` doesn't fail on a missing config.
            isMinifyEnabled = false
        }
    }
}

dependencies {
    // Compose
    val composeBom = platform("androidx.compose:compose-bom:2024.12.01")
    implementation(composeBom)
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    debugImplementation("androidx.compose.ui:ui-tooling")
    implementation("androidx.activity:activity-compose:1.9.3")
    implementation("androidx.navigation:navigation-compose:2.8.5")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.8.7")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.7")
    implementation("androidx.core:core-ktx:1.15.0")
    // Full Material icon set (camera logo, visibility toggles, etc.). Debug
    // builds carry the whole artifact; R8 strips unused icons at release.
    implementation("androidx.compose.material:material-icons-extended")
    // Custom Tabs for Terms/Privacy links (url_launcher replacement).
    implementation("androidx.browser:browser:1.8.0")

    // Firebase — BoM keeps individual SDK versions coherent.
    val firebaseBom = platform("com.google.firebase:firebase-bom:33.7.0")
    implementation(firebaseBom)
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-storage")
    implementation("com.google.firebase:firebase-functions")
    implementation("com.google.firebase:firebase-crashlytics")
    implementation("com.google.firebase:firebase-appcheck-playintegrity")
    implementation("com.google.firebase:firebase-appcheck-debug")

    // Google sign-in via Credential Manager (the modern replacement for
    // the deprecated GoogleSignIn API the Flutter plugin wrapped).
    implementation("androidx.credentials:credentials:1.3.0")
    implementation("androidx.credentials:credentials-play-services-auth:1.3.0")
    implementation("com.google.android.libraries.identity.googleid:googleid:1.1.1")

    // Images
    implementation("io.coil-kt:coil-compose:2.7.0")

    // Camera capture (Phase 4) — CameraX replaces the Flutter camera plugin.
    implementation("androidx.camera:camera-camera2:1.4.1")
    implementation("androidx.camera:camera-lifecycle:1.4.1")
    implementation("androidx.camera:camera-view:1.4.1")
    // EXIF-honoring rotation before the square crop (B13 crop contract).
    implementation("androidx.exifinterface:exifinterface:1.3.7")

    // Widget image downloads (Phase 7).
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    // App-resume hook for the non-forced widget refresh (B8).
    implementation("androidx.lifecycle:lifecycle-process:2.8.7")

    // Coroutines interop for Play Services Tasks (await()).
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.9.0")

    // Background widget refresh (Phase 7) — native WorkManager, no Flutter
    // engine spin-up.
    implementation("androidx.work:work-runtime-ktx:2.10.0")

    // Location lock (geolocator replacement) — foreground-only fixes.
    implementation("com.google.android.gms:play-services-location:21.3.0")

    // JVM unit tests (contract truth tables: geofence/approval, streak dayKey).
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.9.0")
}
