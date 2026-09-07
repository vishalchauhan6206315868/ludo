import 'ludo_player.dart';
import 'token.dart';

enum GameMode {
  twoPlayer,
  fourPlayer,
  vsComputer,
}

enum TurnPhase {
  waitingForRoll,
  waitingForMove,
  animatingMove,
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
  }) : winners = winners ?? [];

  LudoPlayer get currentPlayer => players[currentPlayerIndex];

  bool get isWaitingForRoll => phase == TurnPhase.waitingForRoll;
  bool get isWaitingForMove => phase == TurnPhase.waitingForMove;
  bool get isGameOver => phase == TurnPhase.gameOver;

  bool isTokenMovable(Token token) {
    if (phase != TurnPhase.waitingForMove || currentDiceValue == null) {
      return false;
    }
    if (token.color != currentPlayer.color) {
      return false;
    }
    return token.canMove(currentDiceValue!);
  }
}
