import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/ludo_colors.dart';
import '../constants/ludo_path.dart';
import '../core/network/api_service.dart';
import '../logic/ludo_game_controller.dart';
import '../services/ludo_socket_service.dart';
import '../services/sound_haptic_service.dart';
import '../models/game_state.dart';
import '../models/ludo_player.dart';
import '../models/online_game_mode.dart';
import '../widgets/board/ludo_board_widget.dart';
import '../widgets/dice/animated_dice.dart';
import '../widgets/player_card.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/victory_dialog.dart';
import '../widgets/game_exit_dialog.dart';

class GameScreen extends StatefulWidget {
  final GameMode mode;
  final GameState? restoredState;
  final int passNPlayPlayerCount;
  final List<String>? customPlayerNames;
  final String? sessionId;
  final String? roomCode;
  final bool isTeamUpVsBot;
  final bool isOnlineMatch;
  final bool isHost;
  final int mySeatIndex;
  final OnlineModeType? onlineModeType;

  const GameScreen({
    super.key,
    required this.mode,
    this.restoredState,
    this.passNPlayPlayerCount = 2,
    this.customPlayerNames,
    this.sessionId,
    this.roomCode,
    this.isTeamUpVsBot = false,
    this.isOnlineMatch = false,
    this.isHost = true,
    this.mySeatIndex = 0,
    this.onlineModeType,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late LudoGameController _controller;
  bool _dialogShown = false;
  bool _hasUpdatedLeaderboard = false;
  bool _connectingBannerDismissed = false;
  Timer? _connectingDismissTimer;

  // Dice board-settle & direct player-to-player flight state
  final GlobalKey _arenaStackKey = GlobalKey();
  final GlobalKey _boardKey = GlobalKey();
  final Map<PlayerColor, GlobalKey> _diceSlotKeys = {
    for (final c in PlayerColor.values) c: GlobalKey(),
  };
  late AnimationController _diceTravelController;
  bool _diceOnBoard = false;
  bool _isDiceTraveling = false;
  Offset? _restingDicePos;
  Offset? _travelStartPos;
  Offset? _travelEndPos;
  int _overlayDiceValue = 1;
  double _restingTiltX = 0.0;
  double _restingTiltY = 0.0;
  double _restingTiltZ = 0.0;
  double _currentDiceSize = 34.0;
  double _podDiceSize = 54.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _diceTravelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _diceTravelController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _isDiceTraveling = false;
          _diceOnBoard = false;
          _restingDicePos = null;
          _travelStartPos = null;
          _travelEndPos = null;
        });
      }
    });
    _controller = LudoGameController(
      mode: widget.mode,
      initialState: widget.restoredState,
      passNPlayPlayerCount: widget.passNPlayPlayerCount,
      customPlayerNames: widget.customPlayerNames,
      sessionId: widget.sessionId,
      roomCode: widget.roomCode,
      isTeamUpVsBot: widget.isTeamUpVsBot,
      isOnlineMatch: widget.isOnlineMatch || (widget.sessionId != null && widget.sessionId!.isNotEmpty),
      isHost: widget.isHost,
      mySeatIndex: widget.mySeatIndex,
      onlineModeType: widget.onlineModeType,
    );
    _controller.onDiceTravelRequested = _startDiceTravelTo;
    _controller.addListener(_onGameStateChanged);

    if (widget.isOnlineMatch || (widget.sessionId != null && widget.sessionId!.isNotEmpty)) {
      _connectingDismissTimer = Timer(const Duration(milliseconds: 3000), () {
        if (mounted) {
          setState(() {
            _connectingBannerDismissed = true;
          });
        }
      });
    }
  }

  Offset? _globalToArenaLocal(Offset globalPos) {
    final box =
        _arenaStackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.globalToLocal(globalPos);
  }

  Offset? _getDiceSlotCenter(PlayerColor color) {
    final key = _diceSlotKeys[color];
    final ctx = key?.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final globalCenter = box.localToGlobal(box.size.center(Offset.zero));
    return _globalToArenaLocal(globalCenter);
  }

  Future<void> _startDiceTravelTo(PlayerColor targetColor) async {
    if (!mounted) return;
    if (_restingDicePos == null) {
      _resetDiceOverlay();
      return;
    }
    final targetCenter = _getDiceSlotCenter(targetColor);
    if (targetCenter == null) {
      _resetDiceOverlay();
      return;
    }

    setState(() {
      _travelStartPos = _restingDicePos;
      _travelEndPos = targetCenter;
      _isDiceTraveling = true;
      _diceOnBoard = false;
    });

    try {
      await _diceTravelController.forward(from: 0.0);
    } catch (_) {}

    if (mounted) {
      SoundHapticService.onDiceResult();
      setState(() {
        _isDiceTraveling = false;
        _diceOnBoard = false;
        _restingDicePos = null;
        _travelStartPos = null;
        _travelEndPos = null;
      });
    }
  }

  void _onDiceBoardSettle(
    Offset globalCenter,
    int finalValue, [
    double tiltX = 0.0,
    double tiltY = 0.0,
    double tiltZ = 0.0,
  ]) {
    if (!mounted) return;
    final localPos = _globalToArenaLocal(globalCenter);
    if (localPos == null) return;
    setState(() {
      _restingDicePos = localPos;
      _overlayDiceValue = finalValue;
      _restingTiltX = tiltX;
      _restingTiltY = tiltY;
      _restingTiltZ = tiltZ;
      _diceOnBoard = true;
      _isDiceTraveling = false;
    });
  }

  void _resetDiceOverlay() {
    _diceTravelController.stop();
    _diceOnBoard = false;
    _isDiceTraveling = false;
    _restingDicePos = null;
    _travelStartPos = null;
    _travelEndPos = null;
    _restingTiltX = 0.0;
    _restingTiltY = 0.0;
    _restingTiltZ = 0.0;
  }

  TurnPhase? _lastRecordedPhase;

  void _onGameStateChanged() {
    if (!mounted) return;
    final state = _controller.state;

    // Only clear previous resting dice overlay when actively transitioning into a brand-new throw or game ends
    final bool isStartingNewThrow =
        _lastRecordedPhase != TurnPhase.throwingDice &&
            state.phase == TurnPhase.throwingDice;
    _lastRecordedPhase = state.phase;

    if (state.isGameOver || isStartingNewThrow) {
      _resetDiceOverlay();
    }

    if (state.isGameOver && !_dialogShown) {
      _dialogShown = true;
      // online matches are settled by the server itself (match_finished)
      if (!_controller.isOnlineMatch && widget.sessionId != null && widget.sessionId!.isNotEmpty) {
        ApiService().completeGame(sessionId: widget.sessionId!).catchError((_) => <String, dynamic>{});
      }

      // POST /api/leaderboard/update-result (only once per completed match)
      if (!_hasUpdatedLeaderboard) {
        _hasUpdatedLeaderboard = true;
        final bool isWin;
        if (_controller.isOnlineMatch) {
          // the server decides who won; I am the player on my own seat
          isWin = _controller.onlineWinnerSeat != null && _controller.onlineWinnerSeat == _controller.mySeatIndex;
        } else if (widget.mode == GameMode.teamUp) {
          isWin = _controller.state.winningTeam == 'A';
        } else {
          final winners = _controller.state.winners;
          if (winners.isNotEmpty) {
            final firstWinner = winners.first;
            if (widget.mode == GameMode.vsComputer) {
              isWin = !firstWinner.isBot;
            } else {
              final userPlayer = _controller.state.players.isNotEmpty ? _controller.state.players.first : null;
              isWin = firstWinner == userPlayer;
            }
          } else {
            isWin = false;
          }
        }

        ApiService().updateLeaderboardResult(
          result: isWin ? 'win' : 'loss',
        ).catchError((_) => <String, dynamic>{});
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => VictoryDialog(
            winners: _controller.state.winners,
            winningTeam: _controller.state.winningTeam,
            onPlayAgain: () {
              SoundHapticService.stopAllSounds();
              Navigator.pop(ctx);
              if (_controller.isOnlineMatch) {
                // an online match cannot be restarted locally: go back to the menu to start a new room
                if (mounted) Navigator.pop(context);
                return;
              }
              _dialogShown = false;
              _hasUpdatedLeaderboard = false;
              _resetDiceOverlay();
              _controller.restartGame();
            },
            onMainMenu: () {
              SoundHapticService.stopAllSounds();
              Navigator.pop(ctx);
              if (mounted) {
                Navigator.pop(context);
              }
            },
          ),
        );
      });
    }
    if (mounted) {
      setState(() {});
    }
  }

    @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _controller.pauseTimer();
    } else if (state == AppLifecycleState.resumed) {
      _controller.resumeTimer();
      if (_controller.isOnlineMatch) {
        // came back from the background: reconnect if needed and restore the exact board
        LudoSocketService.instance.ensureConnected().then((_) => _controller.onlineResync());
      }
    }
  }

  @override
  void dispose() {
    _connectingDismissTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _diceTravelController.dispose();
    _controller.removeListener(_onGameStateChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (_controller.state.isGameOver) return true;

    _controller.pauseTimer();
    final bool isPassNPlay = _controller.state.mode == GameMode.passNPlay;
    final bool isOnline = _controller.isOnlineMatch;

    final shouldLeave = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => GameExitDialog(
        title: isOnline
            ? "Leave Match?"
            : (isPassNPlay ? "Exit Game?" : "Exit to Main Menu?"),
        message: isOnline
            ? "If you leave now you forfeit this online match and your opponent wins."
            : isPassNPlay
                ? "Are you sure you want to exit the current Pass N Play match? Your progress will be saved."
                : "Your current match progress is saved automatically. You can resume anytime from the home screen.",
        highlightText: isOnline
            ? "forfeit this online match"
            : (isPassNPlay ? "Your progress will be saved" : "saved automatically"),
        cancelText: isOnline
            ? "Stay"
            : (isPassNPlay ? "CANCEL" : "Continue Playing"),
        confirmText: isOnline
            ? "Leave & Forfeit"
            : (isPassNPlay ? "EXIT" : "Save & Exit"),
        onCancel: () => Navigator.pop(ctx, false),
        onConfirm: () => Navigator.pop(ctx, true),
      ),
    );

    if (shouldLeave != true) {
      _controller.resumeTimer();
      return false;
    }

    if (widget.sessionId != null && widget.sessionId!.isNotEmpty) {
      ApiService().surrenderGame(sessionId: widget.sessionId!).catchError((_) => <String, dynamic>{});
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canExit = await _onWillPop();
        if (canExit && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: MediaQuery.withClampedTextScaling(
        minScaleFactor: 0.85,
        maxScaleFactor: 1.15,
        child: Scaffold(
          backgroundColor: const Color(0xFF060B19),
        appBar: AppBar(
          toolbarHeight: 46,
          backgroundColor: const Color(0xFF0C1428).withValues(alpha: 0.95),
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(
              color: const Color(0xFFFFD700).withValues(alpha: 0.25),
              height: 1.0,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFFFFD700)),
            onPressed: () async {
              final canExit = await _onWillPop();
              if (canExit && context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: const Color(0xFFFFD700),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "LUDO SUPREME",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: Color(0xFFFFD700),
                      ),
                    ),
                    Text(
                      _getModeTitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFB0BEC5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            _buildAppBarButton(
              icon: Icons.settings_rounded,
              tooltip: "Settings",
              onTap: () {
                _controller.pauseTimer();
                showDialog(
                  context: context,
                  builder: (ctx) => SettingsDialog(
                    onRestart: () {
                      _dialogShown = false;
                      _resetDiceOverlay();
                      _controller.restartGame();
                    },
                    onExitToMenu: () {
                      Navigator.pop(context);
                    },
                  ),
                ).then((_) {
                  _controller.resumeTimer();
                });
              },
            ),
            const SizedBox(width: 8),
            _buildAppBarButton(
              icon: Icons.help_outline_rounded,
              tooltip: "Rules",
              onTap: _showRulesDialog,
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: Stack(
          children: [
            // 1. Luxury Midnight Royal Wallpaper
            Positioned.fill(
              child: Image.asset(
                'assets/images/ludo_supreme_bg.jpg',
                fit: BoxFit.cover,
                cacheWidth: 1080,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF060B19),
                ),
              ),
            ),
            // 2. Dark Vignette Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xEA060B19),
                      Color(0xCC060B19),
                      Color(0xF0060B19),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // 3. Main Gameplay Interactive Content (Full-screen board within SafeArea)
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  final availableHeight = constraints.maxHeight;
                  final isLandscape = availableWidth > availableHeight + 220;

                  if (isLandscape) {
                    // Landscape (tablet / wide screen): full-height board inside SafeArea
                    // with bigger dice + colored person icon pods inset equally from all corners.
                    const landscapeMargin = 18.0;
                    final maxBoardByHeight =
                        (availableHeight - 8.0).clamp(180.0, double.infinity);
                    final sidePanelWidth =
                        ((availableWidth - maxBoardByHeight - (landscapeMargin * 2)) / 2)
                            .clamp(138.0, 192.0);
                    final maxBoardByWidth =
                        (availableWidth - (sidePanelWidth * 2) - (landscapeMargin * 2))
                            .clamp(180.0, double.infinity);
                    final boardSize = math.min(maxBoardByWidth, maxBoardByHeight);
                    final isSideCompact = sidePanelWidth < 162.0;
                    final podDiceSize = isSideCompact ? 48.0 : 54.0;
                    _podDiceSize = podDiceSize;
                    final landscapeCellSize = boardSize / 15.0;
                    final boardDiceSize = isSideCompact
                        ? (landscapeCellSize * 1.30).clamp(32.0, 42.0)
                        : (landscapeCellSize * 1.40).clamp(38.0, 52.0);
                    _currentDiceSize = boardDiceSize;

                    return SizedBox(
                      key: _arenaStackKey,
                      width: availableWidth,
                      height: availableHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          // Layer 0: Full-height Board (no status banner)
                          Positioned.fill(
                            child: Center(
                              child: LudoBoardWidget(
                                key: _boardKey,
                                controller: _controller,
                                size: boardSize,
                              ),
                            ),
                          ),

                          // Layer 1: Left-side Player Pods (Red top-left, Blue bottom-left)
                          Positioned(
                            top: landscapeMargin,
                            bottom: landscapeMargin,
                            left: landscapeMargin,
                            width: sidePanelWidth,
                            child: _buildLeftPlayersColumn(
                                state, boardSize, podDiceSize, boardDiceSize, isSideCompact),
                          ),

                          // Layer 2: Right-side Player Pods (Green top-right, Yellow bottom-right)
                          Positioned(
                            top: landscapeMargin,
                            bottom: landscapeMargin,
                            right: landscapeMargin,
                            width: sidePanelWidth,
                            child: _buildRightPlayersColumn(
                                state, boardSize, podDiceSize, boardDiceSize, isSideCompact),
                          ),

                          // Layer 3: Resting & Direct-Flight 3D Dice Overlay
                          _buildDiceOverlay(),
                        ],
                      ),
                    );
                  }

                  // Portrait (phones & portrait tablets): full-width board inside SafeArea
                  final isCompact = availableWidth < 360;
                  final cornerMargin = (availableWidth * 0.045).clamp(14.0, 32.0);

                  // Pod dice size: Big & prominent in player cards ("bada hi rkh")
                  final double podDiceSize = isCompact ? 48.0 : 54.0;
                  _podDiceSize = podDiceSize;

                  // Keep player pods prominent and large ("bada")
                  final double playerPodHeight = isCompact ? 56.0 : 64.0;
                  final barHeight = playerPodHeight + 8.0;

                  // Dynamically scale dice even more compact on board ("aur chhota"):
                  // Phones (<600): ~32-36px (leaving wide open breathing room in center 3x3)
                  // Tablets (600-1023): ~56-66px
                  // Large screens (>=1024): ~64-72px
                  final maxBoardByWidth =
                      (availableWidth - 4.0).clamp(180.0, double.infinity);
                  final estCellSize = maxBoardByWidth / 15.0;

                  double boardDiceSize;
                  if (availableWidth >= 1024) {
                    boardDiceSize = (estCellSize * 1.55).clamp(58.0, 68.0);
                  } else if (availableWidth >= 600) {
                    boardDiceSize = (estCellSize * 1.50).clamp(50.0, 60.0);
                  } else if (isCompact) {
                    boardDiceSize = (estCellSize * 1.10).clamp(24.0, 28.0);
                  } else {
                    boardDiceSize = (estCellSize * 1.15).clamp(27.0, 31.0);
                  }

                  final reservedHeight = (barHeight * 2) + (cornerMargin * 2) + 8.0;

                  final maxBoardByHeight =
                      (availableHeight - reservedHeight).clamp(180.0, double.infinity);
                  final boardSize = math.min(maxBoardByWidth, maxBoardByHeight);

                  // If height constrained, ensure dice scales down with actual board
                  if (boardSize < maxBoardByWidth) {
                    final actualCellSize = boardSize / 15.0;
                    boardDiceSize = (actualCellSize * 1.15).clamp(25.0, 68.0);
                  }
                  _currentDiceSize = boardDiceSize;

                  final barWidth = math
                      .max(boardSize, availableWidth - (cornerMargin * 2))
                      .clamp(180.0, double.infinity);

                  return SizedBox(
                    key: _arenaStackKey,
                    width: availableWidth,
                    height: availableHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        // Layer 0: Full-screen Board (no status banner)
                        Positioned.fill(
                          child: Column(
                            children: [
                              SizedBox(height: barHeight + cornerMargin + 4),
                              Expanded(
                                child: Center(
                                  child: LudoBoardWidget(
                                    key: _boardKey,
                                    controller: _controller,
                                    size: boardSize,
                                  ),
                                ),
                              ),
                              SizedBox(height: barHeight + cornerMargin + 4),
                            ],
                          ),
                        ),

                        // Layer 1: Top Player Pods (equal margin top/left/right)
                        Positioned(
                          top: cornerMargin,
                          left: cornerMargin,
                          right: cornerMargin,
                          child: _buildTopPlayersBar(
                              state, barWidth, podDiceSize, boardDiceSize, isCompact),
                        ),

                        // Layer 2: Bottom Player Pods (equal margin bottom/left/right)
                        Positioned(
                          bottom: cornerMargin,
                          left: cornerMargin,
                          right: cornerMargin,
                          child: _buildBottomPlayersBar(
                              state, barWidth, podDiceSize, boardDiceSize, isCompact),
                        ),

                        // Layer 3: Resting & Direct-Flight 3D Dice Overlay
                        _buildDiceOverlay(),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 4. Online only: connection status (the match is restored automatically on reconnect)
            if (_controller.isOnlineMatch &&
                _controller.onlineConnection != LudoConnectionStatus.connected &&
                !(_connectingBannerDismissed &&
                    _controller.onlineConnection == LudoConnectionStatus.connecting))
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: SafeArea(
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
                        decoration: BoxDecoration(
                          color: _controller.onlineConnection == LudoConnectionStatus.connecting
                              ? const Color(0xFF0C1833).withValues(alpha: 0.94)
                              : Colors.redAccent.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(20),
                          border: _controller.onlineConnection == LudoConnectionStatus.connecting
                              ? Border.all(color: const Color(0xFFFFD700), width: 1.2)
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_controller.onlineConnection != LudoConnectionStatus.unauthorized)
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _controller.onlineConnection == LudoConnectionStatus.connecting
                                        ? const Color(0xFFFFD700)
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Text(
                              _controller.onlineConnection == LudoConnectionStatus.unauthorized
                                  ? "Session expired. Please log in again."
                                  : _controller.onlineConnection == LudoConnectionStatus.connecting
                                      ? "Connecting to match server..."
                                      : "Connection lost. Reconnecting...",
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildAppBarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF16223B).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Icon(icon, color: const Color(0xFFECEFF1), size: 18),
        ),
      ),
    );
  }

  Widget _buildDiceOverlay() {
    if (!_diceOnBoard && !_isDiceTraveling) {
      return const SizedBox.shrink();
    }

    final state = _controller.state;
    final canTapRestingDice = _diceOnBoard &&
        state.phase == TurnPhase.waitingForRoll &&
        !state.currentPlayer.isBot &&
        !_controller.isBotPlaying &&
        _controller.isMyTurn;

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _diceTravelController,
        builder: (context, child) {
          Offset pos;
          double scale = 1.0;
          double extraRotX = 0.0;
          double extraRotY = 0.0;
          double extraRotZ = 0.0;
          double shadowBlur = 10.0;
          double spinEnergy = 0.0;
          double spinAngle = 0.0;

          if (_isDiceTraveling &&
              _travelStartPos != null &&
              _travelEndPos != null) {
            final rawT = _diceTravelController.value;
            final t = Curves.easeInOutCubic.transform(rawT);
            final linear = Offset.lerp(_travelStartPos!, _travelEndPos!, t)!;
            final arcLift = math.sin(rawT * math.pi) * 32.0;
            pos = Offset(linear.dx, linear.dy - arcLift);
            // Smoothly scale up from compact board dice to big player pod dice slot
            final targetScale = (_currentDiceSize > 0)
                ? (_podDiceSize / _currentDiceSize).clamp(1.0, 1.85)
                : 1.5;
            final flightScale = 1.0 + (targetScale - 1.0) * t;
            scale = flightScale + (math.sin(rawT * math.pi) * 0.12);
            // Gentle 3D glide tilt that returns cleanly to 0 upon landing
            extraRotX = math.sin(rawT * math.pi) * 0.45;
            extraRotY = math.sin(rawT * math.pi) * 0.35;
            extraRotZ = math.sin(rawT * math.pi) * 0.30;
            shadowBlur = 10.0 + (math.sin(rawT * math.pi) * 10.0);
            spinEnergy = math.sin(rawT * math.pi) * 0.65;
            spinAngle = rawT * math.pi * 2.5;
          } else if (_restingDicePos != null) {
            pos = _restingDicePos!;
            extraRotX = _restingTiltX;
            extraRotY = _restingTiltY;
            extraRotZ = _restingTiltZ;
          } else {
            return const SizedBox.shrink();
          }

          final half = _currentDiceSize / 2.0;
          final diceContent = DiceCube3DDisplay(
            value: _overlayDiceValue,
            size: _currentDiceSize,
            extraRotX: extraRotX,
            extraRotY: extraRotY,
            extraRotZ: extraRotZ,
            isGlow: _overlayDiceValue == 6 ||
                _isDiceTraveling ||
                canTapRestingDice,
            isSixBonus: _overlayDiceValue == 6,
            spinEnergy: spinEnergy,
            spinAngle: spinAngle,
            shadowBlur: shadowBlur,
          );

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: pos.dx - half,
                top: pos.dy - half,
                child: canTapRestingDice
                    ? MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _controller.onPhysicalDiceThrowStart,
                          child: Transform.scale(
                            scale: scale,
                            child: diceContent,
                          ),
                        ),
                      )
                    : IgnorePointer(
                        child: Transform.scale(
                          scale: scale,
                          child: diceContent,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlayerCard({
    required LudoPlayer player,
    required bool isCurrentTurn,
    required Size boardSize,
    required double diceSize,
    double? boardDiceSize,
    required bool isCompact,
    required bool isRightAligned,
  }) {
    return PlayerCard(
      player: player,
      isCurrentTurn: isCurrentTurn,
      controller: _controller,
      boardSize: boardSize,
      boardKey: _boardKey,
      diceSize: diceSize,
      boardDiceSize: boardDiceSize ?? _currentDiceSize,
      isCompact: isCompact,
      isRightAligned: isRightAligned,
      diceSlotKey: _diceSlotKeys[player.color],
      hideActiveDice: _diceOnBoard || _isDiceTraveling,
      handoffOnSettle: true,
      onBoardSettle: _onDiceBoardSettle,
    );
  }

  Widget? _buildPlayerCardForColor(
    GameState state,
    PlayerColor color, {
    required Size boardSize,
    required double diceSize,
    double? boardDiceSize,
    required bool isCompact,
    required bool isRightAligned,
  }) {
    final idx = state.players.indexWhere((p) => p.color == color);
    if (idx == -1) return null;
    return _buildPlayerCard(
      player: state.players[idx],
      isCurrentTurn: state.currentPlayerIndex == idx,
      boardSize: boardSize,
      diceSize: diceSize,
      boardDiceSize: boardDiceSize,
      isCompact: isCompact,
      isRightAligned: isRightAligned,
    );
  }

  Widget _buildLeftPlayersColumn(GameState state,
      [double boardSize = 360,
      double diceSize = 54,
      double? boardDiceSize,
      bool isCompact = false]) {
    final bSize = Size(boardSize, boardSize);
    final topCard = _buildPlayerCardForColor(
      state,
      PlayerColor.red,
      boardSize: bSize,
      diceSize: diceSize,
      boardDiceSize: boardDiceSize,
      isCompact: isCompact,
      isRightAligned: false,
    );
    final bottomCard = _buildPlayerCardForColor(
      state,
      PlayerColor.blue,
      boardSize: bSize,
      diceSize: diceSize,
      boardDiceSize: boardDiceSize,
      isCompact: isCompact,
      isRightAligned: false,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        topCard ?? const SizedBox.shrink(),
        bottomCard ?? const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildRightPlayersColumn(GameState state,
      [double boardSize = 360,
      double diceSize = 54,
      double? boardDiceSize,
      bool isCompact = false]) {
    final bSize = Size(boardSize, boardSize);
    final topCard = _buildPlayerCardForColor(
      state,
      PlayerColor.green,
      boardSize: bSize,
      diceSize: diceSize,
      boardDiceSize: boardDiceSize,
      isCompact: isCompact,
      isRightAligned: true,
    );
    final bottomCard = _buildPlayerCardForColor(
      state,
      PlayerColor.yellow,
      boardSize: bSize,
      diceSize: diceSize,
      boardDiceSize: boardDiceSize,
      isCompact: isCompact,
      isRightAligned: true,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        topCard ?? const SizedBox.shrink(),
        bottomCard ?? const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildTopPlayersBar(GameState state,
      [double boardSize = 360,
      double diceSize = 54,
      double? boardDiceSize,
      bool isCompact = false]) {
    final bSize = Size(boardSize, boardSize);
    final redCard = _buildPlayerCardForColor(
      state,
      PlayerColor.red,
      boardSize: bSize,
      diceSize: diceSize,
      boardDiceSize: boardDiceSize,
      isCompact: isCompact,
      isRightAligned: false,
    );
    final greenCard = _buildPlayerCardForColor(
      state,
      PlayerColor.green,
      boardSize: bSize,
      diceSize: diceSize,
      boardDiceSize: boardDiceSize,
      isCompact: isCompact,
      isRightAligned: true,
    );

    if (redCard == null && greenCard == null) {
      return const SizedBox.shrink();
    }

    return Center(
      child: SizedBox(
        width: boardSize,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (redCard != null)
              Flexible(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: redCard,
                ),
              )
            else
              const SizedBox.shrink(),
            const SizedBox(width: 4),
            if (greenCard != null)
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: greenCard,
                ),
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPlayersBar(GameState state,
      [double boardSize = 360,
      double diceSize = 54,
      double? boardDiceSize,
      bool isCompact = false]) {
    final bSize = Size(boardSize, boardSize);
    final blueCard = _buildPlayerCardForColor(
      state,
      PlayerColor.blue,
      boardSize: bSize,
      diceSize: diceSize,
      boardDiceSize: boardDiceSize,
      isCompact: isCompact,
      isRightAligned: false,
    );
    final yellowCard = _buildPlayerCardForColor(
      state,
      PlayerColor.yellow,
      boardSize: bSize,
      diceSize: diceSize,
      boardDiceSize: boardDiceSize,
      isCompact: isCompact,
      isRightAligned: true,
    );

    if (blueCard == null && yellowCard == null) {
      return const SizedBox.shrink();
    }

    return Center(
      child: SizedBox(
        width: boardSize,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (blueCard != null)
              Flexible(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: blueCard,
                ),
              )
            else
              const SizedBox.shrink(),
            const SizedBox(width: 4),
            if (yellowCard != null)
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: yellowCard,
                ),
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  String _getModeTitle() {
    switch (widget.mode) {
      case GameMode.twoPlayer:
        return "2 Players Match";
      case GameMode.threePlayer:
        return "3 Players Match";
      case GameMode.fourPlayer:
        return "4 Players Classic";
      case GameMode.vsComputer:
        return "Vs Computer";
      case GameMode.passNPlay:
        return "Pass & Play (${_controller.state.players.length} Players)";
      case GameMode.teamUp:
        return "Team Up (2 vs 2)";
    }
  }

  void _showRulesDialog() {
    _controller.pauseTimer();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LudoColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.menu_book_rounded, color: Colors.amber),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                "Ludo Rules",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _RuleItem(
                title: "1. Throw the Dice",
                desc:
                    "Touch and drag the 3D dice, shake it in your hand, and swipe/flick it towards the board to throw!",
              ),
              _RuleItem(
                title: "2. Release from Base",
                desc:
                    "Roll a 6 to bring a goti out of the base onto the board.",
              ),
              _RuleItem(
                title: "3. Extra Rolls",
                desc:
                    "Rolling a 6, capturing an opponent, or reaching home grants an extra roll.",
              ),
              _RuleItem(
                title: "4. Safe Zones",
                desc: "Tokens on colored Star cells cannot be captured.",
              ),
              _RuleItem(
                title: "5. Capturing",
                desc:
                    "Landing on an opponent's token sends it back to their base with an impact effect.",
              ),
              _RuleItem(
                title: "6. Winning",
                desc:
                    "The first player to move all 4 tokens into the center goal wins!",
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Got it!", style: TextStyle(color: Colors.amber)),
          )
        ],
      ),
    ).then((_) {
      _controller.resumeTimer();
    });
  }
}

class _RuleItem extends StatelessWidget {
  final String title;
  final String desc;

  const _RuleItem({required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
