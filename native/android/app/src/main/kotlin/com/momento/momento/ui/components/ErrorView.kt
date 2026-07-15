package com.momento.momento.ui.components

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.outlined.CloudOff
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.momento.momento.R
import com.momento.momento.ui.theme.DeepPlum

/**
 * Port of `lib/widgets/error_view.dart` — friendly error placeholder used by
 * stream/flow collectors: 64dp cloud-off (plum 30%), message (plum 70%, 15sp),
 * optional outlined retry button.
 *
 * Callers pass sizing via [modifier] (typically `Modifier.fillMaxSize()` to
 * center in the viewport, mirroring the Flutter `Center` wrapper).
 */
@Composable
fun ErrorView(
    message: String,
    onRetry: (() -> Unit)? = null,
    modifier: Modifier = Modifier,
) {
    Box(modifier = modifier, contentAlignment = Alignment.Center) {
        Column(
            modifier = Modifier.padding(32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Icon(
                imageVector = Icons.Outlined.CloudOff,
                contentDescription = null,
                tint = DeepPlum.copy(alpha = 0.3f),
                modifier = Modifier.size(64.dp),
            )
            Spacer(Modifier.height(16.dp))
            Text(
                text = message,
                textAlign = TextAlign.Center,
                color = DeepPlum.copy(alpha = 0.7f),
                fontSize = 15.sp,
            )
            if (onRetry != null) {
                Spacer(Modifier.height(16.dp))
                OutlinedButton(onClick = onRetry) {
                    Icon(
                        imageVector = Icons.Filled.Refresh,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp),
                    )
                    Spacer(Modifier.width(8.dp))
                    Text(stringResource(R.string.common_retry))
                }
            }
        }
    }
}
