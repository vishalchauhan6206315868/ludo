import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedDice extends StatefulWidget {
  final int? value;
  final bool isRolling;
  final bool canRoll;
  final VoidCallback? onRoll;
  final Color diceColor;
  final double size;

  const AnimatedDice({
    super.key,
    required this.value,
    this.isRolling = false,
    this.canRoll = true,
    this.onRoll,
    this.diceColor = Colors.white,
    this.size = 54,
  });

  @override
  State<AnimatedDice> createState() => _AnimatedDiceState();
}

class _AnimatedDiceState extends State<AnimatedDice>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _rotationAnim = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant AnimatedDice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRolling && !oldWidget.isRolling) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.canRoll && !widget.isRolling ? widget.onRoll : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _controller.isAnimating ? _rotationAnim.value : 0.0;
          final scale = _controller.isAnimating ? _scaleAnim.value : 1.0;

          return Transform.scale(
            scale: scale,
            child: Transform.rotate(
              angle: angle,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.diceColor,
                  borderRadius: BorderRadius.circular(widget.size * 0.22),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Color(0xFFF1F5F9),
                      Color(0xFFE2E8F0),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.canRoll
                          ? Colors.amber.withValues(alpha: 0.6)
                          : Colors.black.withValues(alpha: 0.35),
                      blurRadius: widget.canRoll ? 10 : 6,
                      spreadRadius: widget.canRoll ? 2 : 1,
                      offset: const Offset(2, 4),
                    ),
                  ],
                  border: Border.all(
                    color: widget.canRoll ? Colors.amber : const Color(0xFFCBD5E1),
                    width: widget.canRoll ? 2.5 : 1.5,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(widget.size * 0.16),
                  child: _buildDiceFace(widget.value ?? 1),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDiceFace(int val) {
    final dotSize = widget.size * 0.17;

    Widget dot() => Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: val == 6 ? const Color(0xFFE53935) : const Color(0xFF1E293B),
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 1,
                offset: Offset(0.5, 0.5),
              ),
            ],
          ),
        );

    Widget empty() => SizedBox(width: dotSize, height: dotSize);

    switch (val) {
      case 1:
        return Center(child: dot());

      case 2:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [dot(), empty()],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [empty(), dot()],
            ),
          ],
        );

      case 3:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [dot(), empty(), empty()],
            ),
            Center(child: dot()),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [empty(), empty(), dot()],
            ),
          ],
        );

      case 4:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [dot(), dot()],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [dot(), dot()],
            ),
          ],
        );

      case 5:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [dot(), dot()],
            ),
            Center(child: dot()),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [dot(), dot()],
            ),
          ],
        );

      case 6:
      default:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [dot(), dot()],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [dot(), dot()],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [dot(), dot()],
            ),
          ],
        );
    }
  }
}
