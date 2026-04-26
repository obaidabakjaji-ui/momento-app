import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Full-screen viewer for a post. Shows a photo with pinch-zoom for image
/// posts, or a looping video player for video posts. Hero animation on the
/// poster image regardless of media type.
class PhotoViewer extends StatefulWidget {
  final String imageUrl;
  final String heroTag;
  final String? caption;
  final String? videoUrl;

  const PhotoViewer({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    this.caption,
    this.videoUrl,
  });

  bool get isVideo => videoUrl != null && videoUrl!.isNotEmpty;

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  VideoPlayerController? _controller;
  bool _videoReady = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl!))
        ..setLooping(true)
        ..setVolume(0)
        ..initialize().then((_) {
          if (!mounted) return;
          setState(() => _videoReady = true);
          _controller!.play();
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    setState(() {
      if (c.value.isPlaying) {
        c.pause();
        _showControls = true;
      } else {
        c.play();
        _showControls = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: widget.isVideo ? _togglePlay : () => Navigator.pop(context),
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0).abs() > 300) {
            Navigator.pop(context);
          }
        },
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Hero(
                  tag: widget.heroTag,
                  child: widget.isVideo ? _buildVideo() : _buildImage(),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              if (widget.isVideo &&
                  _videoReady &&
                  _showControls &&
                  !(_controller?.value.isPlaying ?? false))
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              if (widget.caption != null && widget.caption!.isNotEmpty)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.caption!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return InteractiveViewer(
      minScale: 1,
      maxScale: 4,
      child: CachedNetworkImage(
        imageUrl: widget.imageUrl,
        fit: BoxFit.contain,
        placeholder: (_, __) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        errorWidget: (_, __, ___) => const Icon(
          Icons.broken_image,
          color: Colors.white,
          size: 64,
        ),
      ),
    );
  }

  Widget _buildVideo() {
    if (!_videoReady || _controller == null) {
      // Show the poster while the video buffers so the hero animation has
      // something to land on.
      return Stack(
        alignment: Alignment.center,
        children: [
          CachedNetworkImage(
            imageUrl: widget.imageUrl,
            fit: BoxFit.contain,
          ),
          const CircularProgressIndicator(color: Colors.white),
        ],
      );
    }
    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: VideoPlayer(_controller!),
    );
  }
}
