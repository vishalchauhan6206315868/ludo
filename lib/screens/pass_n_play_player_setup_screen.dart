import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/ludo_path.dart';
import '../models/game_state.dart';
import 'game_screen.dart';

/// Pass N Play: Step 2 of 2 - Player Configuration Screen.
/// Redesigned with 3D Royal Gaming UI matching reference aesthetics:
/// - Royal cosmic background with light rays & floating 3D dice.
/// - 3D Jeweled crown atop "PASS N PLAY" banner with laurel badges.
/// - Laurel-flanked "PLAYER CONFIGURATION" title banner.
/// - 3D Crowned & Laureled player number medallions.
/// - Rich color-coded velvet cards with subtle crown watermark.
/// - Color indicator pills with dropdown arrow.
/// - Dark glossy capsule input fields with color-matched edit icons.
/// - Device handoff animated prompt banner with vibrating smartphone.
/// - 3D Golden "▶ START GAME" button flanked by exterior pawns & dice.
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
        return const Color(0xFFE53935);
      case PlayerColor.green:
        return const Color(0xFF43A047);
      case PlayerColor.yellow:
        return const Color(0xFFFDD835);
      case PlayerColor.blue:
        return const Color(0xFF1E88E5);
    }
  }

  Color _getLightColor(PlayerColor color) {
    switch (color) {
      case PlayerColor.red:
        return const Color(0xFFFF8A80);
      case PlayerColor.green:
        return const Color(0xFFB9F6CA);
      case PlayerColor.yellow:
        return const Color(0xFFFFF9C4);
      case PlayerColor.blue:
        return const Color(0xFF80D8FF);
    }
  }

  Color _getDarkColor(PlayerColor color) {
    switch (color) {
      case PlayerColor.red:
        return const Color(0xFF880E4F);
      case PlayerColor.green:
        return const Color(0xFF1B5E20);
      case PlayerColor.yellow:
        return const Color(0xFFE65100);
      case PlayerColor.blue:
        return const Color(0xFF0D47A1);
    }
  }

  String _getColorName(PlayerColor color) {
    switch (color) {
      case PlayerColor.red:
        return "RED";
      case PlayerColor.green:
        return "GREEN";
      case PlayerColor.yellow:
        return "YELLOW";
      case PlayerColor.blue:
        return "BLUE";
    }
  }

  List<Color> _getCardGradient(PlayerColor color) {
    switch (color) {
      case PlayerColor.red:
        return const [
          Color(0xFF8B0018),
          Color(0xFF5E0010),
          Color(0xFF2E0008),
        ];
      case PlayerColor.yellow:
        return const [
          Color(0xFF8D5500),
          Color(0xFF5C3300),
          Color(0xFF2D1700),
        ];
      case PlayerColor.green:
        return const [
          Color(0xFF005A18),
          Color(0xFF00380E),
          Color(0xFF001D07),
        ];
      case PlayerColor.blue:
        return const [
          Color(0xFF003E8A),
          Color(0xFF002454),
          Color(0xFF00122E),
        ];
    }
  }

  Color _getGlowColor(PlayerColor color) {
    switch (color) {
      case PlayerColor.red:
        return const Color(0xFFFF1744);
      case PlayerColor.yellow:
        return const Color(0xFFFFB300);
      case PlayerColor.green:
        return const Color(0xFF00E676);
      case PlayerColor.blue:
        return const Color(0xFF00B0FF);
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
      backgroundColor: const Color(0xFF040A18),
      body: Stack(
        children: [
          // 1. Cosmic Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.65),
                  radius: 1.25,
                  colors: [
                    Color(0xFF0C2464),
                    Color(0xFF081745),
                    Color(0xFF040C25),
                    Color(0xFF020612),
                  ],
                  stops: [0.0, 0.35, 0.70, 1.0],
                ),
              ),
            ),
          ),

          // 2. Ambient Floating 3D Dice (Top-Left & Mid-Right)
          const Positioned(
            top: 60,
            left: 12,
            child: CustomPaint(
              size: Size(30, 30),
              painter: _RoyalDicePainter(angle: -0.25),
            ),
          ),
          const Positioned(
            top: 145,
            right: 12,
            child: CustomPaint(
              size: Size(32, 32),
              painter: _RoyalDicePainter(angle: 0.30),
            ),
          ),

          // 3. Screen Content
          SafeArea(
            child: Column(
              children: [
                // Top Header (Back Button, Jeweled Crown, Title, Help Button)
                _buildHeader(context),

                // Main Scrollable Area
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 4),

                                // "PLAYER CONFIGURATION" Title Banner
                                _buildTitleSection(),

                                const SizedBox(height: 12),

                                // Dynamic Player Configuration Cards
                                ...List.generate(widget.playerCount, (idx) {
                                  return _buildPlayerConfigCard(idx);
                                }),

                                const SizedBox(height: 6),

                                // Device Handoff Notice Banner
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

                // Bottom Action Bar: START GAME Button with exterior pawns & dice
                _buildBottomBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Top Header with 3D Jeweled Crown over "PASS N PLAY" Banner
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          // 3D Circular Back Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('player_setup_back_button'),
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: const Color(0xFFFFD700),
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D47A1).withValues(alpha: 0.6),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Center Crown + "PASS N PLAY" Banner
          Expanded(
            child: Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                // Main Capsule Banner with Laurel framing
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFFFD54F),
                      width: 2.2,
                    ),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1E88E5),
                        Color(0xFF0D47A1),
                        Color(0xFF052163),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E88E5).withValues(alpha: 0.6),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.military_tech_rounded,
                                color: Color(0xFFFFD54F), size: 18),
                            SizedBox(width: 6),
                            Text(
                              "PASS N PLAY",
                              maxLines: 1,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.4,
                                shadows: [
                                  Shadow(
                                    color: Color(0xFFFFD54F),
                                    blurRadius: 6,
                                  ),
                                  Shadow(
                                    color: Colors.black,
                                    blurRadius: 4,
                                    offset: Offset(0, 1.5),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.military_tech_rounded,
                                color: Color(0xFFFFD54F), size: 18),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "STEP 2 OF 2 • ${widget.playerCount} PLAYERS",
                          style: const TextStyle(
                            color: Color(0xFFFFE082),
                            fontSize: 9.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                // 3D Jeweled Golden Crown on top
                const Positioned(
                  top: -6,
                  child: CustomPaint(
                    size: Size(44, 26),
                    painter: _RoyalCrownPainter(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // 3D Circular Help Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('player_setup_help_button'),
              borderRadius: BorderRadius.circular(20),
              onTap: _showHelpDialog,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: const Color(0xFFFFD700),
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D47A1).withValues(alpha: 0.6),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
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

  /// Laurel-Framed "PLAYER CONFIGURATION" Title Banner
  Widget _buildTitleSection() {
    return Column(
      children: [
        // Capsule Banner with Golden Laurels
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF6A1B9A),
                Color(0xFF4A148C),
                Color(0xFF1A0038),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(
              color: const Color(0xFFFFD54F),
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFAB47BC).withValues(alpha: 0.5),
                blurRadius: 10,
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.military_tech_rounded,
                    color: Color(0xFFFFD54F), size: 18),
                SizedBox(width: 6),
                Text(
                  "PLAYER CONFIGURATION",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: Color(0xFFFFD54F),
                        blurRadius: 8,
                      ),
                      Shadow(
                        color: Colors.black,
                        blurRadius: 4,
                        offset: Offset(0, 1.5),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.military_tech_rounded,
                    color: Color(0xFFFFD54F), size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 5),

        // Subtitle: "Review colors and customize names for all X players"
        FittedBox(
          fit: BoxFit.scaleDown,
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
              children: [
                const TextSpan(text: "Review colors and customize "),
                const TextSpan(
                  text: "names",
                  style: TextStyle(
                    color: Color(0xFFFFD54F),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: " for all ${widget.playerCount} players",
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 3D Player Card with Crowned Medallion, Color Pill & Name Input Field
  Widget _buildPlayerConfigCard(int index) {
    final playerColor = _getPlayerColor(index);
    final primary = _getPrimaryColor(playerColor);
    final light = _getLightColor(playerColor);
    final dark = _getDarkColor(playerColor);
    final colorName = _getColorName(playerColor);
    final cardGradient = _getCardGradient(playerColor);
    final glowColor = _getGlowColor(playerColor);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        // Metallic Gold & Color Outer Border
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFFDE7),
            const Color(0xFFFFD54F),
            glowColor,
            const Color(0xFFFF8F00),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.45),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2.2),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1.0,
          ),
          gradient: LinearGradient(
            colors: cardGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Stack(
            children: [
              // Specular Top Gloss Highlight
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 38,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.22),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // Watermark Crown on the Right
              Positioned(
                right: 8,
                bottom: 8,
                child: Opacity(
                  opacity: 0.14,
                  child: Icon(
                    Icons.military_tech_rounded,
                    size: 56,
                    color: primary,
                  ),
                ),
              ),

              // Card Content Padding
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left: 3D Crowned & Laureled Number Medallion
                    CustomPaint(
                      size: const Size(60, 68),
                      painter: _CrownedNumberMedallionPainter(
                        number: index + 1,
                        primaryColor: primary,
                        lightColor: light,
                        darkColor: dark,
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Middle: Header (Title + Color Pill) and Name Input
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header: Player Title + Dropdown Color Pill
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Text(
                                  "PLAYER ${index + 1}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black87,
                                        blurRadius: 4,
                                        offset: Offset(0, 1.5),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Color Indicator Pill with Dropdown Arrow
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: primary,
                                      width: 1.4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primary.withValues(alpha: 0.4),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 9,
                                        height: 9,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: primary,
                                          boxShadow: [
                                            BoxShadow(
                                              color: primary,
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        colorName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Icon(
                                        Icons.arrow_drop_down_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Dark Glossy Capsule Input Box
                          Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF060F22)
                                  .withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF40C4FF)
                                    .withValues(alpha: 0.5),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_rounded,
                                  color: primary,
                                  size: 17,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    key: Key('player_name_input_$index'),
                                    controller: _nameControllers[index],
                                    focusNode: _focusNodes[index],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      border: InputBorder.none,
                                      hintText: "Player ${index + 1}",
                                      hintStyle: const TextStyle(
                                        color: Colors.white38,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Device Handoff Notice Banner
  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF091E48),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00B0FF),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0091EA).withValues(alpha: 0.45),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          // 3D Vibrating Phone Icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF021028),
              border: Border.all(
                color: const Color(0xFFFFD54F),
                width: 1.2,
              ),
            ),
            child: const Icon(
              Icons.phone_android_rounded,
              color: Color(0xFFFFD54F),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),

          // Message with yellow highlight
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.0,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
                children: [
                  TextSpan(text: "Turns rotate on this phone with "),
                  TextSpan(
                    text: "animated device handoff",
                    style: TextStyle(
                      color: Color(0xFFFFD54F),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(text: " prompts!"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom Pinned Action Bar: "▶ START GAME" Button with exterior pawns & dice
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF050E22).withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFFFD700).withValues(alpha: 0.35),
            width: 1.4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Bottom Exterior Elements: Pawns & Dice on sides
              const Positioned(
                bottom: -2,
                left: -8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomPaint(
                      size: Size(22, 30),
                      painter: _RoyalPawnPainter(color: Color(0xFFE53935)),
                    ),
                    SizedBox(width: 4),
                    CustomPaint(
                      size: Size(22, 22),
                      painter: _RoyalDicePainter(angle: 0.2),
                    ),
                  ],
                ),
              ),
              const Positioned(
                bottom: -2,
                right: -8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomPaint(
                      size: Size(22, 22),
                      painter: _RoyalDicePainter(angle: -0.3),
                    ),
                    SizedBox(width: 4),
                    CustomPaint(
                      size: Size(22, 30),
                      painter: _RoyalPawnPainter(color: Color(0xFF43A047)),
                    ),
                  ],
                ),
              ),

              // Main Golden "▶ START GAME" Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: GestureDetector(
                    key: const Key('start_game_button'),
                    onTap: _onStartGame,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: const Color(0xFFFFFDE7),
                          width: 1.6,
                        ),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFEA00),
                            Color(0xFFFFB300),
                            Color(0xFFFF8F00),
                            Color(0xFFE65100),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFFF8F00).withValues(alpha: 0.65),
                            blurRadius: 14,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.play_arrow_rounded,
                                  color: Color(0xFF2E1100),
                                  size: 26,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  "START GAME",
                                  style: TextStyle(
                                    color: Color(0xFF2E1100),
                                    fontSize: 17.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.6,
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
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3D Custom Painters: Crown, Crowned Medallion, Pawn, Dice
// ---------------------------------------------------------------------------

/// 3D Jeweled Golden Crown (Top Header)
class _RoyalCrownPainter extends CustomPainter {
  const _RoyalCrownPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    final path = Path()
      ..moveTo(width * 0.12, height * 0.88)
      ..lineTo(width * 0.05, height * 0.32)
      ..lineTo(width * 0.28, height * 0.58)
      ..lineTo(width * 0.50, height * 0.08)
      ..lineTo(width * 0.72, height * 0.58)
      ..lineTo(width * 0.95, height * 0.32)
      ..lineTo(width * 0.88, height * 0.88)
      ..close();

    final crownPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFFDE7),
          Color(0xFFFFE082),
          Color(0xFFFFB300),
          Color(0xFFC45A00),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.6), 4, true);
    canvas.drawPath(path, crownPaint);

    // Crown Outline
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF5D2E00)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // Peak Jewels (Pearls with gold rims)
    final pearlPaint = Paint()..color = const Color(0xFFFFF9C4);
    for (final pt in [
      Offset(width * 0.05, height * 0.32),
      Offset(width * 0.50, height * 0.08),
      Offset(width * 0.95, height * 0.32),
    ]) {
      canvas.drawCircle(pt, 2.5, pearlPaint);
    }

    // Center Ruby on Headband
    final rubyCenter = Offset(width * 0.50, height * 0.74);
    canvas.drawCircle(
      rubyCenter,
      3.2,
      Paint()..color = const Color(0xFFD50000),
    );
    canvas.drawCircle(
      rubyCenter,
      3.2,
      Paint()
        ..color = const Color(0xFFFFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3D Crowned & Laureled Player Number Medallion
class _CrownedNumberMedallionPainter extends CustomPainter {
  final int number;
  final Color primaryColor;
  final Color lightColor;
  final Color darkColor;

  const _CrownedNumberMedallionPainter({
    required this.number,
    required this.primaryColor,
    required this.lightColor,
    required this.darkColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.50, h * 0.58);
    final radius = w * 0.34;

    // 1. Golden Laurel Wreath Leaves on sides
    final laurelPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 3; i++) {
      final yOffset = h * 0.38 + i * 8.0;
      // Left leaf
      canvas.save();
      canvas.translate(w * 0.16, yOffset);
      canvas.rotate(-0.4 - i * 0.12);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 10, height: 5),
        laurelPaint,
      );
      canvas.restore();

      // Right leaf
      canvas.save();
      canvas.translate(w * 0.84, yOffset);
      canvas.rotate(0.4 + i * 0.12);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 10, height: 5),
        laurelPaint,
      );
      canvas.restore();
    }

    // 2. Center Circular Number Medallion
    final circleRect = Rect.fromCircle(center: center, radius: radius);

    // Drop shadow
    canvas.drawCircle(
      center.translate(0, 2),
      radius,
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );

    // Outer Metallic Gold Bevel Rim
    final goldShader = const LinearGradient(
      colors: [Color(0xFFFFFDE7), Color(0xFFFFD54F), Color(0xFFFF8F00)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(circleRect);

    canvas.drawCircle(center, radius, Paint()..shader = goldShader);

    // Inner Color Gradient
    final innerRadius = radius - 2.5;
    final innerPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.4),
        colors: [lightColor, primaryColor, darkColor],
      ).createShader(Rect.fromCircle(center: center, radius: innerRadius));

    canvas.drawCircle(center, innerRadius, innerPaint);

    // White Number Typography
    final textPainter = TextPainter(
      text: TextSpan(
        text: "$number",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 3,
              offset: Offset(0, 1.5),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    // 3. Golden Crown on Top of Medallion
    final crownW = w * 0.44;
    final crownH = h * 0.24;
    final crownLeft = w * 0.50 - crownW / 2;
    final crownTop = h * 0.12;

    final crownPath = Path()
      ..moveTo(crownLeft + crownW * 0.15, crownTop + crownH * 0.88)
      ..lineTo(crownLeft + crownW * 0.05, crownTop + crownH * 0.35)
      ..lineTo(crownLeft + crownW * 0.30, crownTop + crownH * 0.60)
      ..lineTo(crownLeft + crownW * 0.50, crownTop + crownH * 0.10)
      ..lineTo(crownLeft + crownW * 0.70, crownTop + crownH * 0.60)
      ..lineTo(crownLeft + crownW * 0.95, crownTop + crownH * 0.35)
      ..lineTo(crownLeft + crownW * 0.85, crownTop + crownH * 0.88)
      ..close();

    canvas.drawPath(
      crownPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFFDE7), Color(0xFFFFD54F), Color(0xFFFF8F00)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(crownLeft, crownTop, crownW, crownH)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3D Ludo Pawn
class _RoyalPawnPainter extends CustomPainter {
  final Color color;

  const _RoyalPawnPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Pedestal Base
    final baseRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.88),
      width: w * 0.85,
      height: h * 0.20,
    );
    final basePaint = Paint()
      ..shader = LinearGradient(
        colors: [color, color.withValues(alpha: 0.6), Colors.black],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(baseRect);
    canvas.drawOval(baseRect, basePaint);

    // Body Cone
    final bodyPath = Path()
      ..moveTo(w * 0.38, h * 0.44)
      ..lineTo(w * 0.62, h * 0.44)
      ..lineTo(w * 0.78, h * 0.82)
      ..lineTo(w * 0.22, h * 0.82)
      ..close();
    canvas.drawPath(bodyPath, basePaint);

    // Collar Ring
    final collarRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.44),
      width: w * 0.45,
      height: h * 0.10,
    );
    canvas.drawOval(collarRect, Paint()..color = const Color(0xFFFFD54F));

    // Head Sphere
    final headCenter = Offset(w * 0.5, h * 0.24);
    final headRadius = w * 0.28;
    final headPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [Colors.white.withValues(alpha: 0.95), color, Colors.black],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: headCenter, radius: headRadius));
    canvas.drawCircle(headCenter, headRadius, headPaint);

    // Specular Glint
    canvas.drawCircle(
      Offset(headCenter.dx - 2.5, headCenter.dy - 2.5),
      1.8,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Floating 3D Dice Painter
class _RoyalDicePainter extends CustomPainter {
  final double angle;

  const _RoyalDicePainter({this.angle = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.save();
    canvas.translate(w * 0.5, h * 0.5);
    canvas.rotate(angle);

    final diceRect = Rect.fromCenter(
      center: Offset.zero,
      width: w * 0.75,
      height: h * 0.75,
    );
    final diceRRect =
        RRect.fromRectAndRadius(diceRect, const Radius.circular(6));

    canvas.drawRRect(
      diceRRect.shift(const Offset(2, 2)),
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );

    canvas.drawRRect(
      diceRRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF0F0F0), Color(0xFFCFD8DC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(diceRect),
    );

    canvas.drawRRect(
      diceRRect,
      Paint()
        ..color = const Color(0xFFFFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Pips
    final dotPaint = Paint()..color = const Color(0xFF263238);
    canvas.drawCircle(Offset.zero, 2.2, dotPaint);
    canvas.drawCircle(const Offset(-5.5, -5.5), 2.0, dotPaint);
    canvas.drawCircle(const Offset(5.5, 5.5), 2.0, dotPaint);
    canvas.drawCircle(const Offset(-5.5, 5.5), 2.0, dotPaint);
    canvas.drawCircle(const Offset(5.5, -5.5), 2.0, dotPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
