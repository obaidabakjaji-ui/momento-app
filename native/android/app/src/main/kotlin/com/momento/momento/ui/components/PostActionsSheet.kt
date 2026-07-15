package com.momento.momento.ui.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Block
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.Flag
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.momento.momento.R
import com.momento.momento.ui.theme.DeepPlum

// Flutter used Colors.red for all destructive affordances.
private val DestructiveRed = Color(0xFFF44336)

private const val REPORT_REASON_MAX_LENGTH = 200

private enum class PendingAction { Report, Block, Delete }

/**
 * Port of `lib/widgets/post_actions_sheet.dart` — long-press moderation sheet.
 *
 * Others' posts: Report (reason dialog, max 200 chars) + Block (confirm).
 * Own post: Delete (confirm). All destructive items in red.
 *
 * The callbacks fire AFTER the user confirms the dialog; the caller performs
 * the actual repository call and any result snackbar, then removes this
 * composable (it also receives [onDismiss] right after the callback).
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PostActionsSheet(
    isOwnPost: Boolean,
    senderName: String,
    onDismiss: () -> Unit,
    onReport: (reason: String) -> Unit,
    onBlock: () -> Unit,
    onDelete: () -> Unit,
) {
    var pending by remember { mutableStateOf<PendingAction?>(null) }

    when (pending) {
        null -> ModalBottomSheet(
            onDismissRequest = onDismiss,
            containerColor = Color.White,
            shape = RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp),
            dragHandle = { SheetDragHandle() },
        ) {
            Column(
                Modifier
                    .fillMaxWidth()
                    .navigationBarsPadding()
                    .padding(bottom = 8.dp)
            ) {
                if (!isOwnPost) {
                    ActionRow(
                        icon = Icons.Outlined.Flag,
                        title = stringResource(R.string.post_actions_report_title),
                        onClick = { pending = PendingAction.Report },
                    )
                    ActionRow(
                        icon = Icons.Filled.Block,
                        title = stringResource(R.string.post_actions_block_user, senderName),
                        subtitle = stringResource(R.string.post_actions_block_description),
                        onClick = { pending = PendingAction.Block },
                    )
                } else {
                    ActionRow(
                        icon = Icons.Outlined.Delete,
                        title = stringResource(R.string.post_actions_delete),
                        onClick = { pending = PendingAction.Delete },
                    )
                }
            }
        }

        PendingAction.Report -> ReportReasonDialog(
            onCancel = onDismiss,
            onSubmit = { reason ->
                onReport(reason)
                onDismiss()
            },
        )

        PendingAction.Block -> ConfirmDialog(
            title = stringResource(R.string.post_actions_block_title, senderName),
            body = stringResource(R.string.post_actions_block_body, senderName),
            confirmLabel = stringResource(R.string.post_actions_block),
            onCancel = onDismiss,
            onConfirm = {
                onBlock()
                onDismiss()
            },
        )

        PendingAction.Delete -> ConfirmDialog(
            title = stringResource(R.string.post_actions_delete_title),
            body = stringResource(R.string.post_actions_delete_body),
            confirmLabel = stringResource(R.string.common_delete),
            onCancel = onDismiss,
            onConfirm = {
                onDelete()
                onDismiss()
            },
        )
    }
}

@Composable
private fun ActionRow(
    icon: ImageVector,
    title: String,
    onClick: () -> Unit,
    subtitle: String? = null,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = DestructiveRed,
            modifier = Modifier.size(24.dp),
        )
        Spacer(Modifier.width(16.dp))
        Column {
            Text(title, fontSize = 16.sp, color = DeepPlum)
            if (subtitle != null) {
                Text(subtitle, fontSize = 13.sp, color = DeepPlum.copy(alpha = 0.6f))
            }
        }
    }
}

@Composable
private fun ReportReasonDialog(
    onCancel: () -> Unit,
    onSubmit: (String) -> Unit,
) {
    var text by remember { mutableStateOf("") }
    val focusRequester = remember { FocusRequester() }

    AlertDialog(
        onDismissRequest = onCancel,
        title = { Text(stringResource(R.string.post_actions_report_prompt)) },
        text = {
            OutlinedTextField(
                value = text,
                onValueChange = { if (it.length <= REPORT_REASON_MAX_LENGTH) text = it },
                placeholder = { Text(stringResource(R.string.post_actions_report_placeholder)) },
                minLines = 3,
                maxLines = 3,
                supportingText = { Text("${text.length}/$REPORT_REASON_MAX_LENGTH") },
                modifier = Modifier
                    .fillMaxWidth()
                    .focusRequester(focusRequester),
            )
        },
        confirmButton = {
            TextButton(onClick = { onSubmit(text.trim()) }) {
                Text(stringResource(R.string.common_submit))
            }
        },
        dismissButton = {
            TextButton(onClick = onCancel) {
                Text(stringResource(R.string.common_cancel))
            }
        },
    )

    LaunchedEffect(Unit) { focusRequester.requestFocus() }
}

@Composable
private fun ConfirmDialog(
    title: String,
    body: String,
    confirmLabel: String,
    onCancel: () -> Unit,
    onConfirm: () -> Unit,
) {
    AlertDialog(
        onDismissRequest = onCancel,
        title = { Text(title) },
        text = { Text(body) },
        confirmButton = {
            TextButton(
                onClick = onConfirm,
                colors = ButtonDefaults.textButtonColors(contentColor = DestructiveRed),
            ) {
                Text(confirmLabel)
            }
        },
        dismissButton = {
            TextButton(onClick = onCancel) {
                Text(stringResource(R.string.common_cancel))
            }
        },
    )
}
