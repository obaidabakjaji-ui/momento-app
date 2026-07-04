package com.momento.momento.ui.auth

import android.content.Context
import android.net.Uri
import androidx.browser.customtabs.CustomTabsIntent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.GMobiledata
import androidx.compose.material.icons.outlined.Email
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.rounded.CameraAlt
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.LinkAnnotation
import androidx.compose.ui.text.LinkInteractionListener
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextLinkStyles
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.withLink
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.momento.momento.R
import com.momento.momento.core.LegalUrls
import com.momento.momento.ui.theme.Coral
import com.momento.momento.ui.theme.DeepPlum
import com.momento.momento.ui.theme.WarmOrange

/** Port of `lib/screens/auth/auth_screen.dart` — sign in / sign up toggle
 *  form, Google button, forgot-password dialog, legal footer. */
@Composable
fun AuthScreen(vm: AuthViewModel = viewModel()) {
    val loading by vm.loading.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val snackbarHostState = remember { SnackbarHostState() }

    LaunchedEffect(Unit) {
        vm.events.collect { event ->
            snackbarHostState.showSnackbar(
                when (event) {
                    is AuthEvent.Error -> event.message
                    is AuthEvent.ResetLinkSent ->
                        context.getString(R.string.auth_reset_link_sent, event.email)
                    is AuthEvent.ResetFailed ->
                        context.getString(R.string.common_failed_with_error, event.message)
                }
            )
        }
    }

    var isSignUp by rememberSaveable { mutableStateOf(false) }
    var name by rememberSaveable { mutableStateOf("") }
    var email by rememberSaveable { mutableStateOf("") }
    var password by rememberSaveable { mutableStateOf("") }
    // Validation runs on submit only (the Flutter Form had autovalidate off).
    var nameError by rememberSaveable { mutableStateOf(false) }
    var emailError by rememberSaveable { mutableStateOf(false) }
    var passwordError by rememberSaveable { mutableStateOf(false) }
    var showResetDialog by rememberSaveable { mutableStateOf(false) }

    fun submit() {
        nameError = isSignUp && name.trim().isEmpty()
        emailError = !email.contains("@")
        passwordError = password.length < 6
        if (nameError || emailError || passwordError) return
        vm.submit(isSignUp, name.trim(), email.trim(), password)
    }

    Scaffold(
        containerColor = MaterialTheme.colorScheme.background,
        snackbarHost = { SnackbarHost(snackbarHostState) },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .imePadding()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 32.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            // Logo — coral→warmOrange gradient rounded square, white camera.
            Box(
                modifier = Modifier
                    .size(80.dp)
                    .background(
                        brush = Brush.linearGradient(listOf(Coral, WarmOrange)),
                        shape = RoundedCornerShape(20.dp),
                    ),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    imageVector = Icons.Rounded.CameraAlt,
                    contentDescription = null,
                    tint = Color.White,
                    modifier = Modifier.size(40.dp),
                )
            }
            Spacer(Modifier.height(16.dp))
            Text(
                text = stringResource(R.string.app_name),
                style = MaterialTheme.typography.headlineLarge,
                fontWeight = FontWeight.Bold,
                color = DeepPlum,
            )
            Spacer(Modifier.height(8.dp))
            Text(
                text = stringResource(R.string.app_tagline),
                style = MaterialTheme.typography.bodyMedium,
                textAlign = TextAlign.Center,
                color = DeepPlum.copy(alpha = 0.6f),
            )
            Spacer(Modifier.height(48.dp))

            // Name field (sign up only)
            if (isSignUp) {
                AuthTextField(
                    value = name,
                    onValueChange = { name = it },
                    hint = stringResource(R.string.auth_your_name),
                    leadingIcon = Icons.Outlined.Person,
                    isError = nameError,
                    errorText = stringResource(R.string.auth_your_name_hint),
                )
                Spacer(Modifier.height(12.dp))
            }

            // Email
            AuthTextField(
                value = email,
                onValueChange = { email = it },
                hint = stringResource(R.string.auth_email),
                leadingIcon = Icons.Outlined.Email,
                isError = emailError,
                errorText = stringResource(R.string.auth_email_hint),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email),
            )
            Spacer(Modifier.height(12.dp))

            // Password (no visibility toggle — the Flutter screen has none)
            AuthTextField(
                value = password,
                onValueChange = { password = it },
                hint = stringResource(R.string.auth_password),
                leadingIcon = Icons.Outlined.Lock,
                isError = passwordError,
                errorText = stringResource(R.string.auth_password_hint),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                visualTransformation = PasswordVisualTransformation(),
            )
            Spacer(Modifier.height(24.dp))

            // Submit
            Button(
                onClick = ::submit,
                enabled = !loading,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                shape = RoundedCornerShape(16.dp),
            ) {
                if (loading) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        strokeWidth = 2.dp,
                        color = Color.White,
                    )
                } else {
                    Text(
                        stringResource(
                            if (isSignUp) R.string.auth_create_account else R.string.auth_sign_in
                        )
                    )
                }
            }
            if (!isSignUp) {
                Box(Modifier.fillMaxWidth()) {
                    TextButton(
                        onClick = { showResetDialog = true },
                        enabled = !loading,
                        modifier = Modifier.align(Alignment.CenterEnd),
                    ) {
                        Text(stringResource(R.string.auth_forgot_password))
                    }
                }
            }
            Spacer(Modifier.height(12.dp))

            // Google sign in
            OutlinedButton(
                onClick = { vm.signInWithGoogle(context) },
                enabled = !loading,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                shape = RoundedCornerShape(16.dp),
            ) {
                Icon(
                    imageVector = Icons.Filled.GMobiledata,
                    contentDescription = null,
                    modifier = Modifier.size(24.dp),
                )
                Text(stringResource(R.string.auth_continue_with_google))
            }
            Spacer(Modifier.height(24.dp))

            // Toggle sign up / sign in
            TextButton(onClick = { isSignUp = !isSignUp }) {
                Text(
                    stringResource(
                        if (isSignUp) R.string.auth_already_have_account else R.string.auth_no_account
                    )
                )
            }
            Spacer(Modifier.height(8.dp))
            LegalFooter(isSignUp = isSignUp)
        }
    }

    if (showResetDialog) {
        ResetPasswordDialog(
            initialEmail = email.trim(),
            onDismiss = { showResetDialog = false },
            onSend = { vm.sendPasswordReset(it) },
        )
    }
}

@Composable
private fun AuthTextField(
    value: String,
    onValueChange: (String) -> Unit,
    hint: String,
    leadingIcon: ImageVector,
    isError: Boolean,
    errorText: String,
    keyboardOptions: KeyboardOptions = KeyboardOptions.Default,
    visualTransformation: VisualTransformation = VisualTransformation.None,
) {
    // White filled field, r12, coral focus border — the app's input theme.
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        modifier = Modifier.fillMaxWidth(),
        placeholder = { Text(hint) },
        leadingIcon = { Icon(leadingIcon, contentDescription = null) },
        singleLine = true,
        isError = isError,
        supportingText = if (isError) {
            { Text(errorText) }
        } else {
            null
        },
        keyboardOptions = keyboardOptions,
        visualTransformation = visualTransformation,
        shape = RoundedCornerShape(12.dp),
        colors = OutlinedTextFieldDefaults.colors(
            focusedContainerColor = Color.White,
            unfocusedContainerColor = Color.White,
            errorContainerColor = Color.White,
            focusedBorderColor = Coral,
            unfocusedBorderColor = Color.Transparent,
        ),
    )
}

@Composable
private fun ResetPasswordDialog(
    initialEmail: String,
    onDismiss: () -> Unit,
    onSend: (String) -> Unit,
) {
    var value by rememberSaveable { mutableStateOf(initialEmail) }
    val focusRequester = remember { FocusRequester() }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(R.string.auth_reset_password_title)) },
        text = {
            Column {
                Text(stringResource(R.string.auth_reset_password_description))
                Spacer(Modifier.height(16.dp))
                OutlinedTextField(
                    value = value,
                    onValueChange = { value = it },
                    modifier = Modifier
                        .fillMaxWidth()
                        .focusRequester(focusRequester),
                    placeholder = { Text(stringResource(R.string.auth_email_placeholder)) },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email),
                )
            }
        },
        confirmButton = {
            TextButton(onClick = {
                onSend(value.trim())
                onDismiss()
            }) {
                Text(stringResource(R.string.auth_send))
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(stringResource(R.string.common_cancel))
            }
        },
    )
    LaunchedEffect(Unit) { focusRequester.requestFocus() }
}

@Composable
private fun LegalFooter(isSignUp: Boolean) {
    val context = LocalContext.current
    val prefix = stringResource(
        if (isSignUp) R.string.auth_by_creating_you_agree else R.string.auth_by_signing_in_you_agree
    )
    val terms = stringResource(R.string.auth_terms)
    val privacy = stringResource(R.string.auth_privacy_policy)
    val linkStyles = TextLinkStyles(
        style = SpanStyle(color = Coral, textDecoration = TextDecoration.Underline)
    )
    val openLink = LinkInteractionListener { link ->
        openCustomTab(context, (link as LinkAnnotation.Url).url)
    }
    val text = buildAnnotatedString {
        append(prefix)
        withLink(LinkAnnotation.Url(LegalUrls.TERMS_URL, linkStyles, openLink)) {
            append(terms)
        }
        append(" · ")
        withLink(LinkAnnotation.Url(LegalUrls.PRIVACY_URL, linkStyles, openLink)) {
            append(privacy)
        }
        append(".")
    }
    Text(
        text = text,
        modifier = Modifier.padding(horizontal = 16.dp),
        fontSize = 11.sp,
        lineHeight = 15.sp,
        textAlign = TextAlign.Center,
        color = DeepPlum.copy(alpha = 0.6f),
    )
}

private fun openCustomTab(context: Context, url: String) {
    CustomTabsIntent.Builder().build().launchUrl(context, Uri.parse(url))
}
