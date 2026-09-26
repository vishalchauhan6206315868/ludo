import 'dart:math';
import 'package:flutter/material.dart';
import '../../constants/ludo_path.dart';
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
    this.size = 28,
  });

  @override
  State<TokenWidget> createState() => _TokenWidgetState();
}

class _TokenWidgetState extends State<TokenWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseScaleAnim;
  late Animation<double> _pulseGlowAnim;

  late AnimationController _actionController;

  @override
  void initState() {
    super.initState();
    // Idle movable pulsing controller
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _pulseScaleAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseGlowAnim = Tween<double>(begin: 2.0, end: 9.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Dynamic action controller for throw, hop, capture, safe glow, goal
    _actionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    if (widget.isMovable) {
      _pulseController.repeat(reverse: true);
    }

    _triggerActionIfActive(widget.token.animStage);
  }

  @override
  void didUpdateWidget(covariant TokenWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update idle pulse
    if (widget.isMovable && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isMovable && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }

    // Trigger action animation when stage changes
    if (widget.token.animStage != oldWidget.token.animStage ||
        (widget.token.animStage != TokenAnimStage.idle &&
            !_actionController.isAnimating)) {
      _triggerActionIfActive(widget.token.animStage);
    }
  }

  void _triggerActionIfActive(TokenAnimStage stage) {
    switch (stage) {
      case TokenAnimStage.throwing:
        _actionController.duration = const Duration(milliseconds: 550);
        _actionController.forward(from: 0.0);
        break;
      case TokenAnimStage.hopping:
        _actionController.duration = const Duration(milliseconds: 220);
        _actionController.forward(from: 0.0);
        break;
      case TokenAnimStage.captured:
        _actionController.duration = const Duration(milliseconds: 350);
        _actionController.forward(from: 0.0);
        break;
      case TokenAnimStage.safeGlow:
        _actionController.duration = const Duration(milliseconds: 400);
        _actionController.forward(from: 0.0);
        break;
      case TokenAnimStage.goalCelebration:
        _actionController.duration = const Duration(milliseconds: 650);
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
          final stage = widget.token.animStage;
          final isCurrentlySafe = widget.token.step >= 0 &&
              widget.token.step <= 50 &&
              LudoPath.isSafeCoord(widget.token.coordinate);

          double liftY = 0.0;
          double scale = 1.0;
          double tiltAngle = 0.0;
          double shadowBlur = 3.0;
          double shadowSpread = 0.5;
          Offset shadowOffset = const Offset(1.5, 2.5);
          Color shadowColor = Colors.black.withValues(alpha: 0.35);

          if (stage == TokenAnimStage.throwing) {
            // Parabolic 3D arc lift towards center
            liftY = -sin(t * pi) * 28.0;
            scale = 1.0 + sin(t * pi) * 0.38;
            tiltAngle = sin(t * pi) * -0.16;
            shadowBlur = 3.0 + sin(t * pi) * 16.0;
            shadowSpread = 0.5 + sin(t * pi) * 4.0;
            shadowOffset = Offset(1.5, 2.5 + sin(t * pi) * 10.0);
            shadowColor = Colors.black.withValues(alpha: 0.2 + (1.0 - sin(t * pi)) * 0.25);
          } else if (stage == TokenAnimStage.hopping) {
            // Smooth cell-to-cell leap in air
            liftY = -sin(t * pi) * 18.0;
            scale = 1.0 + sin(t * pi) * 0.22;
            tiltAngle = sin(t * pi) * 0.05;
            shadowBlur = 3.0 + sin(t * pi) * 10.0;
            shadowSpread = 0.5 + sin(t * pi) * 2.5;
            shadowOffset = Offset(1.5, 2.5 + sin(t * pi) * 6.0);
          } else if (stage == TokenAnimStage.captured) {
            // Shrinking and spin on capture
            scale = (1.0 - t * 0.35).clamp(0.6, 1.0);
            tiltAngle = t * pi * 2;
          } else if (stage == TokenAnimStage.safeGlow) {
            // Subtle pulse on safe star
            scale = 1.0 + sin(t * pi) * 0.16;
          } else if (stage == TokenAnimStage.goalCelebration) {
            // Celebratory bouncing in home goal
            scale = 1.0 + (sin(t * pi * 2).abs()) * 0.35;
            liftY = -(sin(t * pi * 2).abs()) * 12.0;
          } else if (widget.isMovable) {
            // Idle movable pulse
            scale = _pulseScaleAnim.value;
            shadowBlur = _pulseGlowAnim.value;
            shadowSpread = 2.0;
            shadowOffset = Offset.zero;
            shadowColor = Colors.white.withValues(alpha: 0.9);
          }

          return Transform.translate(
            offset: Offset(0, liftY),
            child: Transform.scale(
              scale: scale,
              child: Transform.rotate(
                angle: tiltAngle,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Safe star sparkle ring effect
                    if (stage == TokenAnimStage.safeGlow)
                      Positioned.fill(
                        child: Transform.scale(
                          scale: 1.0 + t * 0.9,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.amber.withValues(alpha: (1.0 - t).clamp(0.0, 1.0)),
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withValues(alpha: (0.8 * (1.0 - t)).clamp(0.0, 1.0)),
                                  blurRadius: 12,
                                  spreadRadius: 3,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Goal victory celebration ring
                    if (stage == TokenAnimStage.goalCelebration)
                      Positioned.fill(
                        child: Transform.scale(
                          scale: 1.0 + (t * 1.2),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: color.withValues(alpha: (1.0 - t).clamp(0.0, 1.0)),
                                width: 2.8,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Main token body with dynamic 3D gradient and shadow
                    Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: shadowColor,
                            blurRadius: shadowBlur,
                            spreadRadius: shadowSpread,
                            offset: shadowOffset,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Base token body with 3D gradient
                          Container(
                            width: widget.size,
                            height: widget.size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                center: const Alignment(-0.35, -0.4),
                                radius: 0.85,
                                colors: [
                                  lightColor,
                                  color,
                                  darkColor,
                                ],
                                stops: const [0.0, 0.55, 1.0],
                              ),
                              border: Border.all(
                                color: widget.isMovable || stage == TokenAnimStage.throwing
                                    ? Colors.white
                                    : Colors.white70,
                                width: widget.isMovable || stage == TokenAnimStage.throwing
                                    ? 2.4
                                    : 1.5,
                              ),
                            ),
                          ),

                          // Inner pin head circle for 3D pawn look
                          Container(
                            width: widget.size * 0.46,
                            height: widget.size * 0.46,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                center: const Alignment(-0.3, -0.3),
                                radius: 0.7,
                                colors: [
                                  Colors.white.withValues(alpha: 0.9),
                                  lightColor,
                                  color,
                                ],
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 2,
                                  offset: Offset(0.5, 1.0),
                                )
                              ],
                            ),
                          ),

                          // Movable indicator dot
                          if (widget.isMovable && stage == TokenAnimStage.idle)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Floating Ludo King style "STOP" Safe Signal Badge
                    if (isCurrentlySafe &&
                        stage != TokenAnimStage.captured &&
                        stage != TokenAnimStage.throwing)
                      Positioned(
                        top: -6,
                        right: -6,
                        child: AnimatedScale(
                          scale: stage == TokenAnimStage.safeGlow ? 1.35 : 1.0,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.elasticOut,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 3.5, vertical: 1.2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              border:
                                  Border.all(color: Colors.white, width: 1.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1.5),
                                ),
                                if (stage == TokenAnimStage.safeGlow)
                                  const BoxShadow(
                                    color: Colors.amberAccent,
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shield_rounded,
                                  size: 8,
                                  color: Color(0xFF3E2723),
                                ),
                                SizedBox(width: 1.5),
                                Text(
                                  "STOP",
                                  style: TextStyle(
                                    color: Color(0xFF3E2723),
                                    fontSize: 6.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
