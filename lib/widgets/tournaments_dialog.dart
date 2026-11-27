import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Royal 3D Gaming Tournament Selection Dialog for Ludo Supremo.
/// Matches the reference design with 3D jeweled crown, glowing banners,
/// custom 3D tournament emblems (Grand Championship, Daily Knockout, Weekend Blitz),
/// honor medal footer, and exterior 3D pawns.
class TournamentsDialog extends StatelessWidget {
  final void Function(String tournamentName, int prizePool)? onJoinTournament;
  final void Function(String tournamentName, int prizePool, int entryFee)?
      onJoinWithDetails;

  const TournamentsDialog({
    super.key,
    this.onJoinTournament,
    this.onJoinWithDetails,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final viewInsets = mediaQuery.viewInsets.bottom;
    final maxHeight = (screenHeight * 0.92) - viewInsets;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: maxHeight.clamp(400.0, 760.0),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              // 1. Floating Corner Decor (Exterior Dice & Coins)
              Positioned(
                top: 0,
                left: -4,
                child: CustomPaint(
                  size: const Size(36, 36),
                  painter: const _RoyalDicePainter(angle: -0.2),
                ),
              ),
              Positioned(
                top: -2,
                right: -4,
                child: CustomPaint(
                  size: const Size(34, 34),
                  painter: const _RoyalCoinPainter(),
                ),
              ),

              // 2. Main Royal Gaming Modal Container
              Container(
                margin: const EdgeInsets.only(top: 28, bottom: 22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFFFFD54F),
                    width: 3.0,
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF2A085C),
                      Color(0xFF160338),
                      Color(0xFF0A011D),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.5),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: const Color(0xFF7C4DFF).withValues(alpha: 0.35),
                      blurRadius: 22,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 44, 10, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Subtitle Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF260D50),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                const Color(0xFFFFD54F).withValues(alpha: 0.7),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.emoji_events_rounded,
                                color: Color(0xFFFFD54F), size: 15),
                            SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                "Compete with champions & win mega prizes!",
                                style: TextStyle(
                                  color: Color(0xFFFFE082),
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Card 1: GRAND CHAMPIONSHIP
                      _buildTournamentCard(
                        context: context,
                        title: "GRAND CHAMPIONSHIP",
                        badgeText: "KNOCKOUT BRACKET",
                        badgeIcon: Icons.workspace_premium_rounded,
                        badgeGradient: const [
                          Color(0xFFFF1744),
                          Color(0xFFC2185B)
                        ],
                        emblemPainter: const _GrandChampionshipEmblemPainter(),
                        cardGradient: const [
                          Color(0xFF4A0E4E),
                          Color(0xFF2E0836),
                          Color(0xFF1A0022),
                        ],
                        cardBorderColor: const Color(0xFFFF80AB),
                        prizePool: 50,
                        entryFee: 10,
                        playersInfo: "3 Players • 3 Rounds",
                        actionLabel: "REGISTER",
                        onTap: () {
                          Navigator.of(context).pop();
                          onJoinTournament?.call("Grand Championship", 50);
                          onJoinWithDetails?.call(
                              "Grand Championship", 50, 10);
                        },
                      ),

                      const SizedBox(height: 10),

                      // Card 2: DAILY KNOCKOUT
                      _buildTournamentCard(
                        context: context,
                        title: "DAILY KNOCKOUT",
                        badgeText: "LIVE NOW",
                        badgeDot: true,
                        badgeGradient: const [
                          Color(0xFF00E676),
                          Color(0xFF00B0FF)
                        ],
                        emblemPainter: const _DailyKnockoutEmblemPainter(),
                        cardGradient: const [
                          Color(0xFF0D47A1),
                          Color(0xFF0A2E6D),
                          Color(0xFF041738),
                        ],
                        cardBorderColor: const Color(0xFF40C4FF),
                        prizePool: 10,
                        entryFee: 25,
                        playersInfo: "4 Players • Fast Match",
                        actionLabel: "PLAY NOW",
                        onTap: () {
                          Navigator.of(context).pop();
                          onJoinTournament?.call("Daily Knockout", 10);
                          onJoinWithDetails?.call(
                              "Daily Knockout", 10, 25);
                        },
                      ),

                      const SizedBox(height: 10),

                      // Card 3: WEEKEND BLITZ
                      _buildTournamentCard(
                        context: context,
                        title: "WEEKEND BLITZ",
                        badgeText: "SPEED ARENA",
                        badgeIcon: Icons.bolt_rounded,
                        badgeGradient: const [
                          Color(0xFFAB47BC),
                          Color(0xFF6A1B9A)
                        ],
                        emblemPainter: const _WeekendBlitzEmblemPainter(),
                        cardGradient: const [
                          Color(0xFF4A0072),
                          Color(0xFF31004A),
                          Color(0xFF1B0029),
                        ],
                        cardBorderColor: const Color(0xFFEA80FC),
                        prizePool: 25,
                        entryFee: 50,
                        playersInfo: "4 Players • 15s Timer",
                        actionLabel: "ENTER",
                        onTap: () {
                          Navigator.of(context).pop();
                          onJoinTournament?.call("Weekend Blitz", 25);
                          onJoinWithDetails?.call(
                              "Weekend Blitz", 25, 50);
                        },
                      ),

                      const SizedBox(height: 12),

                      // Footer Note Pill with Honor Medal
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C0A38),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color:
                                const Color(0xFFFFD54F).withValues(alpha: 0.6),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFB300)
                                  .withValues(alpha: 0.25),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFFD54F),
                              ),
                              child: const Center(
                                child: Text(
                                  "i",
                                  style: TextStyle(
                                    color: Color(0xFF2A085C),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                "Winners receive direct coin rewards & championship honor badges.",
                                style: TextStyle(
                                  color: Color(0xFFFFF9C4),
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 3D Golden Honor Medal with red ribbons
                            CustomPaint(
                              size: const Size(26, 30),
                              painter: const _HonorMedalPainter(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Top Title Banner with 3D Gold Trophy
              Positioned(
                top: 2,
                child: _buildTitleBanner(),
              ),

              // 4. Jeweled 3D Royal Crown
              Positioned(
                top: -16,
                child: CustomPaint(
                  size: const Size(64, 40),
                  painter: const _RoyalCrownPainter(),
                ),
              ),

              // 5. 3D Close Button (Top Right)
              Positioned(
                top: 14,
                right: 6,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF29B6F6), Color(0xFF0D47A1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: const Color(0xFFFFD54F),
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0D47A1).withValues(alpha: 0.6),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),

              // 6. Bottom Pawns: Red & Green (Left), Blue & Yellow (Right)
              Positioned(
                bottom: -2,
                left: 10,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CustomPaint(
                      size: Size(20, 28),
                      painter: _RoyalPawnPainter(color: Color(0xFFE53935)),
                    ),
                    SizedBox(width: 4),
                    CustomPaint(
                      size: Size(20, 28),
                      painter: _RoyalPawnPainter(color: Color(0xFF43A047)),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: -2,
                right: 10,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CustomPaint(
                      size: Size(20, 28),
                      painter: _RoyalPawnPainter(color: Color(0xFF1E88E5)),
                    ),
                    SizedBox(width: 4),
                    CustomPaint(
                      size: Size(20, 28),
                      painter: _RoyalPawnPainter(color: Color(0xFFFDD835)),
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

  Widget _buildTitleBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFFFD54F),
          width: 2.2,
        ),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E88E5),
            Color(0xFF0D47A1),
            Color(0xFF052163),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E88E5).withValues(alpha: 0.7),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD54F), size: 22),
          SizedBox(width: 7),
          Text(
            "LUDO TOURNAMENTS",
            style: TextStyle(
              fontFamily: 'Roboto',
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
              letterSpacing: 1.0,
              shadows: [
                Shadow(
                  color: Color(0xFFFFB300),
                  blurRadius: 8,
                ),
                Shadow(
                  color: Colors.black,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentCard({
    required BuildContext context,
    required String title,
    required String badgeText,
    IconData? badgeIcon,
    bool badgeDot = false,
    required List<Color> badgeGradient,
    required CustomPainter emblemPainter,
    required List<Color> cardGradient,
    required Color cardBorderColor,
    required int prizePool,
    required int entryFee,
    required String playersInfo,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardBorderColor.withValues(alpha: 0.8),
          width: 1.6,
        ),
        gradient: LinearGradient(
          colors: cardGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: cardBorderColor.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: 3D Emblem with Laurel Wreath & Ribbon
              SizedBox(
                width: 56,
                height: 56,
                child: CustomPaint(
                  painter: emblemPainter,
                ),
              ),
              const SizedBox(width: 8),

              // Middle: Title, Players & Entry/Prize
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12.0,
                          letterSpacing: 0.3,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Players & Rounds
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.group_rounded,
                              color: Color(0xFF40C4FF), size: 12),
                          const SizedBox(width: 3),
                          Text(
                            playersInfo,
                            style: const TextStyle(
                              color: Color(0xFFCFD8DC),
                              fontSize: 10.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Entry & Prize Pool
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Entry
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "ENTRY",
                                style: TextStyle(
                                  color: Color(0xFFB0BEC5),
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.monetization_on,
                                      color: Color(0xFFFFD54F), size: 11),
                                  const SizedBox(width: 2),
                                  Text(
                                    "$entryFee",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.0,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),

                          // Prize Pool
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "PRIZE POOL",
                                style: TextStyle(
                                  color: Color(0xFFFFD54F),
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.emoji_events,
                                      color: Color(0xFFFFD54F), size: 12),
                                  const SizedBox(width: 2),
                                  Text(
                                    "$prizePool COINS",
                                    style: const TextStyle(
                                      color: Color(0xFFFFD54F),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 4),

              // Right: Badge & 3D Action Button
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Badge
                  Container(
                    constraints: const BoxConstraints(maxWidth: 100),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(
                        colors: badgeGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: badgeGradient.first.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (badgeDot) ...[
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 3),
                          ] else if (badgeIcon != null) ...[
                            Icon(badgeIcon, color: Colors.white, size: 9),
                            const SizedBox(width: 2),
                          ],
                          Text(
                            badgeText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 7.8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 3D Action Button
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFFFFDE7),
                          width: 1.2,
                        ),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFEA00),
                            Color(0xFFFFB300),
                            Color(0xFFFF8F00),
                            Color(0xFFE65100),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFFF8F00).withValues(alpha: 0.6),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            actionLabel,
                            style: const TextStyle(
                              color: Color(0xFF2E1100),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Color(0xFF2E1100),
                            size: 9,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom Painters for 3D Emblems, Crown, Medals, Pawns, Dice & Coins
// ---------------------------------------------------------------------------

/// 3D Jeweled Royal Crown with 5 peaks and ruby jewel
class _RoyalCrownPainter extends CustomPainter {
  const _RoyalCrownPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Crown Path (5-peaks)
    final path = Path()
      ..moveTo(width * 0.12, height * 0.88)
      ..lineTo(width * 0.05, height * 0.32)
      ..lineTo(width * 0.28, height * 0.58)
      ..lineTo(width * 0.50, height * 0.08)
      ..lineTo(width * 0.72, height * 0.58)
      ..lineTo(width * 0.95, height * 0.32)
      ..lineTo(width * 0.88, height * 0.88)
      ..close();

    // Crown Gradient
    final crownPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFFDE7),
          Color(0xFFFFE082),
          Color(0xFFFFB300),
          Color(0xFFC45A00),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, width, height));
    canvas.drawPath(path, crownPaint);

    // Crown Outline
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF5D2E00)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // Center Ruby
    final rubyPaint = Paint()..color = const Color(0xFFD50000);
    canvas.save();
    canvas.translate(width * 0.50, height * 0.68);
    canvas.rotate(math.pi / 4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 8, height: 8),
        const Radius.circular(1.5),
      ),
      rubyPaint,
    );
    canvas.restore();

    // Peak Jewels (white pearls with gold rim)
    final pearlPaint = Paint()..color = Colors.white;
    final rimPaint = Paint()
      ..color = const Color(0xFFFF8F00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final pt in [
      Offset(width * 0.05, height * 0.32),
      Offset(width * 0.50, height * 0.08),
      Offset(width * 0.95, height * 0.32),
    ]) {
      canvas.drawCircle(pt, 3.2, pearlPaint);
      canvas.drawCircle(pt, 3.2, rimPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3D Grand Championship Emblem: Golden Trophy Cup + Laurels + Red Curved Ribbon
class _GrandChampionshipEmblemPainter extends CustomPainter {
  const _GrandChampionshipEmblemPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.44);

    // 1. Golden Laurel Wreath Branches on sides
    final laurelPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final yOffset = h * 0.22 + i * 8;
      // Left leaf
      canvas.save();
      canvas.translate(w * 0.18, yOffset);
      canvas.rotate(-0.4 - i * 0.1);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 12, height: 5),
        laurelPaint,
      );
      canvas.restore();

      // Right leaf
      canvas.save();
      canvas.translate(w * 0.82, yOffset);
      canvas.rotate(0.4 + i * 0.1);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 12, height: 5),
        laurelPaint,
      );
      canvas.restore();
    }

    // 2. Trophy Cup Body
    final cupPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF9C4), Color(0xFFFFD54F), Color(0xFFFF8F00)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(w * 0.25, h * 0.12, w * 0.5, h * 0.45));

    final cupPath = Path()
      ..moveTo(w * 0.30, h * 0.16)
      ..lineTo(w * 0.70, h * 0.16)
      ..cubicTo(w * 0.68, h * 0.42, w * 0.60, h * 0.48, w * 0.50, h * 0.48)
      ..cubicTo(w * 0.40, h * 0.48, w * 0.32, h * 0.42, w * 0.30, h * 0.16)
      ..close();
    canvas.drawPath(cupPath, cupPaint);

    // Trophy Handles (Left & Right)
    final handlePaint = Paint()
      ..color = const Color(0xFFFFB300)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final leftHandle = Path()
      ..moveTo(w * 0.32, h * 0.20)
      ..cubicTo(w * 0.16, h * 0.22, w * 0.18, h * 0.38, w * 0.34, h * 0.40);
    canvas.drawPath(leftHandle, handlePaint);

    final rightHandle = Path()
      ..moveTo(w * 0.68, h * 0.20)
      ..cubicTo(w * 0.84, h * 0.22, w * 0.82, h * 0.38, w * 0.66, h * 0.40);
    canvas.drawPath(rightHandle, handlePaint);

    // Stem and Pedestal Base
    final stemPaint = Paint()..color = const Color(0xFFFF8F00);
    canvas.drawRect(
      Rect.fromCenter(
          center: Offset(center.dx, h * 0.52), width: 6, height: 10),
      stemPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(center.dx, h * 0.58), width: 26, height: 6),
        const Radius.circular(2),
      ),
      cupPaint,
    );

    // Center Star on Cup
    final starPaint = Paint()..color = const Color(0xFFFFFDE7);
    _drawStar(canvas, Offset(center.dx, h * 0.30), 5, 6.0, 3.0, starPaint);

    // 3. 3D Curved Red Ribbon at the Base
    _drawCurvedRibbon(
      canvas: canvas,
      size: size,
      mainColor: const Color(0xFFD50000),
      accentColor: const Color(0xFFFF1744),
      shadowColor: const Color(0xFF7F0000),
      ribbonText: "CHAMPION",
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3D Daily Knockout Emblem: Blue Glowing Shield + Lightning Bolt + Green Laurels + Ribbon
class _DailyKnockoutEmblemPainter extends CustomPainter {
  const _DailyKnockoutEmblemPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Green Laurel Wreath on sides
    final greenLaurelPaint = Paint()
      ..color = const Color(0xFF00E676)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final yOffset = h * 0.22 + i * 8;
      canvas.save();
      canvas.translate(w * 0.18, yOffset);
      canvas.rotate(-0.4 - i * 0.1);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 12, height: 5),
        greenLaurelPaint,
      );
      canvas.restore();

      canvas.save();
      canvas.translate(w * 0.82, yOffset);
      canvas.rotate(0.4 + i * 0.1);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 12, height: 5),
        greenLaurelPaint,
      );
      canvas.restore();
    }

    // 2. Royal Blue Shield
    final shieldPath = Path()
      ..moveTo(w * 0.26, h * 0.16)
      ..lineTo(w * 0.74, h * 0.16)
      ..lineTo(w * 0.74, h * 0.42)
      ..cubicTo(w * 0.74, h * 0.58, w * 0.50, h * 0.65, w * 0.50, h * 0.65)
      ..cubicTo(w * 0.50, h * 0.65, w * 0.26, h * 0.58, w * 0.26, h * 0.42)
      ..close();

    final shieldPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF29B6F6), Color(0xFF0288D1), Color(0xFF01579B)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(w * 0.26, h * 0.16, w * 0.48, h * 0.50));
    canvas.drawPath(shieldPath, shieldPaint);

    // Shield Border
    canvas.drawPath(
      shieldPath,
      Paint()
        ..color = const Color(0xFFFFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // 3. Lightning Bolt inside Shield
    final boltPath = Path()
      ..moveTo(w * 0.53, h * 0.20)
      ..lineTo(w * 0.40, h * 0.38)
      ..lineTo(w * 0.50, h * 0.38)
      ..lineTo(w * 0.45, h * 0.56)
      ..lineTo(w * 0.62, h * 0.34)
      ..lineTo(w * 0.52, h * 0.34)
      ..close();

    final boltPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFDE7), Color(0xFFFFEB3B), Color(0xFFFF9800)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(w * 0.40, h * 0.20, w * 0.22, h * 0.36));
    canvas.drawPath(boltPath, boltPaint);

    // 4. 3D Curved Blue Ribbon at base
    _drawCurvedRibbon(
      canvas: canvas,
      size: size,
      mainColor: const Color(0xFF0D47A1),
      accentColor: const Color(0xFF1976D2),
      shadowColor: const Color(0xFF002171),
      ribbonText: "KNOCKOUT",
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3D Weekend Blitz Emblem: Stopwatch with Speed Flames + Violet Ribbon
class _WeekendBlitzEmblemPainter extends CustomPainter {
  const _WeekendBlitzEmblemPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.50, h * 0.40);
    final radius = w * 0.24;

    // 1. Fiery speed motion trails behind stopwatch
    final flamePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF1744), Color(0xFFFF9100), Colors.transparent],
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
      ).createShader(Rect.fromLTWH(w * 0.05, h * 0.20, w * 0.40, h * 0.40));

    final flamePath = Path()
      ..moveTo(w * 0.40, h * 0.25)
      ..quadraticBezierTo(w * 0.10, h * 0.28, w * 0.05, h * 0.38)
      ..quadraticBezierTo(w * 0.18, h * 0.42, w * 0.35, h * 0.45)
      ..quadraticBezierTo(w * 0.08, h * 0.48, w * 0.02, h * 0.55)
      ..quadraticBezierTo(w * 0.20, h * 0.58, w * 0.40, h * 0.55)
      ..close();
    canvas.drawPath(flamePath, flamePaint);

    // 2. Stopwatch Outer Rim
    final rimPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF80AB), Color(0xFFD500F9), Color(0xFF4A148C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, rimPaint);

    // Stopwatch Gold Ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFFFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );

    // Stopwatch Face
    final facePaint = Paint()..color = const Color(0xFF1A002C);
    canvas.drawCircle(center, radius - 3.5, facePaint);

    // Stopwatch Button Top
    canvas.drawRect(
      Rect.fromCenter(
          center: Offset(center.dx, center.dy - radius - 3),
          width: 8,
          height: 5),
      Paint()..color = const Color(0xFFFFD54F),
    );

    // Clock Hands (Fast 15s Blitz)
    final handPaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, Offset(center.dx + 8, center.dy - 6), handPaint);
    canvas.drawLine(center, Offset(center.dx, center.dy - 10), handPaint);

    // Center Pin
    canvas.drawCircle(center, 2.5, Paint()..color = const Color(0xFFFFD54F));

    // 3. 3D Curved Violet Ribbon at Base
    _drawCurvedRibbon(
      canvas: canvas,
      size: size,
      mainColor: const Color(0xFF880E4F),
      accentColor: const Color(0xFFC2185B),
      shadowColor: const Color(0xFF4A002E),
      ribbonText: "BLITZ",
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Helper method to draw a 3D curved ribbon banner with folded ribbon tails and text
void _drawCurvedRibbon({
  required Canvas canvas,
  required Size size,
  required Color mainColor,
  required Color accentColor,
  required Color shadowColor,
  required String ribbonText,
}) {
  final w = size.width;
  final h = size.height;

  // Ribbon Tails (Folded Underneath)
  final leftTail = Path()
    ..moveTo(w * 0.12, h * 0.75)
    ..lineTo(w * 0.02, h * 0.85)
    ..lineTo(w * 0.10, h * 0.88)
    ..lineTo(w * 0.02, h * 0.95)
    ..lineTo(w * 0.18, h * 0.85)
    ..close();
  canvas.drawPath(leftTail, Paint()..color = shadowColor);

  final rightTail = Path()
    ..moveTo(w * 0.88, h * 0.75)
    ..lineTo(w * 0.98, h * 0.85)
    ..lineTo(w * 0.90, h * 0.88)
    ..lineTo(w * 0.98, h * 0.95)
    ..lineTo(w * 0.82, h * 0.85)
    ..close();
  canvas.drawPath(rightTail, Paint()..color = shadowColor);

  // Main Ribbon Body
  final ribbonRect = Rect.fromCenter(
    center: Offset(w * 0.5, h * 0.80),
    width: w * 0.78,
    height: 18,
  );
  final ribbonRRect =
      RRect.fromRectAndRadius(ribbonRect, const Radius.circular(5));

  final ribbonPaint = Paint()
    ..shader = LinearGradient(
      colors: [accentColor, mainColor, shadowColor],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(ribbonRect);
  canvas.drawRRect(ribbonRRect, ribbonPaint);

  // Ribbon Gold Border
  canvas.drawRRect(
    ribbonRRect,
    Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0,
  );

  // Ribbon Text
  final textPainter = TextPainter(
    text: TextSpan(
      text: ribbonText,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontSize: 7.5,
        letterSpacing: 0.8,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  textPainter.paint(
    canvas,
    Offset(
      w * 0.5 - textPainter.width / 2,
      h * 0.80 - textPainter.height / 2,
    ),
  );
}

/// Helper method to draw a regular 5-point star
void _drawStar(Canvas canvas, Offset center, int points, double outerRadius,
    double innerRadius, Paint paint) {
  final path = Path();
  final double step = math.pi / points;
  double angle = -math.pi / 2;

  for (int i = 0; i < points * 2; i++) {
    final r = i.isEven ? outerRadius : innerRadius;
    final x = center.dx + math.cos(angle) * r;
    final y = center.dy + math.sin(angle) * r;
    if (i == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
    angle += step;
  }
  path.close();
  canvas.drawPath(path, paint);
}

/// 3D Golden Honor Medal with red ribbon tails (Footer Decor)
class _HonorMedalPainter extends CustomPainter {
  const _HonorMedalPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.40);
    final radius = w * 0.38;

    // Red Ribbon Tails hanging below
    final ribbonPaint = Paint()..color = const Color(0xFFD50000);
    final leftRibbon = Path()
      ..moveTo(w * 0.35, h * 0.50)
      ..lineTo(w * 0.20, h * 0.95)
      ..lineTo(w * 0.35, h * 0.85)
      ..lineTo(w * 0.45, h * 0.95)
      ..lineTo(w * 0.45, h * 0.50)
      ..close();
    canvas.drawPath(leftRibbon, ribbonPaint);

    final rightRibbon = Path()
      ..moveTo(w * 0.55, h * 0.50)
      ..lineTo(w * 0.55, h * 0.95)
      ..lineTo(w * 0.65, h * 0.85)
      ..lineTo(w * 0.80, h * 0.95)
      ..lineTo(w * 0.65, h * 0.50)
      ..close();
    canvas.drawPath(rightRibbon, ribbonPaint);

    // Medal Outer Rim
    final goldShader = const LinearGradient(
      colors: [Color(0xFFFFFDE7), Color(0xFFFFD54F), Color(0xFFFF8F00)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, Paint()..shader = goldShader);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF5D2E00)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Inner embossed star/crown icon
    canvas.drawCircle(
      center,
      radius - 3.0,
      Paint()..color = const Color(0xFFFFA000),
    );
    _drawStar(canvas, center, 5, 4.5, 2.2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3D Ludo Pawn with glossy highlight reflection
class _RoyalPawnPainter extends CustomPainter {
  final Color color;

  const _RoyalPawnPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Pedestal Base
    final baseRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.88),
      width: w * 0.85,
      height: h * 0.18,
    );
    final basePaint = Paint()
      ..shader = LinearGradient(
        colors: [color, color.withValues(alpha: 0.6), Colors.black],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(baseRect);
    canvas.drawOval(baseRect, basePaint);

    // Pawn Body Cone
    final bodyPath = Path()
      ..moveTo(w * 0.38, h * 0.44)
      ..lineTo(w * 0.62, h * 0.44)
      ..lineTo(w * 0.78, h * 0.82)
      ..lineTo(w * 0.22, h * 0.82)
      ..close();
    canvas.drawPath(bodyPath, basePaint);

    // Collar Ring
    final collarRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.44),
      width: w * 0.45,
      height: h * 0.10,
    );
    canvas.drawOval(collarRect, Paint()..color = const Color(0xFFFFD54F));

    // Head Sphere
    final headCenter = Offset(w * 0.5, h * 0.24);
    final headRadius = w * 0.28;
    final headPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [Colors.white.withValues(alpha: 0.9), color, Colors.black],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: headCenter, radius: headRadius));
    canvas.drawCircle(headCenter, headRadius, headPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Floating 3D Dice Painter
class _RoyalDicePainter extends CustomPainter {
  final double angle;

  const _RoyalDicePainter({this.angle = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.save();
    canvas.translate(w * 0.5, h * 0.5);
    canvas.rotate(angle);

    // Dice Cube (White with soft bevel)
    final diceRect = Rect.fromCenter(
      center: Offset.zero,
      width: w * 0.75,
      height: h * 0.75,
    );
    final diceRRect =
        RRect.fromRectAndRadius(diceRect, const Radius.circular(6));

    canvas.drawRRect(
      diceRRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFE0E0E0), Color(0xFFBDBDBD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(diceRect),
    );

    // Bevel Stroke
    canvas.drawRRect(
      diceRRect,
      Paint()
        ..color = const Color(0xFFFFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Dice Dots (showing 3 or 5 dots)
    final dotPaint = Paint()..color = const Color(0xFFD50000);
    canvas.drawCircle(Offset.zero, 2.2, dotPaint);
    canvas.drawCircle(const Offset(-6, -6), 2.2, dotPaint);
    canvas.drawCircle(const Offset(6, 6), 2.2, dotPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Floating 3D Gold Coin Painter
class _RoyalCoinPainter extends CustomPainter {
  const _RoyalCoinPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final center = Offset(w * 0.5, size.height * 0.5);
    final radius = w * 0.40;

    final coinShader = const LinearGradient(
      colors: [Color(0xFFFFFDE7), Color(0xFFFFD54F), Color(0xFFFF8F00)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, Paint()..shader = coinShader);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF5D2E00)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Coin Inner Star/Symbol
    _drawStar(
        canvas, center, 5, 4.0, 2.0, Paint()..color = const Color(0xFF8D4004));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
