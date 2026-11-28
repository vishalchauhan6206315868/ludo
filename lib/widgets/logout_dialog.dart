import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Attractive 3D Royal Gaming Confirmation Dialog for Exit / Logout.
/// Matches the Royal Blue & Gold theme with 5-point jeweled crown,
/// cream-gold parchment body, 3D pill action buttons, pawns, and twin glowing dice.
class LogoutDialog extends StatelessWidget {
  const LogoutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final viewInsets = mediaQuery.viewInsets.bottom;
    final maxHeight = (screenHeight * 0.90) - viewInsets;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 390,
          maxHeight: maxHeight.clamp(320.0, 680.0),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              // Main Dialog Body Card
              Container(
                margin: const EdgeInsets.only(top: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: const Color(0xFFFFD54F),
                    width: 3.5,
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFFDF5),
                      Color(0xFFFFF8E7),
                      Color(0xFFFFF2D0),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.5),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top spacing beneath the floating header ribbon
                      const SizedBox(height: 52),

                      // Dialog Content Row (Question Bubble + Confirmation Text)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 3D Question Mark Chat Bubble
                            const _QuestionBubbleBadge(),

                            const SizedBox(width: 14),

                            // Confirmation Message Text
                            Expanded(
                              child: Text.rich(
                                const TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "Are you sure you want to\nlog out of ",
                                      style: TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        height: 1.3,
                                      ),
                                    ),
                                    TextSpan(
                                      text: "Ludo Supreme Pro",
                                      style: TextStyle(
                                        color: Color(0xFF0052D4),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    TextSpan(
                                      text: "?",
                                      style: TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Subtle decorative gold arc divider
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 36),
                        child: Container(
                          height: 2.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                const Color(0xFFFFD54F).withValues(alpha: 0.8),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // 3D Capsule Action Buttons (Cancel vs Logout)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            // Cancel Button (3D Royal Blue / Cyan)
                            Expanded(
                              child: _PillGameButton(
                                key: const Key('logout_dialog_cancel_button'),
                                label: "Cancel",
                                icon: Icons.close_rounded,
                                gradientColors: const [
                                  Color(0xFF00B0FF),
                                  Color(0xFF0070F3),
                                  Color(0xFF0044CC),
                                ],
                                borderColor: const Color(0xFF80D8FF),
                                shadowColor: const Color(0xFF0070F3),
                                textShadowColor: const Color(0xFF002F87),
                                onPressed: () => Navigator.of(context).pop(false),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Logout Button (3D Crimson Red)
                            Expanded(
                              child: _PillGameButton(
                                key: const Key('logout_dialog_confirm_button'),
                                label: "Logout",
                                icon: Icons.logout_rounded,
                                gradientColors: const [
                                  Color(0xFFFF3333),
                                  Color(0xFFE50000),
                                  Color(0xFFB30000),
                                ],
                                borderColor: const Color(0xFFFF8A80),
                                shadowColor: const Color(0xFFE50000),
                                textShadowColor: const Color(0xFF7F0000),
                                onPressed: () => Navigator.of(context).pop(true),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Festive Bottom Footer (Pawns + Twin Glowing Dice + Board)
                      const _LogoutFooterIllustration(),
                    ],
                  ),
                ),
              ),

              // Top 3D Header Ribbon with Banner Ears & 5-Point Crown
              Positioned(
                top: 0,
                left: 12,
                right: 12,
                child: _buildHeaderRibbonWithCrown(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the 3D Header Ribbon with side folds and the central 5-point royal crown
  Widget _buildHeaderRibbonWithCrown() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // 1. Central 5-Point Royal Crown
        const Positioned(
          top: -24,
          child: _RoyalCrownWidget(),
        ),

        // 2. Main Ribbon Banner
        Container(
          margin: const EdgeInsets.only(top: 14),
          child: CustomPaint(
            painter: _RibbonBannerPainter(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Gold Logout / Exit Icon
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD54F).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFFD54F),
                          width: 1.8,
                        ),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFFFD54F),
                        size: 22,
                      ),
                    ),

                    const SizedBox(width: 10),

                    // 3D Header Title: "Exit / Logout"
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // "Exit " in 3D White
                        Text(
                          "Exit ",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            shadows: [
                              const Shadow(
                                color: Color(0xFF001E5B),
                                offset: Offset(0, 3),
                                blurRadius: 2,
                              ),
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                offset: const Offset(0, 4),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                        ),
                        // "/ " in White
                        Text(
                          "/ ",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                offset: const Offset(0, 3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        // "Logout" in 3D Gold
                        Text(
                          "Logout",
                          style: TextStyle(
                            color: const Color(0xFFFFD54F),
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            shadows: [
                              const Shadow(
                                color: Color(0xFF944F00),
                                offset: Offset(0, 3),
                                blurRadius: 2,
                              ),
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                offset: const Offset(0, 4),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 3. Top Corner Yellow Sparkle Bursts
        Positioned(
          left: 4,
          top: 10,
          child: _buildSparkleCluster(isLeft: true),
        ),
        Positioned(
          right: 4,
          top: 10,
          child: _buildSparkleCluster(isLeft: false),
        ),
      ],
    );
  }

  /// Builds yellow corner sparks / rays
  Widget _buildSparkleCluster({required bool isLeft}) {
    return Transform.scale(
      scaleX: isLeft ? 1 : -1,
      child: SizedBox(
        width: 24,
        height: 24,
        child: CustomPaint(
          painter: _SparkleClusterPainter(),
        ),
      ),
    );
  }
}

/// Custom painter for corner festive rays/sparks
class _SparkleClusterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    // Ray 1
    canvas.drawLine(const Offset(4, 18), const Offset(12, 10), paint);
    // Ray 2
    canvas.drawLine(const Offset(10, 22), const Offset(20, 16), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom Painter for 3D Royal Blue Ribbon with folded ribbon wings
class _RibbonBannerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Outer Drop Shadow for Ribbon
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    // Left Ribbon Wing
    final leftWingPath = Path()
      ..moveTo(16, 8)
      ..lineTo(-6, 2)
      ..lineTo(2, h * 0.5)
      ..lineTo(-6, h - 2)
      ..lineTo(16, h - 8)
      ..close();
    canvas.drawPath(leftWingPath.shift(const Offset(0, 3)), shadowPaint);

    final wingShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0052D4), Color(0xFF002D80)],
    ).createShader(Rect.fromLTWH(-6, 0, 22, h));
    canvas.drawPath(leftWingPath, Paint()..shader = wingShader);

    // Right Ribbon Wing
    final rightWingPath = Path()
      ..moveTo(w - 16, 8)
      ..lineTo(w + 6, 2)
      ..lineTo(w - 2, h * 0.5)
      ..lineTo(w + 6, h - 2)
      ..lineTo(w - 16, h - 8)
      ..close();
    canvas.drawPath(rightWingPath.shift(const Offset(0, 3)), shadowPaint);

    final rightWingShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0052D4), Color(0xFF002D80)],
    ).createShader(Rect.fromLTWH(w - 16, 0, 22, h));
    canvas.drawPath(rightWingPath, Paint()..shader = rightWingShader);

    // Main Center Banner
    final bannerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(8, 0, w - 16, h),
      const Radius.circular(22),
    );

    // Center Banner Shadow
    canvas.drawRRect(bannerRect.shift(const Offset(0, 4)), shadowPaint);

    // Main Banner Gradient (Royal Blue)
    final bannerShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF0084FF),
        Color(0xFF0052D4),
        Color(0xFF0033A0),
      ],
    ).createShader(bannerRect.outerRect);

    canvas.drawRRect(bannerRect, Paint()..shader = bannerShader);

    // Electric Cyan & Gold Double Glowing Border
    final cyanBorder = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    canvas.drawRRect(bannerRect, cyanBorder);

    final goldInnerBorder = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(10, 2, w - 20, h - 4),
        const Radius.circular(20),
      ),
      goldInnerBorder,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 5-Point Royal Golden Crown with Ruby & Sapphire Gemstones
class _RoyalCrownWidget extends StatelessWidget {
  const _RoyalCrownWidget();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(64, 46),
      painter: _LogoutCrownPainter(),
    );
  }
}

class _LogoutCrownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Crown Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    // 5-Point Crown Body Path
    final crownPath = Path()
      ..moveTo(w * 0.12, h * 0.88)
      // Peak 1 (Leftmost, small)
      ..lineTo(w * 0.08, h * 0.44)
      // Valley 1
      ..lineTo(w * 0.22, h * 0.60)
      // Peak 2 (Mid-left, medium)
      ..lineTo(w * 0.28, h * 0.25)
      // Valley 2
      ..lineTo(w * 0.40, h * 0.54)
      // Peak 3 (Center, tallest)
      ..lineTo(w * 0.50, h * 0.08)
      // Valley 3
      ..lineTo(w * 0.60, h * 0.54)
      // Peak 4 (Mid-right, medium)
      ..lineTo(w * 0.72, h * 0.25)
      // Valley 4
      ..lineTo(w * 0.78, h * 0.60)
      // Peak 5 (Rightmost, small)
      ..lineTo(w * 0.92, h * 0.44)
      // Bottom Right
      ..lineTo(w * 0.88, h * 0.88)
      ..close();

    canvas.drawPath(crownPath.shift(const Offset(0, 2)), shadowPaint);

    // Crown Body Gold Shader
    final goldShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFFF59D),
        Color(0xFFFFD54F),
        Color(0xFFFFA000),
        Color(0xFFFF6F00),
      ],
      stops: [0.0, 0.35, 0.70, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(crownPath, Paint()..shader = goldShader);

    // Crown Base Rim
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.10, h * 0.74, w * 0.80, h * 0.18),
      const Radius.circular(5),
    );
    final rimShader = const LinearGradient(
      colors: [Color(0xFFFFECB3), Color(0xFFFFB300), Color(0xFFE65100)],
    ).createShader(baseRect.outerRect);
    canvas.drawRRect(baseRect, Paint()..shader = rimShader);
    canvas.drawRRect(
      baseRect,
      Paint()
        ..color = const Color(0xFFFFF9C4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Pearls at 5 Peaks
    final pearlShader = const RadialGradient(
      colors: [Colors.white, Color(0xFFFFD54F), Color(0xFFFF8F00)],
    ).createShader(Rect.fromLTWH(0, 0, w, h));
    final pearlPaint = Paint()..shader = pearlShader;

    canvas.drawCircle(Offset(w * 0.08, h * 0.44), 3.0, pearlPaint);
    canvas.drawCircle(Offset(w * 0.28, h * 0.25), 3.5, pearlPaint);
    canvas.drawCircle(Offset(w * 0.50, h * 0.08), 4.2, pearlPaint);
    canvas.drawCircle(Offset(w * 0.72, h * 0.25), 3.5, pearlPaint);
    canvas.drawCircle(Offset(w * 0.92, h * 0.44), 3.0, pearlPaint);

    // Center Ruby Gemstone (Red Diamond)
    final rubyCenter = Offset(w * 0.50, h * 0.40);
    final rubyPath = Path()
      ..moveTo(rubyCenter.dx, rubyCenter.dy - 5.5)
      ..lineTo(rubyCenter.dx + 5.0, rubyCenter.dy)
      ..lineTo(rubyCenter.dx, rubyCenter.dy + 5.5)
      ..lineTo(rubyCenter.dx - 5.0, rubyCenter.dy)
      ..close();

    final rubyShader = const RadialGradient(
      colors: [Color(0xFFFF8A80), Color(0xFFE53935), Color(0xFFB71C1C)],
    ).createShader(Rect.fromCircle(center: rubyCenter, radius: 6));
    canvas.drawPath(rubyPath, Paint()..shader = rubyShader);
    canvas.drawPath(
      rubyPath,
      Paint()
        ..color = const Color(0xFFFFCDD2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // Side Sapphire Gemstones (Blue Diamonds) on peaks 2 and 4
    final sapphireShader = const RadialGradient(
      colors: [Color(0xFF82B1FF), Color(0xFF1976D2), Color(0xFF0D47A1)],
    ).createShader(Rect.fromLTWH(0, 0, w, h));
    final sapphirePaint = Paint()..shader = sapphireShader;

    // Left Sapphire
    final leftSap = Offset(w * 0.28, h * 0.46);
    canvas.drawCircle(leftSap, 2.8, sapphirePaint);
    canvas.drawCircle(
      leftSap,
      2.8,
      Paint()
        ..color = Colors.white70
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );

    // Right Sapphire
    final rightSap = Offset(w * 0.72, h * 0.46);
    canvas.drawCircle(rightSap, 2.8, sapphirePaint);
    canvas.drawCircle(
      rightSap,
      2.8,
      Paint()
        ..color = Colors.white70
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Circular Royal Blue Question Mark Chat Bubble Badge
class _QuestionBubbleBadge extends StatelessWidget {
  const _QuestionBubbleBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 54,
      child: CustomPaint(
        painter: _QuestionBubblePainter(),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text(
              "?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(
                    color: Color(0xFF002B7A),
                    offset: Offset(0, 2),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionBubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Chat bubble with little tail on bottom-left
    final bubblePath = Path()
      ..addOval(Rect.fromLTWH(0, 0, w, h - 6))
      ..moveTo(8, h * 0.65)
      ..lineTo(2, h)
      ..lineTo(18, h * 0.75)
      ..close();

    // Soft drop shadow
    canvas.drawPath(
      bubblePath.shift(const Offset(0, 3)),
      Paint()
        ..color = const Color(0x550052D4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Gradient fill (Royal Blue)
    final bubbleShader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0091FF), Color(0xFF0052D4), Color(0xFF0038A8)],
    ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(bubblePath, Paint()..shader = bubbleShader);

    // Thick White Border
    canvas.drawPath(
      bubblePath,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3D Capsule / Pill Game Button
class _PillGameButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Color> gradientColors;
  final Color borderColor;
  final Color shadowColor;
  final Color textShadowColor;
  final VoidCallback onPressed;

  const _PillGameButton({
    super.key,
    required this.label,
    required this.icon,
    required this.gradientColors,
    required this.borderColor,
    required this.shadowColor,
    required this.textShadowColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
        border: Border.all(
          color: borderColor,
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 22,
                shadows: [
                  Shadow(
                    color: textShadowColor,
                    offset: const Offset(0, 2),
                    blurRadius: 2,
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  letterSpacing: 0.3,
                  shadows: [
                    Shadow(
                      color: textShadowColor,
                      offset: const Offset(0, 2),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Festive Bottom Footer Illustration featuring:
/// - Red Pawn (Bottom Left)
/// - Green Pawn (Bottom Right)
/// - Twin 3D Glowing White Ludo Dice in the center with golden rays & sparks
/// - Curved Ludo board track beneath
class _LogoutFooterIllustration extends StatelessWidget {
  const _LogoutFooterIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 110,
      child: CustomPaint(
        painter: _LogoutFooterPainter(),
      ),
    );
  }
}

class _LogoutFooterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Golden Aura Rays behind Twin Dice
    _drawTwinDiceAura(canvas, Offset(w * 0.50, h * 0.56), 55);

    // 2. Curved Ludo Board Segment at bottom
    _drawCurvedLudoBoard(canvas, w, h);

    // 3. Red Pawn on Left
    _drawGlossyPawn(
      canvas,
      position: Offset(w * 0.12, h * 0.62),
      baseColor: const Color(0xFFE53935),
      darkColor: const Color(0xFFB71C1C),
      highlightColor: const Color(0xFFFF8A80),
      scale: 0.95,
    );

    // 4. Green Pawn on Right
    _drawGlossyPawn(
      canvas,
      position: Offset(w * 0.88, h * 0.62),
      baseColor: const Color(0xFF43A047),
      darkColor: const Color(0xFF1B5E20),
      highlightColor: const Color(0xFFB9F6CA),
      scale: 0.95,
    );

    // 5. Twin 3D Isometric White Ludo Dice in Center
    // Left dice (tilted left)
    _drawIsometricDice(
      canvas,
      center: Offset(w * 0.44, h * 0.56),
      size: 20,
      rotation: -0.16,
      topPips: 2,
      leftPips: 3,
      rightPips: 1,
    );

    // Right dice (tilted right)
    _drawIsometricDice(
      canvas,
      center: Offset(w * 0.56, h * 0.54),
      size: 20,
      rotation: 0.18,
      topPips: 5,
      leftPips: 4,
      rightPips: 6,
    );
  }

  /// Draws radiant golden aura and sparks behind the twin dice
  void _drawTwinDiceAura(Canvas canvas, Offset center, double radius) {
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD54F).withValues(alpha: 0.50),
          const Color(0xFFFFA000).withValues(alpha: 0.25),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.3));

    canvas.drawCircle(center, radius * 1.2, auraPaint);

    // Sparkle rays
    final sparkPaint = Paint()
      ..color = const Color(0xFFFFE082).withValues(alpha: 0.85)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3.0) + 0.25;
      final startDist = radius * 0.50;
      final endDist = radius * 0.85;
      final p1 = Offset(center.dx + math.cos(angle) * startDist, center.dy + math.sin(angle) * startDist);
      final p2 = Offset(center.dx + math.cos(angle) * endDist, center.dy + math.sin(angle) * endDist);
      canvas.drawLine(p1, p2, sparkPaint);
    }
  }

  /// Draws the curved Ludo board track across the bottom
  void _drawCurvedLudoBoard(Canvas canvas, double w, double h) {
    final boardPath = Path()
      ..moveTo(0, h * 0.65)
      ..quadraticBezierTo(w * 0.5, h * 0.80, w, h * 0.65)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.save();
    canvas.clipPath(boardPath);

    // Quadrants: Red, Blue, Green, Yellow
    final sections = [
      {'color': const Color(0xFFD32F2F), 'start': 0.0, 'end': 0.25},
      {'color': const Color(0xFF1976D2), 'start': 0.25, 'end': 0.50},
      {'color': const Color(0xFF388E3C), 'start': 0.50, 'end': 0.75},
      {'color': const Color(0xFFFBC02D), 'start': 0.75, 'end': 1.0},
    ];

    for (final sec in sections) {
      final color = sec['color'] as Color;
      final startX = (sec['start'] as double) * w;
      final endX = (sec['end'] as double) * w;

      final rect = Rect.fromLTRB(startX, h * 0.60, endX, h);
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.95),
            color.withValues(alpha: 0.70),
          ],
        ).createShader(rect);
      canvas.drawRect(rect, paint);

      // Tile dividing grid lines
      final gridPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      final tileWidth = (endX - startX) / 3.0;
      for (int i = 1; i < 3; i++) {
        final gx = startX + (i * tileWidth);
        canvas.drawLine(Offset(gx, h * 0.60), Offset(gx, h), gridPaint);
      }
    }

    canvas.restore();

    // Top Glowing Border (Electric Cyan & Gold)
    final topBorderPath = Path()
      ..moveTo(0, h * 0.65)
      ..quadraticBezierTo(w * 0.5, h * 0.80, w, h * 0.65);

    final cyanGlowPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6;
    canvas.drawPath(topBorderPath, cyanGlowPaint);

    final goldAccentPaint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(topBorderPath.shift(const Offset(0, 2)), goldAccentPaint);
  }

  /// Draws a 3D glossy pawn
  void _drawGlossyPawn(
    Canvas canvas, {
    required Offset position,
    required Color baseColor,
    required Color darkColor,
    required Color highlightColor,
    double scale = 1.0,
  }) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.scale(scale);

    // 1. Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 22), width: 26, height: 8),
      shadowPaint,
    );

    // 2. Base Ring
    final baseRect = Rect.fromCenter(center: const Offset(0, 18), width: 24, height: 8.5);
    final baseShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [highlightColor, baseColor, darkColor],
    ).createShader(baseRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(baseRect, const Radius.circular(5)),
      Paint()..shader = baseShader,
    );

    // 3. Body
    final bodyPath = Path()
      ..moveTo(-4, 2)
      ..quadraticBezierTo(-6, 11, -10, 16)
      ..lineTo(10, 16)
      ..quadraticBezierTo(6, 11, 4, 2)
      ..close();

    final bodyRect = Rect.fromLTWH(-10, 2, 20, 14);
    final bodyShader = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [darkColor, highlightColor, baseColor, darkColor],
      stops: const [0.0, 0.35, 0.70, 1.0],
    ).createShader(bodyRect);
    canvas.drawPath(bodyPath, Paint()..shader = bodyShader);

    // 4. Collar
    final collarRect = Rect.fromCenter(center: const Offset(0, 1), width: 13, height: 4);
    final collarShader = LinearGradient(
      colors: [highlightColor, baseColor, darkColor],
    ).createShader(collarRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(collarRect, const Radius.circular(2)),
      Paint()..shader = collarShader,
    );

    // 5. Head
    final headCenter = const Offset(0, -8);
    const headRadius = 8.0;
    final headShader = RadialGradient(
      center: const Alignment(-0.35, -0.40),
      radius: 0.9,
      colors: [
        Colors.white,
        highlightColor,
        baseColor,
        darkColor,
      ],
      stops: const [0.0, 0.25, 0.65, 1.0],
    ).createShader(Rect.fromCircle(center: headCenter, radius: headRadius));
    canvas.drawCircle(headCenter, headRadius, Paint()..shader = headShader);

    canvas.restore();
  }

  /// Draws a 3D isometric dice with custom pips
  void _drawIsometricDice(
    Canvas canvas, {
    required Offset center,
    required double size,
    required double rotation,
    required int topPips,
    required int leftPips,
    required int rightPips,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final s = size;

    // Dice Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.40)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, s * 0.90), width: s * 1.7, height: s * 0.55),
      shadowPaint,
    );

    // Top Face
    final topFace = Path()
      ..moveTo(0, -s * 0.88)
      ..lineTo(s * 0.82, -s * 0.44)
      ..lineTo(0, 0)
      ..lineTo(-s * 0.82, -s * 0.44)
      ..close();
    final topShader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.white, Color(0xFFF1F5F9)],
    ).createShader(Rect.fromLTWH(-s, -s, s * 2, s));
    canvas.drawPath(topFace, Paint()..shader = topShader);

    // Left Face
    final leftFace = Path()
      ..moveTo(-s * 0.82, -s * 0.44)
      ..lineTo(0, 0)
      ..lineTo(0, s * 0.88)
      ..lineTo(-s * 0.82, s * 0.44)
      ..close();
    final leftShader = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
    ).createShader(Rect.fromLTWH(-s, 0, s, s));
    canvas.drawPath(leftFace, Paint()..shader = leftShader);

    // Right Face
    final rightFace = Path()
      ..moveTo(0, 0)
      ..lineTo(s * 0.82, -s * 0.44)
      ..lineTo(s * 0.82, s * 0.44)
      ..lineTo(0, s * 0.88)
      ..close();
    final rightShader = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFFCBD5E1), Color(0xFF94A3B8)],
    ).createShader(Rect.fromLTWH(0, 0, s, s));
    canvas.drawPath(rightFace, Paint()..shader = rightShader);

    // Edge Outlines
    final edgePaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawPath(topFace, edgePaint);
    canvas.drawPath(leftFace, edgePaint);
    canvas.drawPath(rightFace, edgePaint);

    // Pip Paint
    final pipPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    // Draw Top Pips
    _drawFacePips(canvas, Offset(0, -s * 0.44), s * 0.65, topPips, pipPaint);

    // Draw Left Pips
    _drawFacePips(canvas, Offset(-s * 0.40, s * 0.22), s * 0.55, leftPips, pipPaint);

    // Draw Right Pips
    _drawFacePips(canvas, Offset(s * 0.40, s * 0.22), s * 0.55, rightPips, pipPaint);

    canvas.restore();
  }

  void _drawFacePips(Canvas canvas, Offset center, double span, int count, Paint paint) {
    const r = 2.0;
    if (count == 1 || count == 3 || count == 5) {
      canvas.drawCircle(center, r, paint);
    }
    if (count >= 2) {
      canvas.drawCircle(Offset(center.dx - span * 0.35, center.dy - span * 0.20), r, paint);
      canvas.drawCircle(Offset(center.dx + span * 0.35, center.dy + span * 0.20), r, paint);
    }
    if (count >= 4) {
      canvas.drawCircle(Offset(center.dx + span * 0.35, center.dy - span * 0.20), r, paint);
      canvas.drawCircle(Offset(center.dx - span * 0.35, center.dy + span * 0.20), r, paint);
    }
    if (count == 6) {
      canvas.drawCircle(Offset(center.dx - span * 0.35, center.dy), r, paint);
      canvas.drawCircle(Offset(center.dx + span * 0.35, center.dy), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
