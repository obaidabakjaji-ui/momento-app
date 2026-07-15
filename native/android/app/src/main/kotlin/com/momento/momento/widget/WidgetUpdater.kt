package com.momento.momento.widget

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import com.momento.momento.data.RoomRepository
import com.momento.momento.data.UserRepository
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import org.json.JSONArray
import java.io.File

/**
 * Lightweight DTO passed to [WidgetUpdater.updateWidgetWithPosts].
 *
 * [postId] / [roomId] are pushed to the widget alongside the displayable
 * fields so the native receiver can address the underlying Firestore doc
 * for tap actions (open the post in-app, double-tap to like).
 *
 * [createdAtMs] is unix milliseconds — used natively for expiry math and
 * to render "2h ago".
 */
data class WidgetPost(
    val imageUrl: String,
    val senderName: String,
    val roomName: String,
    val postId: String,
    val roomId: String,
    val isFavoriteRoom: Boolean = false,
    val caption: String? = null,
    val likeCount: Int = 0,
    val createdAtMs: Long,
)

/**
 * Widget push pipeline — port of lib/services/widget_service.dart
 * (WidgetService). Writes directly into the home_widget plugin's
 * SharedPreferences file (`HomeWidgetPreferences`, B11) so the byte-tested
 * [MomentoWidgetReceiver] keeps rendering across the Flutter → native
 * update-in-place, then triggers the receiver with the same explicit
 * ACTION_APPWIDGET_UPDATE broadcast home_widget's `updateWidget` sent.
 */
object WidgetUpdater {

    private const val TAG = "WidgetUpdater"

    // Refresh serialisation state. In-process only — that's fine for the
    // throttle, which only needs to stop same-process stampedes. Content
    // dedup does NOT live here: the push signature is persisted in the
    // widget prefs (see [SIGNATURE_KEY]) precisely because the WorkManager
    // job can run in a fresh process, where any in-memory cache would
    // always be empty. An in-memory signature caused two real bugs: the
    // background job re-downloaded every widget image on every run, and —
    // worse — when all posts had expired it skipped clearing the widget,
    // leaving expired photos up indefinitely. (B6/B8)
    private val refreshMutex = Mutex()

    @Volatile
    private var lastRefreshAtMs = 0L
    private const val REFRESH_THROTTLE_MS = 5_000L

    /** Persisted fingerprint of the last successfully pushed post set. */
    private const val SIGNATURE_KEY = "momento_signature"

    // Fire-and-forget home for the feed's push side effect (FeedViewModel).
    // Outlives any ViewModel so a mid-push teardown can't leave the prefs
    // half-written.
    private val updaterScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    private val httpClient: OkHttpClient by lazy { OkHttpClient() }

    private fun widgetPrefs(context: Context): SharedPreferences =
        context.getSharedPreferences(
            MomentoWidgetReceiver.WIDGET_DATA_PREFS, Context.MODE_PRIVATE,
        )

    private fun readPersistedSignature(context: Context): String =
        try {
            widgetPrefs(context).getString(SIGNATURE_KEY, "") ?: ""
        } catch (_: Exception) {
            ""
        }

    private fun persistSignature(context: Context, signature: String) {
        widgetPrefs(context).edit().putString(SIGNATURE_KEY, signature).apply()
    }

    /**
     * Pull the user's freshest visible posts straight from Firestore and
     * push them to the widget. Used at three call sites:
     *   1. After the user posts a new huddle (so the widget reflects the
     *      new photo without waiting for the feed collector to redraw).
     *   2. When the app comes to foreground (covers "I came back to the
     *      app and the widget was still showing yesterday's photos").
     *   3. The WorkManager background job (so the widget keeps cycling new
     *      content even when the app hasn't been opened in hours).
     *
     * Serialised + throttled: if one refresh is mid-flight, additional calls
     * short-circuit instead of stacking up. After a successful run, further
     * non-forced calls within [REFRESH_THROTTLE_MS] are skipped — the
     * app-resume and BG-task paths fire often and don't need sub-5s
     * freshness.
     *
     * [force] bypasses the throttle for explicit user actions (posting a
     * photo): the user just created content and expects the widget to
     * reflect it immediately, even if a passive refresh ran a second ago.
     * The in-flight guard is always respected so two refreshes never race
     * (B8).
     */
    suspend fun refreshForUser(context: Context, uid: String, force: Boolean = false) {
        if (!refreshMutex.tryLock()) return
        try {
            if (!force &&
                System.currentTimeMillis() - lastRefreshAtMs < REFRESH_THROTTLE_MS
            ) {
                return
            }
            try {
                doRefreshForUser(context.applicationContext, uid)
                lastRefreshAtMs = System.currentTimeMillis()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, "refreshForUser failed", e)
            }
        } finally {
            refreshMutex.unlock()
        }
    }

    // Port of WidgetService._doRefreshForUser (B12): user doc →
    // activeRoomIds else roomIds → getRoomPostsOnce per room →
    // blocked-sender filter (B10) → favorite-first sort → take(20) →
    // updateWidgetWithPosts. No user / no rooms → clearWidget().
    private suspend fun doRefreshForUser(context: Context, uid: String) {
        try {
            Log.d(TAG, "refresh: START uid=$uid")
            val user = UserRepository.getUser(uid)
            if (user == null) {
                Log.d(TAG, "refresh: no user doc, clearing")
                clearWidget(context)
                return
            }
            val sourceRoomIds =
                if (user.activeRoomIds.isNotEmpty()) user.activeRoomIds else user.roomIds
            Log.d(
                TAG,
                "refresh: sourceRoomIds=$sourceRoomIds " +
                    "(active=${user.activeRoomIds.size}, all=${user.roomIds.size})",
            )
            if (sourceRoomIds.isEmpty()) {
                Log.d(TAG, "refresh: no source rooms, clearing")
                clearWidget(context)
                return
            }

            val rooms = RoomRepository.getRooms(sourceRoomIds)
            val roomMap = rooms.associateBy { it.id }

            val all = mutableListOf<PostWithRoom>()
            for (roomId in sourceRoomIds) {
                val posts = RoomRepository.getRoomPostsOnce(roomId)
                Log.d(TAG, "refresh: room=$roomId fetched ${posts.size} posts")
                for (p in posts) {
                    val ageMin = (System.currentTimeMillis() - p.createdAtMs) / 60_000L
                    Log.d(TAG, "  post=${p.id} sender=${p.senderName} ageMin=$ageMin")
                    all.add(
                        PostWithRoom(
                            postId = p.id,
                            imageUrl = p.imageUrl,
                            senderName = p.senderName,
                            senderId = p.senderId,
                            roomId = roomId,
                            caption = p.caption,
                            likeCount = p.likeCount,
                            createdAtMs = p.createdAtMs,
                        )
                    )
                }
            }

            val blocked = user.blockedUserIds.toSet()
            val favorites = user.favoriteRoomIds.toSet()
            val visible = all.filter { it.senderId !in blocked }
                .sortedWith(
                    compareBy<PostWithRoom> { if (it.roomId in favorites) 0 else 1 }
                        .thenByDescending { it.createdAtMs }
                )

            val widgetPosts = visible.take(20).map { p ->
                WidgetPost(
                    imageUrl = p.imageUrl,
                    senderName = p.senderName,
                    roomName = roomMap[p.roomId]?.name ?: "",
                    isFavoriteRoom = p.roomId in favorites,
                    caption = p.caption,
                    likeCount = p.likeCount,
                    postId = p.postId,
                    roomId = p.roomId,
                    createdAtMs = p.createdAtMs,
                )
            }

            Log.d(TAG, "refresh: pushing ${widgetPosts.size} widget posts")
            updateWidgetWithPosts(context, widgetPosts)
            Log.d(TAG, "refresh: END")
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            // The widget refresh runs as fire-and-forget from several call
            // sites (camera send, foreground resume, BG job). A failure here
            // must not tank the calling flow — log so debugging is possible,
            // then bail.
            Log.w(TAG, "refreshForUser failed", e)
        }
    }

    /**
     * Fire-and-forget wrapper for the feed's collect side effect
     * (FeedViewModel): launches [updateWidgetWithPosts] on the updater's own
     * background scope so a widget failure (or ViewModel teardown) can never
     * touch the feed.
     */
    fun pushPostsAsync(context: Context, posts: List<WidgetPost>) {
        val appContext = context.applicationContext
        updaterScope.launch {
            try {
                updateWidgetWithPosts(appContext, posts)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.w(TAG, "feed widget push failed", e)
            }
        }
    }

    /**
     * One photo per [WidgetPost] to render in the widget rotation. Items
     * should be passed in display order (favorites already bubbled to
     * front).
     *
     * Signature-dedup semantics (B6) — exactly the Dart behaviour:
     * unchanged signature → skip everything; empty posts + empty signature
     * → no-op; empty + non-empty → clearWidget(); PARTIAL download failure
     * → persist '' so the next refresh retries; full success → persist the
     * signature; ALL downloads failed → clearWidget().
     */
    suspend fun updateWidgetWithPosts(context: Context, posts: List<WidgetPost>) {
        withContext(Dispatchers.IO) {
            // The persisted signature (not an in-memory field) is the dedup
            // source of truth so it survives into the fresh process each
            // WorkManager run may get. See the note on the object fields.
            val lastSignature = readPersistedSignature(context)

            if (posts.isEmpty()) {
                if (lastSignature.isEmpty()) return@withContext // already cleared
                clearWidget(context)
                return@withContext
            }

            // Cheap content fingerprint — identical posts in the same order
            // should never re-broadcast to the receiver. imageUrl is unique
            // per upload and createdAtMs per post, so the signature changes
            // the moment anything visible changes (new post, deletion,
            // re-sort).
            val signature = posts.joinToString(";") { "${it.imageUrl}|${it.createdAtMs}" }
            if (signature == lastSignature) {
                Log.d(TAG, "signature unchanged, skipping push")
                return@withContext
            }

            val dir = context.filesDir
            val paths = mutableListOf<String>()
            val senders = mutableListOf<String>()
            val rooms = mutableListOf<String>()
            val favs = mutableListOf<Boolean>()
            val captions = mutableListOf<String>()
            val likes = mutableListOf<Int>()
            val createdAts = mutableListOf<Long>()
            val postIds = mutableListOf<String>()
            val roomIds = mutableListOf<String>()

            for ((i, p) in posts.withIndex()) {
                val localPath =
                    downloadImage(p.imageUrl, File(dir, "widget_momento_$i.jpg"))
                if (localPath != null) {
                    paths.add(localPath)
                    senders.add(p.senderName)
                    rooms.add(p.roomName)
                    favs.add(p.isFavoriteRoom)
                    captions.add(p.caption ?: "")
                    likes.add(p.likeCount)
                    createdAts.add(p.createdAtMs)
                    postIds.add(p.postId)
                    roomIds.add(p.roomId)
                }
            }

            if (paths.isEmpty()) {
                // Every download failed (e.g. cold Storage token right after
                // a fresh install). clearWidget resets the persisted
                // signature so the very next refresh retries instead of
                // treating this result as "done".
                clearWidget(context)
                return@withContext
            }

            widgetPrefs(context).edit()
                .putString("momento_image_paths", JSONArray(paths).toString())
                .putString("momento_senders", JSONArray(senders).toString())
                .putString("momento_rooms", JSONArray(rooms).toString())
                .putString("momento_favorites", JSONArray(favs).toString())
                .putString("momento_captions", JSONArray(captions).toString())
                .putString("momento_likes", JSONArray(likes).toString())
                .putString("momento_created_ats", JSONArray(createdAts).toString())
                .putString("momento_post_ids", JSONArray(postIds).toString())
                .putString("momento_room_ids", JSONArray(roomIds).toString())
                .putString("momento_count", paths.size.toString())
                // Single-item fields kept for native widgets that haven't
                // been updated yet.
                .putString("momento_image_path", paths.first())
                .putString("momento_sender", senders.first())
                .putString("momento_timestamp", System.currentTimeMillis().toString())
                .apply()

            // Only persist the signature if EVERY intended post actually
            // downloaded. If some failed, paths.size < posts.size —
            // persisting the full signature would make the next identical
            // refresh dedup-skip and the missing photos would never appear
            // until the post list changed (the "doesn't show until the 3rd
            // photo" bug). Persisting '' forces the next refresh to retry
            // the failed downloads. (B6)
            val allSucceeded = paths.size == posts.size
            persistSignature(context, if (allSucceeded) signature else "")
            if (!allSucceeded) {
                Log.d(
                    TAG,
                    "${posts.size - paths.size} of ${posts.size} downloads " +
                        "failed — will retry next refresh",
                )
            }
            triggerWidgetUpdate(context)
        }
    }

    /**
     * Zero out every widget key, persist an empty signature (so the next
     * refresh with content re-pushes), and re-broadcast so the receiver
     * renders its empty state. Always safe to call — B6's empty+empty
     * short-circuit in [updateWidgetWithPosts] keeps repeat clears cheap.
     */
    suspend fun clearWidget(context: Context) {
        withContext(Dispatchers.IO) {
            persistSignature(context, "")
            widgetPrefs(context).edit()
                .putString("momento_image_paths", "[]")
                .putString("momento_senders", "[]")
                .putString("momento_rooms", "[]")
                .putString("momento_favorites", "[]")
                .putString("momento_captions", "[]")
                .putString("momento_likes", "[]")
                .putString("momento_created_ats", "[]")
                .putString("momento_post_ids", "[]")
                .putString("momento_room_ids", "[]")
                .putString("momento_count", "0")
                .putString("momento_image_path", "")
                .putString("momento_sender", "")
                .apply()
            triggerWidgetUpdate(context)
        }
    }

    /**
     * What home_widget's `updateWidget` did on Android: an explicit
     * ACTION_APPWIDGET_UPDATE broadcast targeted at the receiver component,
     * carrying the currently bound widget ids (B11). Every data push lands
     * as a real `onUpdate`, which is also what keeps the receiver's expiry
     * alarm armed (B7).
     */
    private fun triggerWidgetUpdate(context: Context) {
        val component = ComponentName(context, MomentoWidgetReceiver::class.java)
        val ids = AppWidgetManager.getInstance(context).getAppWidgetIds(component)
        val intent = Intent(context, MomentoWidgetReceiver::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        }
        context.sendBroadcast(intent)
    }

    private fun downloadImage(url: String, dest: File): String? {
        return try {
            val request = Request.Builder().url(url).build()
            httpClient.newCall(request).execute().use { response ->
                if (!response.isSuccessful) {
                    Log.w(TAG, "download HTTP ${response.code} for $url")
                    return null
                }
                val body = response.body ?: run {
                    Log.w(TAG, "download empty body for $url")
                    return null
                }
                body.byteStream().use { input ->
                    dest.outputStream().use { output -> input.copyTo(output) }
                }
                dest.absolutePath
            }
        } catch (e: Exception) {
            Log.w(TAG, "download failed for $url", e)
            null
        }
    }

    /**
     * Internal flattening helper for [refreshForUser] — we iterate per-room
     * and collect posts into one list before sorting (port of the Dart
     * `_PostWithRoom`).
     */
    private data class PostWithRoom(
        val postId: String,
        val imageUrl: String,
        val senderName: String,
        val senderId: String,
        val roomId: String,
        val caption: String?,
        val likeCount: Int,
        val createdAtMs: Long,
    )
}
