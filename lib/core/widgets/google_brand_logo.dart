import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Authentic 4-color Google "G" brand logo painted using crisp vector arcs & bars.
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
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final double strokeWidth = size.width * 0.21;
    final Rect rect = Rect.fromCircle(center: center, radius: radius - (strokeWidth / 2));

    final Paint bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final Paint greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final Paint yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final Paint redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Red arc (top segment)
    canvas.drawArc(rect, -math.pi * 0.75, math.pi * 0.55, false, redPaint);

    // Yellow arc (left segment)
    canvas.drawArc(rect, -math.pi * 1.30, math.pi * 0.55, false, yellowPaint);

    // Green arc (bottom segment)
    canvas.drawArc(rect, math.pi * 0.25, math.pi * 0.45, false, greenPaint);

    // Blue arc (right segment)
    canvas.drawArc(rect, -math.pi * 0.20, math.pi * 0.45, false, bluePaint);

    // Center horizontal blue crossbar
    final Paint blueFill = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    final double barWidth = size.width * 0.45;
    final double barHeight = strokeWidth * 0.9;
    final RRect barRRect = RRect.fromLTRBR(
      center.dx - 1,
      center.dy - (barHeight / 2),
      center.dx + barWidth,
      center.dy + (barHeight / 2),
      const Radius.circular(2),
    );
    canvas.drawRRect(barRRect, blueFill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
