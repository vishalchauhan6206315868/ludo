import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/ludo_path.dart';
import '../core/network/api_service.dart';
import '../models/game_state.dart';
import '../models/ludo_player.dart';
import '../models/online_game_mode.dart';
import '../models/room_model.dart';
import '../models/token.dart';
import '../services/auth_service.dart';
import '../services/game_storage_service.dart';
import '../services/ludo_socket_service.dart';
import '../services/sound_haptic_service.dart';
import '../widgets/celebration/passed_celebration_overlay.dart';
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
  bool _isProcessingDiceResult = false;
  bool _isMovingToken = false;
  bool _isBotPlaying = false;

  @visibleForTesting
  static bool isFastBotForTesting = false;

  /// Holds current celebration state when a goti reaches Home/Passed goal
  PassedCelebrationData? activeCelebration;

  Duration _botDelay(int ms) => isFastBotForTesting
      ? const Duration(milliseconds: 10)
      : Duration(milliseconds: ms);

  Duration _stepDelay(int ms) => isFastBotForTesting
      ? const Duration(milliseconds: 5)
      : Duration(milliseconds: ms);

  // Board impact vibration offset during capture
  double boardShakeOffset = 0.0;

  // Tracks consecutive dry rolls (no 6) while ALL 4 of a player's gotis are still in base
  final Map<PlayerColor, int> _baseNoSixCount = {};
  final Map<PlayerColor, int> _baseNoSixThreshold = {};

  String? sessionId;
  final String? roomCode;
  final bool isTeamUpVsBot;
  final bool isOnlineMatch;
  final bool isHost;
  int mySeatIndex;

  // ---- online match (Socket.IO): the SERVER decides, this phone only shows & requests ----
  final LudoSocketService _socket = LudoSocketService.instance;
  final List<StreamSubscription<dynamic>> _onlineSubs = [];
  final Map<String, int> _onlineSeatByUser = {};
  Future<void> _onlineQueue = Future.value();
  int _onlineVersion = -1;
  Completer<void>? _diceSettleCompleter;
  bool _onlineRollPending = false;
  bool _onlineMovePending = false;
  Timer? _onlineCountdown;
  DateTime? _onlineDeadline;
  String? _lastTimeoutName;

  /// Tokens (ids) the server allows to move with the current dice.
  List<int> onlineMovableTokenIds = const [];

  /// For the "Reconnecting..." banner.
  LudoConnectionStatus onlineConnection = LudoConnectionStatus.connecting;

  /// Seats whose player is currently disconnected.
  final Set<int> offlineSeats = {};

  /// Payload of the final `match_finished` event (same on both phones), once received.
  Map<String, dynamic>? onlineResult;

  /// Seat of the winner according to the server (null = draw / not finished).
  int? onlineWinnerSeat;

  bool get isMyTurn => !isOnlineMatch || (state.currentPlayerIndex == mySeatIndex);

  /// Callback requested when dice needs to fly from board to a player pod (same player on extra turn, or next player)
  Future<void> Function(PlayerColor targetColor)? onDiceTravelRequested;

  /// Most recent settled dice roll value across turns (used for seamless display)
  int lastSettledDiceValue = 1;

  final OnlineModeType? onlineModeType;

  LudoGameController({
    GameMode mode = GameMode.twoPlayer,
    GameState? initialState,
    int passNPlayPlayerCount = 2,
    List<String>? customPlayerNames,
    this.sessionId,
    this.roomCode,
    this.isTeamUpVsBot = false,
    this.isOnlineMatch = false,
    this.isHost = true,
    this.mySeatIndex = 0,
    this.onlineModeType,
  }) {
    if (initialState != null) {
      state = initialState;
      if (state.phase == TurnPhase.waitingForPlayerHandoff) {
        state.phase = TurnPhase.waitingForRoll;
        _startTurnTimer();
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
        isVsBot: isTeamUpVsBot,
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _turnTimer?.cancel();
    _disposeOnline();
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
  Future<void> forceTurnTimeout({bool autoPlay = false}) => _onTurnTimeout(autoPlay: autoPlay);

  void _startTurnTimer() {
    if (isOnlineMatch) return; // online: the server owns the clock (see _startOnlineCountdown)
    _turnTimer?.cancel();
    if (state.isGameOver) {
      return;
    }
    turnSecondsRemaining = maxTurnSeconds;
    _isTimerPaused = false;
    // Manual dice rolls only: do not auto-roll human dice on a countdown timer.
  }

  Future<void> _onTurnTimeout({bool autoPlay = true}) async {
    if (isOnlineMatch) return; // online: the server times turns out and tells both phones
    if (_disposed ||
        state.isGameOver ||
        _isChangingTurn ||
        _isProcessingDiceResult ||
        _isMovingToken) {
      return;
    }

    // Safety timeout: Never skip Computer while Bot is actively playing!
    if (_isBotPlaying || state.currentPlayer.isBot) {
      return;
    }

    // Do not interrupt if goti or dice animations are in the middle of physics
    if (state.phase == TurnPhase.animatingMove ||
        state.phase == TurnPhase.throwingDice) {
      return;
    }

    // AUTO-PLAY ON TIMEOUT:
    // 1. If player has not rolled the dice yet, auto-roll the dice for them!
    if (autoPlay && state.phase == TurnPhase.waitingForRoll) {
      _turnTimer?.cancel();
      state.statusMessage =
          "Time's up! Auto-rolling for ${state.currentPlayer.name}...";
      _safeNotifyListeners();
      initiateDiceThrow(isHuman: true);
      return;
    }

    // 2. If player rolled the dice but did not pick a goti, auto-move the best goti for them!
    if (autoPlay &&
        state.phase == TurnPhase.waitingForMove &&
        state.currentDiceValue != null) {
      _turnTimer?.cancel();
      final diceVal = state.currentDiceValue!;
      List<Token> movable = state.currentPlayer.getMovableTokens(diceVal);
      if (movable.isEmpty &&
          state.mode == GameMode.teamUp &&
          state.currentPlayer.hasFinished) {
        final teammate = state.currentTeammate;
        if (teammate != null && !teammate.hasFinished) {
          movable = teammate.getMovableTokens(diceVal);
        }
      }

      if (movable.isNotEmpty) {
        state.statusMessage =
            "Time's up! Auto-moving goti for ${state.currentPlayer.name}...";
        _safeNotifyListeners();

        Token? bestToken = LudoBotAI.pickBestToken(
          botPlayer: state.currentPlayer,
          allPlayers: state.players,
          diceValue: diceVal,
        );
        bestToken ??= movable.first;
        if (!movable.contains(bestToken)) {
          bestToken = movable.first;
        }

        await moveToken(bestToken);
        return;
      }
    }

    // Fallback: Skip turn if no legal action exists or autoPlay is false
    if (sessionId != null && sessionId!.isNotEmpty) {
      ApiService().timeoutGame(sessionId: sessionId!).catchError((_) => <String, dynamic>{});
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
      final nextIdx = _getNextPlayerIndex(state.currentPlayerIndex);
      state.currentPlayerIndex = nextIdx;
      state.currentDiceValue = null;
      state.selectedTokenId = null;
      state.consecutiveSixes = 0;

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
    bool isVsBot = false,
  }) {
    _turnTimer?.cancel();
    _isChangingTurn = false;
    _baseNoSixCount.clear();
    _baseNoSixThreshold.clear();
    List<LudoPlayer> players = [];

    switch (mode) {
      case GameMode.twoPlayer:
        if (isOnlineMatch) {
          players = [
            LudoPlayer(
              color: PlayerColor.red,
              name: mySeatIndex == 0 ? "You (Red)" : "Opponent (Red)",
              isBot: false,
            ),
            LudoPlayer(
              color: PlayerColor.green,
              name: mySeatIndex == 1 ? "You (Green)" : "Opponent (Green)",
              isBot: false,
            ),
          ];
        } else {
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
        }
        break;

      case GameMode.threePlayer:
        if (isOnlineMatch) {
          players = [
            LudoPlayer(
              color: PlayerColor.red,
              name: mySeatIndex == 0 ? "You (Red)" : "Player 1 (Red)",
              isBot: false,
            ),
            LudoPlayer(
              color: PlayerColor.green,
              name: mySeatIndex == 1 ? "You (Green)" : "Player 2 (Green)",
              isBot: false,
            ),
            LudoPlayer(
              color: PlayerColor.yellow,
              name: mySeatIndex == 2 ? "You (Yellow)" : "Player 3 (Yellow)",
              isBot: false,
            ),
          ];
        } else {
          players = [
            LudoPlayer(
              color: PlayerColor.red,
              name: customPlayerNames != null && customPlayerNames.isNotEmpty
                  ? customPlayerNames[0]
                  : "Player 1 (Red)",
              isBot: false,
            ),
            LudoPlayer(
              color: PlayerColor.green,
              name: customPlayerNames != null && customPlayerNames.length > 1
                  ? customPlayerNames[1]
                  : "Player 2 (Green)",
              isBot: false,
            ),
            LudoPlayer(
              color: PlayerColor.yellow,
              name: customPlayerNames != null && customPlayerNames.length > 2
                  ? customPlayerNames[2]
                  : "Player 3 (Yellow)",
              isBot: false,
            ),
          ];
        }
        break;

      case GameMode.fourPlayer:
        if (isOnlineMatch) {
          players = [
            LudoPlayer(
              color: PlayerColor.red,
              name: mySeatIndex == 0 ? "You (Red)" : "Player 1 (Red)",
              isBot: false,
            ),
            LudoPlayer(
              color: PlayerColor.green,
              name: mySeatIndex == 1 ? "You (Green)" : "Player 2 (Green)",
              isBot: false,
            ),
            LudoPlayer(
              color: PlayerColor.yellow,
              name: mySeatIndex == 2 ? "You (Yellow)" : "Player 3 (Yellow)",
              isBot: false,
            ),
            LudoPlayer(
              color: PlayerColor.blue,
              name: mySeatIndex == 3 ? "You (Blue)" : "Player 4 (Blue)",
              isBot: false,
            ),
          ];
        } else {
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
        }
        break;

      case GameMode.vsComputer:
        players = [
          LudoPlayer(
            color: PlayerColor.yellow,
            name: "You (Yellow)",
            isBot: false,
          ),
          LudoPlayer(
            color: PlayerColor.red,
            name: "Computer (Red)",
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

      case GameMode.teamUp:
        final bool isBotGame = isVsBot;
        players = [
          LudoPlayer(
            color: PlayerColor.red,
            name: (customPlayerNames != null && customPlayerNames.isNotEmpty && customPlayerNames[0].trim().isNotEmpty)
                ? customPlayerNames[0]
                : (isBotGame ? "You (Red)" : "Player 1 (Red)"),
            teamId: 'A',
            isBot: false,
          ),
          LudoPlayer(
            color: PlayerColor.green,
            name: (customPlayerNames != null && customPlayerNames.length > 1 && customPlayerNames[1].trim().isNotEmpty)
                ? customPlayerNames[1]
                : (isBotGame ? "Bot Opponent 1" : "Player 2 (Green)"),
            teamId: 'B',
            isBot: isBotGame,
          ),
          LudoPlayer(
            color: PlayerColor.yellow,
            name: (customPlayerNames != null && customPlayerNames.length > 2 && customPlayerNames[2].trim().isNotEmpty)
                ? customPlayerNames[2]
                : (isBotGame ? "Bot Partner" : "Player 3 (Yellow)"),
            teamId: 'A',
            isBot: isBotGame,
          ),
          LudoPlayer(
            color: PlayerColor.blue,
            name: (customPlayerNames != null && customPlayerNames.length > 3 && customPlayerNames[3].trim().isNotEmpty)
                ? customPlayerNames[3]
                : (isBotGame ? "Bot Opponent 2" : "Player 4 (Blue)"),
            teamId: 'B',
            isBot: isBotGame,
          ),
        ];
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
    activeCelebration = null;
    _safeNotifyListeners();

    if (isOnlineMatch) {
      state.statusMessage = "Connecting to match...";
      _startOnlineSync();
    } else if (state.currentPlayer.isBot) {
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
      if (roll == 6) {
        SoundHapticService.maybePlayWowSound(chance: 0.30, delayMs: 120);
      }
      _trackBaseNoSixAndTriggerMeme(state.currentPlayer, roll);
    }
  }

  /// Tracks when a player has all 4 gotis stuck inside base and still fails to roll a 6.
  /// After 7–8 dry rolls without opening, triggers one of the random funny meme sounds!
  void _trackBaseNoSixAndTriggerMeme(LudoPlayer player, int roll) {
    final allInBase = player.tokens.every((t) => t.isInBase);
    if (!allInBase || roll == 6) {
      _baseNoSixCount[player.color] = 0;
      _baseNoSixThreshold.remove(player.color);
      return;
    }

    final count = (_baseNoSixCount[player.color] ?? 0) + 1;
    final threshold =
        _baseNoSixThreshold.putIfAbsent(player.color, () => 7 + _random.nextInt(2));
    if (count >= threshold) {
      SoundHapticService.playRandomMemeSound(delayMs: 140);
      _baseNoSixCount[player.color] = 0;
      _baseNoSixThreshold[player.color] = 7 + _random.nextInt(2);
    } else {
      _baseNoSixCount[player.color] = count;
    }
  }

  /// Unified logical dice roll generation and phase transition for both Human and Computer
  int initiateDiceThrow({bool isHuman = true}) {
    if (isOnlineMatch) {
      _onlineRequestRoll();
      return state.currentDiceValue ?? 1;
    }
    if (state.phase != TurnPhase.waitingForRoll ||
        _isChangingTurn ||
        (isHuman && (state.currentPlayer.isBot || _isBotPlaying))) {
      return state.currentDiceValue ?? (_random.nextInt(6) + 1);
    }

    if (isOnlineMatch && !isMyTurn) {
      return state.currentDiceValue ?? 1;
    }

    final roll = _random.nextInt(6) + 1;
    playDiceThrowAnimation(roll: roll, isHuman: isHuman);
    if (sessionId != null && sessionId!.isNotEmpty) {
      ApiService().rollDice(sessionId: sessionId!).then((res) {
        if (res['success'] == true && res['data'] != null) {
          final serverVal = res['data']['diceValue'] as int?;
          if (serverVal != null && serverVal >= 1 && serverVal <= 6) {
            state.currentDiceValue = serverVal;
          }
        }
      }).catchError((_) {});
    }
    return roll;
  }

  /// Initiates physical dice throw from finger drag release or bot/tap
  void onPhysicalDiceThrowStart() {
    if (isOnlineMatch) {
      _onlineRequestRoll();
      return;
    }
    if (state.phase != TurnPhase.waitingForRoll ||
        _isChangingTurn ||
        state.currentPlayer.isBot ||
        _isBotPlaying) {
      return;
    }
    if (isOnlineMatch && !isMyTurn) {
      return;
    }
    initiateDiceThrow(isHuman: true);
  }

  /// Called when the physical dice finishes flight, bounces, and settles on the board
  Future<void> onPhysicalDiceThrowComplete(int roll) async {
    if (isOnlineMatch) {
      // the dice finished its flight: let the queued online event continue
      final c = _diceSettleCompleter;
      if (c != null && !c.isCompleted) c.complete();
      return;
    }
    if (_disposed || state.isGameOver) return;
    if (state.currentPlayer.isBot) return; // Bot turn is managed by playBotTurn()
    if (state.phase == TurnPhase.animatingMove ||
        state.phase == TurnPhase.waitingForPlayerHandoff ||
        state.phase == TurnPhase.gameOver ||
        _isChangingTurn ||
        _isProcessingDiceResult) {
      return;
    }
    state.phase = TurnPhase.throwingDice;

    _isProcessingDiceResult = true;
    _turnTimer?.cancel();

    try {
      final effectiveRoll = state.currentDiceValue ?? roll;
      state.currentDiceValue = effectiveRoll;
      lastSettledDiceValue = effectiveRoll;
      _trackBaseNoSixAndTriggerMeme(state.currentPlayer, effectiveRoll);

      // Check consecutive sixes
      if (effectiveRoll == 6) {
        state.consecutiveSixes++;
        if (state.consecutiveSixes == 3) {
          state.statusMessage = "3 consecutive Sixes! Turn passed.";
          state.consecutiveSixes = 0;
          state.phase = TurnPhase.animatingMove;
          _safeNotifyListeners();

          await Future.delayed(_stepDelay(900));
          if (_disposed) return;
          if (onDiceTravelRequested != null) {
            final nextIdx = _getNextPlayerIndex(state.currentPlayerIndex);
            await onDiceTravelRequested!(state.players[nextIdx].color);
          }
          _nextTurn();
          return;
        }
        SoundHapticService.maybePlayWowSound(chance: 0.34, delayMs: 120);
      } else {
        state.consecutiveSixes = 0;
      }

      // Check movable tokens
      List<Token> movable = state.currentPlayer.getMovableTokens(effectiveRoll);
      if (movable.isEmpty && state.mode == GameMode.teamUp && state.currentPlayer.hasFinished) {
        final teammate = state.currentTeammate;
        if (teammate != null && !teammate.hasFinished) {
          movable = teammate.getMovableTokens(effectiveRoll);
        }
      }

      if (movable.isEmpty) {
        state.statusMessage =
            "${state.currentPlayer.name} rolled $effectiveRoll. No moves possible!";
        state.phase = TurnPhase.animatingMove;
        _safeNotifyListeners();

        // Brief hold so player clearly sees the rolled number on board before flight
        await Future.delayed(const Duration(milliseconds: 750));
        if (_disposed) return;
        if (onDiceTravelRequested != null) {
          final nextIdx = _getNextPlayerIndex(state.currentPlayerIndex);
          await onDiceTravelRequested!(state.players[nextIdx].color);
        }
        _nextTurn();
        return;
      }

      final player = state.currentPlayer;

      // First Token Auto-Opening Rule:
      // When a human player has not opened their first-ever token yet and rolls 6:
      // Automatically open their first starting token from base without prompting for selection or waiting for tap!
      if (!player.isBot &&
          !player.hasOpenedFirstToken &&
          effectiveRoll == 6 &&
          movable.any((t) => t.isInBase)) {
        final tokenToOpen = movable.firstWhere((t) => t.isInBase);
        player.hasOpenedFirstToken = true;
        state.phase = TurnPhase.animatingMove;
        state.statusMessage =
            "${player.name} rolled 6! First goti automatically opened!";
        state.selectedTokenId = tokenToOpen.id;
        _safeNotifyListeners();

        await Future.delayed(_stepDelay(80));
        if (_disposed || state.isGameOver) return;
        await moveToken(tokenToOpen);
        return;
      }

      state.phase = TurnPhase.waitingForMove;
      state.statusMessage =
          "${state.currentPlayer.name} rolled $effectiveRoll! Tap a glowing goti to move.";
      _safeNotifyListeners();

      // Human turn: start move timer
      _startTurnTimer();

      // Smart Auto-Move Logic:
      // When roll is not 6 (1..5) and there is exactly 1 movable token (e.g. only 1 open goti),
      // auto-move it so the player doesn't have to tap unnecessarily.
      // If roll is 6, player gets to decide which goti to move (unlock goti vs advance open goti).
      if (effectiveRoll != 6 && movable.length == 1) {
        state.phase = TurnPhase.animatingMove;
        state.statusMessage =
            "${state.currentPlayer.name} rolled $effectiveRoll! Auto-moving goti...";
        state.selectedTokenId = movable.first.id;
        _safeNotifyListeners();

        await Future.delayed(_stepDelay(80));
        if (_disposed || state.isGameOver) return;
        await moveToken(movable.first);
      } else if (effectiveRoll == 6 && movable.length == 1) {
        // Single remaining movable token on roll of 6 (no decision needed)
        state.phase = TurnPhase.animatingMove;
        state.statusMessage =
            "${state.currentPlayer.name} rolled 6! Auto-moving goti...";
        state.selectedTokenId = movable.first.id;
        _safeNotifyListeners();

        await Future.delayed(_stepDelay(80));
        if (_disposed || state.isGameOver) return;
        await moveToken(movable.first);
      }
    } finally {
      _isProcessingDiceResult = false;
    }
  }

  /// Handles user tapping a token directly on the board
  Future<void> onTokenTapped(Token token) async {
    // 0. Online: taps only REQUEST a move; the server validates and both phones animate it
    if (isOnlineMatch) {
      await _onlineTokenTapped(token);
      return;
    }

    // 1. If currently animating, throwing dice, waiting for handoff, changing turn, bot playing, or game over, ignore taps (lock input)
    if (state.phase == TurnPhase.animatingMove ||
        state.phase == TurnPhase.throwingDice ||
        state.phase == TurnPhase.waitingForPlayerHandoff ||
        _isChangingTurn ||
        _isMovingToken ||
        _isProcessingDiceResult ||
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
      final isOwnToken = token.color == state.currentPlayer.color;
      final isTeammateToken = state.mode == GameMode.teamUp &&
          state.currentPlayer.hasFinished &&
          state.currentTeammate != null &&
          token.color == state.currentTeammate!.color;

      if (!isOwnToken && !isTeammateToken) return;
      if (state.currentPlayer.isBot) return;
      if (!token.canMove(state.currentDiceValue!)) return;

      await moveToken(token);
    }
  }

  /// Rolls the dice (triggers physical throw sequence)
  void rollDice() {
    if (isOnlineMatch) {
      _onlineRequestRoll();
      return;
    }
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
        _isChangingTurn ||
        _isMovingToken) {
      return const MoveResult();
    }
    _isMovingToken = true;
    try {
      final isOwnToken = token.color == state.currentPlayer.color;
      final isTeammateToken = state.mode == GameMode.teamUp &&
          state.currentPlayer.hasFinished &&
          state.currentTeammate != null &&
          token.color == state.currentTeammate!.color;

      if (!isOwnToken && !isTeammateToken) return const MoveResult();
      if (!token.canMove(state.currentDiceValue!)) return const MoveResult();

      final diceVal = state.currentDiceValue!;
      if (sessionId != null && sessionId!.isNotEmpty) {
        ApiService()
            .moveToken(sessionId: sessionId!, tokenId: token.id)
            .catchError((_) => <String, dynamic>{});
      }
      return await _executeStepByStepMovement(token, diceVal, autoAdvanceTurn: autoAdvanceTurn);
    } finally {
      _isMovingToken = false;
    }
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

    bool extraTurn = false;
    bool capturedOpponent = false;
    bool reachedHomeGoal = false;
    bool enteredHomeStretch = false;

    // 1. Immediate Step-by-step Hopping Movement (no pre-move jump delay)
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
          if (state.mode == GameMode.teamUp && p.isTeammateWith(state.currentPlayer)) continue;
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

              // In 1 KILL WIN mode: first capture claims instant victory!
              if (onlineModeType == OnlineModeType.oneKillWin) {
                if (!state.winners.contains(state.currentPlayer)) {
                  state.winners.add(state.currentPlayer);
                  state.currentPlayer.rank = 1;
                  state.phase = TurnPhase.gameOver;
                  state.statusMessage =
                      "VICTORY! ${state.currentPlayer.name} achieved 1-Kill Win!";
                  SoundHapticService.onVictory();
                  GameStorageService.saveGame(state);
                  _safeNotifyListeners();
                  return const MoveResult(
                    captured: true,
                    gameOver: true,
                  );
                }
              }
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

      int? finishRank;
      if (state.currentPlayer.hasFinished) {
        if (!state.winners.contains(state.currentPlayer)) {
          state.winners.add(state.currentPlayer);
          state.currentPlayer.rank = state.winners.length;
        }
        finishRank = state.currentPlayer.rank;
      }

      final celebration = PassedCelebrationData(
        token: token,
        player: state.currentPlayer,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        finishRank: finishRank,
      );
      activeCelebration = celebration;
      if (finishRank != null) {
        // Player completed ALL 4 gotis -> play 10-second Diwali fireworks celebration!
        SoundHapticService.onVictory();
        state.statusMessage =
            "👑 ${state.currentPlayer.name} finished #$finishRank! All 4 gotis Home!";
      } else {
        SoundHapticService.onHomeGoal();
        state.statusMessage =
            "🎉 Goti reached Home! Bonus roll for ${state.currentPlayer.name}!";
      }
      _safeNotifyListeners();

      await Future.delayed(_stepDelay(finishRank != null ? 1350 : 1000));
      if (_disposed) return const MoveResult();

      if (activeCelebration == celebration) {
        activeCelebration = null;
      }
      token.animStage = TokenAnimStage.idle;
      _safeNotifyListeners();

      // Check if match ended after this player finished
      if (state.currentPlayer.hasFinished) {
        if (state.mode == GameMode.teamUp) {
          final teamId = state.currentPlayer.teamId;
          final teamPlayers = state.players.where((p) => p.teamId == teamId).toList();
          final allTeamFinished = teamPlayers.isNotEmpty && teamPlayers.every((p) => p.hasFinished);
          if (allTeamFinished) {
            state.winningTeam = teamId;
            state.phase = TurnPhase.gameOver;
            state.statusMessage = "🏆 Team $teamId Victory! All 8 gotis reached Home!";
            GameStorageService.clearSavedGame();
            _safeNotifyListeners();
            return MoveResult(
              captured: capturedOpponent,
              reachedHome: reachedHomeGoal,
              extraTurn: false,
              gameOver: true,
            );
          }
        } else {
          final remaining = state.players.where((p) => !p.hasFinished).toList();
          if (remaining.length <= 1) {
            // Game Over!
            if (remaining.isNotEmpty && !state.winners.contains(remaining.first)) {
              state.winners.add(remaining.first);
              remaining.first.rank = state.winners.length;
            }
            state.phase = TurnPhase.gameOver;
            state.statusMessage = "🏆 Game Over! ${state.winners.first.name} Won!";
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
        // Goti movement complete + Extra turn (6 rolled / capture / home):
        // Dice flies back to SAME player's corner pod!
        if (onDiceTravelRequested != null) {
          await onDiceTravelRequested!(state.currentPlayer.color);
        }

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
        // Normal move (non-6): dice flies across to NEXT player's corner pod!
        final nextIdx = _getNextPlayerIndex(state.currentPlayerIndex);
        final nextColor = state.players[nextIdx].color;
        if (onDiceTravelRequested != null) {
          await onDiceTravelRequested!(nextColor);
        }
        _nextTurn();
      }
    }

    return moveResult;
  }

  int _getNextPlayerIndex(int fromIndex) {
    int nextIdx = (fromIndex + 1) % state.players.length;
    int safetyCount = 0;
    while ((state.players[nextIdx].hasFinished || state.players[nextIdx].isSurrendered) &&
        safetyCount < state.players.length) {
      if (state.mode == GameMode.teamUp) {
        final p = state.players[nextIdx];
        final teammate = state.players.firstWhere(
          (other) => other != p && other.isTeammateWith(p),
          orElse: () => p,
        );
        if (!teammate.hasFinished) {
          break;
        }
      }
      nextIdx = (nextIdx + 1) % state.players.length;
      safetyCount++;
    }
    return nextIdx;
  }

  void _nextTurn() {
    if (_disposed || state.isGameOver || _isChangingTurn) return;
    _isChangingTurn = true;
    _isBotPlaying = false;
    bool shouldTriggerBot = false;
    try {
      _turnTimer?.cancel();

      final nextIdx = _getNextPlayerIndex(state.currentPlayerIndex);

      state.currentPlayerIndex = nextIdx;
      state.currentDiceValue = null;
      state.selectedTokenId = null;
      state.consecutiveSixes = 0;

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
        lastSettledDiceValue = roll;
        debugPrint('[BOT] Dice animation started');
        await playDiceThrowAnimation(roll: roll, isHuman: false);
        if (_disposed || state.isGameOver || !state.currentPlayer.isBot) return;

        debugPrint('[BOT] Dice result = $roll');

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
            if (onDiceTravelRequested != null) {
              final nextIdx = _getNextPlayerIndex(state.currentPlayerIndex);
              await onDiceTravelRequested!(state.players[nextIdx].color);
            }
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

          await Future.delayed(_botDelay(800));
          if (_disposed || state.isGameOver) return;
          if (onDiceTravelRequested != null) {
            final nextIdx = _getNextPlayerIndex(state.currentPlayerIndex);
            await onDiceTravelRequested!(state.players[nextIdx].color);
          }
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
          if (onDiceTravelRequested != null) {
            await onDiceTravelRequested!(state.currentPlayer.color);
          }
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
          final nextIdx = _getNextPlayerIndex(state.currentPlayerIndex);
          final nextColor = state.players[nextIdx].color;
          if (onDiceTravelRequested != null) {
            await onDiceTravelRequested!(nextColor);
          }
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

  // ===========================================================================
  // ONLINE MULTIPLAYER (Socket.IO)
  //   * the server rolls the dice, validates every move and decides turns / timeouts
  //   * this phone only sends REQUESTS and then plays back what the server announces,
  //     so both screens always show the same dice, the same goti moves and the same result
  // ===========================================================================

  void _enqueueOnline(Future<void> Function() job) {
    // events are played strictly one after another (dice -> move -> turn), never overlapping
    _onlineQueue = _onlineQueue.then((_) async {
      if (_disposed) return;
      try {
        await job();
      } catch (e) {
        debugPrint('[ONLINE] event failed: $e');
      }
    });
  }

  bool _isThisSession(Map<String, dynamic> e) => e['sessionId']?.toString() == sessionId;

  int? _seatOfUser(String? userId) => userId == null ? null : _onlineSeatByUser[userId];

  void _startOnlineSync() {
    // If sessionId is missing but roomCode is available, fetch or start session
    if ((sessionId == null || sessionId!.isEmpty) && (roomCode != null && roomCode!.isNotEmpty)) {
      _resolveSessionFromRoomCode();
      return;
    }

    if (sessionId == null || sessionId!.isEmpty) return;
    _attachOnlineSync();
  }

  Future<void> _resolveSessionFromRoomCode() async {
    try {
      if (isHost) {
        final res = await ApiService().startGame(roomCode: roomCode!);
        if (res['success'] == true && res['data'] is Map) {
          final data = res['data'] as Map;
          final session = data['session'];
          sessionId = data['sessionId']?.toString() ??
              (session is Map ? (session['_id'] ?? session['id'])?.toString() : null);
        }
      }
      if (sessionId == null || sessionId!.isEmpty) {
        final roomRes = await ApiService().getRoomDetails(roomCode: roomCode!);
        if (roomRes['success'] == true && roomRes['data'] is Map) {
          final r = RoomModel.fromJson(roomRes['data']);
          sessionId = r.sessionId;
          if (r.seatIndex != null && r.seatIndex != mySeatIndex) {
            mySeatIndex = r.seatIndex!;
          }
        }
      }
    } catch (e) {
      debugPrint('[ONLINE] resolve session error: $e');
    }

    if (sessionId != null && sessionId!.isNotEmpty && !_disposed) {
      _attachOnlineSync();
    }
  }

  void _attachOnlineSync() {
    if (sessionId == null || sessionId!.isEmpty) return;
    onlineConnection = _socket.status;
    _safeNotifyListeners();

    _onlineSubs.add(_socket.statusStream.listen((s) {
      onlineConnection = s;
      _safeNotifyListeners();
      // every time we are back online ask the server for the truth (restores the board)
      if (s == LudoConnectionStatus.connected) onlineResync();
    }));

    _onlineSubs.add(_socket.on('game_state').listen((e) {
      final st = e['state'];
      if (st is Map && st['sessionId']?.toString() == sessionId) {
        final map = Map<String, dynamic>.from(st);
        _enqueueOnline(() async => _onlineApplyFullState(map, force: true));
      }
    }));
    _onlineSubs.add(_socket.on('dice_rolled').listen((e) {
      if (_isThisSession(e)) _enqueueOnline(() => _onlineHandleDice(e));
    }));
    _onlineSubs.add(_socket.on('token_moved').listen((e) {
      if (_isThisSession(e)) _enqueueOnline(() => _onlineHandleMove(e));
    }));
    _onlineSubs.add(_socket.on('turn_changed').listen((e) {
      if (!_isThisSession(e)) return;
      _enqueueOnline(() async {
        final v = (e['stateVersion'] as num?)?.toInt() ?? 0;
        if (v < _onlineVersion) return; // older than what we already show
        final turn = e['turn'];
        if (turn is Map) _onlineApplyTurn(Map<String, dynamic>.from(turn), reason: e['reason']?.toString());
      });
    }));
    _onlineSubs.add(_socket.on('turn_timeout').listen((e) {
      if (!_isThisSession(e)) return;
      final seat = _seatOfUser(e['userId']?.toString());
      if (seat != null && seat < state.players.length) {
        _lastTimeoutName = state.players[seat].name;
        state.statusMessage = "Time's up for $_lastTimeoutName!";
        _safeNotifyListeners();
      }
    }));
    _onlineSubs.add(_socket.on('player_surrendered').listen((e) {
      if (!_isThisSession(e)) return;
      final seat = _seatOfUser(e['userId']?.toString());
      if (seat != null && seat < state.players.length) {
        state.players[seat].isSurrendered = true;
        state.statusMessage = '${state.players[seat].name} left the match.';
        final st = e['state'];
        if (st is Map) {
          _onlineApplyFullState(Map<String, dynamic>.from(st));
        } else {
          _safeNotifyListeners();
        }
      }
    }));
    _onlineSubs.add(_socket.on('player_disconnected').listen((e) {
      if (e['channel'] != 'session' || e['id']?.toString() != sessionId) return;
      final seat = _seatOfUser(e['userId']?.toString());
      if (seat == null || seat >= state.players.length) return;
      offlineSeats.add(seat);
      state.statusMessage = '${state.players[seat].name} lost connection...';
      _safeNotifyListeners();
    }));
    _onlineSubs.add(_socket.on('player_reconnected').listen((e) {
      if (e['sessionId']?.toString() != sessionId) return;
      final seat = _seatOfUser(e['userId']?.toString());
      if (seat == null) return;
      offlineSeats.remove(seat);
      _safeNotifyListeners();
    }));
    _onlineSubs.add(_socket.on('match_finished').listen((e) {
      if (_isThisSession(e)) _enqueueOnline(() async => _onlineHandleFinished(e));
    }));

    // connect (if needed) and fetch the full state of this match
    _socket.ensureConnected().then((ok) {
      if (ok) {
        onlineResync();
      } else if (!_disposed) {
        state.statusMessage = 'Cannot reach the game server. Retrying...';
        _safeNotifyListeners();
      }
    });
  }

  /// Joins the match channel and restores the whole board from the server (first open,
  /// after a reconnect, after the app was in the background).
  Future<void> onlineResync() async {
    if (!isOnlineMatch || _disposed || sessionId == null || sessionId!.isEmpty) return;
    final ack = await _socket.joinSession(sessionId!);
    final st = ack.data['state'];
    if (ack.ok && st is Map) {
      final map = Map<String, dynamic>.from(st);
      _enqueueOnline(() async => _onlineApplyFullState(map, force: true));
    } else if (!ack.ok && ack.code != 'NOT_CONNECTED' && ack.code != 'TIMEOUT') {
      _onlineShowError(ack);
    }
  }

  void _onlineShowError(LudoAck ack) {
    final msg = ack.message;
    if (msg != null && msg.isNotEmpty) {
      state.statusMessage = msg;
      _safeNotifyListeners();
    }
  }

  // ---- my actions: request only ----

  Future<void> _onlineRequestRoll() async {
    if (_disposed || state.isGameOver || !isMyTurn) return;
    if (state.phase != TurnPhase.waitingForRoll || _onlineRollPending) return;

    final currentSid = sessionId;
    if (currentSid == null || currentSid.isEmpty) {
      debugPrint('[ONLINE] sessionId is null, resolving before roll...');
      if (roomCode != null && roomCode!.isNotEmpty) {
        await _resolveSessionFromRoomCode();
      }
      if (sessionId == null || sessionId!.isEmpty) {
        state.statusMessage = 'Connecting to match session...';
        _safeNotifyListeners();
        return;
      }
    }

    _onlineRollPending = true;
    final activeSid = sessionId!;

    try {
      SoundHapticService.playDiceRollSound();
    } catch (_) {}

    LudoAck ack = LudoAck.err('NOT_CONNECTED');
    if (_socket.isConnected) {
      ack = await _socket.rollDice(activeSid);
    }

    if (!ack.ok) {
      debugPrint('[ONLINE] Socket roll failed (${ack.code}), attempting REST ApiService.rollDice');
      try {
        final restRes = await ApiService().rollDice(sessionId: activeSid);
        if (restRes['success'] == true && restRes['data'] != null) {
          final data = Map<String, dynamic>.from(restRes['data'] as Map);
          final diceVal = (data['diceValue'] as num?)?.toInt() ??
              (data['dice'] as num?)?.toInt();
          if (diceVal != null && diceVal >= 1 && diceVal <= 6) {
            final myUserId = await AuthService.getUserUid();
            final syntheticEvent = <String, dynamic>{
              'sessionId': activeSid,
              'playerId': myUserId ?? data['playerId'] ?? data['userId'],
              'diceValue': diceVal,
              'movableTokenIds': data['movableTokenIds'] ?? data['movableTokens'] ?? <dynamic>[],
              'turnPassed': data['turnPassed'] == true,
              'threeSixes': data['threeSixes'] == true,
              'state': data['state'] ?? data['session'],
            };
            await _onlineHandleDice(syntheticEvent);
            return;
          }
        }
      } catch (e) {
        debugPrint('[ONLINE] REST roll fallback error: $e');
      }

      _onlineRollPending = false;
      _onlineShowError(ack);
      if (ack.code == 'FORBIDDEN' || ack.code == 'CONFLICT' || ack.code == 'BAD_REQUEST') {
        onlineResync();
      }
      return;
    }

    // the dice_rolled event drives the animation; watchdog in case it never arrives
    Future.delayed(const Duration(seconds: 4), () {
      if (_disposed || !_onlineRollPending) return;
      _onlineRollPending = false;
      onlineResync();
    });
  }

  Future<void> _onlineTokenTapped(Token token) async {
    if (_disposed || state.isGameOver || !isMyTurn) return;
    if (token.color != state.currentPlayer.color) return;

    if (state.phase == TurnPhase.waitingForRoll) {
      await _onlineRequestRoll(); // tapping your goti also throws the dice (same as offline)
      return;
    }
    if (state.phase != TurnPhase.waitingForMove || _onlineMovePending) return;
    if (!onlineMovableTokenIds.contains(token.id)) return;
    await _onlineSendMove(token.id);
  }

  Future<void> _onlineSendMove(int tokenId) async {
    if (_disposed || _onlineMovePending) return;
    _onlineMovePending = true;
    final activeSid = sessionId;
    if (activeSid == null || activeSid.isEmpty) {
      _onlineMovePending = false;
      return;
    }

    LudoAck ack = LudoAck.err('NOT_CONNECTED');
    if (_socket.isConnected) {
      ack = await _socket.moveToken(activeSid, tokenId);
    }

    if (!ack.ok) {
      debugPrint('[ONLINE] Socket move failed (${ack.code}), attempting REST ApiService.moveToken');
      try {
        final restRes = await ApiService().moveToken(sessionId: activeSid, tokenId: tokenId);
        if (restRes['success'] == true && restRes['data'] != null) {
          final data = Map<String, dynamic>.from(restRes['data'] as Map);
          final myUserId = await AuthService.getUserUid();
          final syntheticEvent = <String, dynamic>{
            'sessionId': activeSid,
            'playerId': myUserId ?? data['playerId'] ?? data['userId'],
            'move': data['move'] ?? {'tokenId': tokenId, 'prevStep': 0, 'newStep': 0},
            'state': data['state'] ?? data['session'],
          };
          await _onlineHandleMove(syntheticEvent);
          return;
        }
      } catch (e) {
        debugPrint('[ONLINE] REST move fallback error: $e');
      }

      _onlineMovePending = false;
      _onlineShowError(ack);
      if (ack.code == 'FORBIDDEN' || ack.code == 'CONFLICT' || ack.code == 'BAD_REQUEST') {
        onlineResync();
      }
      return;
    }

    Future.delayed(const Duration(seconds: 4), () {
      if (_disposed || !_onlineMovePending) return;
      _onlineMovePending = false;
      onlineResync();
    });
  }

  // ---- what the server announces: play it back ----

  Future<void> _onlineHandleDice(Map<String, dynamic> e) async {
    final seat = _seatOfUser(e['playerId']?.toString());
    if (seat == null || seat >= state.players.length) return;
    final dice = (e['diceValue'] as num).toInt();
    final movable = ((e['movableTokenIds'] as List?) ?? const []).map((x) => (x as num).toInt()).toList();
    final turnPassed = e['turnPassed'] == true;
    final threeSixes = e['threeSixes'] == true;
    final mine = seat == mySeatIndex;
    _onlineRollPending = false;

    state.currentPlayerIndex = seat;
    state.selectedTokenId = null;
    onlineMovableTokenIds = movable;

    // throw animation with the SERVER's number (identical on both phones)
    _diceSettleCompleter = Completer<void>();
    playDiceThrowAnimation(roll: dice, isHuman: true);
    await _diceSettleCompleter!.future.timeout(const Duration(seconds: 4), onTimeout: () {});
    _diceSettleCompleter = null;
    if (_disposed) return;

    final name = state.players[seat].name;
    if (turnPassed) {
      state.statusMessage = threeSixes ? '3 consecutive Sixes! Turn passed.' : '$name rolled $dice. No moves possible!';
      state.phase = TurnPhase.animatingMove;
      _safeNotifyListeners();
      await Future.delayed(_stepDelay(900));
      final st = e['state'];
      if (st is Map) _onlineApplyFullState(Map<String, dynamic>.from(st));
      return;
    }

    state.phase = TurnPhase.waitingForMove;
    state.statusMessage = mine ? 'You rolled $dice! Tap a glowing goti to move.' : '$name rolled $dice! Moving goti...';
    _safeNotifyListeners();

    // only one legal goti: move it automatically (same convenience as offline)
    if (mine && movable.length == 1) {
      await Future.delayed(_stepDelay(80));
      if (!_disposed && state.phase == TurnPhase.waitingForMove) {
        await _onlineSendMove(movable.first);
      }
    }
  }

  Future<void> _onlineHandleMove(Map<String, dynamic> e) async {
    _onlineMovePending = false;
    final seat = _seatOfUser(e['playerId']?.toString());
    final mv = e['move'];
    if (mv is Map && seat != null && seat < state.players.length) {
      final tokenId = (mv['tokenId'] as num).toInt();
      final prev = (mv['prevStep'] as num).toInt();
      final next = (mv['newStep'] as num).toInt();
      final player = state.players[seat];
      final token = player.tokens.firstWhere((t) => t.id == tokenId, orElse: () => player.tokens.first);

      state.currentPlayerIndex = seat;
      token.step = prev; // start exactly where the server says
      final dice = prev == -1 ? 6 : (next - prev);
      state.currentDiceValue = dice;
      onlineMovableTokenIds = const [];
      await _executeStepByStepMovement(token, dice, autoAdvanceTurn: false);
      if (_disposed) return;
    }
    // after the animation snap to the exact server positions (fixes any drift) and next turn
    final st = e['state'];
    if (st is Map) _onlineApplyFullState(Map<String, dynamic>.from(st));
  }

  Future<void> _onlineHandleFinished(Map<String, dynamic> e) async {
    final st = e['state'];
    if (st is Map) _onlineApplyPlayers(Map<String, dynamic>.from(st));
    onlineResult = e;

    final ordered = <LudoPlayer>[];
    final ranking = e['ranking'];
    if (ranking is List) {
      for (final r in ranking) {
        if (r is! Map) continue;
        final seat = _seatOfUser(r['userId']?.toString());
        if (seat == null || seat >= state.players.length) continue;
        final p = state.players[seat];
        p.rank = (r['rank'] as num?)?.toInt();
        ordered.add(p);
      }
    }
    if (ordered.isNotEmpty) state.winners = ordered;
    final winnerId = e['winnerId']?.toString();
    onlineWinnerSeat = (winnerId == null || winnerId.isEmpty) ? null : _seatOfUser(winnerId);

    _onlineCountdown?.cancel();
    _turnTimer?.cancel();
    state.currentDiceValue = null;
    onlineMovableTokenIds = const [];
    state.phase = TurnPhase.gameOver;
    if (onlineWinnerSeat != null && onlineWinnerSeat! < state.players.length) {
      state.statusMessage = '🏆 ${state.players[onlineWinnerSeat!].name} won the match!';
    } else {
      state.statusMessage = 'Match finished.';
    }
    _safeNotifyListeners();
  }

  // ---- applying server state ----

  /// Names, token positions, online flags (everything about the players).
  void _onlineApplyPlayers(Map<String, dynamic> st) {
    final players = st['players'];
    if (players is! List) return;
    _onlineSeatByUser.clear();
    offlineSeats.clear();
    for (final raw in players) {
      if (raw is! Map) continue;
      final p = Map<String, dynamic>.from(raw);
      final seat = (p['seatIndex'] as num?)?.toInt();
      if (seat == null || seat < 0 || seat >= state.players.length) continue;
      _onlineSeatByUser[p['userId'].toString()] = seat;

      final lp = state.players[seat];
      final serverName = (p['name'] ?? '').toString();
      if (serverName.isNotEmpty) lp.name = seat == mySeatIndex ? '$serverName (You)' : serverName;
      if (p['online'] == false) offlineSeats.add(seat);
      if (p['hasSurrendered'] == true || p['surrendered'] == true) {
        lp.isSurrendered = true;
      }

      final tokens = p['tokens'];
      if (tokens is List) {
        for (final t in tokens) {
          if (t is! Map) continue;
          final id = (t['tokenId'] as num).toInt();
          final step = (t['step'] as num).toInt();
          final token = lp.tokens.firstWhere((x) => x.id == id, orElse: () => lp.tokens.first);
          token.step = step;
          token.animStage = TokenAnimStage.idle;
          if (step >= 0) lp.hasEverOpenedToken = true;
        }
      }
    }

    AuthService.getUserUid().then((myUid) {
      if (_disposed || myUid == null) return;
      if (_onlineSeatByUser.containsKey(myUid)) {
        final realSeat = _onlineSeatByUser[myUid];
        if (realSeat != null && realSeat != mySeatIndex) {
          mySeatIndex = realSeat;
          for (int i = 0; i < state.players.length; i++) {
            final p = state.players[i];
            if (i == mySeatIndex) {
              if (!p.name.contains('(You)')) {
                p.name = '${p.name.replaceAll(RegExp(r'\s*\((?:Opponent|You)\)'), '')} (You)';
              }
            } else {
              if (p.name.contains('(You)')) {
                p.name = p.name.replaceAll(RegExp(r'\s*\(You\)'), ' (Opponent)');
              }
            }
          }
          _safeNotifyListeners();
        }
      }
    }).catchError((_) {});
  }

  void _onlineApplyFullState(Map<String, dynamic> st, {bool force = false}) {
    if (_disposed) return;
    final version = (st['stateVersion'] as num?)?.toInt() ?? 0;
    if (!force && version < _onlineVersion) return;
    _onlineVersion = version;

    _onlineApplyPlayers(st);
    _onlineRollPending = false;
    _onlineMovePending = false;

    if (st['status']?.toString() == 'completed' || st['gameCompleted'] == true) {
      _onlineHandleFinished({
        'sessionId': st['sessionId'],
        'winnerId': st['winnerId'],
        'state': st,
        'ranking': [
          for (final p in (st['players'] as List? ?? const []))
            if (p is Map) {'userId': p['userId'], 'rank': p['rank']},
        ]..sort((a, b) => ((a['rank'] as num?) ?? 99).compareTo((b['rank'] as num?) ?? 99)),
      });
      return;
    }

    final turn = st['turn'];
    if (turn is Map) {
      _onlineApplyTurn(Map<String, dynamic>.from(turn));
    } else {
      _safeNotifyListeners();
    }
  }

  void _onlineApplyTurn(Map<String, dynamic> turn, {String? reason}) {
    final seat = (turn['seatIndex'] as num?)?.toInt();
    if (seat == null || seat < 0 || seat >= state.players.length || state.isGameOver) return;

    final status = turn['status']?.toString();
    final dice = (turn['diceValue'] as num?)?.toInt();
    final movable = ((turn['movableTokenIds'] as List?) ?? const []).map((x) => (x as num).toInt()).toList();

    state.currentPlayerIndex = seat;
    state.consecutiveSixes = (turn['consecutiveSixes'] as num?)?.toInt() ?? 0;
    state.selectedTokenId = null;
    final name = state.players[seat].name;

    if (status == 'WAITING_FOR_MOVE' && dice != null) {
      state.phase = TurnPhase.waitingForMove;
      state.currentDiceValue = dice;
      onlineMovableTokenIds = movable;
      state.statusMessage = isMyTurn ? 'You rolled $dice! Tap a glowing goti to move.' : '$name rolled $dice! Moving goti...';
    } else {
      state.phase = TurnPhase.waitingForRoll;
      state.currentDiceValue = null;
      onlineMovableTokenIds = const [];
      if (reason == 'timeout' && _lastTimeoutName != null) {
        state.statusMessage = "Time's up for $_lastTimeoutName! ${isMyTurn ? 'Your turn!' : "$name's turn."}";
      } else if (reason == 'extra_turn') {
        state.statusMessage = isMyTurn ? 'Bonus turn! Throw the dice again.' : 'Bonus turn for $name...';
      } else {
        state.statusMessage = isMyTurn ? 'Your turn! Drag & flick dice to throw.' : 'Waiting for $name to roll...';
      }
      if (onDiceTravelRequested != null && state.players.length > seat) {
        onDiceTravelRequested!(state.players[seat].color);
      }
    }

    final remainingMs = (turn['remainingMs'] as num?)?.toInt();
    _startOnlineCountdown(remainingMs ?? maxTurnSeconds * 1000);
    _safeNotifyListeners();
  }

  /// Display-only countdown. The server enforces the real deadline and passes the turn itself.
  void _startOnlineCountdown(int remainingMs) {
    _onlineCountdown?.cancel();
    _onlineDeadline = DateTime.now().add(Duration(milliseconds: remainingMs));
    _syncOnlineCountdown();
    _onlineCountdown = Timer.periodic(const Duration(seconds: 1), (_) => _syncOnlineCountdown());
  }

  void _syncOnlineCountdown() {
    if (_disposed) return;
    if (state.isGameOver || _onlineDeadline == null) {
      _onlineCountdown?.cancel();
      return;
    }
    final ms = _onlineDeadline!.difference(DateTime.now()).inMilliseconds;
    final secs = (ms / 1000).ceil().clamp(0, maxTurnSeconds).toInt();
    if (secs != turnSecondsRemaining) {
      turnSecondsRemaining = secs;
      _safeNotifyListeners();
    }
  }

  void _disposeOnline() {
    for (final s in _onlineSubs) {
      s.cancel();
    }
    _onlineSubs.clear();
    _onlineCountdown?.cancel();
    final c = _diceSettleCompleter;
    if (c != null && !c.isCompleted) c.complete();
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

