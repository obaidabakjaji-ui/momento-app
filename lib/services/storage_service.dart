import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

/// Result of [StorageService.uploadMomentoVideo].
class VideoUploadResult {
  final String videoUrl;
  final String posterUrl;
  const VideoUploadResult({required this.videoUrl, required this.posterUrl});
}

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadMomentoImage({
    required String senderId,
    required File imageFile,
  }) async {
    final fileName = '${const Uuid().v4()}.jpg';
    final ref = _storage.ref('momentos/$senderId/$fileName');

    final uploadTask = ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final snapshot = await uploadTask;
    return snapshot.ref.getDownloadURL();
  }

  /// Upload a video clip and its pre-extracted poster frame in parallel.
  /// Stored alongside photos under `momentos/{senderId}/` so storage rules
  /// stay simple (one rule covers everything the user uploads).
  Future<VideoUploadResult> uploadMomentoVideo({
    required String senderId,
    required File videoFile,
    required File posterFile,
  }) async {
    final id = const Uuid().v4();
    final videoRef = _storage.ref('momentos/$senderId/$id.mp4');
    final posterRef = _storage.ref('momentos/$senderId/$id-poster.jpg');

    final results = await Future.wait([
      videoRef
          .putFile(videoFile, SettableMetadata(contentType: 'video/mp4'))
          .then((s) => s.ref.getDownloadURL()),
      posterRef
          .putFile(posterFile, SettableMetadata(contentType: 'image/jpeg'))
          .then((s) => s.ref.getDownloadURL()),
    ]);

    return VideoUploadResult(videoUrl: results[0], posterUrl: results[1]);
  }

  /// Upload a room photo. Stored under the uploader's path so storage rules
  /// stay simple (only the uploader can write to their own folder).
  Future<String> uploadRoomPhoto({
    required String uploaderId,
    required File imageFile,
  }) async {
    final fileName = '${const Uuid().v4()}.jpg';
    final ref = _storage.ref('room_photos/$uploaderId/$fileName');

    final uploadTask = ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final snapshot = await uploadTask;
    return snapshot.ref.getDownloadURL();
  }
}
