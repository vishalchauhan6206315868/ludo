import 'package:flutter/material.dart';
import '../../constants/ludo_colors.dart';
import '../../constants/ludo_path.dart';
import '../../logic/ludo_game_controller.dart';
import '../../models/token.dart';
import '../token/token_widget.dart';
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
    const double borderWidth = 3.5;
    final boardInnerSize = size - (borderWidth * 2);
    final cellSize = boardInnerSize / 15;

    return Transform.translate(
      offset: Offset(controller.boardShakeOffset, 0),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: LudoColors.boardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 18,
              spreadRadius: 3,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: LudoColors.boardBorder,
            width: borderWidth,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: boardInnerSize,
            height: boardInnerSize,
            child: Stack(
              children: [
                // 1. Board Background Layout (Track grid)
                _buildBoardBackground(cellSize),

                // 2. Four Base Corners (6x6 each)
                Positioned(
                  left: 0,
                  top: 0,
                  width: 6 * cellSize,
                  height: 6 * cellSize,
                  child: _buildBaseCorner(
                    PlayerColor.red,
                    LudoColors.red,
                    LudoColors.redBg,
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
                    LudoColors.greenBg,
                    cellSize,
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 9 * cellSize,
                  width: 6 * cellSize,
                  height: 6 * cellSize,
                  child: _buildBaseCorner(
                    PlayerColor.blue,
                    LudoColors.blue,
                    LudoColors.blueBg,
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
                    LudoColors.yellowBg,
                    cellSize,
                  ),
                ),

                // 3. Center Finish Triangle (3x3)
                Positioned(
                  left: 6 * cellSize,
                  top: 6 * cellSize,
                  width: 3 * cellSize,
                  height: 3 * cellSize,
                  child: CustomPaint(
                    painter: HomeTrianglePainter(),
                  ),
                ),

                // 4. Tokens Overlay with smart stacking and smooth hop interpolation
                ..._buildTokenWidgets(cellSize),
              ],
            ),
          ),
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
    Color cellBg = Colors.white;
    bool isStar = false;
    Color starColor = LudoColors.safeStar;

    // Home Stretches
    // Red home stretch: row 7, cols 1..5
    if (row == 7 && col >= 1 && col <= 5) {
      cellBg = LudoColors.red;
    }
    // Green home stretch: col 7, rows 1..5
    else if (col == 7 && row >= 1 && row <= 5) {
      cellBg = LudoColors.green;
    }
    // Yellow home stretch: row 7, cols 9..13
    else if (row == 7 && col >= 9 && col <= 13) {
      cellBg = LudoColors.yellow;
    }
    // Blue home stretch: col 7, rows 9..13
    else if (col == 7 && row >= 9 && row <= 13) {
      cellBg = LudoColors.blue;
    }
    // Start tiles (with color)
    else if (col == 1 && row == 6) {
      cellBg = LudoColors.red;
      isStar = true;
      starColor = Colors.white;
    } else if (col == 8 && row == 1) {
      cellBg = LudoColors.green;
      isStar = true;
      starColor = Colors.white;
    } else if (col == 13 && row == 8) {
      cellBg = LudoColors.yellow;
      isStar = true;
      starColor = Colors.white;
    } else if (col == 6 && row == 13) {
      cellBg = LudoColors.blue;
      isStar = true;
      starColor = Colors.white;
    }
    // Other safe stars
    else if ((col == 6 && row == 2) ||
        (col == 12 && row == 6) ||
        (col == 8 && row == 12) ||
        (col == 2 && row == 8)) {
      isStar = true;
      starColor = LudoColors.safeStar;
    }

    return Container(
      decoration: BoxDecoration(
        color: cellBg,
        border: Border.all(
          color: LudoColors.pathBorder,
          width: 0.75,
        ),
      ),
      child: isStar
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: cellSize * 0.46,
                    height: cellSize * 0.46,
                    child: CustomPaint(
                      painter: SafeStarPainter(color: starColor),
                    ),
                  ),
                  Text(
                    "STOP",
                    style: TextStyle(
                      fontSize: (cellSize * 0.19).clamp(4.0, 6.5),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                      color: starColor == Colors.white
                          ? Colors.white.withValues(alpha: 0.95)
                          : const Color(0xFF424242),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildBaseCorner(
    PlayerColor color,
    Color primaryColor,
    Color bgColor,
    double cellSize,
  ) {
    final slotSize = cellSize * 1.3;
    final slotOffset1 = 2.0 * cellSize - (slotSize / 2);
    final slotOffset2 = 4.0 * cellSize - (slotSize / 2);

    return Container(
      width: cellSize * 6,
      height: cellSize * 6,
      decoration: BoxDecoration(
        color: primaryColor,
        border: Border.all(color: LudoColors.boardBorder, width: 1.5),
      ),
      child: Stack(
        children: [
          // White rounded container
          Positioned(
            left: cellSize * 0.75,
            top: cellSize * 0.75,
            width: cellSize * 4.5,
            height: cellSize * 4.5,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(cellSize * 0.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(1, 2),
                  ),
                ],
              ),
            ),
          ),
          // 4 Base slots centered under tokens (centers at 2.0 * cellSize and 4.0 * cellSize)
          _buildBaseSlot(slotOffset1, slotOffset1, slotSize, primaryColor),
          _buildBaseSlot(slotOffset2, slotOffset1, slotSize, primaryColor),
          _buildBaseSlot(slotOffset1, slotOffset2, slotSize, primaryColor),
          _buildBaseSlot(slotOffset2, slotOffset2, slotSize, primaryColor),
        ],
      ),
    );
  }

  Widget _buildBaseSlot(double left, double top, double size, Color color) {
    return Positioned(
      left: left,
      top: top,
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.18),
          border: Border.all(color: color.withValues(alpha: 0.55), width: 1.5),
        ),
      ),
    );
  }

  List<Widget> _buildTokenWidgets(double cellSize) {
    final List<Widget> widgets = [];

    // Group active tokens by coordinate to apply visual offset when stacked
    final Map<BoardCoord, List<_TokenEntry>> coordMap = {};

    for (final player in controller.state.players) {
      for (final token in player.tokens) {
        final coord = token.coordinate;
        coordMap.putIfAbsent(coord, () => []).add(
              _TokenEntry(
                token: token,
                player: player,
                isMovable: controller.state.isTokenMovable(token),
              ),
            );
      }
    }

    final tokenSize = cellSize * 0.88;

    coordMap.forEach((coord, entries) {
      final total = entries.length;

      for (int i = 0; i < total; i++) {
        final entry = entries[i];
        Offset offset = Offset.zero;

        // Apply smart stacking offset if multiple tokens share the cell
        if (total > 1 && !entry.token.isInBase) {
          final delta = cellSize * 0.22;
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

        // Calculate absolute pixel position from board coordinates (0..14)
        final left = coord.col * cellSize + (cellSize - tokenSize) / 2 + offset.dx;
        final top = coord.row * cellSize + (cellSize - tokenSize) / 2 + offset.dy;

        // Smooth translation duration: 380ms on capture return, 210ms during normal step hop
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
              size: total > 1 && !entry.token.isInBase
                  ? tokenSize * 0.82
                  : tokenSize,
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
