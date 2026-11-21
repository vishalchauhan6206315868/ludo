import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Attractive 3D Royal Game Exit Dialog matching reference aesthetics
class GameExitDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? highlightText;
  final String cancelText;
  final String confirmText;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;

  const GameExitDialog({
    super.key,
    this.title = "Exit to Main Menu?",
    this.message =
        "Your current match progress is saved automatically. You can resume anytime from the home screen.",
    this.highlightText = "saved automatically",
    this.cancelText = "Continue Playing",
    this.confirmText = "Save & Exit",
    this.onCancel,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Bottom Exterior Ambient Pawns (Green on left, Blue on right)
              const Positioned(
                bottom: -10,
                left: -12,
                child: CustomPaint(
                  size: Size(34, 46),
                  painter: _ExteriorPawnPainter(color: Color(0xFF00E676)),
                ),
              ),
              const Positioned(
                bottom: -10,
                right: -12,
                child: CustomPaint(
                  size: Size(34, 46),
                  painter: _ExteriorPawnPainter(color: Color(0xFF00B0FF)),
                ),
              ),

              // Main Dialog Beveled Outer Container
              Container(
                margin: const EdgeInsets.only(top: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFFDE7),
                      Color(0xFFFFD54F),
                      Color(0xFFFFB300),
                      Color(0xFFFF8F00),
                      Color(0xFF6D3800),
                      Color(0xFFFFD54F),
                    ],
                    stops: [0.0, 0.20, 0.45, 0.70, 0.90, 1.0],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.45),
                      blurRadius: 26,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: const Color(0xFF0072FF).withValues(alpha: 0.45),
                      blurRadius: 22,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.85),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(3.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 1.0,
                    ),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF0B2568),
                        Color(0xFF081C52),
                        Color(0xFF040F2E),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Specular Gloss Overlay at the Top
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 55,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(23),
                              topRight: Radius.circular(23),
                            ),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.22),
                                Colors.white.withValues(alpha: 0.04),
                                Colors.transparent,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),

                      // Card Content
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 28, 14, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 12),

                            // Mascot, Information & Speed Dice Row
                            _buildBodySection(context),

                            const SizedBox(height: 14),

                            // Golden Star Divider
                            _buildStarDivider(),

                            const SizedBox(height: 14),

                            // Dual Action Buttons: Continue Playing vs Save & Exit
                            _buildActionButtons(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Top Arched Title Banner with 3D Jeweled Crown
              Positioned(
                top: 0,
                child: _buildCrownAndTitleBanner(),
              ),

              // Top-Right 3D Red Circular Close Button (X)
              Positioned(
                top: 14,
                right: 4,
                child: _buildCloseButton(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Crown atop Title Banner
  Widget _buildCrownAndTitleBanner() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Title Capsule Banner
        Container(
          margin: const EdgeInsets.only(top: 14),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFFFD54F),
              width: 2.2,
            ),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF29B6F6),
                Color(0xFF0288D1),
                Color(0xFF01579B),
                Color(0xFF052163),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00B0FF).withValues(alpha: 0.65),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                shadows: [
                  Shadow(
                    color: Color(0xFFFFD54F),
                    blurRadius: 10,
                  ),
                  Shadow(
                    color: Colors.black87,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 3D Jeweled Golden Crown with Ruby
        const Positioned(
          top: -12,
          child: CustomPaint(
            size: Size(54, 30),
            painter: _CrownWithRubyPainter(),
          ),
        ),
      ],
    );
  }

  /// Circular 3D Red Close Button (X)
  Widget _buildCloseButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          try {
            HapticFeedback.selectionClick();
          } catch (_) {}
          if (onCancel != null) {
            onCancel!();
          } else {
            Navigator.pop(context, false);
          }
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFF5252),
                Color(0xFFE53935),
                Color(0xFFB71C1C),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD50000).withValues(alpha: 0.7),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 20,
              weight: 800,
            ),
          ),
        ),
      ),
    );
  }

  /// Mascot, Center Message & Speed Dice Row
  Widget _buildBodySection(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left: 3D Cute Red Pawn Mascot
        const CustomPaint(
          size: Size(62, 74),
          painter: _CuteRedPawnMascotPainter(),
        ),

        const SizedBox(width: 8),

        // Center: Formatted description text
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: _buildRichMessage(),
          ),
        ),

        const SizedBox(width: 8),

        // Right: 3D Speed Dice with Cyan Glow Trail
        const CustomPaint(
          size: Size(54, 62),
          painter: _SpeedDicePainter(),
        ),
      ],
    );
  }

  /// Rich message formatting with radiant yellow highlight
  Widget _buildRichMessage() {
    if (highlightText == null ||
        highlightText!.isEmpty ||
        !message.contains(highlightText!)) {
      return Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13.0,
          fontWeight: FontWeight.w600,
          height: 1.35,
          shadows: [
            Shadow(
              color: Colors.black87,
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
      );
    }

    final parts = message.split(highlightText!);
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13.0,
          fontWeight: FontWeight.w600,
          height: 1.35,
          shadows: [
            Shadow(
              color: Colors.black87,
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        children: [
          if (parts.isNotEmpty) TextSpan(text: parts[0]),
          TextSpan(
            text: highlightText,
            style: const TextStyle(
              color: Color(0xFFFFEB3B),
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                  color: Color(0xFFFFD54F),
                  blurRadius: 8,
                ),
                Shadow(
                  color: Colors.black,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
          if (parts.length > 1) TextSpan(text: parts[1]),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Golden Star Divider
  Widget _buildStarDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1.2,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Color(0xFFFFD54F),
                ],
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Icon(
            Icons.star_rounded,
            color: Color(0xFFFFD54F),
            size: 18,
            shadows: [
              Shadow(
                color: Color(0xFFFFD54F),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            height: 1.2,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFD54F),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Dual 3D Buttons: Continue Playing (Cyan) & Save & Exit (Gold)
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Continue Playing Button
        Expanded(
          child: GestureDetector(
            onTap: () {
              try {
                HapticFeedback.lightImpact();
              } catch (_) {}
              if (onCancel != null) {
                onCancel!();
              } else {
                Navigator.pop(context, false);
              }
            },
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF80D8FF),
                  width: 1.4,
                ),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF00E5FF),
                    Color(0xFF0091EA),
                    Color(0xFF0D47A1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00B0FF).withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.home_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        cancelText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
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

        const SizedBox(width: 10),

        // Save & Exit Button
        Expanded(
          child: GestureDetector(
            onTap: () {
              try {
                HapticFeedback.mediumImpact();
              } catch (_) {}
              if (onConfirm != null) {
                onConfirm!();
              } else {
                Navigator.pop(context, true);
              }
            },
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFFFFDE7),
                  width: 1.4,
                ),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFF59D),
                    Color(0xFFFFD54F),
                    Color(0xFFFF8F00),
                    Color(0xFFE65100),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8F00).withValues(alpha: 0.65),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.exit_to_app_rounded,
                        color: Color(0xFF2E1100),
                        size: 20,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        confirmText,
                        style: const TextStyle(
                          color: Color(0xFF2E1100),
                          fontSize: 14.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
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

// ---------------------------------------------------------------------------
// 3D Custom Painters: Crown with Ruby, Mascot Pawn, Speed Dice, Exterior Pawn
// ---------------------------------------------------------------------------

/// 3D Jeweled Golden Crown with center Ruby Gemstone
class _CrownWithRubyPainter extends CustomPainter {
  const _CrownWithRubyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Golden Sunburst Flare Behind Crown
    final rayPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD54F).withValues(alpha: 0.6),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(w * 0.5, h * 0.6),
        radius: w * 0.55,
      ));
    canvas.drawCircle(Offset(w * 0.5, h * 0.6), w * 0.5, rayPaint);

    // Crown Body Path
    final path = Path()
      ..moveTo(w * 0.12, h * 0.88)
      ..lineTo(w * 0.05, h * 0.35)
      ..lineTo(w * 0.28, h * 0.60)
      ..lineTo(w * 0.50, h * 0.10)
      ..lineTo(w * 0.72, h * 0.60)
      ..lineTo(w * 0.95, h * 0.35)
      ..lineTo(w * 0.88, h * 0.88)
      ..close();

    final crownPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFFDE7),
          Color(0xFFFFE082),
          Color(0xFFFFB300),
          Color(0xFFC45A00),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // Shadow
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.7), 4, true);
    canvas.drawPath(path, crownPaint);

    // Crown Peak Pearl Jewels
    final pearlPaint = Paint()..color = const Color(0xFFFFF9C4);
    canvas.drawCircle(Offset(w * 0.05, h * 0.35), 2.8, pearlPaint);
    canvas.drawCircle(Offset(w * 0.50, h * 0.10), 3.8, pearlPaint);
    canvas.drawCircle(Offset(w * 0.95, h * 0.35), 2.8, pearlPaint);

    // Center Ruby Gemstone on the Crown Base
    final rubyCenter = Offset(w * 0.50, h * 0.76);
    final rubyBasePaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFFFF5252),
          Color(0xFFD50000),
          Color(0xFF880E4F),
        ],
      ).createShader(Rect.fromCircle(center: rubyCenter, radius: 4.5));

    // Ruby gold rim
    canvas.drawCircle(
      rubyCenter,
      5.2,
      Paint()
        ..color = const Color(0xFFFFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(rubyCenter, 4.2, rubyBasePaint);

    // Ruby Glint
    canvas.drawCircle(
      Offset(rubyCenter.dx - 1.2, rubyCenter.dy - 1.2),
      1.2,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Cute 3D Red Pawn Mascot with Eyes, Smile and Thumbs-up Gesture
class _CuteRedPawnMascotPainter extends CustomPainter {
  const _CuteRedPawnMascotPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final redGradient = const LinearGradient(
      colors: [
        Color(0xFFFF8A80),
        Color(0xFFFF1744),
        Color(0xFFD50000),
        Color(0xFF880E4F),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    // 1. Base Pedestal
    final baseRect = Rect.fromLTWH(w * 0.10, h * 0.75, w * 0.65, h * 0.18);
    final baseRRect = RRect.fromRectAndRadius(baseRect, const Radius.circular(8));
    final basePaint = Paint()
      ..shader = redGradient.createShader(baseRect);

    canvas.drawRRect(
      baseRRect.shift(const Offset(0, 3)),
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );
    canvas.drawRRect(baseRRect, basePaint);

    // 2. Middle Body Cone
    final bodyPath = Path()
      ..moveTo(w * 0.22, h * 0.75)
      ..lineTo(w * 0.32, h * 0.44)
      ..lineTo(w * 0.52, h * 0.44)
      ..lineTo(w * 0.62, h * 0.75)
      ..close();

    final bodyPaint = Paint()
      ..shader = redGradient.createShader(Rect.fromLTWH(w * 0.2, h * 0.44, w * 0.45, h * 0.35));
    canvas.drawPath(bodyPath, bodyPaint);

    // Body Specular Highlight
    canvas.drawLine(
      Offset(w * 0.30, h * 0.72),
      Offset(w * 0.36, h * 0.47),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    // 3. Head Sphere
    final headCenter = Offset(w * 0.42, h * 0.32);
    final headRadius = w * 0.24;
    final headRect = Rect.fromCircle(center: headCenter, radius: headRadius);
    final headPaint = Paint()..shader = redGradient.createShader(headRect);

    canvas.drawCircle(
      headCenter.translate(0, 2),
      headRadius,
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );
    canvas.drawCircle(headCenter, headRadius, headPaint);

    // Head Glint
    canvas.drawCircle(
      Offset(headCenter.dx - 6, headCenter.dy - 6),
      3.5,
      Paint()..color = Colors.white.withValues(alpha: 0.75),
    );

    // 4. Cartoon Eyes (Big, Expressive)
    final leftEyeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.36, h * 0.30), width: 7.5, height: 11),
      const Radius.circular(4),
    );
    final rightEyeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.48, h * 0.30), width: 7.5, height: 11),
      const Radius.circular(4),
    );

    // White Sclera
    canvas.drawRRect(leftEyeRect, Paint()..color = Colors.white);
    canvas.drawRRect(rightEyeRect, Paint()..color = Colors.white);

    // Black Pupils
    canvas.drawCircle(Offset(w * 0.37, h * 0.30), 2.5, Paint()..color = Colors.black87);
    canvas.drawCircle(Offset(w * 0.49, h * 0.30), 2.5, Paint()..color = Colors.black87);

    // White Catchlights
    canvas.drawCircle(Offset(w * 0.36, h * 0.28), 1.0, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(w * 0.48, h * 0.28), 1.0, Paint()..color = Colors.white);

    // 5. Smiling Mouth
    final smilePath = Path()
      ..moveTo(w * 0.36, h * 0.38)
      ..quadraticBezierTo(w * 0.42, h * 0.44, w * 0.48, h * 0.38);

    canvas.drawPath(
      smilePath,
      Paint()
        ..color = const Color(0xFF4A0000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );

    // 6. White-Gloved Hand with Thumbs-up
    final glovePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final gloveBorder = Paint()
      ..color = const Color(0xFF9E9E9E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Arm line
    canvas.drawLine(
      Offset(w * 0.50, h * 0.55),
      Offset(w * 0.68, h * 0.52),
      Paint()
        ..color = const Color(0xFFD50000)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    // Glove Palm
    final palmCenter = Offset(w * 0.74, h * 0.52);
    canvas.drawCircle(palmCenter, 6.0, glovePaint);
    canvas.drawCircle(palmCenter, 6.0, gloveBorder);

    // Upright Thumb
    final thumbRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.76, h * 0.43), width: 5.5, height: 11),
      const Radius.circular(3),
    );
    canvas.drawRRect(thumbRect, glovePaint);
    canvas.drawRRect(thumbRect, gloveBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3D Speed Dice with Cyan Energy Swoosh Trails
class _SpeedDicePainter extends CustomPainter {
  const _SpeedDicePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Cyan Energy Speed Swoosh
    final trailPaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Colors.transparent,
          Color(0xFF00E5FF),
          Color(0xFF40C4FF),
          Colors.transparent,
        ],
        stops: [0.0, 0.45, 0.85, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final swooshPath = Path()
      ..moveTo(w * 0.10, h * 0.85)
      ..cubicTo(w * 0.70, h * 0.95, w * 0.95, h * 0.50, w * 0.75, h * 0.15);
    canvas.drawPath(swooshPath, trailPaint);

    // Second faint cyan streak
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.30, h * 0.78)
        ..cubicTo(w * 0.85, h * 0.80, w * 0.98, h * 0.40, w * 0.65, h * 0.22),
      Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // 3D Isometric Dice Cube (Centered around w * 0.52, h * 0.50)
    final diceCenter = Offset(w * 0.50, h * 0.50);
    final diceSize = w * 0.52;

    // Dice Body RRect
    final diceRect = Rect.fromCenter(
      center: diceCenter,
      width: diceSize,
      height: diceSize,
    );
    final diceRRect = RRect.fromRectAndRadius(diceRect, const Radius.circular(8));

    // Drop shadow
    canvas.drawRRect(
      diceRRect.shift(const Offset(2, 4)),
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );

    // White Porcelain Cube Face Gradient
    final cubePaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFF5F5F5),
          Color(0xFFCFD8DC),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(diceRect);

    canvas.drawRRect(diceRRect, cubePaint);
    canvas.drawRRect(
      diceRRect,
      Paint()
        ..color = const Color(0xFFB0BEC5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Dice Pips (5 dots pattern)
    final pipPaint = Paint()..color = const Color(0xFF263238);
    final pipRadius = diceSize * 0.08;

    // Center
    canvas.drawCircle(diceCenter, pipRadius, pipPaint);
    // Top-Left
    canvas.drawCircle(
      Offset(diceCenter.dx - diceSize * 0.26, diceCenter.dy - diceSize * 0.26),
      pipRadius,
      pipPaint,
    );
    // Top-Right
    canvas.drawCircle(
      Offset(diceCenter.dx + diceSize * 0.26, diceCenter.dy - diceSize * 0.26),
      pipRadius,
      pipPaint,
    );
    // Bottom-Left
    canvas.drawCircle(
      Offset(diceCenter.dx - diceSize * 0.26, diceCenter.dy + diceSize * 0.26),
      pipRadius,
      pipPaint,
    );
    // Bottom-Right
    canvas.drawCircle(
      Offset(diceCenter.dx + diceSize * 0.26, diceCenter.dy + diceSize * 0.26),
      pipRadius,
      pipPaint,
    );

    // Specular Highlight Glint on Dice Corner
    canvas.drawCircle(
      Offset(diceCenter.dx - diceSize * 0.32, diceCenter.dy - diceSize * 0.32),
      2.0,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3D Exterior Glossy Pawn Painter (For Bottom Corners)
class _ExteriorPawnPainter extends CustomPainter {
  final Color color;
  const _ExteriorPawnPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final gradient = LinearGradient(
      colors: [
        Colors.white.withValues(alpha: 0.9),
        color,
        HSLColor.fromColor(color).withLightness(0.25).toColor(),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    // Base Oval
    final baseRect = Rect.fromLTWH(w * 0.1, h * 0.72, w * 0.8, h * 0.24);
    canvas.drawOval(baseRect.shift(const Offset(0, 3)),
        Paint()..color = Colors.black.withValues(alpha: 0.6));
    canvas.drawOval(baseRect, Paint()..shader = gradient.createShader(baseRect));

    // Cone Body
    final path = Path()
      ..moveTo(w * 0.22, h * 0.75)
      ..lineTo(w * 0.38, h * 0.42)
      ..lineTo(w * 0.62, h * 0.42)
      ..lineTo(w * 0.78, h * 0.75)
      ..close();
    canvas.drawPath(path, Paint()..shader = gradient.createShader(baseRect));

    // Head Sphere
    final headCenter = Offset(w * 0.5, h * 0.28);
    final headRadius = w * 0.26;
    final headRect = Rect.fromCircle(center: headCenter, radius: headRadius);
    canvas.drawCircle(headCenter.translate(0, 2), headRadius,
        Paint()..color = Colors.black.withValues(alpha: 0.4));
    canvas.drawCircle(headCenter, headRadius,
        Paint()..shader = gradient.createShader(headRect));

    // Specular Glint
    canvas.drawCircle(
      Offset(headCenter.dx - 3, headCenter.dy - 3),
      2.2,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
