package com.momento.momento.ui.auth

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.momento.momento.data.AuthRepository
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/** One-shot snackbar events. Raw messages come from exceptions (mirrors the
 *  Dart screen showing `e.toString()`); the screen resolves the rest from
 *  string resources. */
sealed interface AuthEvent {
    data class Error(val message: String) : AuthEvent
    data class ResetLinkSent(val email: String) : AuthEvent
    data class ResetFailed(val message: String) : AuthEvent
}

class AuthViewModel : ViewModel() {

    // Single loading flag gates both the email submit and the Google button,
    // matching the Flutter screen's `_loading`.
    private val _loading = MutableStateFlow(false)
    val loading: StateFlow<Boolean> = _loading.asStateFlow()

    private val _events = MutableSharedFlow<AuthEvent>()
    val events: SharedFlow<AuthEvent> = _events.asSharedFlow()

    /** Sign in or sign up. On success no navigation happens here — AuthGate
     *  re-routes on the next authFlow emission. */
    fun submit(isSignUp: Boolean, name: String, email: String, password: String) {
        if (_loading.value) return
        viewModelScope.launch {
            _loading.value = true
            try {
                if (isSignUp) {
                    AuthRepository.signUpWithEmail(name, email, password)
                } else {
                    AuthRepository.signInWithEmail(email, password)
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                _events.emit(AuthEvent.Error(e.message ?: e.toString()))
            } finally {
                _loading.value = false
            }
        }
    }

    /** [context] must be an Activity context — CredentialManager shows UI. */
    fun signInWithGoogle(context: Context) {
        if (_loading.value) return
        viewModelScope.launch {
            _loading.value = true
            try {
                AuthRepository.signInWithGoogle(context)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                _events.emit(AuthEvent.Error(e.message ?: e.toString()))
            } finally {
                _loading.value = false
            }
        }
    }

    fun sendPasswordReset(email: String) {
        // Same silent bail-out as the Dart dialog handler.
        if (email.isEmpty() || !email.contains("@")) return
        viewModelScope.launch {
            try {
                AuthRepository.sendPasswordResetEmail(email)
                _events.emit(AuthEvent.ResetLinkSent(email))
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                _events.emit(AuthEvent.ResetFailed(e.message ?: e.toString()))
            }
        }
    }
}
