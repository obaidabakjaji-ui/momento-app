import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/room_service.dart';
import '../../models/app_user.dart';
import '../../models/room.dart';
import '../../models/room_post.dart';
import '../../theme.dart';
import '../../widgets/like_button.dart';
import '../../widgets/post_actions_sheet.dart';
import '../../widgets/shimmer_placeholder.dart';
import '../../widgets/error_view.dart';
import '../../widgets/photo_viewer.dart';
import 'room_settings_screen.dart';

class RoomDetailScreen extends StatefulWidget {
  final String roomId;
  const RoomDetailScreen({super.key, required this.roomId});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  final _auth = AuthService();
  final _firestore = FirestoreService();
  final _rooms = RoomService();
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser!.uid;

    return StreamBuilder<Room?>(
      stream: _rooms.watchRoom(widget.roomId),
      builder: (context, roomSnap) {
        final room = roomSnap.data;
        if (room == null) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final isAdmin = room.isAdmin(uid);
        return Scaffold(
          appBar: AppBar(
            title: Text(room.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: isAdmin ? 'Room settings' : 'Members',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RoomSettingsScreen(roomId: room.id),
                  ),
                ),
              ),
            ],
          ),
          body: StreamBuilder<AppUser?>(
            stream: _firestore.watchUser(uid),
            builder: (context, userSnap) {
              final blocked =
                  userSnap.data?.blockedUserIds.toSet() ?? <String>{};
              return StreamBuilder<List<RoomPost>>(
                stream: _rooms.watchRoomPosts(room.id),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return const ErrorView(message: "Couldn't load posts.");
                  }
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const ShimmerList(itemHeight: 120);
                  }
                  final posts = (snap.data ?? [])
                      .where((p) => !blocked.contains(p.senderId))
                      .toList();
                  if (posts.isEmpty) return _buildEmptyState();
                  return PageView.builder(
                    controller: _pageController,
                    itemCount: posts.length,
                    itemBuilder: (_, i) =>
                        _PostCard(post: posts[i], currentUserId: uid),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_camera_outlined,
              size: 80,
              color: MomentoTheme.deepPlum.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No momentos in this room yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: MomentoTheme.deepPlum,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Take a photo from the camera to be the first.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MomentoTheme.deepPlum.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final RoomPost post;
  final String currentUserId;
  const _PostCard({required this.post, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final remaining = post.expiresAt.difference(DateTime.now());
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              post.senderName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: MomentoTheme.deepPlum,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onLongPress: () => showPostActionsSheet(
                context: context,
                post: post,
                currentUserId: currentUserId,
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PhotoViewer(
                    imageUrl: post.imageUrl,
                    heroTag: 'roompost_${post.id}',
                    caption: post.caption,
                  ),
                ),
              ),
              child: Hero(
                tag: 'roompost_${post.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: CachedNetworkImage(
                    imageUrl: post.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    fadeInDuration: const Duration(milliseconds: 350),
                    placeholder: (_, __) => Container(
                      color: MomentoTheme.softPink.withValues(alpha: 0.3),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: MomentoTheme.softPink.withValues(alpha: 0.3),
                      child: const Icon(Icons.broken_image, size: 48),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (post.caption != null && post.caption!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                post.caption!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: MomentoTheme.deepPlum.withValues(alpha: 0.85),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LikeButton(post: post, currentUserId: currentUserId),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: MomentoTheme.coral.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 16, color: MomentoTheme.coral),
                    const SizedBox(width: 6),
                    Text(
                      remaining.isNegative
                          ? 'Expired'
                          : '${hours}h ${minutes}m remaining',
                      style: const TextStyle(
                        color: MomentoTheme.coral,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
