import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final List<String> roomIds;
  final List<String> activeRoomIds;
  final List<String> favoriteRoomIds;
  final List<String> blockedUserIds;
  final bool hasSeenOnboarding;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastPostDate;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.roomIds = const [],
    this.activeRoomIds = const [],
    this.favoriteRoomIds = const [],
    this.blockedUserIds = const [],
    this.hasSeenOnboarding = false,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastPostDate,
    required this.createdAt,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      roomIds: List<String>.from(data['roomIds'] ?? const []),
      activeRoomIds: List<String>.from(data['activeRoomIds'] ?? const []),
      favoriteRoomIds: List<String>.from(data['favoriteRoomIds'] ?? const []),
      blockedUserIds: List<String>.from(data['blockedUserIds'] ?? const []),
      hasSeenOnboarding: data['hasSeenOnboarding'] ?? false,
      currentStreak: (data['currentStreak'] ?? 0) as int,
      longestStreak: (data['longestStreak'] ?? 0) as int,
      lastPostDate: (data['lastPostDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'roomIds': roomIds,
        'activeRoomIds': activeRoomIds,
        'favoriteRoomIds': favoriteRoomIds,
        'blockedUserIds': blockedUserIds,
        'hasSeenOnboarding': hasSeenOnboarding,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastPostDate':
            lastPostDate == null ? null : Timestamp.fromDate(lastPostDate!),
        'createdAt': Timestamp.fromDate(createdAt),
      };

  bool get hasRooms => roomIds.isNotEmpty;
  bool hasBlocked(String uid) => blockedUserIds.contains(uid);
}
