import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Premium 3D Gaming Mode Card:
/// - Visual DNA precisely matched to `ludo_supreme_emblem.png`:
///   * Thick 3D metallic beveled golden frame with inner secondary gold rim
///   * Deep Royal Sapphire radial gradient background
///   * Multi-layered ambient golden glow & deep 3D drop shadow
///   * Specular curved glass gloss highlight across upper section
///   * Decorative corner gold studs & 3D golden plaque title banner
///   * Interactive spring press animation (scale-down + glow intensify)
class GameModeCard extends StatefulWidget {
  final Key? cardKey;
  final String title;
  final Widget illustration;
  final VoidCallback onTap;
  final double height;
  final double? width;
  final bool isVertical;
  final Color glowColor;
  final Color accentColor;
  final List<Color>? cardGradient;
  final bool showPedestalShadow;

  const GameModeCard({
    super.key,
    this.cardKey,
    required this.title,
    required this.illustration,
    required this.onTap,
    required this.height,
    this.width,
    this.isVertical = false,
    this.glowColor = const Color(0xFFFFB300),
    this.accentColor = const Color(0xFFFFD700),
    this.cardGradient,
    this.showPedestalShadow = false,
  });

  @override
  State<GameModeCard> createState() => _GameModeCardState();
}

class _GameModeCardState extends State<GameModeCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // Default to the exact Royal Sapphire Radial Gradient of ludo_supreme_emblem.png
    final effectiveColors = widget.cardGradient ??
        const [
          Color(0xFF1544A2), // Vivid Sapphire Center
          Color(0xFF0C2B72), // Deep Royal Navy
          Color(0xFF040F2D), // Midnight Perimeter
        ];

    final cardContent = AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          // 3D Metallic Golden Outer Bevel Frame (matches emblem frame)
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFFDE7), // Bright top highlight
              Color(0xFFFFE082), // Light warm gold
              Color(0xFFFFB300), // Pure golden luster
              Color(0xFFFF8F00), // Amber mid-tone
              Color(0xFF8D4B00), // Deep bronze bevel edge
              Color(0xFFFFD54F), // Bottom reflection
            ],
            stops: [0.0, 0.18, 0.42, 0.68, 0.88, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            // Layer 1: Warm Golden Halo Bloom (matching emblem outer glow)
            BoxShadow(
              color: widget.glowColor.withValues(
                alpha: _isPressed ? 0.65 : 0.42,
              ),
              blurRadius: _isPressed ? 14 : 24,
              spreadRadius: _isPressed ? 1.0 : 3.0,
              offset: const Offset(0, 4),
            ),
            // Layer 2: Deep 3D Drop Shadow (Floating altitude)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.78),
              blurRadius: 18,
              offset: const Offset(0, 9),
            ),
            // Layer 3: Sharp contact rim shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.92),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(3.2), // Physical golden rim thickness
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            // Dual Gold Rim: Secondary inner golden border like the emblem
            border: Border.all(
              color: const Color(0xFFFFD700).withValues(alpha: 0.55),
              width: 1.1,
            ),
            // Deep Radial Sapphire Background
            gradient: RadialGradient(
              center: const Alignment(0.0, -0.2),
              radius: 0.90,
              colors: effectiveColors,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (highlighted) {
                if (mounted) {
                  setState(() => _isPressed = highlighted);
                }
              },
              splashColor: widget.accentColor.withValues(alpha: 0.22),
              highlightColor: Colors.white.withValues(alpha: 0.12),
              child: Stack(
                children: [
                  // 1. Core Card Content (Illustration + 3D Banner)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Upper Illustration Arena
                      Expanded(
                        child: widget.illustration,
                      ),

                      // Lower 3D Golden Plaque Title Banner
                      _buildGoldenTitleBanner(
                        widget.title,
                        isVertical: widget.isVertical,
                      ),
                    ],
                  ),

                  // 2. Glossy Specular Glass Reflection Sheen
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: widget.height * 0.46,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.20),
                              Colors.white.withValues(alpha: 0.05),
                              Colors.transparent,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            stops: const [0.0, 0.48, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 3. Top Specular Highlight Edge Line
                  Positioned(
                    top: 0,
                    left: 14,
                    right: 14,
                    height: 1.5,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.70),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 4. Decorative Golden Corner Rivets / Studs
                  Positioned(
                    top: 5,
                    left: 5,
                    child: _buildCornerStud(),
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: _buildCornerStud(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // If pedestal shadow is requested (for featured PLAY VS COMPUTER)
    if (widget.showPedestalShadow) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            key: widget.cardKey,
            child: cardContent,
          ),
          const SizedBox(height: 6),
          // Soft Floating Golden Pedestal Stage Glow (matches emblem stage)
          Container(
            width: (widget.width ?? 220) * 0.84,
            height: 14,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.elliptical(200, 14)),
              gradient: RadialGradient(
                colors: [
                  widget.glowColor.withValues(alpha: 0.45),
                  const Color(0x3300E5FF),
                  Colors.transparent,
                ],
                radius: 0.85,
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      key: widget.cardKey,
      child: cardContent,
    );
  }

  /// Miniature metallic gold rivet at card corners
  Widget _buildCornerStud() {
    return IgnorePointer(
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [
              Color(0xFFFFFDE7),
              Color(0xFFFFD54F),
              Color(0xFF794000),
            ],
            center: Alignment(-0.3, -0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }

  /// 3D Golden Plaque Title Banner with metallic bevel & crisp outline
  Widget _buildGoldenTitleBanner(String titleText, {required bool isVertical}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 4,
        vertical: isVertical ? 8.0 : 6.0,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFF9C4), // Highlight gold
            Color(0xFFFFE082), // Warm yellow gold
            Color(0xFFFFB300), // Main royal gold
            Color(0xFFFF8F00), // Deep golden amber
            Color(0xFFC45A00), // Bronze shadow
          ],
          stops: [0.0, 0.22, 0.52, 0.82, 1.0],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: const Border(
          top: BorderSide(
            color: Color(0xFFFFFDE7),
            width: 1.2,
          ),
          bottom: BorderSide(
            color: Color(0xFF6D3200),
            width: 2.5, // 3D depth bottom lip
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            offset: const Offset(0, -1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Left decorative golden diamond stud
                _buildBannerNotch(),
                const SizedBox(width: 3.5),

                // Title text with high-contrast outline
                Text(
                  titleText,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: isVertical ? 13.0 : 11.2,
                    fontWeight: FontWeight.w900,
                    letterSpacing: isVertical ? 0.8 : 0.4,
                    color: Colors.white,
                    shadows: const [
                      // 8-directional outline shadows for bold crisp game outline
                      Shadow(offset: Offset(-1.2, -1.2), color: Color(0xFF3E1800)),
                      Shadow(offset: Offset(1.2, -1.2), color: Color(0xFF3E1800)),
                      Shadow(offset: Offset(-1.2, 1.2), color: Color(0xFF3E1800)),
                      Shadow(offset: Offset(1.2, 1.2), color: Color(0xFF3E1800)),
                      Shadow(offset: Offset(0, -1.4), color: Color(0xFF3E1800)),
                      Shadow(offset: Offset(0, 1.4), color: Color(0xFF3E1800)),
                      Shadow(offset: Offset(-1.4, 0), color: Color(0xFF3E1800)),
                      Shadow(offset: Offset(1.4, 0), color: Color(0xFF3E1800)),
                      // 3D Bottom Drop Shadow
                      Shadow(
                        color: Color(0x99000000),
                        offset: Offset(0, 2.0),
                        blurRadius: 2.5,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 3.5),
                // Right decorative golden diamond stud
                _buildBannerNotch(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerNotch() {
    return Transform.rotate(
      angle: math.pi / 4,
      child: Container(
        width: 4.5,
        height: 4.5,
        decoration: const BoxDecoration(
          color: Color(0xFFFFF9C4),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF6D3200),
              offset: Offset(0.5, 0.5),
              blurRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 1. PLAY WITH FRIENDS ILLUSTRATION (Directly based on ludo_supreme_emblem.png)
// ============================================================================
class PlayWithFriendsIllustration extends StatelessWidget {
  const PlayWithFriendsIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FriendsIllustrationPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _FriendsIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.58;

    // A. Radiant Sunburst Golden Rays (matching emblem radiant backdrop)
    _drawSunburstRays(canvas, size, Offset(cx, cy * 0.85));

    // B. Emblem Signature: 3D Segmented Gold-Rimmed Wheel Stage Pedestal
    _drawEmblemPedestal(canvas, Offset(cx, size.height * 0.82), size.width * 0.88, 26);

    // C. 4 Glossy 3D Pawns from the Emblem (Red, Green, Yellow, Blue)
    // 1. Blue Pawn (Top/Back Center)
    _drawGlossyPawn(
      canvas,
      center: Offset(cx - size.width * 0.16, cy - 8),
      size: 32,
      baseColor: const Color(0xFF0277BD),
      lightColor: const Color(0xFF29B6F6),
      darkColor: const Color(0xFF01579B),
    );

    // 2. Yellow Pawn (Right foreground)
    _drawGlossyPawn(
      canvas,
      center: Offset(cx + size.width * 0.24, cy + 4),
      size: 36,
      baseColor: const Color(0xFFFBC02D),
      lightColor: const Color(0xFFFFF59D),
      darkColor: const Color(0xFFE65100),
    );

    // 3. Green Pawn (Left-mid foreground)
    _drawGlossyPawn(
      canvas,
      center: Offset(cx - size.width * 0.26, cy + 4),
      size: 36,
      baseColor: const Color(0xFF2E7D32),
      lightColor: const Color(0xFF81C784),
      darkColor: const Color(0xFF1B5E20),
    );

    // 4. Red Hero Pawn (Center foreground with gold crown collar)
    _drawGlossyPawn(
      canvas,
      center: Offset(cx - size.width * 0.04, cy + 1),
      size: 42,
      baseColor: const Color(0xFFE53935),
      lightColor: const Color(0xFFFF8A80),
      darkColor: const Color(0xFFB71C1C),
      hasGoldCrown: true,
    );

    // D. Large 3D White Ivory Dice with Glossy Red Pips (from emblem)
    _drawGlossyDice(
      canvas,
      center: Offset(cx + size.width * 0.16, cy + 14),
      size: 24,
      pipColor: const Color(0xFFD32F2F),
      pipCount: 6,
      rotation: 0.12,
    );

    // E. Brilliant Golden Twinkle Sparkles
    _drawSparkle(canvas, Offset(cx - size.width * 0.36, cy - 20), 6.5);
    _drawSparkle(canvas, Offset(cx + size.width * 0.36, cy - 24), 7.0);
    _drawSparkle(canvas, Offset(cx - 4, cy - 36), 6.0);
    _drawSparkle(canvas, Offset(cx + size.width * 0.16, cy - 30), 4.5);
  }

  /// Draws the 3D circular 4-quadrant segmented stage from the emblem
  void _drawEmblemPedestal(Canvas canvas, Offset center, double width, double height) {
    final rect = Rect.fromCenter(center: center, width: width, height: height);

    // 1. Deep Stage Drop Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, center.dy + 4), width: width, height: height),
      Paint()..color = const Color(0x66000000),
    );

    // 2. Outer Golden Bevel Rim
    final goldBorderPaint = Paint()
      ..shader = LinearGradient(
        colors: const [Color(0xFFFFF9C4), Color(0xFFFFB300), Color(0xFF8D4B00)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    canvas.drawOval(rect, goldBorderPaint);

    // 3. Inner Quadrants Base
    final innerRect = Rect.fromCenter(center: center, width: width - 4, height: height - 4);
    // Draw 4 Quadrants: Red, Green, Yellow, Blue
    final clipPath = Path()..addOval(innerRect);
    canvas.save();
    canvas.clipPath(clipPath);

    // Quadrant 1: Red (top-left)
    canvas.drawRect(
      Rect.fromLTRB(innerRect.left, innerRect.top, center.dx, center.dy),
      Paint()..color = const Color(0xFFC62828),
    );
    // Quadrant 2: Blue (top-right)
    canvas.drawRect(
      Rect.fromLTRB(center.dx, innerRect.top, innerRect.right, center.dy),
      Paint()..color = const Color(0xFF0D47A1),
    );
    // Quadrant 3: Green (bottom-left)
    canvas.drawRect(
      Rect.fromLTRB(innerRect.left, center.dy, center.dx, innerRect.bottom),
      Paint()..color = const Color(0xFF1B5E20),
    );
    // Quadrant 4: Yellow (bottom-right)
    canvas.drawRect(
      Rect.fromLTRB(center.dx, center.dy, innerRect.right, innerRect.bottom),
      Paint()..color = const Color(0xFFF57F17),
    );

    // Inner White Separator Lines
    final separatorPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(innerRect.left, center.dy), Offset(innerRect.right, center.dy), separatorPaint);
    canvas.drawLine(Offset(center.dx, innerRect.top), Offset(center.dx, innerRect.bottom), separatorPaint);

    canvas.restore();
  }

  void _drawSunburstRays(Canvas canvas, Size size, Offset center) {
    final rayPaint = Paint()
      ..color = const Color(0x22FFD700)
      ..style = PaintingStyle.fill;
    const rayCount = 12;
    const rayAngle = (math.pi * 2) / rayCount;
    final radius = math.max(size.width, size.height) * 1.3;

    for (int i = 0; i < rayCount; i++) {
      final startAngle = i * rayAngle;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + radius * math.cos(startAngle),
          center.dy + radius * math.sin(startAngle),
        )
        ..lineTo(
          center.dx + radius * math.cos(startAngle + rayAngle * 0.42),
          center.dy + radius * math.sin(startAngle + rayAngle * 0.42),
        )
        ..close();
      canvas.drawPath(path, rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// 2. PASS N PLAY ILLUSTRATION (Purple/Sapphire + Gold Theme)
// ============================================================================
class PassNPlayIllustration extends StatelessWidget {
  const PassNPlayIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PassNPlayIllustrationPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _PassNPlayIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.54;

    // A. Ambient Magenta/Cyan Energy Halo
    final glowRect = Rect.fromCircle(center: Offset(cx, cy), radius: 42);
    final glowPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0x66AB47BC),
          Color(0x3300E5FF),
          Colors.transparent,
        ],
      ).createShader(glowRect);
    canvas.drawCircle(Offset(cx, cy), 44, glowPaint);

    // B. Floating Circular Ludo Gaming Tablet / Board (Gold Bezel)
    final deviceRect = Rect.fromCenter(center: Offset(cx, cy + 4), width: 72, height: 48);
    // Outer Gold Rim
    canvas.drawOval(
      deviceRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFF9C4), Color(0xFFFFB300), Color(0xFF8D4B00)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(deviceRect),
    );

    // Inner Board with 4 quadrants
    final innerBoardRect = Rect.fromCenter(center: Offset(cx, cy + 4), width: 66, height: 42);
    canvas.save();
    canvas.clipPath(Path()..addOval(innerBoardRect));
    canvas.drawRect(
      Rect.fromLTRB(innerBoardRect.left, innerBoardRect.top, cx, cy + 4),
      Paint()..color = const Color(0x88C62828),
    );
    canvas.drawRect(
      Rect.fromLTRB(cx, innerBoardRect.top, innerBoardRect.right, cy + 4),
      Paint()..color = const Color(0x880D47A1),
    );
    canvas.drawRect(
      Rect.fromLTRB(innerBoardRect.left, cy + 4, cx, innerBoardRect.bottom),
      Paint()..color = const Color(0x881B5E20),
    );
    canvas.drawRect(
      Rect.fromLTRB(cx, cy + 4, innerBoardRect.right, innerBoardRect.bottom),
      Paint()..color = const Color(0x88F57F17),
    );
    canvas.restore();

    // Center Gold Star
    _drawSparkle(canvas, Offset(cx, cy + 4), 4.5);

    // C. Dual Orbiting Pass-Handoff Energy Arrows (Pass the Phone!)
    _drawPassArrows(canvas, Offset(cx, cy + 4), radius: 38);

    // D. 4 Local Multiplayer Pawns
    // Green Pawn (Top-left)
    _drawGlossyPawn(
      canvas,
      center: Offset(cx - 30, cy - 14),
      size: 28,
      baseColor: const Color(0xFF2E7D32),
      lightColor: const Color(0xFF81C784),
      darkColor: const Color(0xFF1B5E20),
    );

    // Blue Pawn (Top-right)
    _drawGlossyPawn(
      canvas,
      center: Offset(cx + 30, cy - 14),
      size: 28,
      baseColor: const Color(0xFF0277BD),
      lightColor: const Color(0xFF29B6F6),
      darkColor: const Color(0xFF01579B),
    );

    // Main Red Pawn (Left)
    _drawGlossyPawn(
      canvas,
      center: Offset(cx - 27, cy + 3),
      size: 36,
      baseColor: const Color(0xFFE53935),
      lightColor: const Color(0xFFFF8A80),
      darkColor: const Color(0xFFB71C1C),
    );

    // Main Yellow Pawn (Right)
    _drawGlossyPawn(
      canvas,
      center: Offset(cx + 27, cy + 3),
      size: 36,
      baseColor: const Color(0xFFFBC02D),
      lightColor: const Color(0xFFFFF59D),
      darkColor: const Color(0xFFE65100),
    );

    // E. 3D Tumbling Ivory Dice centered in foreground with Red Pips
    _drawGlossyDice(
      canvas,
      center: Offset(cx, cy + 17),
      size: 22,
      pipColor: const Color(0xFFD32F2F),
      pipCount: 5,
      rotation: -0.12,
    );

    // F. Golden Sparkles
    _drawSparkle(canvas, Offset(cx - 38, cy - 24), 5.5);
    _drawSparkle(canvas, Offset(cx + 38, cy - 24), 6.5);
    _drawSparkle(canvas, Offset(cx, cy - 32), 4.5);
  }

  void _drawPassArrows(Canvas canvas, Offset center, {required double radius}) {
    final goldArrowPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    final cyanArrowPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    // Top arc (sweeping right)
    final topRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(topRect, -math.pi * 0.95, math.pi * 0.8, false, goldArrowPaint);
    _drawArrowHead(
      canvas,
      tip: Offset(
        center.dx + radius * math.cos(-math.pi * 0.15),
        center.dy + radius * math.sin(-math.pi * 0.15),
      ),
      angle: math.pi * 0.38,
      color: const Color(0xFFFFD700),
    );

    // Bottom arc (sweeping left)
    canvas.drawArc(topRect, math.pi * 0.05, math.pi * 0.8, false, cyanArrowPaint);
    _drawArrowHead(
      canvas,
      tip: Offset(
        center.dx + radius * math.cos(math.pi * 0.85),
        center.dy + radius * math.sin(math.pi * 0.85),
      ),
      angle: -math.pi * 0.62,
      color: const Color(0xFF00E5FF),
    );
  }

  void _drawArrowHead(
    Canvas canvas, {
    required Offset tip,
    required double angle,
    required Color color,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    const length = 7.0;
    final p1 = Offset(
      tip.dx - length * math.cos(angle - 0.5),
      tip.dy - length * math.sin(angle - 0.5),
    );
    final p2 = Offset(
      tip.dx - length * math.cos(angle + 0.5),
      tip.dy - length * math.sin(angle + 0.5),
    );
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// 3. PLAY VS COMPUTER ILLUSTRATION (Obsidian Cyber Blue + Emblem Crown Style)
// ============================================================================
class PlayVsComputerIllustration extends StatelessWidget {
  const PlayVsComputerIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PlayVsComputerIllustrationPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _PlayVsComputerIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.53;

    // A. Tech Cyber Background Matrix Glow & Energy Circuit
    _drawTechBackground(canvas, size, Offset(cx - 30, cy - 2));

    // B. AI Ludo Robot Bot (Left Cyber Challenger)
    _drawRobotBot(canvas, Offset(cx - 32, cy - 2), 52);

    // C. 3D Opposing Human Player Pawn: Royal Ruby Red with Grand Gold Crown
    _drawGlossyPawn(
      canvas,
      center: Offset(cx + 42, cy + 4),
      size: 46,
      baseColor: const Color(0xFFE53935),
      lightColor: const Color(0xFFFF8A80),
      darkColor: const Color(0xFFB71C1C),
      hasGoldCrown: true,
    );

    // D. Tumbling 3D Lucky Dice in Mid-Air between Human & AI with Red Pips
    _drawGlossyDice(
      canvas,
      center: Offset(cx + 6, cy + 22),
      size: 25,
      pipColor: const Color(0xFFD32F2F),
      pipCount: 6,
      rotation: 0.24,
    );

    // E. Glowing Energy Arcs & Circuit Sparkles
    _drawSparkle(canvas, Offset(cx + 46, cy - 24), 7.5);
    _drawSparkle(canvas, Offset(cx - 52, cy - 26), 6.5);
    _drawSparkle(canvas, Offset(cx + 6, cy - 28), 5.5);
    _drawSparkle(canvas, Offset(cx - 4, cy + 32), 4.5);
  }

  void _drawTechBackground(Canvas canvas, Size size, Offset center) {
    // Glowing cyan radial halo
    final bgGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0x5500E5FF),
          const Color(0x2200B4D8),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 56));
    canvas.drawCircle(center, 58, bgGlow);

    // Concentric digital circuit arcs
    final arcPaint = Paint()
      ..color = const Color(0x4400E5FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    canvas.drawCircle(center, 42, arcPaint);
    canvas.drawCircle(center, 50, arcPaint);

    // Cyber circuit lines
    final linePaint = Paint()
      ..color = const Color(0x5500E5FF)
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(center.dx - 38, center.dy),
      Offset(center.dx - 58, center.dy - 14),
      linePaint,
    );
    canvas.drawLine(
      Offset(center.dx + 34, center.dy - 22),
      Offset(center.dx + 52, center.dy - 34),
      linePaint,
    );
  }

  void _drawRobotBot(Canvas canvas, Offset center, double size) {
    // 1. Antenna with glowing golden orb
    final antennaPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx, center.dy - size * 0.44),
      Offset(center.dx, center.dy - size * 0.70),
      antennaPaint,
    );
    // Glowing antenna orb with inner specular white core
    canvas.drawCircle(
      Offset(center.dx, center.dy - size * 0.74),
      5.5,
      Paint()..color = const Color(0xFFFFB300),
    );
    canvas.drawCircle(
      Offset(center.dx, center.dy - size * 0.74),
      2.8,
      Paint()..color = Colors.white,
    );

    // 2. Ear bolts (Cyber Headphone Pads) with golden gradient
    final earPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF59D), Color(0xFFFFB300), Color(0xFFE65100)],
      ).createShader(
        Rect.fromLTWH(center.dx - size * 0.6, center.dy - 10, size * 1.2, 20),
      );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx - size * 0.52, center.dy),
          width: 8,
          height: 18,
        ),
        const Radius.circular(3.5),
      ),
      earPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx + size * 0.52, center.dy),
          width: 8,
          height: 18,
        ),
        const Radius.circular(3.5),
      ),
      earPaint,
    );

    // 3. Robot Head Shell (Sleek High-Gloss Metallic Platinum)
    final headRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: size * 0.96, height: size * 0.86),
      Radius.circular(size * 0.28),
    );
    final headPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFE2E8F0),
          Color(0xFF94A3B8),
          Color(0xFF475569),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(headRect.outerRect);
    canvas.drawRRect(headRect, headPaint);

    // 4. Head Cyan Glow Rim
    canvas.drawRRect(
      headRect,
      Paint()
        ..color = const Color(0xFF00E5FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // 5. Dark Visor Screen
    final visorRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + 1),
        width: size * 0.74,
        height: size * 0.48,
      ),
      Radius.circular(size * 0.16),
    );
    canvas.drawRRect(visorRect, Paint()..color = const Color(0xFF050B1A));

    // 6. Glowing Cyan Focused AI Eyes
    final eyePaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.fill;
    // Left eye
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx - size * 0.18, center.dy + 1),
          width: 9.0,
          height: 10.5,
        ),
        const Radius.circular(5.0),
      ),
      eyePaint,
    );
    // Right eye
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx + size * 0.18, center.dy + 1),
          width: 9.0,
          height: 10.5,
        ),
        const Radius.circular(5.0),
      ),
      eyePaint,
    );

    // White eye glints
    canvas.drawCircle(
      Offset(center.dx - size * 0.19, center.dy - 1.8),
      1.8,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(center.dx + size * 0.17, center.dy - 1.8),
      1.8,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// SHARED 3D GLOSSY DRAWING HELPERS: EMBLEM PAWN, DICE, SPARKLE
// ============================================================================

/// Draws a glossy 3D Ludo Pawn directly matched to `ludo_supreme_emblem.png`
void _drawGlossyPawn(
  Canvas canvas, {
  required Offset center,
  required double size,
  required Color baseColor,
  required Color lightColor,
  required Color darkColor,
  bool hasGoldCrown = false,
}) {
  // 1. Dark bottom ground shadow
  final shadowRect = Rect.fromCenter(
    center: Offset(center.dx, center.dy + size * 0.44),
    width: size * 0.78,
    height: size * 0.20,
  );
  canvas.drawOval(shadowRect, Paint()..color = const Color(0x66000000));

  // 2. Base Pedestal Oval with curved glossy rim
  final baseRect = Rect.fromCenter(
    center: Offset(center.dx, center.dy + size * 0.38),
    width: size * 0.72,
    height: size * 0.23,
  );
  final basePaint = Paint()
    ..shader = LinearGradient(
      colors: [lightColor, baseColor, darkColor],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(baseRect);
  canvas.drawOval(baseRect, basePaint);

  // 3. Body Bell / Flared Skirt
  final bodyPath = Path()
    ..moveTo(center.dx - size * 0.16, center.dy - size * 0.05)
    ..quadraticBezierTo(
      center.dx - size * 0.12,
      center.dy + size * 0.18,
      center.dx - size * 0.32,
      center.dy + size * 0.38,
    )
    ..lineTo(center.dx + size * 0.32, center.dy + size * 0.38)
    ..quadraticBezierTo(
      center.dx + size * 0.12,
      center.dy + size * 0.18,
      center.dx + size * 0.16,
      center.dy - size * 0.05,
    )
    ..close();

  final bodyRect = Rect.fromLTWH(
    center.dx - size * 0.35,
    center.dy - size * 0.05,
    size * 0.7,
    size * 0.45,
  );
  final bodyPaint = Paint()
    ..shader = LinearGradient(
      colors: [lightColor, baseColor, darkColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(bodyRect);
  canvas.drawPath(bodyPath, bodyPaint);

  // 4. Neck Collar Ring (Golden collar like the emblem)
  final collarRect = Rect.fromCenter(
    center: Offset(center.dx, center.dy - size * 0.07),
    width: size * 0.44,
    height: size * 0.13,
  );
  canvas.drawOval(
    collarRect,
    Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFDE7), Color(0xFFFFD54F), Color(0xFFFF8F00)],
      ).createShader(collarRect),
  );

  // 5. Spherical Head with Specular Radial Highlight
  final headCenter = Offset(center.dx, center.dy - size * 0.28);
  final headRadius = size * 0.24;
  final headRect = Rect.fromCircle(center: headCenter, radius: headRadius);
  final headPaint = Paint()
    ..shader = RadialGradient(
      center: const Alignment(-0.35, -0.35),
      radius: 0.85,
      colors: [lightColor, baseColor, darkColor],
    ).createShader(headRect);
  canvas.drawCircle(headCenter, headRadius, headPaint);

  // 6. Bold Curved Specular Head Glint (from emblem)
  final glintCenter = Offset(
    headCenter.dx - headRadius * 0.35,
    headCenter.dy - headRadius * 0.35,
  );
  canvas.drawOval(
    Rect.fromCenter(
      center: glintCenter,
      width: headRadius * 0.65,
      height: headRadius * 0.45,
    ),
    Paint()..color = const Color(0xDDFFFFFF),
  );

  // 7. Optional Golden Crown on Hero Pawn
  if (hasGoldCrown) {
    _drawMiniCrown(canvas, Offset(headCenter.dx, headCenter.dy - headRadius * 0.8), size * 0.30);
  }
}

/// Draws a golden crown on top of hero pawns
void _drawMiniCrown(Canvas canvas, Offset center, double width) {
  final crownPath = Path()
    ..moveTo(center.dx - width * 0.5, center.dy)
    ..lineTo(center.dx - width * 0.55, center.dy - width * 0.55)
    ..lineTo(center.dx - width * 0.25, center.dy - width * 0.25)
    ..lineTo(center.dx, center.dy - width * 0.70)
    ..lineTo(center.dx + width * 0.25, center.dy - width * 0.25)
    ..lineTo(center.dx + width * 0.55, center.dy - width * 0.55)
    ..lineTo(center.dx + width * 0.5, center.dy)
    ..close();

  final crownPaint = Paint()
    ..shader = LinearGradient(
      colors: const [Color(0xFFFFFDE7), Color(0xFFFFD54F), Color(0xFFFF8F00)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromCenter(center: center, width: width, height: width));
  canvas.drawPath(crownPath, crownPaint);

  // Crown jewels (rubies & emeralds)
  canvas.drawCircle(Offset(center.dx, center.dy - width * 0.72), 1.6, Paint()..color = const Color(0xFFFF1744));
  canvas.drawCircle(Offset(center.dx - width * 0.55, center.dy - width * 0.57), 1.4, Paint()..color = const Color(0xFF00E676));
  canvas.drawCircle(Offset(center.dx + width * 0.55, center.dy - width * 0.57), 1.4, Paint()..color = const Color(0xFF00E676));
}

/// Draws a 3D White Ivory Dice with Red Inset Pips (matching ludo_supreme_emblem.png)
void _drawGlossyDice(
  Canvas canvas, {
  required Offset center,
  required double size,
  required Color pipColor,
  int pipCount = 6,
  double rotation = 0.0,
}) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  if (rotation != 0.0) {
    canvas.rotate(rotation);
  }

  // Shadow
  final shadowRRect = RRect.fromRectAndRadius(
    Rect.fromCenter(center: const Offset(1.5, 4.0), width: size, height: size),
    Radius.circular(size * 0.25),
  );
  canvas.drawRRect(shadowRRect, Paint()..color = const Color(0x66000000));

  // Dice Body
  final diceRRect = RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset.zero, width: size, height: size),
    Radius.circular(size * 0.25),
  );
  final dicePaint = Paint()
    ..shader = const LinearGradient(
      colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9), Color(0xFFCBD5E1)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(diceRRect.outerRect);
  canvas.drawRRect(diceRRect, dicePaint);

  // Dice Golden/Silver Rim Border
  canvas.drawRRect(
    diceRRect,
    Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFE082), Color(0xFF94A3B8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(diceRRect.outerRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1,
  );

  // Recessed Glossy Red Pips (from emblem)
  final dotPaint = Paint()..color = pipColor;
  final pipRadius = size * 0.092;
  final offsetD = size * 0.26;

  void drawPip(Offset pos) {
    // Outer shadow for inset depth
    canvas.drawCircle(Offset(pos.dx + 0.5, pos.dy + 0.5), pipRadius, Paint()..color = const Color(0x33000000));
    // Main Pip Body
    canvas.drawCircle(pos, pipRadius, dotPaint);
    // Inner Specular Glint
    canvas.drawCircle(Offset(pos.dx - pipRadius * 0.3, pos.dy - pipRadius * 0.3), pipRadius * 0.35, Paint()..color = Colors.white.withValues(alpha: 0.7));
  }

  if (pipCount == 6) {
    // 6 pips: 2 columns of 3
    final positions = [
      Offset(-offsetD, -offsetD),
      Offset(-offsetD, 0),
      Offset(-offsetD, offsetD),
      Offset(offsetD, -offsetD),
      Offset(offsetD, 0),
      Offset(offsetD, offsetD),
    ];
    for (final pos in positions) {
      drawPip(pos);
    }
  } else {
    // 5 pips: 4 corners + center
    final positions = [
      Offset(-offsetD, -offsetD),
      Offset(offsetD, -offsetD),
      Offset.zero,
      Offset(-offsetD, offsetD),
      Offset(offsetD, offsetD),
    ];
    for (final pos in positions) {
      drawPip(pos);
    }
  }

  // Specular diagonal shine across dice face
  final shinePaint = Paint()
    ..shader = const LinearGradient(
      colors: [Color(0x66FFFFFF), Colors.transparent],
      begin: Alignment.topLeft,
      end: Alignment.center,
    ).createShader(diceRRect.outerRect);
  canvas.drawRRect(diceRRect, shinePaint);

  canvas.restore();
}

/// Draws a 4-point golden sparkle star with bright center
void _drawSparkle(Canvas canvas, Offset center, double radius) {
  final paint = Paint()..color = const Color(0xFFFFD700);
  final path = Path()
    ..moveTo(center.dx, center.dy - radius)
    ..quadraticBezierTo(center.dx, center.dy, center.dx + radius, center.dy)
    ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + radius)
    ..quadraticBezierTo(center.dx, center.dy, center.dx - radius, center.dy)
    ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - radius)
    ..close();
  canvas.drawPath(path, paint);

  // Bright white center specular dot
  canvas.drawCircle(center, radius * 0.38, Paint()..color = Colors.white);
}

// ============================================================================
// 4. ONLINE MULTIPLAYER ILLUSTRATION (Glowing Holographic Globe & Networked Pawns)
// ============================================================================
class OnlineIllustration extends StatelessWidget {
  const OnlineIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OnlineIllustrationPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _OnlineIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.54;
    final scale = (size.width / 120.0).clamp(0.65, 1.25);

    // 1. Digital Cyber Glow Behind Globe
    final glowRadius = 36.0 * scale;
    final bgGlow = Paint()
      ..shader = RadialGradient(
        colors: const [
          Color(0x6600E5FF),
          Color(0x330091EA),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: glowRadius * 1.3));
    canvas.drawCircle(Offset(cx, cy), glowRadius * 1.3, bgGlow);

    // 2. 3D Glowing Holographic Globe (Cyan/Sapphire Sphere)
    final globeRadius = 25.0 * scale;
    final globeRect = Rect.fromCircle(center: Offset(cx, cy + 2 * scale), radius: globeRadius);
    final globePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.9,
        colors: const [
          Color(0xFF29B6F6),
          Color(0xFF0277BD),
          Color(0xFF013A63),
          Color(0xFF001833),
        ],
      ).createShader(globeRect);
    canvas.drawCircle(Offset(cx, cy + 2 * scale), globeRadius, globePaint);

    // 3. Globe Latitude & Longitude Grid Lines (Cyan neon)
    final gridPaint = Paint()
      ..color = const Color(0x8880D8FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;
    // Equator & parallels
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 2 * scale), width: globeRadius * 2, height: globeRadius * 0.9),
      gridPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 2 * scale), width: globeRadius * 2, height: globeRadius * 1.6),
      gridPaint,
    );
    // Vertical meridian
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 2 * scale), width: globeRadius * 0.85, height: globeRadius * 2),
      gridPaint,
    );
    // Outer golden/cyan rim
    canvas.drawCircle(
      Offset(cx, cy + 2 * scale),
      globeRadius,
      Paint()
        ..color = const Color(0xFFFFD700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3 * scale,
    );

    // 4. Two Online Players Connecting Across the Globe:
    // Left Player: Royal Ruby Red Pawn
    _drawGlossyPawn(
      canvas,
      center: Offset(cx - 26 * scale, cy + 6 * scale),
      size: 28 * scale,
      baseColor: const Color(0xFFE53935),
      lightColor: const Color(0xFFFF8A80),
      darkColor: const Color(0xFFB71C1C),
      hasGoldCrown: true,
    );

    // Right Player: Vivid Emerald Green Pawn
    _drawGlossyPawn(
      canvas,
      center: Offset(cx + 26 * scale, cy + 6 * scale),
      size: 28 * scale,
      baseColor: const Color(0xFF2E7D32),
      lightColor: const Color(0xFF81C784),
      darkColor: const Color(0xFF1B5E20),
    );

    // 5. Orbiting Golden Wifi / Connection Signal Waves
    final signalPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * scale
      ..strokeCap = StrokeCap.round;
    final topArcRect = Rect.fromCircle(center: Offset(cx, cy - 8 * scale), radius: 18 * scale);
    canvas.drawArc(topArcRect, -math.pi * 0.85, math.pi * 0.70, false, signalPaint);
    final topArcRect2 = Rect.fromCircle(center: Offset(cx, cy - 8 * scale), radius: 24 * scale);
    canvas.drawArc(topArcRect2, -math.pi * 0.85, math.pi * 0.70, false, signalPaint..strokeWidth = 1.4 * scale);

    // 6. Center Floating Glowing Lucky Dice with Red Pips
    _drawGlossyDice(
      canvas,
      center: Offset(cx, cy + 14 * scale),
      size: 18 * scale,
      pipColor: const Color(0xFFD32F2F),
      pipCount: 6,
      rotation: 0.1,
    );

    // 7. Twinkling Golden Sparkles
    _drawSparkle(canvas, Offset(cx - 26 * scale, cy - 20 * scale), 5.0 * scale);
    _drawSparkle(canvas, Offset(cx + 26 * scale, cy - 20 * scale), 5.0 * scale);
    _drawSparkle(canvas, Offset(cx, cy - 28 * scale), 4.2 * scale);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// 5. TEAM UP ILLUSTRATION (Heraldic Golden Shield & Allied Duo 2v2)
// ============================================================================
class TeamUpIllustration extends StatelessWidget {
  const TeamUpIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TeamUpIllustrationPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _TeamUpIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.54;
    final scale = (size.width / 120.0).clamp(0.65, 1.25);

    // 1. Radiant Team Synergy Glow
    final glowRadius = 38.0 * scale;
    final bgGlow = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0x66FFD700),
          Color(0x33FF6F00),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: glowRadius));
    canvas.drawCircle(Offset(cx, cy), glowRadius, bgGlow);

    // 2. Golden Heraldic Team Shield in Background
    _drawGoldenShield(canvas, Offset(cx, cy - 2 * scale), 46 * scale, 52 * scale);

    // 3. Two Allied Pawns Side-by-Side (Teammates!)
    // Teammate 1: Red Champion Pawn with Gold Crown (Left)
    _drawGlossyPawn(
      canvas,
      center: Offset(cx - 15 * scale, cy + 5 * scale),
      size: 32 * scale,
      baseColor: const Color(0xFFE53935),
      lightColor: const Color(0xFFFF8A80),
      darkColor: const Color(0xFFB71C1C),
      hasGoldCrown: true,
    );

    // Teammate 2: Gold/Yellow Partner Pawn (Right)
    _drawGlossyPawn(
      canvas,
      center: Offset(cx + 15 * scale, cy + 5 * scale),
      size: 32 * scale,
      baseColor: const Color(0xFFFBC02D),
      lightColor: const Color(0xFFFFF59D),
      darkColor: const Color(0xFFE65100),
    );

    // 4. "2v2" Golden Metallic Badge / Ribbon across bottom
    _draw2v2Badge(canvas, Offset(cx, cy + 22 * scale), scale);

    // 5. Golden Sparkles
    _drawSparkle(canvas, Offset(cx - 28 * scale, cy - 18 * scale), 5.5 * scale);
    _drawSparkle(canvas, Offset(cx + 28 * scale, cy - 18 * scale), 6.0 * scale);
    _drawSparkle(canvas, Offset(cx, cy - 28 * scale), 5.0 * scale);
  }

  void _drawGoldenShield(Canvas canvas, Offset center, double width, double height) {
    final path = Path()
      ..moveTo(center.dx, center.dy - height * 0.48)
      ..lineTo(center.dx + width * 0.48, center.dy - height * 0.36)
      ..lineTo(center.dx + width * 0.44, center.dy + height * 0.12)
      ..quadraticBezierTo(
        center.dx + width * 0.30,
        center.dy + height * 0.44,
        center.dx,
        center.dy + height * 0.54,
      )
      ..quadraticBezierTo(
        center.dx - width * 0.30,
        center.dy + height * 0.44,
        center.dx - width * 0.44,
        center.dy + height * 0.12,
      )
      ..lineTo(center.dx - width * 0.48, center.dy - height * 0.36)
      ..close();

    // Shield gradient
    final shieldPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF0F265C),
          Color(0xFF09173E),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCenter(center: center, width: width, height: height));
    canvas.drawPath(path, shieldPaint);

    // Golden shield border
    final borderPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFDE7), Color(0xFFFFD54F), Color(0xFF8D4B00)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCenter(center: center, width: width, height: height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, borderPaint);
  }

  void _draw2v2Badge(Canvas canvas, Offset center, double scale) {
    final badgeWidth = 44.0 * scale;
    final badgeHeight = 16.0 * scale;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: badgeWidth, height: badgeHeight),
      Radius.circular(5.0 * scale),
    );

    // Drop shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, center.dy + 1.5 * scale), width: badgeWidth, height: badgeHeight),
        Radius.circular(5.0 * scale),
      ),
      Paint()..color = const Color(0x66000000),
    );

    // Gold gradient body
    final badgePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF9C4), Color(0xFFFFB300), Color(0xFFC45A00)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rrect.outerRect);
    canvas.drawRRect(rrect, badgePaint);

    // Dark border
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFF5D2E00)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * scale,
    );

    // "2 VS 2" text
    final textPainter = TextPainter(
      text: TextSpan(
        text: "2 VS 2",
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 8.5 * scale,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF2E1200),
          letterSpacing: 0.6 * scale,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// 6. TOURNAMENTS ILLUSTRATION (3D Golden Championship Trophy, Laurels & Sparks)
// ============================================================================
class TournamentsIllustration extends StatelessWidget {
  const TournamentsIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TournamentsIllustrationPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _TournamentsIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.54;
    final scale = (size.width / 120.0).clamp(0.65, 1.25);

    // 1. Radiant Championship Golden Aura Glow
    final glowRadius = 38.0 * scale;
    final bgGlow = Paint()
      ..shader = RadialGradient(
        colors: const [
          Color(0x77FFD700),
          Color(0x33FF8F00),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: glowRadius * 1.25));
    canvas.drawCircle(Offset(cx, cy), glowRadius * 1.25, bgGlow);

    // 2. Golden Victory Laurel Branches (Left & Right)
    _drawLaurelWreath(canvas, Offset(cx, cy), scale);

    // 3. 3D Golden Championship Trophy Cup
    _drawTrophyCup(canvas, Offset(cx, cy), scale);

    // 4. Two Flanking Glowing Pawns at base
    _drawGlossyPawn(
      canvas,
      center: Offset(cx - 30 * scale, cy + 12 * scale),
      size: 20 * scale,
      baseColor: const Color(0xFFE53935),
      lightColor: const Color(0xFFFF8A80),
      darkColor: const Color(0xFFB71C1C),
    );

    _drawGlossyPawn(
      canvas,
      center: Offset(cx + 30 * scale, cy + 12 * scale),
      size: 20 * scale,
      baseColor: const Color(0xFF1E88E5),
      lightColor: const Color(0xFF90CAF9),
      darkColor: const Color(0xFF0D47A1),
    );

    // 5. Center Floating Glowing Lucky Dice with Red Pips resting in front
    _drawGlossyDice(
      canvas,
      center: Offset(cx, cy + 18 * scale),
      size: 15 * scale,
      pipColor: const Color(0xFFD32F2F),
      pipCount: 1,
      rotation: 0.0,
    );

    // 6. Twinkling Golden Sparkles & Light Beams
    _drawSparkle(canvas, Offset(cx - 24 * scale, cy - 22 * scale), 5.5 * scale);
    _drawSparkle(canvas, Offset(cx + 24 * scale, cy - 22 * scale), 5.5 * scale);
    _drawSparkle(canvas, Offset(cx, cy - 30 * scale), 6.5 * scale);
    _drawSparkle(canvas, Offset(cx - 16 * scale, cy + 2 * scale), 4.0 * scale);
    _drawSparkle(canvas, Offset(cx + 16 * scale, cy + 2 * scale), 4.0 * scale);
  }

  void _drawLaurelWreath(Canvas canvas, Offset center, double scale) {
    final leafPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF9C4), Color(0xFFFFD54F), Color(0xFFFF8F00)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: 36 * scale));

    // Stems (left and right curved arcs)
    final stemPaint = Paint()
      ..shader = leafPaint.shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * scale
      ..strokeCap = StrokeCap.round;

    final leftStem = Path()
      ..moveTo(center.dx - 12 * scale, center.dy + 20 * scale)
      ..quadraticBezierTo(
        center.dx - 36 * scale,
        center.dy + 4 * scale,
        center.dx - 22 * scale,
        center.dy - 18 * scale,
      );
    canvas.drawPath(leftStem, stemPaint);

    final rightStem = Path()
      ..moveTo(center.dx + 12 * scale, center.dy + 20 * scale)
      ..quadraticBezierTo(
        center.dx + 36 * scale,
        center.dy + 4 * scale,
        center.dx + 22 * scale,
        center.dy - 18 * scale,
      );
    canvas.drawPath(rightStem, stemPaint);

    // Leaves along left stem
    final leftLeaves = [
      Offset(center.dx - 22 * scale, center.dy + 16 * scale),
      Offset(center.dx - 32 * scale, center.dy + 8 * scale),
      Offset(center.dx - 34 * scale, center.dy - 3 * scale),
      Offset(center.dx - 28 * scale, center.dy - 13 * scale),
      Offset(center.dx - 19 * scale, center.dy - 20 * scale),
    ];
    for (final pos in leftLeaves) {
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(-0.5);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 8 * scale, height: 4 * scale),
        leafPaint,
      );
      canvas.restore();
    }

    // Leaves along right stem
    final rightLeaves = [
      Offset(center.dx + 22 * scale, center.dy + 16 * scale),
      Offset(center.dx + 32 * scale, center.dy + 8 * scale),
      Offset(center.dx + 34 * scale, center.dy - 3 * scale),
      Offset(center.dx + 28 * scale, center.dy - 13 * scale),
      Offset(center.dx + 19 * scale, center.dy - 20 * scale),
    ];
    for (final pos in rightLeaves) {
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(0.5);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 8 * scale, height: 4 * scale),
        leafPaint,
      );
      canvas.restore();
    }
  }

  void _drawTrophyCup(Canvas canvas, Offset center, double scale) {
    // 1. Trophy Pedestal Base
    final baseWidth = 28.0 * scale;
    final baseHeight = 9.0 * scale;
    final baseTop = center.dy + 13.0 * scale;

    final baseRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, baseTop + baseHeight / 2),
        width: baseWidth,
        height: baseHeight,
      ),
      Radius.circular(3.0 * scale),
    );

    // Base Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, baseTop + baseHeight / 2 + 2 * scale),
          width: baseWidth,
          height: baseHeight,
        ),
        Radius.circular(3.0 * scale),
      ),
      Paint()..color = const Color(0x77000000),
    );

    // Base Gradient
    final basePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF5D2E00), Color(0xFF8D4600), Color(0xFF3E1B00)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(baseRect.outerRect);
    canvas.drawRRect(baseRect, basePaint);

    // Base Rim Gold Stripe
    canvas.drawRRect(
      baseRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFF9C4), Color(0xFFFFD54F), Color(0xFFC45A00)],
        ).createShader(baseRect.outerRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * scale,
    );

    // 2. Stem (Connecting column)
    final stemPath = Path()
      ..moveTo(center.dx - 4.5 * scale, baseTop)
      ..lineTo(center.dx - 3.0 * scale, center.dy + 6.0 * scale)
      ..lineTo(center.dx + 3.0 * scale, center.dy + 6.0 * scale)
      ..lineTo(center.dx + 4.5 * scale, baseTop)
      ..close();
    canvas.drawPath(
      stemPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFD54F), Color(0xFFFFA000), Color(0xFF7A3600)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromCenter(center: center, width: 10 * scale, height: 10 * scale)),
    );

    // Stem ring
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx, center.dy + 9.5 * scale), width: 10 * scale, height: 3.5 * scale),
      Paint()..color = const Color(0xFFFFE082),
    );

    // 3. Trophy Cup Handles (Left and Right loops)
    final handlePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFDE7), Color(0xFFFFD54F), Color(0xFF8D4B00)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCenter(center: center, width: 44 * scale, height: 30 * scale))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2 * scale
      ..strokeCap = StrokeCap.round;

    final leftHandle = Path()
      ..moveTo(center.dx - 14 * scale, center.dy - 12 * scale)
      ..cubicTo(
        center.dx - 27 * scale,
        center.dy - 14 * scale,
        center.dx - 26 * scale,
        center.dy + 2 * scale,
        center.dx - 11 * scale,
        center.dy + 3 * scale,
      );
    canvas.drawPath(leftHandle, handlePaint);

    final rightHandle = Path()
      ..moveTo(center.dx + 14 * scale, center.dy - 12 * scale)
      ..cubicTo(
        center.dx + 27 * scale,
        center.dy - 14 * scale,
        center.dx + 26 * scale,
        center.dy + 2 * scale,
        center.dx + 11 * scale,
        center.dy + 3 * scale,
      );
    canvas.drawPath(rightHandle, handlePaint);

    // 4. Trophy Main Bowl (Chalice)
    final bowlPath = Path()
      ..moveTo(center.dx - 16 * scale, center.dy - 14 * scale)
      ..lineTo(center.dx + 16 * scale, center.dy - 14 * scale)
      ..quadraticBezierTo(
        center.dx + 16 * scale,
        center.dy - 2 * scale,
        center.dx + 7 * scale,
        center.dy + 6 * scale,
      )
      ..lineTo(center.dx - 7 * scale, center.dy + 6 * scale)
      ..quadraticBezierTo(
        center.dx - 16 * scale,
        center.dy - 2 * scale,
        center.dx - 16 * scale,
        center.dy - 14 * scale,
      )
      ..close();

    final bowlRect = Rect.fromCenter(center: Offset(center.dx, center.dy - 4 * scale), width: 34 * scale, height: 22 * scale);
    final bowlPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFF9C4),
          Color(0xFFFFD54F),
          Color(0xFFFFB300),
          Color(0xFFC45A00),
          Color(0xFF6D2F00),
        ],
        stops: [0.0, 0.25, 0.55, 0.82, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bowlRect);
    canvas.drawPath(bowlPath, bowlPaint);

    // Bowl rim lip (Oval on top)
    final rimRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy - 14 * scale),
      width: 32 * scale,
      height: 6 * scale,
    );
    canvas.drawOval(
      rimRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFFDE7), Color(0xFFFFD54F), Color(0xFFC45A00)],
        ).createShader(rimRect),
    );
    canvas.drawOval(
      rimRect,
      Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 * scale,
    );

    // 5. Embossed Golden Star / Crown on the Cup Center
    _drawCupEmblem(canvas, Offset(center.dx, center.dy - 5 * scale), 6.5 * scale);
  }

  void _drawCupEmblem(Canvas canvas, Offset center, double radius) {
    // 5-point star
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outerAngle = -math.pi / 2 + (i * 4 * math.pi / 5);
      final x = center.dx + radius * math.cos(outerAngle);
      final y = center.dy + radius * math.sin(outerAngle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFFFEE58), Color(0xFFFF8F00)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    canvas.drawCircle(
      center,
      radius * 0.35,
      Paint()..color = const Color(0xFFD32F2F),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


