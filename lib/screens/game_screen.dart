import 'package:flutter/material.dart';
import '../constants/ludo_colors.dart';
import '../logic/ludo_game_controller.dart';
import '../models/game_state.dart';
import '../widgets/board/ludo_board_widget.dart';
import '../widgets/player_card.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/victory_dialog.dart';

class GameScreen extends StatefulWidget {
  final GameMode mode;
  final GameState? restoredState;

  const GameScreen({
    super.key,
    required this.mode,
    this.restoredState,
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
    );
    _controller.addListener(_onGameStateChanged);
  }

  void _onGameStateChanged() {
    if (_controller.state.isGameOver && !_dialogShown) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
              Navigator.pop(context);
            },
          ),
        );
      });
    }
    setState(() {});
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
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LudoColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Exit to Main Menu?",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          "Your current match progress is saved automatically. You can resume anytime from the home screen.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Continue Playing",
                style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black87,
            ),
            child: const Text("Save & Exit"),
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
        backgroundColor: LudoColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: LudoColors.surfaceDark,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
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
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.6), width: 1.2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _getModeTitle(),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: "Settings",
              icon: const Icon(Icons.settings_rounded, color: Colors.white70),
              onPressed: () {
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
            IconButton(
              tooltip: "Rules",
              icon:
                  const Icon(Icons.help_outline_rounded, color: Colors.white70),
              onPressed: _showRulesDialog,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final availableHeight = constraints.maxHeight;

              // Calculate board size to fit gracefully on both mobile & desktop
              final maxBoardByHeight = availableHeight - 200;
              final maxBoardByWidth = availableWidth - 24;
              final boardSize = (maxBoardByHeight < maxBoardByWidth
                      ? maxBoardByHeight
                      : maxBoardByWidth)
                  .clamp(280.0, 520.0);

              return SingleChildScrollView(
                clipBehavior: Clip.none,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: availableHeight - 16),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // Layer 0: Board and Status Banner
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 62),
                          Center(
                            child: LudoBoardWidget(
                              controller: _controller,
                              size: boardSize,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildStatusBanner(state),
                          const SizedBox(height: 62),
                        ],
                      ),

                      // Layer 1: Top Player Cards (Painted ON TOP of the board so throwing dice floats over board)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: _buildTopPlayersBar(state, boardSize),
                      ),

                      // Layer 2: Bottom Player Cards (Painted ON TOP of the board so throwing dice floats over board)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: _buildBottomPlayersBar(state, boardSize),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(GameState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: LudoColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: state.currentPlayer.primaryColor.withValues(alpha: 0.5),
        ),
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

  Widget _buildTopPlayersBar(GameState state, [double boardSize = 360]) {
    final bSize = Size(boardSize, boardSize);
    if (state.mode == GameMode.fourPlayer) {
      // Show Red (idx 0) and Green (idx 1) at top
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          PlayerCard(
            player: state.players[0],
            isCurrentTurn: state.currentPlayerIndex == 0,
            controller: _controller,
            boardSize: bSize,
          ),
          PlayerCard(
            player: state.players[1],
            isCurrentTurn: state.currentPlayerIndex == 1,
            controller: _controller,
            boardSize: bSize,
          ),
        ],
      );
    } else {
      // 2 Players or vs Computer: Show player 2 at top
      return Center(
        child: PlayerCard(
          player: state.players[1],
          isCurrentTurn: state.currentPlayerIndex == 1,
          controller: _controller,
          boardSize: bSize,
        ),
      );
    }
  }

  Widget _buildBottomPlayersBar(GameState state, [double boardSize = 360]) {
    final bSize = Size(boardSize, boardSize);
    if (state.mode == GameMode.fourPlayer) {
      // Show Blue (idx 3) and Yellow (idx 2) at bottom
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          PlayerCard(
            player: state.players[3],
            isCurrentTurn: state.currentPlayerIndex == 3,
            controller: _controller,
            boardSize: bSize,
          ),
          PlayerCard(
            player: state.players[2],
            isCurrentTurn: state.currentPlayerIndex == 2,
            controller: _controller,
            boardSize: bSize,
          ),
        ],
      );
    } else {
      // 2 Players or vs Computer: Show player 1 at bottom
      return Center(
        child: PlayerCard(
          player: state.players[0],
          isCurrentTurn: state.currentPlayerIndex == 0,
          controller: _controller,
          boardSize: bSize,
        ),
      );
    }
  }

  String _getModeTitle() {
    switch (widget.mode) {
      case GameMode.twoPlayer:
        return "2 Players Match";
      case GameMode.fourPlayer:
        return "4 Players Classic";
      case GameMode.vsComputer:
        return "Vs Computer";
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
            Text("Ludo Rules",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
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
