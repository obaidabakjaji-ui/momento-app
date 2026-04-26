import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/room_service.dart';
import '../../models/room.dart';
import '../../theme.dart';
import 'room_detail_screen.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final _auth = AuthService();
  final _rooms = RoomService();
  final _codeController = TextEditingController();
  final _searchController = TextEditingController();

  bool _busy = false;
  Timer? _searchDebounce;
  List<Room> _searchResults = const [];
  bool _searching = false;

  @override
  void dispose() {
    _codeController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce =
        Timer(const Duration(milliseconds: 300), () => _runSearch(value));
  }

  Future<void> _runSearch(String value) async {
    final q = value.trim();
    if (q.isEmpty) {
      if (mounted) setState(() => _searchResults = const []);
      return;
    }
    setState(() => _searching = true);
    try {
      final results = await _rooms.searchPublicRooms(q);
      if (!mounted) return;
      // Filter out rooms the user is already a member of
      final me = _auth.currentUser?.uid;
      setState(() {
        _searchResults = me == null
            ? results
            : results.where((r) => !r.memberIds.contains(me)).toList();
        _searching = false;
      });
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _joinRoom(Room room) async {
    setState(() => _busy = true);
    try {
      final me = await _auth.getCurrentAppUser();
      if (me == null) return;

      if (room.isMember(me.uid)) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RoomDetailScreen(roomId: room.id),
          ),
        );
        return;
      }

      final joined = await _rooms.requestOrJoinRoom(
        room: room,
        userId: me.uid,
        userName: me.displayName,
        userPhotoUrl: me.photoUrl,
      );

      if (!mounted) return;
      if (joined) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RoomDetailScreen(roomId: room.id),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Request sent. Waiting for an admin of "${room.name}" to approve.',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _joinByCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      _showError('Room codes are 6 characters');
      return;
    }

    setState(() => _busy = true);
    try {
      final room = await _rooms.findRoomByCode(code);
      if (room == null) {
        _showError('No room found with that code');
        return;
      }
      await _joinRoom(room);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Room')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Code entry card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'Have a code?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6,
                  ),
                  maxLength: 6,
                  decoration: const InputDecoration(
                    hintText: 'A7BX92',
                    hintStyle: TextStyle(letterSpacing: 6),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _joinByCode,
                    child: _busy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Join by code'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Search by name
          Text(
            'Or search public rooms',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Room name…',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_searching)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_searchController.text.trim().isNotEmpty &&
              _searchResults.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No public rooms matched.',
                style: TextStyle(
                  color: MomentoTheme.deepPlum.withValues(alpha: 0.6),
                ),
              ),
            )
          else
            ..._searchResults.map(_buildResultTile),
          const SizedBox(height: 24),
          Text(
            'Permission-based rooms can only be joined using their code.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: MomentoTheme.deepPlum.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultTile(Room room) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: MomentoTheme.softPink,
          backgroundImage:
              room.photoUrl != null ? NetworkImage(room.photoUrl!) : null,
          child: room.photoUrl == null
              ? Text(
                  room.name.isNotEmpty ? room.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: MomentoTheme.coral,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          room.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: MomentoTheme.deepPlum,
          ),
        ),
        subtitle: Text(
          '${room.memberCount} member${room.memberCount == 1 ? '' : 's'}',
          style: TextStyle(
            fontSize: 12,
            color: MomentoTheme.deepPlum.withValues(alpha: 0.6),
          ),
        ),
        trailing: FilledButton(
          onPressed: _busy ? null : () => _joinRoom(room),
          style: FilledButton.styleFrom(
            backgroundColor: MomentoTheme.coral,
            visualDensity: VisualDensity.compact,
          ),
          child: const Text('Join'),
        ),
      ),
    );
  }
}
