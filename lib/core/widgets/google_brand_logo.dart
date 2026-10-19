import 'package:flutter/material.dart';

/// Official 4-color Google "G" brand logo painted with pixel-perfect vector paths.
class GoogleBrandLogo extends StatelessWidget {
  final double size;

  const GoogleBrandLogo({super.key, this.size = 20.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / 24.0;
    canvas.scale(scale, scale);

    // 1. Blue segment (Right bar & upper right arc)
    final Paint bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final Path bluePath = Path()
      ..moveTo(23.49, 12.27)
      ..cubicTo(23.49, 11.48, 23.42, 10.73, 23.30, 10.0)
      ..lineTo(12.0, 10.0)
      ..lineTo(12.0, 14.51)
      ..lineTo(18.47, 14.51)
      ..cubicTo(18.18, 15.99, 17.33, 17.24, 16.07, 18.09)
      ..lineTo(16.07, 21.09)
      ..lineTo(19.93, 21.09)
      ..cubicTo(22.19, 19.0, 23.49, 15.92, 23.49, 12.27)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // 2. Green segment (Bottom arc)
    final Paint greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    final Path greenPath = Path()
      ..moveTo(12.0, 24.0)
      ..cubicTo(15.24, 24.0, 17.95, 22.92, 19.93, 21.09)
      ..lineTo(16.07, 18.09)
      ..cubicTo(14.99, 18.81, 13.62, 19.25, 12.0, 19.25)
      ..cubicTo(8.87, 19.25, 6.22, 17.14, 5.27, 14.29)
      ..lineTo(1.29, 14.29)
      ..lineTo(1.29, 17.38)
      ..cubicTo(3.26, 21.30, 7.31, 24.0, 12.0, 24.0)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // 3. Yellow segment (Left arc)
    final Paint yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    final Path yellowPath = Path()
      ..moveTo(5.27, 14.29)
      ..cubicTo(5.02, 13.57, 4.89, 12.80, 4.89, 12.0)
      ..cubicTo(4.89, 11.20, 5.02, 10.43, 5.27, 9.71)
      ..lineTo(5.27, 6.62)
      ..lineTo(1.29, 6.62)
      ..cubicTo(0.47, 8.24, 0.0, 10.06, 0.0, 12.0)
      ..cubicTo(0.0, 13.94, 0.47, 15.76, 1.29, 17.38)
      ..lineTo(5.27, 14.29)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // 4. Red segment (Top arc)
    final Paint redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;
    final Path redPath = Path()
      ..moveTo(12.0, 4.75)
      ..cubicTo(13.77, 4.75, 15.35, 5.36, 16.60, 6.55)
      ..lineTo(20.02, 3.13)
      ..cubicTo(17.95, 1.19, 15.24, 0.0, 12.0, 0.0)
      ..cubicTo(7.31, 0.0, 3.26, 2.70, 1.29, 6.62)
      ..lineTo(5.27, 9.71)
      ..cubicTo(6.22, 6.86, 8.87, 4.75, 12.0, 4.75)
      ..close();
    canvas.drawPath(redPath, redPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
