import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/ludo_colors.dart';
import 'pass_n_play_player_setup_screen.dart';

/// Royal 3D Gaming Pass N Play Setup Screen (Select Players).
/// Matches the reference design with:
/// - 3D Jeweled crown on top of "PASS N PLAY" banner
/// - 3D circular back and help buttons
/// - "SELECT PLAYERS" banner with laurel wreath and center group medallion
/// - 3D player count cards (2P, 3P, 4P) with custom 3D cube emblems
/// - Multi-layer ambient colored glow & realistic 3D elevation drop shadows
/// - Color indicator pills for each mode (Red, Yellow, Green, Blue)
/// - 3D Golden NEXT button with pawns and dice decor
class PassNPlaySetupScreen extends StatefulWidget {
  final int initialPlayerCount;

  const PassNPlaySetupScreen({
    super.key,
    this.initialPlayerCount = 2,
  });

  @override
  State<PassNPlaySetupScreen> createState() => _PassNPlaySetupScreenState();
}

class _PassNPlaySetupScreenState extends State<PassNPlaySetupScreen> {
  late int _selectedPlayerCount;

  @override
  void initState() {
    super.initState();
    _selectedPlayerCount = widget.initialPlayerCount.clamp(2, 4);
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
              "Pass N Play Rules",
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
              "• Play locally with friends on this single phone.",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            SizedBox(height: 8),
            Text(
              "• Select 2, 3, or 4 players to participate in the match.",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            SizedBox(height: 8),
            Text(
              "• In the next step, configure each player's name.",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            SizedBox(height: 8),
            Text(
              "• Device prompts each player when their turn arrives. No internet or bots required!",
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

  Future<void> _onNext() async {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PassNPlayPlayerSetupScreen(
          playerCount: _selectedPlayerCount,
        ),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060B19),
      body: Stack(
        children: [
          // 1. Cosmic Gradient Background Wallpaper
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF040816),
                    Color(0xFF0A183C),
                    Color(0xFF060D24),
                    Color(0xFF02040B),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 2. Floating 3D Dice at Top Corners
          const Positioned(
            top: 48,
            left: 10,
            child: CustomPaint(
              size: Size(32, 32),
              painter: _RoyalDicePainter(angle: -0.25),
            ),
          ),
          const Positioned(
            top: 48,
            right: 12,
            child: CustomPaint(
              size: Size(30, 30),
              painter: _RoyalDicePainter(angle: 0.3),
            ),
          ),

          // 3. Middle Side Floating Pawns (Green on left, Yellow on right)
          const Positioned(
            top: 155,
            left: 8,
            child: CustomPaint(
              size: Size(22, 32),
              painter: _RoyalPawnPainter(color: Color(0xFF43A047)),
            ),
          ),
          const Positioned(
            top: 155,
            right: 8,
            child: CustomPaint(
              size: Size(22, 32),
              painter: _RoyalPawnPainter(color: Color(0xFFFDD835)),
            ),
          ),

          // 4. Screen Content
          SafeArea(
            child: Column(
              children: [
                // Top Header (Back, Crown + "PASS N PLAY", Help)
                _buildHeader(context),

                // Main Selection Body
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

                                // Center Medallion + "SELECT PLAYERS" Title Banner
                                _buildSelectPlayersSection(),

                                const SizedBox(height: 12),

                                // 2 Players Selection Card
                                _buildPlayerOptionCard(
                                  count: 2,
                                  title: "2 PLAYERS",
                                  badgeText: "1 VS 1 DUEL",
                                  subtitle: "Opposing corners tactical race",
                                  cardKey: const Key('select_card_2p'),
                                  colors: [
                                    LudoColors.red,
                                    LudoColors.yellow,
                                  ],
                                  colorNames: ["Red", "Yellow"],
                                ),

                                const SizedBox(height: 10),

                                // 3 Players Selection Card
                                _buildPlayerOptionCard(
                                  count: 3,
                                  title: "3 PLAYERS",
                                  badgeText: "TRIANGLE BATTLE",
                                  subtitle: "3-corner fast tactical clash",
                                  cardKey: const Key('select_card_3p'),
                                  colors: [
                                    LudoColors.red,
                                    LudoColors.green,
                                    LudoColors.yellow,
                                  ],
                                  colorNames: ["Red", "Green", "Yellow"],
                                ),

                                const SizedBox(height: 10),

                                // 4 Players Selection Card
                                _buildPlayerOptionCard(
                                  count: 4,
                                  title: "4 PLAYERS",
                                  badgeText: "FULL ARENA",
                                  subtitle: "Classic 4-corner championship",
                                  cardKey: const Key('select_card_4p'),
                                  colors: [
                                    LudoColors.red,
                                    LudoColors.green,
                                    LudoColors.yellow,
                                    LudoColors.blue,
                                  ],
                                  colorNames: [
                                    "Red",
                                    "Green",
                                    "Yellow",
                                    "Blue",
                                  ],
                                ),

                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Action Bar: NEXT Button with Pawns
                _buildBottomBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Top Header with Back Button, Crown over "PASS N PLAY", and Help Button
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          // 3D Circular Back Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('pass_n_play_back_button'),
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
                      const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "STEP 1 OF 2 • SELECT PLAYERS",
                          style: TextStyle(
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
              key: const Key('pass_n_play_help_button'),
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

  /// Center Group Medallion + "SELECT PLAYERS" Title Banner
  Widget _buildSelectPlayersSection() {
    return Column(
      children: [
        // 3D Circular Medallion with Group Icon
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF40C4FF), Color(0xFF0091EA), Color(0xFF01579B)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(
              color: const Color(0xFFFFD54F),
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00B0FF).withValues(alpha: 0.6),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.groups_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 6),

        // "SELECT PLAYERS" Capsule Banner with Golden Laurels
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF1E88E5), Color(0xFF0D47A1), Color(0xFF052163)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(
              color: const Color(0xFFFFD54F),
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E88E5).withValues(alpha: 0.5),
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
                  "SELECT PLAYERS",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
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

        // Subtitle: "Choose how many players will compete on this device"
        Column(
          children: const [
            Text(
              "Choose how many players will compete",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              "on this device",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFFFD54F),
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 3D Player Count Selection Card (2P, 3P, 4P)
  Widget _buildPlayerOptionCard({
    required int count,
    required String title,
    required String badgeText,
    required String subtitle,
    required Key cardKey,
    required List<Color> colors,
    required List<String> colorNames,
  }) {
    final isSelected = _selectedPlayerCount == count;

    // Card Colors & Gradients based on player count
    List<Color> cardGradient;
    Color glowColor;
    Color borderColor;

    if (count == 2) {
      cardGradient = isSelected
          ? const [Color(0xFF0052D4), Color(0xFF2855E3), Color(0xFF092994)]
          : const [Color(0xFF0B2456), Color(0xFF071738), Color(0xFF030A1A)];
      glowColor = const Color(0xFF29B6F6);
      borderColor = isSelected ? const Color(0xFFFFD54F) : const Color(0xFF40C4FF);
    } else if (count == 3) {
      cardGradient = isSelected
          ? const [Color(0xFF0052D4), Color(0xFF2855E3), Color(0xFF092994)]
          : const [Color(0xFF0D47A1), Color(0xFF093175), Color(0xFF031438)];
      glowColor = const Color(0xFF00E5FF);
      borderColor = isSelected ? const Color(0xFFFFD54F) : const Color(0xFF29B6F6);
    } else {
      cardGradient = isSelected
          ? const [Color(0xFF4A0072), Color(0xFF6A1B9A), Color(0xFF310055)]
          : const [Color(0xFF380054), Color(0xFF240038), Color(0xFF130020)];
      glowColor = const Color(0xFFD500F9);
      borderColor = isSelected ? const Color(0xFFFFD54F) : const Color(0xFFEA80FC);
    }

    return AnimatedScale(
      scale: isSelected ? 1.015 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          // Metallic Gold Outer Bevel Frame when selected
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    Color(0xFFFFFDE7),
                    Color(0xFFFFE082),
                    Color(0xFFFFB300),
                    Color(0xFFFF8F00),
                    Color(0xFF8D4B00),
                    Color(0xFFFFD54F),
                  ],
                  stops: [0.0, 0.20, 0.45, 0.70, 0.90, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    borderColor.withValues(alpha: 0.6),
                    Colors.white.withValues(alpha: 0.1),
                    borderColor.withValues(alpha: 0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          boxShadow: [
            if (isSelected) ...[
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: glowColor.withValues(alpha: 0.5),
                blurRadius: 18,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ] else ...[
              BoxShadow(
                color: glowColor.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ],
        ),
        padding: EdgeInsets.all(isSelected ? 2.5 : 1.5),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isSelected ? 17.5 : 18.5),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFFD700).withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.12),
              width: 1.0,
            ),
            gradient: LinearGradient(
              colors: cardGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: cardKey,
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                try {
                  HapticFeedback.selectionClick();
                } catch (_) {}
                setState(() => _selectedPlayerCount = count);
              },
              child: Stack(
                children: [
                  // Specular Curved Gloss Highlight
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 36,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                        ),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white
                                .withValues(alpha: isSelected ? 0.25 : 0.12),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),

                  // Card Content
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 10.0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left: 3D Cube Emblem ("2P", "3P", "4P")
                        _build3DCubeEmblem(count, isSelected),

                        const SizedBox(width: 10),

                        // Center: Title, Badge, Subtitle & Player Color Pills
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Title & Badge Row
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15.0,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.8),
                                            offset: const Offset(0, 2),
                                            blurRadius: 4,
                                          ),
                                          if (isSelected)
                                            Shadow(
                                              color: glowColor
                                                  .withValues(alpha: 0.8),
                                              blurRadius: 10,
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    _buildBadge(badgeText, count, isSelected),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),

                              // Subtitle
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  subtitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black54,
                                        offset: Offset(0, 1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Player Color Pills Row
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(colors.length, (i) {
                                    return Container(
                                      margin: const EdgeInsets.only(right: 5),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF040B1A),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: colors[i],
                                          width: 1.0,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: colors[i]
                                                .withValues(alpha: 0.4),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              color: colors[i],
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            colorNames[i],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9.0,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Right: Selection Indicator (Green checkmark or dark metallic ring)
                        _buildSelectionIndicator(isSelected, glowColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 3D Cube Emblem ("2P", "3P", "4P") with Crown
  Widget _build3DCubeEmblem(int count, bool isSelected) {
    List<Color> cubeGradient;
    Color textColor;
    bool showCrown = count == 2 || isSelected;

    if (count == 2) {
      cubeGradient = const [
        Color(0xFFFFFDE7),
        Color(0xFFFFD54F),
        Color(0xFFFF9800),
      ];
      textColor = const Color(0xFF2E1100);
    } else if (count == 3) {
      cubeGradient = isSelected
          ? const [Color(0xFFFFFDE7), Color(0xFFFFD54F), Color(0xFFFF9800)]
          : const [Color(0xFF29B6F6), Color(0xFF0288D1), Color(0xFF01579B)];
      textColor = isSelected ? const Color(0xFF2E1100) : Colors.white;
    } else {
      cubeGradient = isSelected
          ? const [Color(0xFFFFFDE7), Color(0xFFFFD54F), Color(0xFFFF9800)]
          : const [Color(0xFFAB47BC), Color(0xFF7B1FA2), Color(0xFF4A148C)];
      textColor = isSelected ? const Color(0xFF2E1100) : Colors.white;
    }

    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        // 3D Cube Body
        Container(
          margin: EdgeInsets.only(top: showCrown ? 8 : 0),
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: cubeGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: const Color(0xFFFFD54F),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: cubeGradient[1].withValues(alpha: 0.6),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              "${count}P",
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                shadows: [
                  if (textColor == Colors.white)
                    const Shadow(
                      color: Colors.black87,
                      blurRadius: 4,
                      offset: Offset(0, 1.5),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Crown on Top
        if (showCrown)
          const Positioned(
            top: -2,
            child: CustomPaint(
              size: Size(32, 18),
              painter: _RoyalCrownPainter(),
            ),
          ),
      ],
    );
  }

  /// Small Mode Category Pill Tag
  Widget _buildBadge(String text, int count, bool isSelected) {
    Color badgeColor;
    Color textColor;

    if (count == 2) {
      badgeColor = const Color(0xFFFFD54F);
      textColor = const Color(0xFF2E1100);
    } else if (count == 3) {
      badgeColor = isSelected ? const Color(0xFFFFD54F) : const Color(0xFF1976D2);
      textColor = isSelected ? const Color(0xFF2E1100) : Colors.white;
    } else {
      badgeColor = isSelected ? const Color(0xFFFFD54F) : const Color(0xFF8E24AA);
      textColor = isSelected ? const Color(0xFF2E1100) : Colors.white;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.5),
            blurRadius: 4,
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  /// Selection Circle Indicator
  Widget _buildSelectionIndicator(bool isSelected, Color glowColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isSelected
            ? const LinearGradient(
                colors: [
                  Color(0xFF69F0AE),
                  Color(0xFF00E676),
                  Color(0xFF00C853),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF1E2746), Color(0xFF0E1325)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        border: Border.all(
          color: isSelected
              ? Colors.white
              : const Color(0xFFFFD700).withValues(alpha: 0.6),
          width: isSelected ? 2.0 : 1.8,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: const Color(0xFF00E676).withValues(alpha: 0.8),
              blurRadius: 12,
              spreadRadius: 2,
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: isSelected
          ? const Center(
              child: Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 20,
                weight: 800,
              ),
            )
          : null,
    );
  }

  /// Bottom pinned action bar with 3D Golden "NEXT" button & exterior pawns
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
              // Bottom Exterior Pawns: Red & Green (Left), Yellow & Blue (Right)
              const Positioned(
                bottom: -2,
                left: -8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomPaint(
                      size: Size(20, 28),
                      painter: _RoyalPawnPainter(color: Color(0xFFE53935)),
                    ),
                    SizedBox(width: 3),
                    CustomPaint(
                      size: Size(20, 28),
                      painter: _RoyalPawnPainter(color: Color(0xFF43A047)),
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
                      size: Size(20, 28),
                      painter: _RoyalPawnPainter(color: Color(0xFFFDD835)),
                    ),
                    SizedBox(width: 3),
                    CustomPaint(
                      size: Size(20, 28),
                      painter: _RoyalPawnPainter(color: Color(0xFF1E88E5)),
                    ),
                  ],
                ),
              ),

              // Main Golden NEXT Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 46),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: GestureDetector(
                    key: const Key('next_button'),
                    onTap: _onNext,
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
                            color: const Color(0xFFFF8F00).withValues(alpha: 0.65),
                            blurRadius: 14,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            "NEXT",
                            style: TextStyle(
                              color: Color(0xFF2E1100),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFF2E1100),
                            size: 22,
                          ),
                        ],
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
// 3D Custom Painters for Crown, Pawn, and Dice
// ---------------------------------------------------------------------------

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
    canvas.drawPath(path, crownPaint);

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF5D2E00)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // Center Ruby
    final rubyPaint = Paint()..color = const Color(0xFFD50000);
    canvas.save();
    canvas.translate(width * 0.50, height * 0.65);
    canvas.rotate(math.pi / 4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 6, height: 6),
        const Radius.circular(1.2),
      ),
      rubyPaint,
    );
    canvas.restore();

    final pearlPaint = Paint()..color = Colors.white;
    for (final pt in [
      Offset(width * 0.05, height * 0.32),
      Offset(width * 0.50, height * 0.08),
      Offset(width * 0.95, height * 0.32),
    ]) {
      canvas.drawCircle(pt, 2.5, pearlPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoyalPawnPainter extends CustomPainter {
  final Color color;

  const _RoyalPawnPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final baseRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.88),
      width: w * 0.85,
      height: h * 0.18,
    );
    final basePaint = Paint()
      ..shader = LinearGradient(
        colors: [color, color.withValues(alpha: 0.6), Colors.black],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(baseRect);
    canvas.drawOval(baseRect, basePaint);

    final bodyPath = Path()
      ..moveTo(w * 0.38, h * 0.44)
      ..lineTo(w * 0.62, h * 0.44)
      ..lineTo(w * 0.78, h * 0.82)
      ..lineTo(w * 0.22, h * 0.82)
      ..close();
    canvas.drawPath(bodyPath, basePaint);

    final collarRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.44),
      width: w * 0.45,
      height: h * 0.10,
    );
    canvas.drawOval(collarRect, Paint()..color = const Color(0xFFFFD54F));

    final headCenter = Offset(w * 0.5, h * 0.24);
    final headRadius = w * 0.28;
    final headPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [Colors.white.withValues(alpha: 0.9), color, Colors.black],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: headCenter, radius: headRadius));
    canvas.drawCircle(headCenter, headRadius, headPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
        RRect.fromRectAndRadius(diceRect, const Radius.circular(5));

    canvas.drawRRect(
      diceRRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFE0E0E0), Color(0xFFBDBDBD)],
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

    final dotPaint = Paint()..color = const Color(0xFFD50000);
    canvas.drawCircle(Offset.zero, 2.0, dotPaint);
    canvas.drawCircle(const Offset(-5, -5), 2.0, dotPaint);
    canvas.drawCircle(const Offset(5, 5), 2.0, dotPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
