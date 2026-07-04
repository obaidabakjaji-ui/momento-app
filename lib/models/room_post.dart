import 'package:cloud_firestore/cloud_firestore.dart';

/// A photo post inside a room. Posts expire 6 hours after creation.
/// When a user posts to multiple rooms, one RoomPost doc is written per room
/// (all sharing the same image URL).
class RoomPost {
  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String imageUrl;
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
        'caption': caption,
        'createdAt': Timestamp.fromDate(createdAt),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'likedBy': likedBy,
        'pending': pending,
      };

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  int get likeCount => likedBy.length;
  bool likedByUser(String uid) => likedBy.contains(uid);
}
