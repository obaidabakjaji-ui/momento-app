package com.momento.momento.ui.auth

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Logout
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.momento.momento.R
import com.momento.momento.ui.theme.Coral
import com.momento.momento.ui.theme.DeepPlum

/**
 * Port of `lib/screens/auth/verify_email_screen.dart` — hard gate shown right
 * after sign-up (and on launch for unverified accounts). On a correct code the
 * repository reloads the user and AuthGate routes onward on the next authFlow
 * emission (B1); this screen never navigates itself.
 */
@Composable
fun VerifyEmailScreen(
    uid: String,
    vm: VerifyEmailViewModel = viewModel(key = "verify-email-$uid"),
) {
    val state by vm.state.collectAsStateWithLifecycle()
    val focusRequester = remember { FocusRequester() }
    val keyboard = LocalSoftwareKeyboardController.current

    // Runs on first entry (tick 0 → initial focus, like the Dart
    // post-frame callback) and again whenever a wrong code bumps the tick.
    LaunchedEffect(state.refocusTick) {
        focusRequester.requestFocus()
        keyboard?.show()
    }

    Scaffold(containerColor = MaterialTheme.colorScheme.background) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .imePadding()
                .padding(horizontal = 28.dp, vertical = 32.dp),
        ) {
            // Escape hatch — without it an unverified account is stuck here.
            IconButton(onClick = vm::signOut) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.Logout,
                    contentDescription = stringResource(R.string.auth_sign_out),
                    tint = DeepPlum,
                )
            }
            Spacer(Modifier.height(24.dp))
            Text(
                text = stringResource(R.string.verify_title),
                fontSize = 28.sp,
                fontWeight = FontWeight.W700,
                color = DeepPlum,
            )
            Spacer(Modifier.height(10.dp))
            Text(
                text = stringResource(R.string.verify_description, vm.email),
                fontSize = 15.sp,
                lineHeight = 21.sp,
                color = DeepPlum.copy(alpha = 0.7f),
            )
            Spacer(Modifier.height(36.dp))
            CodeField(
                code = state.code,
                enabled = !state.verifying,
                onCodeChange = vm::onCodeChange,
                focusRequester = focusRequester,
            )
            state.error?.let {
                Spacer(Modifier.height(16.dp))
                Text(text = it.resolve(), color = Coral)
            }
            state.info?.let {
                Spacer(Modifier.height(16.dp))
                Text(text = it.resolve(), color = DeepPlum.copy(alpha = 0.7f))
            }
            Spacer(Modifier.weight(1f))
            TextButton(
                onClick = vm::resend,
                enabled = state.resendSecondsLeft == 0 && !state.verifying,
                modifier = Modifier.align(Alignment.CenterHorizontally),
            ) {
                Text(
                    text = if (state.resendSecondsLeft > 0) {
                        stringResource(R.string.verify_resend_in, state.resendSecondsLeft)
                    } else {
                        stringResource(R.string.verify_resend)
                    },
                    fontWeight = FontWeight.W600,
                )
            }
            if (state.verifying) {
                CircularProgressIndicator(
                    modifier = Modifier
                        .align(Alignment.CenterHorizontally)
                        .padding(top = 8.dp),
                )
            }
        }
    }
}

@Composable
private fun VerifyMessage.resolve(): String = when (this) {
    is VerifyMessage.Raw -> text
    is VerifyMessage.Res -> stringResource(id)
}

/**
 * Six drawn code boxes backed by ONE hidden text field (the Dart screen's
 * Stack of an opacity-0 TextField under painted boxes). Tapping anywhere on
 * the row focuses the hidden field; the ViewModel filters to digits, caps at
 * 6, and auto-submits when full.
 */
@Composable
private fun CodeField(
    code: String,
    enabled: Boolean,
    onCodeChange: (String) -> Unit,
    focusRequester: FocusRequester,
) {
    BasicTextField(
        value = code,
        onValueChange = onCodeChange,
        modifier = Modifier
            .fillMaxWidth()
            .focusRequester(focusRequester),
        enabled = enabled,
        singleLine = true,
        keyboardOptions = KeyboardOptions(
            keyboardType = KeyboardType.Number,
            imeAction = ImeAction.Done,
        ),
        // The real input stays invisible — the boxes below are the visual.
        textStyle = TextStyle(color = Color.Transparent),
        cursorBrush = SolidColor(Color.Transparent),
        decorationBox = { innerTextField ->
            Box {
                Box(
                    modifier = Modifier
                        .matchParentSize()
                        .alpha(0f),
                ) {
                    innerTextField()
                }
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                ) {
                    repeat(6) { i ->
                        CodeBox(
                            digit = code.getOrNull(i)?.toString() ?: "",
                            active = enabled && i == code.length,
                        )
                    }
                }
            }
        },
    )
}

@Composable
private fun CodeBox(digit: String, active: Boolean) {
    Box(
        modifier = Modifier
            .size(width = 46.dp, height = 56.dp)
            .background(Color.White, RoundedCornerShape(12.dp))
            .border(
                width = if (active) 2.dp else 1.dp,
                color = if (active) Coral else DeepPlum.copy(alpha = 0.12f),
                shape = RoundedCornerShape(12.dp),
            ),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = digit,
            fontSize = 22.sp,
            fontWeight = FontWeight.W700,
            color = DeepPlum,
        )
    }
}
