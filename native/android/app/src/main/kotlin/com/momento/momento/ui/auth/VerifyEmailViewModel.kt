package com.momento.momento.ui.auth

import androidx.annotation.StringRes
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.momento.momento.R
import com.momento.momento.data.AuthRepository
import com.momento.momento.data.EmailCodeException
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/** Error/info text is either the server's own message (which the cooldown
 *  regex has already been run against) or a local string resource. */
sealed interface VerifyMessage {
    data class Raw(val text: String) : VerifyMessage
    data class Res(@StringRes val id: Int) : VerifyMessage
}

class VerifyEmailViewModel : ViewModel() {

    data class UiState(
        val code: String = "",
        val verifying: Boolean = false,
        val error: VerifyMessage? = null,
        val info: VerifyMessage? = null,
        val resendSecondsLeft: Int = 0,
        /** Bumped when the screen should clear+refocus the code field. */
        val refocusTick: Int = 0,
    )

    private val _state = MutableStateFlow(UiState())
    val state: StateFlow<UiState> = _state.asStateFlow()

    val email: String get() = AuthRepository.currentUser?.email ?: "—"

    private var cooldownJob: Job? = null

    init {
        // Fire a code automatically the first time the user lands here — works
        // for fresh sign-ups AND existing-but-unverified sign-ins. The screen
        // obtains this ViewModel keyed per auth uid (VerifyEmailScreen), so
        // this runs once per account/session: it survives rotation, but a
        // different unverified account gets a fresh instance (fresh auto-sent
        // code, no stale error/cooldown/verifying state).
        viewModelScope.launch { autoRequestCode() }
    }

    fun onCodeChange(raw: String) {
        // The Flutter field is disabled while verifying; ignore input here.
        if (_state.value.verifying) return
        val digits = raw.filter { it.isDigit() }.take(6)
        _state.update { it.copy(code = digits) }
        if (digits.length == 6) submit(digits)
    }

    fun signOut() = AuthRepository.signOut()

    private suspend fun autoRequestCode() {
        try {
            AuthRepository.requestEmailCode()
            _state.update { it.copy(info = VerifyMessage.Res(R.string.verify_code_sent)) }
            startResendCooldown(30)
        } catch (e: EmailCodeException) {
            // The server's own 30s cooldown protects against spam if the user
            // kills the app and comes back too fast — swallow that error and
            // just keep the countdown running locally.
            when (e.code) {
                "cooldown" -> startResendCooldown(parseCooldownSeconds(e.message) ?: 30)
                "already-verified" -> reloadAsVerified()
                else -> _state.update { it.copy(error = VerifyMessage.Raw(e.message.orEmpty())) }
            }
        } catch (e: CancellationException) {
            throw e
        } catch (_: Exception) {
            _state.update { it.copy(error = VerifyMessage.Res(R.string.verify_code_failed)) }
        }
    }

    fun resend() {
        _state.update { it.copy(error = null, info = null) }
        viewModelScope.launch {
            try {
                AuthRepository.requestEmailCode()
                _state.update { it.copy(info = VerifyMessage.Res(R.string.verify_code_sent_new)) }
                startResendCooldown(30)
            } catch (e: EmailCodeException) {
                if (e.code == "already-verified") {
                    reloadAsVerified()
                    return@launch
                }
                _state.update { it.copy(error = VerifyMessage.Raw(e.message.orEmpty())) }
                // If the server told us a cooldown is in effect, respect it.
                parseCooldownSeconds(e.message)?.let { startResendCooldown(it) }
            } catch (e: CancellationException) {
                throw e
            } catch (_: Exception) {
                _state.update { it.copy(error = VerifyMessage.Res(R.string.verify_code_failed_new)) }
            }
        }
    }

    private fun submit(code: String) {
        if (_state.value.verifying) return
        _state.update { it.copy(verifying = true, error = null, info = null) }
        viewModelScope.launch {
            try {
                AuthRepository.verifyEmailCode(code)
                // Success: the repository reloads the user, authFlow re-emits
                // (B1) and AuthGate routes away. Keep `verifying` true so the
                // field stays disabled for the final frame(s).
            } catch (e: EmailCodeException) {
                if (e.code == "already-verified") {
                    reloadAsVerified()
                    return@launch
                }
                _state.update {
                    it.copy(
                        verifying = false,
                        error = VerifyMessage.Raw(e.message.orEmpty()),
                        code = "",
                        refocusTick = it.refocusTick + 1,
                    )
                }
            } catch (e: CancellationException) {
                throw e
            } catch (_: Exception) {
                _state.update {
                    it.copy(verifying = false, error = VerifyMessage.Res(R.string.verify_something_wrong))
                }
            }
        }
    }

    /** "already-verified" is success in disguise: reload so authFlow re-emits
     *  with emailVerified=true and the gate leaves this screen. */
    private suspend fun reloadAsVerified() {
        try {
            AuthRepository.reloadCurrentUser()
        } catch (e: CancellationException) {
            throw e
        } catch (_: Exception) {
            // Reload failing here is non-fatal — the next app start re-checks.
        }
        _state.update { it.copy(verifying = false) }
    }

    private fun startResendCooldown(seconds: Int) {
        cooldownJob?.cancel()
        cooldownJob = viewModelScope.launch {
            var left = seconds
            while (left > 0) {
                _state.update { it.copy(resendSecondsLeft = left) }
                delay(1_000)
                left--
            }
            _state.update { it.copy(resendSecondsLeft = 0) }
        }
    }

    /** Server cooldown messages embed the wait, e.g. "try again in 23s". */
    private fun parseCooldownSeconds(message: String?): Int? =
        message?.let { Regex("""(\d+)s""").find(it)?.groupValues?.get(1)?.toIntOrNull() }
}
