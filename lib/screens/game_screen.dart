import 'package:flutter/material.dart';
import '../constants/ludo_colors.dart';
import '../logic/ludo_game_controller.dart';
import '../models/game_state.dart';
import '../widgets/board/ludo_board_widget.dart';
import '../widgets/pass_n_play_handoff_overlay.dart';
import '../widgets/player_card.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/victory_dialog.dart';

class GameScreen extends StatefulWidget {
  final GameMode mode;
  final GameState? restoredState;
  final int passNPlayPlayerCount;
  final List<String>? customPlayerNames;

  const GameScreen({
    super.key,
    required this.mode,
    this.restoredState,
    this.passNPlayPlayerCount = 2,
    this.customPlayerNames,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late LudoGameController _controller;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    _controller = LudoGameController(
      mode: widget.mode,
      initialState: widget.restoredState,
      passNPlayPlayerCount: widget.passNPlayPlayerCount,
      customPlayerNames: widget.customPlayerNames,
    );
    _controller.addListener(_onGameStateChanged);
  }

  void _onGameStateChanged() {
    if (!mounted) return;
    if (_controller.state.isGameOver && !_dialogShown) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => VictoryDialog(
            winners: _controller.state.winners,
            onPlayAgain: () {
              Navigator.pop(ctx);
              _dialogShown = false;
              _controller.restartGame();
            },
            onMainMenu: () {
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
  void dispose() {
    _controller.removeListener(_onGameStateChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (_controller.state.isGameOver) return true;

    _controller.pauseTimer();
    final bool isPassNPlay = _controller.state.mode == GameMode.passNPlay;

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LudoColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isPassNPlay ? "Exit Game?" : "Exit to Main Menu?",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          isPassNPlay
              ? "Are you sure you want to exit the current Pass N Play match? Your progress will be saved."
              : "Your current match progress is saved automatically. You can resume anytime from the home screen.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isPassNPlay ? "CANCEL" : "Continue Playing",
                style: const TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black87,
            ),
            child: Text(isPassNPlay ? "EXIT" : "Save & Exit"),
          ),
        ],
      ),
    );

    if (shouldLeave != true) {
      _controller.resumeTimer();
      return false;
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
      child: Scaffold(
        backgroundColor: const Color(0xFF060B19),
        appBar: AppBar(
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
            // 3. Main Gameplay Interactive Content
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  final availableHeight = constraints.maxHeight;

                  final isMultiTop = state.mode == GameMode.fourPlayer ||
                      state.mode == GameMode.threePlayer ||
                      (state.mode == GameMode.passNPlay && state.players.length >= 3);
                  final isMobileMultiTop = isMultiTop && availableWidth < 460;
                  final isCompact = isMobileMultiTop || availableWidth < 370;

                  // Calculate responsive dice size based on device screen & board scale:
                  // Mobile (< 600px width): 46.0 (or 38.0 for multi-player mobile)
                  // Tablet (600 - 1024px width): 56.0
                  // Web / Linux Desktop (> 1024px width): 66.0
                  final double diceSize;
                  if (availableWidth >= 1024) {
                    diceSize = 66.0;
                  } else if (availableWidth >= 600) {
                    diceSize = 56.0;
                  } else if (isMobileMultiTop) {
                    diceSize = 38.0;
                  } else {
                    diceSize = (availableWidth * 0.11).clamp(42.0, 46.0);
                  }
                  final cardVerticalOffset =
                      diceSize > 56.0 ? 76.0 : (isCompact ? 52.0 : 62.0);

                  // Calculate board size to fit gracefully on both mobile & desktop
                  final reservedHeight =
                      isCompact ? 144.0 : (diceSize > 56.0 ? 190.0 : 164.0);
                  final maxBoardByHeight = availableHeight - reservedHeight;
                  final maxBoardByWidth = availableWidth - 24;
                  final boardSize = (maxBoardByHeight < maxBoardByWidth
                          ? maxBoardByHeight
                          : maxBoardByWidth)
                      .clamp(availableHeight < 560 ? 240.0 : 270.0, 520.0);

                  return SingleChildScrollView(
                    clipBehavior: Clip.none,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: availableHeight - 16),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          // Layer 0: Board and Status Banner
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: cardVerticalOffset),
                              Center(
                                child: LudoBoardWidget(
                                  controller: _controller,
                                  size: boardSize,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildStatusBanner(state),
                              SizedBox(height: cardVerticalOffset),
                            ],
                          ),

                          // Layer 1: Top Player Cards
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: _buildTopPlayersBar(
                                state, boardSize, diceSize, isCompact),
                          ),

                          // Layer 2: Bottom Player Cards
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: _buildBottomPlayersBar(
                                state, boardSize, diceSize, isCompact),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // 4. Pass N Play Device Handoff Overlay
            if (state.mode == GameMode.passNPlay &&
                state.phase == TurnPhase.waitingForPlayerHandoff)
              PassNPlayHandoffOverlay(
                nextPlayer: state.currentPlayer,
                onReady: _controller.onPlayerReady,
              ),
          ],
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

  Widget _buildStatusBanner(GameState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF10192D).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.15),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: state.currentPlayer.primaryColor,
              boxShadow: [
                BoxShadow(
                  color:
                      state.currentPlayer.primaryColor.withValues(alpha: 0.8),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              state.statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPlayersBar(GameState state,
      [double boardSize = 360, double diceSize = 46, bool isCompact = false]) {
    final bSize = Size(boardSize, boardSize);
    if (state.mode == GameMode.fourPlayer ||
        state.mode == GameMode.threePlayer ||
        (state.mode == GameMode.passNPlay && state.players.length >= 3)) {
      // Show Red (idx 0) and Green (idx 1) at top
      return Row(
        children: [
          Expanded(
            child: PlayerCard(
              player: state.players[0],
              isCurrentTurn: state.currentPlayerIndex == 0,
              controller: _controller,
              boardSize: bSize,
              diceSize: diceSize,
              isCompact: isCompact,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: PlayerCard(
              player: state.players[1],
              isCurrentTurn: state.currentPlayerIndex == 1,
              controller: _controller,
              boardSize: bSize,
              diceSize: diceSize,
              isCompact: isCompact,
            ),
          ),
        ],
      );
    } else {
      // 2 Players, vs Computer, or 2P Pass N Play: Show player 2 at top
      return Center(
        child: PlayerCard(
          player: state.players[1],
          isCurrentTurn: state.currentPlayerIndex == 1,
          controller: _controller,
          boardSize: bSize,
          diceSize: diceSize,
          isCompact: isCompact,
        ),
      );
    }
  }

  Widget _buildBottomPlayersBar(GameState state,
      [double boardSize = 360, double diceSize = 46, bool isCompact = false]) {
    final bSize = Size(boardSize, boardSize);
    if (state.mode == GameMode.fourPlayer ||
        (state.mode == GameMode.passNPlay && state.players.length == 4)) {
      // Show Blue (idx 3) and Yellow (idx 2) at bottom
      return Row(
        children: [
          Expanded(
            child: PlayerCard(
              player: state.players[3],
              isCurrentTurn: state.currentPlayerIndex == 3,
              controller: _controller,
              boardSize: bSize,
              diceSize: diceSize,
              isCompact: isCompact,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: PlayerCard(
              player: state.players[2],
              isCurrentTurn: state.currentPlayerIndex == 2,
              controller: _controller,
              boardSize: bSize,
              diceSize: diceSize,
              isCompact: isCompact,
            ),
          ),
        ],
      );
    } else if (state.mode == GameMode.threePlayer ||
        (state.mode == GameMode.passNPlay && state.players.length == 3)) {
      // 3 Players: Show Yellow (idx 2) at bottom centered
      return Center(
        child: PlayerCard(
          player: state.players[2],
          isCurrentTurn: state.currentPlayerIndex == 2,
          controller: _controller,
          boardSize: bSize,
          diceSize: diceSize,
          isCompact: isCompact,
        ),
      );
    } else {
      // 2 Players, vs Computer, or 2P Pass N Play: Show player 1 at bottom
      return Center(
        child: PlayerCard(
          player: state.players[0],
          isCurrentTurn: state.currentPlayerIndex == 0,
          controller: _controller,
          boardSize: bSize,
          diceSize: diceSize,
          isCompact: isCompact,
        ),
      );
    }
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
