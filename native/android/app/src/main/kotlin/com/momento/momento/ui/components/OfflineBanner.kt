package com.momento.momento.ui.components

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.util.Log
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.expandVertically
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CloudOff
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.momento.momento.R
import com.momento.momento.ui.theme.DeepPlum
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow

private const val TAG = "OfflineBanner"

/**
 * Port of `lib/widgets/offline_banner.dart` — deepPlum full-width strip shown
 * while the device has no connectivity, with a 200ms animated collapse/expand.
 *
 * Self-contained connectivity monitoring: ConnectivityManager's default
 * network callback wrapped in a [callbackFlow]. "Offline" means EVERY network
 * transport is gone (the Dart `result.every((r) => r == none)` contract) —
 * on `onLost` we re-check `activeNetwork` so a wifi→cellular handover never
 * flashes the banner.
 *
 * Any registration/service failure folds to "online" (banner hidden) rather
 * than crashing or failing the flow.
 *
 * NOTE: requires `android.permission.ACCESS_NETWORK_STATE` in the manifest
 * (a normal, install-time permission). Without it registration throws a
 * SecurityException, which this component folds to permanently-online.
 */
@Composable
fun OfflineBanner(modifier: Modifier = Modifier) {
    val appContext = LocalContext.current.applicationContext
    val offlineFlow = remember(appContext) { connectivityOfflineFlow(appContext) }
    val offline by offlineFlow.collectAsStateWithLifecycle(initialValue = false)

    AnimatedVisibility(
        visible = offline,
        enter = expandVertically(animationSpec = tween(durationMillis = 200)),
        exit = shrinkVertically(animationSpec = tween(durationMillis = 200)),
        modifier = modifier,
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(DeepPlum)
                .padding(vertical = 8.dp, horizontal = 16.dp),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(
                imageVector = Icons.Filled.CloudOff,
                contentDescription = null,
                tint = Color.White,
                modifier = Modifier.size(16.dp),
            )
            Spacer(Modifier.width(8.dp))
            Text(
                text = stringResource(R.string.common_you_are_offline),
                color = Color.White,
                fontSize = 13.sp,
            )
        }
    }
}

/**
 * Emits `true` while the device is offline (no default network at all).
 * Never closes with an error — failures are logged and folded to `false`
 * (online), per the house callbackFlow rule.
 */
private fun connectivityOfflineFlow(context: Context): Flow<Boolean> = callbackFlow {
    val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
    if (cm == null) {
        Log.w(TAG, "ConnectivityManager unavailable — assuming online")
        trySend(false)
        awaitClose { }
        return@callbackFlow
    }

    val callback = object : ConnectivityManager.NetworkCallback() {
        override fun onAvailable(network: Network) {
            trySend(false)
        }

        override fun onLost(network: Network) {
            // Offline only if NO network took over (every transport gone).
            val stillConnected = try {
                cm.activeNetwork != null
            } catch (e: Exception) {
                Log.w(TAG, "activeNetwork check failed — assuming online", e)
                true
            }
            trySend(!stillConnected)
        }

        override fun onUnavailable() {
            trySend(true)
        }
    }

    var registered = false
    try {
        // Initial state before the first callback fires.
        trySend(cm.activeNetwork == null)
        cm.registerDefaultNetworkCallback(callback)
        registered = true
    } catch (e: Exception) {
        // House rule: never close(error) a callbackFlow — log, emit safe value.
        Log.w(TAG, "Network callback registration failed — assuming online", e)
        trySend(false)
    }

    awaitClose {
        if (registered) {
            runCatching { cm.unregisterNetworkCallback(callback) }
                .onFailure { Log.w(TAG, "unregisterNetworkCallback failed", it) }
        }
    }
}
