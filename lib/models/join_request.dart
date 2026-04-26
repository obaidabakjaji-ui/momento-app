import 'package:cloud_firestore/cloud_firestore.dart';

class JoinRequest {
  final String id;
  final String roomId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final DateTime createdAt;

  JoinRequest({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.createdAt,
  });

  factory JoinRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JoinRequest(
      id: doc.id,
      roomId: data['roomId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'roomId': roomId,
        'userId': userId,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
