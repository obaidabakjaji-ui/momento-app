package com.momento.momento

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import java.io.File

class MomentoWidgetReceiver : HomeWidgetProvider() {

    companion object {
        const val ACTION_NEXT = "com.momento.momento.ACTION_NEXT"
        const val ACTION_PREV = "com.momento.momento.ACTION_PREV"
        const val EXTRA_WIDGET_ID = "widget_id"
        const val PREF_CURRENT_INDEX = "widget_current_index_"
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        if (intent.action == ACTION_NEXT || intent.action == ACTION_PREV) {
            val widgetId = intent.getIntExtra(EXTRA_WIDGET_ID, -1)
            if (widgetId == -1) return

            val prefs = context.getSharedPreferences("home_widget_prefs", Context.MODE_PRIVATE)
            val count = (prefs.getString("momento_count", "0") ?: "0").toIntOrNull() ?: 0
            if (count <= 1) return

            val currentIndex = prefs.getInt("$PREF_CURRENT_INDEX$widgetId", 0)
            val newIndex = if (intent.action == ACTION_NEXT) {
                (currentIndex + 1) % count
            } else {
                (currentIndex - 1 + count) % count
            }

            prefs.edit().putInt("$PREF_CURRENT_INDEX$widgetId", newIndex).apply()

            val appWidgetManager = AppWidgetManager.getInstance(context)
            onUpdate(context, appWidgetManager, intArrayOf(widgetId), prefs)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val paths = parseArray(widgetData.getString("momento_image_paths", "[]"))
        val names = parseArray(widgetData.getString("momento_senders", "[]"))
        val rooms = parseArray(widgetData.getString("momento_rooms", "[]"))
        val favs = parseArray(widgetData.getString("momento_favorites", "[]"))
        val videos = parseArray(widgetData.getString("momento_is_videos", "[]"))
        val captions = parseArray(widgetData.getString("momento_captions", "[]"))
        val likes = parseArray(widgetData.getString("momento_likes", "[]"))
        val createdAts = parseArray(widgetData.getString("momento_created_ats", "[]"))
        val count = paths.length()

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.momento_widget)

            if (count == 0) {
                showEmptyState(views)
            } else {
                val prefs = context.getSharedPreferences("home_widget_prefs", Context.MODE_PRIVATE)
                val currentIndex = prefs.getInt("$PREF_CURRENT_INDEX$widgetId", 0) % count
                val imagePath = paths.getString(currentIndex)
                val senderName = names.optStringSafe(currentIndex)
                val roomName = rooms.optStringSafe(currentIndex)
                val isFavorite = favs.optBoolean(currentIndex, false)
                val isVideo = videos.optBoolean(currentIndex, false)
                val caption = captions.optStringSafe(currentIndex)
                val likeCount = likes.optInt(currentIndex, 0)
                val createdAtMs = createdAts.optLongAt(currentIndex)

                val file = File(imagePath)
                if (!file.exists()) {
                    showEmptyState(views)
                    appWidgetManager.updateAppWidget(widgetId, views)
                    return@forEach
                }

                // Photo
                views.setImageViewBitmap(R.id.widget_image, BitmapFactory.decodeFile(imagePath))
                views.setViewVisibility(R.id.widget_image, View.VISIBLE)
                views.setViewVisibility(R.id.widget_empty, View.GONE)

                // Bottom scrim — needed once we render text on top
                views.setViewVisibility(R.id.widget_scrim, View.VISIBLE)

                // Top-left: time-ago chip ("now", "5m", "2h", "3d")
                val timeText = relativeTime(createdAtMs)
                if (timeText != null) {
                    views.setTextViewText(R.id.widget_time, timeText)
                    views.setViewVisibility(R.id.widget_time, View.VISIBLE)
                } else {
                    views.setViewVisibility(R.id.widget_time, View.GONE)
                }

                // Top-right: page counter
                if (count > 1) {
                    views.setTextViewText(R.id.widget_counter, "${currentIndex + 1}/$count")
                    views.setViewVisibility(R.id.widget_counter, View.VISIBLE)
                } else {
                    views.setViewVisibility(R.id.widget_counter, View.GONE)
                }

                // Bottom label group
                views.setViewVisibility(R.id.widget_label_group, View.VISIBLE)
                views.setTextViewText(R.id.widget_sender, senderName)
                val sub = buildString {
                    if (roomName.isNotEmpty()) append(roomName)
                    if (likeCount > 0) {
                        if (isNotEmpty()) append("  ·  ")
                        append("❤ ").append(likeCount)
                    }
                }
                if (sub.isNotEmpty()) {
                    views.setTextViewText(R.id.widget_sub, sub)
                    views.setViewVisibility(R.id.widget_sub, View.VISIBLE)
                } else {
                    views.setViewVisibility(R.id.widget_sub, View.GONE)
                }
                if (caption.isNotEmpty()) {
                    views.setTextViewText(R.id.widget_caption, caption)
                    views.setViewVisibility(R.id.widget_caption, View.VISIBLE)
                } else {
                    views.setViewVisibility(R.id.widget_caption, View.GONE)
                }

                // Coral favorite accent at the very bottom
                views.setViewVisibility(
                    R.id.widget_favorite_accent,
                    if (isFavorite) View.VISIBLE else View.GONE
                )

                // Centered play badge for video posts
                views.setViewVisibility(
                    R.id.widget_play_badge,
                    if (isVideo) View.VISIBLE else View.GONE
                )

                // Tap zones for navigating the photo rotation
                if (count > 1) {
                    val nextIntent = Intent(context, MomentoWidgetReceiver::class.java).apply {
                        action = ACTION_NEXT
                        putExtra(EXTRA_WIDGET_ID, widgetId)
                    }
                    val nextPending = PendingIntent.getBroadcast(
                        context, widgetId * 2, nextIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    views.setOnClickPendingIntent(R.id.widget_next_area, nextPending)
                    views.setViewVisibility(R.id.widget_next_area, View.VISIBLE)

                    val prevIntent = Intent(context, MomentoWidgetReceiver::class.java).apply {
                        action = ACTION_PREV
                        putExtra(EXTRA_WIDGET_ID, widgetId)
                    }
                    val prevPending = PendingIntent.getBroadcast(
                        context, widgetId * 2 + 1, prevIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    views.setOnClickPendingIntent(R.id.widget_prev_area, prevPending)
                    views.setViewVisibility(R.id.widget_prev_area, View.VISIBLE)
                } else {
                    views.setViewVisibility(R.id.widget_next_area, View.GONE)
                    views.setViewVisibility(R.id.widget_prev_area, View.GONE)
                }
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun showEmptyState(views: RemoteViews) {
        views.setViewVisibility(R.id.widget_image, View.GONE)
        views.setViewVisibility(R.id.widget_scrim, View.GONE)
        views.setViewVisibility(R.id.widget_time, View.GONE)
        views.setViewVisibility(R.id.widget_counter, View.GONE)
        views.setViewVisibility(R.id.widget_label_group, View.GONE)
        views.setViewVisibility(R.id.widget_favorite_accent, View.GONE)
        views.setViewVisibility(R.id.widget_play_badge, View.GONE)
        views.setViewVisibility(R.id.widget_next_area, View.GONE)
        views.setViewVisibility(R.id.widget_prev_area, View.GONE)
        views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
    }

    private fun parseArray(json: String?): JSONArray =
        try { JSONArray(json ?: "[]") } catch (_: Exception) { JSONArray() }

    private fun JSONArray.optStringSafe(index: Int): String =
        if (index < length()) optString(index, "") else ""

    private fun JSONArray.optLongAt(index: Int): Long =
        if (index < length()) optLong(index, 0L) else 0L

    private fun relativeTime(ms: Long): String? {
        if (ms <= 0L) return null
        val delta = (System.currentTimeMillis() - ms) / 1000
        if (delta < 0) return null
        if (delta < 60) return "now"
        if (delta < 3600) return "${delta / 60}m"
        if (delta < 86400) return "${delta / 3600}h"
        return "${delta / 86400}d"
    }
}
