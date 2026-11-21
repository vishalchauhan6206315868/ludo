import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/online_game_mode.dart';

/// Reusable 3D gaming card representing a selectable Online Game Mode.
///
/// Features:
/// - 3D Multi-Layer Depth Shadows (Ambient colored glow + realistic 3D elevation drop shadow)
/// - Top specular curved glass gloss highlight for resin/3D feel
/// - Custom 3D emblems (Laurel + Crowned Dice, Shield + Trophy, Hexagon + Lightning, Flame, Mask)
/// - Mode-specific electric gradients
/// - Neon green checkmark indicator for selected state
/// - Metallic ring outline for unselected state
class OnlineGameModeCard extends StatefulWidget {
  final OnlineGameMode mode;
  final bool isSelected;
  final VoidCallback onSelect;

  const OnlineGameModeCard({
    super.key,
    required this.mode,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  State<OnlineGameModeCard> createState() => _OnlineGameModeCardState();
}

class _OnlineGameModeCardState extends State<OnlineGameModeCard> {
  bool _isPressed = false;

  List<Color> _getModeGradient(OnlineGameMode mode) {
    switch (mode.modeType) {
      case OnlineModeType.classic:
        return const [
          Color(0xFF0052D4),
          Color(0xFF2855E3),
          Color(0xFF092994),
        ];
      case OnlineModeType.oneKillWin:
        return const [
          Color(0xFFE52D27),
          Color(0xFFC2185B),
          Color(0xFF6B021C),
        ];
      case OnlineModeType.quick:
        return const [
          Color(0xFF00C853),
          Color(0xFF009624),
          Color(0xFF004D20),
        ];
      case OnlineModeType.popular:
        return const [
          Color(0xFF8E2DE2),
          Color(0xFF6A00B0),
          Color(0xFF31006E),
        ];
      case OnlineModeType.mask:
        return const [
          Color(0xFF00BCD4),
          Color(0xFF00838F),
          Color(0xFF004D40),
        ];
    }
  }

  Color _getBadgeBackgroundColor(OnlineGameMode mode) {
    switch (mode.modeType) {
      case OnlineModeType.classic:
        return const Color(0xFFFFD54F);
      case OnlineModeType.oneKillWin:
        return const Color(0xFFD50000);
      case OnlineModeType.quick:
        return const Color(0xFF00C853);
      case OnlineModeType.popular:
        return const Color(0xFFAB47BC);
      case OnlineModeType.mask:
        return const Color(0xFF00BCD4);
    }
  }

  Color _getBadgeTextColor(OnlineGameMode mode) {
    switch (mode.modeType) {
      case OnlineModeType.classic:
        return const Color(0xFF2E1100);
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.mode;
    final isSelected = widget.isSelected;
    final gradientColors = _getModeGradient(mode);

    return AnimatedScale(
      scale: _isPressed ? 0.97 : (isSelected ? 1.015 : 1.0),
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 5.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          // Metallic Gold Outer Bevel Frame when selected, subtle glowing border when unselected
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    Color(0xFFFFFDE7),
                    Color(0xFFFFE082),
                    Color(0xFFFFB300),
                    Color(0xFFFF8F00),
                    Color(0xFF8D4B00),
                    Color(0xFFFFD54F),
                  ],
                  stops: [0.0, 0.20, 0.45, 0.70, 0.90, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    mode.glowColor.withValues(alpha: 0.6),
                    Colors.white.withValues(alpha: 0.1),
                    mode.glowColor.withValues(alpha: 0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          boxShadow: [
            if (isSelected) ...[
              // Layer 1: Ambient Neon Bloom Halo
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: mode.glowColor.withValues(alpha: 0.55),
                blurRadius: 18,
                spreadRadius: 1,
              ),
              // Layer 2: Deep 3D Drop Shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ] else ...[
              // Unselected 3D Shadow with colored ambient glow
              BoxShadow(
                color: mode.glowColor.withValues(alpha: 0.35),
                blurRadius: 14,
                spreadRadius: 0.5,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.65),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ],
        ),
        padding: EdgeInsets.all(isSelected ? 2.6 : 1.5),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isSelected ? 19.5 : 20.5),
            // Inner secondary border
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFFD700).withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.15),
              width: 1.0,
            ),
            // Mode-specific Rich Radial/Linear Deep Gaming Gradient
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: Key('online_mode_card_${mode.id}'),
              borderRadius: BorderRadius.circular(20),
              splashColor: mode.accentColor.withValues(alpha: 0.25),
              highlightColor: Colors.transparent,
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              onTap: () {
                try {
                  HapticFeedback.selectionClick();
                } catch (_) {}
                widget.onSelect();
              },
              child: Stack(
                children: [
                  // Specular Curved Gloss Highlight (Depth Effect)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 38,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(19),
                          topRight: Radius.circular(19),
                        ),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white
                                .withValues(alpha: isSelected ? 0.25 : 0.15),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 11.0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // LEFT: 3D Mode Emblem
                        _build3DModeEmblem(mode.modeType),

                        const SizedBox(width: 12),

                        // CENTER: Mode Title, Badge, Description, Players count
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Top line: Mode Title & Badge
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      mode.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.8),
                                            offset: const Offset(0, 2),
                                            blurRadius: 4,
                                          ),
                                          if (isSelected)
                                            Shadow(
                                              color: mode.glowColor
                                                  .withValues(alpha: 0.8),
                                              blurRadius: 10,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildBadge(mode),
                                ],
                              ),
                              const SizedBox(height: 3),

                              // Description
                              Text(
                                mode.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w500,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
                                      offset: Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Bottom line: Green online indicator & "Players: XXXX"
                              Row(
                                children: [
                                  const Icon(
                                    Icons.group_rounded,
                                    color: Color(0xFF00E676),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      "Players: ${mode.formattedPlayerCount}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11.0,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // RIGHT: Selection Circle Indicator (3D Green checkmark or dark metallic ring)
                        _buildSelectionIndicator(isSelected),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 3D Mode Emblem according to mode type
  Widget _build3DModeEmblem(OnlineModeType modeType) {
    CustomPainter painter;
    switch (modeType) {
      case OnlineModeType.classic:
        painter = const _ClassicEmblemPainter();
        break;
      case OnlineModeType.oneKillWin:
        painter = const _OneKillWinEmblemPainter();
        break;
      case OnlineModeType.quick:
        painter = const _QuickEmblemPainter();
        break;
      case OnlineModeType.popular:
        painter = const _PopularEmblemPainter();
        break;
      case OnlineModeType.mask:
        painter = const _MaskEmblemPainter();
        break;
    }

    return SizedBox(
      width: 54,
      height: 54,
      child: CustomPaint(
        painter: painter,
      ),
    );
  }

  /// Mode category pill tag
  Widget _buildBadge(OnlineGameMode mode) {
    final bgColor = _getBadgeBackgroundColor(mode);
    final textColor = _getBadgeTextColor(mode);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.5),
            blurRadius: 4,
          ),
        ],
      ),
      child: Text(
        mode.badgeText,
        style: TextStyle(
          color: textColor,
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Selection Circle Indicator:
  /// - 3D Green checkmark with glowing neon bloom when selected
  /// - 3D Dark metallic ring when unselected
  Widget _buildSelectionIndicator(bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isSelected
            ? const LinearGradient(
                colors: [
                  Color(0xFF69F0AE),
                  Color(0xFF00E676),
                  Color(0xFF00C853),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [
                  Color(0xFF1E2746),
                  Color(0xFF0E1325),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        border: Border.all(
          color: isSelected
              ? Colors.white
              : const Color(0xFFFFD700).withValues(alpha: 0.6),
          width: isSelected ? 2.0 : 1.8,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: const Color(0xFF00E676).withValues(alpha: 0.8),
              blurRadius: 12,
              spreadRadius: 2,
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: isSelected
          ? const Center(
              child: Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 20,
                weight: 800,
              ),
            )
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// 3D Custom Painters for Mode Emblems
// ---------------------------------------------------------------------------

/// 1. Classic Emblem: Golden Laurel Wreath + Yellow Crowned Dice with dots
class _ClassicEmblemPainter extends CustomPainter {
  const _ClassicEmblemPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.55);

    // Laurel Leaves
    final laurelPaint = Paint()..color = const Color(0xFFFFD54F);
    for (int i = 0; i < 3; i++) {
      final yOffset = h * 0.35 + i * 8;
      // Left
      canvas.save();
      canvas.translate(w * 0.15, yOffset);
      canvas.rotate(-0.4 - i * 0.15);
      canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 10, height: 4),
          laurelPaint);
      canvas.restore();
      // Right
      canvas.save();
      canvas.translate(w * 0.85, yOffset);
      canvas.rotate(0.4 + i * 0.15);
      canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 10, height: 4),
          laurelPaint);
      canvas.restore();
    }

    // Yellow 3D Dice Body
    final diceRect = Rect.fromCenter(center: center, width: 28, height: 28);
    final diceRRect = RRect.fromRectAndRadius(diceRect, const Radius.circular(6));

    final dicePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFDE7), Color(0xFFFFD54F), Color(0xFFFF8F00)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(diceRect);
    canvas.drawRRect(diceRRect, dicePaint);

    // Dice Outline
    canvas.drawRRect(
      diceRRect,
      Paint()
        ..color = const Color(0xFF5D2E00)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Dice Dots (5 dots)
    final dotPaint = Paint()..color = const Color(0xFF5D2E00);
    canvas.drawCircle(center, 2.0, dotPaint);
    canvas.drawCircle(Offset(center.dx - 6.5, center.dy - 6.5), 1.8, dotPaint);
    canvas.drawCircle(Offset(center.dx + 6.5, center.dy - 6.5), 1.8, dotPaint);
    canvas.drawCircle(Offset(center.dx - 6.5, center.dy + 6.5), 1.8, dotPaint);
    canvas.drawCircle(Offset(center.dx + 6.5, center.dy + 6.5), 1.8, dotPaint);

    // Mini Crown on Top of Dice
    final crownPath = Path()
      ..moveTo(center.dx - 10, center.dy - 14)
      ..lineTo(center.dx - 12, center.dy - 22)
      ..lineTo(center.dx - 5, center.dy - 18)
      ..lineTo(center.dx, center.dy - 24)
      ..lineTo(center.dx + 5, center.dy - 18)
      ..lineTo(center.dx + 12, center.dy - 22)
      ..lineTo(center.dx + 10, center.dy - 14)
      ..close();

    final crownPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFDE7), Color(0xFFFFD54F), Color(0xFFFFA000)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(center.dx - 12, center.dy - 24, 24, 10));
    canvas.drawPath(crownPath, crownPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 2. 1 Kill Win Emblem: Laurel Wreath + Red Shield + Championship Trophy
class _OneKillWinEmblemPainter extends CustomPainter {
  const _OneKillWinEmblemPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.50);

    // Laurel Leaves
    final laurelPaint = Paint()..color = const Color(0xFFFFD54F);
    for (int i = 0; i < 3; i++) {
      final yOffset = h * 0.35 + i * 8;
      canvas.save();
      canvas.translate(w * 0.15, yOffset);
      canvas.rotate(-0.4 - i * 0.15);
      canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 10, height: 4),
          laurelPaint);
      canvas.restore();

      canvas.save();
      canvas.translate(w * 0.85, yOffset);
      canvas.rotate(0.4 + i * 0.15);
      canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 10, height: 4),
          laurelPaint);
      canvas.restore();
    }

    // Ruby Shield
    final shieldPath = Path()
      ..moveTo(center.dx - 15, center.dy - 16)
      ..lineTo(center.dx + 15, center.dy - 16)
      ..lineTo(center.dx + 15, center.dy + 4)
      ..cubicTo(center.dx + 15, center.dy + 15, center.dx, center.dy + 20,
          center.dx, center.dy + 20)
      ..cubicTo(center.dx, center.dy + 20, center.dx - 15, center.dy + 15,
          center.dx - 15, center.dy + 4)
      ..close();

    final shieldPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF5252), Color(0xFFD50000), Color(0xFF8B0000)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(center.dx - 15, center.dy - 16, 30, 36));
    canvas.drawPath(shieldPath, shieldPaint);

    // Shield Border
    canvas.drawPath(
      shieldPath,
      Paint()
        ..color = const Color(0xFFFFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // White Trophy Cup inside Shield
    final trophyPaint = Paint()..color = Colors.white;
    final cupPath = Path()
      ..moveTo(center.dx - 7, center.dy - 8)
      ..lineTo(center.dx + 7, center.dy - 8)
      ..cubicTo(center.dx + 6, center.dy + 3, center.dx + 3, center.dy + 5,
          center.dx, center.dy + 5)
      ..cubicTo(center.dx - 3, center.dy + 5, center.dx - 6, center.dy + 3,
          center.dx - 7, center.dy - 8)
      ..close();
    canvas.drawPath(cupPath, trophyPaint);

    // Trophy Handles
    final handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawArc(
        Rect.fromCircle(
            center: Offset(center.dx - 7, center.dy - 4), radius: 3),
        -math.pi / 2,
        math.pi,
        false,
        handlePaint);
    canvas.drawArc(
        Rect.fromCircle(
            center: Offset(center.dx + 7, center.dy - 4), radius: 3),
        math.pi / 2,
        math.pi,
        false,
        handlePaint);

    // Stem and Base
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(center.dx, center.dy + 8), width: 2, height: 4),
        trophyPaint);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(center.dx, center.dy + 10),
                width: 10,
                height: 2),
            const Radius.circular(1)),
        trophyPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3. Quick Emblem: Emerald Hexagon Shield + 3D Golden Lightning Bolt
class _QuickEmblemPainter extends CustomPainter {
  const _QuickEmblemPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.5);
    const radius = 22.0;

    // Hexagon Shield
    final hexPath = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        hexPath.moveTo(x, y);
      } else {
        hexPath.lineTo(x, y);
      }
    }
    hexPath.close();

    final hexPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF00E676), Color(0xFF00A844), Color(0xFF004D20)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawPath(hexPath, hexPaint);

    // Hexagon Border
    canvas.drawPath(
      hexPath,
      Paint()
        ..color = const Color(0xFFB9F6CA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Golden Lightning Bolt
    final boltPath = Path()
      ..moveTo(center.dx + 2, center.dy - 14)
      ..lineTo(center.dx - 7, center.dy + 1)
      ..lineTo(center.dx - 1, center.dy + 1)
      ..lineTo(center.dx - 4, center.dy + 14)
      ..lineTo(center.dx + 8, center.dy - 3)
      ..lineTo(center.dx + 1, center.dy - 3)
      ..close();

    final boltPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFDE7), Color(0xFFFFEB3B), Color(0xFFFF9800)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: 14));
    canvas.drawPath(boltPath, boltPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 4. Popular Emblem: Teardrop Badge + 3D Golden Flame
class _PopularEmblemPainter extends CustomPainter {
  const _PopularEmblemPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.5);

    // Circular Teardrop Shield
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFAB47BC), Color(0xFF7B1FA2), Color(0xFF4A148C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: 22));
    canvas.drawCircle(center, 22, bgPaint);

    // Border
    canvas.drawCircle(
      center,
      22,
      Paint()
        ..color = const Color(0xFFEA80FC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Fire Flame Body
    final flamePath = Path()
      ..moveTo(center.dx, center.dy - 14)
      ..cubicTo(center.dx + 7, center.dy - 6, center.dx + 13, center.dy + 3,
          center.dx + 10, center.dy + 10)
      ..cubicTo(center.dx + 7, center.dy + 15, center.dx - 7, center.dy + 15,
          center.dx - 10, center.dy + 10)
      ..cubicTo(center.dx - 13, center.dy + 3, center.dx - 7, center.dy - 6,
          center.dx, center.dy - 14)
      ..close();

    final flamePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF176), Color(0xFFFF9800), Color(0xFFD50000)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: 14));
    canvas.drawPath(flamePath, flamePaint);

    // Inner Flame Core
    final innerFlame = Path()
      ..moveTo(center.dx, center.dy - 4)
      ..cubicTo(center.dx + 4, center.dy + 1, center.dx + 5, center.dy + 7,
          center.dx + 4, center.dy + 9)
      ..cubicTo(center.dx + 2, center.dy + 11, center.dx - 2, center.dy + 11,
          center.dx - 4, center.dy + 9)
      ..cubicTo(center.dx - 5, center.dy + 7, center.dx - 4, center.dy + 1,
          center.dx, center.dy - 4)
      ..close();
    canvas.drawPath(innerFlame, Paint()..color = const Color(0xFFFFFDE7));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 5. Mask Emblem: Circular Teal Badge + 3D White Masquerade Mask
class _MaskEmblemPainter extends CustomPainter {
  const _MaskEmblemPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.5);

    // Circular Teal Badge
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF26C6DA), Color(0xFF0097A7), Color(0xFF006064)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: 22));
    canvas.drawCircle(center, 22, bgPaint);

    // Border
    canvas.drawCircle(
      center,
      22,
      Paint()
        ..color = const Color(0xFF80DEEA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // White Masquerade Mask
    final maskPath = Path()
      ..moveTo(center.dx - 15, center.dy - 5)
      ..cubicTo(center.dx - 14, center.dy - 10, center.dx - 6, center.dy - 8,
          center.dx, center.dy - 4)
      ..cubicTo(center.dx + 6, center.dy - 8, center.dx + 14, center.dy - 10,
          center.dx + 15, center.dy - 5)
      ..cubicTo(center.dx + 16, center.dy + 3, center.dx + 8, center.dy + 8,
          center.dx, center.dy + 4)
      ..cubicTo(center.dx - 8, center.dy + 8, center.dx - 16, center.dy + 3,
          center.dx - 15, center.dy - 5)
      ..close();

    final maskPaint = Paint()..color = Colors.white;
    canvas.drawPath(maskPath, maskPaint);

    // Eye Holes
    final eyePaint = Paint()..color = const Color(0xFF006064);
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(center.dx - 6, center.dy - 1), width: 6, height: 4),
      eyePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(center.dx + 6, center.dy - 1), width: 6, height: 4),
      eyePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
