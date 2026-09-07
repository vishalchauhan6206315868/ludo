import '../constants/ludo_path.dart';
import '../models/ludo_player.dart';
import '../models/token.dart';

class LudoBotAI {
  /// Picks the best token to move based on tactical heuristic scores
  static Token? pickBestToken({
    required LudoPlayer botPlayer,
    required List<LudoPlayer> allPlayers,
    required int diceValue,
  }) {
    final movable = botPlayer.getMovableTokens(diceValue);
    if (movable.isEmpty) return null;
    if (movable.length == 1) return movable.first;

    Token bestToken = movable.first;
    double highestScore = -9999;

    for (final token in movable) {
      final score = _evaluateMove(
        token: token,
        diceValue: diceValue,
        botPlayer: botPlayer,
        allPlayers: allPlayers,
      );

      if (score > highestScore) {
        highestScore = score;
        bestToken = token;
      }
    }

    return bestToken;
  }

  static double _evaluateMove({
    required Token token,
    required int diceValue,
    required LudoPlayer botPlayer,
    required List<LudoPlayer> allPlayers,
  }) {
    double score = 0;

    // 1. Opening from base on roll of 6
    if (token.isInBase && diceValue == 6) {
      // Check if starting cell is occupied by opponent
      final startCoord = LudoPath.commonTrack[LudoPath.startIndex(botPlayer.color)];
      final opponentAtStart = _findOpponentsAt(startCoord, botPlayer.color, allPlayers);
      if (opponentAtStart.isNotEmpty) {
        score += 90; // Bonus for capturing on start!
      } else {
        score += 65;
      }
      return score;
    }

    final targetStep = token.step + diceValue;

    // 2. Reaching the Home Goal
    if (targetStep == 56) {
      return 120; // Highest priority: finishing a token!
    }

    // 3. Entering or advancing in Home stretch (Safe from all captures)
    if (targetStep > 50) {
      score += 50 + (targetStep - 50) * 5;
      return score;
    }

    final targetCoord = LudoPath.getCoordinate(
      color: botPlayer.color,
      step: targetStep,
      tokenIndex: token.id,
    );

    // 4. Capturing opponent
    if (!LudoPath.isSafeCoord(targetCoord)) {
      final opponents = _findOpponentsAt(targetCoord, botPlayer.color, allPlayers);
      if (opponents.isNotEmpty) {
        score += 100; // Major reward for capturing!
      }
    }

    // 5. Landing on a Safe Star
    if (LudoPath.isSafeCoord(targetCoord)) {
      score += 40;
    }

    // 6. Escaping danger (if current spot is unsafe and opponent is close behind)
    final currentCoord = token.coordinate;
    if (!LudoPath.isSafeCoord(currentCoord) && token.step <= 50) {
      if (_isUnderThreat(token, allPlayers)) {
        score += 45; // Escape from threat
      }
    }

    // 7. General advancement: favor moving pieces closer to goal
    score += token.step * 0.5;

    return score;
  }

  static List<Token> _findOpponentsAt(
    BoardCoord coord,
    PlayerColor myColor,
    List<LudoPlayer> allPlayers,
  ) {
    final List<Token> opponents = [];
    for (final player in allPlayers) {
      if (player.color == myColor) continue;
      for (final t in player.tokens) {
        if (t.isPlaying && t.coordinate == coord) {
          opponents.add(t);
        }
      }
    }
    return opponents;
  }

  static bool _isUnderThreat(Token token, List<LudoPlayer> allPlayers) {
    final myGlobalPos = (LudoPath.startIndex(token.color) + token.step) % 52;

    for (final player in allPlayers) {
      if (player.color == token.color) continue;
      for (final enemyToken in player.tokens) {
        if (!enemyToken.isPlaying || enemyToken.step > 50) continue;
        final enemyGlobalPos =
            (LudoPath.startIndex(enemyToken.color) + enemyToken.step) % 52;
        final distance = (myGlobalPos - enemyGlobalPos + 52) % 52;
        if (distance >= 1 && distance <= 6) {
          return true;
        }
      }
    }
    return false;
  }
}
