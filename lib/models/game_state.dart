import 'ludo_player.dart';
import 'token.dart';

enum GameMode {
  twoPlayer,
  threePlayer,
  fourPlayer,
  vsComputer,
  passNPlay,
  teamUp,
}

enum TurnPhase {
  waitingForRoll,
  throwingDice,
  waitingForMove,
  animatingMove,
  waitingForPlayerHandoff,
  gameOver,
}

class GameState {
  final List<LudoPlayer> players;
  final GameMode mode;
  int currentPlayerIndex;
  int? currentDiceValue;
  TurnPhase phase;
  int consecutiveSixes;
  List<LudoPlayer> winners;
  String statusMessage;
  int? selectedTokenId;
  String? winningTeam;

  GameState({
    required this.players,
    required this.mode,
    this.currentPlayerIndex = 0,
    this.currentDiceValue,
    this.phase = TurnPhase.waitingForRoll,
    this.consecutiveSixes = 0,
    List<LudoPlayer>? winners,
    this.statusMessage = "Roll the dice to begin!",
    this.selectedTokenId,
    this.winningTeam,
  }) : winners = winners ?? [];

  LudoPlayer get currentPlayer => players[currentPlayerIndex];

  /// In Team Up mode, returns current player's partner
  LudoPlayer? get currentTeammate {
    if (mode != GameMode.teamUp) return null;
    try {
      return players.firstWhere(
        (p) => p != currentPlayer && p.isTeammateWith(currentPlayer),
      );
    } catch (_) {
      return null;
    }
  }

  bool get isWaitingForRoll => phase == TurnPhase.waitingForRoll;
  bool get isThrowingDice => phase == TurnPhase.throwingDice;
  bool get isWaitingForMove => phase == TurnPhase.waitingForMove;
  bool get isWaitingForPlayerHandoff => phase == TurnPhase.waitingForPlayerHandoff;
  bool get isGameOver => phase == TurnPhase.gameOver;

  bool isTokenMovable(Token token) {
    if (phase != TurnPhase.waitingForMove || currentDiceValue == null) {
      return false;
    }
    // In Team Up, if current player has already finished all 4 tokens, they roll for their teammate!
    if (mode == GameMode.teamUp && currentPlayer.hasFinished) {
      final teammate = currentTeammate;
      if (teammate != null && token.color == teammate.color) {
        return token.canMove(currentDiceValue!);
      }
    }
    if (token.color != currentPlayer.color) {
      return false;
    }
    return token.canMove(currentDiceValue!);
  }
}
