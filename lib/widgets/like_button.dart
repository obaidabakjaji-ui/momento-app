import 'package:flutter/material.dart';
import '../models/room_post.dart';
import '../services/room_service.dart';
import '../theme.dart';
import 'liked_by_sheet.dart';

/// Heart button + count for a [RoomPost]. Tapping toggles the current user's
/// like via [RoomService.toggleLike]. Optimistic update so the UI reacts
/// instantly.
class LikeButton extends StatefulWidget {
  final RoomPost post;
  final String currentUserId;

  const LikeButton({
    super.key,
    required this.post,
    required this.currentUserId,
  });

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton>
    with SingleTickerProviderStateMixin {
  final _rooms = RoomService();
  late bool _liked;
  late int _count;
  bool _busy = false;
  late final AnimationController _bounceController;
  late final Animation<double> _bounce;

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _liked = widget.post.likedByUser(widget.currentUserId);
    _count = widget.post.likeCount;
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _bounce = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 50),
    ]).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(covariant LikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reflect external changes (e.g. another user liked) when not mid-toggle.
    if (!_busy && oldWidget.post != widget.post) {
      _liked = widget.post.likedByUser(widget.currentUserId);
      _count = widget.post.likeCount;
    }
  }

  Future<void> _toggle() async {
    if (_busy) return;
    final newLiked = !_liked;
    setState(() {
      _busy = true;
      _liked = newLiked;
      _count += newLiked ? 1 : -1;
    });
    if (newLiked) _bounceController.forward(from: 0);
    try {
      await _rooms.toggleLike(
        roomId: widget.post.roomId,
        postId: widget.post.id,
        userId: widget.currentUserId,
        like: newLiked,
      );
    } catch (_) {
      // Roll back on failure
      if (mounted) {
        setState(() {
          _liked = !newLiked;
          _count += newLiked ? -1 : 1;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openLikedBy(BuildContext context) {
    showLikedBySheet(
      context: context,
      userIds: widget.post.likedBy,
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: _toggle,
      onLongPress:
          widget.post.likedBy.isNotEmpty ? () => _openLikedBy(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _liked
              ? MomentoTheme.coral.withValues(alpha: 0.15)
              : MomentoTheme.deepPlum.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _bounce,
              child: Icon(
                _liked ? Icons.favorite : Icons.favorite_border,
                size: 16,
                color: _liked
                    ? MomentoTheme.coral
                    : MomentoTheme.deepPlum.withValues(alpha: 0.6),
              ),
            ),
            if (_count > 0) ...[
              const SizedBox(width: 6),
              Text(
                '$_count',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _liked
                      ? MomentoTheme.coral
                      : MomentoTheme.deepPlum.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
