package com.momento.momento.ui.components

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.EaseOut
import androidx.compose.animation.core.keyframes
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.momento.momento.ui.theme.Coral
import com.momento.momento.ui.theme.DeepPlum
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.launch

/**
 * Port of `lib/widgets/like_button.dart` — heart pill with count.
 *
 * - Optimistic toggle: flips liked/count immediately, rolls back if [onToggle]
 *   throws.
 * - Busy guard: external [likedBy] updates are ignored while a toggle is
 *   in flight (mirror of the Dart `_busy` + `didUpdateWidget` guard).
 * - Bounce 1.0 -> 1.35 -> 1.0 over 280ms easeOut on LIKE only (not unlike).
 * - Long-press opens the liked-by sheet ONLY when [likedBy] is non-empty.
 *
 * @param onToggle suspend; performs the Firestore write (e.g.
 *   `RoomRepository.toggleLike`). Must throw on failure so the component can
 *   roll back the optimistic state.
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun LikeButton(
    likedBy: List<String>,
    currentUid: String,
    onToggle: suspend (nowLiked: Boolean) -> Unit,
    onShowLikedBy: () -> Unit,
    modifier: Modifier = Modifier,
) {
    var liked by remember { mutableStateOf(likedBy.contains(currentUid)) }
    var count by remember { mutableIntStateOf(likedBy.size) }
    var busy by remember { mutableStateOf(false) }
    val scale = remember { Animatable(1f) }
    val scope = rememberCoroutineScope()
    val currentOnToggle by rememberUpdatedState(onToggle)

    // Reflect external changes (e.g. another user liked) when not mid-toggle —
    // the Compose analogue of the Dart didUpdateWidget sync.
    LaunchedEffect(likedBy, currentUid) {
        if (!busy) {
            liked = likedBy.contains(currentUid)
            count = likedBy.size
        }
    }

    fun toggle() {
        if (busy) return
        val nowLiked = !liked
        busy = true
        liked = nowLiked
        count += if (nowLiked) 1 else -1
        if (nowLiked) {
            scope.launch {
                scale.snapTo(1f)
                scale.animateTo(
                    targetValue = 1f,
                    animationSpec = keyframes {
                        durationMillis = 280
                        1.0f at 0 using EaseOut
                        1.35f at 140 using EaseOut
                        1.0f at 280
                    },
                )
            }
        }
        scope.launch {
            try {
                currentOnToggle(nowLiked)
            } catch (e: CancellationException) {
                throw e
            } catch (_: Exception) {
                // Roll back on failure.
                liked = !nowLiked
                count += if (nowLiked) -1 else 1
            } finally {
                busy = false
            }
        }
    }

    Row(
        modifier = modifier
            .clip(RoundedCornerShape(20.dp))
            .background(
                if (liked) Coral.copy(alpha = 0.15f)
                else DeepPlum.copy(alpha = 0.06f)
            )
            .combinedClickable(
                onClick = { toggle() },
                onLongClick = if (likedBy.isNotEmpty()) onShowLikedBy else null,
            )
            .padding(horizontal = 14.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            imageVector = if (liked) Icons.Filled.Favorite else Icons.Filled.FavoriteBorder,
            contentDescription = null,
            tint = if (liked) Coral else DeepPlum.copy(alpha = 0.6f),
            modifier = Modifier
                .size(16.dp)
                .graphicsLayer {
                    scaleX = scale.value
                    scaleY = scale.value
                },
        )
        if (count > 0) {
            Spacer(Modifier.width(6.dp))
            Text(
                text = count.toString(),
                fontSize = 13.sp,
                fontWeight = FontWeight.W600,
                color = if (liked) Coral else DeepPlum.copy(alpha = 0.7f),
            )
        }
    }
}
