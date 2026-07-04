import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Full-screen photo viewer with pinch-zoom and hero animation.
class PhotoViewer extends StatelessWidget {
  final String imageUrl;
  final String heroTag;
  final String? caption;

  const PhotoViewer({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
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
                  tag: heroTag,
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
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
                  ),
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
              if (caption != null && caption!.isNotEmpty)
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
                      caption!,
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
}
