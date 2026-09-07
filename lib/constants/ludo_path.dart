class BoardCoord {
  final double col;
  final double row;

  const BoardCoord(this.col, this.row);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardCoord &&
          runtimeType == other.runtimeType &&
          col == other.col &&
          row == other.row;

  @override
  int get hashCode => col.hashCode ^ row.hashCode;

  @override
  String toString() => '($col, $row)';
}

enum PlayerColor {
  red,
  green,
  yellow,
  blue,
}

class LudoPath {
  // 52 common track coordinates in clockwise sequence starting at Red start (1, 6)
  static const List<BoardCoord> commonTrack = [
    // 0..4: Left arm top row going right
    BoardCoord(1, 6), // 0: Red Start
    BoardCoord(2, 6),
    BoardCoord(3, 6),
    BoardCoord(4, 6),
    BoardCoord(5, 6),

    // 5..10: Top arm left col going up
    BoardCoord(6, 5),
    BoardCoord(6, 4),
    BoardCoord(6, 3),
    BoardCoord(6, 2), // 8: Safe Star
    BoardCoord(6, 1),
    BoardCoord(6, 0),

    // 11: Top arm top center
    BoardCoord(7, 0),

    // 12..17: Top arm right col going down
    BoardCoord(8, 0),
    BoardCoord(8, 1), // 13: Green Start
    BoardCoord(8, 2),
    BoardCoord(8, 3),
    BoardCoord(8, 4),
    BoardCoord(8, 5),

    // 18..23: Right arm top row going right
    BoardCoord(9, 6),
    BoardCoord(10, 6),
    BoardCoord(11, 6),
    BoardCoord(12, 6), // 21: Safe Star
    BoardCoord(13, 6),
    BoardCoord(14, 6),

    // 24: Right arm right center
    BoardCoord(14, 7),

    // 25..30: Right arm bottom row going left
    BoardCoord(14, 8),
    BoardCoord(13, 8), // 26: Yellow Start
    BoardCoord(12, 8),
    BoardCoord(11, 8),
    BoardCoord(10, 8),
    BoardCoord(9, 8),

    // 31..36: Bottom arm right col going down
    BoardCoord(8, 9),
    BoardCoord(8, 10),
    BoardCoord(8, 11),
    BoardCoord(8, 12), // 34: Safe Star
    BoardCoord(8, 13),
    BoardCoord(8, 14),

    // 37: Bottom arm bottom center
    BoardCoord(7, 14),

    // 38..43: Bottom arm left col going up
    BoardCoord(6, 14),
    BoardCoord(6, 13), // 39: Blue Start
    BoardCoord(6, 12),
    BoardCoord(6, 11),
    BoardCoord(6, 10),
    BoardCoord(6, 9),

    // 44..49: Left arm bottom row going left
    BoardCoord(5, 8),
    BoardCoord(4, 8),
    BoardCoord(3, 8),
    BoardCoord(2, 8), // 47: Safe Star
    BoardCoord(1, 8),
    BoardCoord(0, 8),

    // 50: Left arm left center
    BoardCoord(0, 7),

    // 51: Left arm corner before Red start
    BoardCoord(0, 6),
  ];

  // Start index on commonTrack for each player
  static int startIndex(PlayerColor color) {
    switch (color) {
      case PlayerColor.red:
        return 0;
      case PlayerColor.green:
        return 13;
      case PlayerColor.yellow:
        return 26;
      case PlayerColor.blue:
        return 39;
    }
  }

  // Safe star positions (8 in total: 4 starting cells + 4 star cells)
  static const List<BoardCoord> safeCoords = [
    BoardCoord(1, 6), // Red start
    BoardCoord(6, 2), // Top star
    BoardCoord(8, 1), // Green start
    BoardCoord(12, 6), // Right star
    BoardCoord(13, 8), // Yellow start
    BoardCoord(8, 12), // Bottom star
    BoardCoord(6, 13), // Blue start
    BoardCoord(2, 8), // Left star
  ];

  static bool isSafeCoord(BoardCoord coord) {
    return safeCoords.contains(coord);
  }

  // Home stretch coordinates (steps 51 to 55) for each color
  static const Map<PlayerColor, List<BoardCoord>> homeStretch = {
    PlayerColor.red: [
      BoardCoord(1, 7),
      BoardCoord(2, 7),
      BoardCoord(3, 7),
      BoardCoord(4, 7),
      BoardCoord(5, 7),
    ],
    PlayerColor.green: [
      BoardCoord(7, 1),
      BoardCoord(7, 2),
      BoardCoord(7, 3),
      BoardCoord(7, 4),
      BoardCoord(7, 5),
    ],
    PlayerColor.yellow: [
      BoardCoord(13, 7),
      BoardCoord(12, 7),
      BoardCoord(11, 7),
      BoardCoord(10, 7),
      BoardCoord(9, 7),
    ],
    PlayerColor.blue: [
      BoardCoord(7, 13),
      BoardCoord(7, 12),
      BoardCoord(7, 11),
      BoardCoord(7, 10),
      BoardCoord(7, 9),
    ],
  };

  // Center Home Goal coordinate for each color
  static const Map<PlayerColor, BoardCoord> homeGoal = {
    PlayerColor.red: BoardCoord(6.5, 7.0),
    PlayerColor.green: BoardCoord(7.0, 6.5),
    PlayerColor.yellow: BoardCoord(7.5, 7.0),
    PlayerColor.blue: BoardCoord(7.0, 7.5),
  };

  // Base slot coordinates for 4 tokens in each player's home base (6x6)
  static const Map<PlayerColor, List<BoardCoord>> baseSlots = {
    PlayerColor.red: [
      BoardCoord(1.5, 1.5),
      BoardCoord(3.5, 1.5),
      BoardCoord(1.5, 3.5),
      BoardCoord(3.5, 3.5),
    ],
    PlayerColor.green: [
      BoardCoord(10.5, 1.5),
      BoardCoord(12.5, 1.5),
      BoardCoord(10.5, 3.5),
      BoardCoord(12.5, 3.5),
    ],
    PlayerColor.yellow: [
      BoardCoord(10.5, 10.5),
      BoardCoord(12.5, 10.5),
      BoardCoord(10.5, 12.5),
      BoardCoord(12.5, 12.5),
    ],
    PlayerColor.blue: [
      BoardCoord(1.5, 10.5),
      BoardCoord(3.5, 10.5),
      BoardCoord(1.5, 12.5),
      BoardCoord(3.5, 12.5),
    ],
  };

  /// Computes board coordinate for a token at a given step (0..56)
  /// -1 represents token in base
  /// 0..50 represents common track
  /// 51..55 represents home stretch
  /// 56 represents home goal
  static BoardCoord getCoordinate({
    required PlayerColor color,
    required int step,
    required int tokenIndex,
  }) {
    if (step < 0) {
      return baseSlots[color]![tokenIndex];
    }
    if (step <= 50) {
      final globalIndex = (startIndex(color) + step) % 52;
      return commonTrack[globalIndex];
    }
    if (step <= 55) {
      final homeIndex = step - 51;
      return homeStretch[color]![homeIndex];
    }
    return homeGoal[color]!;
  }
}
