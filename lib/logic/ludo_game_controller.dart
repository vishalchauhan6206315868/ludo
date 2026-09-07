import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/ludo_path.dart';
import '../models/game_state.dart';
import '../models/ludo_player.dart';
import '../models/token.dart';
import 'ludo_bot_ai.dart';

class LudoGameController extends ChangeNotifier {
  late GameState state;
  final Random _random = Random();
  bool _disposed = false;

  LudoGameController({GameMode mode = GameMode.twoPlayer}) {
    initGame(mode);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  void initGame(GameMode mode) {
    List<LudoPlayer> players = [];

    switch (mode) {
      case GameMode.twoPlayer:
        players = [
          LudoPlayer(
            color: PlayerColor.red,
            name: "Player 1 (Red)",
            isBot: false,
          ),
          LudoPlayer(
            color: PlayerColor.yellow,
            name: "Player 2 (Yellow)",
            isBot: false,
          ),
        ];
        break;

      case GameMode.fourPlayer:
        players = [
          LudoPlayer(
            color: PlayerColor.red,
            name: "Player 1 (Red)",
            isBot: false,
          ),
          LudoPlayer(
            color: PlayerColor.green,
            name: "Player 2 (Green)",
            isBot: false,
          ),
          LudoPlayer(
            color: PlayerColor.yellow,
            name: "Player 3 (Yellow)",
            isBot: false,
          ),
          LudoPlayer(
            color: PlayerColor.blue,
            name: "Player 4 (Blue)",
            isBot: false,
          ),
        ];
        break;

      case GameMode.vsComputer:
        players = [
          LudoPlayer(
            color: PlayerColor.red,
            name: "You (Red)",
            isBot: false,
          ),
          LudoPlayer(
            color: PlayerColor.yellow,
            name: "Computer (Yellow)",
            isBot: true,
          ),
        ];
        break;
    }

    state = GameState(
      players: players,
      mode: mode,
      currentPlayerIndex: 0,
      phase: TurnPhase.waitingForRoll,
      statusMessage: "${players.first.name}'s turn! Tap dice to roll.",
    );

    _safeNotifyListeners();

    if (state.currentPlayer.isBot) {
      _triggerBotTurn();
    }
  }

  /// Rolls the dice
  Future<void> rollDice() async {
    if (state.phase != TurnPhase.waitingForRoll) return;

    final player = state.currentPlayer;
    state.phase = TurnPhase.animatingMove;
    state.statusMessage = "${player.name} is rolling...";
    _safeNotifyListeners();

    // Dice rolling animation delay
    await Future.delayed(const Duration(milliseconds: 550));
    if (_disposed) return;

    final roll = _random.nextInt(6) + 1;
    state.currentDiceValue = roll;

    // Check consecutive sixes
    if (roll == 6) {
      state.consecutiveSixes++;
      if (state.consecutiveSixes == 3) {
        state.statusMessage = "3 consecutive Sixes! Turn passed.";
        state.consecutiveSixes = 0;
        state.phase = TurnPhase.animatingMove;
        _safeNotifyListeners();

        await Future.delayed(const Duration(milliseconds: 1000));
        if (_disposed) return;
        _nextTurn();
        return;
      }
    } else {
      state.consecutiveSixes = 0;
    }

    // Check movable tokens
    final movable = player.getMovableTokens(roll);

    if (movable.isEmpty) {
      state.statusMessage = "${player.name} rolled $roll. No moves possible!";
      state.phase = TurnPhase.animatingMove;
      _safeNotifyListeners();

      await Future.delayed(const Duration(milliseconds: 1000));
      if (_disposed) return;
      _nextTurn();
      return;
    }

    state.phase = TurnPhase.waitingForMove;
    state.statusMessage =
        "${player.name} rolled $roll! Tap a glowing token to move.";
    _safeNotifyListeners();

    // If current player is bot, AI picks token
    if (player.isBot) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (_disposed) return;
      final best = LudoBotAI.pickBestToken(
        botPlayer: player,
        allPlayers: state.players,
        diceValue: roll,
      );
      if (best != null) {
        await moveToken(best);
      }
    } else if (movable.length == 1 && movable.first.isInBase) {
      // Auto-move single token coming out of base for fast gameplay
      await Future.delayed(const Duration(milliseconds: 400));
      if (_disposed) return;
      await moveToken(movable.first);
    }
  }

  /// Moves the chosen token
  Future<void> moveToken(Token token) async {
    if (state.phase != TurnPhase.waitingForMove ||
        state.currentDiceValue == null) {
      return;
    }
    if (token.color != state.currentPlayer.color) return;
    if (!token.canMove(state.currentDiceValue!)) return;

    state.phase = TurnPhase.animatingMove;
    final diceVal = state.currentDiceValue!;
    _safeNotifyListeners();

    bool extraTurn = false;

    // Step-by-step movement animation
    if (token.isInBase) {
      // Come out of base to start tile
      token.step = 0;
      _safeNotifyListeners();
      await Future.delayed(const Duration(milliseconds: 250));
      if (_disposed) return;
    } else {
      final target = token.step + diceVal;
      while (token.step < target) {
        token.step++;
        _safeNotifyListeners();
        await Future.delayed(const Duration(milliseconds: 130));
        if (_disposed) return;
      }
    }

    // Check for captures
    if (token.step <= 50) {
      final coord = token.coordinate;
      if (!LudoPath.isSafeCoord(coord)) {
        for (final p in state.players) {
          if (p.color == token.color) continue;
          for (final enemyToken in p.tokens) {
            if (enemyToken.isPlaying && enemyToken.coordinate == coord) {
              // Capture!
              enemyToken.step = -1; // Send back to base
              extraTurn = true;
              state.statusMessage =
                  "Boom! ${state.currentPlayer.name} captured ${p.name}'s token!";
              _safeNotifyListeners();
              await Future.delayed(const Duration(milliseconds: 700));
              if (_disposed) return;
            }
          }
        }
      }
    }

    // Check if reached Goal
    if (token.hasReachedGoal) {
      extraTurn = true;
      state.statusMessage =
          "🎉 Token reached Home! Bonus roll for ${state.currentPlayer.name}!";
      _safeNotifyListeners();

      // Check if player won
      if (state.currentPlayer.hasFinished) {
        if (!state.winners.contains(state.currentPlayer)) {
          state.winners.add(state.currentPlayer);
          state.currentPlayer.rank = state.winners.length;
        }

        final remaining = state.players.where((p) => !p.hasFinished).toList();
        if (remaining.length <= 1) {
          // Game Over!
          if (remaining.isNotEmpty && !state.winners.contains(remaining.first)) {
            state.winners.add(remaining.first);
            remaining.first.rank = state.winners.length;
          }
          state.phase = TurnPhase.gameOver;
          state.statusMessage = "🏆 Game Over! ${state.winners.first.name} Won!";
          _safeNotifyListeners();
          return;
        }
      }
      await Future.delayed(const Duration(milliseconds: 700));
      if (_disposed) return;
    }

    // Extra turn if rolled 6
    if (diceVal == 6) {
      extraTurn = true;
    }

    if (extraTurn) {
      state.phase = TurnPhase.waitingForRoll;
      state.currentDiceValue = null;
      state.statusMessage =
          "Bonus turn for ${state.currentPlayer.name}! Roll again.";
      _safeNotifyListeners();

      if (state.currentPlayer.isBot) {
        _triggerBotTurn();
      }
    } else {
      _nextTurn();
    }
  }

  void _nextTurn() {
    int nextIdx = (state.currentPlayerIndex + 1) % state.players.length;

    // Skip players who have already finished all 4 tokens
    int safetyCount = 0;
    while (state.players[nextIdx].hasFinished && safetyCount < state.players.length) {
      nextIdx = (nextIdx + 1) % state.players.length;
      safetyCount++;
    }

    state.currentPlayerIndex = nextIdx;
    state.currentDiceValue = null;
    state.phase = TurnPhase.waitingForRoll;
    state.consecutiveSixes = 0;
    state.statusMessage = "${state.currentPlayer.name}'s turn! Roll dice.";
    _safeNotifyListeners();

    if (state.currentPlayer.isBot) {
      _triggerBotTurn();
    }
  }

  void _triggerBotTurn() {
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!_disposed &&
          state.currentPlayer.isBot &&
          state.phase == TurnPhase.waitingForRoll) {
        rollDice();
      }
    });
  }

  void restartGame() {
    initGame(state.mode);
  }
}
