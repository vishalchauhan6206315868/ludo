import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/ludo_path.dart';
import '../models/game_state.dart';
import '../models/ludo_player.dart';
import '../models/token.dart';
import '../services/game_storage_service.dart';
import '../services/sound_haptic_service.dart';
import 'ludo_bot_ai.dart';

class LudoGameController extends ChangeNotifier {
  late GameState state;
  final Random _random = Random();
  bool _disposed = false;

  static const int maxTurnSeconds = 10;
  int turnSecondsRemaining = maxTurnSeconds;
  Timer? _turnTimer;
  bool _isTimerPaused = false;
  bool _isChangingTurn = false;
  bool _isBotPlaying = false;

  @visibleForTesting
  static bool isFastBotForTesting = false;

  Duration _botDelay(int ms) => isFastBotForTesting
      ? const Duration(milliseconds: 10)
      : Duration(milliseconds: ms);

  Duration _stepDelay(int ms) => isFastBotForTesting
      ? const Duration(milliseconds: 5)
      : Duration(milliseconds: ms);

  // Board impact vibration offset during capture
  double boardShakeOffset = 0.0;

  LudoGameController({
    GameMode mode = GameMode.twoPlayer,
    GameState? initialState,
    int passNPlayPlayerCount = 2,
    List<String>? customPlayerNames,
  }) {
    if (initialState != null) {
      state = initialState;
      if (state.phase == TurnPhase.waitingForPlayerHandoff) {
        _isTimerPaused = true;
      } else if (state.currentPlayer.isBot) {
        _triggerBotTurn();
      } else {
        _startTurnTimer();
      }
    } else {
      initGame(
        mode,
        passNPlayPlayerCount: passNPlayPlayerCount,
        customPlayerNames: customPlayerNames,
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _turnTimer?.cancel();
    SoundHapticService.stopAllSounds();
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  void pauseTimer() {
    _isTimerPaused = true;
  }

  void resumeTimer() {
    if (state.isGameOver || state.phase == TurnPhase.waitingForPlayerHandoff) return;
    _isTimerPaused = false;
  }

  @visibleForTesting
  bool get isTimerPaused => _isTimerPaused;

  bool get isBotPlaying => _isBotPlaying;

  @visibleForTesting
  void forceTurnTimeout() => _onTurnTimeout();

  void _startTurnTimer() {
    _turnTimer?.cancel();
    if (state.isGameOver) {
      return;
    }
    turnSecondsRemaining = maxTurnSeconds;
    _isTimerPaused = false;
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }
      if (_isTimerPaused) return;

      if (turnSecondsRemaining > 1) {
        turnSecondsRemaining--;
        _safeNotifyListeners();
      } else {
        turnSecondsRemaining = 0;
        _safeNotifyListeners();
        timer.cancel();
        _onTurnTimeout();
      }
    });
  }

  void _onTurnTimeout() {
    if (_disposed || state.isGameOver || _isChangingTurn) return;

    // Safety timeout: Never skip Computer while Bot is actively playing!
    if (_isBotPlaying || state.currentPlayer.isBot) {
      return;
    }

    // Do not interrupt if goti or dice animations are in the middle of physics
    if (state.phase == TurnPhase.animatingMove ||
        state.phase == TurnPhase.throwingDice) {
      return;
    }

    _isChangingTurn = true;
    _isBotPlaying = false;
    bool shouldTriggerBot = false;
    try {
      _turnTimer?.cancel();

      final timedOutPlayer = state.currentPlayer;

      // Clean up any pending goti animations on timed-out player
      for (final t in timedOutPlayer.tokens) {
        t.animStage = TokenAnimStage.idle;
      }

      state.currentDiceValue = null;
      state.selectedTokenId = null;
      state.consecutiveSixes = 0;

      // Advance turn to next active player
      int nextIdx = (state.currentPlayerIndex + 1) % state.players.length;
      int safetyCount = 0;
      while (state.players[nextIdx].hasFinished &&
          safetyCount < state.players.length) {
        nextIdx = (nextIdx + 1) % state.players.length;
        safetyCount++;
      }

      state.currentPlayerIndex = nextIdx;
      state.currentDiceValue = null;
      state.selectedTokenId = null;
      state.consecutiveSixes = 0;

      if (state.mode == GameMode.passNPlay) {
        state.phase = TurnPhase.waitingForPlayerHandoff;
        state.statusMessage =
            "Time's up for ${timedOutPlayer.name}! Pass the device to ${state.currentPlayer.name}!";
        turnSecondsRemaining = maxTurnSeconds;
        _isTimerPaused = true;
        _safeNotifyListeners();
        GameStorageService.saveGame(state);
        return;
      }

      state.phase = TurnPhase.waitingForRoll;
      state.statusMessage =
          "Time's up for ${timedOutPlayer.name}! ${state.currentPlayer.name}'s turn.";

      // Reset timer to full duration for next player
      turnSecondsRemaining = maxTurnSeconds;
      _isTimerPaused = false;

      _safeNotifyListeners();

      GameStorageService.saveGame(state);

      if (state.currentPlayer.isBot) {
        shouldTriggerBot = true;
      } else {
        _startTurnTimer();
      }
    } finally {
      _isChangingTurn = false;
    }

    if (shouldTriggerBot) {
      _triggerBotTurn();
    }
  }

  void initGame(
    GameMode mode, {
    int passNPlayPlayerCount = 2,
    List<String>? customPlayerNames,
  }) {
    _turnTimer?.cancel();
    _isChangingTurn = false;
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

      case GameMode.threePlayer:
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

      case GameMode.passNPlay:
        final count = (customPlayerNames != null && customPlayerNames.isNotEmpty)
            ? customPlayerNames.length.clamp(2, 4)
            : passNPlayPlayerCount.clamp(2, 4);
        final defaultNames = ["Player 1", "Player 2", "Player 3", "Player 4"];
        String getName(int idx) {
          if (customPlayerNames != null &&
              idx < customPlayerNames.length &&
              customPlayerNames[idx].trim().isNotEmpty) {
            return customPlayerNames[idx].trim();
          }
          return defaultNames[idx];
        }

        if (count == 2) {
          players = [
            LudoPlayer(
              color: PlayerColor.red,
              name: getName(0),
              isBot: false,
            ),
            LudoPlayer(
              color: PlayerColor.yellow,
              name: getName(1),
              isBot: false,
            ),
          ];
        } else if (count == 3) {
          players = [
            LudoPlayer(
              color: PlayerColor.red,
              name: getName(0),
              isBot: false,
            ),
            LudoPlayer(
              color: PlayerColor.green,
              name: getName(1),
              isBot: false,
            ),
            LudoPlayer(
              color: PlayerColor.yellow,
              name: getName(2),
              isBot: false,
            ),
          ];
        } else {
          players = [
            LudoPlayer(
              color: PlayerColor.red,
              name: getName(0),
              isBot: false,
            ),
            LudoPlayer(
              color: PlayerColor.green,
              name: getName(1),
              isBot: false,
            ),
            LudoPlayer(
              color: PlayerColor.yellow,
              name: getName(2),
              isBot: false,
            ),
            LudoPlayer(
              color: PlayerColor.blue,
              name: getName(3),
              isBot: false,
            ),
          ];
        }
        break;
    }

    state = GameState(
      players: players,
      mode: mode,
      currentPlayerIndex: 0,
      phase: TurnPhase.waitingForRoll,
      statusMessage: "${players.first.name}'s turn! Drag & flick dice to throw.",
    );

    turnSecondsRemaining = maxTurnSeconds;
    _safeNotifyListeners();

    if (state.currentPlayer.isBot) {
      _triggerBotTurn();
    } else {
      _startTurnTimer();
    }
  }

  /// Trigger subtle board impact vibration on capture
  Future<void> triggerCaptureShake() async {
    final offsets = [4.5, -4.5, 3.0, -3.0, 1.5, 0.0];
    for (final offset in offsets) {
      boardShakeOffset = offset;
      _safeNotifyListeners();
      await Future.delayed(const Duration(milliseconds: 32));
      if (_disposed) return;
    }
    boardShakeOffset = 0.0;
    _safeNotifyListeners();
  }

  /// Common dice throw animation pipeline for Human and Computer
  Future<void> playDiceThrowAnimation({
    required int roll,
    required bool isHuman,
  }) async {
    SoundHapticService.playDiceRollSound();
    state.phase = TurnPhase.throwingDice;
    state.currentDiceValue = roll;
    state.statusMessage = "${state.currentPlayer.name} throws the dice!";
    _turnTimer?.cancel();
    _safeNotifyListeners();

    if (!isHuman) {
      // Computer awaits the exact same physical trajectory, flight, bounces, and settle duration
      await Future.delayed(_botDelay(1750));
      SoundHapticService.onDiceResult();
    }
  }

  /// Unified logical dice roll generation and phase transition for both Human and Computer
  int initiateDiceThrow({bool isHuman = true}) {
    if (state.phase != TurnPhase.waitingForRoll ||
        _isChangingTurn ||
        (isHuman && (state.currentPlayer.isBot || _isBotPlaying))) {
      return state.currentDiceValue ?? (_random.nextInt(6) + 1);
    }

    final roll = _random.nextInt(6) + 1;
    playDiceThrowAnimation(roll: roll, isHuman: isHuman);
    return roll;
  }

  /// Initiates physical dice throw from finger drag release or bot/tap
  void onPhysicalDiceThrowStart() {
    if (state.phase != TurnPhase.waitingForRoll ||
        _isChangingTurn ||
        state.currentPlayer.isBot ||
        _isBotPlaying) {
      return;
    }
    initiateDiceThrow(isHuman: true);
  }

  /// Called when the physical dice finishes flight, bounces, and settles on the board
  Future<void> onPhysicalDiceThrowComplete(int roll) async {
    if (_disposed || state.isGameOver) return;
    if (state.currentPlayer.isBot) return; // Bot turn is managed by playBotTurn()
    state.currentDiceValue = roll;

    // Check consecutive sixes
    if (roll == 6) {
      state.consecutiveSixes++;
      if (state.consecutiveSixes == 3) {
        state.statusMessage = "3 consecutive Sixes! Turn passed.";
        state.consecutiveSixes = 0;
        state.phase = TurnPhase.animatingMove;
        _safeNotifyListeners();

        await Future.delayed(const Duration(milliseconds: 900));
        if (_disposed) return;
        _nextTurn();
        return;
      }
    } else {
      state.consecutiveSixes = 0;
    }

    // Check movable tokens
    final movable = state.currentPlayer.getMovableTokens(roll);

    if (movable.isEmpty) {
      state.statusMessage =
          "${state.currentPlayer.name} rolled $roll. No moves possible!";
      state.phase = TurnPhase.animatingMove;
      _safeNotifyListeners();

      await Future.delayed(const Duration(milliseconds: 950));
      if (_disposed) return;
      _nextTurn();
      return;
    }

    final player = state.currentPlayer;

    // First Token Auto-Opening Rule:
    // When a human player has not opened their first-ever token yet and rolls 6:
    // Automatically open their first starting token from base without prompting for selection or waiting for tap!
    if (!player.isBot &&
        !player.hasOpenedFirstToken &&
        roll == 6 &&
        movable.any((t) => t.isInBase)) {
      final tokenToOpen = movable.firstWhere((t) => t.isInBase);
      player.hasOpenedFirstToken = true;
      state.phase = TurnPhase.animatingMove;
      state.statusMessage =
          "${player.name} rolled 6! First goti automatically opened!";
      state.selectedTokenId = tokenToOpen.id;
      _safeNotifyListeners();

      await Future.delayed(_stepDelay(400));
      if (_disposed || state.isGameOver) return;
      await moveToken(tokenToOpen);
      return;
    }

    state.phase = TurnPhase.waitingForMove;
    state.statusMessage =
        "${state.currentPlayer.name} rolled $roll! Tap a glowing goti to move.";
    _safeNotifyListeners();

    // If current player is bot, AI picks token
    if (state.currentPlayer.isBot) {
      await Future.delayed(const Duration(milliseconds: 650));
      if (_disposed) return;
      final best = LudoBotAI.pickBestToken(
        botPlayer: state.currentPlayer,
        allPlayers: state.players,
        diceValue: roll,
      );
      if (best != null) {
        await moveToken(best);
      }
    } else {
      // Human turn: start move timer
      _startTurnTimer();

      // Smart Auto-Move Logic:
      // When roll is not 6 (1..5) and there is exactly 1 movable token (e.g. only 1 open goti),
      // auto-move it so the player doesn't have to tap unnecessarily.
      // If roll is 6, player gets to decide which goti to move (unlock goti vs advance open goti).
      if (roll != 6 && movable.length == 1) {
        state.phase = TurnPhase.animatingMove;
        state.statusMessage =
            "${state.currentPlayer.name} rolled $roll! Auto-moving goti...";
        state.selectedTokenId = movable.first.id;
        _safeNotifyListeners();

        await Future.delayed(_stepDelay(400));
        if (_disposed || state.isGameOver) return;
        await moveToken(movable.first);
      } else if (roll == 6 && movable.length == 1) {
        // Single remaining movable token on roll of 6 (no decision needed)
        state.phase = TurnPhase.animatingMove;
        state.statusMessage =
            "${state.currentPlayer.name} rolled 6! Auto-moving goti...";
        state.selectedTokenId = movable.first.id;
        _safeNotifyListeners();

        await Future.delayed(_stepDelay(400));
        if (_disposed || state.isGameOver) return;
        await moveToken(movable.first);
      }
    }
  }

  /// Handles user tapping a token directly on the board
  Future<void> onTokenTapped(Token token) async {
    // 1. If currently animating, throwing dice, waiting for handoff, changing turn, bot playing, or game over, ignore taps (lock input)
    if (state.phase == TurnPhase.animatingMove ||
        state.phase == TurnPhase.throwingDice ||
        state.phase == TurnPhase.waitingForPlayerHandoff ||
        _isChangingTurn ||
        _isBotPlaying ||
        state.currentPlayer.isBot ||
        state.isGameOver) {
      return;
    }

    // 2. Direct goti tap during roll phase launches dice throw!
    if (state.phase == TurnPhase.waitingForRoll) {
      if (token.color != state.currentPlayer.color || state.currentPlayer.isBot) {
        return;
      }
      rollDice();
      return;
    }

    // 3. Normal Move Phase: User taps a glowing movable token
    if (state.phase == TurnPhase.waitingForMove) {
      if (token.color != state.currentPlayer.color || state.currentPlayer.isBot) return;
      if (!token.canMove(state.currentDiceValue!)) return;

      await moveToken(token);
    }
  }

  /// Rolls the dice (triggers physical throw sequence)
  void rollDice() {
    if (state.phase != TurnPhase.waitingForRoll ||
        _isChangingTurn ||
        state.currentPlayer.isBot ||
        _isBotPlaying) {
      return;
    }
    onPhysicalDiceThrowStart();
  }

  /// Moves the chosen token with realistic throw & step-by-step hopping
  Future<MoveResult> moveToken(Token token, {bool autoAdvanceTurn = true}) async {
    if ((state.phase != TurnPhase.waitingForMove &&
            state.phase != TurnPhase.animatingMove) ||
        state.currentDiceValue == null ||
        _isChangingTurn) {
      return const MoveResult();
    }
    if (token.color != state.currentPlayer.color) return const MoveResult();
    if (!token.canMove(state.currentDiceValue!)) return const MoveResult();

    final diceVal = state.currentDiceValue!;
    return await _executeStepByStepMovement(token, diceVal, autoAdvanceTurn: autoAdvanceTurn);
  }

  /// Executes complete realistic movement sequence: Throw -> Hopping -> Capture -> Safe/Goal -> Next Turn
  Future<MoveResult> _executeStepByStepMovement(
    Token token,
    int diceVal, {
    bool autoAdvanceTurn = true,
  }) async {
    _turnTimer?.cancel();
    state.phase = TurnPhase.animatingMove;
    _safeNotifyListeners();

    // 1. Initial 3D Throw / Lift Animation on the selected goti
    token.animStage = TokenAnimStage.throwing;
    _safeNotifyListeners();

    await Future.delayed(_stepDelay(550));
    if (_disposed) return const MoveResult();

    token.animStage = TokenAnimStage.idle;
    _safeNotifyListeners();

    bool extraTurn = false;
    bool capturedOpponent = false;
    bool reachedHomeGoal = false;
    bool enteredHomeStretch = false;

    // 2. Step-by-step Hopping Movement
    if (token.isInBase) {
      state.currentPlayer.hasOpenedFirstToken = true;
      // Come out of base onto starting cell
      token.animStage = TokenAnimStage.hopping;
      token.step = 0;
      SoundHapticService.onTokenOpen();
      _safeNotifyListeners();

      await Future.delayed(_stepDelay(260));
      if (_disposed) return const MoveResult();

      token.animStage = TokenAnimStage.idle;
      _safeNotifyListeners();
    } else {
      final target = token.step + diceVal;
      while (token.step < target) {
        token.step++;
        if (token.step == 51) {
          enteredHomeStretch = true;
        }
        token.animStage = TokenAnimStage.hopping;
        SoundHapticService.playTokenStepSound();
        _safeNotifyListeners();

        await Future.delayed(_stepDelay(230));
        if (_disposed) return const MoveResult();
      }

      token.animStage = TokenAnimStage.idle;
      _safeNotifyListeners();

      if (enteredHomeStretch && token.step < 56) {
        SoundHapticService.onHomeStretchEnter();
      }
    }

    // 3. Check for captures with impact shake and opponent base return
    if (token.step <= 50) {
      final coord = token.coordinate;
      if (!LudoPath.isSafeCoord(coord)) {
        for (final p in state.players) {
          if (p.color == token.color) continue;
          for (final enemyToken in p.tokens) {
            if (enemyToken.isPlaying && enemyToken.coordinate == coord) {
              // Capture impact!
              triggerCaptureShake();
              SoundHapticService.onTokenCapture();
              enemyToken.animStage = TokenAnimStage.captured;
              state.statusMessage =
                  "Boom! ${state.currentPlayer.name} captured ${p.name}'s goti!";
              _safeNotifyListeners();

              await Future.delayed(_stepDelay(280));
              if (_disposed) return const MoveResult();

              // Opponent smoothly returns to base slot
              enemyToken.step = -1;
              _safeNotifyListeners();

              await Future.delayed(_stepDelay(380));
              if (_disposed) return const MoveResult();

              enemyToken.animStage = TokenAnimStage.idle;
              extraTurn = true;
              capturedOpponent = true;
              _safeNotifyListeners();
            }
          }
        }
      }
    }

    // 4. Safe Star Sparkle Effect or Normal Landing
    if (token.step <= 50 && LudoPath.isSafeCoord(token.coordinate)) {
      token.animStage = TokenAnimStage.safeGlow;
      SoundHapticService.onSafeCellLanding();
      _safeNotifyListeners();

      await Future.delayed(_stepDelay(400));
      if (_disposed) return const MoveResult();

      token.animStage = TokenAnimStage.idle;
      _safeNotifyListeners();
    } else if (!capturedOpponent && !token.hasReachedGoal && !token.isInBase) {
      // Normal track cell landing (controlled short haptic)
      SoundHapticService.onTokenStepLanding();
    }

    // 5. Check if reached Goal
    if (token.hasReachedGoal) {
      extraTurn = true;
      reachedHomeGoal = true;
      token.animStage = TokenAnimStage.goalCelebration;
      SoundHapticService.onHomeGoal();
      state.statusMessage =
          "🎉 Goti reached Home! Bonus roll for ${state.currentPlayer.name}!";
      _safeNotifyListeners();

      await Future.delayed(_stepDelay(650));
      if (_disposed) return const MoveResult();

      token.animStage = TokenAnimStage.idle;
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
          SoundHapticService.onVictory();
          GameStorageService.clearSavedGame();
          _safeNotifyListeners();
          return MoveResult(
            captured: capturedOpponent,
            reachedHome: reachedHomeGoal,
            extraTurn: false,
            gameOver: true,
          );
        }
      }
      await Future.delayed(_stepDelay(400));
      if (_disposed) return const MoveResult();
    }

    // 6. Extra turn if rolled 6
    if (diceVal == 6) {
      extraTurn = true;
    }

    // A player who has completed all 4 tokens has finished their game and cannot have an extra turn
    if (state.currentPlayer.hasFinished) {
      extraTurn = false;
    }

    final moveResult = MoveResult(
      captured: capturedOpponent,
      reachedHome: reachedHomeGoal,
      extraTurn: extraTurn,
      gameOver: state.isGameOver,
    );

    if (autoAdvanceTurn) {
      if (extraTurn && !state.currentPlayer.hasFinished) {
        state.phase = TurnPhase.waitingForRoll;
        state.currentDiceValue = null;
        state.statusMessage =
            "Bonus turn for ${state.currentPlayer.name}! Drag & throw dice again.";
        turnSecondsRemaining = maxTurnSeconds;
        _safeNotifyListeners();
        GameStorageService.saveGame(state);

        if (state.currentPlayer.isBot) {
          _triggerBotTurn();
        } else {
          _startTurnTimer();
        }
      } else {
        _nextTurn();
      }
    }

    return moveResult;
  }

  void _nextTurn() {
    if (_disposed || state.isGameOver || _isChangingTurn) return;
    _isChangingTurn = true;
    _isBotPlaying = false;
    bool shouldTriggerBot = false;
    try {
      _turnTimer?.cancel();

      int nextIdx = (state.currentPlayerIndex + 1) % state.players.length;

      // Skip players who have already finished all 4 tokens
      int safetyCount = 0;
      while (state.players[nextIdx].hasFinished &&
          safetyCount < state.players.length) {
        nextIdx = (nextIdx + 1) % state.players.length;
        safetyCount++;
      }

      state.currentPlayerIndex = nextIdx;
      state.currentDiceValue = null;
      state.selectedTokenId = null;
      state.consecutiveSixes = 0;

      if (state.mode == GameMode.passNPlay) {
        state.phase = TurnPhase.waitingForPlayerHandoff;
        state.statusMessage =
            "Pass the device to ${state.currentPlayer.name}!";
        turnSecondsRemaining = maxTurnSeconds;
        _isTimerPaused = true;
        _safeNotifyListeners();
        GameStorageService.saveGame(state);
        return;
      }

      state.phase = TurnPhase.waitingForRoll;
      state.statusMessage =
          "${state.currentPlayer.name}'s turn! Drag & throw dice.";
      turnSecondsRemaining = maxTurnSeconds;
      _isTimerPaused = false;
      _safeNotifyListeners();

      GameStorageService.saveGame(state);

      if (state.currentPlayer.isBot) {
        shouldTriggerBot = true;
      } else {
        _startTurnTimer();
      }
    } finally {
      _isChangingTurn = false;
    }

    if (shouldTriggerBot) {
      _triggerBotTurn();
    }
  }

  /// Called when the next player taps "I'M READY" in Pass N Play mode
  void onPlayerReady() {
    if (_disposed ||
        state.isGameOver ||
        state.phase != TurnPhase.waitingForPlayerHandoff) {
      return;
    }
    state.phase = TurnPhase.waitingForRoll;
    state.statusMessage =
        "${state.currentPlayer.name}'s turn! Drag & throw dice.";
    turnSecondsRemaining = maxTurnSeconds;
    _isTimerPaused = false;
    _safeNotifyListeners();
    GameStorageService.saveGame(state);
    _startTurnTimer();
  }

  /// Dedicated alias for computer turn automation
  Future<void> playBotTurn() => playComputerTurn();

  /// Dedicated computer turn automation:
  /// Thinking -> Automatic Dice Roll -> AI Token Selection -> Movement Animation -> Extra Turn Check -> Next Player
  Future<void> playComputerTurn() async {
    if (_disposed || state.isGameOver || _isChangingTurn || _isBotPlaying) return;
    if (!state.currentPlayer.isBot || state.currentPlayer.hasFinished) return;

    _isBotPlaying = true;
    debugPrint('[BOT] TURN START');
    debugPrint('[BOT] Current Player = ${state.currentPlayer.name}');

    try {
      while (!_disposed && !state.isGameOver && state.currentPlayer.isBot) {
        // Reset and maintain turn timer for safety display
        turnSecondsRemaining = maxTurnSeconds;
        _isTimerPaused = false;
        debugPrint('[BOT] Timer started');
        _safeNotifyListeners();

        // 1. Initial realistic thinking pause
        state.phase = TurnPhase.waitingForRoll;
        state.statusMessage = "${state.currentPlayer.name} is thinking...";
        _safeNotifyListeners();

        await Future.delayed(_botDelay(650));
        if (_disposed || state.isGameOver || !state.currentPlayer.isBot) return;

        // 2. Unified automatic dice roll trigger
        debugPrint('[BOT] Starting automatic dice roll');
        final roll = _random.nextInt(6) + 1;
        debugPrint('[BOT] Dice animation started');
        await playDiceThrowAnimation(roll: roll, isHuman: false);
        if (_disposed || state.isGameOver || !state.currentPlayer.isBot) return;

        debugPrint('[BOT] Dice result = $roll');
        state.statusMessage = "${state.currentPlayer.name} rolled $roll!";
        _safeNotifyListeners();

        // 4. Check 3 consecutive sixes rule
        if (roll == 6) {
          state.consecutiveSixes++;
          if (state.consecutiveSixes == 3) {
            state.statusMessage = "3 consecutive Sixes! Turn passed.";
            state.consecutiveSixes = 0;
            state.phase = TurnPhase.animatingMove;
            _safeNotifyListeners();

            await Future.delayed(_botDelay(850));
            if (_disposed || state.isGameOver) return;
            debugPrint('[BOT] Extra turn = false');
            debugPrint('[BOT] COMPUTER TURN COMPLETE');
            debugPrint('[BOT] Starting HUMAN TURN');
            _isBotPlaying = false;
            _nextTurn();
            return;
          }
        } else {
          state.consecutiveSixes = 0;
        }

        // 5. Check movable tokens
        final movable = state.currentPlayer.getMovableTokens(roll);
        debugPrint('[BOT] Movable tokens = ${movable.length}');

        if (movable.isEmpty) {
          state.statusMessage =
              "${state.currentPlayer.name} rolled $roll. No moves possible!";
          state.phase = TurnPhase.animatingMove;
          _safeNotifyListeners();

          await Future.delayed(_botDelay(950));
          if (_disposed || state.isGameOver) return;
          debugPrint('[BOT] Extra turn = false');
          debugPrint('[BOT] COMPUTER TURN COMPLETE');
          debugPrint('[BOT] Starting HUMAN TURN');
          _isBotPlaying = false;
          _nextTurn();
          return;
        }

        // 6. Bot selects best token using tactical AI heuristic
        state.phase = TurnPhase.waitingForMove;
        state.statusMessage =
            "${state.currentPlayer.name} rolled $roll! Choosing goti...";
        _safeNotifyListeners();

        await Future.delayed(_botDelay(600));
        if (_disposed || state.isGameOver || !state.currentPlayer.isBot) return;

        Token? bestToken = LudoBotAI.pickBestToken(
          botPlayer: state.currentPlayer,
          allPlayers: state.players,
          diceValue: roll,
        );
        bestToken ??= movable.first;

        // Verify token validity
        if (!state.currentPlayer.tokens.contains(bestToken) ||
            !bestToken.canMove(roll)) {
          bestToken = movable.first;
        }
        debugPrint('[BOT] AI selected token = ${bestToken.id}');

        // Highlight chosen token briefly
        state.selectedTokenId = bestToken.id;
        state.statusMessage = "${state.currentPlayer.name} moving goti...";
        _safeNotifyListeners();

        await Future.delayed(_botDelay(350));
        if (_disposed || state.isGameOver || !state.currentPlayer.isBot) return;

        // 7. Execute step-by-step movement and await animation completely
        debugPrint('[BOT] Token movement started');
        final moveResult = await _executeStepByStepMovement(
          bestToken,
          roll,
          autoAdvanceTurn: false,
        );
        debugPrint('[BOT] Token movement completed');
        debugPrint('[BOT] Capture = ${moveResult.captured}');
        debugPrint('[BOT] Reached home = ${moveResult.reachedHome}');
        debugPrint('[BOT] Extra turn = ${moveResult.extraTurn}');

        if (moveResult.gameOver || state.isGameOver) {
          debugPrint('[BOT] COMPUTER TURN COMPLETE');
          _isBotPlaying = false;
          return;
        }

        // 8. If extra turn -> Computer automatically rolls again
        if (moveResult.extraTurn) {
          state.phase = TurnPhase.waitingForRoll;
          state.currentDiceValue = null;
          state.selectedTokenId = null;
          state.statusMessage =
              "Bonus turn for ${state.currentPlayer.name}! Rolling again...";
          turnSecondsRemaining = maxTurnSeconds;
          _safeNotifyListeners();
          GameStorageService.saveGame(state);
          // Loop continues for the extra turn
          continue;
        } else {
          // 9. Otherwise -> end Computer turn, start Human turn
          debugPrint('[BOT] COMPUTER TURN COMPLETE');
          debugPrint('[BOT] Starting HUMAN TURN');
          _isBotPlaying = false;
          _nextTurn();
          return;
        }
      }
    } catch (e, stack) {
      debugPrint('[BOT] Error in computer turn: $e\n$stack');
      _isBotPlaying = false;
      if (!_disposed && !state.isGameOver) {
        _nextTurn();
      }
    } finally {
      _isBotPlaying = false;
    }
  }

  void _triggerBotTurn() {
    _startTurnTimer();
    playComputerTurn();
  }

  void restartGame({List<String>? customPlayerNames}) {
    GameStorageService.clearSavedGame();
    final names = customPlayerNames ??
        (state.mode == GameMode.passNPlay
            ? state.players.map((p) => p.name).toList()
            : null);
    initGame(
      state.mode,
      passNPlayPlayerCount: state.players.length,
      customPlayerNames: names,
    );
  }
}

/// Movement execution result detailing captures, home goals, extra turn, and game over state
class MoveResult {
  final bool captured;
  final bool reachedHome;
  final bool extraTurn;
  final bool gameOver;

  const MoveResult({
    this.captured = false,
    this.reachedHome = false,
    this.extraTurn = false,
    this.gameOver = false,
  });
}

