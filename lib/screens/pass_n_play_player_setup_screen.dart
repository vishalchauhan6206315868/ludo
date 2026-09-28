import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/ludo_colors.dart';
import '../constants/ludo_path.dart';
import '../models/game_state.dart';
import 'game_screen.dart';

class PassNPlayPlayerSetupScreen extends StatefulWidget {
  final int playerCount;

  const PassNPlayPlayerSetupScreen({
    super.key,
    required this.playerCount,
  });

  @override
  State<PassNPlayPlayerSetupScreen> createState() =>
      _PassNPlayPlayerSetupScreenState();
}

class _PassNPlayPlayerSetupScreenState
    extends State<PassNPlayPlayerSetupScreen> {
  late final List<TextEditingController> _nameControllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _nameControllers = List.generate(
      widget.playerCount,
      (index) => TextEditingController(text: "Player ${index + 1}"),
    );
    _focusNodes = List.generate(
      widget.playerCount,
      (_) => FocusNode(),
    );
  }

  @override
  void dispose() {
    for (final c in _nameControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  PlayerColor _getPlayerColor(int index) {
    if (widget.playerCount == 2) {
      return index == 0 ? PlayerColor.red : PlayerColor.yellow;
    } else if (widget.playerCount == 3) {
      switch (index) {
        case 0:
          return PlayerColor.red;
        case 1:
          return PlayerColor.green;
        case 2:
          return PlayerColor.yellow;
        default:
          return PlayerColor.red;
      }
    } else {
      switch (index) {
        case 0:
          return PlayerColor.red;
        case 1:
          return PlayerColor.green;
        case 2:
          return PlayerColor.yellow;
        case 3:
          return PlayerColor.blue;
        default:
          return PlayerColor.red;
      }
    }
  }

  Color _getPrimaryColor(PlayerColor color) {
    switch (color) {
      case PlayerColor.red:
        return LudoColors.red;
      case PlayerColor.green:
        return LudoColors.green;
      case PlayerColor.yellow:
        return LudoColors.yellow;
      case PlayerColor.blue:
        return LudoColors.blue;
    }
  }

  Color _getLightColor(PlayerColor color) {
    switch (color) {
      case PlayerColor.red:
        return LudoColors.redLight;
      case PlayerColor.green:
        return LudoColors.greenLight;
      case PlayerColor.yellow:
        return LudoColors.yellowLight;
      case PlayerColor.blue:
        return LudoColors.blueLight;
    }
  }

  Color _getDarkColor(PlayerColor color) {
    switch (color) {
      case PlayerColor.red:
        return LudoColors.redDark;
      case PlayerColor.green:
        return LudoColors.greenDark;
      case PlayerColor.yellow:
        return LudoColors.yellowDark;
      case PlayerColor.blue:
        return LudoColors.blueDark;
    }
  }

  String _getColorName(PlayerColor color) {
    switch (color) {
      case PlayerColor.red:
        return "Red";
      case PlayerColor.green:
        return "Green";
      case PlayerColor.yellow:
        return "Yellow";
      case PlayerColor.blue:
        return "Blue";
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0C1833),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFFD700), width: 1.6),
        ),
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded,
                color: Color(0xFFFFD700), size: 24),
            SizedBox(width: 10),
            Text(
              "Player Configuration",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "• Customize each player's name before starting the game.",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            SizedBox(height: 8),
            Text(
              "• Colors and home bases are assigned according to official Ludo tournament rules.",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            SizedBox(height: 8),
            Text(
              "• In 2-player matches, players sit opposite (Red & Yellow) for balanced competition.",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            SizedBox(height: 8),
            Text(
              "• Tap START GAME when ready to roll the dice!",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "GOT IT",
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onStartGame() async {
    final names = <String>[];
    for (int i = 0; i < widget.playerCount; i++) {
      final text = _nameControllers[i].text.trim();
      names.add(text.isNotEmpty ? text : "Player ${i + 1}");
    }

    try {
      HapticFeedback.lightImpact();
    } catch (_) {}

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          mode: GameMode.passNPlay,
          passNPlayPlayerCount: widget.playerCount,
          customPlayerNames: names,
        ),
      ),
    );

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D1E),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF091738),
              Color(0xFF060E22),
              Color(0xFF030712),
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Header
              _buildHeader(context),

              // Main Content
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Step indicator & Title
                              _buildTitleSection(),

                              const SizedBox(height: 16),

                              // Dynamic Player Cards (Only selected count)
                              ...List.generate(widget.playerCount, (idx) {
                                return _buildPlayerConfigCard(idx);
                              }),

                              const SizedBox(height: 12),

                              // Info note
                              _buildInfoBanner(),

                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bottom Start Game Bar
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF091530).withValues(alpha: 0.85),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFFFD700).withValues(alpha: 0.2),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('player_setup_back_button'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF132244),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1.0,
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Header Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "PASS N PLAY",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  "STEP 2 OF 2 • ${widget.playerCount} PLAYERS",
                  style: const TextStyle(
                    color: Color(0xFF90A4AE),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),

          // Help Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('player_setup_help_button'),
              borderRadius: BorderRadius.circular(12),
              onTap: _showHelpDialog,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF132244),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                    width: 1.0,
                  ),
                ),
                child: const Icon(
                  Icons.help_outline_rounded,
                  color: Color(0xFFFFD700),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "PLAYER CONFIGURATION",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
            shadows: [
              Shadow(
                color: Color(0x66FFD700),
                offset: Offset(0, 2),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Review colors and customize names for all ${widget.playerCount} players",
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFB0BEC5),
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerConfigCard(int index) {
    final playerColor = _getPlayerColor(index);
    final primary = _getPrimaryColor(playerColor);
    final light = _getLightColor(playerColor);
    final dark = _getDarkColor(playerColor);
    final colorName = _getColorName(playerColor);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1C38),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: primary.withValues(alpha: 0.65),
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Player Number + Color Badge
            Row(
              children: [
                // Circular Player Number Avatar
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.3, -0.3),
                      radius: 0.85,
                      colors: [light, primary, dark],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      "${index + 1}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Player Title
                Expanded(
                  child: Text(
                    "PLAYER ${index + 1}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),

                // Color Pill Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: primary.withValues(alpha: 0.8),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primary,
                          boxShadow: [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.8),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        colorName.toUpperCase(),
                        style: TextStyle(
                          color: primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Token & Name Input Row
            Row(
              children: [
                // 3D Ludo Token Goti Preview
                _build3DGotiPreview(primary, light, dark),

                const SizedBox(width: 12),

                // Editable Name Text Field
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF091326),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primary.withValues(alpha: 0.35),
                        width: 1.0,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: TextField(
                      key: Key('player_name_input_$index'),
                      controller: _nameControllers[index],
                      focusNode: _focusNodes[index],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                        border: InputBorder.none,
                        hintText: "Player ${index + 1}",
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 28, maxHeight: 20),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(
                            Icons.edit_rounded,
                            color: primary,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _build3DGotiPreview(Color primary, Color light, Color dark) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF091326),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.0,
        ),
      ),
      child: Center(
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.35, -0.4),
              radius: 0.85,
              colors: [light, primary, dark],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.65),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.85),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F223D),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.phonelink_ring_rounded,
            color: Color(0xFFFFD700),
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Turns rotate on this phone with animated device handoff prompts!",
              style: TextStyle(
                color: Color(0xFFFFECB3),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF091428).withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFFFD700).withValues(alpha: 0.25),
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFE082),
                    Color(0xFFFFB300),
                    Color(0xFFFF8F00),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8F00).withValues(alpha: 0.5),
                    blurRadius: 16,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: const Key('start_game_button'),
                  borderRadius: BorderRadius.circular(16),
                  onTap: _onStartGame,
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          color: Color(0xFF10192D),
                          size: 28,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "START GAME",
                          style: TextStyle(
                            color: Color(0xFF10192D),
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
