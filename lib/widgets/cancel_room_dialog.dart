import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Royal 3D Cancel Room Confirmation Dialog
/// Matches the reference design with 3D Crown, Sunburst Rays, Floating Dice,
/// 3D Megaphone with announcement rays, highlighted warning text, and glossy bubble buttons.
class CancelRoomDialog extends StatelessWidget {
  final bool isHost;

  const CancelRoomDialog({
    super.key,
    this.isHost = true,
  });

  /// Static helper to display the dialog and return `true` if cancelled/left, `false` otherwise.
  static Future<bool?> show(BuildContext context, {bool isHost = true}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => CancelRoomDialog(isHost: isHost),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 0.85,
      maxScaleFactor: 1.15,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 390,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // 1. Top Royal Crown with Sunburst Rays
              Positioned(
                top: -38,
                child: CustomPaint(
                  size: const Size(120, 56),
                  painter: _CancelCrownPainter(),
                ),
              ),

              // 2. Top-Left Floating 3D Dice
              Positioned(
                top: -24,
                left: 10,
                child: CustomPaint(
                  size: const Size(38, 38),
                  painter: _CancelDicePainter(rotationAngle: -0.22),
                ),
              ),

              // 3. Top-Right Floating 3D Dice
              Positioned(
                top: -24,
                right: 10,
                child: CustomPaint(
                  size: const Size(38, 38),
                  painter: _CancelDicePainter(rotationAngle: 0.25),
                ),
              ),

              // 4. Main Royal Navy Dialog Card Container
              Container(
                margin: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0D1D45),
                      Color(0xFF081432),
                      Color(0xFF040B1E),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFFFFD700), width: 2.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                      blurRadius: 22,
                      spreadRadius: 1,
                    ),
                    const BoxShadow(
                      color: Colors.black87,
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      // Inner Cyan Border Glow Outline
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),

                      // Content
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 3D Embossed Title Capsule: Cancel Room?
                            _buildTitleCapsule(),
                            const SizedBox(height: 14),

                            // Body Content: 3D Megaphone & Highlighted Typography
                            _buildBodyContent(),
                            const SizedBox(height: 12),

                            // Golden Horizontal Divider with 3D Star
                            _buildStarDivider(),
                            const SizedBox(height: 14),

                            // Action Buttons Row: Stay vs Cancel Room
                            _buildActionButtons(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 3D Embossed Title Capsule with Comic Golden Whiskers
  Widget _buildTitleCapsule() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Left Comic Whiskers
          CustomPaint(
            size: const Size(18, 16),
            painter: _ComicWhiskersPainter(isLeft: true),
          ),
          const SizedBox(width: 4),

          // Embossed Blue Capsule with Title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0066FF), Color(0xFF0038A8)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFD700), width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0091EA).withValues(alpha: 0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isHost ? "Cancel " : "Leave ",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black87,
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFFFFFDE7),
                      Color(0xFFFFEA79),
                      Color(0xFFFFB300),
                      Color(0xFFFFA000),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(bounds),
                  child: const Text(
                    "Room?",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Color(0xFF5E3900),
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),

          // Right Comic Whiskers
          CustomPaint(
            size: const Size(18, 16),
            painter: _ComicWhiskersPainter(isLeft: false),
          ),
        ],
      ),
    );
  }

  /// Body Content: 3D Megaphone on left, explanation with highlighted text on right
  Widget _buildBodyContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 3D Red & White Announcement Megaphone
        Container(
          margin: const EdgeInsets.only(right: 12),
          child: CustomPaint(
            size: const Size(64, 56),
            painter: _MegaphonePainter(),
          ),
        ),

        // Explanatory Message
        Expanded(
          child: Text.rich(
            TextSpan(
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                height: 1.35,
                shadows: [
                  Shadow(color: Colors.black87, blurRadius: 3),
                ],
              ),
              children: isHost
                  ? const [
                      TextSpan(text: "Are you sure you want to cancel this room? All joined players will be "),
                      TextSpan(
                        text: "removed",
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(color: Color(0xFFFF9900), blurRadius: 4),
                          ],
                        ),
                      ),
                      TextSpan(text: " and entry fees "),
                      TextSpan(
                        text: "refunded.",
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(color: Color(0xFFFF9900), blurRadius: 4),
                          ],
                        ),
                      ),
                    ]
                  : const [
                      TextSpan(text: "Are you sure you want to leave this room? Your entry fee will be "),
                      TextSpan(
                        text: "refunded.",
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(color: Color(0xFFFF9900), blurRadius: 4),
                          ],
                        ),
                      ),
                    ],
            ),
          ),
        ),
      ],
    );
  }

  /// Golden Horizontal Line with 3D Golden Star in center
  Widget _buildStarDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFFFFD700).withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.star_rounded,
            color: Color(0xFFFFD700),
            size: 18,
            shadows: [
              Shadow(color: Color(0xFFFF9900), blurRadius: 6),
            ],
          ),
        ),
        Expanded(
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFD700).withValues(alpha: 0.7),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 3D Glossy Action Buttons: Stay (Blue) vs Cancel Room (Red)
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Stay Button (Electric Cyan/Blue Glossy Capsule)
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(false),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF00A2FF),
                    Color(0xFF0066FF),
                    Color(0xFF0044CC),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF80D8FF), width: 2.0),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0091EA).withValues(alpha: 0.55),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                  const BoxShadow(
                    color: Colors.black45,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // White circle with dark-blue X
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF0044CC),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Stay",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(color: Colors.black54, offset: Offset(0, 1.5), blurRadius: 3),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Cancel Room Button (Crimson Red Glossy Capsule)
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(true),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF2A4B),
                    Color(0xFFD50000),
                    Color(0xFF8B0000),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFF8A80), width: 2.0),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF1744).withValues(alpha: 0.55),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                  const BoxShadow(
                    color: Colors.black45,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white,
                          size: 22,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 3),
                          ],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isHost ? "Cancel Room" : "Leave",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                            shadows: [
                              Shadow(color: Colors.black54, offset: Offset(0, 1.5), blurRadius: 3),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 3D Golden Crown with Center Ruby and Sunburst Rays
class _CancelCrownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.65);

    // 1. Sunburst Light Rays
    final rayPaint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 9; i++) {
      final angle = -math.pi * 0.85 + (i * (math.pi * 0.7 / 8));
      final rayStart = Offset(center.dx + math.cos(angle) * 16, center.dy + math.sin(angle) * 16);
      final rayEnd = Offset(center.dx + math.cos(angle) * 36, center.dy + math.sin(angle) * 36);

      rayPaint.shader = LinearGradient(
        colors: [
          const Color(0xFFFFD700).withValues(alpha: 0.65),
          Colors.transparent,
        ],
      ).createShader(Rect.fromPoints(rayStart, rayEnd));

      canvas.drawLine(rayStart, rayEnd, rayPaint);
    }

    // 2. Crown Glow
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFB300).withValues(alpha: 0.45),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 28));
    canvas.drawCircle(center, 28, glow);

    // 3. 3D Crown Body
    final crownPath = Path()
      ..moveTo(center.dx - 22, center.dy + 12)
      ..lineTo(center.dx + 22, center.dy + 12)
      ..lineTo(center.dx + 26, center.dy - 10)
      ..lineTo(center.dx + 13, center.dy)
      ..lineTo(center.dx, center.dy - 16)
      ..lineTo(center.dx - 13, center.dy)
      ..lineTo(center.dx - 26, center.dy - 10)
      ..close();

    final crownPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF9D2), Color(0xFFFFD700), Color(0xFFFF8F00), Color(0xFF8C5300)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: 24));
    canvas.drawPath(crownPath, crownPaint);

    // 4. Center Ruby / Purple Gemstone
    final gemPath = Path()
      ..moveTo(center.dx, center.dy - 6)
      ..lineTo(center.dx + 5, center.dy)
      ..lineTo(center.dx, center.dy + 6)
      ..lineTo(center.dx - 5, center.dy)
      ..close();
    canvas.drawPath(gemPath, Paint()..color = const Color(0xFF9C27B0));

    // Outer Jewels
    final rubyPaint = Paint()..color = const Color(0xFFFF1744);
    canvas.drawCircle(Offset(center.dx, center.dy - 16), 3.0, rubyPaint);
    canvas.drawCircle(Offset(center.dx - 26, center.dy - 10), 2.5, rubyPaint);
    canvas.drawCircle(Offset(center.dx + 26, center.dy - 10), 2.5, rubyPaint);
    canvas.drawCircle(Offset(center.dx - 13, center.dy), 2.0, Paint()..color = const Color(0xFF00E5FF));
    canvas.drawCircle(Offset(center.dx + 13, center.dy), 2.0, Paint()..color = const Color(0xFF00E5FF));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Floating 3D White Isometric Dice Painter
class _CancelDicePainter extends CustomPainter {
  final double rotationAngle;

  _CancelDicePainter({this.rotationAngle = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width * 0.5, size.height * 0.5);
    canvas.rotate(rotationAngle);

    final s = size.width * 0.45;

    // Top Face
    final topFace = Path()
      ..moveTo(0, -s)
      ..lineTo(s, -s * 0.5)
      ..lineTo(0, 0)
      ..lineTo(-s, -s * 0.5)
      ..close();
    canvas.drawPath(topFace, Paint()..color = Colors.white);

    // Left Face
    final leftFace = Path()
      ..moveTo(-s, -s * 0.5)
      ..lineTo(0, 0)
      ..lineTo(0, s)
      ..lineTo(-s, s * 0.5)
      ..close();
    canvas.drawPath(leftFace, Paint()..color = const Color(0xFFD6DBDF));

    // Right Face
    final rightFace = Path()
      ..moveTo(0, 0)
      ..lineTo(s, -s * 0.5)
      ..lineTo(s, s * 0.5)
      ..lineTo(0, s)
      ..close();
    canvas.drawPath(rightFace, Paint()..color = const Color(0xFFAEB6BF));

    // Pips
    final pipPaint = Paint()..color = const Color(0xFF0A1224);
    canvas.drawCircle(Offset(0, -s * 0.5), 2.0, pipPaint);
    canvas.drawCircle(Offset(-s * 0.5, s * 0.1), 1.6, pipPaint);
    canvas.drawCircle(Offset(-s * 0.5, s * 0.35), 1.6, pipPaint);
    canvas.drawCircle(Offset(s * 0.5, s * 0.1), 1.6, pipPaint);
    canvas.drawCircle(Offset(s * 0.5, s * 0.35), 1.6, pipPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3D Red and White Announcement Megaphone Painter
class _MegaphonePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Yellow/Golden Sound Wave Rays
    final rayPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawArc(
      Rect.fromCircle(center: const Offset(42, 28), radius: 14),
      -math.pi * 0.35,
      math.pi * 0.7,
      false,
      rayPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(42, 28), radius: 20),
      -math.pi * 0.35,
      math.pi * 0.7,
      false,
      rayPaint,
    );

    // 2. Megaphone Cone (Red and White)
    final conePath = Path()
      ..moveTo(12, 24)
      ..lineTo(38, 14)
      ..lineTo(38, 42)
      ..lineTo(12, 32)
      ..close();

    final conePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF1744), Color(0xFFD50000), Color(0xFF8B0000)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(const Rect.fromLTWH(12, 14, 26, 28));
    canvas.drawPath(conePath, conePaint);

    // Middle White Band on Cone
    final whiteBand = Path()
      ..moveTo(22, 20)
      ..lineTo(30, 17)
      ..lineTo(30, 39)
      ..lineTo(22, 36)
      ..close();
    canvas.drawPath(whiteBand, Paint()..color = Colors.white);

    // Flared Horn Rim
    final rimPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFDE7), Color(0xFFFFEA79), Color(0xFFFFB300)],
      ).createShader(const Rect.fromLTWH(36, 12, 8, 32));
    canvas.drawOval(const Rect.fromLTWH(35, 12, 7, 32), rimPaint);

    // Small Rear Cap
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(7, 23, 7, 10), const Radius.circular(3)),
      Paint()..color = const Color(0xFFFF5252),
    );

    // Handle
    final handlePath = Path()
      ..moveTo(18, 30)
      ..lineTo(14, 46)
      ..lineTo(20, 48)
      ..lineTo(24, 32)
      ..close();
    canvas.drawPath(handlePath, Paint()..color = const Color(0xFFD50000));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Comic Energy Whiskers Painter (\ | /)
class _ComicWhiskersPainter extends CustomPainter {
  final bool isLeft;

  _ComicWhiskersPainter({required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.save();
    if (!isLeft) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }

    canvas.drawLine(const Offset(2, 2), const Offset(16, 7), paint);
    canvas.drawLine(const Offset(0, 8), const Offset(15, 8), paint);
    canvas.drawLine(const Offset(2, 14), const Offset(16, 9), paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
