import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/room_service.dart';
import '../../services/storage_service.dart';
import '../../models/app_user.dart';
import '../../models/room.dart';
import '../../models/join_request.dart';
import '../../theme.dart';
import 'pending_posts_screen.dart';

class RoomSettingsScreen extends StatefulWidget {
  final String roomId;
  const RoomSettingsScreen({super.key, required this.roomId});

  @override
  State<RoomSettingsScreen> createState() => _RoomSettingsScreenState();
}

class _RoomSettingsScreenState extends State<RoomSettingsScreen> {
  final _auth = AuthService();
  final _firestore = FirestoreService();
  final _rooms = RoomService();
  final _storage = StorageService();
  final _picker = ImagePicker();
  bool _uploadingPhoto = false;

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
        final isCreator = room.isCreator(uid);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Room Settings'),
            actions: [
              if (isCreator)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Rename room',
                  onPressed: () => _renameRoom(room),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(room),
              const SizedBox(height: 16),
              _buildCodeCard(room),
              const SizedBox(height: 24),
              if (isAdmin) ...[
                _sectionTitle('Moderation'),
                const SizedBox(height: 8),
                _buildModerationCard(room),
                const SizedBox(height: 24),
              ],
              if (isAdmin && room.visibility == RoomVisibility.permission) ...[
                _sectionTitle('Pending Join Requests'),
                const SizedBox(height: 8),
                _buildJoinRequests(room),
                const SizedBox(height: 24),
              ],
              _sectionTitle('Members (${room.memberCount})'),
              const SizedBox(height: 8),
              _buildMembers(room, isAdmin, uid),
              const SizedBox(height: 32),
              if (room.memberIds.length > 1)
                OutlinedButton.icon(
                  onPressed: () => _confirmLeave(room),
                  icon: const Icon(Icons.logout),
                  label: const Text('Leave Room'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              if (isAdmin) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _confirmDelete(room),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete Room'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(Room room) {
    final isAdmin = room.isAdmin(_auth.currentUser!.uid);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: isAdmin && !_uploadingPhoto ? () => _changePhoto(room) : null,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 32,
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
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                if (_uploadingPhoto)
                  const Positioned.fill(
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                else if (isAdmin)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: MomentoTheme.coral,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit,
                          size: 12, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: MomentoTheme.deepPlum,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      room.visibility == RoomVisibility.public
                          ? Icons.public
                          : Icons.lock_outline,
                      size: 14,
                      color: MomentoTheme.deepPlum.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      room.visibility == RoomVisibility.public
                          ? 'Public'
                          : 'Permission',
                      style: TextStyle(
                        fontSize: 12,
                        color: MomentoTheme.deepPlum.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeCard(Room room) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [MomentoTheme.coral, MomentoTheme.warmOrange],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Room code',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            room.code,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: room.code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code copied!')),
                  );
                },
                icon:
                    const Icon(Icons.copy, color: Colors.white70, size: 16),
                label: const Text('Copy',
                    style: TextStyle(color: Colors.white70)),
              ),
              TextButton.icon(
                onPressed: () => SharePlus.instance.share(
                  ShareParams(
                    text:
                        'Join my "${room.name}" room on Momento — use code ${room.code}',
                    subject: 'Join ${room.name} on Momento',
                  ),
                ),
                icon: const Icon(Icons.share,
                    color: Colors.white70, size: 16),
                label: const Text('Share',
                    style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: MomentoTheme.deepPlum,
      ),
    );
  }

  Widget _buildModerationCard(Room room) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: room.requiresPostApproval,
            onChanged: (v) => _rooms.setRequiresPostApproval(
              roomId: room.id,
              requires: v,
            ),
            activeThumbColor: MomentoTheme.coral,
            title: const Text(
              'Require post approval',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: MomentoTheme.deepPlum,
              ),
            ),
            subtitle: Text(
              'Posts by regular members wait for admin approval. '
              'Admins and trusted users always post immediately.',
              style: TextStyle(
                fontSize: 12,
                color: MomentoTheme.deepPlum.withValues(alpha: 0.6),
              ),
            ),
          ),
          if (room.requiresPostApproval) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.inbox_outlined,
                  color: MomentoTheme.coral),
              title: const Text('Review pending posts'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PendingPostsScreen(
                    roomId: room.id,
                    roomName: room.name,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJoinRequests(Room room) {
    return StreamBuilder<List<JoinRequest>>(
      stream: _rooms.watchJoinRequests(room.id),
      builder: (context, snap) {
        final requests = snap.data ?? [];
        if (requests.isEmpty) {
          return _emptyCard('No pending requests');
        }
        return Column(
          children: requests.map((req) {
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
                    backgroundImage: req.userPhotoUrl != null
                        ? NetworkImage(req.userPhotoUrl!)
                        : null,
                    child: req.userPhotoUrl == null
                        ? Text(
                            req.userName.isNotEmpty
                                ? req.userName[0].toUpperCase()
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
                      req.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: MomentoTheme.deepPlum,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check_circle,
                        color: Colors.green, size: 30),
                    onPressed: () => _rooms.approveJoinRequest(
                      roomId: room.id,
                      userId: req.userId,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel,
                        color: Colors.red, size: 30),
                    onPressed: () => _rooms.denyJoinRequest(
                      roomId: room.id,
                      userId: req.userId,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMembers(Room room, bool currentIsAdmin, String currentUid) {
    return FutureBuilder<List<AppUser>>(
      future: _firestore.getUsers(room.memberIds),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final members = snap.data!;
        return Column(
          children: members.map((m) {
            final isMemberAdmin = room.isAdmin(m.uid);
            final isMemberCreator = room.isCreator(m.uid);
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
                    backgroundImage: m.photoUrl != null
                        ? NetworkImage(m.photoUrl!)
                        : null,
                    child: m.photoUrl == null
                        ? Text(
                            m.displayName.isNotEmpty
                                ? m.displayName[0].toUpperCase()
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: MomentoTheme.deepPlum,
                          ),
                        ),
                        if (isMemberCreator)
                          const Text('Creator',
                              style: TextStyle(
                                fontSize: 11,
                                color: MomentoTheme.coral,
                                fontWeight: FontWeight.w600,
                              ))
                        else if (isMemberAdmin)
                          Text('Admin',
                              style: TextStyle(
                                fontSize: 11,
                                color: MomentoTheme.deepPlum
                                    .withValues(alpha: 0.6),
                              )),
                      ],
                    ),
                  ),
                  if (room.isTrusted(m.uid) && !isMemberAdmin)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Tooltip(
                        message: 'Trusted — bypasses post approval',
                        child: Icon(
                          Icons.verified,
                          size: 18,
                          color: MomentoTheme.coral.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  if (currentIsAdmin && m.uid != currentUid && !isMemberCreator)
                    PopupMenuButton<String>(
                      onSelected: (action) =>
                          _handleMemberAction(action, room, m),
                      itemBuilder: (_) {
                        final isTrusted = room.isTrusted(m.uid);
                        return [
                          if (!isMemberAdmin)
                            const PopupMenuItem(
                              value: 'promote',
                              child: Text('Make admin'),
                            )
                          else
                            const PopupMenuItem(
                              value: 'demote',
                              child: Text('Remove admin'),
                            ),
                          if (!isMemberAdmin)
                            PopupMenuItem(
                              value: isTrusted ? 'untrust' : 'trust',
                              child: Text(
                                isTrusted
                                    ? 'Remove trusted status'
                                    : 'Mark as trusted',
                              ),
                            ),
                          const PopupMenuItem(
                            value: 'kick',
                            child: Text('Remove from room',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ];
                      },
                    ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: MomentoTheme.deepPlum.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Future<void> _handleMemberAction(
      String action, Room room, AppUser member) async {
    switch (action) {
      case 'promote':
        await _rooms.promoteToAdmin(roomId: room.id, userId: member.uid);
        break;
      case 'demote':
        await _rooms.demoteAdmin(roomId: room.id, userId: member.uid);
        break;
      case 'trust':
        await _rooms.setUserTrusted(
            roomId: room.id, userId: member.uid, trusted: true);
        break;
      case 'untrust':
        await _rooms.setUserTrusted(
            roomId: room.id, userId: member.uid, trusted: false);
        break;
      case 'kick':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Remove member?'),
            content: Text(
                '${member.displayName} will be removed from "${room.name}".'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Remove'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await _rooms.kickMember(roomId: room.id, userId: member.uid);
        }
        break;
    }
  }

  Future<void> _changePhoto(Room room) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final url = await _storage.uploadRoomPhoto(
        uploaderId: _auth.currentUser!.uid,
        imageFile: File(picked.path),
      );
      await _rooms.updateRoomPhoto(roomId: room.id, photoUrl: url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update photo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _renameRoom(Room room) async {
    final controller = TextEditingController(text: room.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename room'),
        content: TextField(
          controller: controller,
          maxLength: 40,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'New name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty && newName != room.name) {
      await _rooms.renameRoom(roomId: room.id, newName: newName);
    }
  }

  Future<void> _confirmLeave(Room room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave room?'),
        content: Text('You will stop receiving momentos from "${room.name}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _rooms.leaveRoom(
        roomId: room.id,
        userId: _auth.currentUser!.uid,
      );
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  Future<void> _confirmDelete(Room room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete room?'),
        content: Text(
            '"${room.name}" will be permanently deleted for all members. This cannot be undone.'),
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
    if (confirmed == true) {
      await _rooms.deleteRoom(room.id);
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }
}
