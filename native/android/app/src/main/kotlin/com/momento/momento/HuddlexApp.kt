package com.momento.momento

import android.app.Application
import com.google.firebase.FirebaseApp
import com.google.firebase.appcheck.FirebaseAppCheck
import com.google.firebase.appcheck.debug.DebugAppCheckProviderFactory
import com.google.firebase.appcheck.playintegrity.PlayIntegrityAppCheckProviderFactory
import com.google.firebase.crashlytics.FirebaseCrashlytics

class HuddlexApp : Application() {
    override fun onCreate() {
        super.onCreate()
        FirebaseApp.initializeApp(this)

        // Mirror of the Flutter setup: debug provider in debug builds
        // (token must be registered in Firebase Console → App Check),
        // Play Integrity in release.
        FirebaseAppCheck.getInstance().installAppCheckProviderFactory(
            if (BuildConfig.DEBUG) DebugAppCheckProviderFactory.getInstance()
            else PlayIntegrityAppCheckProviderFactory.getInstance()
        )

        // Crash reporting only for release, same policy as the Flutter app.
        FirebaseCrashlytics.getInstance()
            .isCrashlyticsCollectionEnabled = !BuildConfig.DEBUG
    }
}
