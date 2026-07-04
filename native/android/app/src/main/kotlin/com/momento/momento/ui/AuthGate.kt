package com.momento.momento.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.momento.momento.data.AuthRepository
import com.momento.momento.data.AuthUserSnapshot
import com.momento.momento.data.UserRepository
import com.momento.momento.ui.auth.AuthScreen
import com.momento.momento.ui.auth.VerifyEmailScreen

/**
 * Distinguishes "auth state not known yet" from "signed out" (null). Compared
 * by identity so no real emission can ever collide with it.
 */
private val LoadingSentinel = AuthUserSnapshot(
    uid = "",
    email = null,
    displayName = null,
    emailVerified = false,
    generation = Long.MIN_VALUE,
)

/**
 * Routing mirror of the Flutter `AuthGate` (lib/main.dart):
 * spinner (pre-first-emission) → [AuthScreen] (signed out) →
 * [VerifyEmailScreen] (!emailVerified — Google accounts arrive verified and
 * skip it) → spinner while the user doc is null → onboarding → home.
 *
 * Onboarding/Home are later phases, so they're injected as slots.
 */
@Composable
fun AuthGate(
    onboarding: @Composable () -> Unit,
    home: @Composable () -> Unit,
) {
    // authFlow is userChanges-semantics (B1): it re-emits after
    // reloadCurrentUser(), which is what routes away from the verify screen
    // the moment a correct code lands.
    val snapshot by AuthRepository.authFlow
        .collectAsStateWithLifecycle(initialValue = LoadingSentinel)
    val snap = snapshot
    when {
        snap === LoadingSentinel -> LoadingScreen()
        snap == null -> AuthScreen()
        // Keyed on uid so a second unverified account in the same Activity
        // gets a fresh ViewModel (fresh auto-sent code, no stale state).
        !snap.emailVerified -> VerifyEmailScreen(uid = snap.uid)
        else -> VerifiedGate(uid = snap.uid, onboarding = onboarding, home = home)
    }
}

@Composable
private fun VerifiedGate(
    uid: String,
    onboarding: @Composable () -> Unit,
    home: @Composable () -> Unit,
) {
    // Keyed on uid so signing out and back in with a different account
    // re-subscribes to the right doc.
    val userFlow = remember(uid) { UserRepository.watchUser(uid) }
    val user by userFlow.collectAsStateWithLifecycle(initialValue = null)
    val appUser = user
    when {
        // null covers both "first snapshot not in yet" and "doc missing" —
        // during the sign-up doc-creation race we must keep spinning, never
        // flash onboarding.
        appUser == null -> LoadingScreen()
        !appUser.hasSeenOnboarding -> onboarding()
        else -> home()
    }
}

@Composable
private fun LoadingScreen() {
    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        CircularProgressIndicator()
    }
}
