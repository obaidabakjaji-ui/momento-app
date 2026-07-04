package com.momento.momento.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

// Brand palette — must stay identical to MomentoTheme in the Flutter app
// (lib/theme.dart) until cutover so screenshots/tests compare 1:1.
val Coral = Color(0xFFFF6B6B)
val WarmOrange = Color(0xFFFF9A56)
val SoftPink = Color(0xFFFFB7B2)
val DeepPlum = Color(0xFF2D2337)
val Seashell = Color(0xFFFFF5EE)

private val LightColors = lightColorScheme(
    primary = Coral,
    secondary = WarmOrange,
    tertiary = SoftPink,
    background = Seashell,
    surface = Color.White,
    onPrimary = Color.White,
    onSecondary = Color.White,
    onBackground = DeepPlum,
    onSurface = DeepPlum,
)

@Composable
fun HuddlexTheme(content: @Composable () -> Unit) {
    // The Flutter app ships light-only; dark mode is a post-cutover
    // opportunity, not a parity requirement.
    @Suppress("UNUSED_EXPRESSION") isSystemInDarkTheme()
    MaterialTheme(
        colorScheme = LightColors,
        content = content,
    )
}
