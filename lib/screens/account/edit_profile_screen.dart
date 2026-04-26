import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../models/app_user.dart';
import '../../theme.dart';

class EditProfileScreen extends StatefulWidget {
  final AppUser user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _picker = ImagePicker();
  late final TextEditingController _nameController;

  File? _pickedPhoto;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.displayName);
  }

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
      setState(() => _pickedPhoto = File(picked.path));
    }
  }

  Future<void> _save() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      String? newPhotoUrl;
      if (_pickedPhoto != null) {
        final fileName = '${const Uuid().v4()}.jpg';
        final ref = FirebaseStorage.instance
            .ref('profile_photos/${widget.user.uid}/$fileName');
        final snap = await ref.putFile(
          _pickedPhoto!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        newPhotoUrl = await snap.ref.getDownloadURL();
      }

      final update = <String, dynamic>{};
      if (newName != widget.user.displayName) update['displayName'] = newName;
      if (newPhotoUrl != null) update['photoUrl'] = newPhotoUrl;

      if (update.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.uid)
            .update(update);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final hasExistingPhoto = u.photoUrl != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: GestureDetector(
                onTap: _saving ? null : _pickPhoto,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: MomentoTheme.softPink,
                      backgroundImage: _pickedPhoto != null
                          ? FileImage(_pickedPhoto!) as ImageProvider
                          : hasExistingPhoto
                              ? NetworkImage(u.photoUrl!)
                              : null,
                      child: (_pickedPhoto == null && !hasExistingPhoto)
                          ? Text(
                              u.displayName.isNotEmpty
                                  ? u.displayName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.bold,
                                color: MomentoTheme.coral,
                              ),
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
            const SizedBox(height: 8),
            Text(
              'Tap to change photo',
              style: TextStyle(
                fontSize: 12,
                color: MomentoTheme.deepPlum.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              maxLength: 40,
              decoration: const InputDecoration(
                labelText: 'Display name',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              u.email,
              style: TextStyle(
                color: MomentoTheme.deepPlum.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
