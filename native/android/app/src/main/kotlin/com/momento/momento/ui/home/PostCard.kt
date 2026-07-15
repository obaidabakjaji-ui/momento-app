package com.momento.momento.ui.home

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BrokenImage
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.outlined.Timer
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.SubcomposeAsyncImage
import coil.request.ImageRequest
import com.momento.momento.R
import com.momento.momento.data.RoomRepository
import com.momento.momento.data.model.RoomPost
import com.momento.momento.ui.components.LikeButton
import com.momento.momento.ui.components.LikedBySheet
import com.momento.momento.ui.components.PhotoViewer
import com.momento.momento.ui.components.PostActionsSheet
import com.momento.momento.ui.theme.Coral
import com.momento.momento.ui.theme.DeepPlum
import com.momento.momento.ui.theme.SoftPink
import com.momento.momento.ui.theme.WarmOrange
import kotlinx.coroutines.delay

/**
 * One page of the feed pager — port of the Dart `_PostCard`
 * (lib/screens/home/home_screen.dart): centered "Sender · Room" header with a
 * warmOrange star for favorite rooms, the photo filling the remaining height
 * (r24, crossfade, tap → viewer, long-press → actions sheet), optional
 * caption, then a centered LikeButton + countdown chip row.
 *
 * Moderation callbacks bubble up so the FeedViewModel can run the repository
 * calls and the screen can show the confirmation/failure snackbars.
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun PostCard(
    post: RoomPost,
    roomName: String,
    isFavoriteRoom: Boolean,
    currentUid: String,
    onReport: (reason: String) -> Unit,
    onBlock: () -> Unit,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier,
) {
    var showViewer by remember { mutableStateOf(false) }
    var showActions by remember { mutableStateOf(false) }
    var showLikedBy by remember { mutableStateOf(false) }

    Column(modifier = modifier.fillMaxSize().padding(16.dp)) {
        // Header: optional favorite star + "Sender · Room", centered.
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(bottom = 8.dp),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            if (isFavoriteRoom) {
                Icon(
                    imageVector = Icons.Filled.Star,
                    contentDescription = null,
                    modifier = Modifier.size(16.dp),
                    tint = WarmOrange,
                )
                Spacer(Modifier.width(4.dp))
            }
            Text(
                text = "${post.senderName} · $roomName",
                fontSize = 16.sp,
                fontWeight = FontWeight.W600,
                color = DeepPlum,
            )
        }

        // Photo fills the remaining height. No ripple: the Dart card used a
        // bare GestureDetector over the image.
        Box(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth()
                .clip(RoundedCornerShape(24.dp))
                .combinedClickable(
                    interactionSource = remember { MutableInteractionSource() },
                    indication = null,
                    onClick = { showViewer = true },
                    onLongClick = { showActions = true },
                ),
        ) {
            SubcomposeAsyncImage(
                model = ImageRequest.Builder(LocalContext.current)
                    .data(post.imageUrl)
                    .crossfade(350)
                    .build(),
                contentDescription = post.caption ?: post.senderName,
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxSize(),
                loading = {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(SoftPink.copy(alpha = 0.3f)),
                        contentAlignment = Alignment.Center,
                    ) {
                        CircularProgressIndicator()
                    }
                },
                error = {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(SoftPink.copy(alpha = 0.3f)),
                        contentAlignment = Alignment.Center,
                    ) {
                        Icon(
                            imageVector = Icons.Filled.BrokenImage,
                            contentDescription = null,
                            modifier = Modifier.size(48.dp),
                        )
                    }
                },
            )
        }

        if (!post.caption.isNullOrEmpty()) {
            Spacer(Modifier.height(10.dp))
            Text(
                text = post.caption,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 8.dp),
                textAlign = TextAlign.Center,
                fontSize = 14.sp,
                lineHeight = 19.sp, // Dart: height 1.35 at 14sp
                color = DeepPlum.copy(alpha = 0.85f),
            )
        }

        Spacer(Modifier.height(12.dp))

        // Bottom row: like pill + countdown chip, centered. The camera action
        // lives in the app bar (not a FAB) precisely so nothing covers this.
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            LikeButton(
                likedBy = post.likedBy,
                currentUid = currentUid,
                onToggle = { nowLiked ->
                    // B13 like rules: the likedBy diff must be exactly the
                    // caller's OWN uid added or removed. Throws on failure so
                    // the component rolls back its optimistic state.
                    RoomRepository.toggleLike(
                        roomId = post.roomId,
                        postId = post.id,
                        userId = currentUid,
                        like = nowLiked,
                    )
                },
                onShowLikedBy = { showLikedBy = true },
            )
            Spacer(Modifier.width(12.dp))
            CountdownChip(expiresAtMs = post.expiresAtMs)
        }
    }

    if (showViewer) {
        PhotoViewer(
            imageUrl = post.imageUrl,
            caption = post.caption,
            onDismiss = { showViewer = false },
        )
    }
    if (showActions) {
        PostActionsSheet(
            isOwnPost = post.senderId == currentUid,
            senderName = post.senderName,
            onDismiss = { showActions = false },
            onReport = onReport,
            onBlock = onBlock,
            onDelete = onDelete,
        )
    }
    if (showLikedBy) {
        // B10: the liked-by list is deliberately NOT filtered by blockedUserIds.
        LikedBySheet(
            likerIds = post.likedBy,
            onDismiss = { showLikedBy = false },
        )
    }
}

/**
 * "Xh Ym remaining" pill (coral-10%, r20) computed from the post's expiresAt.
 * B4: expiry FILTERING lives in RoomRepository.watchRoomPosts — this chip only
 * displays remaining time, but it must keep ticking (>= once/min) so the
 * countdown moves and flips to "Expired" without waiting for a feed emission.
 */
@Composable
private fun CountdownChip(expiresAtMs: Long, modifier: Modifier = Modifier) {
    var nowMs by remember { mutableLongStateOf(System.currentTimeMillis()) }
    LaunchedEffect(expiresAtMs) {
        while (true) {
            delay(30_000L) // twice the >=1/min contract, cheap recomposition
            nowMs = System.currentTimeMillis()
        }
    }
    val remainingMs = expiresAtMs - nowMs
    val hours = (remainingMs / 3_600_000L).toInt()
    val minutes = ((remainingMs / 60_000L) % 60L).toInt()

    Row(
        modifier = modifier
            .background(Coral.copy(alpha = 0.1f), RoundedCornerShape(20.dp))
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            imageVector = Icons.Outlined.Timer,
            contentDescription = null,
            modifier = Modifier.size(16.dp),
            tint = Coral,
        )
        Spacer(Modifier.width(6.dp))
        Text(
            text = if (remainingMs < 0) {
                stringResource(R.string.home_expired)
            } else {
                stringResource(R.string.home_time_remaining, hours, minutes)
            },
            fontSize = 14.sp,
            fontWeight = FontWeight.W600,
            color = Coral,
        )
    }
}
