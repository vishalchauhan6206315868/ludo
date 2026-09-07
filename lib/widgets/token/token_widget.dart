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
    this.size = 28,
  });

  @override
  State<TokenWidget> createState() => _TokenWidgetState();
}

class _TokenWidgetState extends State<TokenWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.22).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 2.0, end: 10.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    if (widget.isMovable) {
      _animController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant TokenWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMovable && !_animController.isAnimating) {
      _animController.repeat(reverse: true);
    } else if (!widget.isMovable && _animController.isAnimating) {
      _animController.stop();
      _animController.reset();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.player.primaryColor;
    final darkColor = widget.player.darkColor;
    final lightColor = widget.player.lightColor;

    return GestureDetector(
      onTap: widget.isMovable ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          final scale = widget.isMovable ? _scaleAnimation.value : 1.0;
          final glowSpread = widget.isMovable ? _glowAnimation.value : 2.0;

          return Transform.scale(
            scale: scale,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.isMovable
                        ? Colors.white.withValues(alpha: 0.9)
                        : Colors.black.withValues(alpha: 0.35),
                    blurRadius: glowSpread,
                    spreadRadius: widget.isMovable ? 2 : 0.5,
                    offset: widget.isMovable
                        ? Offset.zero
                        : const Offset(1.5, 2.5),
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
                        color: widget.isMovable ? Colors.white : Colors.white70,
                        width: widget.isMovable ? 2.2 : 1.5,
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 2,
                          offset: const Offset(0.5, 1.0),
                        )
                      ],
                    ),
                  ),

                  // Movable indicator dot or pulse
                  if (widget.isMovable)
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
          );
        },
      ),
    );
  }
}
