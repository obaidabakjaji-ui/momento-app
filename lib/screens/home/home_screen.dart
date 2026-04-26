import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/room_service.dart';
import '../../services/widget_service.dart';
import '../../models/app_user.dart';
import '../../models/room.dart';
import '../../models/room_post.dart';
import '../../theme.dart';
import '../camera/camera_screen.dart';
import '../rooms/rooms_screen.dart';
import '../account/account_screen.dart';
import '../../widgets/like_button.dart';
import '../../widgets/post_actions_sheet.dart';
import '../../widgets/shimmer_placeholder.dart';
import '../../widgets/error_view.dart';
import '../../widgets/photo_viewer.dart';
import '../../widgets/offline_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      _FeedTab(),
      RoomsScreen(),
      AccountScreen(),
    ];

    return Scaffold(
      body: pages[_tabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.meeting_room_outlined),
            selectedIcon: Icon(Icons.meeting_room),
            label: 'Rooms',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
      floatingActionButton: _tabIndex == 0
          ? FloatingActionButton.extended(
              backgroundColor: MomentoTheme.coral,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.camera_alt),
              label: const Text('New Momento'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CameraScreen()),
              ),
            )
          : null,
    );
  }
}

/// Emit a snapshot whenever any input stream emits, carrying the latest value
/// from every input. Waits until each stream has emitted at least once.
Stream<List<List<T>>> _combineLatest<T>(List<Stream<List<T>>> streams) {
  if (streams.isEmpty) return Stream.value(const []);
  final controller = StreamController<List<List<T>>>.broadcast();
  final latest = List<List<T>?>.filled(streams.length, null);
  final subs = <StreamSubscription>[];
  var seen = 0;

  for (var i = 0; i < streams.length; i++) {
    final idx = i;
    subs.add(streams[i].listen(
      (value) {
        if (latest[idx] == null) seen++;
        latest[idx] = value;
        if (seen == streams.length) {
          controller.add(latest.map((v) => v ?? <T>[]).toList());
        }
      },
      onError: controller.addError,
    ));
  }

  controller.onCancel = () async {
    for (final s in subs) {
      await s.cancel();
    }
  };
  return controller.stream;
}

/// The merged feed of posts from all rooms the user has marked as "active",
/// with favorites bubbled to the front of the rotation.
class _FeedTab extends StatefulWidget {
  const _FeedTab();

  @override
  State<_FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<_FeedTab> {
  final _auth = AuthService();
  final _firestore = FirestoreService();
  final _rooms = RoomService();
  final _widget = WidgetService();
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser!.uid;

    return StreamBuilder<AppUser?>(
      stream: _firestore.watchUser(uid),
      builder: (context, userSnap) {
        if (userSnap.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Momento')),
            body: const ErrorView(message: "Couldn't load your account."),
          );
        }
        final user = userSnap.data;
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Momento')),
            body: const ShimmerList(itemHeight: 120),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Momento',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: Column(
            children: [
              const OfflineBanner(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await Future.delayed(const Duration(milliseconds: 400));
                    if (mounted) setState(() {});
                  },
                  color: MomentoTheme.coral,
                  child: _buildBody(user),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(AppUser user) {
    if (user.roomIds.isEmpty) return _buildNoRoomsState();

    // Source rooms = active rooms if any, otherwise all rooms
    final sourceRoomIds = user.activeRoomIds.isNotEmpty
        ? user.activeRoomIds
        : user.roomIds;

    return FutureBuilder<List<Room>>(
      future: _rooms.getRooms(sourceRoomIds),
      builder: (context, roomsSnap) {
        if (roomsSnap.hasError) {
          return const ErrorView(message: "Couldn't load your rooms.");
        }
        if (!roomsSnap.hasData) {
          return const ShimmerList(itemHeight: 120);
        }
        final rooms = roomsSnap.data!;
        if (rooms.isEmpty) return _buildEmptyFeed();

        // Combine post streams from each source room into one merged feed
        final streams = rooms.map((r) => _rooms.watchRoomPosts(r.id)).toList();
        final combined = _combineLatest(streams);
        final roomMap = {for (final r in rooms) r.id: r};
        final favorites = user.favoriteRoomIds.toSet();

        return StreamBuilder<List<List<RoomPost>>>(
          stream: combined,
          builder: (context, snap) {
            if (snap.hasError) {
              return const ErrorView(message: "Couldn't load posts.");
            }
            if (!snap.hasData) {
              return const ShimmerList(itemHeight: 120);
            }
            final blocked = user.blockedUserIds.toSet();
            final all = snap.data!
                .expand((list) => list)
                .where((p) => !blocked.contains(p.senderId))
                .toList();
            // Sort: favorites first, then by createdAt desc
            all.sort((a, b) {
              final af = favorites.contains(a.roomId) ? 0 : 1;
              final bf = favorites.contains(b.roomId) ? 0 : 1;
              if (af != bf) return af - bf;
              return b.createdAt.compareTo(a.createdAt);
            });

            _pushToWidget(all, roomMap, favorites);

            if (all.isEmpty) return _buildEmptyFeed();

            return PageView.builder(
              controller: _pageController,
              itemCount: all.length,
              itemBuilder: (_, i) => _PostCard(
                post: all[i],
                roomName: roomMap[all[i].roomId]?.name ?? '',
                isFavorite: favorites.contains(all[i].roomId),
                currentUserId: user.uid,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pushToWidget(
    List<RoomPost> posts,
    Map<String, Room> roomMap,
    Set<String> favorites,
  ) async {
    if (posts.isEmpty) {
      await _widget.clearWidget();
      return;
    }
    final widgetPosts = posts.take(20).map((p) {
      return WidgetPost(
        imageUrl: p.imageUrl,
        senderName: p.senderName,
        roomName: roomMap[p.roomId]?.name ?? '',
        isFavoriteRoom: favorites.contains(p.roomId),
        caption: p.caption,
        likeCount: p.likeCount,
        isVideo: p.isVideo,
        createdAtMs: p.createdAt.millisecondsSinceEpoch,
      );
    }).toList();
    await _widget.updateWidgetWithPosts(widgetPosts);
  }

  Widget _buildNoRoomsState() {
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
              'Open the Rooms tab to create or join one.',
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

  Widget _buildEmptyFeed() {
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
            const SizedBox(height: 24),
            Text(
              'No momentos yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: MomentoTheme.deepPlum,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Take a photo and share it with your rooms!',
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
  final String roomName;
  final bool isFavorite;
  final String currentUserId;

  const _PostCard({
    required this.post,
    required this.roomName,
    required this.isFavorite,
    required this.currentUserId,
  });

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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isFavorite) ...[
                  const Icon(Icons.star,
                      color: MomentoTheme.warmOrange, size: 16),
                  const SizedBox(width: 4),
                ],
                Text(
                  '${post.senderName} · $roomName',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: MomentoTheme.deepPlum,
                  ),
                ),
              ],
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
                    heroTag: 'post_${post.id}',
                    caption: post.caption,
                    videoUrl: post.videoUrl,
                  ),
                ),
              ),
              child: Hero(
                tag: 'post_${post.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: post.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        fadeInDuration: const Duration(milliseconds: 350),
                        placeholder: (_, __) => Container(
                          color: MomentoTheme.softPink.withValues(alpha: 0.3),
                          child:
                              const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: MomentoTheme.softPink.withValues(alpha: 0.3),
                          child: const Icon(Icons.broken_image, size: 48),
                        ),
                      ),
                      if (post.isVideo)
                        const Positioned.fill(
                          child: IgnorePointer(child: _VideoPlayBadge()),
                        ),
                    ],
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

/// Centered translucent play button shown over the poster of a video post.
class _VideoPlayBadge extends StatelessWidget {
  const _VideoPlayBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.play_arrow_rounded,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }
}
