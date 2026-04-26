import 'package:cloud_firestore/cloud_firestore.dart';

/// Media kind for a [RoomPost]. Stored as a string in Firestore.
enum PostMediaType {
  photo,
  video;

  String get value => name;

  static PostMediaType fromString(String? raw) {
    switch (raw) {
      case 'video':
        return PostMediaType.video;
      case 'photo':
      default:
        return PostMediaType.photo;
    }
  }
}

/// A photo or video post inside a room. Posts expire 6 hours after creation.
/// When a user posts to multiple rooms, one RoomPost doc is written per room
/// (all sharing the same media URLs).
///
/// For video posts, [imageUrl] is the poster (extracted client-side at upload)
/// and [videoUrl] is the actual MP4. Widgets and feed thumbnails always use
/// [imageUrl]; only the in-app full-screen player loads [videoUrl].
class RoomPost {
  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String imageUrl;
  final String? videoUrl;
  final PostMediaType mediaType;
  final String? caption;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> likedBy;
  final bool pending;

  RoomPost({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.imageUrl,
    this.videoUrl,
    this.mediaType = PostMediaType.photo,
    this.caption,
    required this.createdAt,
    required this.expiresAt,
    this.likedBy = const [],
    this.pending = false,
  });

  factory RoomPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoomPost(
      id: doc.id,
      roomId: data['roomId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderPhotoUrl: data['senderPhotoUrl'],
      imageUrl: data['imageUrl'] ?? '',
      videoUrl: data['videoUrl'],
      mediaType: PostMediaType.fromString(data['mediaType'] as String?),
      caption: data['caption'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likedBy: List<String>.from(data['likedBy'] ?? const []),
      pending: data['pending'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'roomId': roomId,
        'senderId': senderId,
        'senderName': senderName,
        'senderPhotoUrl': senderPhotoUrl,
        'imageUrl': imageUrl,
        if (videoUrl != null) 'videoUrl': videoUrl,
        'mediaType': mediaType.value,
        'caption': caption,
        'createdAt': Timestamp.fromDate(createdAt),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'likedBy': likedBy,
        'pending': pending,
      };

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isVideo => mediaType == PostMediaType.video;
  int get likeCount => likedBy.length;
  bool likedByUser(String uid) => likedBy.contains(uid);
}
