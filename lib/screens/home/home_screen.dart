import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/widget_service.dart';
import '../../models/app_user.dart';
import '../../models/momento.dart';
import '../../models/link_request.dart';
import '../../theme.dart';
import '../camera/camera_screen.dart';
import '../link/link_screen.dart';
import '../account/account_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = AuthService();
  final _firestore = FirestoreService();
  final _widget = WidgetService();
  final _pageController = PageController();

  // Cache sender names so we don't re-fetch every build
  final Map<String, String> _senderNames = {};

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
        final user = userSnap.data;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Momento',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              // Pending requests badge
              StreamBuilder<List<LinkRequest>>(
                stream: _firestore.watchPendingRequests(uid),
                builder: (context, reqSnap) {
                  final count = reqSnap.data?.length ?? 0;
                  return IconButton(
                    icon: Badge(
                      isLabelVisible: count > 0,
                      label: Text('$count'),
                      child: const Icon(Icons.person),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AccountScreen()),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.person_add),
                onPressed: () => _openLinkScreen(context),
              ),
            ],
          ),
          body: _buildBody(context, user, uid),
          floatingActionButton: user != null && user.isLinked
              ? FloatingActionButton.extended(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CameraScreen()),
                  ),
                  backgroundColor: MomentoTheme.coral,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('New Momento'),
                )
              : null,
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AppUser? user, String uid) {
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!user.isLinked) {
      return _buildNotLinkedState(context);
    }

    return StreamBuilder<List<Momento>>(
      stream: _firestore.watchMomentosForUser(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final momentos = snap.data ?? [];

        // Update widget with all momentos
        _updateWidgetData(momentos);

        if (momentos.isEmpty) {
          return _buildEmptyState();
        }

        return PageView.builder(
          controller: _pageController,
          itemCount: momentos.length,
          itemBuilder: (context, index) {
            return _MomentoCard(
              momento: momentos[index],
              senderName: _senderNames[momentos[index].senderId],
              onSenderLoaded: (name) {
                _senderNames[momentos[index].senderId] = name;
              },
              firestore: _firestore,
            );
          },
        );
      },
    );
  }

  Future<void> _updateWidgetData(List<Momento> momentos) async {
    if (momentos.isEmpty) {
      _widget.clearWidget();
      return;
    }

    // Resolve sender names
    final senderIds = momentos.map((m) => m.senderId).toSet().toList();
    for (final id in senderIds) {
      if (!_senderNames.containsKey(id)) {
        final user = await _firestore.getUser(id);
        if (user != null) _senderNames[id] = user.displayName;
      }
    }

    final widgetData = momentos.map((m) => {
      'imageUrl': m.imageUrl,
      'senderName': _senderNames[m.senderId] ?? 'Friend',
    }).toList();

    _widget.updateWidgetWithMomentos(widgetData);
  }

  Widget _buildNotLinkedState(BuildContext context) {
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
                Icons.people_outline,
                size: 50,
                color: MomentoTheme.coral.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Link with a friend',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: MomentoTheme.deepPlum,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share your invite code or enter theirs to start sharing momentos',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MomentoTheme.deepPlum.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _openLinkScreen(context),
              icon: const Icon(Icons.person_add),
              label: const Text('Add a Friend'),
            ),
          ],
        ),
      ),
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
              'Take a photo and send it to your friends!',
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

  void _openLinkScreen(BuildContext context) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const LinkScreen()),
    );
  }
}

class _MomentoCard extends StatefulWidget {
  final Momento momento;
  final String? senderName;
  final void Function(String name) onSenderLoaded;
  final FirestoreService firestore;

  const _MomentoCard({
    required this.momento,
    required this.senderName,
    required this.onSenderLoaded,
    required this.firestore,
  });

  @override
  State<_MomentoCard> createState() => _MomentoCardState();
}

class _MomentoCardState extends State<_MomentoCard> {
  String _name = '';

  @override
  void initState() {
    super.initState();
    _name = widget.senderName ?? '';
    if (_name.isEmpty) _loadSender();
  }

  Future<void> _loadSender() async {
    final user = await widget.firestore.getUser(widget.momento.senderId);
    if (user != null && mounted) {
      setState(() => _name = user.displayName);
      widget.onSenderLoaded(user.displayName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.momento.expiresAt.difference(DateTime.now());
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Sender name
          if (_name.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: MomentoTheme.deepPlum,
                ),
              ),
            ),
          // Image
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CachedNetworkImage(
                imageUrl: widget.momento.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
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
          const SizedBox(height: 12),
          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    );
  }
}
