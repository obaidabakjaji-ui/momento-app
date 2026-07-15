package com.momento.momento.ui.components

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.TileMode
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.momento.momento.ui.theme.SoftPink

/**
 * Port of `lib/widgets/shimmer_placeholder.dart` — a softPink gradient
 * (alpha .15 / .35 / .15) sweeping horizontally on an infinite 1200ms loop.
 * Used in place of a bare spinner while feeds and room lists load.
 *
 * The sweep reproduces the Dart alignment math: gradient start/end slide from
 * `Alignment(-1 + 2t)` to `Alignment(1 + 2t)`, i.e. from x = t·w to (1+t)·w,
 * clamped at the edges.
 */
@Composable
fun ShimmerPlaceholder(
    modifier: Modifier = Modifier,
    height: Dp = 80.dp,
    radius: Dp = 12.dp,
) {
    val transition = rememberInfiniteTransition(label = "shimmer")
    val t by transition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 1200, easing = LinearEasing),
            repeatMode = RepeatMode.Restart,
        ),
        label = "shimmerSweep",
    )
    val colors = remember {
        listOf(
            SoftPink.copy(alpha = 0.15f),
            SoftPink.copy(alpha = 0.35f),
            SoftPink.copy(alpha = 0.15f),
        )
    }

    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(height)
            .drawBehind {
                val brush = Brush.horizontalGradient(
                    colors = colors,
                    startX = t * size.width,
                    endX = (1f + t) * size.width,
                    tileMode = TileMode.Clamp,
                )
                drawRoundRect(brush = brush, cornerRadius = CornerRadius(radius.toPx()))
            },
    )
}

/**
 * Port of the Dart `ShimmerList` — five rounded r12 shimmer tiles, the
 * standard list/feed loading state.
 */
@Composable
fun ShimmerList(modifier: Modifier = Modifier) {
    Column(
        modifier = modifier.padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        repeat(5) {
            ShimmerPlaceholder()
        }
    }
}
