import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../constants/ludo_colors.dart';
import '../../constants/ludo_path.dart';
import '../../logic/ludo_game_controller.dart';
import '../../models/game_state.dart';
import '../../models/token.dart';
import '../token/token_widget.dart';
import '../celebration/passed_celebration_overlay.dart';
import 'board_decorations.dart';

class LudoBoardWidget extends StatelessWidget {
  final LudoGameController controller;
  final double size;

  const LudoBoardWidget({
    super.key,
    required this.controller,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    const double borderWidth = 6.0;
    const double innerBorderWidth = 1.2;
    final boardInnerSize = size - (borderWidth * 2) - (innerBorderWidth * 2);
    final cellSize = boardInnerSize / 15;

    // Gentle 3D tabletop perspective view (~6° natural surface tilt: /_____\):
    // Negative rotateX pulls the front (bottom) edge toward the viewer while
    // receding the top edge slightly, keeping every cell and token tap 100% accurate.
    final tiltMatrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0009)
      ..rotateX(-0.10);

    return Transform.translate(
      offset: Offset(controller.boardShakeOffset, 0),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // 3D Extruded Metallic Gold Bottom Slab (gives real board thickness)
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.translationValues(0, 5.5, 0)
                ..multiply(tiltMatrix),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(21),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF7A4700),
                      Color(0xFFD9910B),
                      Color(0xFF9C5B00),
                      Color(0xFFE6A21E),
                      Color(0xFF6B3C00),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.28),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.72),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ),
            ),

            // Top Luxury 3D Beveled Gold Frame + Board Face
            Transform(
              alignment: Alignment.center,
              transform: tiltMatrix,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFF8C9),
                      Color(0xFFFFD54F),
                      Color(0xFFD48806),
                      Color(0xFFFFEE88),
                      Color(0xFFB26A00),
                    ],
                    stops: [0.0, 0.25, 0.55, 0.80, 1.0],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: const Color(0xFFFFFBE6).withValues(alpha: 0.7),
                    width: 0.8,
                  ),
                ),
                padding: const EdgeInsets.all(borderWidth - 0.8),
                child: Container(
                  decoration: BoxDecoration(
                    color: LudoColors.boardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF3E2600),
                      width: innerBorderWidth,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.5),
                    child: SizedBox(
                      width: boardInnerSize,
                      height: boardInnerSize,
                      child: Stack(
                        children: [
                          // 1. Raised 3D Beveled Track Grid
                          _buildBoardBackground(cellSize),

                          // 2. Four Luxury Base Corners (6x6 each) with Pastel Courts
                          Positioned(
                            left: 0,
                            top: 0,
                            width: 6 * cellSize,
                            height: 6 * cellSize,
                            child: _buildBaseCorner(
                              PlayerColor.red,
                              LudoColors.red,
                              const Color(0xFFFFCDD2),
                              cellSize,
                            ),
                          ),
                          Positioned(
                            left: 9 * cellSize,
                            top: 0,
                            width: 6 * cellSize,
                            height: 6 * cellSize,
                            child: _buildBaseCorner(
                              PlayerColor.green,
                              LudoColors.green,
                              const Color(0xFFC8F0D2),
                              cellSize,
                            ),
                          ),
                          Positioned(
                            left: 0,
                            top: 9 * cellSize,
                            width: 6 * cellSize,
                            height: 6 * cellSize,
                            child: controller.state.mode == GameMode.threePlayer
                                ? Opacity(
                                    opacity: 0.35,
                                    child: _buildBaseCorner(
                                      PlayerColor.blue,
                                      LudoColors.blue,
                                      const Color(0xFFBBDEFB),
                                      cellSize,
                                    ),
                                  )
                                : _buildBaseCorner(
                                    PlayerColor.blue,
                                    LudoColors.blue,
                                    const Color(0xFFBBDEFB),
                                    cellSize,
                                  ),
                          ),
                          Positioned(
                            left: 9 * cellSize,
                            top: 9 * cellSize,
                            width: 6 * cellSize,
                            height: 6 * cellSize,
                            child: _buildBaseCorner(
                              PlayerColor.yellow,
                              LudoColors.yellow,
                              const Color(0xFFFFECB3),
                              cellSize,
                            ),
                          ),

                          // 3. Center 3D Beveled Finish Triangles (3x3)
                          Positioned(
                            left: 6 * cellSize,
                            top: 6 * cellSize,
                            width: 3 * cellSize,
                            height: 3 * cellSize,
                            child: CustomPaint(
                              painter: HomeTrianglePainter(),
                            ),
                          ),

                          // 4. 3D Sculpted Pawns Overlay with smart stacking & strict bounds
                          ..._buildTokenWidgets(cellSize, boardInnerSize),

                          // 5. Passed Home Celebration Overlay
                          PassedCelebrationOverlay(
                            celebration: controller.activeCelebration,
                            cellSize: cellSize,
                            boardSize: boardInnerSize,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardBackground(double cellSize) {
    return Column(
      children: List.generate(15, (row) {
        return Expanded(
          child: Row(
            children: List.generate(15, (col) {
              return Expanded(
                child: _buildCell(col, row, cellSize),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildCell(int col, int row, double cellSize) {
    // 1. Four Corner Bases (6x6 each) - rendered as Positioned overlays in Stack
    if ((col < 6 && row < 6) ||
        (col >= 9 && row < 6) ||
        (col < 6 && row >= 9) ||
        (col >= 9 && row >= 9)) {
      return const SizedBox.shrink();
    }

    // Center 3x3 area - rendered as Positioned HomeTrianglePainter in Stack
    if (col >= 6 && col <= 8 && row >= 6 && row <= 8) {
      return const SizedBox.shrink();
    }

    // 2. Track cells styling
    Color? coloredBg;
    bool isStar = false;
    Color starColor = LudoColors.safeStar;

    // Home Stretches
    if (row == 7 && col >= 1 && col <= 5) {
      coloredBg = LudoColors.red;
    } else if (col == 7 && row >= 1 && row <= 5) {
      coloredBg = LudoColors.green;
    } else if (row == 7 && col >= 9 && col <= 13) {
      coloredBg = LudoColors.yellow;
    } else if (col == 7 && row >= 9 && row <= 13) {
      coloredBg = LudoColors.blue;
    }
    // Start tiles (with color & crisp light star)
    else if (col == 1 && row == 6) {
      coloredBg = LudoColors.red;
      isStar = true;
      starColor = const Color(0xFFFFCDD2);
    } else if (col == 8 && row == 1) {
      coloredBg = LudoColors.green;
      isStar = true;
      starColor = const Color(0xFFC8F0D2);
    } else if (col == 13 && row == 8) {
      coloredBg = LudoColors.yellow;
      isStar = true;
      starColor = const Color(0xFFFFF8E1);
    } else if (col == 6 && row == 13) {
      coloredBg = LudoColors.blue;
      isStar = true;
      starColor = const Color(0xFFBBDEFB);
    }
    // 4 White Safe Star tiles (color-matched to each arm)
    else if (col == 6 && row == 2) {
      isStar = true;
      starColor = LudoColors.green;
    } else if (col == 12 && row == 6) {
      isStar = true;
      starColor = LudoColors.yellow;
    } else if (col == 8 && row == 12) {
      isStar = true;
      starColor = LudoColors.blue;
    } else if (col == 2 && row == 8) {
      isStar = true;
      starColor = LudoColors.red;
    }

    // Raised 3D pillowed tile look (subtle top sheen + bottom bevel)
    final gradient = coloredBg != null
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(coloredBg, Colors.white, 0.14)!,
              coloredBg,
              Color.lerp(coloredBg, Colors.black, 0.14)!,
            ],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF6F8FB),
              Color(0xFFE6ECF4),
            ],
          );

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        border: Border.all(
          color: coloredBg != null
              ? Colors.black.withValues(alpha: 0.24)
              : const Color(0xFF94A3B8).withValues(alpha: 0.62),
          width: 0.75,
        ),
      ),
      child: isStar
          ? Center(
              child: SizedBox(
                width: cellSize * 0.64,
                height: cellSize * 0.64,
                child: CustomPaint(
                  painter: SafeStarPainter(color: starColor),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBaseCorner(
    PlayerColor color,
    Color primaryColor,
    Color pastelCourtColor,
    double cellSize,
  ) {
    final slotSize = cellSize * 1.18;
    final slotOffset1 = 2.0 * cellSize - (slotSize / 2);
    final slotOffset2 = 4.0 * cellSize - (slotSize / 2);

    int? finishedRank;
    for (final p in controller.state.players) {
      if (p.color == color && p.hasFinished && p.rank != null && p.rank! <= 3) {
        finishedRank = p.rank;
        break;
      }
    }

    return Container(
      width: cellSize * 6,
      height: cellSize * 6,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(primaryColor, Colors.white, 0.12)!,
            primaryColor,
            Color.lerp(primaryColor, Colors.black, 0.15)!,
          ],
        ),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.30),
          width: 1.1,
        ),
      ),
      child: Stack(
        children: [
          // Soft pastel rounded inner court (matching luxury board reference)
          Positioned(
            left: cellSize * 0.68,
            top: cellSize * 0.68,
            width: cellSize * 4.64,
            height: cellSize * 4.64,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(pastelCourtColor, Colors.white, 0.28)!,
                    pastelCourtColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(cellSize * 0.92),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.55),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),

          // Golden-ring base slots
          _buildBaseSlot(slotOffset1, slotOffset1, slotSize, primaryColor),
          _buildBaseSlot(slotOffset2, slotOffset1, slotSize, primaryColor),
          _buildBaseSlot(slotOffset1, slotOffset2, slotSize, primaryColor),
          _buildBaseSlot(slotOffset2, slotOffset2, slotSize, primaryColor),

          // Royal 1ST / 2ND / 3RD Award Emblem when all 4 gotis of this player reach Home!
          if (finishedRank != null)
            Positioned.fill(
              child: Center(
                child: _HomeRankCrownMedal(
                  rank: finishedRank,
                  size: cellSize * 4.25,
                  playerColor: primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBaseSlot(double left, double top, double size, Color color) {
    final ringWidth = (size * 0.11).clamp(2.4, 4.0);
    return Positioned(
      left: left,
      top: top,
      width: size,
      height: size,
      child: Container(
        padding: EdgeInsets.all(ringWidth),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF5B8),
              Color(0xFFFFCA28),
              Color(0xFFB86E00),
              Color(0xFFFFE082),
              Color(0xFF7A4400),
            ],
            stops: [0.0, 0.26, 0.55, 0.78, 1.0],
          ),
          border: Border.all(
            color: const Color(0xFF784200).withValues(alpha: 0.72),
            width: 0.9,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.24),
              blurRadius: 3.5,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.25, -0.25),
              radius: 0.9,
              colors: [
                Colors.white.withValues(alpha: 0.94),
                Color.lerp(Colors.white, color, 0.22)!,
                Color.lerp(Colors.white, color, 0.36)!,
              ],
              stops: const [0.0, 0.68, 1.0],
            ),
            border: Border.all(
              color: const Color(0xFF6B3C00).withValues(alpha: 0.38),
              width: 0.7,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTokenWidgets(double cellSize, double boardInnerSize) {
    final List<Widget> widgets = [];

    // Separate passed (Home Goal) tokens from active/base tokens so passed tokens
    // shrink to mini trophy pawns and line up neatly along each triangle's outer edge,
    // keeping the center Home zone clean for the 3D dice!
    final Map<BoardCoord, List<_TokenEntry>> coordMap = {};
    final Map<PlayerColor, List<_TokenEntry>> goalMap = {};

    for (final player in controller.state.players) {
      for (final token in player.tokens) {
        final bool isMovable = controller.isOnlineMatch
            ? (controller.isMyTurn &&
                controller.state.phase == TurnPhase.waitingForMove &&
                token.color == controller.state.currentPlayer.color &&
                (controller.onlineMovableTokenIds.isNotEmpty
                    ? controller.onlineMovableTokenIds.contains(token.id)
                    : controller.state.isTokenMovable(token)))
            : controller.state.isTokenMovable(token);
        final entry = _TokenEntry(
          token: token,
          player: player,
          isMovable: isMovable,
        );
        if (token.hasReachedGoal) {
          goalMap.putIfAbsent(player.color, () => []).add(entry);
        } else {
          final coord = token.coordinate;
          coordMap.putIfAbsent(coord, () => []).add(entry);
        }
      }
    }

    final trackTokenSize = cellSize * 0.92;
    final baseTokenSize = cellSize * 1.18;
    final passedTokenSize = cellSize * 0.54;

    // 1. Render passed tokens neatly lined up along their own Home Triangle outer edge
    goalMap.forEach((color, entries) {
      entries.sort((a, b) => a.token.id.compareTo(b.token.id));
      final total = entries.length;
      final spacing = cellSize * 0.50;
      final homeCenter = 7.5 * cellSize;
      // Inset 0.34 cells from the 3x3 box outer border -> strictly inside triangle & far from center dice!
      final edgeInset = 0.34 * cellSize;

      for (int i = 0; i < total; i++) {
        final entry = entries[i];
        final lineOffset = (i - (total - 1) / 2.0) * spacing;

        late final double centerX;
        late final double centerY;
        switch (color) {
          case PlayerColor.red:
            // Left triangle: vertical line along left outer edge (col = 6.0)
            centerX = 6.0 * cellSize + edgeInset;
            centerY = homeCenter + lineOffset;
            break;
          case PlayerColor.green:
            // Top triangle: horizontal line along top outer edge (row = 6.0)
            centerX = homeCenter + lineOffset;
            centerY = 6.0 * cellSize + edgeInset;
            break;
          case PlayerColor.yellow:
            // Right triangle: vertical line along right outer edge (col = 9.0)
            centerX = 9.0 * cellSize - edgeInset;
            centerY = homeCenter + lineOffset;
            break;
          case PlayerColor.blue:
            // Bottom triangle: horizontal line along bottom outer edge (row = 9.0)
            centerX = homeCenter + lineOffset;
            centerY = 9.0 * cellSize - edgeInset;
            break;
        }

        final left = (centerX - passedTokenSize / 2)
            .clamp(1.0, (boardInnerSize - passedTokenSize - 1.0).clamp(0.0, boardInnerSize));
        final top = (centerY - passedTokenSize / 2)
            .clamp(1.0, (boardInnerSize - passedTokenSize - 1.0).clamp(0.0, boardInnerSize));

        widgets.add(
          AnimatedPositioned(
            key: ValueKey('${entry.token.color.name}_${entry.token.id}'),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            left: left,
            top: top,
            child: TokenWidget(
              token: entry.token,
              player: entry.player,
              isMovable: false,
              size: passedTokenSize,
              onTap: null,
            ),
          ),
        );
      }
    });

    // 2. Render active track & base tokens
    coordMap.forEach((coord, entries) {
      final total = entries.length;

      for (int i = 0; i < total; i++) {
        final entry = entries[i];
        final double effectiveTokenSize;
        if (entry.token.isInBase) {
          effectiveTokenSize = baseTokenSize;
        } else if (total > 1) {
          effectiveTokenSize = trackTokenSize * 0.78;
        } else {
          effectiveTokenSize = trackTokenSize;
        }

        Offset offset = Offset.zero;

        // Apply smart stacking offset if multiple tokens share the cell
        if (total > 1 && !entry.token.isInBase) {
          final delta = cellSize * 0.16;
          switch (i) {
            case 0:
              offset = Offset(-delta, -delta);
              break;
            case 1:
              offset = Offset(delta, delta);
              break;
            case 2:
              offset = Offset(-delta, delta);
              break;
            case 3:
              offset = Offset(delta, -delta);
              break;
          }
        }

        // Calculate absolute pixel position and clamp strictly within the board
        final maxCoord = (boardInnerSize - effectiveTokenSize - 1.0)
            .clamp(0.0, boardInnerSize);
        final left = (coord.col * cellSize +
                (cellSize - effectiveTokenSize) / 2 +
                offset.dx)
            .clamp(1.0, maxCoord);
        final top = (coord.row * cellSize +
                (cellSize - effectiveTokenSize) / 2 +
                offset.dy)
            .clamp(1.0, maxCoord);

        // Smooth translation duration: 380ms on capture return, 210ms during normal step
        final animDuration = entry.token.animStage == TokenAnimStage.captured
            ? const Duration(milliseconds: 380)
            : const Duration(milliseconds: 210);

        widgets.add(
          AnimatedPositioned(
            key: ValueKey('${entry.token.color.name}_${entry.token.id}'),
            duration: animDuration,
            curve: Curves.easeInOutCubic,
            left: left,
            top: top,
            child: TokenWidget(
              token: entry.token,
              player: entry.player,
              isMovable: entry.isMovable,
              size: effectiveTokenSize,
              onTap: () => controller.onTokenTapped(entry.token),
            ),
          ),
        );
      }
    });

    return widgets;
  }
}

class _TokenEntry {
  final Token token;
  final dynamic player;
  final bool isMovable;

  _TokenEntry({
    required this.token,
    required this.player,
    required this.isMovable,
  });
}

/// Royal 3D Board Award Emblem permanently awarded in the center of a player's Home Court
/// when all 4 of their gotis reach Home:
/// - 1ST: 24K Gold Trophy + Jeweled Crown + Golden Laurel Wreath + Crimson Silk "1ST" Ribbon
/// - 2ND: Polished Silver Crown Crest + Silver Laurel Wreath + Royal Blue "2ND" Ribbon
/// - 3RD: Antique Bronze Crown Crest + Bronze Laurel Wreath + Burgundy "3RD" Ribbon
class _HomeRankCrownMedal extends StatelessWidget {
  final int rank;
  final double size;
  final Color playerColor;

  const _HomeRankCrownMedal({
    required this.rank,
    required this.size,
    required this.playerColor,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 650),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value.clamp(0.0, 1.25),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RoyalBoardAwardPainter(
            rank: rank,
            playerColor: playerColor,
          ),
        ),
      ),
    );
  }
}

class _RoyalBoardAwardPainter extends CustomPainter {
  final int rank;
  final Color playerColor;

  const _RoyalBoardAwardPainter({
    required this.rank,
    required this.playerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h * 0.48;

    final List<Color> metalColors = switch (rank) {
      1 => const [
          Color(0xFFFFFBE6),
          Color(0xFFFFDE59),
          Color(0xFFFFB300),
          Color(0xFFB86B00),
        ],
      2 => const [
          Color(0xFFFFFFFF),
          Color(0xFFE2E8F0),
          Color(0xFF94A3B8),
          Color(0xFF475569),
        ],
      _ => const [
          Color(0xFFFFDFC2),
          Color(0xFFE09145),
          Color(0xFFB56220),
          Color(0xFF6B320B),
        ],
    };

    final Color rimColor = switch (rank) {
      1 => const Color(0xFF6B3400),
      2 => const Color(0xFF334155),
      _ => const Color(0xFF4A2006),
    };

    final List<Color> ribbonColors = switch (rank) {
      1 => const [
          Color(0xFF7F0000),
          Color(0xFFD32F2F),
          Color(0xFFE53935),
          Color(0xFFD32F2F),
          Color(0xFF7F0000),
        ],
      2 => const [
          Color(0xFF0A2463),
          Color(0xFF1565C0),
          Color(0xFF1E88E5),
          Color(0xFF1565C0),
          Color(0xFF0A2463),
        ],
      _ => const [
          Color(0xFF4A1432),
          Color(0xFF880E4F),
          Color(0xFFAD1457),
          Color(0xFF880E4F),
          Color(0xFF4A1432),
        ],
    };

    final String label = switch (rank) {
      1 => '1ST',
      2 => '2ND',
      _ => '3RD',
    };

    final metalGrad = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: metalColors,
      stops: const [0.0, 0.32, 0.70, 1.0],
    );
    final rimStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.015).clamp(1.0, 1.8)
      ..strokeJoin = StrokeJoin.round
      ..color = rimColor;

    // 1. Soft Sunburst Glow & Subtle Light Rays behind crest
    final glowR = w * 0.46;
    canvas.drawCircle(
      Offset(cx, cy),
      glowR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            metalColors[1].withValues(alpha: rank == 1 ? 0.52 : 0.34),
            metalColors[2].withValues(alpha: rank == 1 ? 0.22 : 0.12),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: glowR)),
    );

    if (rank == 1) {
      canvas.save();
      canvas.translate(cx, cy);
      const rayCount = 12;
      final rayR = w * 0.44;
      final rayPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF8C2).withValues(alpha: 0.45),
            const Color(0xFFFFCA28).withValues(alpha: 0.14),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: rayR));
      for (int i = 0; i < rayCount; i++) {
        final a = i * (2 * math.pi / rayCount);
        final p = Path()
          ..moveTo(0, 0)
          ..lineTo(math.cos(a - 0.09) * rayR, math.sin(a - 0.09) * rayR)
          ..lineTo(math.cos(a + 0.09) * rayR, math.sin(a + 0.09) * rayR)
          ..close();
        canvas.drawPath(p, rayPaint);
      }
      canvas.restore();
    }

    // 2. Twin Curved 3D Metallic Laurel Wreath Branches
    _drawLaurelWreath(canvas, size, Offset(cx, cy + h * 0.18), metalColors, rimColor, flipX: false);
    _drawLaurelWreath(canvas, size, Offset(cx, cy + h * 0.18), metalColors, rimColor, flipX: true);

    // 3. Sculpted Centerpiece: 1ST = 3D Golden Trophy + Jeweled Crown; 2ND/3RD = 3D Jeweled Crown Crest
    if (rank == 1) {
      _drawTrophyAndCrown(canvas, size, Offset(cx, cy), metalGrad, rimStroke);
    } else {
      _drawRoyalShieldCrown(canvas, size, Offset(cx, cy - h * 0.02), metalColors, rimStroke);
    }

    // 4. Curved Silk Ribbon Banner across lower chest with embossed rank label
    _drawSilkRibbon(canvas, size, Offset(cx, h * 0.77), ribbonColors, metalColors, label);

    // 5. Crisp 4-Point Sparkle Twinkles
    _drawSparkle(canvas, Offset(w * 0.17, h * 0.20), w * 0.065, metalColors.first);
    _drawSparkle(canvas, Offset(w * 0.84, h * 0.24), w * 0.055, Colors.white);
    if (rank == 1) {
      _drawSparkle(canvas, Offset(cx, h * 0.07), w * 0.052, const Color(0xFFFFFDE7));
    }
  }

  void _drawLaurelWreath(
    Canvas canvas,
    Size size,
    Offset origin,
    List<Color> metalColors,
    Color rimColor, {
    required bool flipX,
  }) {
    final w = size.width;
    final h = size.height;
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    if (flipX) canvas.scale(-1.0, 1.0);

    final stem = Path()
      ..moveTo(-w * 0.14, h * 0.04)
      ..quadraticBezierTo(-w * 0.40, -h * 0.06, -w * 0.36, -h * 0.44);
    canvas.drawPath(
      stem,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (w * 0.022).clamp(1.6, 2.8)
        ..strokeCap = StrokeCap.round
        ..color = metalColors[2],
    );

    final leaves = [
      (Offset(-w * 0.24, -h * 0.01), -2.50, w * 0.115),
      (Offset(-w * 0.32, -h * 0.10), -2.20, w * 0.128),
      (Offset(-w * 0.37, -h * 0.21), -1.88, w * 0.132),
      (Offset(-w * 0.38, -h * 0.33), -1.55, w * 0.125),
      (Offset(-w * 0.35, -h * 0.43), -1.25, w * 0.112),
      (Offset(-w * 0.28, -h * 0.25), -1.08, w * 0.105),
    ];

    for (final (pos, angle, len) in leaves) {
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(angle);
      final leaf = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(len * 0.5, -len * 0.44, len, 0)
        ..quadraticBezierTo(len * 0.5, len * 0.44, 0, 0)
        ..close();

      // Shadow
      canvas.drawPath(
        leaf.shift(const Offset(0, 1.2)),
        Paint()..color = Colors.black.withValues(alpha: 0.28),
      );
      canvas.drawPath(
        leaf,
        Paint()
          ..shader = LinearGradient(
            colors: [metalColors[0], metalColors[1], metalColors[3]],
          ).createShader(Rect.fromLTWH(0, -len * 0.5, len, len)),
      );
      canvas.drawPath(
        leaf,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7
          ..color = rimColor.withValues(alpha: 0.65),
      );
      canvas.restore();
    }

    canvas.restore();
  }

  void _drawTrophyAndCrown(
    Canvas canvas,
    Size size,
    Offset c,
    LinearGradient metalGrad,
    Paint rimStroke,
  ) {
    final w = size.width;
    final cupRect = Rect.fromCenter(center: c, width: w * 0.55, height: w * 0.60);

    // Grounded tabletop drop shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(c.dx, c.dy + w * 0.24), width: w * 0.46, height: w * 0.10),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.36)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Curved S-handles
    for (final sign in const [-1.0, 1.0]) {
      final hPath = Path()
        ..moveTo(c.dx + sign * w * 0.14, c.dy - w * 0.12)
        ..cubicTo(
          c.dx + sign * w * 0.30,
          c.dy - w * 0.15,
          c.dx + sign * w * 0.28,
          c.dy + w * 0.05,
          c.dx + sign * w * 0.10,
          c.dy + w * 0.08,
        );
      canvas.drawPath(
        hPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (w * 0.048).clamp(3.2, 6.0)
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF7A3E00),
      );
      canvas.drawPath(
        hPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (w * 0.032).clamp(2.2, 4.2)
          ..strokeCap = StrokeCap.round
          ..shader = metalGrad.createShader(cupRect),
      );
    }

    // Stem & Pedestal Base
    final stem = Path()
      ..moveTo(c.dx - w * 0.045, c.dy + w * 0.08)
      ..lineTo(c.dx + w * 0.045, c.dy + w * 0.08)
      ..lineTo(c.dx + w * 0.07, c.dy + w * 0.18)
      ..lineTo(c.dx - w * 0.07, c.dy + w * 0.18)
      ..close();
    canvas.drawPath(stem, Paint()..shader = metalGrad.createShader(cupRect));
    canvas.drawPath(stem, rimStroke);

    final baseRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(c.dx, c.dy + w * 0.21), width: w * 0.28, height: w * 0.065),
      const Radius.circular(3.5),
    );
    canvas.drawRRect(baseRect, Paint()..shader = metalGrad.createShader(cupRect));
    canvas.drawRRect(baseRect, rimStroke);

    // Sculpted Trophy Cup
    final cup = Path()
      ..moveTo(c.dx - w * 0.18, c.dy - w * 0.16)
      ..lineTo(c.dx + w * 0.18, c.dy - w * 0.16)
      ..cubicTo(
        c.dx + w * 0.18,
        c.dy + w * 0.03,
        c.dx + w * 0.09,
        c.dy + w * 0.11,
        c.dx,
        c.dy + w * 0.11,
      )
      ..cubicTo(
        c.dx - w * 0.09,
        c.dy + w * 0.11,
        c.dx - w * 0.18,
        c.dy + w * 0.03,
        c.dx - w * 0.18,
        c.dy - w * 0.16,
      )
      ..close();

    canvas.drawPath(
      cup,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.28, -0.35),
          radius: 0.95,
          colors: [
            Color(0xFFFFFCE0),
            Color(0xFFFFD54F),
            Color(0xFFFFA000),
            Color(0xFFBF6000),
          ],
          stops: [0.0, 0.35, 0.72, 1.0],
        ).createShader(cupRect),
    );
    canvas.drawPath(cup, rimStroke);

    // Specular shine strip on cup
    final sheen = Path()
      ..moveTo(c.dx - w * 0.11, c.dy - w * 0.12)
      ..quadraticBezierTo(c.dx - w * 0.12, c.dy - w * 0.01, c.dx - w * 0.05, c.dy + w * 0.05)
      ..quadraticBezierTo(c.dx - w * 0.08, c.dy - w * 0.01, c.dx - w * 0.07, c.dy - w * 0.12)
      ..close();
    canvas.drawPath(sheen, Paint()..color = Colors.white.withValues(alpha: 0.55));

    // Top Cup Rim Lip
    final lip = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(c.dx, c.dy - w * 0.16), width: w * 0.38, height: w * 0.042),
      const Radius.circular(3),
    );
    canvas.drawRRect(lip, Paint()..shader = metalGrad.createShader(cupRect));
    canvas.drawRRect(lip, rimStroke);

    // Jeweled Royal Crown Perched on Top of Trophy
    final crownY = c.dy - w * 0.27;
    final velvet = Path()
      ..moveTo(c.dx - w * 0.12, crownY + w * 0.08)
      ..lineTo(c.dx - w * 0.14, crownY - w * 0.03)
      ..lineTo(c.dx, crownY - w * 0.09)
      ..lineTo(c.dx + w * 0.14, crownY - w * 0.03)
      ..lineTo(c.dx + w * 0.12, crownY + w * 0.08)
      ..close();
    canvas.drawPath(velvet, Paint()..color = const Color(0xFFB71C1C));

    final crown = Path()
      ..moveTo(c.dx - w * 0.13, crownY + w * 0.09)
      ..lineTo(c.dx - w * 0.17, crownY - w * 0.06)
      ..lineTo(c.dx - w * 0.07, crownY + w * 0.01)
      ..lineTo(c.dx, crownY - w * 0.12)
      ..lineTo(c.dx + w * 0.07, crownY + w * 0.01)
      ..lineTo(c.dx + w * 0.17, crownY - w * 0.06)
      ..lineTo(c.dx + w * 0.13, crownY + w * 0.09)
      ..close();
    canvas.drawPath(crown, Paint()..shader = metalGrad.createShader(cupRect));
    canvas.drawPath(crown, rimStroke);

    // Cyan sapphire center gem on crown
    canvas.drawCircle(
      Offset(c.dx, crownY + w * 0.04),
      w * 0.032,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFFB3E5FC), Color(0xFF00B0FF), Color(0xFF01579B)],
        ).createShader(Rect.fromCircle(center: Offset(c.dx, crownY + w * 0.04), radius: w * 0.032)),
    );
  }

  void _drawRoyalShieldCrown(
    Canvas canvas,
    Size size,
    Offset c,
    List<Color> metalColors,
    Paint rimStroke,
  ) {
    final w = size.width;
    final rect = Rect.fromCenter(center: c, width: w * 0.46, height: w * 0.46);
    final grad = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: metalColors,
    );

    // Shadow
    canvas.drawCircle(
      Offset(c.dx, c.dy + w * 0.03),
      w * 0.21,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Metallic Medallion Shield
    canvas.drawCircle(c, w * 0.20, Paint()..shader = grad.createShader(rect));
    canvas.drawCircle(c, w * 0.20, rimStroke);

    canvas.drawCircle(
      c,
      w * 0.155,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [
            const Color(0xFF1A3A8A),
            const Color(0xFF0A1944),
          ],
        ).createShader(rect),
    );

    // Sculpted 3D Crown inside medallion
    final crown = Path()
      ..moveTo(c.dx - w * 0.10, c.dy + w * 0.06)
      ..lineTo(c.dx - w * 0.12, c.dy - w * 0.05)
      ..lineTo(c.dx - w * 0.045, c.dy + w * 0.005)
      ..lineTo(c.dx, c.dy - w * 0.085)
      ..lineTo(c.dx + w * 0.045, c.dy + w * 0.005)
      ..lineTo(c.dx + w * 0.12, c.dy - w * 0.05)
      ..lineTo(c.dx + w * 0.10, c.dy + w * 0.06)
      ..close();
    canvas.drawPath(crown, Paint()..shader = grad.createShader(rect));
    canvas.drawPath(crown, rimStroke);

    // Center player-color jewel
    canvas.drawCircle(
      Offset(c.dx, c.dy + w * 0.02),
      w * 0.025,
      Paint()..color = playerColor,
    );
  }

  void _drawSilkRibbon(
    Canvas canvas,
    Size size,
    Offset center,
    List<Color> ribbonColors,
    List<Color> metalColors,
    String label,
  ) {
    final rw = size.width * 0.80;
    final rh = size.height * 0.22;
    final left = center.dx - rw / 2;
    final top = center.dy - rh / 2;

    // Folded Swallowtail Ends
    final lTail = Path()
      ..moveTo(left + rw * 0.14, top + rh * 0.25)
      ..lineTo(left, top + rh * 0.20)
      ..lineTo(left + rw * 0.065, top + rh * 0.60)
      ..lineTo(left, top + rh * 0.98)
      ..lineTo(left + rw * 0.17, top + rh * 0.90)
      ..close();
    final rTail = Path()
      ..moveTo(left + rw * 0.86, top + rh * 0.25)
      ..lineTo(left + rw, top + rh * 0.20)
      ..lineTo(left + rw * 0.935, top + rh * 0.60)
      ..lineTo(left + rw, top + rh * 0.98)
      ..lineTo(left + rw * 0.83, top + rh * 0.90)
      ..close();

    final tailPaint = Paint()..color = ribbonColors.first;
    canvas.drawPath(lTail, tailPaint);
    canvas.drawPath(rTail, tailPaint);

    // Main Curved Silk Ribbon
    final mainPath = Path()
      ..moveTo(left + rw * 0.10, top + rh * 0.14)
      ..quadraticBezierTo(center.dx, top - rh * 0.08, left + rw * 0.90, top + rh * 0.14)
      ..lineTo(left + rw * 0.88, top + rh * 0.88)
      ..quadraticBezierTo(center.dx, top + rh * 0.70, left + rw * 0.12, top + rh * 0.88)
      ..close();

    canvas.drawPath(
      mainPath.shift(const Offset(0, 2.2)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    final rRect = Rect.fromLTWH(left, top, rw, rh);
    canvas.drawPath(
      mainPath,
      Paint()
        ..shader = LinearGradient(
          colors: ribbonColors,
          stops: const [0.0, 0.22, 0.50, 0.78, 1.0],
        ).createShader(rRect),
    );

    // Metallic Gold / Silver / Bronze Ribbon Trim Border
    canvas.drawPath(
      mainPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (size.width * 0.018).clamp(1.2, 2.0)
        ..shader = LinearGradient(
          colors: [metalColors[2], metalColors[0], metalColors[1], metalColors[0], metalColors[2]],
        ).createShader(rRect),
    );

    // Crisp Embossed Rank Text ("1ST", "2ND", "3RD")
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: const Color(0xFFFFF8DC),
          fontSize: (size.width * 0.155).clamp(10.0, 20.0),
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          shadows: const [
            Shadow(
              color: Colors.black87,
              blurRadius: 3,
              offset: Offset(0, 1.2),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2 - rh * 0.04));
  }

  void _drawSparkle(Canvas canvas, Offset c, double r, Color color) {
    final inner = r * 0.26;
    final p = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + inner, c.dy - inner)
      ..lineTo(c.dx + r, c.dy)
      ..lineTo(c.dx + inner, c.dy + inner)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - inner, c.dy + inner)
      ..lineTo(c.dx - r, c.dy)
      ..lineTo(c.dx - inner, c.dy - inner)
      ..close();
    canvas.drawPath(p, Paint()..color = color.withValues(alpha: 0.92));
  }

  @override
  bool shouldRepaint(covariant _RoyalBoardAwardPainter oldDelegate) =>
      oldDelegate.rank != rank || oldDelegate.playerColor != playerColor;
}
