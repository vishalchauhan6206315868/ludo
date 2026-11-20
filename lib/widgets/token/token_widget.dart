import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/ludo_player.dart';
import '../../models/token.dart';

class TokenWidget extends StatefulWidget {
  final Token token;
  final LudoPlayer player;
  final bool isMovable;
  final VoidCallback? onTap;
  final double size;

  const TokenWidget({
    super.key,
    required this.token,
    required this.player,
    required this.isMovable,
    this.onTap,
    this.size = 24,
  });

  @override
  State<TokenWidget> createState() => _TokenWidgetState();
}

class _TokenWidgetState extends State<TokenWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;

  late AnimationController _actionController;
  TokenAnimStage _lastStage = TokenAnimStage.idle;

  @override
  void initState() {
    super.initState();

    // Continuous 360° spinning halo + radar ripple + rhythmic bounce for movable tokens
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    // Action animation controller for hop, capture, safe glow, goal
    _actionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    if (widget.isMovable) {
      _pulseController.repeat();
    }

    _lastStage = widget.token.animStage;
    _triggerActionAnimation(widget.token.animStage);
  }

  @override
  void didUpdateWidget(covariant TokenWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isMovable && !_pulseController.isAnimating) {
      _pulseController.repeat();
    } else if (!widget.isMovable && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }

    if (widget.token.animStage != _lastStage) {
      _lastStage = widget.token.animStage;
      _triggerActionAnimation(widget.token.animStage);
    } else if (widget.token.animStage == TokenAnimStage.hopping &&
        widget.token.step != oldWidget.token.step) {
      _triggerActionAnimation(TokenAnimStage.hopping);
    }
  }

  void _triggerActionAnimation(TokenAnimStage stage) {
    switch (stage) {
      case TokenAnimStage.throwing:
        _actionController.duration = const Duration(milliseconds: 520);
        _actionController.forward(from: 0.0);
        break;
      case TokenAnimStage.hopping:
        _actionController.duration = const Duration(milliseconds: 210);
        _actionController.forward(from: 0.0);
        break;
      case TokenAnimStage.captured:
        _actionController.duration = const Duration(milliseconds: 450);
        _actionController.forward(from: 0.0);
        break;
      case TokenAnimStage.safeGlow:
        _actionController.duration = const Duration(milliseconds: 380);
        _actionController.forward(from: 0.0);
        break;
      case TokenAnimStage.goalCelebration:
        _actionController.duration = const Duration(milliseconds: 850);
        _actionController.forward(from: 0.0);
        break;
      case TokenAnimStage.idle:
        if (_actionController.isAnimating) {
          _actionController.stop();
          _actionController.reset();
        }
        break;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _actionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.player.primaryColor;
    final darkColor = widget.player.darkColor;
    final lightColor = widget.player.lightColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _actionController]),
        builder: (context, child) {
          final t = _actionController.value;
          final pulseT = _pulseController.value;
          final stage = widget.token.animStage;
          final showMovableHighlight =
              widget.isMovable && stage == TokenAnimStage.idle;

          double liftY = 0.0;
          double scale = 1.0;
          double tiltAngle = 0.0;

          if (stage == TokenAnimStage.throwing) {
            liftY = -sin(t * pi) * 16.0;
            scale = 1.0 + sin(t * pi) * 0.20;
          } else if (stage == TokenAnimStage.hopping) {
            // Smooth cell-to-cell glide with subtle scale pop (stays strictly inside board)
            scale = 1.0 + sin(t * pi) * 0.10;
          } else if (stage == TokenAnimStage.captured) {
            scale = (1.0 - t * 0.35).clamp(0.6, 1.0);
            tiltAngle = t * pi * 2;
          } else if (stage == TokenAnimStage.safeGlow) {
            scale = 1.0 + sin(t * pi) * 0.15;
          } else if (stage == TokenAnimStage.goalCelebration) {
            scale = 1.0 + (sin(t * pi * 2).abs()) * 0.32;
            liftY = -(sin(t * pi * 2).abs()) * 8.0;
          } else if (showMovableHighlight) {
            // Crisp rhythmic bounce inside the grounded spinning halo ring
            final bounce = sin(pulseT * pi * 2).abs();
            liftY = -bounce * (widget.size * 0.16).clamp(3.2, 5.2);
            scale = 1.0 + bounce * 0.11;
          }

          final haloW = widget.size * 1.95;
          final haloH = widget.size * 1.05;

          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // 1. Grounded High-Contrast Spinning Dashed Halo + Expanding Radar Ripples
                // Sits directly on the board tile beneath the bouncing 3D pawn!
                if (showMovableHighlight)
                  Positioned(
                    left: (widget.size - haloW) / 2,
                    top: (widget.size * 0.78) - (haloH / 2),
                    width: haloW,
                    height: haloH,
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _MovableTokenHaloPainter(
                          progress: pulseT,
                          accentColor: color,
                        ),
                      ),
                    ),
                  ),

                // 2. Bouncing / Animated 3D Pawn + Event Effects
                Transform.translate(
                  offset: Offset(0, liftY),
                  child: Transform.scale(
                    scale: scale,
                    child: Transform.rotate(
                      angle: tiltAngle,
                      child: SizedBox(
                        width: widget.size,
                        height: widget.size,
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            // Safe star sparkle ring effect
                            if (stage == TokenAnimStage.safeGlow)
                              Positioned.fill(
                                child: Transform.scale(
                                  scale: 1.0 + t * 0.8,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.amber.withValues(
                                            alpha: (1.0 - t).clamp(0.0, 1.0)),
                                        width: 2.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // Goal victory celebration ring and star sparkle
                            if (stage == TokenAnimStage.goalCelebration) ...[
                              Positioned.fill(
                                child: Transform.scale(
                                  scale: 1.0 + (t * 1.3),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFFFD700)
                                            .withValues(
                                                alpha:
                                                    (1.0 - t).clamp(0.0, 1.0)),
                                        width: 2.6,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -8,
                                child: Opacity(
                                  opacity: (sin(t * pi)).clamp(0.0, 1.0),
                                  child: const Icon(
                                    Icons.stars_rounded,
                                    color: Color(0xFFFFD700),
                                    size: 15,
                                  ),
                                ),
                              ),
                            ],

                            // Sculpted 3D Glossy Pawn matching the luxury board
                            CustomPaint(
                              size: Size.square(widget.size),
                              painter: _Board3DPawnPainter(
                                baseColor: color,
                                lightColor: lightColor,
                                darkColor: darkColor,
                                isMovable: showMovableHighlight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Crisp 3D sculpted glossy Ludo pawn (wide circular base + conical body + spherical head
/// with studio specular highlights and directional tabletop shadow).
class _Board3DPawnPainter extends CustomPainter {
  final Color baseColor;
  final Color lightColor;
  final Color darkColor;
  final bool isMovable;

  _Board3DPawnPainter({
    required this.baseColor,
    required this.lightColor,
    required this.darkColor,
    required this.isMovable,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // 1. Subtle golden under-glow when movable (main spinning halo sits grounded underneath)
    if (isMovable) {
      final glowRect = Rect.fromCenter(
        center: Offset(cx, h * 0.78),
        width: w * 0.96,
        height: h * 0.42,
      );
      canvas.drawOval(
        glowRect,
        Paint()
          ..color = const Color(0xFFFFD54F).withValues(alpha: 0.48)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
      );
    }

    // 2. Soft tabletop drop shadow under base
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + w * 0.04, h * 0.84),
        width: w * 0.80,
        height: h * 0.30,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.36)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2),
    );

    // 3. 3D Extruded Bottom Rim of Pawn Base
    final baseBottomRect = Rect.fromCenter(
      center: Offset(cx, h * 0.79),
      width: w * 0.76,
      height: h * 0.32,
    );
    canvas.drawOval(
      baseBottomRect,
      Paint()
        ..shader = LinearGradient(
          colors: [baseColor, darkColor, Color.lerp(darkColor, Colors.black, 0.35)!],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(baseBottomRect),
    );

    // Top bevel of pawn circular base
    final baseTopRect = Rect.fromCenter(
      center: Offset(cx, h * 0.74),
      width: w * 0.74,
      height: h * 0.28,
    );
    canvas.drawOval(
      baseTopRect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Color.lerp(lightColor, Colors.white, 0.35)!,
            baseColor,
            darkColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(baseTopRect),
    );

    // 4. Sculpted Tapered Pawn Body
    final bodyPath = Path()
      ..moveTo(cx - w * 0.30, h * 0.73)
      ..quadraticBezierTo(cx - w * 0.20, h * 0.54, cx - w * 0.14, h * 0.40)
      ..lineTo(cx + w * 0.14, h * 0.40)
      ..quadraticBezierTo(cx + w * 0.20, h * 0.54, cx + w * 0.30, h * 0.73)
      ..quadraticBezierTo(cx, h * 0.82, cx - w * 0.30, h * 0.73)
      ..close();

    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Color.lerp(lightColor, Colors.white, 0.28)!,
            lightColor,
            baseColor,
            darkColor,
          ],
          stops: const [0.0, 0.22, 0.55, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(Offset.zero & size),
    );

    // Glossy specular reflection streak on body
    final shinePath = Path()
      ..moveTo(cx - w * 0.19, h * 0.70)
      ..quadraticBezierTo(cx - w * 0.13, h * 0.55, cx - w * 0.08, h * 0.44)
      ..lineTo(cx - w * 0.03, h * 0.44)
      ..quadraticBezierTo(cx - w * 0.07, h * 0.55, cx - w * 0.11, h * 0.70)
      ..close();
    canvas.drawPath(
      shinePath,
      Paint()..color = Colors.white.withValues(alpha: 0.42),
    );

    // Subtle neck shadow collar
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * 0.41),
        width: w * 0.32,
        height: h * 0.10,
      ),
      Paint()..color = darkColor.withValues(alpha: 0.55),
    );

    // 5. High-Gloss Spherical Pawn Head
    final headCenter = Offset(cx, h * 0.26);
    final headR = w * 0.24;
    canvas.drawCircle(
      headCenter,
      headR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.38, -0.42),
          radius: 0.90,
          colors: [
            Colors.white,
            Color.lerp(lightColor, Colors.white, 0.30)!,
            baseColor,
            darkColor,
          ],
          stops: const [0.0, 0.24, 0.62, 1.0],
        ).createShader(Rect.fromCircle(center: headCenter, radius: headR)),
    );

    // Bright specular catchlight dot on head
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - headR * 0.34, headCenter.dy - headR * 0.34),
        width: headR * 0.44,
        height: headR * 0.26,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.82),
    );

    // Subtle white rim outline when movable
    if (isMovable) {
      canvas.drawCircle(
        headCenter,
        headR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..color = Colors.white.withValues(alpha: 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _Board3DPawnPainter oldDelegate) =>
      oldDelegate.baseColor != baseColor ||
      oldDelegate.isMovable != isMovable;
}

/// Grounded high-contrast movable-token indicator painted directly on the board tile:
/// - Two staggered expanding golden radar ripple waves
/// - High-contrast dark backing ring (pops sharply on white, yellow & colored tiles)
/// - Continuously spinning 8-dash 24K gold & white highlight ring
class _MovableTokenHaloPainter extends CustomPainter {
  final double progress;
  final Color accentColor;

  const _MovableTokenHaloPainter({
    required this.progress,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseW = size.width * 0.62;
    final baseH = size.height * 0.56;

    // 1. Two staggered expanding radar ripples (always active, zero dead gap)
    for (int i = 0; i < 2; i++) {
      final rT = (progress + i * 0.5) % 1.0;
      final alpha = pow(1.0 - rT, 1.35).toDouble().clamp(0.0, 1.0);
      final rippleRect = Rect.fromCenter(
        center: center,
        width: baseW * (0.96 + rT * 0.62),
        height: baseH * (0.96 + rT * 0.62),
      );

      // Subtle dark contrast halo behind the golden wave (ensures visibility on white cells)
      canvas.drawOval(
        rippleRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0 * alpha + 0.6
          ..color = const Color(0xFF0F172A).withValues(alpha: 0.32 * alpha),
      );
      canvas.drawOval(
        rippleRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8 * alpha + 0.5
          ..color = const Color(0xFFFFD54F).withValues(alpha: 0.88 * alpha),
      );
    }

    // 2. Soft warm golden spotlight fill right under the pawn
    final ringRect = Rect.fromCenter(
      center: center,
      width: baseW,
      height: baseH,
    );
    canvas.drawOval(
      ringRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFE066).withValues(alpha: 0.42),
            accentColor.withValues(alpha: 0.16),
            Colors.transparent,
          ],
          stops: const [0.0, 0.65, 1.0],
        ).createShader(ringRect),
    );

    // 3. High-contrast dark ring backing so rotating dashes pop on every tile color
    canvas.drawOval(
      ringRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (size.width * 0.068).clamp(3.0, 4.4)
        ..color = const Color(0xFF0B1221).withValues(alpha: 0.80),
    );

    // 4. Continuously spinning 8-segment bright 24K gold & white dashed ring
    const int dashCount = 8;
    const double stepAngle = (2.0 * pi) / dashCount;
    const double sweepAngle = stepAngle * 0.56;
    final double spinOffset = progress * 2.0 * pi;
    final double dashStroke = (size.width * 0.042).clamp(1.9, 2.8);

    for (int i = 0; i < dashCount; i++) {
      final start = spinOffset + i * stepAngle;
      final dashColor = i.isEven
          ? const Color(0xFFFFE066) // Bright 24K gold
          : const Color(0xFFFFFFFF); // Crisp white highlight
      canvas.drawArc(
        ringRect,
        start,
        sweepAngle,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = dashStroke
          ..strokeCap = StrokeCap.round
          ..color = dashColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MovableTokenHaloPainter oldDelegate) =>
      (oldDelegate.progress - progress).abs() > 0.005 ||
      oldDelegate.accentColor != accentColor;
}
