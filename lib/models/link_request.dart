import 'package:cloud_firestore/cloud_firestore.dart';

class LinkRequest {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;

  LinkRequest({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.status,
    required this.createdAt,
  });

  factory LinkRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LinkRequest(
      id: doc.id,
      fromUserId: data['fromUserId'] ?? '',
      fromUserName: data['fromUserName'] ?? '',
      toUserId: data['toUserId'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'fromUserId': fromUserId,
        'fromUserName': fromUserName,
        'toUserId': toUserId,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  bool get isPending => status == 'pending';
}
