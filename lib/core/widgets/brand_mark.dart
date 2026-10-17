import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
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
        painter: const _BrandMarkPainter(),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkInk : AppColors.ink;
    final brandColor = isDark
        ? AppColors.primaryTealLight
        : AppColors.primaryTeal;

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
                style: TextStyle(color: textColor),
              ),
              TextSpan(
                text: 'Learn',
                style: TextStyle(color: brandColor),
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
  const _BrandMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 64, size.height / 64);

    canvas.drawRRect(
      RRect.fromLTRBR(0, 0, 64, 64, const Radius.circular(16)),
      Paint()..color = AppColors.primaryTeal,
    );

    final pages = Paint()..color = Colors.white;
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
    canvas.drawPath(cap, Paint()..color = AppColors.accentTeal);

    canvas.drawLine(
      const Offset(49, 20),
      const Offset(49, 28),
      Paint()
        ..color = AppColors.accentTeal
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      const Offset(49, 30),
      2,
      Paint()..color = AppColors.accentTeal,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BrandMarkPainter oldDelegate) => false;
}
