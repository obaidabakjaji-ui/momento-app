import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/app_user.dart';
import '../../models/link_request.dart';
import '../../theme.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _auth = AuthService();
  final _firestore = FirestoreService();

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
              // Profile card
              _buildProfileCard(user),
              const SizedBox(height: 24),

              // Invite code card
              _buildInviteCodeCard(user),
              const SizedBox(height: 24),

              // Pending requests
              _buildSectionTitle('Pending Requests'),
              const SizedBox(height: 8),
              _buildPendingRequests(uid),
              const SizedBox(height: 24),

              // Connected friends
              _buildSectionTitle('Connected Friends'),
              const SizedBox(height: 8),
              _buildConnectedFriends(user),
              const SizedBox(height: 32),

              // Sign out
              OutlinedButton.icon(
                onPressed: () {
                  _auth.signOut();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ],
          );
        },
      ),
    );
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteCodeCard(AppUser user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [MomentoTheme.coral, MomentoTheme.warmOrange],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'Your invite code',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            user.inviteCode ?? '------',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: user.inviteCode ?? ''),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Code copied!')),
              );
            },
            icon: const Icon(Icons.copy, color: Colors.white70, size: 16),
            label: const Text(
              'Copy',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: MomentoTheme.deepPlum,
      ),
    );
  }

  Widget _buildPendingRequests(String uid) {
    return StreamBuilder<List<LinkRequest>>(
      stream: _firestore.watchPendingRequests(uid),
      builder: (context, snap) {
        final requests = snap.data ?? [];
        if (requests.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'No pending requests',
              style: TextStyle(
                color: MomentoTheme.deepPlum.withValues(alpha: 0.5),
              ),
            ),
          );
        }

        return Column(
          children: requests.map((req) => _buildRequestTile(req)).toList(),
        );
      },
    );
  }

  Widget _buildRequestTile(LinkRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: MomentoTheme.softPink,
            child: Text(
              request.fromUserName.isNotEmpty
                  ? request.fromUserName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: MomentoTheme.coral,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.fromUserName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: MomentoTheme.deepPlum,
                  ),
                ),
                Text(
                  'Wants to connect',
                  style: TextStyle(
                    fontSize: 12,
                    color: MomentoTheme.deepPlum.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 32),
            onPressed: () async {
              await _firestore.acceptLinkRequest(request.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Connected with ${request.fromUserName}!'),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red, size: 32),
            onPressed: () async {
              await _firestore.rejectLinkRequest(request.id);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedFriends(AppUser user) {
    if (user.linkedUserIds.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'No connections yet',
          style: TextStyle(
            color: MomentoTheme.deepPlum.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return FutureBuilder<List<AppUser>>(
      future: _firestore.getUsers(user.linkedUserIds),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final friends = snap.data!;
        return Column(
          children: friends.map((friend) => _buildFriendTile(friend, user.uid)).toList(),
        );
      },
    );
  }

  Widget _buildFriendTile(AppUser friend, String currentUid) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: MomentoTheme.coral,
            backgroundImage:
                friend.photoUrl != null ? NetworkImage(friend.photoUrl!) : null,
            child: friend.photoUrl == null
                ? Text(
                    friend.displayName.isNotEmpty
                        ? friend.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: MomentoTheme.deepPlum,
                  ),
                ),
                Text(
                  friend.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: MomentoTheme.deepPlum.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.person_remove,
              color: Colors.red.withValues(alpha: 0.7),
            ),
            onPressed: () => _confirmRemoveFriend(friend, currentUid),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveFriend(AppUser friend, String currentUid) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Connection'),
        content: Text(
          'Are you sure you want to remove ${friend.displayName}? '
          'You will stop receiving their momentos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _firestore.unlinkUser(currentUid, friend.uid);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed ${friend.displayName}'),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
