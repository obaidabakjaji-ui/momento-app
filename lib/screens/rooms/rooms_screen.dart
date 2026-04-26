import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/room_service.dart';
import '../../models/app_user.dart';
import '../../models/room.dart';
import '../../theme.dart';
import '../../widgets/shimmer_placeholder.dart';
import '../../widgets/error_view.dart';
import 'create_room_screen.dart';
import 'join_room_screen.dart';
import 'room_detail_screen.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  final _auth = AuthService();
  final _firestore = FirestoreService();
  final _rooms = RoomService();

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rooms',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Join by code',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JoinRoomScreen()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<AppUser?>(
        stream: _firestore.watchUser(uid),
        builder: (context, userSnap) {
          if (userSnap.hasError) {
            return const ErrorView(message: "Couldn't load your account.");
          }
          final user = userSnap.data;
          if (user == null) {
            return const ShimmerList(itemHeight: 84);
          }
          if (user.roomIds.isEmpty) {
            return _buildEmptyState(context);
          }
          return RefreshIndicator(
            onRefresh: () async {
              // Force a re-fetch of the room list by rebuilding.
              await Future.delayed(const Duration(milliseconds: 400));
              if (mounted) setState(() {});
            },
            color: MomentoTheme.coral,
            child: FutureBuilder<List<Room>>(
              future: _rooms.getRooms(user.roomIds),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const ErrorView(message: "Couldn't load your rooms.");
                }
                if (!snap.hasData) {
                  return const ShimmerList(itemHeight: 84);
                }
                final rooms = List<Room>.from(snap.data!)
                  ..sort((a, b) {
                    // Favorites first, then newest
                    final af = user.favoriteRoomIds.contains(a.id) ? 0 : 1;
                    final bf = user.favoriteRoomIds.contains(b.id) ? 0 : 1;
                    if (af != bf) return af - bf;
                    return b.createdAt.compareTo(a.createdAt);
                  });
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: rooms.length,
                  itemBuilder: (context, i) {
                    final room = rooms[i];
                    return _RoomTile(
                      room: room,
                      isFavorite: user.favoriteRoomIds.contains(room.id),
                      isActive: user.activeRoomIds.contains(room.id),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RoomDetailScreen(roomId: room.id),
                        ),
                      ),
                      onToggleFavorite: () => _rooms.toggleFavoriteRoom(
                        userId: uid,
                        roomId: room.id,
                        favorite: !user.favoriteRoomIds.contains(room.id),
                      ),
                      onToggleActive: () {
                        final newList = List<String>.from(user.activeRoomIds);
                        if (newList.contains(room.id)) {
                          newList.remove(room.id);
                        } else {
                          newList.add(room.id);
                        }
                        _rooms.setActiveRooms(uid, newList);
                      },
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: MomentoTheme.coral,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Room'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateRoomScreen()),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: MomentoTheme.softPink.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.meeting_room_outlined,
                size: 50,
                color: MomentoTheme.coral.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No rooms yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: MomentoTheme.deepPlum,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a new room or join one with a code to start sharing momentos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MomentoTheme.deepPlum.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const JoinRoomScreen()),
                  ),
                  icon: const Icon(Icons.search),
                  label: const Text('Join Room'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateRoomScreen()),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Room'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  final Room room;
  final bool isFavorite;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onToggleActive;

  const _RoomTile({
    required this.room,
    required this.isFavorite,
    required this.isActive,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: MomentoTheme.softPink,
                backgroundImage: room.photoUrl != null
                    ? NetworkImage(room.photoUrl!)
                    : null,
                child: room.photoUrl == null
                    ? Text(
                        room.name.isNotEmpty ? room.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: MomentoTheme.coral,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            room.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: MomentoTheme.deepPlum,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          room.visibility == RoomVisibility.public
                              ? Icons.public
                              : Icons.lock_outline,
                          size: 14,
                          color: MomentoTheme.deepPlum.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${room.memberCount} member${room.memberCount == 1 ? '' : 's'} · Code ${room.code}',
                      style: TextStyle(
                        fontSize: 12,
                        color: MomentoTheme.deepPlum.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: isFavorite ? 'Unfavorite' : 'Favorite',
                icon: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: isFavorite
                      ? MomentoTheme.warmOrange
                      : MomentoTheme.deepPlum.withValues(alpha: 0.4),
                ),
                onPressed: onToggleFavorite,
              ),
              IconButton(
                tooltip: isActive ? 'Deactivate' : 'Activate',
                icon: Icon(
                  isActive
                      ? Icons.notifications_active
                      : Icons.notifications_off_outlined,
                  color: isActive
                      ? MomentoTheme.coral
                      : MomentoTheme.deepPlum.withValues(alpha: 0.4),
                ),
                onPressed: onToggleActive,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
