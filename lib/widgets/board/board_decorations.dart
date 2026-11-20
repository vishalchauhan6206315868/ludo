import 'dart:math';
import 'package:flutter/material.dart';
import '../../constants/ludo_colors.dart';

class SafeStarPainter extends CustomPainter {
  final Color color;

  SafeStarPainter({this.color = LudoColors.safeStar});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width * 0.44;
    final innerRadius = outerRadius * 0.45;

    const int points = 5;
    final double step = pi / points;
    final path = Path();

    for (int i = 0; i < 2 * points; i++) {
      final r = (i % 2 == 0) ? outerRadius : innerRadius;
      final angle = i * step - pi / 2;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Subtle soft shadow for tactile depth
    canvas.drawPath(
      path.shift(const Offset(0, 0.8)),
      Paint()..color = Colors.black.withValues(alpha: 0.22),
    );

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(color, Colors.white, 0.22)!,
          color,
          Color.lerp(color, Colors.black, 0.14)!,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, fillPaint);

    final borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant SafeStarPainter oldDelegate) =>
      oldDelegate.color != color;
}

class HomeTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    void drawBeveledTriangle(Path path, Color baseColor, Alignment lightFrom) {
      final paint = Paint()
        ..shader = LinearGradient(
          begin: lightFrom,
          end: Alignment(-lightFrom.x, -lightFrom.y),
          colors: [
            Color.lerp(baseColor, Colors.white, 0.16)!,
            baseColor,
            Color.lerp(baseColor, Colors.black, 0.16)!,
          ],
          stops: const [0.0, 0.52, 1.0],
        ).createShader(Offset.zero & size);
      canvas.drawPath(path, paint);
    }

    // Top triangle: Green
    final pathGreen = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(center.dx, center.dy)
      ..close();
    drawBeveledTriangle(pathGreen, LudoColors.green, Alignment.topCenter);

    // Right triangle: Yellow
    final pathYellow = Path()
      ..moveTo(w, 0)
      ..lineTo(w, h)
      ..lineTo(center.dx, center.dy)
      ..close();
    drawBeveledTriangle(pathYellow, LudoColors.yellow, Alignment.topRight);

    // Bottom triangle: Blue
    final pathBlue = Path()
      ..moveTo(0, h)
      ..lineTo(w, h)
      ..lineTo(center.dx, center.dy)
      ..close();
    drawBeveledTriangle(pathBlue, LudoColors.blue, Alignment.bottomCenter);

    // Left triangle: Red
    final pathRed = Path()
      ..moveTo(0, 0)
      ..lineTo(0, h)
      ..lineTo(center.dx, center.dy)
      ..close();
    drawBeveledTriangle(pathRed, LudoColors.red, Alignment.topLeft);

    // Crisp diagonal & outer borders
    final borderPaint = Paint()
      ..color = const Color(0xFF1F2937).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    canvas.drawLine(Offset.zero, Offset(w, h), borderPaint);
    canvas.drawLine(Offset(w, 0), Offset(0, h), borderPaint);
    canvas.drawRect(Offset.zero & size, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
