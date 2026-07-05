package com.momento.momento.data

import android.net.Uri
import com.google.firebase.storage.FirebaseStorage
import com.google.firebase.storage.StorageMetadata
import java.io.File
import java.util.UUID
import kotlinx.coroutines.tasks.await

// Firebase Storage uploads — mirror of lib/services/storage_service.dart plus
// the profile-photo path (inlined in the Dart edit_profile_screen; routed
// through the repository here per MIGRATION_MAP §1.3 "3 upload paths").
//
// All three paths are {folder}/{ownerUid}/{uuid}.jpg — files live under the
// UPLOADER's uid so storage rules stay simple: only the owner can write to
// their own folder.
object StorageRepository {

    private val storage: FirebaseStorage get() = FirebaseStorage.getInstance()

    // Post image → momentos/{senderId}/{uuid}.jpg
    suspend fun uploadMomentoImage(senderId: String, imageFile: File): String =
        upload("momentos/$senderId", imageFile)

    // Room avatar → room_photos/{uploaderId}/{uuid}.jpg. Stored under the
    // uploader's path (not the room's) — same rationale as the Dart service.
    suspend fun uploadRoomPhoto(uploaderId: String, imageFile: File): String =
        upload("room_photos/$uploaderId", imageFile)

    // Profile avatar → profile_photos/{uid}/{uuid}.jpg (EditProfileScreen).
    suspend fun uploadProfilePhoto(uid: String, imageFile: File): String =
        upload("profile_photos/$uid", imageFile)

    private suspend fun upload(folder: String, imageFile: File): String {
        val fileName = "${UUID.randomUUID()}.jpg"
        val ref = storage.reference.child("$folder/$fileName")

        val metadata = StorageMetadata.Builder()
            .setContentType("image/jpeg")
            .build()

        ref.putFile(Uri.fromFile(imageFile), metadata).await()
        return ref.downloadUrl.await().toString()
    }
}
