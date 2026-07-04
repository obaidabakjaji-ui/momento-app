import 'dart:async' show unawaited;
import 'dart:io';
import 'dart:ui' show ImageFilter;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/room_service.dart';
import '../../services/location_service.dart';
import '../../services/widget_service.dart';
import '../../models/app_user.dart';
import '../../models/room.dart';
import '../../theme.dart';

/// What the user picked as the post target.
enum _Target { active, all, custom }

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final _auth = AuthService();
  final _storage = StorageService();
  final _roomService = RoomService();
  final _location = LocationService();
  final _picker = ImagePicker();

  File? _imageFile;
  bool _sending = false;
  bool _loading = true;

  AppUser? _user;
  List<Room> _userRooms = [];

  _Target _target = _Target.active;
  final Set<String> _customSelection = {};
  final _captionController = TextEditingController();

  CameraController? _cameraController;
  List<CameraDescription> _availableCameras = const [];
  int _activeCameraIndex = 0;
  bool _cameraInitializing = false;
  FlashMode _flashMode = FlashMode.off;

  // Visual feedback for the shutter press: scale-down on touch and a brief
  // white-flash overlay on the preview when the photo actually fires.
  bool _shutterPressed = false;
  double _captureFlash = 0;

  @override
  void dispose() {
    _captionController.dispose();
    _cameraController?.dispose();
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
    if (user.roomIds.isNotEmpty) {
      await _initCamera();
    }
  }

  Future<void> _initCamera({int? preferredIndex}) async {
    if (_cameraInitializing) return;
    setState(() => _cameraInitializing = true);

    try {
      if (_availableCameras.isEmpty) {
        _availableCameras = await availableCameras();
      }
      if (_availableCameras.isEmpty) {
        setState(() => _cameraInitializing = false);
        return;
      }

      if (preferredIndex != null) {
        _activeCameraIndex = preferredIndex;
      } else {
        final rearIndex = _availableCameras.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
        );
        _activeCameraIndex = rearIndex >= 0 ? rearIndex : 0;
      }

      await _cameraController?.dispose();
      final controller = CameraController(
        _availableCameras[_activeCameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      try {
        await controller.setFlashMode(_flashMode);
      } catch (_) {
        // Front cameras often don't support flash — ignore.
      }
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _cameraController = controller;
        _cameraInitializing = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _cameraInitializing = false);
      }
    }
  }

  Future<void> _toggleCamera() async {
    if (_availableCameras.length < 2) return;
    final next = (_activeCameraIndex + 1) % _availableCameras.length;
    await _initCamera(preferredIndex: next);
  }

  Future<void> _toggleFlash() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    final next =
        _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    try {
      await controller.setFlashMode(next);
      setState(() => _flashMode = next);
    } catch (_) {
      // Some cameras (front-facing) reject flash mode changes — ignore.
    }
  }

  Future<void> _disposeCamera() async {
    final c = _cameraController;
    _cameraController = null;
    if (c != null) await c.dispose();
    if (mounted) setState(() {});
  }

  Future<void> _captureFromLiveCamera() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isTakingPicture) return;
    HapticFeedback.mediumImpact();
    // White flash overlay: spike to ~70% then fade to 0 over ~140ms. The
    // AnimatedOpacity in the Stack handles the actual fade.
    setState(() => _captureFlash = 0.7);
    try {
      final xfile = await controller.takePicture();
      final cropped = await _cropToSquare(File(xfile.path));
      if (cropped != null && mounted) {
        _clearMedia();
        await _disposeCamera();
        setState(() => _imageFile = cropped);
      }
    } catch (_) {
      // Capture can fail if the sensor was reclaimed — swallow and let
      // the user retry.
    } finally {
      if (mounted) setState(() => _captureFlash = 0);
    }
  }

  bool get _hasMedia => _imageFile != null;

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

  Future<void> _pickFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (picked == null) return;
    final cropped = await _cropToSquare(File(picked.path));
    if (cropped != null && mounted) {
      _clearMedia();
      setState(() => _imageFile = cropped);
    }
  }

  /// Centers a square crop on the picked image and re-encodes as JPEG.
  ///
  /// Two reasons we do this client-side rather than letting the widget
  /// crop at render time:
  ///   1. Widget surface is square (Android 2×2 / iOS systemSmall), so a
  ///      non-square source gets edge-cropped by ImageView.centerCrop and
  ///      the user has no control over what gets cut.
  ///   2. `image.decodeImage()` honours EXIF orientation, so a portrait
  ///      iPhone shot ends up the right way up — Android's BitmapFactory
  ///      in the widget process does NOT auto-apply EXIF, which is why
  ///      portrait photos sometimes appeared sideways on the home screen.
  Future<File?> _cropToSquare(File source) async {
    try {
      final bytes = await source.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      final size =
          decoded.width < decoded.height ? decoded.width : decoded.height;
      final x = (decoded.width - size) ~/ 2;
      final y = (decoded.height - size) ~/ 2;
      final square = img.copyCrop(
        decoded,
        x: x,
        y: y,
        width: size,
        height: size,
      );

      final tmpDir = await getTemporaryDirectory();
      final outPath =
          '${tmpDir.path}/huddle_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final outFile = File(outPath);
      await outFile.writeAsBytes(img.encodeJpg(square, quality: 88));
      return outFile;
    } catch (_) {
      return source;
    }
  }

  void _clearMedia() {
    _imageFile = null;
  }

  Future<void> _send() async {
    if (!_hasMedia || _user == null) return;
    final l = AppLocalizations.of(context);
    final targets = _resolveTargetRoomIds();
    if (targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.cameraPickAtLeastOne)),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      // If any target room has the location lock active, grab GPS so
      // postToRooms can decide live vs. pending per-room. We skip GPS
      // entirely when no target uses the lock, so the user is never
      // prompted for location they don't need.
      final targetRooms = _userRooms.where((r) => targets.contains(r.id));
      final anyLocked =
          targetRooms.any((r) => r.hasActiveLocationLock && !r.isAdmin(_user!.uid));
      double? senderLat;
      double? senderLng;
      if (anyLocked) {
        final loc = await _location.getCurrentPosition();
        if (loc.ok) {
          senderLat = loc.lat;
          senderLng = loc.lng;
        }
        // If lookup failed we proceed without coords: the geofence treats
        // unknown GPS as out-of-area, so the post lands as pending. That's
        // the right default — admins still see it and can approve.
      }

      final imageUrl = await _storage.uploadMomentoImage(
        senderId: _user!.uid,
        imageFile: _imageFile!,
      );

      final caption = _captionController.text.trim();
      final result = await _roomService.postToRooms(
        roomIds: targets,
        senderId: _user!.uid,
        senderName: _user!.displayName,
        senderPhotoUrl: _user!.photoUrl,
        imageUrl: imageUrl,
        caption: caption.isEmpty ? null : caption,
        senderLat: senderLat,
        senderLng: senderLng,
      );
      // Force the home-screen widget to pull the new post immediately. The
      // feed StreamBuilder normally handles this, but on cold-start +
      // pop-and-rebuild the rebuild can race the widget's auto-refresh and
      // the user sees stale data for tens of seconds. force: true bypasses
      // the refresh throttle — the user just posted and expects the widget
      // to update now. Fire-and-forget so the snackbar/pop don't wait.
      unawaited(WidgetService().refreshForUser(_user!.uid, force: true));
      if (mounted) {
        String message;
        if (result.pending == 0) {
          message = l.cameraPostedTo(result.live);
        } else if (result.live == 0) {
          message = l.cameraPendingApproval(result.pending);
        } else {
          message = l.cameraLiveAndPending(result.live, result.pending);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.cameraFailedToSend(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (_loading) {
      return const Scaffold(
        backgroundColor: _kCameraBg,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_user == null || _user!.roomIds.isEmpty) {
      return Scaffold(
        backgroundColor: _kCameraBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              l.cameraNoRooms,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _kCameraBg,
      resizeToAvoidBottomInset: true,
      body: _hasMedia ? _buildReviewScreen() : _buildLiveCameraScreen(),
    );
  }

  /// Edge-to-edge live capture surface.
  ///
  /// Layout: dark background → centered 3:2 rounded preview card → floating
  /// glassy controls overlaid (close + flash on top, gallery + shutter + flip
  /// on bottom). Everything sits in one Stack so the camera feed never moves.
  Widget _buildLiveCameraScreen() {
    return SafeArea(
      child: Stack(
        children: [
          // Centered preview card.
          Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 72, 16, 200),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: AspectRatio(
                  aspectRatio: 3 / 2,
                  child: _buildLivePreview(),
                ),
              ),
            ),
          ),
          // Top-left close.
          Positioned(
            top: 12,
            left: 16,
            child: _GlassyIconButton(
              icon: Icons.close_rounded,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          // Top-right flash.
          Positioned(
            top: 12,
            right: 16,
            child: _GlassyIconButton(
              icon: _flashMode == FlashMode.off
                  ? Icons.flash_off_rounded
                  : Icons.flash_on_rounded,
              tint: _flashMode == FlashMode.off ? null : MomentoTheme.coral,
              onPressed: _toggleFlash,
            ),
          ),
          // Bottom row: gallery / shutter / flip.
          Positioned(
            left: 0,
            right: 0,
            bottom: 28,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _GlassyIconButton(
                  icon: Icons.photo_library_rounded,
                  onPressed: _pickFromGallery,
                  size: 52,
                ),
                _buildShutter(),
                _GlassyIconButton(
                  icon: Icons.flip_camera_ios_rounded,
                  onPressed: _toggleCamera,
                  size: 52,
                ),
              ],
            ),
          ),
          // Small wordmark, centered up top. Subtle — just enough that the
          // screen feels branded without competing with the photo.
          Positioned(
            top: 22,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Huddlex',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          // White capture flash overlay. AnimatedOpacity fades it out as
          // soon as _captureFromLiveCamera flips _captureFlash back to 0.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _captureFlash,
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                child: Container(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreview() {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: controller.value.previewSize?.height ?? 1,
          height: controller.value.previewSize?.width ?? 1,
          child: CameraPreview(controller),
        ),
      ),
    );
  }

  /// The shutter button. Coral gradient core inside a clean white ring —
  /// the only on-brand colour on the live screen, so it pops as the primary
  /// action without shouting. Scales down on touch for tactile feedback.
  Widget _buildShutter() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _shutterPressed = true),
      onTapUp: (_) => setState(() => _shutterPressed = false),
      onTapCancel: () => setState(() => _shutterPressed = false),
      onTap: _captureFromLiveCamera,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _shutterPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          padding: const EdgeInsets.all(5),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [MomentoTheme.coral, MomentoTheme.warmOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Post-capture review. The photo stays in the same 3:2 rounded card as
  /// the live preview did (so the transition feels continuous), and the
  /// caption + target + send live in a glassy panel near the bottom.
  Widget _buildReviewScreen() {
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: Stack(
        children: [
          // Top: captured photo, same size + position as the live preview.
          Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 72, 16, 280),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: AspectRatio(
                  aspectRatio: 3 / 2,
                  child: _imageFile == null
                      ? const SizedBox.shrink()
                      : Image.file(_imageFile!, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
          // Top-left retake (acts like close — discards capture, restarts camera).
          Positioned(
            top: 12,
            left: 16,
            child: _GlassyIconButton(
              icon: Icons.close_rounded,
              onPressed: _sending ? null : () => _discardCapture(),
            ),
          ),
          // Bottom panel: caption + target + send.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildReviewPanel(l),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewPanel(AppLocalizations l) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCaptionField(l),
              const SizedBox(height: 12),
              _buildTargetPills(l),
              if (_target == _Target.custom) ...[
                const SizedBox(height: 10),
                _buildCustomRoomChips(),
              ],
              const SizedBox(height: 16),
              _buildSendButton(l),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaptionField(AppLocalizations l) {
    return TextField(
      controller: _captionController,
      maxLength: 140,
      maxLines: 2,
      minLines: 1,
      textInputAction: TextInputAction.done,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: l.cameraCaptionHint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        counterText: '',
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.12),
            width: 0.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.12),
            width: 0.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: MomentoTheme.coral, width: 1),
        ),
      ),
    );
  }

  Widget _buildTargetPills(AppLocalizations l) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _targetPill(
          label: l.cameraActiveRoomsCount(_user!.activeRoomIds.length),
          selected: _target == _Target.active,
          onTap: () => setState(() => _target = _Target.active),
        ),
        _targetPill(
          label: l.cameraAllRoomsCount(_user!.roomIds.length),
          selected: _target == _Target.all,
          onTap: () => setState(() => _target = _Target.all),
        ),
        _targetPill(
          label: l.cameraPickRooms,
          selected: _target == _Target.custom,
          onTap: () => setState(() => _target = _Target.custom),
        ),
      ],
    );
  }

  Widget _targetPill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? MomentoTheme.coral
                : Colors.white.withValues(alpha: 0.08),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: 0.18),
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomRoomChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: _userRooms.map((room) {
        final selected = _customSelection.contains(room.id);
        return _targetPill(
          label: room.name,
          selected: selected,
          onTap: () => setState(() {
            if (selected) {
              _customSelection.remove(room.id);
            } else {
              _customSelection.add(room.id);
            }
          }),
        );
      }).toList(),
    );
  }

  Widget _buildSendButton(AppLocalizations l) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [MomentoTheme.coral, MomentoTheme.warmOrange],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: MomentoTheme.coral.withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _sending ? null : _send,
            borderRadius: BorderRadius.circular(18),
            child: Center(
              child: _sending
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l.cameraPostMomento,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _discardCapture() async {
    setState(_clearMedia);
    await _initCamera(preferredIndex: _activeCameraIndex);
  }
}

/// The capture surface sits on near-black rather than pure black so the
/// rounded preview corners and glassy controls have something to read
/// against. ~Cinema dark.
const Color _kCameraBg = Color(0xFF0B0B0E);

/// Circular glassy button used for the floating camera controls (close,
/// flash, gallery, flip). Renders as a translucent disc with a thin border
/// — the BackdropFilter samples whatever is behind it for the frosted look.
class _GlassyIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? tint;

  const _GlassyIconButton({
    required this.icon,
    required this.onPressed,
    this.size = 44,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = tint ?? Colors.white;
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.white.withValues(alpha: 0.10),
          child: InkWell(
            onTap: onPressed,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 0.5,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: size * 0.48),
            ),
          ),
        ),
      ),
    );
  }
}
