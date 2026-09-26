import 'dart:math';
import 'package:flutter/material.dart';
import '../../constants/ludo_colors.dart';

class SafeStarPainter extends CustomPainter {
  final Color color;

  SafeStarPainter({this.color = LudoColors.safeStar});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.black45
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width * 0.40;
    final innerRadius = outerRadius * 0.45;

    const int points = 5;
    final double step = pi / points;

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

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HomeTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    final pRed = Paint()..color = LudoColors.red;
    final pGreen = Paint()..color = LudoColors.green;
    final pYellow = Paint()..color = LudoColors.yellow;
    final pBlue = Paint()..color = LudoColors.blue;

    final borderPaint = Paint()
      ..color = LudoColors.boardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Top triangle: Green
    final pathGreen = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(pathGreen, pGreen);
    canvas.drawPath(pathGreen, borderPaint);

    // Right triangle: Yellow
    final pathYellow = Path()
      ..moveTo(w, 0)
      ..lineTo(w, h)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(pathYellow, pYellow);
    canvas.drawPath(pathYellow, borderPaint);

    // Bottom triangle: Blue
    final pathBlue = Path()
      ..moveTo(0, h)
      ..lineTo(w, h)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(pathBlue, pBlue);
    canvas.drawPath(pathBlue, borderPaint);

    // Left triangle: Red
    final pathRed = Path()
      ..moveTo(0, 0)
      ..lineTo(0, h)
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(pathRed, pRed);
    canvas.drawPath(pathRed, borderPaint);

    // Center Royal Golden Medallion
    final goldFillPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;
    final goldBorderPaint = Paint()
      ..color = const Color(0xFFB8860B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, w * 0.16, goldFillPaint);
    canvas.drawCircle(center, w * 0.16, goldBorderPaint);

    // Inner bright ring
    final innerRingPaint = Paint()
      ..color = const Color(0xFFFFF176)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, w * 0.13, innerRingPaint);

    // Mini center star in medallion
    final starPaint = Paint()
      ..color = const Color(0xFF8D6E12)
      ..style = PaintingStyle.fill;
    final starPath = Path();
    const int pts = 4;
    final double step = pi / pts;
    final outR = w * 0.08;
    final inR = outR * 0.35;
    for (int i = 0; i < 2 * pts; i++) {
      final r = (i % 2 == 0) ? outR : inR;
      final angle = i * step - pi / 2;
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }
    starPath.close();
    canvas.drawPath(starPath, starPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
