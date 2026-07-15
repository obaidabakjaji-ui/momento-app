package com.momento.momento.widget

import android.content.Context
import android.util.Log
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import com.google.firebase.auth.FirebaseAuth
import java.util.concurrent.TimeUnit

/**
 * Periodic background widget refresh — port of
 * lib/services/widget_background_task.dart (the Workmanager callback).
 *
 * Keeps the widget cycling fresh content even when the app hasn't been
 * opened in hours. Signed-out (no current user) is a clean no-op success —
 * exactly like the Dart callback.
 */
class WidgetRefreshWorker(
    appContext: Context,
    params: WorkerParameters,
) : CoroutineWorker(appContext, params) {

    override suspend fun doWork(): Result {
        try {
            val user = FirebaseAuth.getInstance().currentUser ?: return Result.success()
            // Non-forced: the 15-min cadence doesn't need to punch through
            // the 5s throttle (B8). refreshForUser logs and swallows its own
            // failures; returning success regardless mirrors the Dart
            // callback's unconditional `return true`.
            WidgetUpdater.refreshForUser(applicationContext, user.uid)
        } catch (e: Exception) {
            // Background job — no UI to surface failures. Log so it shows up
            // in logcat if the user is debugging.
            Log.w(TAG, "widget refresh failed", e)
        }
        return Result.success()
    }

    companion object {
        private const val TAG = "WidgetRefreshWorker"

        /**
         * Identifier for the periodic widget-refresh work — same unique name
         * the Flutter app registered with Workmanager (B13), so REPLACE also
         * supersedes any task left behind by an update-in-place install.
         */
        const val UNIQUE_WORK_NAME = "huddlex-widget-refresh"

        /**
         * Schedule (or re-schedule) the periodic refresh: 15 min (the
         * WorkManager minimum), network required, REPLACE policy — a
         * policy/period change only takes effect if the existing task is
         * replaced. Called from HuddlexApp.onCreate.
         */
        fun schedule(context: Context) {
            val request = PeriodicWorkRequestBuilder<WidgetRefreshWorker>(15, TimeUnit.MINUTES)
                .setConstraints(
                    Constraints.Builder()
                        .setRequiredNetworkType(NetworkType.CONNECTED)
                        .build()
                )
                .build()
            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                UNIQUE_WORK_NAME,
                ExistingPeriodicWorkPolicy.REPLACE,
                request,
            )
        }
    }
}
