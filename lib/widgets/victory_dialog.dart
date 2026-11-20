import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/ludo_colors.dart';
import '../models/ludo_player.dart';

class VictoryDialog extends StatefulWidget {
  final List<LudoPlayer> winners;
  final String? winningTeam;
  final VoidCallback onPlayAgain;
  final VoidCallback onMainMenu;

  const VictoryDialog({
    super.key,
    required this.winners,
    this.winningTeam,
    required this.onPlayAgain,
    required this.onMainMenu,
  });

  @override
  State<VictoryDialog> createState() => _VictoryDialogState();
}

class _VictoryDialogState extends State<VictoryDialog>
    with TickerProviderStateMixin {
  late AnimationController _fxController;
  late AnimationController _entranceController;
  late Animation<double> _cardScale;
  late Animation<double> _cardOpacity;

  @override
  void initState() {
    super.initState();
    _fxController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    )..forward();

    _cardScale = Tween<double>(begin: 0.74, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );
    _cardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _fxController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final winner = widget.winners.isNotEmpty ? widget.winners.first : null;
    final winnerColor = winner?.primaryColor ?? LudoColors.red;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Full-Screen Sky Fireworks & Vibrant 3D Confetti Ribbons
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _fxController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _GrandVictoryFxPainter(
                      progress: _fxController.value,
                      winnerColor: winnerColor,
                    ),
                  );
                },
              ),
            ),
          ),

          // 2. Royal Victory Card matching the luxury reference design
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 28, 18, 16),
              child: AnimatedBuilder(
                animation: _entranceController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _cardOpacity.value,
                    child: Transform.scale(
                      scale: _cardScale.value,
                      child: child,
                    ),
                  );
                },
                child: _buildVictoryCard(winner, winnerColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVictoryCard(LudoPlayer? winner, Color winnerColor) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 386),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Main Royal Indigo-Violet Card with Glowing 24K Gold Frame
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(3.2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF8C4),
                  Color(0xFFFFCA28),
                  Color(0xFFE68A00),
                  Color(0xFFFFEE88),
                  Color(0xFFCC7000),
                  Color(0xFFFFF3B0),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.55),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: const Color(0xFFFF6D00).withValues(alpha: 0.28),
                  blurRadius: 36,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.78),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(27),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.0, -0.58),
                    radius: 1.15,
                    colors: [
                      Color(0xFF28209C),
                      Color(0xFF171072),
                      Color(0xFF150954),
                      Color(0xFF1E084B),
                    ],
                    stops: [0.0, 0.36, 0.72, 1.0],
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Subtle decorative interior floating confetti bits at top corners
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: _fxController,
                          builder: (context, _) => CustomPaint(
                            painter: _CardSparkleConfettiPainter(
                              progress: _fxController.value,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Card Content
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 122, 18, 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 1. Curved Crimson-Red "1ST PLACE CHAMPION" Silk Ribbon
                          _buildChampionRibbon(),
                          const SizedBox(height: 10),

                          // 2. Bold 3D Metallic Gold "VICTORY!" flanked by golden laurel sprigs
                          _buildVictoryTitleRow(),
                          const SizedBox(height: 10),

                          // 3. Winner Subtitle with Sculpted 3D Pawn
                          _buildWinnerSubtitle(winner),
                          const SizedBox(height: 14),

                          // 4. Glassmorphic Standings Container with Laurel Rank Badges
                          _buildStandingsContainer(),
                          const SizedBox(height: 18),

                          // 5. Glossy 3D Pill Buttons (Blue Main Menu + Gold Play Again)
                          _buildActionButtons(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Top Sculpted 3D Golden Trophy + Jeweled Crown + Twin Laurel Branches
          // Positioned to peek gracefully above the top gold frame (exact reference look!)
          Positioned(
            top: -18,
            child: IgnorePointer(
              child: SizedBox(
                width: 240,
                height: 158,
                child: AnimatedBuilder(
                  animation: _fxController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _VictoryTrophyCrestPainter(
                        progress: _fxController.value,
                        winnerColor: winnerColor,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChampionRibbon() {
    return SizedBox(
      width: 280,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _CrimsonChampionRibbonPainter(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(
                    width: 15,
                    height: 12,
                    child: CustomPaint(painter: _TinyGoldCrownPainter()),
                  ),
                  SizedBox(width: 7),
                  Text(
                    '1ST PLACE CHAMPION',
                    style: TextStyle(
                      color: Color(0xFFFFF5D1),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 3,
                          offset: Offset(0, 1.2),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 7),
                  SizedBox(
                    width: 15,
                    height: 12,
                    child: CustomPaint(painter: _TinyGoldCrownPainter()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVictoryTitleRow() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 34,
            height: 36,
            child: CustomPaint(
              painter: _MiniLaurelPainter(flipHorizontal: false),
            ),
          ),
          const SizedBox(width: 6),
          Stack(
            children: [
              // Deep 3D bronze extrusion shadow
              Transform.translate(
                offset: const Offset(0, 3.2),
                child: Text(
                  'VICTORY!',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8,
                    color: const Color(0xFF6B2D00).withValues(alpha: 0.92),
                    height: 1.0,
                  ),
                ),
              ),
              // Metallic 24K Gold front text
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFFDE7),
                    Color(0xFFFFE55C),
                    Color(0xFFFFC107),
                    Color(0xFFFF8F00),
                  ],
                  stops: [0.0, 0.32, 0.70, 1.0],
                ).createShader(bounds),
                child: const Text(
                  'VICTORY!',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          const SizedBox(
            width: 34,
            height: 36,
            child: CustomPaint(
              painter: _MiniLaurelPainter(flipHorizontal: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinnerSubtitle(LudoPlayer? winner) {
    if (widget.winningTeam != null) {
      return Column(
        children: [
          Text(
            'TEAM ${widget.winningTeam} WINS!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFFFE066),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Co-op victory! All 8 team tokens reached Home.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      );
    }

    if (winner == null) return const SizedBox.shrink();

    // Highlight parenthesized color e.g. "(Red)" in bright gold just like reference
    final fullName = winner.name;
    final parenStart = fullName.indexOf('(');
    final parenEnd = fullName.indexOf(')');
    final List<InlineSpan> spans;
    if (parenStart >= 0 && parenEnd > parenStart) {
      spans = [
        TextSpan(text: fullName.substring(0, parenStart)),
        TextSpan(
          text: fullName.substring(parenStart, parenEnd + 1),
          style: const TextStyle(
            color: Color(0xFFFFEE58),
            fontWeight: FontWeight.w900,
          ),
        ),
        TextSpan(text: '${fullName.substring(parenEnd + 1)} Wins the Match!'),
      ];
    } else {
      spans = [
        TextSpan(
          text: fullName,
          style: const TextStyle(
            color: Color(0xFFFFEE58),
            fontWeight: FontWeight.w900,
          ),
        ),
        const TextSpan(text: ' Wins the Match!'),
      ];
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CustomPaint(
              painter: _Mini3DPawnPainter(
                baseColor: winner.primaryColor,
                lightColor: winner.lightColor,
                darkColor: winner.darkColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 4,
                    offset: Offset(0, 1.5),
                  ),
                ],
              ),
              children: spans,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandingsContainer() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1F166E).withValues(alpha: 0.72),
            const Color(0xFF140B48).withValues(alpha: 0.85),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF7C4DFF).withValues(alpha: 0.55),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(widget.winners.length, (idx) {
          return _buildStandingRow(widget.winners[idx], idx);
        }),
      ),
    );
  }

  Widget _buildStandingRow(LudoPlayer player, int index) {
    final bool isFirst = index == 0;
    final bool isLast = index == widget.winners.length - 1;

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 9),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: isFirst
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFA81D13),
                  Color(0xFF7B110B),
                  Color(0xFF5D0C08),
                ],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0E2F7E),
                  Color(0xFF08205C),
                  Color(0xFF061745),
                ],
              ),
        border: Border.all(
          color: isFirst
              ? const Color(0xFFFFB74D)
              : const Color(0xFF3D68C4).withValues(alpha: 0.65),
          width: isFirst ? 2.0 : 1.2,
        ),
        boxShadow: isFirst
            ? [
                BoxShadow(
                  color: const Color(0xFFFF8F00).withValues(alpha: 0.55),
                  blurRadius: 12,
                  spreadRadius: 0.5,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          // Laurel Wreath Rank Medal (1ST Gold / 2ND Silver / 3RD Bronze)
          SizedBox(
            width: 50,
            height: 36,
            child: CustomPaint(
              painter: _RankLaurelMedalPainter(rank: index + 1),
            ),
          ),
          const SizedBox(width: 8),

          // Sculpted 3D Glossy Pawn matching player's color
          SizedBox(
            width: 28,
            height: 28,
            child: CustomPaint(
              painter: _Mini3DPawnPainter(
                baseColor: player.primaryColor,
                lightColor: player.lightColor,
                darkColor: player.darkColor,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Player Name
          Expanded(
            child: Text(
              player.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isFirst ? FontWeight.w800 : FontWeight.w700,
                fontSize: 15.5,
                shadows: const [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),

          // Mini Golden Trophy on the 1ST row
          if (isFirst)
            const SizedBox(
              width: 28,
              height: 28,
              child: CustomPaint(painter: _MiniGoldTrophyPainter()),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Glossy Blue Pill "Main Menu" Button
        Expanded(
          child: _GlossyVictoryButton(
            label: 'Main Menu',
            icon: Icons.home_rounded,
            topColor: const Color(0xFF40C4FF),
            midColor: const Color(0xFF0288D1),
            bottomColor: const Color(0xFF0147A3),
            borderColor: const Color(0xFF80D8FF),
            glowColor: const Color(0xFF00B0FF),
            foregroundColor: Colors.white,
            onTap: widget.onMainMenu,
          ),
        ),
        const SizedBox(width: 12),

        // Glossy 24K Gold Pill "Play Again" Button
        Expanded(
          child: _GlossyVictoryButton(
            label: 'Play Again',
            icon: Icons.refresh_rounded,
            topColor: const Color(0xFFFFF59D),
            midColor: const Color(0xFFFFCA28),
            bottomColor: const Color(0xFFFF8F00),
            borderColor: const Color(0xFFFFF9C4),
            glowColor: const Color(0xFFFFB300),
            foregroundColor: const Color(0xFF3E1800),
            onTap: widget.onPlayAgain,
          ),
        ),
      ],
    );
  }
}

/// Glossy 3D capsule pill button matching the reference's blue Main Menu & gold Play Again buttons.
class _GlossyVictoryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color topColor;
  final Color midColor;
  final Color bottomColor;
  final Color borderColor;
  final Color glowColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  const _GlossyVictoryButton({
    required this.label,
    required this.icon,
    required this.topColor,
    required this.midColor,
    required this.bottomColor,
    required this.borderColor,
    required this.glowColor,
    required this.foregroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [topColor, midColor, bottomColor],
              stops: const [0.0, 0.45, 1.0],
            ),
            border: Border.all(color: borderColor, width: 2.0),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.55),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Top glossy jelly specular highlight bar
              Positioned(
                top: 3,
                left: 14,
                right: 14,
                height: 15,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.52),
                        Colors.white.withValues(alpha: 0.04),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: foregroundColor, size: 22),
                      const SizedBox(width: 7),
                      Text(
                        label,
                        style: TextStyle(
                          color: foregroundColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 15.5,
                          letterSpacing: 0.3,
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
}

/// Top Hero Crest: Rotating sunburst + twin curved golden laurel branches +
/// sculpted 3D golden trophy + jeweled royal crown (cyan center gem & ruby side gems).
class _VictoryTrophyCrestPainter extends CustomPainter {
  final double progress;
  final Color winnerColor;

  const _VictoryTrophyCrestPainter({
    required this.progress,
    required this.winnerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.55;

    // 1. Soft Rotating Sunburst Rays behind the trophy
    canvas.save();
    canvas.translate(cx, cy + 8);
    canvas.rotate(progress * 2 * pi * 0.35);
    const rays = 14;
    final rayR = size.width * 0.46;
    final rayPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD54F).withValues(alpha: 0.55),
          const Color(0xFF9C4DFF).withValues(alpha: 0.25),
          Colors.transparent,
        ],
        stops: const [0.0, 0.52, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: rayR));

    for (int i = 0; i < rays; i++) {
      final a = i * (2 * pi / rays);
      final p = Path()
        ..moveTo(0, 0)
        ..lineTo(cos(a - 0.10) * rayR, sin(a - 0.10) * rayR)
        ..lineTo(cos(a + 0.10) * rayR, sin(a + 0.10) * rayR)
        ..close();
      canvas.drawPath(p, rayPaint);
    }
    canvas.restore();

    // Warm golden aura bloom behind trophy
    canvas.drawCircle(
      Offset(cx, cy),
      54,
      Paint()
        ..color = const Color(0xFFFFC107).withValues(alpha: 0.38)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    // 2. Twin Curved Golden Laurel Branches flanking left & right of trophy
    _drawLaurelBranch(canvas, Offset(cx, cy + 38), flipX: false);
    _drawLaurelBranch(canvas, Offset(cx, cy + 38), flipX: true);

    final trophyRect = Rect.fromCenter(center: Offset(cx, cy), width: 110, height: 110);
    final goldGrad = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFFFBE6),
        Color(0xFFFFDF59),
        Color(0xFFFFB300),
        Color(0xFFD97706),
        Color(0xFFFFE082),
      ],
      stops: [0.0, 0.28, 0.58, 0.84, 1.0],
    );
    final rimStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = const Color(0xFF6B3400);

    // 3. Sculpted Trophy Handles (graceful double S-curves)
    final handlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.2
      ..strokeCap = StrokeCap.round
      ..shader = goldGrad.createShader(trophyRect);

    for (final sign in const [-1.0, 1.0]) {
      final hPath = Path()
        ..moveTo(cx + sign * 28, cy - 26)
        ..cubicTo(
          cx + sign * 58,
          cy - 32,
          cx + sign * 54,
          cy + 8,
          cx + sign * 20,
          cy + 14,
        );
      canvas.drawPath(
        hPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8.4
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF7A3E00),
      );
      canvas.drawPath(hPath, handlePaint);
    }

    // 4. Stepped Golden Pedestal Base + Stem
    final baseBottom = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 44), width: 54, height: 11),
      const Radius.circular(5),
    );
    final baseMid = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 36), width: 38, height: 9),
      const Radius.circular(4),
    );
    final stemPath = Path()
      ..moveTo(cx - 8, cy + 16)
      ..lineTo(cx + 8, cy + 16)
      ..lineTo(cx + 12, cy + 33)
      ..lineTo(cx - 12, cy + 33)
      ..close();

    canvas.drawPath(stemPath, Paint()..shader = goldGrad.createShader(trophyRect));
    canvas.drawPath(stemPath, rimStroke);
    canvas.drawRRect(baseMid, Paint()..shader = goldGrad.createShader(trophyRect));
    canvas.drawRRect(baseMid, rimStroke);
    canvas.drawRRect(baseBottom, Paint()..shader = goldGrad.createShader(trophyRect));
    canvas.drawRRect(baseBottom, rimStroke);

    // 5. Sculpted 3D Trophy Cup Body
    final cupPath = Path()
      ..moveTo(cx - 34, cy - 34)
      ..lineTo(cx + 34, cy - 34)
      ..cubicTo(cx + 34, cy + 4, cx + 18, cy + 20, cx, cy + 20)
      ..cubicTo(cx - 18, cy + 20, cx - 34, cy + 4, cx - 34, cy - 34)
      ..close();

    // Soft drop shadow
    canvas.drawPath(
      cupPath.shift(const Offset(0, 4)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.42)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(
      cupPath,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.28, -0.35),
          radius: 0.95,
          colors: const [
            Color(0xFFFFFCE0),
            Color(0xFFFFD54F),
            Color(0xFFFFA000),
            Color(0xFFBF6000),
          ],
          stops: const [0.0, 0.35, 0.72, 1.0],
        ).createShader(trophyRect),
    );
    canvas.drawPath(cupPath, rimStroke);

    // Glossy curved specular reflection on cup belly
    final sheenPath = Path()
      ..moveTo(cx - 21, cy - 26)
      ..quadraticBezierTo(cx - 24, cy - 4, cx - 10, cy + 8)
      ..quadraticBezierTo(cx - 16, cy - 4, cx - 13, cy - 26)
      ..close();
    canvas.drawPath(
      sheenPath,
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );

    // Top lip rim of trophy cup
    final lipRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy - 34), width: 72, height: 7),
      const Radius.circular(4),
    );
    canvas.drawRRect(lipRect, Paint()..shader = goldGrad.createShader(trophyRect));
    canvas.drawRRect(lipRect, rimStroke);

    // 6. Royal Jeweled Golden Crown perched right on top of trophy!
    _drawRoyalCrown(canvas, Offset(cx, cy - 54), goldGrad, rimStroke);
  }

  void _drawLaurelBranch(Canvas canvas, Offset origin, {required bool flipX}) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    if (flipX) canvas.scale(-1.0, 1.0);

    // Curved golden stem sweeping out and up around trophy
    final stem = Path()
      ..moveTo(-24, 4)
      ..quadraticBezierTo(-62, -10, -70, -56);
    canvas.drawPath(
      stem,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFFFCA28),
    );

    // 7 paired laurel leaves along the arc
    final leafSpecs = [
      (Offset(-36, -2), -2.55, 11.5),
      (Offset(-46, -12), -2.25, 13.0),
      (Offset(-55, -24), -1.95, 13.5),
      (Offset(-62, -37), -1.72, 13.0),
      (Offset(-67, -50), -1.52, 12.0),
      (Offset(-52, -34), -1.20, 11.5),
      (Offset(-43, -21), -1.45, 11.0),
    ];

    for (final (pos, angle, len) in leafSpecs) {
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(angle);
      final leaf = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(len * 0.5, -len * 0.42, len, 0)
        ..quadraticBezierTo(len * 0.5, len * 0.42, 0, 0)
        ..close();
      canvas.drawPath(
        leaf,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFFF59D), Color(0xFFFFB300), Color(0xFFB26A00)],
          ).createShader(Rect.fromLTWH(0, -len * 0.5, len, len)),
      );
      canvas.drawPath(
        leaf,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7
          ..color = const Color(0xFF7A4400).withValues(alpha: 0.7),
      );
      canvas.restore();
    }

    canvas.restore();
  }

  void _drawRoyalCrown(
    Canvas canvas,
    Offset center,
    LinearGradient goldGrad,
    Paint rimStroke,
  ) {
    final cx = center.dx;
    final cy = center.dy;
    final crownRect = Rect.fromCenter(center: center, width: 68, height: 42);

    // Velvet ruby interior backing inside crown arches
    final velvetPath = Path()
      ..moveTo(cx - 21, cy + 14)
      ..lineTo(cx - 24, cy - 8)
      ..lineTo(cx, cy - 18)
      ..lineTo(cx + 24, cy - 8)
      ..lineTo(cx + 21, cy + 14)
      ..close();
    canvas.drawPath(velvetPath, Paint()..color = const Color(0xFFB71C1C));

    // 5-point royal crown silhouette
    final crownPath = Path()
      ..moveTo(cx - 22, cy + 16)
      ..lineTo(cx - 29, cy - 12)
      ..lineTo(cx - 12, cy + 1)
      ..lineTo(cx, cy - 22)
      ..lineTo(cx + 12, cy + 1)
      ..lineTo(cx + 29, cy - 12)
      ..lineTo(cx + 22, cy + 16)
      ..close();

    canvas.drawPath(crownPath, Paint()..shader = goldGrad.createShader(crownRect));
    canvas.drawPath(crownPath, rimStroke);

    // Crown golden headband
    final bandRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 14), width: 46, height: 8),
      const Radius.circular(4),
    );
    canvas.drawRRect(bandRect, Paint()..shader = goldGrad.createShader(crownRect));
    canvas.drawRRect(bandRect, rimStroke);

    // Pearl dots on crown peaks
    for (final pt in [
      Offset(cx - 29, cy - 14),
      Offset(cx, cy - 24),
      Offset(cx + 29, cy - 14),
    ]) {
      canvas.drawCircle(pt, 3.8, Paint()..color = const Color(0xFFFFF8C2));
      canvas.drawCircle(pt, 3.8, rimStroke..strokeWidth = 1.0);
    }

    // Center Cyan Sapphire Gem + side Ruby Gems (signature reference look!)
    canvas.drawCircle(
      Offset(cx, cy + 5),
      5.2,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFFB3E5FC), Color(0xFF00B0FF), Color(0xFF01579B)],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy + 5), radius: 5.2)),
    );
    canvas.drawCircle(
      Offset(cx, cy + 5),
      5.2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = const Color(0xFFFFF59D),
    );

    for (final dx in const [-14.0, 14.0]) {
      canvas.drawCircle(
        Offset(cx + dx, cy + 8),
        3.2,
        Paint()..color = const Color(0xFFE53935),
      );
      canvas.drawCircle(
        Offset(cx + dx, cy + 8),
        3.2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.9
          ..color = const Color(0xFFFFF59D),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VictoryTrophyCrestPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.winnerColor != winnerColor;
}

/// Curved crimson-red silk ribbon banner with folded tails and 24K gold trim borders.
class _CrimsonChampionRibbonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Folded Left & Right Swallowtail Ribbon Ends
    final leftTail = Path()
      ..moveTo(w * 0.14, h * 0.28)
      ..lineTo(w * 0.02, h * 0.24)
      ..lineTo(w * 0.075, h * 0.58)
      ..lineTo(w * 0.01, h * 0.92)
      ..lineTo(w * 0.16, h * 0.88)
      ..close();
    final rightTail = Path()
      ..moveTo(w * 0.86, h * 0.28)
      ..lineTo(w * 0.98, h * 0.24)
      ..lineTo(w * 0.925, h * 0.58)
      ..lineTo(w * 0.99, h * 0.92)
      ..lineTo(w * 0.84, h * 0.88)
      ..close();

    final tailPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF6A0000), Color(0xFFB71C1C), Color(0xFF6A0000)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(leftTail, tailPaint);
    canvas.drawPath(rightTail, tailPaint);

    // 2. Curved Main Silk Banner Body
    final mainPath = Path()
      ..moveTo(w * 0.10, h * 0.16)
      ..quadraticBezierTo(w * 0.50, -h * 0.04, w * 0.90, h * 0.16)
      ..lineTo(w * 0.88, h * 0.84)
      ..quadraticBezierTo(w * 0.50, h * 0.68, w * 0.12, h * 0.84)
      ..close();

    // Shadow under ribbon
    canvas.drawPath(
      mainPath.shift(const Offset(0, 4)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    canvas.drawPath(
      mainPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF7F0000),
            Color(0xFFD32F2F),
            Color(0xFFE53935),
            Color(0xFFD32F2F),
            Color(0xFF7F0000),
          ],
          stops: [0.0, 0.22, 0.50, 0.78, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // 3. 24K Metallic Gold Top & Bottom Trim Borders
    final goldBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFD48806),
          Color(0xFFFFF59D),
          Color(0xFFFFCA28),
          Color(0xFFFFF59D),
          Color(0xFFD48806),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(mainPath, goldBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TinyGoldCrownPainter extends CustomPainter {
  const _TinyGoldCrownPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.12, h * 0.90)
      ..lineTo(w * 0.04, h * 0.28)
      ..lineTo(w * 0.32, h * 0.56)
      ..lineTo(w * 0.50, h * 0.08)
      ..lineTo(w * 0.68, h * 0.56)
      ..lineTo(w * 0.96, h * 0.28)
      ..lineTo(w * 0.88, h * 0.90)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFD54F));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Small golden laurel sprigs flanking "VICTORY!"
class _MiniLaurelPainter extends CustomPainter {
  final bool flipHorizontal;

  const _MiniLaurelPainter({required this.flipHorizontal});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (flipHorizontal) {
      canvas.translate(size.width, 0);
      canvas.scale(-1.0, 1.0);
    }

    final stem = Path()
      ..moveTo(size.width * 0.85, size.height * 0.88)
      ..quadraticBezierTo(size.width * 0.30, size.height * 0.62, size.width * 0.22, size.height * 0.14);
    canvas.drawPath(
      stem,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFFFCA28),
    );

    final leaves = [
      (Offset(size.width * 0.62, size.height * 0.78), -2.5, 9.0),
      (Offset(size.width * 0.44, size.height * 0.62), -2.2, 9.5),
      (Offset(size.width * 0.32, size.height * 0.44), -1.8, 9.5),
      (Offset(size.width * 0.25, size.height * 0.24), -1.5, 8.5),
      (Offset(size.width * 0.48, size.height * 0.48), -1.1, 8.5),
    ];

    for (final (pos, ang, len) in leaves) {
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(ang);
      final leaf = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(len * 0.5, -len * 0.42, len, 0)
        ..quadraticBezierTo(len * 0.5, len * 0.42, 0, 0)
        ..close();
      canvas.drawPath(
        leaf,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFFF59D), Color(0xFFFFB300)],
          ).createShader(Rect.fromLTWH(0, -len * 0.5, len, len)),
      );
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MiniLaurelPainter oldDelegate) =>
      oldDelegate.flipHorizontal != flipHorizontal;
}

/// Sculpted glossy 3D Ludo pawn matching the gameplay board tokens.
class _Mini3DPawnPainter extends CustomPainter {
  final Color baseColor;
  final Color lightColor;
  final Color darkColor;

  const _Mini3DPawnPainter({
    required this.baseColor,
    required this.lightColor,
    required this.darkColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Ground shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h * 0.88), width: w * 0.78, height: h * 0.22),
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );

    // Base disc
    final baseRect = Rect.fromCenter(
      center: Offset(cx, h * 0.80),
      width: w * 0.74,
      height: h * 0.28,
    );
    canvas.drawOval(
      baseRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [darkColor, baseColor, lightColor, darkColor],
          stops: const [0.0, 0.28, 0.62, 1.0],
        ).createShader(baseRect),
    );

    // Conical body
    final bodyPath = Path()
      ..moveTo(cx - w * 0.14, h * 0.42)
      ..quadraticBezierTo(cx - w * 0.22, h * 0.66, cx - w * 0.34, h * 0.80)
      ..quadraticBezierTo(cx, h * 0.90, cx + w * 0.34, h * 0.80)
      ..quadraticBezierTo(cx + w * 0.22, h * 0.66, cx + w * 0.14, h * 0.42)
      ..close();
    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [darkColor, lightColor, baseColor, darkColor],
          stops: const [0.0, 0.30, 0.62, 1.0],
        ).createShader(Rect.fromLTWH(0, h * 0.40, w, h * 0.50)),
    );

    // Spherical glossy head
    final headCenter = Offset(cx, h * 0.30);
    final headR = w * 0.23;
    canvas.drawCircle(
      headCenter,
      headR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.38),
          radius: 0.95,
          colors: [
            Colors.white.withValues(alpha: 0.92),
            lightColor,
            baseColor,
            darkColor,
          ],
          stops: const [0.0, 0.25, 0.65, 1.0],
        ).createShader(Rect.fromCircle(center: headCenter, radius: headR)),
    );
  }

  @override
  bool shouldRepaint(covariant _Mini3DPawnPainter oldDelegate) =>
      oldDelegate.baseColor != baseColor;
}

/// Laurel Wreath Rank Medal (`1ST` 24K Gold + Star, `2ND` Silver, `3RD` Bronze).
class _RankLaurelMedalPainter extends CustomPainter {
  final int rank;

  const _RankLaurelMedalPainter({required this.rank});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 1;

    final List<Color> metalColors = switch (rank) {
      1 => const [Color(0xFFFFF8C2), Color(0xFFFFCA28), Color(0xFFC47D00)],
      2 => const [Color(0xFFFFFFFF), Color(0xFFCFD8DC), Color(0xFF78909C)],
      3 => const [Color(0xFFFFCC99), Color(0xFFD4813B), Color(0xFF8D4816)],
      _ => const [Color(0xFFB0BEC5), Color(0xFF78909C), Color(0xFF455A64)],
    };

    final Color textColor = rank <= 3 ? const Color(0xFF2B1400) : Colors.white;
    final String label = switch (rank) {
      1 => '1ST',
      2 => '2ND',
      3 => '3RD',
      _ => '#$rank',
    };

    // Left & Right curved mini laurel wreaths
    for (final sign in const [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.scale(sign, 1.0);
      final arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..color = metalColors[1];
      canvas.drawArc(
        Rect.fromCenter(center: Offset.zero, width: size.width * 0.86, height: size.height * 0.88),
        pi * 0.62,
        pi * 0.78,
        false,
        arcPaint,
      );

      for (int i = 0; i < 4; i++) {
        final a = pi * (0.72 + i * 0.20);
        final px = cos(a) * size.width * 0.42;
        final py = sin(a) * size.height * 0.42;
        canvas.save();
        canvas.translate(px, py);
        canvas.rotate(a + 0.5);
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 6.2, height: 3.0),
          Paint()..color = metalColors[0],
        );
        canvas.restore();
      }
      canvas.restore();
    }

    // Center Metallic Coin
    final coinR = size.height * 0.38;
    final coinRect = Rect.fromCircle(center: Offset(cx, cy), radius: coinR);
    canvas.drawCircle(
      Offset(cx, cy),
      coinR,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: metalColors,
        ).createShader(coinRect),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      coinR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = metalColors.last,
    );

    // Tiny golden star perched at top of 1ST medal
    if (rank == 1) {
      final sc = Offset(cx, cy - coinR - 1.5);
      const r = 4.5;
      const inner = 1.6;
      final star = Path()
        ..moveTo(sc.dx, sc.dy - r)
        ..lineTo(sc.dx + inner, sc.dy - inner)
        ..lineTo(sc.dx + r, sc.dy)
        ..lineTo(sc.dx + inner, sc.dy + inner)
        ..lineTo(sc.dx, sc.dy + r)
        ..lineTo(sc.dx - inner, sc.dy + inner)
        ..lineTo(sc.dx - r, sc.dy)
        ..lineTo(sc.dx - inner, sc.dy - inner)
        ..close();
      canvas.drawPath(star, Paint()..color = const Color(0xFFFFF8C2));
    }

    // Rank Text ("1ST", "2ND", "3RD")
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: textColor,
          fontSize: 10.2,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _RankLaurelMedalPainter oldDelegate) =>
      oldDelegate.rank != rank;
}

/// Crisp mini golden trophy icon for the right side of the 1ST place row.
class _MiniGoldTrophyPainter extends CustomPainter {
  const _MiniGoldTrophyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rect = Offset.zero & size;
    final gold = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF8C2), Color(0xFFFFCA28), Color(0xFFC47D00)],
      ).createShader(rect);

    // Handles
    final handle = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xFFFFCA28);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx - 7, cy - 3), width: 7, height: 8),
      pi * 0.5,
      pi,
      false,
      handle,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx + 7, cy - 3), width: 7, height: 8),
      -pi * 0.5,
      pi,
      false,
      handle,
    );

    // Cup
    final cup = Path()
      ..moveTo(cx - 7, cy - 9)
      ..lineTo(cx + 7, cy - 9)
      ..quadraticBezierTo(cx + 7, cy + 2, cx, cy + 3)
      ..quadraticBezierTo(cx - 7, cy + 2, cx - 7, cy - 9)
      ..close();
    canvas.drawPath(cup, gold);

    // Stem + Base
    canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy + 6), width: 3.5, height: 5), gold);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + 9.5), width: 12, height: 3.5),
        const Radius.circular(1.5),
      ),
      gold,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Subtle vibrant confetti curls & glints inside the upper card backdrop.
class _CardSparkleConfettiPainter extends CustomPainter {
  final double progress;

  const _CardSparkleConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final pieces = [
      (x: 0.12, y: 0.16, color: const Color(0xFFFFD54F), rot: -0.6, w: 14.0, h: 6.0),
      (x: 0.08, y: 0.30, color: const Color(0xFF00E5FF), rot: -0.9, w: 13.0, h: 5.5),
      (x: 0.17, y: 0.06, color: const Color(0xFFFF6E91), rot: 0.5, w: 12.0, h: 5.5),
      (x: 0.85, y: 0.15, color: const Color(0xFFFFD54F), rot: 0.4, w: 12.0, h: 5.0),
      (x: 0.90, y: 0.26, color: const Color(0xFF00E676), rot: 0.3, w: 12.0, h: 5.5),
      (x: 0.79, y: 0.07, color: const Color(0xFFE040FB), rot: -0.5, w: 14.0, h: 6.0),
    ];

    for (int i = 0; i < pieces.length; i++) {
      final p = pieces[i];
      final bob = sin(progress * 2 * pi + i * 1.1) * 4.0;
      canvas.save();
      canvas.translate(size.width * p.x, size.height * p.y + bob);
      canvas.rotate(p.rot + sin(progress * 2 * pi + i) * 0.18);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.w, height: p.h),
          const Radius.circular(2.5),
        ),
        Paint()..color = p.color.withValues(alpha: 0.92),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CardSparkleConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Full-screen sky fireworks + 3D tumbling metallic gold & vibrant confetti shower.
class _GrandVictoryFxPainter extends CustomPainter {
  final double progress;
  final Color winnerColor;

  const _GrandVictoryFxPainter({
    required this.progress,
    required this.winnerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final palette = [
      const Color(0xFFFFE066),
      const Color(0xFFFFB300),
      const Color(0xFF00E5FF),
      const Color(0xFFE040FB),
      const Color(0xFF00E676),
      winnerColor,
    ];

    // 1. Four Staggered Sky Firework Bursts around the Victory Card
    final fireworks = [
      (x: 0.16, y: 0.14, offset: 0.00, color: const Color(0xFFFFD54F)),
      (x: 0.85, y: 0.16, offset: 0.25, color: winnerColor),
      (x: 0.14, y: 0.80, offset: 0.50, color: const Color(0xFFE040FB)),
      (x: 0.86, y: 0.78, offset: 0.74, color: const Color(0xFF00E5FF)),
    ];

    for (final fw in fireworks) {
      final ft = (progress + fw.offset) % 1.0;
      if (ft > 0.58) continue;
      final localT = (ft / 0.58).clamp(0.0, 1.0);
      final eased = 1.0 - pow(1.0 - localT, 2.5).toDouble();
      final alpha = (localT < 0.15
              ? localT / 0.15
              : pow(1.0 - localT, 1.5).toDouble())
          .clamp(0.0, 1.0);

      final center = Offset(size.width * fw.x, size.height * fw.y);
      final maxR = min(size.width, size.height) * 0.18;

      if (localT < 0.35) {
        canvas.drawCircle(
          center,
          maxR * 0.45 * eased,
          Paint()
            ..color = fw.color.withValues(alpha: 0.30 * (1.0 - localT / 0.35))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
        );
      }

      const rayCount = 14;
      for (int r = 0; r < rayCount; r++) {
        final a = r * (2 * pi / rayCount) + fw.offset * 3.0;
        final headDist = maxR * eased;
        final tailDist = max(0.0, headDist - 16.0 * (1.0 - localT * 0.5));
        final grav = localT * localT * 18.0;

        final head = Offset(
          center.dx + cos(a) * headDist,
          center.dy + sin(a) * headDist + grav,
        );
        final tail = Offset(
          center.dx + cos(a) * tailDist,
          center.dy + sin(a) * tailDist + grav * 0.7,
        );

        canvas.drawLine(
          tail,
          head,
          Paint()
            ..strokeWidth = 2.0 * (1.0 - localT * 0.4)
            ..strokeCap = StrokeCap.round
            ..color = fw.color.withValues(alpha: 0.90 * alpha),
        );
        canvas.drawCircle(
          head,
          1.9 * (1.0 - localT * 0.4),
          Paint()..color = Colors.white.withValues(alpha: 0.95 * alpha),
        );
      }
    }

    // 2. Continuous 3D Tumbling Metallic Confetti Shower across full screen
    final rng = Random(2026);
    for (int i = 0; i < 60; i++) {
      final startX = rng.nextDouble() * size.width;
      final startY = rng.nextDouble() * size.height;
      final speedY = 0.65 + rng.nextDouble() * 0.85;
      final swayAmp = 14.0 + rng.nextDouble() * 22.0;
      final swayFreq = 1.0 + rng.nextInt(2).toDouble();
      final phase = rng.nextDouble() * 2 * pi;
      final pSize = 5.5 + rng.nextDouble() * 5.5;
      final color = palette[i % palette.length];

      final y = (startY + progress * size.height * speedY) % size.height;
      final x = startX + sin(progress * 2 * pi * swayFreq + phase) * swayAmp;
      final flip = cos(progress * 8 * pi + phase).abs().clamp(0.22, 1.0);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * 4 * pi * (i.isEven ? 1 : -1) + phase);
      canvas.scale(1.0, flip);

      final paint = Paint()..color = color.withValues(alpha: 0.88);
      if (i % 3 == 0) {
        canvas.drawCircle(Offset.zero, pSize * 0.42, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: pSize * 1.45,
              height: pSize * 0.62,
            ),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _GrandVictoryFxPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.winnerColor != winnerColor;
}
