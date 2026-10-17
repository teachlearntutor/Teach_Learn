import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// TeachLearn's elegant arc spinner & skeleton shimmer loader.
class AppLoader extends StatefulWidget {
  final double size;
  final Color? color;
  final bool isFullscreen;
  final String? labelText;

  const AppLoader({
    super.key,
    this.size = 36.0,
    this.color,
    this.isFullscreen = false,
    this.labelText,
  });

  const factory AppLoader.fullscreen({Key? key, String? labelText}) =
      _FullscreenLoader;

  const factory AppLoader.inline({Key? key, double size, Color? color}) =
      _InlineLoader;

  static Widget skeleton({
    required double width,
    required double height,
    BorderRadius? borderRadius,
  }) {
    return _SkeletonShimmer(
      width: width,
      height: height,
      borderRadius: borderRadius ?? BorderRadius.circular(8),
    );
  }

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

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
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final strokeColor =
        widget.color ??
        (Theme.of(context).brightness == Brightness.dark
            ? AppColors.primaryTealLight
            : AppColors.primaryTeal);

    final loader = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _ArcPainter(
            progress: reduceMotion ? 0.25 : _controller.value,
            color: strokeColor,
          ),
        );
      },
    );

    if (widget.isFullscreen) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            loader,
            const SizedBox(height: 20),
            Text(
              widget.labelText ?? "TeachLearn",
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: strokeColor, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }

    return loader;
  }
}

class _FullscreenLoader extends AppLoader {
  const _FullscreenLoader({super.key, super.labelText})
    : super(size: 48.0, isFullscreen: true);
}

class _InlineLoader extends AppLoader {
  const _InlineLoader({super.key, super.size = 18.0, super.color})
    : super(isFullscreen: false);
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final Rect rect = Rect.fromCircle(center: center, radius: radius - 3);

    final Paint trackPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.5, size.width * 0.08)
      ..strokeCap = StrokeCap.round;

    final Paint arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.5, size.width * 0.08)
      ..strokeCap = StrokeCap.round;

    // Draw continuous background circle track
    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);

    // Draw rotating active arc stroke
    final double startAngle = progress * math.pi * 2;
    final double sweepAngle =
        math.sin(progress * math.pi) * (math.pi * 1.2) + 0.4;

    canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _SkeletonShimmer extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const _SkeletonShimmer({
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  State<_SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<_SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final baseColor = isDark ? AppColors.surfaceDark : AppColors.borderLight;
    final highlightColor = isDark
        ? AppColors.darkInkMuted.withValues(alpha: 0.15)
        : AppColors.surfaceLight;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = reduceMotion ? 0.5 : _controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(-1.5 + progress * 3, 0),
            end: Alignment(-0.5 + progress * 3, 0),
            colors: [baseColor, highlightColor, baseColor],
            stops: const [0.25, 0.5, 0.75],
          ).createShader(bounds),
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: widget.borderRadius,
            ),
          ),
        );
      },
    );
  }
}
