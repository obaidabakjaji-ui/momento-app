import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final List<String> linkedUserIds;
  final String? inviteCode;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.linkedUserIds = const [],
    this.inviteCode,
    required this.createdAt,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // Support both old single linkedUserId and new linkedUserIds list
    List<String> linked = [];
    if (data['linkedUserIds'] != null) {
      linked = List<String>.from(data['linkedUserIds']);
    } else if (data['linkedUserId'] != null) {
      linked = [data['linkedUserId'] as String];
    }
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      linkedUserIds: linked,
      inviteCode: data['inviteCode'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'linkedUserIds': linkedUserIds,
        'inviteCode': inviteCode,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  bool get isLinked => linkedUserIds.isNotEmpty;
}
