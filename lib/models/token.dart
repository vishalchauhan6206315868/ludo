import '../constants/ludo_path.dart';

enum TokenStatus {
  inBase,
  onTrack,
  inHomeStretch,
  reachedGoal,
}

enum TokenAnimStage {
  idle,
  throwing,
  hopping,
  captured,
  safeGlow,
  goalCelebration,
}

class Token {
  final int id; // 0..3
  final PlayerColor color;
  int step; // -1 = base, 0..50 = common track, 51..55 = home stretch, 56 = goal
  TokenAnimStage animStage;

  Token({
    required this.id,
    required this.color,
    this.step = -1,
    this.animStage = TokenAnimStage.idle,
  });

  TokenStatus get status {
    if (step < 0) return TokenStatus.inBase;
    if (step <= 50) return TokenStatus.onTrack;
    if (step <= 55) return TokenStatus.inHomeStretch;
    return TokenStatus.reachedGoal;
  }

  bool get isInBase => step < 0;
  bool get hasReachedGoal => step == 56;
  bool get isPlaying => step >= 0 && step < 56;

  BoardCoord get coordinate => LudoPath.getCoordinate(
        color: color,
        step: step,
        tokenIndex: id,
      );

  bool canMove(int diceValue) {
    if (hasReachedGoal) return false;
    if (isInBase) {
      return diceValue == 6;
    }
    // Cannot overshoot step 56
    return (step + diceValue) <= 56;
  }

  Token copyWith({int? step, TokenAnimStage? animStage}) {
    return Token(
      id: id,
      color: color,
      step: step ?? this.step,
      animStage: animStage ?? this.animStage,
    );
  }
}
