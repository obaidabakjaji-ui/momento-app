package com.momento.momento.ui.components

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.gestures.rememberTransformableState
import androidx.compose.foundation.gestures.transformable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BrokenImage
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.input.pointer.util.VelocityTracker
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import coil.compose.SubcomposeAsyncImage
import com.momento.momento.R
import kotlin.math.abs

/**
 * Port of `lib/widgets/photo_viewer.dart` — fullscreen black photo viewer.
 *
 * - Pinch-zoom 1x–4x ([Modifier.transformable]); single-finger pan when zoomed.
 * - Tap or fast vertical fling (velocity > 300 dp/s, matching Flutter's
 *   logical-pixel threshold) dismisses. Fling only applies at 1x — when
 *   zoomed, drags pan the image instead.
 * - White close button top-right, caption in a black-50% r12 pill at bottom.
 *
 * DEVIATION (sanctioned for this phase): the Flutter hero transition is
 * replaced with a simple 200ms fade-in fullscreen dialog. Shared-element
 * transitions can be layered on post-cutover.
 */
@Composable
fun PhotoViewer(
    imageUrl: String,
    caption: String?,
    onDismiss: () -> Unit,
) {
    val currentOnDismiss by rememberUpdatedState(onDismiss)

    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(
            usePlatformDefaultWidth = false,
            decorFitsSystemWindows = false,
        ),
    ) {
        // Simple fade-in in lieu of the Flutter hero transition.
        val appear = remember { Animatable(0f) }
        LaunchedEffect(Unit) { appear.animateTo(1f, tween(durationMillis = 200)) }

        var scale by remember { mutableFloatStateOf(1f) }
        var offset by remember { mutableStateOf(Offset.Zero) }
        var containerSize by remember { mutableStateOf(IntSize.Zero) }

        // Keep the image from panning fully off-screen (InteractiveViewer-ish).
        fun clampOffset(candidate: Offset, atScale: Float): Offset {
            val maxX = containerSize.width * (atScale - 1f) / 2f
            val maxY = containerSize.height * (atScale - 1f) / 2f
            return Offset(
                candidate.x.coerceIn(-maxX, maxX),
                candidate.y.coerceIn(-maxY, maxY),
            )
        }

        val transformState = rememberTransformableState { zoomChange, panChange, _ ->
            scale = (scale * zoomChange).coerceIn(1f, 4f)
            offset = if (scale > 1f) clampOffset(offset + panChange, scale) else Offset.Zero
        }

        // Flutter's `primaryVelocity > 300` is logical px/s == dp/s in Compose.
        val flingThresholdPxPerSec = with(LocalDensity.current) { 300.dp.toPx() }

        Box(
            modifier = Modifier
                .fillMaxSize()
                .graphicsLayer { alpha = appear.value }
                .background(Color.Black)
                .onSizeChanged { containerSize = it }
                .pointerInput(Unit) {
                    detectTapGestures(onTap = { currentOnDismiss() })
                }
                // Passive vertical-fling observer: never consumes, so it does
                // not fight the transformable pinch/pan handling below.
                .pointerInput(Unit) {
                    awaitEachGesture {
                        val tracker = VelocityTracker()
                        var multiTouch = false
                        val down = awaitFirstDown(requireUnconsumed = false)
                        tracker.addPosition(down.uptimeMillis, down.position)
                        while (true) {
                            val event = awaitPointerEvent()
                            if (event.changes.count { it.pressed } > 1) multiTouch = true
                            val tracked = event.changes.firstOrNull { it.id == down.id }
                            if (tracked != null) {
                                tracker.addPosition(tracked.uptimeMillis, tracked.position)
                            }
                            if (event.changes.none { it.pressed }) break
                        }
                        val velocity = tracker.calculateVelocity()
                        val vertical = abs(velocity.y) > abs(velocity.x)
                        if (!multiTouch && scale <= 1.01f && vertical &&
                            abs(velocity.y) > flingThresholdPxPerSec
                        ) {
                            currentOnDismiss()
                        }
                    }
                }
                .transformable(transformState),
        ) {
            SubcomposeAsyncImage(
                model = imageUrl,
                contentDescription = caption,
                contentScale = ContentScale.Fit,
                loading = {
                    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator(color = Color.White)
                    }
                },
                error = {
                    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Icon(
                            imageVector = Icons.Filled.BrokenImage,
                            contentDescription = null,
                            tint = Color.White,
                            modifier = Modifier.size(64.dp),
                        )
                    }
                },
                modifier = Modifier
                    .fillMaxSize()
                    .graphicsLayer {
                        scaleX = scale
                        scaleY = scale
                        translationX = offset.x
                        translationY = offset.y
                    },
            )

            IconButton(
                onClick = onDismiss,
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .statusBarsPadding()
                    .padding(8.dp),
            ) {
                Icon(
                    imageVector = Icons.Filled.Close,
                    contentDescription = stringResource(R.string.component_close),
                    tint = Color.White,
                )
            }

            if (!caption.isNullOrEmpty()) {
                Box(
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .navigationBarsPadding()
                        .padding(start = 16.dp, end = 16.dp, bottom = 24.dp)
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(12.dp))
                        .background(Color.Black.copy(alpha = 0.5f))
                        .padding(horizontal = 16.dp, vertical = 12.dp),
                ) {
                    Text(text = caption, color = Color.White)
                }
            }
        }
    }
}
