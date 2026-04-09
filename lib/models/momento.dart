import 'package:cloud_firestore/cloud_firestore.dart';

class Momento {
  final String id;
  final String senderId;
  final String receiverId;
  final String imageUrl;
  final DateTime createdAt;
  final DateTime expiresAt;

  Momento({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.imageUrl,
    required this.createdAt,
    required this.expiresAt,
  });

  factory Momento.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Momento(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'receiverId': receiverId,
        'imageUrl': imageUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'expiresAt': Timestamp.fromDate(expiresAt),
      };

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
