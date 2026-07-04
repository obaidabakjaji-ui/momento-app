package com.momento.momento.data

import android.util.Log
import com.google.firebase.firestore.FirebaseFirestore
import com.momento.momento.data.model.AppUser
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await

// User-doc reads only — mirror of lib/services/firestore_service.dart.
// Room and post operations arrive with RoomRepository in a later phase.
object UserRepository {

    private val db: FirebaseFirestore get() = FirebaseFirestore.getInstance()

    // Live users/{uid} stream. Emits null while the doc doesn't exist — the
    // auth gate treats that as "keep spinning" (sign-up doc-creation race),
    // never as "show onboarding".
    fun watchUser(uid: String): Flow<AppUser?> = callbackFlow {
        val registration = db.collection("users").document(uid)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    // Mirror Flutter StreamBuilder semantics: a listener error
                    // (e.g. PERMISSION_DENIED racing a sign-out/token revoke)
                    // must NOT fail the flow — the gate has no .catch and
                    // would crash. Emit null so it keeps spinning until
                    // authFlow re-routes.
                    Log.w("UserRepository", "users/$uid snapshot listener error", error)
                    trySend(null)
                    return@addSnapshotListener
                }
                trySend(snapshot?.let { AppUser.fromSnapshot(it) })
            }
        awaitClose { registration.remove() }
    }

    suspend fun getUser(uid: String): AppUser? {
        val doc = db.collection("users").document(uid).get().await()
        return AppUser.fromSnapshot(doc)
    }
}
