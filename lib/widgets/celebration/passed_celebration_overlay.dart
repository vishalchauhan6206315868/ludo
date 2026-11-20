import 'dart:math';
import 'package:flutter/material.dart';
import '../../constants/ludo_colors.dart';
import '../../models/ludo_player.dart';
import '../../models/token.dart';

/// Data passed when a token reaches the home goal
class PassedCelebrationData {
  final Token token;
  final LudoPlayer player;
  final int timestamp;

  /// Non-null when this token was the player's 4th & final token (e.g. 1 = 1st place!).
  final int? finishRank;

  const PassedCelebrationData({
    required this.token,
    required this.player,
    required this.timestamp,
    this.finishRank,
  });

  bool get isFirstPlaceWin => finishRank == 1;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PassedCelebrationData &&
          other.token.id == token.id &&
          other.player.color == player.color &&
          other.timestamp == timestamp &&
          other.finishRank == finishRank;

  @override
  int get hashCode =>
      Object.hash(token.id, player.color, timestamp, finishRank);
}

/// Pure visual, card-free royal board celebration triggered when a token enters
/// the Home Triangle:
/// - Rotating 24K golden sunburst glow
/// - 3 staggered expanding energy shockwave rings (Gold, Player-Color, White Sparkle)
/// - Luminous firework spark trails + 3D fluttering metallic confetti & stars
/// - Boxless floating mini 3D golden crown emblem
class PassedCelebrationOverlay extends StatefulWidget {
  final PassedCelebrationData? celebration;
  final double cellSize;
  final double boardSize;

  const PassedCelebrationOverlay({
    super.key,
    required this.celebration,
    required this.cellSize,
    required this.boardSize,
  });

  @override
  State<PassedCelebrationOverlay> createState() =>
      _PassedCelebrationOverlayState();
}

class _PassedCelebrationOverlayState extends State<PassedCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  List<_ConfettiParticle> _confetti = [];
  List<_FireworkSpark> _sparks = [];
  int _lastTimestamp = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1220),
    );

    if (widget.celebration != null) {
      _triggerCelebration(widget.celebration!);
    }
  }

  @override
  void didUpdateWidget(covariant PassedCelebrationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.celebration != null &&
        widget.celebration!.timestamp != _lastTimestamp) {
      _triggerCelebration(widget.celebration!);
    }
  }

  void _triggerCelebration(PassedCelebrationData celebration) {
    _lastTimestamp = celebration.timestamp;
    final bool isGrand = celebration.isFirstPlaceWin;
    _animController.duration =
        Duration(milliseconds: isGrand ? 1550 : 1220);
    _confetti = _generateConfetti(celebration.player, isGrand: isGrand);
    _sparks = _generateSparks(celebration.player, isGrand: isGrand);
    _animController.forward(from: 0.0);
  }

  List<_FireworkSpark> _generateSparks(LudoPlayer player, {bool isGrand = false}) {
    final rand = Random(_lastTimestamp ^ 0x5F37);
    final count = isGrand ? 30 : 18;
    final primary = player.primaryColor;
    final light = player.lightColor;

    return List.generate(count, (i) {
      final angle = (i * (2 * pi / count)) + (rand.nextDouble() * 0.22 - 0.11);
      final maxRadius = widget.boardSize *
          (isGrand
              ? (0.34 + rand.nextDouble() * 0.22)
              : (0.28 + rand.nextDouble() * 0.18));
      final tailLength = (isGrand ? 20.0 : 14.0) + rand.nextDouble() * 14.0;
      final isGold = i % 3 != 0;
      return _FireworkSpark(
        angle: angle,
        maxRadius: maxRadius,
        tailLength: tailLength,
        color: isGold ? const Color(0xFFFFE066) : light,
        glowColor: isGold ? const Color(0xFFFF9800) : primary,
        delay: rand.nextDouble() * (isGrand ? 0.14 : 0.08),
      );
    });
  }

  List<_ConfettiParticle> _generateConfetti(LudoPlayer player, {bool isGrand = false}) {
    final rand = Random(_lastTimestamp);
    final count = isGrand ? 74 : 48;
    final primary = player.primaryColor;
    final light = player.lightColor;

    final palette = [
      const Color(0xFFFFE066), // Bright 24K Gold
      const Color(0xFFFFB300), // Rich Gold
      const Color(0xFFFFFFFF), // Pure Sparkle White
      primary,
      light,
      const Color(0xFFFFF59D), // Champagne Gold
    ];

    return List.generate(count, (i) {
      final angle = (i * (2 * pi / count)) + (rand.nextDouble() * 0.40 - 0.20);
      final speed = widget.boardSize *
          (isGrand
              ? (0.22 + rand.nextDouble() * 0.34)
              : (0.18 + rand.nextDouble() * 0.26));
      final size = (isGrand ? 5.6 : 4.8) + rand.nextDouble() * 5.8;
      final rotSpeed = (rand.nextDouble() - 0.5) * 9.5;
      final flipSpeed = 4.0 + rand.nextDouble() * 7.0;
      final color = palette[rand.nextInt(palette.length)];
      // 0: 3D ribbon strip, 1: 4-point star, 2: diamond foil
      final shapeType = i % 3;

      return _ConfettiParticle(
        angle: angle,
        speed: speed,
        size: size,
        rotationSpeed: rotSpeed,
        flipSpeed: flipSpeed,
        color: color,
        shapeType: shapeType,
        upwardBoost: (isGrand ? 20.0 : 12.0) + rand.nextDouble() * 24.0,
      );
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.celebration == null && !_animController.isAnimating) {
      return const SizedBox.shrink();
    }

    final player = widget.celebration?.player;
    final playerColor = player?.primaryColor ?? LudoColors.yellow;
    final playerLight = player?.lightColor ?? const Color(0xFFFFF59D);

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          final t = _animController.value;
          if (t <= 0.0 || t >= 1.0) {
            return const SizedBox.shrink();
          }

          return SizedBox(
            width: widget.boardSize,
            height: widget.boardSize,
            child: CustomPaint(
              size: Size(widget.boardSize, widget.boardSize),
              painter: _RoyalHomeCelebrationPainter(
                confetti: _confetti,
                sparks: _sparks,
                progress: t,
                boardCenter: Offset(widget.boardSize / 2, widget.boardSize / 2),
                playerColor: playerColor,
                playerLight: playerLight,
                cellSize: widget.cellSize,
                isGrandWin: widget.celebration?.isFirstPlaceWin ?? false,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FireworkSpark {
  final double angle;
  final double maxRadius;
  final double tailLength;
  final Color color;
  final Color glowColor;
  final double delay;

  const _FireworkSpark({
    required this.angle,
    required this.maxRadius,
    required this.tailLength,
    required this.color,
    required this.glowColor,
    required this.delay,
  });
}

class _ConfettiParticle {
  final double angle;
  final double speed;
  final double size;
  final double rotationSpeed;
  final double flipSpeed;
  final Color color;
  final int shapeType;
  final double upwardBoost;

  const _ConfettiParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.rotationSpeed,
    required this.flipSpeed,
    required this.color,
    required this.shapeType,
    required this.upwardBoost,
  });
}

/// Pure board-native royal celebration painter (no blocking center card):
/// 1. Center golden sunburst flash & rotating sun rays
/// 2. 3 staggered expanding energy waves (24K Gold, Player-Color, White Sparkle)
/// 3. Firework spark streaks with luminous comet tails
/// 4. 3D fluttering foil confetti ribbons & stars
/// 5. Boxless floating mini 3D golden crown rising from the Home Triangle
class _RoyalHomeCelebrationPainter extends CustomPainter {
  final List<_ConfettiParticle> confetti;
  final List<_FireworkSpark> sparks;
  final double progress;
  final Offset boardCenter;
  final Color playerColor;
  final Color playerLight;
  final double cellSize;
  final bool isGrandWin;

  const _RoyalHomeCelebrationPainter({
    required this.confetti,
    required this.sparks,
    required this.progress,
    required this.boardCenter,
    required this.playerColor,
    required this.playerLight,
    required this.cellSize,
    this.isGrandWin = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress;
    final boost = isGrandWin ? 1.38 : 1.0;

    // 1. Center Golden Sunburst Glow + Rotating Tapered Light Rays
    final sunAlpha = t < 0.15
        ? (t / 0.15)
        : pow((1.0 - ((t - 0.15) / 0.85)).clamp(0.0, 1.0), 1.4).toDouble();
    if (sunAlpha > 0.01) {
      final glowR =
          size.width * (0.14 + 0.16 * Curves.easeOut.transform(t)) * boost;
      canvas.drawCircle(
        boardCenter,
        glowR,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFFBE6).withValues(alpha: 0.85 * sunAlpha),
              const Color(0xFFFFD54F).withValues(alpha: 0.48 * sunAlpha),
              playerColor.withValues(alpha: 0.22 * sunAlpha),
              Colors.transparent,
            ],
            stops: const [0.0, 0.36, 0.70, 1.0],
          ).createShader(Rect.fromCircle(center: boardCenter, radius: glowR)),
      );

      // Rotating golden sunburst rays (16 rays for 1st-place grand burst, 12 normal)
      canvas.save();
      canvas.translate(boardCenter.dx, boardCenter.dy);
      canvas.rotate(t * (isGrandWin ? 1.35 : 0.95));
      final rayCount = isGrandWin ? 16 : 12;
      final rayLen = size.width *
          (0.18 + 0.15 * Curves.easeOutCubic.transform(t)) *
          boost;
      final rayPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF8D6).withValues(alpha: 0.62 * sunAlpha),
            const Color(0xFFFFCA28).withValues(alpha: 0.25 * sunAlpha),
            Colors.transparent,
          ],
          stops: const [0.0, 0.50, 1.0],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: rayLen));

      for (int i = 0; i < rayCount; i++) {
        final a = i * (2 * pi / rayCount);
        const halfSpread = 0.085;
        final path = Path()
          ..moveTo(0, 0)
          ..lineTo(cos(a - halfSpread) * rayLen, sin(a - halfSpread) * rayLen)
          ..lineTo(cos(a + halfSpread) * rayLen, sin(a + halfSpread) * rayLen)
          ..close();
        canvas.drawPath(path, rayPaint);
      }
      canvas.restore();
    }

    // 2. Staggered Expanding Shockwave Rings (3 normal, 4 grand golden waves on 1st-place win)
    final waves = [
      (start: 0.00, dur: 0.74, maxR: isGrandWin ? 0.52 : 0.44, color: const Color(0xFFFFD54F), width: isGrandWin ? 5.2 : 4.2, bloom: true),
      (start: 0.11, dur: 0.76, maxR: isGrandWin ? 0.48 : 0.41, color: playerColor, width: isGrandWin ? 4.4 : 3.6, bloom: true),
      (start: 0.22, dur: 0.74, maxR: isGrandWin ? 0.44 : 0.37, color: const Color(0xFFFFFDF2), width: 2.5, bloom: false),
      if (isGrandWin)
        (start: 0.33, dur: 0.66, maxR: 0.46, color: const Color(0xFFFFB300), width: 3.4, bloom: true),
    ];

    for (final w in waves) {
      if (t < w.start || t > w.start + w.dur) continue;
      final wt = ((t - w.start) / w.dur).clamp(0.0, 1.0);
      final eased = Curves.easeOutCubic.transform(wt);
      final radius = (size.width * 0.04) + (size.width * w.maxR * eased);
      final alpha = pow(1.0 - wt, 1.35).toDouble().clamp(0.0, 1.0);
      if (alpha <= 0.01) continue;

      if (w.bloom) {
        canvas.drawCircle(
          boardCenter,
          radius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = (w.width * 2.4) * (1.0 - wt * 0.4)
            ..color = w.color.withValues(alpha: alpha * 0.32)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0),
        );
      }

      canvas.drawCircle(
        boardCenter,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w.width * (1.0 - wt * 0.55)
          ..color = w.color.withValues(alpha: alpha * 0.92),
      );
    }

    // 3. Firework Spark Streaks with Luminous Comet Tails
    for (final s in sparks) {
      final st = ((t - s.delay) / 0.70).clamp(0.0, 1.0);
      if (st <= 0.0 || st >= 1.0) continue;

      final eased = 1.0 - pow(1.0 - st, 2.6).toDouble();
      final headDist = s.maxRadius * eased;
      final tailDist = max(0.0, headDist - s.tailLength * (1.0 - st * 0.65));
      final alpha = (st < 0.15 ? st / 0.15 : pow(1.0 - st, 1.4).toDouble())
          .clamp(0.0, 1.0);

      final head = Offset(
        boardCenter.dx + cos(s.angle) * headDist,
        boardCenter.dy + sin(s.angle) * headDist,
      );
      final tail = Offset(
        boardCenter.dx + cos(s.angle) * tailDist,
        boardCenter.dy + sin(s.angle) * tailDist,
      );

      // Soft bloom trail
      canvas.drawLine(
        tail,
        head,
        Paint()
          ..strokeWidth = 3.2 * (1.0 - st * 0.4)
          ..strokeCap = StrokeCap.round
          ..color = s.glowColor.withValues(alpha: 0.42 * alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0),
      );
      // Bright incandescent core streak
      canvas.drawLine(
        tail,
        head,
        Paint()
          ..strokeWidth = 1.7 * (1.0 - st * 0.35)
          ..strokeCap = StrokeCap.round
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              s.color.withValues(alpha: 0.0),
              s.color.withValues(alpha: 0.95 * alpha),
            ],
          ).createShader(Rect.fromPoints(tail, head).inflate(2.0)),
      );
      // Bright spark head dot
      canvas.drawCircle(
        head,
        2.1 * (1.0 - st * 0.4),
        Paint()..color = const Color(0xFFFFFEF2).withValues(alpha: 0.95 * alpha),
      );
    }

    // 4. 3D Fluttering Foil Confetti Ribbons & 4-Point Stars
    final confettiAlpha = t < 0.10
        ? (t / 0.10)
        : (1.0 - ((t - 0.10) / 0.90)).clamp(0.0, 1.0);
    if (confettiAlpha > 0.01) {
      for (final p in confetti) {
        final dist = p.speed * (1.0 - pow(1.0 - t, 2.3).toDouble());
        final gravity = (t * t * 56.0) - (sin(t * pi) * p.upwardBoost);
        final dx = boardCenter.dx + cos(p.angle) * dist;
        final dy = boardCenter.dy + sin(p.angle) * dist + gravity;

        canvas.save();
        canvas.translate(dx, dy);
        canvas.rotate(p.rotationSpeed * t);

        // 3D paper-ribbon flip along X axis
        final flipScale = cos(p.flipSpeed * t).abs().clamp(0.22, 1.0);
        final fillPaint = Paint()
          ..color = p.color.withValues(alpha: confettiAlpha * 0.95)
          ..style = PaintingStyle.fill;

        switch (p.shapeType) {
          case 0:
            // 3D tumbling metallic ribbon
            canvas.scale(1.0, flipScale);
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromCenter(
                  center: Offset.zero,
                  width: p.size * 1.55,
                  height: p.size * 0.62,
                ),
                const Radius.circular(1.5),
              ),
              fillPaint,
            );
            break;
          case 1:
            // Crisp 4-point star sparkle
            final r = p.size * 0.85;
            final inner = r * 0.28;
            final starPath = Path();
            for (int k = 0; k < 4; k++) {
              final a1 = k * (pi / 2);
              final a2 = a1 + (pi / 4);
              if (k == 0) {
                starPath.moveTo(cos(a1) * r, sin(a1) * r);
              } else {
                starPath.lineTo(cos(a1) * r, sin(a1) * r);
              }
              starPath.lineTo(cos(a2) * inner, sin(a2) * inner);
            }
            starPath.close();
            canvas.drawPath(starPath, fillPaint);
            break;
          case 2:
          default:
            // Glittering diamond foil
            canvas.scale(flipScale, 1.0);
            final r = p.size * 0.68;
            final diamond = Path()
              ..moveTo(0, -r)
              ..lineTo(r * 0.72, 0)
              ..lineTo(0, r)
              ..lineTo(-r * 0.72, 0)
              ..close();
            canvas.drawPath(diamond, fillPaint);
            break;
        }
        canvas.restore();
      }
    }

    // 5. Boxless Floating Mini 3D Golden Crown Emblem (no card, no dark rectangle!)
    _drawFloatingGoldenCrown(canvas, t);
  }

  void _drawFloatingGoldenCrown(Canvas canvas, double t) {
    final crownAlpha = t < 0.14
        ? (t / 0.14)
        : (t < 0.68
            ? 1.0
            : (1.0 - ((t - 0.68) / 0.32)).clamp(0.0, 1.0));
    if (crownAlpha <= 0.01) return;

    final popScale = t < 0.24
        ? Curves.elasticOut.transform((t / 0.24).clamp(0.0, 1.0))
        : 1.0 + (t - 0.24) * 0.08;
    final floatY = -Curves.easeOutCubic.transform(t) *
        (cellSize * (isGrandWin ? 1.85 : 1.45));
    final crownSize = (cellSize * (isGrandWin ? 2.25 : 1.55))
        .clamp(isGrandWin ? 38.0 : 26.0, isGrandWin ? 62.0 : 44.0);

    canvas.save();
    canvas.translate(boardCenter.dx, boardCenter.dy + floatY);
    canvas.scale(popScale);

    // Warm golden aura glow directly behind crown (zero box/border)
    canvas.drawCircle(
      Offset.zero,
      crownSize * 0.68,
      Paint()
        ..color = const Color(0xFFFFD54F).withValues(alpha: 0.42 * crownAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9.0),
    );

    final w = crownSize;
    final h = crownSize * 0.74;
    final crownPath = Path()
      ..moveTo(-w * 0.44, h * 0.34)
      ..lineTo(-w * 0.50, -h * 0.22)
      ..lineTo(-w * 0.20, h * 0.04)
      ..lineTo(0.0, -h * 0.46)
      ..lineTo(w * 0.20, h * 0.04)
      ..lineTo(w * 0.50, -h * 0.22)
      ..lineTo(w * 0.44, h * 0.34)
      ..close();

    // Soft drop shadow
    canvas.drawPath(
      crownPath.shift(const Offset(0, 2.5)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45 * crownAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0),
    );

    // 24K Metallic Gold Crown Fill
    final crownRect = Rect.fromCenter(center: Offset.zero, width: w, height: h);
    canvas.drawPath(
      crownPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFFF9C4).withValues(alpha: crownAlpha),
            const Color(0xFFFFCA28).withValues(alpha: crownAlpha),
            const Color(0xFFC47D00).withValues(alpha: crownAlpha),
          ],
        ).createShader(crownRect),
    );

    // Crisp rim outline
    canvas.drawPath(
      crownPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF5C3200).withValues(alpha: 0.85 * crownAlpha),
    );

    // 3 tiny crown peak jewels (player-color center ruby/sapphire/emerald + gold side pearls)
    final peaks = [
      (Offset(-w * 0.50, -h * 0.24), const Color(0xFFFFF8E1), w * 0.075),
      (Offset(0.0, -h * 0.48), playerLight, w * 0.095),
      (Offset(w * 0.50, -h * 0.24), const Color(0xFFFFF8E1), w * 0.075),
    ];
    for (final (pos, jewelColor, r) in peaks) {
      canvas.drawCircle(
        pos,
        r,
        Paint()..color = jewelColor.withValues(alpha: crownAlpha),
      );
    }

    // Center player-color gem on crown band
    canvas.drawCircle(
      Offset(0, h * 0.14),
      w * 0.09,
      Paint()..color = playerColor.withValues(alpha: crownAlpha),
    );
    canvas.drawCircle(
      Offset(-w * 0.025, h * 0.11),
      w * 0.03,
      Paint()..color = Colors.white.withValues(alpha: 0.85 * crownAlpha),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RoyalHomeCelebrationPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
