import 'package:cloud_firestore/cloud_firestore.dart';

enum RoomVisibility { public, permission }

class Room {
  final String id;
  final String name;
  final String code;
  final RoomVisibility visibility;
  final String? photoUrl;
  final String createdBy;
  final DateTime createdAt;
  final List<String> adminIds;
  final List<String> memberIds;
  final bool requiresPostApproval;
  final List<String> trustedUserIds;

  Room({
    required this.id,
    required this.name,
    required this.code,
    required this.visibility,
    this.photoUrl,
    required this.createdBy,
    required this.createdAt,
    required this.adminIds,
    required this.memberIds,
    this.requiresPostApproval = false,
    this.trustedUserIds = const [],
  });

  factory Room.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Room(
      id: doc.id,
      name: data['name'] ?? '',
      code: data['code'] ?? '',
      visibility: (data['visibility'] ?? 'public') == 'permission'
          ? RoomVisibility.permission
          : RoomVisibility.public,
      photoUrl: data['photoUrl'],
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      adminIds: List<String>.from(data['adminIds'] ?? const []),
      memberIds: List<String>.from(data['memberIds'] ?? const []),
      requiresPostApproval: data['requiresPostApproval'] ?? false,
      trustedUserIds:
          List<String>.from(data['trustedUserIds'] ?? const []),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        // Lowercased name used for prefix-search queries (public rooms only).
        'nameLower': name.toLowerCase(),
        'code': code,
        'visibility':
            visibility == RoomVisibility.permission ? 'permission' : 'public',
        'photoUrl': photoUrl,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'adminIds': adminIds,
        'memberIds': memberIds,
        'requiresPostApproval': requiresPostApproval,
        'trustedUserIds': trustedUserIds,
      };

  int get memberCount => memberIds.length;
  bool isMember(String uid) => memberIds.contains(uid);
  bool isAdmin(String uid) => adminIds.contains(uid);
  bool isCreator(String uid) => createdBy == uid;
  bool isTrusted(String uid) => trustedUserIds.contains(uid);

  /// True if a post by [uid] must wait for admin approval.
  bool requiresApprovalFor(String uid) =>
      requiresPostApproval && !isAdmin(uid) && !isTrusted(uid);
}
