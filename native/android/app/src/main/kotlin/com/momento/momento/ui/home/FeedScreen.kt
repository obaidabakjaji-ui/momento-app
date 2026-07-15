package com.momento.momento.ui.home

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.pager.VerticalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.outlined.MeetingRoom
import androidx.compose.material.icons.outlined.PhotoCamera
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.material3.pulltorefresh.PullToRefreshDefaults
import androidx.compose.material3.pulltorefresh.rememberPullToRefreshState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.momento.momento.R
import com.momento.momento.ui.components.ErrorView
import com.momento.momento.ui.components.OfflineBanner
import com.momento.momento.ui.components.ShimmerList
import com.momento.momento.ui.theme.Coral
import com.momento.momento.ui.theme.DeepPlum
import com.momento.momento.ui.theme.SoftPink

/**
 * The merged feed tab — port of the Dart `_FeedTab`
 * (lib/screens/home/home_screen.dart): transparent centered app bar with the
 * coral camera as the LEADING action (deliberately not a FAB so it can never
 * cover the countdown chip), OfflineBanner pinned above the content, coral
 * pull-to-refresh, and a vertical pager of post cards.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FeedScreen(
    uid: String,
    viewModel: FeedViewModel = viewModel(key = "feed_$uid") { FeedViewModel(uid) },
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val isRefreshing by viewModel.isRefreshing.collectAsStateWithLifecycle()
    val snackbarHostState = remember { SnackbarHostState() }
    val context = LocalContext.current

    // One-shot snackbars for the long-press moderation actions — same copy
    // (and keys) as the Dart post_actions_sheet handlers.
    LaunchedEffect(viewModel) {
        viewModel.events.collect { event ->
            val message = when (event) {
                FeedEvent.ReportSubmitted ->
                    context.getString(R.string.post_actions_report_submitted)
                is FeedEvent.UserBlocked ->
                    context.getString(R.string.post_actions_user_blocked, event.senderName)
                FeedEvent.PostDeleted ->
                    context.getString(R.string.post_actions_deleted)
                is FeedEvent.ActionFailed ->
                    context.getString(R.string.common_failed_with_error, event.message)
            }
            snackbarHostState.showSnackbar(message)
        }
    }

    // Phase 7: app-resume widget refresh — a LifecycleResumeEffect calling
    // WidgetUpdater.refreshForUser(uid) (non-forced, B8) belongs here.

    // Hoisted above the state `when` so the page position survives the brief
    // Loading flash that pull-to-refresh causes (the Dart _FeedTab kept its
    // PageController as a State field for the same reason).
    val pagerState = rememberPagerState(
        pageCount = { (uiState as? FeedUiState.Feed)?.posts?.size ?: 0 },
    )

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            CenterAlignedTopAppBar(
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
                    containerColor = Color.Transparent,
                ),
                navigationIcon = {
                    // Top-left camera — replaces the Flutter-era FAB so the
                    // "Xh Ym remaining" chip on each card stays unobscured.
                    // Phase 4: opens CameraScreen; a no-op until then.
                    IconButton(onClick = { /* Phase 4: CameraScreen */ }) {
                        Icon(
                            imageVector = Icons.Filled.CameraAlt,
                            contentDescription = stringResource(R.string.home_new_momento),
                            tint = Coral,
                        )
                    }
                },
                title = {
                    Text(
                        text = stringResource(R.string.app_name),
                        fontWeight = FontWeight.Bold,
                    )
                },
            )
        },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
        ) {
            OfflineBanner()

            val pullState = rememberPullToRefreshState()
            PullToRefreshBox(
                isRefreshing = isRefreshing,
                onRefresh = viewModel::refresh,
                state = pullState,
                modifier = Modifier.fillMaxSize(),
                indicator = {
                    PullToRefreshDefaults.Indicator(
                        state = pullState,
                        isRefreshing = isRefreshing,
                        modifier = Modifier.align(Alignment.TopCenter),
                        color = Coral,
                    )
                },
            ) {
                when (val state = uiState) {
                    FeedUiState.Loading -> ShimmerList(Modifier.fillMaxSize())

                    is FeedUiState.Error -> ErrorView(
                        message = stringResource(state.messageRes),
                        onRetry = viewModel::refresh,
                        modifier = Modifier.fillMaxSize(),
                    )

                    FeedUiState.NoRooms -> NoRoomsState()

                    FeedUiState.Empty -> EmptyFeedState()

                    is FeedUiState.Feed -> VerticalPager(
                        state = pagerState,
                        modifier = Modifier.fillMaxSize(),
                        key = { page -> state.posts[page].post.id },
                    ) { page ->
                        val item = state.posts[page]
                        PostCard(
                            post = item.post,
                            roomName = item.roomName,
                            isFavoriteRoom = item.isFavoriteRoom,
                            currentUid = uid,
                            onReport = { reason -> viewModel.reportPost(item.post, reason) },
                            onBlock = { viewModel.blockSender(item.post) },
                            onDelete = { viewModel.deletePost(item.post) },
                        )
                    }
                }
            }
        }
    }
}

/** "No communities yet" — softPink r30 tile with the meeting-room icon. */
@Composable
private fun NoRoomsState(modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(horizontal = 32.dp, vertical = 48.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Box(
            modifier = Modifier
                .size(100.dp)
                .background(SoftPink.copy(alpha = 0.3f), RoundedCornerShape(30.dp)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector = Icons.Outlined.MeetingRoom,
                contentDescription = null,
                modifier = Modifier.size(50.dp),
                tint = Coral.copy(alpha = 0.7f),
            )
        }
        Spacer(Modifier.height(24.dp))
        Text(
            text = stringResource(R.string.home_no_rooms_title),
            textAlign = TextAlign.Center,
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold,
            color = DeepPlum,
        )
        Spacer(Modifier.height(8.dp))
        Text(
            text = stringResource(R.string.home_no_rooms_home_body),
            textAlign = TextAlign.Center,
            color = DeepPlum.copy(alpha = 0.6f),
        )
    }
}

/** "No huddles yet" — 80dp camera-outline in plum-20%. */
@Composable
private fun EmptyFeedState(modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .padding(horizontal = 32.dp, vertical = 48.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Icon(
            imageVector = Icons.Outlined.PhotoCamera,
            contentDescription = null,
            modifier = Modifier.size(80.dp),
            tint = DeepPlum.copy(alpha = 0.2f),
        )
        Spacer(Modifier.height(24.dp))
        Text(
            text = stringResource(R.string.home_no_momentos_title),
            textAlign = TextAlign.Center,
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold,
            color = DeepPlum,
        )
        Spacer(Modifier.height(8.dp))
        Text(
            text = stringResource(R.string.home_no_momentos_body),
            textAlign = TextAlign.Center,
            color = DeepPlum.copy(alpha = 0.6f),
        )
    }
}
