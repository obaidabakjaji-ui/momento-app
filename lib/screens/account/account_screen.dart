import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/room_service.dart';
import '../../services/moderation_service.dart';
import '../../models/app_user.dart';
import '../../models/room.dart';
import '../../theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../legal_urls.dart';
import '../auth/auth_screen.dart';
import 'edit_profile_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _auth = AuthService();
  final _firestore = FirestoreService();
  final _rooms = RoomService();
  final _moderation = ModerationService();

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('My Account')),
      body: StreamBuilder<AppUser?>(
        stream: _firestore.watchUser(uid),
        builder: (context, userSnap) {
          final user = userSnap.data;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildProfileCard(user),
              if (user.currentStreak > 0) ...[
                const SizedBox(height: 12),
                _buildStreakCard(user),
              ],
              const SizedBox(height: 24),
              _sectionTitle('Active Rooms'),
              const SizedBox(height: 4),
              Text(
                'Posts go here by default. Toggle on/off in the Rooms tab.',
                style: TextStyle(
                  fontSize: 12,
                  color: MomentoTheme.deepPlum.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              _buildRoomList(user, user.activeRoomIds, emptyText: 'No active rooms'),
              const SizedBox(height: 24),
              _sectionTitle('Favorite Rooms'),
              const SizedBox(height: 4),
              Text(
                'Favorites bubble to the front of the feed and the widget rotation.',
                style: TextStyle(
                  fontSize: 12,
                  color: MomentoTheme.deepPlum.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              _buildRoomList(user, user.favoriteRoomIds,
                  emptyText: 'No favorites'),
              const SizedBox(height: 24),
              _sectionTitle('Blocked Users'),
              const SizedBox(height: 8),
              _buildBlockedList(user),
              const SizedBox(height: 32),
              _sectionTitle('Legal'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: const Text('Terms of Service'),
                      trailing: const Icon(Icons.open_in_new, size: 16),
                      onTap: () => launchUrl(Uri.parse(kTermsOfServiceUrl)),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip_outlined),
                      title: const Text('Privacy Policy'),
                      trailing: const Icon(Icons.open_in_new, size: 16),
                      onTap: () => launchUrl(Uri.parse(kPrivacyPolicyUrl)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await _auth.signOut();
                  if (!mounted) return;
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                    (_) => false,
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _confirmDeleteAccount,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.withValues(alpha: 0.7),
                ),
                child: const Text('Delete my account'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
          'This will permanently remove your account, memberships in all rooms, '
          'and favorites. Posts will expire naturally. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _auth.deleteAccount();
      if (!mounted) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        messenger.showSnackBar(const SnackBar(
          content: Text(
            'Please sign out and sign back in, then try deleting again.',
          ),
        ));
      } else {
        messenger.showSnackBar(SnackBar(content: Text('Failed: ${e.message}')));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Widget _buildProfileCard(AppUser user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: MomentoTheme.coral,
            backgroundImage:
                user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
            child: user.photoUrl == null
                ? Text(
                    user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: MomentoTheme.deepPlum,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    color: MomentoTheme.deepPlum.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${user.roomIds.length} room${user.roomIds.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: MomentoTheme.deepPlum.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit profile',
            color: MomentoTheme.coral,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditProfileScreen(user: user),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(AppUser user) {
    final best = user.longestStreak;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [MomentoTheme.coral, MomentoTheme.warmOrange],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department,
              color: Colors.white, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.currentStreak}-day streak',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  best > user.currentStreak
                      ? 'Best: $best days'
                      : 'Keep it going — post today',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: MomentoTheme.deepPlum,
      ),
    );
  }

  Widget _buildBlockedList(AppUser user) {
    if (user.blockedUserIds.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'No blocked users',
          style: TextStyle(
            color: MomentoTheme.deepPlum.withValues(alpha: 0.5),
          ),
        ),
      );
    }
    return FutureBuilder<List<AppUser>>(
      future: _firestore.getUsers(user.blockedUserIds),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: snap.data!.map((blocked) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: MomentoTheme.softPink,
                    backgroundImage: blocked.photoUrl != null
                        ? NetworkImage(blocked.photoUrl!)
                        : null,
                    child: blocked.photoUrl == null
                        ? Text(
                            blocked.displayName.isNotEmpty
                                ? blocked.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: MomentoTheme.coral,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      blocked.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: MomentoTheme.deepPlum,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _moderation.unblockUser(
                      currentUserId: user.uid,
                      targetUserId: blocked.uid,
                    ),
                    child: const Text('Unblock'),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildRoomList(
    AppUser user,
    List<String> roomIds, {
    required String emptyText,
  }) {
    if (roomIds.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          emptyText,
          style: TextStyle(
            color: MomentoTheme.deepPlum.withValues(alpha: 0.5),
          ),
        ),
      );
    }
    return FutureBuilder<List<Room>>(
      future: _rooms.getRooms(roomIds),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: snap.data!
              .map((room) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: MomentoTheme.softPink,
                          backgroundImage: room.photoUrl != null
                              ? NetworkImage(room.photoUrl!)
                              : null,
                          child: room.photoUrl == null
                              ? Text(
                                  room.name.isNotEmpty
                                      ? room.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: MomentoTheme.coral,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            room.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: MomentoTheme.deepPlum,
                            ),
                          ),
                        ),
                        Text(
                          room.code,
                          style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 2,
                            color: MomentoTheme.deepPlum.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}
