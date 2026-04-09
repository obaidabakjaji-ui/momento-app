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
        val pathsJson = widgetData.getString("momento_image_paths", "[]") ?: "[]"
        val namesJson = widgetData.getString("momento_senders", "[]") ?: "[]"

        val paths = try { JSONArray(pathsJson) } catch (_: Exception) { JSONArray() }
        val names = try { JSONArray(namesJson) } catch (_: Exception) { JSONArray() }
        val count = paths.length()

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.momento_widget)

            if (count == 0) {
                showEmptyState(views)
            } else {
                val prefs = context.getSharedPreferences("home_widget_prefs", Context.MODE_PRIVATE)
                val currentIndex = prefs.getInt("$PREF_CURRENT_INDEX$widgetId", 0) % count
                val imagePath = paths.getString(currentIndex)
                val senderName = if (currentIndex < names.length()) names.getString(currentIndex) else ""

                val file = File(imagePath)
                if (file.exists()) {
                    val bitmap = BitmapFactory.decodeFile(imagePath)
                    views.setImageViewBitmap(R.id.widget_image, bitmap)
                    views.setViewVisibility(R.id.widget_image, View.VISIBLE)
                    views.setViewVisibility(R.id.widget_empty, View.GONE)
                    views.setTextViewText(R.id.widget_sender, senderName)
                    views.setViewVisibility(R.id.widget_sender, View.VISIBLE)

                    // Show page indicator if multiple photos
                    if (count > 1) {
                        views.setTextViewText(R.id.widget_counter, "${currentIndex + 1}/$count")
                        views.setViewVisibility(R.id.widget_counter, View.VISIBLE)
                    } else {
                        views.setViewVisibility(R.id.widget_counter, View.GONE)
                    }
                } else {
                    showEmptyState(views)
                }

                // Set up swipe/tap actions for navigation
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
        views.setViewVisibility(R.id.widget_sender, View.GONE)
        views.setViewVisibility(R.id.widget_counter, View.GONE)
        views.setViewVisibility(R.id.widget_next_area, View.GONE)
        views.setViewVisibility(R.id.widget_prev_area, View.GONE)
        views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
    }
}
