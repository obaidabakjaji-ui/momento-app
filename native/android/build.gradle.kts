// Root build file for the NATIVE Huddlex Android app (Flutter migration).
// Versions deliberately match the toolchain already proven on this machine
// by the Flutter build: AGP 8.9.1, Kotlin 2.1.20, google-services 4.4.2,
// crashlytics 3.0.5.
plugins {
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.20" apply false
    id("org.jetbrains.kotlin.plugin.compose") version "2.1.20" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
    id("com.google.firebase.crashlytics") version "3.0.5" apply false
}
