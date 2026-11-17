import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'TeachLearn open-book mark',
      child: CustomPaint(
        size: Size.square(size),
        painter: _BrandMarkPainter(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}

class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.fontSize = 26, this.center = true});

  final double fontSize;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: TextStyle(
              fontFamily: AppTypography.headingFontFamily,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              fontVariations: const [FontVariation('wght', 700)],
              height: 1.1,
            ),
            children: [
              TextSpan(
                text: 'Teach',
                style: TextStyle(color: colors.onSurface),
              ),
              TextSpan(
                text: 'Learn',
                style: TextStyle(color: colors.primary),
              ),
            ],
          ),
          textAlign: center ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 4),
        Text(
          'Teach. Learn. Track.',
          textAlign: center ? TextAlign.center : TextAlign.start,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter({
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final Color backgroundColor;
  final Color foregroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 64, size.height / 64);

    canvas.drawRRect(
      RRect.fromLTRBR(0, 0, 64, 64, const Radius.circular(12)),
      Paint()..color = backgroundColor,
    );

    final pages = Paint()..color = foregroundColor;
    final leftPage = Path()
      ..moveTo(10, 27)
      ..cubicTo(19, 26, 26, 28, 31, 33)
      ..lineTo(31, 53)
      ..cubicTo(25, 48, 18, 46, 10, 47)
      ..close();
    final rightPage = Path()
      ..moveTo(54, 27)
      ..cubicTo(45, 26, 38, 28, 33, 33)
      ..lineTo(33, 53)
      ..cubicTo(39, 48, 46, 46, 54, 47)
      ..close();
    canvas.drawPath(leftPage, pages);
    canvas.drawPath(rightPage, pages);

    final cap = Path()
      ..moveTo(32, 10)
      ..lineTo(52, 19)
      ..lineTo(32, 28)
      ..lineTo(12, 19)
      ..close();
    canvas.drawPath(cap, Paint()..color = foregroundColor);

    canvas.drawLine(
      const Offset(49, 20),
      const Offset(49, 28),
      Paint()
        ..color = foregroundColor
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      const Offset(49, 30),
      2,
      Paint()..color = foregroundColor,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BrandMarkPainter oldDelegate) =>
      backgroundColor != oldDelegate.backgroundColor ||
      foregroundColor != oldDelegate.foregroundColor;
}
