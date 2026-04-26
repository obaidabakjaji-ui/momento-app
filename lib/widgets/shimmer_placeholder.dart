import 'package:flutter/material.dart';
import '../theme.dart';

/// A simple animated gradient placeholder. Used in place of a bare spinner
/// while feeds and rooms lists are loading.
class ShimmerPlaceholder extends StatefulWidget {
  final double height;
  final double? width;
  final double radius;

  const ShimmerPlaceholder({
    super.key,
    this.height = 80,
    this.width,
    this.radius = 12,
  });

  @override
  State<ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = _controller.value;
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2 * t, 0),
              end: Alignment(1.0 + 2 * t, 0),
              colors: [
                MomentoTheme.softPink.withValues(alpha: 0.15),
                MomentoTheme.softPink.withValues(alpha: 0.35),
                MomentoTheme.softPink.withValues(alpha: 0.15),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A list of [ShimmerPlaceholder] tiles for use as a list/feed loading state.
class ShimmerList extends StatelessWidget {
  final int count;
  final double itemHeight;
  final EdgeInsets padding;

  const ShimmerList({
    super.key,
    this.count = 5,
    this.itemHeight = 80,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      itemCount: count,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ShimmerPlaceholder(height: itemHeight),
      ),
    );
  }
}
