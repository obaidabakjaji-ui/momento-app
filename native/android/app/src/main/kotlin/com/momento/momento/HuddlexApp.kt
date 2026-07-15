package com.momento.momento

import android.app.Application
import android.content.Context
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.ProcessLifecycleOwner
import com.google.firebase.FirebaseApp
import com.google.firebase.appcheck.FirebaseAppCheck
import com.google.firebase.appcheck.debug.DebugAppCheckProviderFactory
import com.google.firebase.appcheck.playintegrity.PlayIntegrityAppCheckProviderFactory
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.crashlytics.FirebaseCrashlytics
import com.momento.momento.widget.WidgetRefreshWorker
import com.momento.momento.widget.WidgetUpdater
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class HuddlexApp : Application() {

    // App-lifetime fire-and-forget work (widget refreshes). Never cancelled —
    // refreshForUser logs and swallows its own failures (B8), so nothing
    // launched here can crash the app.
    private val appScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    override fun onCreate() {
        super.onCreate()
        appContext = applicationContext
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

        // Phase 7: 15-min periodic widget refresh, unique name + REPLACE
        // policy — mirror of the Flutter Workmanager registration in
        // main.dart (B13).
        WidgetRefreshWorker.schedule(this)

        // Phase 7: app-resume widget refresh — covers "I came back to the
        // app and the widget was still showing yesterday's photos".
        // Non-forced: the 5s throttle absorbs rapid fg/bg flapping (B8).
        ProcessLifecycleOwner.get().lifecycle.addObserver(
            LifecycleEventObserver { _, event ->
                if (event != Lifecycle.Event.ON_RESUME) return@LifecycleEventObserver
                val uid = FirebaseAuth.getInstance().currentUser?.uid
                    ?: return@LifecycleEventObserver
                appScope.launch {
                    WidgetUpdater.refreshForUser(this@HuddlexApp, uid)
                }
            }
        )
    }

    companion object {
        /**
         * Process-wide application context. No Hilt in this project (house
         * rule: plain object singletons), so components without a Context of
         * their own — e.g. FeedViewModel's widget push hook — reach the app
         * context through here. Set before any Activity/ViewModel exists.
         */
        @Volatile
        lateinit var appContext: Context
            private set
    }
}
