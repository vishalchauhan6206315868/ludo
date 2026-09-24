import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/ludo_colors.dart';
import '../models/ludo_player.dart';

class VictoryDialog extends StatefulWidget {
  final List<LudoPlayer> winners;
  final VoidCallback onPlayAgain;
  final VoidCallback onMainMenu;

  const VictoryDialog({
    super.key,
    required this.winners,
    required this.onPlayAgain,
    required this.onMainMenu,
  });

  @override
  State<VictoryDialog> createState() => _VictoryDialogState();
}

class _VictoryDialogState extends State<VictoryDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final winner = widget.winners.isNotEmpty ? widget.winners.first : null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti background animation
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _confettiController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ConfettiPainter(progress: _confettiController.value),
                );
              },
            ),
          ),

          // Main Card
          Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: BoxDecoration(
              color: LudoColors.surfaceDark,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.amber, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.3),
                  blurRadius: 25,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
              children: [
                // Trophy icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFFFFE082), Color(0xFFFFB300), Color(0xFFFFA000)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.5),
                        blurRadius: 16,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  "VICTORY!",
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),

                if (winner != null)
                  Text(
                    "${winner.name} Wins the Match!",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                const SizedBox(height: 20),

                // Standings list
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: LudoColors.backgroundDark,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: List.generate(widget.winners.length, (idx) {
                      final p = widget.winners[idx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              "#${idx + 1}",
                              style: TextStyle(
                                color: idx == 0 ? Colors.amber : Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: p.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                p.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (idx == 0)
                              const Icon(Icons.star_rounded,
                                  color: Colors.amber, size: 20),
                          ],
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onMainMenu,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white30),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Main Menu",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: widget.onPlayAgain,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Play Again",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<Color> colors = [
    Colors.red,
    Colors.green,
    Colors.yellow,
    Colors.blue,
    Colors.purple,
    Colors.amber,
  ];

  _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rand = Random(42);
    final paint = Paint();

    for (int i = 0; i < 60; i++) {
      paint.color = colors[rand.nextInt(colors.length)];
      final startX = rand.nextDouble() * size.width;
      final speed = 0.5 + rand.nextDouble() * 0.5;
      final y = ((progress * speed + rand.nextDouble()) % 1.0) * size.height;
      final particleSize = 6.0 + rand.nextDouble() * 6.0;

      canvas.save();
      canvas.translate(startX, y);
      canvas.rotate(progress * 2 * pi * (i % 2 == 0 ? 1 : -1));
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: particleSize,
          height: particleSize * 0.6,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
