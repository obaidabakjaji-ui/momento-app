package com.momento.momento

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import java.io.File

/**
 * Huddlex home-screen widget.
 *
 * Auto-rotation is driven by ViewFlipper.autoStart in the layout — the
 * launcher cycles between populated cards in its own process, so cycling
 * survives doze, force-stop, and app-killed states.
 *
 * The whole widget surface is a single tap target that launches the app.
 * No prev/next zones, no touch-to-pause — the user views in-app for any
 * detailed interaction.
 *
 * Rebuild dedup: home_widget pushes data often (each Firestore tick can
 * trigger one). Each rebuild removes + re-adds children, which restarts
 * the flipper at child 0. We hash the photo set and skip the rebuild if
 * it hasn't changed.
 */
class MomentoWidgetReceiver : HomeWidgetProvider() {

    companion object {
        const val TAG = "HuddlexWidget"
        // Bumped from "last_data_hash" — earlier builds cached a "success"
        // hash for renders that were actually silently rejected by the
        // launcher (binder bundle too large). The dedup then refused to
        // re-render with identical content even after the bitmap fix was
        // shipped. A new key resets the cache without needing the user to
        // clear app data. _v3 bump pairs with the static-single-card
        // layout switch so the new structure picks up immediately on next
        // push even when the underlying post data hasn't changed.
        const val PREF_LAST_DATA_HASH = "last_data_hash_v5"

        // home_widget plugin's SharedPreferences (see home_widget-0.9.0/
        // .../HomeWidgetPlugin.kt constant PREFERENCES).
        const val WIDGET_DATA_PREFS = "HomeWidgetPreferences"

        // Per-widget UI state owned by us, not by the plugin.
        const val INDEX_PREFS = "home_widget_prefs"

        // Hard cap on the longest edge of each card bitmap. The Android
        // binder transaction limit for a RemoteViews bundle is ~1 MB, and
        // every additional card adds its decoded bitmap to that bundle. A
        // 1080×1080 ARGB_8888 bitmap alone is 4.5 MB — way over budget,
        // and the launcher silently rejects the whole update when it
        // exceeds the limit, leaving the widget stuck on its previous
        // (often empty) render. 400 px in RGB_565 lands at ~320 KB per
        // card.
        const val MAX_BITMAP_EDGE = 400

        // Cap on how many cards the ViewFlipper holds at once. With each
        // card around 320 KB of bitmap, five cards keep total RemoteViews
        // payload comfortably under the 1 MB transaction limit. Older
        // content cycles out as new posts arrive.
        const val MAX_CARDS = 5
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val indexPrefs = context.getSharedPreferences(INDEX_PREFS, Context.MODE_PRIVATE)
        val newHash = dataHash(widgetData)
        val lastHash = indexPrefs.getInt(PREF_LAST_DATA_HASH, Int.MIN_VALUE)
        if (newHash == lastHash) {
            Log.d(TAG, "onUpdate: data unchanged (hash=$newHash), skipping rebuild")
            return
        }
        indexPrefs.edit().putInt(PREF_LAST_DATA_HASH, newHash).apply()
        renderAllPhotos(context, appWidgetManager, appWidgetIds, widgetData)
    }

    private fun dataHash(widgetData: SharedPreferences): Int {
        val paths = widgetData.getString("momento_image_paths", "[]") ?: "[]"
        val createdAts = widgetData.getString("momento_created_ats", "[]") ?: "[]"
        // Include postIds so older builds (without post-id arrays) and
        // newer ones produce different hashes — the tap wiring depends on
        // these arrays being present, so we want a forced re-render the
        // first time they appear in prefs.
        val postIds = widgetData.getString("momento_post_ids", "[]") ?: "[]"
        var h = paths.hashCode()
        h = h * 31 + createdAts.hashCode()
        h = h * 31 + postIds.hashCode()
        return h
    }

    private fun renderAllPhotos(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val arrays = readArrays(widgetData)
        val activeIndices = computeActiveIndicesFromArrays(arrays)
        val count = activeIndices.size

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.momento_widget)

            when {
                count == 0 -> {
                    showEmptyState(views)
                }
                count == 1 -> {
                    // Static single-card path bypasses the flipper entirely
                    // so its cross-fade animation can't play on a "switch"
                    // to the same child. Cleanly avoids the single-photo
                    // glitch we hit earlier without disabling animations
                    // for the multi-photo case.
                    val rendered =
                        populateSingleCard(views, arrays, activeIndices[0])
                    if (rendered) {
                        views.setViewVisibility(R.id.widget_single_card, View.VISIBLE)
                        views.setViewVisibility(R.id.widget_flipper, View.GONE)
                        views.setViewVisibility(R.id.widget_empty, View.GONE)
                    } else {
                        showEmptyState(views)
                    }
                }
                else -> {
                    views.setViewVisibility(R.id.widget_flipper, View.VISIBLE)
                    views.setViewVisibility(R.id.widget_single_card, View.GONE)
                    views.setViewVisibility(R.id.widget_empty, View.GONE)
                    views.removeAllViews(R.id.widget_flipper)

                    var addedAny = false
                    for ((position, originalIndex) in activeIndices.take(MAX_CARDS).withIndex()) {
                        val card = buildPhotoCard(
                            context, position, count, originalIndex, arrays,
                        ) ?: continue
                        views.addView(R.id.widget_flipper, card)
                        addedAny = true
                    }

                    if (!addedAny) {
                        showEmptyState(views)
                    }
                }
            }

            // Tap anywhere on the widget opens the app.
            wireOpenAppOnTap(context, views, widgetId)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    /**
     * Render the single-photo case directly into the root RemoteViews —
     * no ViewFlipper, no animation, just the photo card. Returns false
     * if the bitmap couldn't be decoded so the caller can fall back to
     * the empty state.
     */
    private fun populateSingleCard(
        views: RemoteViews,
        arrays: Arrays,
        originalIndex: Int,
    ): Boolean {
        val imagePath = arrays.paths.getString(originalIndex)
        if (!File(imagePath).exists()) return false
        val bitmap = decodeScaledBitmap(imagePath, MAX_BITMAP_EDGE) ?: return false
        views.setImageViewBitmap(R.id.single_card_image, bitmap)

        val sender = arrays.names.optStringSafe(originalIndex)
        val room = arrays.rooms.optStringSafe(originalIndex)
        val likeCount = arrays.likes.optInt(originalIndex, 0)
        val title = buildString {
            append(sender)
            if (room.isNotEmpty()) {
                if (isNotEmpty()) append("  ·  ")
                append(room)
            }
            if (likeCount > 0) {
                if (isNotEmpty()) append("  ·  ")
                append("❤ ").append(likeCount)
            }
        }
        views.setTextViewText(R.id.single_card_title, title)

        val caption = arrays.captions.optStringSafe(originalIndex)
        if (caption.isNotEmpty()) {
            views.setTextViewText(R.id.single_card_caption, caption)
            views.setViewVisibility(R.id.single_card_caption, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.single_card_caption, View.GONE)
        }
        return true
    }

    /**
     * Tap anywhere on the widget root → launch the app. One PendingIntent
     * keyed by widgetId so multiple widgets don't share the same intent.
     */
    private fun wireOpenAppOnTap(context: Context, views: RemoteViews, widgetId: Int) {
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: return
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        val pending = PendingIntent.getActivity(
            context, widgetId, launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        views.setOnClickPendingIntent(R.id.widget_root, pending)
    }

    private fun buildPhotoCard(
        context: Context,
        position: Int,
        count: Int,
        originalIndex: Int,
        arrays: Arrays,
    ): RemoteViews? {
        val imagePath = arrays.paths.getString(originalIndex)
        val file = File(imagePath)
        if (!file.exists()) return null

        val bitmap = decodeScaledBitmap(imagePath, MAX_BITMAP_EDGE) ?: return null
        val card = RemoteViews(context.packageName, R.layout.widget_photo_card)
        card.setImageViewBitmap(R.id.card_image, bitmap)

        val sender = arrays.names.optStringSafe(originalIndex)
        val room = arrays.rooms.optStringSafe(originalIndex)
        val likeCount = arrays.likes.optInt(originalIndex, 0)
        val title = buildString {
            append(sender)
            if (room.isNotEmpty()) {
                if (isNotEmpty()) append("  ·  ")
                append(room)
            }
            if (likeCount > 0) {
                if (isNotEmpty()) append("  ·  ")
                append("❤ ").append(likeCount)
            }
        }
        card.setTextViewText(R.id.card_title, title)

        val caption = arrays.captions.optStringSafe(originalIndex)
        if (caption.isNotEmpty()) {
            card.setTextViewText(R.id.card_caption, caption)
            card.setViewVisibility(R.id.card_caption, View.VISIBLE)
        }

        @Suppress("UNUSED_VARIABLE") val total = count
        @Suppress("UNUSED_VARIABLE") val pos = position
        return card
    }

    /**
     * Two-pass decode: first read just the source dimensions, then load the
     * actual pixels with an inSampleSize large enough that the longest edge
     * lands at or under [targetEdge]. Forces RGB_565 because the photos
     * don't need transparency and 2-bytes-per-pixel halves the memory
     * footprint vs. the default ARGB_8888 — critical for staying under the
     * RemoteViews binder budget.
     */
    private fun decodeScaledBitmap(path: String, targetEdge: Int): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, bounds)
        val srcW = bounds.outWidth
        val srcH = bounds.outHeight
        if (srcW <= 0 || srcH <= 0) return null

        var sample = 1
        while (srcW / (sample * 2) >= targetEdge && srcH / (sample * 2) >= targetEdge) {
            sample *= 2
        }
        val loadOpts = BitmapFactory.Options().apply {
            inSampleSize = sample
            inPreferredConfig = Bitmap.Config.RGB_565
        }
        return BitmapFactory.decodeFile(path, loadOpts)
    }

    private fun showEmptyState(views: RemoteViews) {
        views.setViewVisibility(R.id.widget_flipper, View.GONE)
        views.setViewVisibility(R.id.widget_single_card, View.GONE)
        views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
    }

    private fun readArrays(widgetData: SharedPreferences): Arrays = Arrays(
        paths = parseArray(widgetData.getString("momento_image_paths", "[]")),
        names = parseArray(widgetData.getString("momento_senders", "[]")),
        rooms = parseArray(widgetData.getString("momento_rooms", "[]")),
        favs = parseArray(widgetData.getString("momento_favorites", "[]")),
        captions = parseArray(widgetData.getString("momento_captions", "[]")),
        likes = parseArray(widgetData.getString("momento_likes", "[]")),
        createdAts = parseArray(widgetData.getString("momento_created_ats", "[]")),
    )

    private fun computeActiveIndicesFromArrays(arrays: Arrays): List<Int> {
        val postLifetimeMs = 6L * 60L * 60L * 1000L
        val nowMs = System.currentTimeMillis()
        val active = mutableListOf<Int>()
        for (i in 0 until arrays.paths.length()) {
            val createdAtMs = arrays.createdAts.optLongAt(i)
            if (createdAtMs <= 0 || nowMs - createdAtMs < postLifetimeMs) {
                active.add(i)
            }
        }
        return active
    }

    private data class Arrays(
        val paths: JSONArray,
        val names: JSONArray,
        val rooms: JSONArray,
        val favs: JSONArray,
        val captions: JSONArray,
        val likes: JSONArray,
        val createdAts: JSONArray,
    )

    private fun parseArray(json: String?): JSONArray =
        try { JSONArray(json ?: "[]") } catch (_: Exception) { JSONArray() }

    private fun JSONArray.optStringSafe(index: Int): String =
        if (index < length()) optString(index, "") else ""

    private fun JSONArray.optLongAt(index: Int): Long =
        if (index < length()) optLong(index, 0L) else 0L
}
