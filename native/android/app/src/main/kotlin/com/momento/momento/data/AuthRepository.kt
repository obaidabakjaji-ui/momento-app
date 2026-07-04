package com.momento.momento.data

import android.content.Context
import androidx.credentials.CredentialManager
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import androidx.credentials.exceptions.GetCredentialCancellationException
import androidx.credentials.exceptions.GetCredentialException
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseAuthException
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.auth.GoogleAuthProvider
import com.google.firebase.auth.UserProfileChangeRequest
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.functions.FirebaseFunctions
import com.google.firebase.functions.FirebaseFunctionsException
import com.momento.momento.data.model.AppUser
import java.util.Date
import java.util.concurrent.atomic.AtomicLong
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await

/**
 * Thrown by [AuthRepository.requestEmailCode] / [AuthRepository.verifyEmailCode]
 * for cases the UI should surface specially (e.g. cooldown, wrong code).
 *
 * [code] is one of: `cooldown`, `wrong-code`, `expired`, `attempts-exhausted`,
 * `no-pending`, `already-verified`, `unknown`.
 */
class EmailCodeException(val code: String, message: String) : Exception(message)

/**
 * Immutable snapshot of the signed-in user for the auth gate.
 *
 * [generation] increments on every emission. WHY: FirebaseUser is a MUTABLE
 * object — after reload() it is the SAME instance with flipped fields, so
 * Compose state equality / distinctUntilChanged would swallow the re-emission
 * and the auth gate would never leave the verify screen. A fresh snapshot with
 * a bumped generation defeats that.
 */
data class AuthUserSnapshot(
    val uid: String,
    val email: String?,
    val displayName: String?,
    val emailVerified: Boolean,
    val generation: Long,
)

object AuthRepository {

    private val auth: FirebaseAuth get() = FirebaseAuth.getInstance()
    private val db: FirebaseFirestore get() = FirebaseFirestore.getInstance()

    // The email-code callables are deployed in us-central1 only — the default
    // instance would call the wrong region and 404.
    private val functions: FirebaseFunctions
        get() = FirebaseFunctions.getInstance("us-central1")

    // Firebase auto-generated Web OAuth client ID. Required as serverClientId
    // by Credential Manager / Google ID sign-in. Bound to project
    // momento-app-64950. (Same value the Flutter google_sign_in setup uses.)
    private const val GOOGLE_SERVER_CLIENT_ID =
        "149110523075-d3dkatbv890ibpm6vtb6rd3p470j3bbm.apps.googleusercontent.com"

    // Explicit re-emit trigger for authFlow (contract B1): Android's
    // AuthStateListener is the authStateChanges() equivalent — it does NOT
    // fire after user.reload(), so without this the gate would never leave
    // VerifyEmailScreen after a successful code entry.
    private val reloadTrigger = MutableSharedFlow<Unit>(extraBufferCapacity = 1)

    val currentUser: FirebaseUser? get() = auth.currentUser

    // userChanges()-style stream (B1): AuthStateListener (sign-in/out) merged
    // with reloadTrigger (property changes after reload()).
    val authFlow: Flow<AuthUserSnapshot?> = callbackFlow {
        val generation = AtomicLong(0)

        fun emitCurrent(user: FirebaseUser?) {
            val gen = generation.incrementAndGet()
            trySend(
                user?.let {
                    AuthUserSnapshot(
                        uid = it.uid,
                        email = it.email,
                        displayName = it.displayName,
                        emailVerified = it.isEmailVerified,
                        generation = gen,
                    )
                }
            )
        }

        // Fires immediately with the current state on registration — the gate
        // gets its first emission without any extra plumbing.
        val listener = FirebaseAuth.AuthStateListener { firebaseAuth ->
            emitCurrent(firebaseAuth.currentUser)
        }
        auth.addAuthStateListener(listener)

        // Child of the producer scope — cancelled automatically on close.
        launch {
            reloadTrigger.collect { emitCurrent(auth.currentUser) }
        }

        awaitClose { auth.removeAuthStateListener(listener) }
    }

    suspend fun signUpWithEmail(name: String, email: String, password: String) {
        val user = try {
            auth.createUserWithEmailAndPassword(email, password).await().user
        } catch (e: FirebaseAuthException) {
            throw friendlyAuthException(e)
        } ?: throw Exception("Something went wrong. Try again.")

        user.updateProfile(
            UserProfileChangeRequest.Builder().setDisplayName(name).build()
        ).await()
        createUserDoc(user, name)
        // The verification code is requested by VerifyEmailScreen on entry —
        // that way both the sign-up path and the existing-but-unverified
        // sign-in path get a code sent automatically without duplicating
        // logic here. (Same rationale as the Dart auth_service.)
    }

    suspend fun signInWithEmail(email: String, password: String) {
        try {
            auth.signInWithEmailAndPassword(email, password).await()
        } catch (e: FirebaseAuthException) {
            throw friendlyAuthException(e)
        }
    }

    // Needs an Activity context — Credential Manager shows the account picker.
    suspend fun signInWithGoogle(context: Context) {
        val googleIdOption = GetGoogleIdOption.Builder()
            .setServerClientId(GOOGLE_SERVER_CLIENT_ID)
            .setFilterByAuthorizedAccounts(false)
            .build()
        val request = GetCredentialRequest.Builder()
            .addCredentialOption(googleIdOption)
            .build()

        val response = try {
            CredentialManager.create(context).getCredential(context, request)
        } catch (e: GetCredentialCancellationException) {
            throw Exception("Sign-in cancelled.")
        } catch (e: GetCredentialException) {
            throw Exception(e.message ?: "Google sign-in failed. Try again.")
        }

        val credential = response.credential
        if (credential !is CustomCredential ||
            credential.type != GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL
        ) {
            throw Exception("Google sign-in failed. Try again.")
        }
        val idToken = GoogleIdTokenCredential.createFrom(credential.data).idToken

        val user = try {
            auth.signInWithCredential(GoogleAuthProvider.getCredential(idToken, null))
                .await().user
        } catch (e: FirebaseAuthException) {
            throw friendlyAuthException(e)
        } ?: throw Exception("Google sign-in failed. Try again.")

        // Create user doc if first time (mirrors the Dart auth_service).
        val doc = db.collection("users").document(user.uid).get().await()
        if (!doc.exists()) {
            createUserDoc(user, user.displayName ?: "User")
        }
    }

    suspend fun sendPasswordResetEmail(email: String) {
        try {
            auth.sendPasswordResetEmail(email).await()
        } catch (e: FirebaseAuthException) {
            throw friendlyAuthException(e)
        }
    }

    /**
     * Ask the backend to generate a fresh 6-digit code and email it to the
     * signed-in user. Throws [EmailCodeException] for cooldown / already
     * verified cases.
     */
    suspend fun requestEmailCode() {
        if (auth.currentUser == null) {
            throw EmailCodeException("unauthenticated", "Sign in first.")
        }
        try {
            functions.getHttpsCallable("requestEmailCode").call().await()
        } catch (e: FirebaseFunctionsException) {
            throw mapFunctionsException(e)
        }
    }

    /**
     * Submit a 6-digit code. On success Firebase Auth's `emailVerified` flag
     * flips to true (refreshed + re-emitted via [reloadCurrentUser]).
     */
    suspend fun verifyEmailCode(code: String) {
        if (auth.currentUser == null) {
            throw EmailCodeException("unauthenticated", "Sign in first.")
        }
        try {
            functions.getHttpsCallable("verifyEmailCode")
                .call(mapOf("code" to code))
                .await()
        } catch (e: FirebaseFunctionsException) {
            throw mapFunctionsException(e)
        }
        // Refresh local auth state so emailVerified flips true immediately and
        // authFlow re-emits (B1) — the gate routes onward without a restart.
        reloadCurrentUser()
    }

    // user.reload() mutates the existing FirebaseUser in place; no listener
    // fires for it, so we poke the reload trigger to force a fresh
    // AuthUserSnapshot emission (B1).
    suspend fun reloadCurrentUser() {
        auth.currentUser?.reload()?.await()
        reloadTrigger.emit(Unit)
    }

    fun signOut() {
        // No Credential Manager state to clear: clearCredentialState() needs a
        // Context and only affects passive credential hints — with
        // filterByAuthorizedAccounts=false the picker always shows every
        // account anyway. Firebase sign-out alone matches the Dart behavior
        // the gate depends on (AuthStateListener fires with null).
        auth.signOut()
    }

    private suspend fun createUserDoc(user: FirebaseUser, name: String) {
        val appUser = AppUser(
            uid = user.uid,
            email = user.email ?: "",
            displayName = name,
            photoUrl = user.photoUrl?.toString(),
            createdAt = Date(),
        )
        db.collection("users").document(user.uid).set(appUser.toMap()).await()
    }

    // Same mapping table as the Dart auth_service (B13). The cooldown case
    // deliberately keeps the server's original message — the verify screen
    // parses the remaining seconds out of it with regex (\d+)s.
    private fun mapFunctionsException(e: FirebaseFunctionsException): EmailCodeException {
        return when (e.code) {
            FirebaseFunctionsException.Code.RESOURCE_EXHAUSTED ->
                // Server uses this for both "wait Ns" and "too many attempts".
                if ((e.message ?: "").lowercase().contains("attempts")) {
                    EmailCodeException(
                        "attempts-exhausted",
                        "Too many wrong attempts. Request a new code.",
                    )
                } else {
                    EmailCodeException("cooldown", e.message ?: "Try again soon.")
                }
            FirebaseFunctionsException.Code.DEADLINE_EXCEEDED ->
                EmailCodeException("expired", "That code expired. Tap resend for a new one.")
            FirebaseFunctionsException.Code.PERMISSION_DENIED ->
                EmailCodeException("wrong-code", "Wrong code. Try again.")
            FirebaseFunctionsException.Code.FAILED_PRECONDITION ->
                EmailCodeException("no-pending", "No active code. Tap resend to get a new one.")
            else ->
                EmailCodeException("unknown", e.message ?: "Something went wrong.")
        }
    }

    // The Flutter auth screen surfaces the FirebaseAuthException's own text in
    // a snackbar; Android's FirebaseAuthException carries the same
    // backend-provided message, so we rethrow it as a plain Exception whose
    // message the UI shows directly. Fallbacks cover the rare null-message
    // codes.
    private fun friendlyAuthException(e: FirebaseAuthException): Exception {
        val fallback = when (e.errorCode) {
            "ERROR_INVALID_EMAIL" -> "The email address is badly formatted."
            "ERROR_EMAIL_ALREADY_IN_USE" -> "An account already exists with that email."
            "ERROR_WEAK_PASSWORD" -> "Password should be at least 6 characters."
            "ERROR_USER_NOT_FOUND",
            "ERROR_WRONG_PASSWORD",
            "ERROR_INVALID_CREDENTIAL" -> "Incorrect email or password."
            "ERROR_USER_DISABLED" -> "This account has been disabled."
            "ERROR_TOO_MANY_REQUESTS" -> "Too many attempts. Try again later."
            "ERROR_NETWORK_REQUEST_FAILED" -> "Network error. Check your connection."
            else -> "Something went wrong. Try again."
        }
        return Exception(e.message ?: fallback)
    }
}
