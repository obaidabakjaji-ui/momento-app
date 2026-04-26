import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/room_service.dart';
import '../../services/storage_service.dart';
import '../../models/room.dart';
import '../../theme.dart';
import 'room_detail_screen.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _auth = AuthService();
  final _rooms = RoomService();
  final _storage = StorageService();
  final _picker = ImagePicker();
  final _nameController = TextEditingController();

  RoomVisibility _visibility = RoomVisibility.public;
  bool _creating = false;
  File? _photoFile;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      setState(() => _photoFile = File(picked.path));
    }
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('Please enter a room name');
      return;
    }

    setState(() => _creating = true);
    try {
      String? photoUrl;
      if (_photoFile != null) {
        photoUrl = await _storage.uploadRoomPhoto(
          uploaderId: _auth.currentUser!.uid,
          imageFile: _photoFile!,
        );
      }
      final room = await _rooms.createRoom(
        name: name,
        visibility: _visibility,
        creatorUid: _auth.currentUser!.uid,
        photoUrl: photoUrl,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RoomDetailScreen(roomId: room.id),
        ),
      );
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _creating = false);
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
      appBar: AppBar(title: const Text('Create Room')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _creating ? null : _pickPhoto,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: MomentoTheme.softPink.withValues(alpha: 0.4),
                      backgroundImage:
                          _photoFile != null ? FileImage(_photoFile!) : null,
                      child: _photoFile == null
                          ? const Icon(
                              Icons.camera_alt_outlined,
                              size: 32,
                              color: MomentoTheme.coral,
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: MomentoTheme.coral,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Room photo (optional)',
                style: TextStyle(
                  fontSize: 12,
                  color: MomentoTheme.deepPlum.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Room name',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              maxLength: 40,
              decoration: const InputDecoration(
                hintText: 'e.g. Family, Trip 2026, Best Friends',
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Who can join?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _VisibilityCard(
              icon: Icons.public,
              title: 'Public',
              subtitle: 'Anyone with the room code can join instantly',
              selected: _visibility == RoomVisibility.public,
              onTap: () => setState(() => _visibility = RoomVisibility.public),
            ),
            const SizedBox(height: 8),
            _VisibilityCard(
              icon: Icons.lock_outline,
              title: 'Permission',
              subtitle: 'New members must be approved by an admin',
              selected: _visibility == RoomVisibility.permission,
              onTap: () =>
                  setState(() => _visibility = RoomVisibility.permission),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _creating ? null : _create,
                child: _creating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create Room'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisibilityCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _VisibilityCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? MomentoTheme.coral
                : MomentoTheme.deepPlum.withValues(alpha: 0.1),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 28,
              color: selected
                  ? MomentoTheme.coral
                  : MomentoTheme.deepPlum.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: MomentoTheme.deepPlum,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: MomentoTheme.deepPlum.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: MomentoTheme.coral),
          ],
        ),
      ),
    );
  }
}
