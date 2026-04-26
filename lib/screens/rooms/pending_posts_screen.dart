import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../services/room_service.dart';
import '../../models/room_post.dart';
import '../../theme.dart';

/// Admin-only screen listing posts awaiting approval in a single room.
class PendingPostsScreen extends StatelessWidget {
  final String roomId;
  final String roomName;

  const PendingPostsScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  Widget build(BuildContext context) {
    final service = RoomService();
    return Scaffold(
      appBar: AppBar(title: Text('Pending — $roomName')),
      body: StreamBuilder<List<RoomPost>>(
        stream: service.watchPendingPosts(roomId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snap.data ?? [];
          if (posts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Nothing waiting for approval.',
                  style: TextStyle(
                    color: MomentoTheme.deepPlum.withValues(alpha: 0.6),
                  ),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (_, i) => _PendingCard(post: posts[i]),
          );
        },
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final RoomPost post;
  const _PendingCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final service = RoomService();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: MomentoTheme.softPink,
                  backgroundImage: post.senderPhotoUrl != null
                      ? NetworkImage(post.senderPhotoUrl!)
                      : null,
                  child: post.senderPhotoUrl == null
                      ? Text(
                          post.senderName.isNotEmpty
                              ? post.senderName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: MomentoTheme.coral,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  post.senderName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: MomentoTheme.deepPlum,
                  ),
                ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 1,
            child: CachedNetworkImage(
              imageUrl: post.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: MomentoTheme.softPink.withValues(alpha: 0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
          if (post.caption != null && post.caption!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                post.caption!,
                style: const TextStyle(color: MomentoTheme.deepPlum),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => service.rejectPost(
                      roomId: post.roomId,
                      postId: post.id,
                    ),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => service.approvePost(
                      roomId: post.roomId,
                      postId: post.id,
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
