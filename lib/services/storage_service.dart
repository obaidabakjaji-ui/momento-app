import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

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
