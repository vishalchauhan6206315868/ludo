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
    final cellSize = size / 15;

    return Container(
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
          width: 3.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // 1. Board Background Layout
            _buildBoardBackground(cellSize),

            // 2. Center Finish Triangle (3x3)
            Positioned(
              left: 6 * cellSize,
              top: 6 * cellSize,
              width: 3 * cellSize,
              height: 3 * cellSize,
              child: CustomPaint(
                painter: HomeTrianglePainter(),
              ),
            ),

            // 3. Tokens Overlay with smart stacking
            ..._buildTokenWidgets(cellSize),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardBackground(double cellSize) {
    return Column(
      children: List.generate(15, (row) {
        return Row(
          children: List.generate(15, (col) {
            return SizedBox(
              width: cellSize,
              height: cellSize,
              child: _buildCell(col, row, cellSize),
            );
          }),
        );
      }),
    );
  }

  Widget _buildCell(int col, int row, double cellSize) {
    // 1. Four Corner Bases (6x6 each)
    // Red Base: Top-Left (cols 0..5, rows 0..5)
    if (col < 6 && row < 6) {
      if (col == 0 && row == 0) {
        return _buildBaseCorner(
          PlayerColor.red,
          LudoColors.red,
          LudoColors.redBg,
          cellSize,
        );
      }
      return const SizedBox.shrink(); // Covered by 6x6 widget
    }

    // Green Base: Top-Right (cols 9..14, rows 0..5)
    if (col >= 9 && row < 6) {
      if (col == 9 && row == 0) {
        return _buildBaseCorner(
          PlayerColor.green,
          LudoColors.green,
          LudoColors.greenBg,
          cellSize,
        );
      }
      return const SizedBox.shrink();
    }

    // Blue Base: Bottom-Left (cols 0..5, rows 9..14)
    if (col < 6 && row >= 9) {
      if (col == 0 && row == 9) {
        return _buildBaseCorner(
          PlayerColor.blue,
          LudoColors.blue,
          LudoColors.blueBg,
          cellSize,
        );
      }
      return const SizedBox.shrink();
    }

    // Yellow Base: Bottom-Right (cols 9..14, rows 9..14)
    if (col >= 9 && row >= 9) {
      if (col == 9 && row == 9) {
        return _buildBaseCorner(
          PlayerColor.yellow,
          LudoColors.yellow,
          LudoColors.yellowBg,
          cellSize,
        );
      }
      return const SizedBox.shrink();
    }

    // Center 3x3 area
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
              child: SizedBox(
                width: cellSize * 0.7,
                height: cellSize * 0.7,
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
    Color bgColor,
    double cellSize,
  ) {
    return Container(
      width: cellSize * 6,
      height: cellSize * 6,
      decoration: BoxDecoration(
        color: primaryColor,
        border: Border.all(color: LudoColors.boardBorder, width: 1.5),
      ),
      padding: EdgeInsets.all(cellSize * 0.75),
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
        child: Padding(
          padding: EdgeInsets.all(cellSize * 0.35),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBaseSlot(primaryColor, cellSize),
                  _buildBaseSlot(primaryColor, cellSize),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBaseSlot(primaryColor, cellSize),
                  _buildBaseSlot(primaryColor, cellSize),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBaseSlot(Color color, double cellSize) {
    return Container(
      width: cellSize * 1.3,
      height: cellSize * 1.3,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
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

        widgets.add(
          AnimatedPositioned(
            key: ValueKey('${entry.token.color.name}_${entry.token.id}'),
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeInOut,
            left: left,
            top: top,
            child: TokenWidget(
              token: entry.token,
              player: entry.player,
              isMovable: entry.isMovable,
              size: total > 1 && !entry.token.isInBase
                  ? tokenSize * 0.82
                  : tokenSize,
              onTap: () => controller.moveToken(entry.token),
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
