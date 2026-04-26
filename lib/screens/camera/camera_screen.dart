import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/room_service.dart';
import '../../models/app_user.dart';
import '../../models/room.dart';
import '../../models/room_post.dart';
import '../../theme.dart';

/// What the user picked as the post target.
enum _Target { active, all, custom }

const _maxVideoSeconds = 6;

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final _auth = AuthService();
  final _storage = StorageService();
  final _roomService = RoomService();
  final _picker = ImagePicker();

  // Either photo OR video is selected at a time.
  File? _imageFile;
  File? _videoFile; // muted, compressed mp4 ready to upload
  File? _videoPosterFile; // jpg poster for the video
  VideoPlayerController? _videoPreview;

  bool _processingVideo = false;
  bool _sending = false;
  bool _loading = true;

  AppUser? _user;
  List<Room> _userRooms = [];

  _Target _target = _Target.active;
  final Set<String> _customSelection = {};
  final _captionController = TextEditingController();

  @override
  void dispose() {
    _captionController.dispose();
    _videoPreview?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadUserAndRooms();
  }

  Future<void> _loadUserAndRooms() async {
    final user = await _auth.getCurrentAppUser();
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final rooms = await _roomService.getRooms(user.roomIds);
    if (!mounted) return;
    setState(() {
      _user = user;
      _userRooms = rooms;
      _customSelection
        ..clear()
        ..addAll(user.activeRoomIds);
      if (user.activeRoomIds.isEmpty && user.roomIds.isNotEmpty) {
        _target = _Target.all;
      }
      _loading = false;
    });
  }

  bool get _hasMedia => _imageFile != null || _videoFile != null;
  bool get _isVideo => _videoFile != null;

  List<String> _resolveTargetRoomIds() {
    if (_user == null) return const [];
    switch (_target) {
      case _Target.active:
        return _user!.activeRoomIds;
      case _Target.all:
        return _user!.roomIds;
      case _Target.custom:
        return _customSelection.toList();
    }
  }

  Future<void> _takePhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      _clearMedia();
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _pickFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      _clearMedia();
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _recordVideo() async {
    final picked = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: _maxVideoSeconds),
    );
    if (picked == null) return;
    await _processPickedVideo(File(picked.path));
  }

  Future<void> _pickVideoFromGallery() async {
    final picked = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: _maxVideoSeconds),
    );
    if (picked == null) return;
    await _processPickedVideo(File(picked.path));
  }

  /// Strip audio + compress to a sane size, then extract a poster frame
  /// from the middle of the clip.
  Future<void> _processPickedVideo(File rawVideo) async {
    if (!mounted) return;
    _clearMedia();
    setState(() => _processingVideo = true);
    try {
      // Compress + remove audio. MediumQuality keeps clips small while still
      // looking sharp on phones.
      final compressed = await VideoCompress.compressVideo(
        rawVideo.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: false,
      );
      if (compressed == null || compressed.file == null) {
        throw Exception('Could not process video.');
      }

      // Hard-cap at 6s in case the source was longer than image_picker honored
      // (some Android cameras ignore maxDuration).
      final durationMs = compressed.duration?.toInt() ?? 0;
      if (durationMs > (_maxVideoSeconds + 1) * 1000) {
        await VideoCompress.deleteAllCache();
        throw Exception('Video must be 6 seconds or shorter.');
      }

      // Poster from a frame near the middle (more interesting than the very
      // first frame, which is often a black/exposure-adjusting frame).
      final mid = (durationMs / 2).round();
      final posterDir = await getTemporaryDirectory();
      final posterBytes = await VideoThumbnail.thumbnailData(
        video: compressed.file!.path,
        imageFormat: ImageFormat.JPEG,
        timeMs: mid,
        quality: 80,
        maxWidth: 1080,
      );
      if (posterBytes == null) {
        throw Exception('Could not generate poster frame.');
      }
      final posterFile = File(
          '${posterDir.path}/momento-poster-${DateTime.now().millisecondsSinceEpoch}.jpg');
      await posterFile.writeAsBytes(posterBytes);

      final preview = VideoPlayerController.file(compressed.file!);
      await preview.initialize();
      preview.setLooping(true);
      preview.play();

      if (!mounted) {
        await preview.dispose();
        return;
      }
      setState(() {
        _videoFile = compressed.file;
        _videoPosterFile = posterFile;
        _videoPreview = preview;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _processingVideo = false);
    }
  }

  void _clearMedia() {
    _videoPreview?.pause();
    _videoPreview?.dispose();
    _imageFile = null;
    _videoFile = null;
    _videoPosterFile = null;
    _videoPreview = null;
  }

  Future<void> _send() async {
    if (!_hasMedia || _user == null) return;
    final targets = _resolveTargetRoomIds();
    if (targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick at least one room')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      late final String imageUrl;
      String? videoUrl;
      var mediaType = PostMediaType.photo;

      if (_isVideo) {
        final result = await _storage.uploadMomentoVideo(
          senderId: _user!.uid,
          videoFile: _videoFile!,
          posterFile: _videoPosterFile!,
        );
        imageUrl = result.posterUrl;
        videoUrl = result.videoUrl;
        mediaType = PostMediaType.video;
      } else {
        imageUrl = await _storage.uploadMomentoImage(
          senderId: _user!.uid,
          imageFile: _imageFile!,
        );
      }

      final caption = _captionController.text.trim();
      final result = await _roomService.postToRooms(
        roomIds: targets,
        senderId: _user!.uid,
        senderName: _user!.displayName,
        senderPhotoUrl: _user!.photoUrl,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        mediaType: mediaType,
        caption: caption.isEmpty ? null : caption,
      );
      if (mounted) {
        String message;
        if (result.pending == 0) {
          message =
              'Posted to ${result.live} room${result.live == 1 ? '' : 's'}!';
        } else if (result.live == 0) {
          message =
              '${result.pending} post${result.pending == 1 ? '' : 's'} pending admin approval.';
        } else {
          message =
              '${result.live} live, ${result.pending} pending admin approval.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_user == null || _user!.roomIds.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('New Momento')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Join or create a room first to post momentos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MomentoTheme.deepPlum.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('New Momento')),
      body: Column(
        children: [
          Expanded(child: _buildPreviewArea()),
          if (_hasMedia) _buildCaptionField(),
          if (_hasMedia) _buildTargetPicker(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: !_hasMedia ? _buildPickerButtons() : _buildSendButtons(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewArea() {
    if (_processingVideo) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing video…'),
          ],
        ),
      );
    }
    if (_imageFile != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(
            _imageFile!,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        ),
      );
    }
    if (_videoPreview != null && _videoPreview!.value.isInitialized) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: _videoPreview!.value.aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                VideoPlayer(_videoPreview!),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.videocam, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Muted',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 80,
            color: MomentoTheme.deepPlum.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Capture a photo or 6-second clip',
            style: TextStyle(
              color: MomentoTheme.deepPlum.withValues(alpha: 0.5),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _processingVideo ? null : _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Photo'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _processingVideo ? null : _recordVideo,
                icon: const Icon(Icons.videocam),
                label: const Text('Video'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _processingVideo ? null : _pickFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Photo from gallery'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _processingVideo ? null : _pickVideoFromGallery,
                icon: const Icon(Icons.video_library),
                label: const Text('Video from gallery'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSendButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _sending
                ? null
                : () => setState(() {
                      _clearMedia();
                    }),
            child: const Text('Retake'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _sending ? null : _send,
            child: _sending
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(_isVideo ? 'Post Clip' : 'Post Momento'),
          ),
        ),
      ],
    );
  }

  Widget _buildCaptionField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: _captionController,
        maxLength: 140,
        maxLines: 2,
        minLines: 1,
        textInputAction: TextInputAction.done,
        style: const TextStyle(color: MomentoTheme.deepPlum),
        decoration: InputDecoration(
          hintText: 'Add a caption (optional)',
          filled: true,
          fillColor: Colors.white,
          counterText: '',
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildTargetPicker() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Post to',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: MomentoTheme.deepPlum.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: Text(
                    'Active rooms (${_user!.activeRoomIds.length})'),
                selected: _target == _Target.active,
                onSelected: (_) => setState(() => _target = _Target.active),
              ),
              ChoiceChip(
                label: Text('All rooms (${_user!.roomIds.length})'),
                selected: _target == _Target.all,
                onSelected: (_) => setState(() => _target = _Target.all),
              ),
              ChoiceChip(
                label: const Text('Pick…'),
                selected: _target == _Target.custom,
                onSelected: (_) => setState(() => _target = _Target.custom),
              ),
            ],
          ),
          if (_target == _Target.custom) ...[
            const Divider(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _userRooms.map((room) {
                final selected = _customSelection.contains(room.id);
                return FilterChip(
                  label: Text(room.name),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _customSelection.add(room.id);
                    } else {
                      _customSelection.remove(room.id);
                    }
                  }),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
