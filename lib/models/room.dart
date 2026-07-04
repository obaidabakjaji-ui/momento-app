import 'dart:math' as math;
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

  /// Location lock: when enabled, posts from outside the pinned circle are
  /// auto-pended for admin approval. Admin sets the pin + radius from the
  /// room settings screen.
  final bool locationLockEnabled;
  final double? locationLat;
  final double? locationLng;
  final int? locationRadiusM;

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
    this.locationLockEnabled = false,
    this.locationLat,
    this.locationLng,
    this.locationRadiusM,
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
      locationLockEnabled: data['locationLockEnabled'] ?? false,
      locationLat: (data['locationLat'] as num?)?.toDouble(),
      locationLng: (data['locationLng'] as num?)?.toDouble(),
      locationRadiusM: (data['locationRadiusM'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
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
        'locationLockEnabled': locationLockEnabled,
        'locationLat': locationLat,
        'locationLng': locationLng,
        'locationRadiusM': locationRadiusM,
      };

  int get memberCount => memberIds.length;
  bool isMember(String uid) => memberIds.contains(uid);
  bool isAdmin(String uid) => adminIds.contains(uid);
  bool isCreator(String uid) => createdBy == uid;
  bool isTrusted(String uid) => trustedUserIds.contains(uid);

  /// True if the lock is configured (enabled + pin + radius all present).
  bool get hasActiveLocationLock =>
      locationLockEnabled &&
      locationLat != null &&
      locationLng != null &&
      locationRadiusM != null;

  /// Whether a post by [uid] from [senderLat]/[senderLng] should land
  /// `pending: true`. Admins bypass everything; trusted users bypass the
  /// approval requirement but still get geofenced. A missing GPS reading
  /// while the lock is active is treated as out-of-area (fail closed).
  bool requiresApprovalFor(
    String uid, {
    double? senderLat,
    double? senderLng,
  }) {
    if (isAdmin(uid)) return false;
    final needsApproval = requiresPostApproval && !isTrusted(uid);
    if (needsApproval) return true;
    return _isOutsideGeofence(senderLat, senderLng);
  }

  bool _isOutsideGeofence(double? senderLat, double? senderLng) {
    if (!hasActiveLocationLock) return false;
    if (senderLat == null || senderLng == null) return true;
    final dist = _haversineMeters(
      senderLat,
      senderLng,
      locationLat!,
      locationLng!,
    );
    return dist > locationRadiusM!;
  }

  static double _haversineMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusM = 6371000.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusM * c;
  }

  static double _deg2rad(double deg) => deg * (math.pi / 180);
}
