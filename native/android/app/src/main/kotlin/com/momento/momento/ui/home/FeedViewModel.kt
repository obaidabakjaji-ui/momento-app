package com.momento.momento.ui.home

import android.util.Log
import androidx.annotation.StringRes
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.momento.momento.HuddlexApp
import com.momento.momento.R
import com.momento.momento.data.ModerationRepository
import com.momento.momento.data.RoomRepository
import com.momento.momento.data.UserRepository
import com.momento.momento.data.model.AppUser
import com.momento.momento.data.model.Room
import com.momento.momento.data.model.RoomPost
import com.momento.momento.widget.WidgetPost
import com.momento.momento.widget.WidgetUpdater
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.emitAll
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/** One post ready for rendering: the raw post plus room-derived header data. */
data class FeedPost(
    val post: RoomPost,
    val roomName: String,
    val isFavoriteRoom: Boolean,
)

sealed interface FeedUiState {
    data object Loading : FeedUiState
    data object NoRooms : FeedUiState
    data object Empty : FeedUiState
    data class Error(@StringRes val messageRes: Int) : FeedUiState
    data class Feed(val posts: List<FeedPost>) : FeedUiState
}

/** One-shot snackbar events for the moderation actions. Copy is resolved by
 *  the screen from the same string keys the Dart post_actions_sheet used. */
sealed interface FeedEvent {
    data object ReportSubmitted : FeedEvent
    data class UserBlocked(val senderName: String) : FeedEvent
    data object PostDeleted : FeedEvent
    data class ActionFailed(val message: String) : FeedEvent
}

/**
 * Merged feed of posts from the user's source rooms — port of the Dart
 * `_FeedTabState` stream plumbing (lib/screens/home/home_screen.dart):
 *
 *   watchUser(uid)
 *     → source rooms = activeRoomIds if non-empty ELSE all roomIds (B12)
 *     → one-shot getRooms (names + favorite lookup for the card header)
 *     → combine() of per-room watchRoomPosts flows (each already filters
 *       expired + pending client-side — B4; do NOT re-filter here)
 *     → drop posts from senders in the viewer's blockedUserIds (B10)
 *     → favorite rooms first (0/1 bucket), createdAt desc within (B12)
 *
 * The user doc stays reactive end-to-end: favorite/blocked changes re-run the
 * final combine without resubscribing post listeners; only a change to the
 * SOURCE ROOM SET (or a pull-to-refresh) tears down and recreates the room
 * fetch + post subscriptions (flatMapLatest).
 */
@OptIn(ExperimentalCoroutinesApi::class)
class FeedViewModel(private val uid: String) : ViewModel() {

    private companion object {
        const val TAG = "FeedViewModel"
    }

    /** Intermediate result of the rooms-and-posts stage of the pipeline. */
    private sealed interface PostsStage {
        /** No source rooms — the final state is decided by the user doc alone. */
        data object Idle : PostsStage
        data object Loading : PostsStage
        data object RoomsError : PostsStage
        /** A per-room post listener errored (watchRoomPosts closed with the
         *  error) — Dart routes this to ErrorView("Couldn't load posts"). */
        data object PostsError : PostsStage
        data class Data(
            val roomsById: Map<String, Room>,
            val posts: List<RoomPost>,
        ) : PostsStage
    }

    /** Bumped by pull-to-refresh to force a resubscription even when the
     *  source room set is unchanged (Dart fake-refresh = setState rebuild). */
    private val refreshTick = MutableStateFlow(0)

    private val _isRefreshing = MutableStateFlow(false)
    val isRefreshing: StateFlow<Boolean> = _isRefreshing.asStateFlow()

    private val _events = MutableSharedFlow<FeedEvent>()
    val events: SharedFlow<FeedEvent> = _events.asSharedFlow()

    // Live user doc. watchUser folds listener errors to null (see
    // UserRepository), which the UI renders as Loading — same as the Dart
    // StreamBuilder's no-data branch.
    private val userFlow: StateFlow<AppUser?> = UserRepository.watchUser(uid)
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), null)

    /** flatMapLatest key: refresh generation + the resolved source room ids. */
    private data class SourceKey(val tick: Int, val roomIds: List<String>)

    private val postsStage: Flow<PostsStage> =
        combine(refreshTick, userFlow) { tick, user ->
            // B12: source rooms = activeRoomIds if non-empty, else ALL rooms.
            val sourceRoomIds = user?.let {
                if (it.activeRoomIds.isNotEmpty()) it.activeRoomIds else it.roomIds
            } ?: emptyList()
            SourceKey(tick, sourceRoomIds)
        }
            // Favorite/blocked-only user changes keep the same key — post
            // listeners survive; only a room-set change (or refresh) recombines.
            .distinctUntilChanged()
            .flatMapLatest { key ->
                if (key.roomIds.isEmpty()) return@flatMapLatest flowOf<PostsStage>(PostsStage.Idle)
                flow {
                    emit(PostsStage.Loading)
                    // One-shot room fetch (names, favorite lookup) — mirrors the
                    // Dart FutureBuilder over RoomService.getRooms.
                    val rooms = try {
                        RoomRepository.getRooms(key.roomIds)
                    } catch (e: CancellationException) {
                        throw e
                    } catch (e: Exception) {
                        Log.w(TAG, "getRooms failed for feed", e)
                        emit(PostsStage.RoomsError)
                        return@flow
                    }
                    if (rooms.isEmpty()) {
                        // All ids failed to resolve — Dart shows the empty feed.
                        // (combine() of zero flows would never emit.)
                        emit(PostsStage.Data(emptyMap(), emptyList()))
                        return@flow
                    }
                    val roomsById = rooms.associateBy { it.id }
                    val postFlows = rooms.map { RoomRepository.watchRoomPosts(it.id) }
                    // Like Dart's _combineLatest: waits until every room stream
                    // has emitted once, then re-emits on any change. Expired +
                    // pending posts are already filtered inside watchRoomPosts
                    // (B4) — no re-filtering here. A listener error closes the
                    // room's flow (watchRoomPosts), which cancels the combine —
                    // route it to the posts-error state like Dart's onError →
                    // StreamBuilder ErrorView (home_screen.dart).
                    emitAll(
                        combine(postFlows) { perRoom: Array<List<RoomPost>> ->
                            PostsStage.Data(roomsById, perRoom.flatMap { it }) as PostsStage
                        }.catch { e ->
                            Log.w(TAG, "room posts stream failed for feed", e)
                            emit(PostsStage.PostsError)
                        }
                    )
                }
            }

    val uiState: StateFlow<FeedUiState> =
        combine(userFlow, postsStage) { user, stage ->
            when {
                user == null -> FeedUiState.Loading
                user.roomIds.isEmpty() -> FeedUiState.NoRooms
                stage is PostsStage.Idle || stage is PostsStage.Loading -> FeedUiState.Loading
                stage is PostsStage.RoomsError ->
                    FeedUiState.Error(R.string.home_could_not_load_rooms)
                stage is PostsStage.PostsError ->
                    FeedUiState.Error(R.string.home_could_not_load_posts)
                else -> {
                    stage as PostsStage.Data
                    val blocked = user.blockedUserIds.toSet()
                    val favorites = user.favoriteRoomIds.toSet()
                    val visible = stage.posts
                        // B10: blocked-sender filtering is CLIENT-SIDE and
                        // one-directional (the viewer's blockedUserIds). The
                        // liked-by sheet is deliberately NOT filtered.
                        .filter { it.senderId !in blocked }
                        // B12: favorite-room posts first, createdAt desc within.
                        .sortedWith(
                            compareBy<RoomPost> { if (it.roomId in favorites) 0 else 1 }
                                .thenByDescending { it.createdAtMs }
                        )
                    if (visible.isEmpty()) {
                        FeedUiState.Empty
                    } else {
                        FeedUiState.Feed(
                            visible.map { post ->
                                FeedPost(
                                    post = post,
                                    roomName = stage.roomsById[post.roomId]?.name ?: "",
                                    isFavoriteRoom = post.roomId in favorites,
                                )
                            }
                        )
                    }
                }
            }
        }
            // Phase 7: widget push hook — as a collect side effect of every
            // merged-feed emission (including empty ones, which flow through so
            // the widget clears exactly once — B6/B12), push posts.take(20) to
            // the WidgetUpdater here. Do NOT implement before Phase 7.
            .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), FeedUiState.Loading)

    /**
     * Pull-to-refresh. Matches the Dart fake-refresh semantics (400ms grace,
     * then rebuild): the tick bump tears down and recreates the room fetch +
     * post subscriptions via flatMapLatest.
     */
    fun refresh() {
        if (_isRefreshing.value) return
        viewModelScope.launch {
            _isRefreshing.value = true
            delay(400)
            refreshTick.update { it + 1 }
            _isRefreshing.value = false
        }
    }

    // ===== Moderation actions (long-press sheet) =====

    fun reportPost(post: RoomPost, reason: String) {
        viewModelScope.launch {
            try {
                ModerationRepository.reportPost(
                    reporterId = uid,
                    reportedUserId = post.senderId,
                    roomId = post.roomId,
                    postId = post.id,
                    reason = reason,
                )
                _events.emit(FeedEvent.ReportSubmitted)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                _events.emit(FeedEvent.ActionFailed(e.message ?: e.toString()))
            }
        }
    }

    fun blockSender(post: RoomPost) {
        viewModelScope.launch {
            try {
                // Writes to the VIEWER's blockedUserIds (one-directional, B10);
                // the reactive user doc makes their posts vanish on the next
                // uiState combine — no resubscription needed.
                ModerationRepository.blockUser(currentUserId = uid, targetUserId = post.senderId)
                _events.emit(FeedEvent.UserBlocked(post.senderName))
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                _events.emit(FeedEvent.ActionFailed(e.message ?: e.toString()))
            }
        }
    }

    fun deletePost(post: RoomPost) {
        viewModelScope.launch {
            try {
                RoomRepository.deletePost(roomId = post.roomId, postId = post.id)
                _events.emit(FeedEvent.PostDeleted)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                _events.emit(FeedEvent.ActionFailed(e.message ?: e.toString()))
            }
        }
    }
}
