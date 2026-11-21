import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/ludo_colors.dart';
import '../models/game_state.dart';
import '../screens/game_screen.dart';

/// 3D Royal Cooperative Team Up (2 vs 2) Setup Dialog.
/// Features:
/// - 3D Jeweled crown on top of the title banner
/// - 3D segmented mode selector cards (Pass 'N' Play vs Vs Computer)
/// - Two distinct 3D battle cards for Team A (Fire & Gold) and Team B (Earth & Ocean)
/// - Multi-layer colored ambient bloom shadows & realistic 3D elevation drop shadows
/// - Central 3D golden "VS" medallion with laser divider lines
/// - 3D golden Start 2v2 Match action button
/// - Exterior 3D pawns & dice
class TeamUpSetupDialog extends StatefulWidget {
  const TeamUpSetupDialog({super.key});

  @override
  State<TeamUpSetupDialog> createState() => _TeamUpSetupDialogState();
}

class _TeamUpSetupDialogState extends State<TeamUpSetupDialog> {
  // Mode selection: 0 = Pass 'N' Play (Local 4 Players), 1 = Vs Computer (You + Bot vs Bots)
  int _selectedMode = 0;

  final TextEditingController _p1Controller =
      TextEditingController(text: "Player 1 (Red)");
  final TextEditingController _p2Controller =
      TextEditingController(text: "Player 2 (Green)");
  final TextEditingController _p3Controller =
      TextEditingController(text: "Player 3 (Yellow)");
  final TextEditingController _p4Controller =
      TextEditingController(text: "Player 4 (Blue)");

  @override
  void dispose() {
    _p1Controller.dispose();
    _p2Controller.dispose();
    _p3Controller.dispose();
    _p4Controller.dispose();
    super.dispose();
  }

  void _onModeChanged(int newMode) {
    setState(() {
      _selectedMode = newMode;
      if (newMode == 1) {
        // Vs Computer defaults
        _p1Controller.text = "You (Red)";
        _p2Controller.text = "Bot Opponent 1";
        _p3Controller.text = "Bot Ally (Yellow)";
        _p4Controller.text = "Bot Opponent 2";
      } else {
        // Pass 'N' Play defaults
        _p1Controller.text = "Player 1 (Red)";
        _p2Controller.text = "Player 2 (Green)";
        _p3Controller.text = "Player 3 (Yellow)";
        _p4Controller.text = "Player 4 (Blue)";
      }
    });
  }

  void _startMatch() {
    final isVsBot = _selectedMode == 1;
    final names = [
      _p1Controller.text.trim().isEmpty
          ? (_selectedMode == 1 ? "You" : "Player 1")
          : _p1Controller.text.trim(),
      _p2Controller.text.trim().isEmpty
          ? (_selectedMode == 1 ? "Bot 1" : "Player 2")
          : _p2Controller.text.trim(),
      _p3Controller.text.trim().isEmpty
          ? (_selectedMode == 1 ? "Bot Ally" : "Player 3")
          : _p3Controller.text.trim(),
      _p4Controller.text.trim().isEmpty
          ? (_selectedMode == 1 ? "Bot 2" : "Player 4")
          : _p4Controller.text.trim(),
    ];

    Navigator.of(context).pop();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          mode: GameMode.teamUp,
          isTeamUpVsBot: isVsBot,
          customPlayerNames: names,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final viewInsets = mediaQuery.viewInsets.bottom;
    final maxHeight = (screenHeight * 0.92) - viewInsets;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 430,
          maxHeight: maxHeight.clamp(400.0, 760.0),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              // 1. Floating Corner Decor (Exterior 3D Dice)
              const Positioned(
                top: 0,
                left: -4,
                child: CustomPaint(
                  size: Size(34, 34),
                  painter: _RoyalDicePainter(angle: -0.25),
                ),
              ),
              const Positioned(
                top: -2,
                right: -4,
                child: CustomPaint(
                  size: Size(32, 32),
                  painter: _RoyalDicePainter(angle: 0.3),
                ),
              ),

              // 2. Main Royal Gaming Modal Container
              Container(
                margin: const EdgeInsets.only(top: 28, bottom: 22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFFFFD54F),
                    width: 3.0,
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF260D52),
                      Color(0xFF140530),
                      Color(0xFF09011A),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.5),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: const Color(0xFF7C4DFF).withValues(alpha: 0.35),
                      blurRadius: 22,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 44, 10, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Subtitle Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF260D50),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFFD54F)
                                .withValues(alpha: 0.7),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.military_tech_rounded,
                                color: Color(0xFFFFD54F), size: 16),
                            SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                "Offline Duo Cooperative Battles",
                                style: TextStyle(
                                  color: Color(0xFFFFE082),
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 3D Mode Selector Segmented Cards
                      _buildModeSelector(),
                      const SizedBox(height: 12),

                      // TEAM A: 3D Battle Card (Fire & Gold)
                      _buildTeamACard(),

                      // Central 3D "VS" Battle Medallion
                      _buildVsMedallion(),

                      // TEAM B: 3D Battle Card (Earth & Ocean)
                      _buildTeamBCard(),
                      const SizedBox(height: 12),

                      // 3D Rules Capsule Box
                      _buildRulesBox(),
                      const SizedBox(height: 14),

                      // 3D Action Button: START 2V2 MATCH
                      _buildStartButton(),
                    ],
                  ),
                ),
              ),

              // 3. Top Title Banner with 3D Shield/Trophy
              Positioned(
                top: 2,
                child: _buildTitleBanner(),
              ),

              // 4. Jeweled 3D Royal Crown
              const Positioned(
                top: -16,
                child: CustomPaint(
                  size: Size(64, 40),
                  painter: _RoyalCrownPainter(),
                ),
              ),

              // 5. 3D Close Button (Top Right)
              Positioned(
                top: 14,
                right: 6,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF29B6F6), Color(0xFF0D47A1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: const Color(0xFFFFD54F),
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0D47A1).withValues(alpha: 0.6),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),

              // 6. Bottom Pawns: Red & Yellow (Team A, Left) | Green & Blue (Team B, Right)
              const Positioned(
                bottom: -2,
                left: 10,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomPaint(
                      size: Size(20, 28),
                      painter: _RoyalPawnPainter(color: Color(0xFFE53935)),
                    ),
                    SizedBox(width: 4),
                    CustomPaint(
                      size: Size(20, 28),
                      painter: _RoyalPawnPainter(color: Color(0xFFFDD835)),
                    ),
                  ],
                ),
              ),
              const Positioned(
                bottom: -2,
                right: 10,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomPaint(
                      size: Size(20, 28),
                      painter: _RoyalPawnPainter(color: Color(0xFF43A047)),
                    ),
                    SizedBox(width: 4),
                    CustomPaint(
                      size: Size(20, 28),
                      painter: _RoyalPawnPainter(color: Color(0xFF1E88E5)),
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

  Widget _buildTitleBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
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
            color: const Color(0xFF1E88E5).withValues(alpha: 0.7),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.shield_rounded, color: Color(0xFFFFD54F), size: 22),
          SizedBox(width: 7),
          Text(
            "TEAM UP (2 VS 2)",
            style: TextStyle(
              fontFamily: 'Roboto',
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
              letterSpacing: 1.0,
              shadows: [
                Shadow(
                  color: Color(0xFFFFB300),
                  blurRadius: 8,
                ),
                Shadow(
                  color: Colors.black,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3D Mode Selector Segmented Cards
  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0A021C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD54F).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeTab(
              index: 0,
              icon: Icons.smartphone_rounded,
              label: "Pass 'N' Play",
              subtitle: "4 Friends (1 Device)",
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _buildModeTab(
              index: 1,
              icon: Icons.smart_toy_rounded,
              label: "Vs Computer",
              subtitle: "You + Bot vs Bots",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required int index,
    required IconData icon,
    required String label,
    required String subtitle,
  }) {
    final isSelected = _selectedMode == index;

    return GestureDetector(
      onTap: () => _onModeChanged(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    Color(0xFF29B6F6),
                    Color(0xFF1E88E5),
                    Color(0xFF0D47A1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFD54F)
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1E88E5).withValues(alpha: 0.6),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 15,
                    color:
                        isSelected ? const Color(0xFFFFD54F) : Colors.white60,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight:
                          isSelected ? FontWeight.w900 : FontWeight.w600,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                subtitle,
                style: TextStyle(
                  color:
                      isSelected ? const Color(0xFFFFE082) : Colors.white38,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// TEAM A: 3D Battle Card (Fire & Gold: Red & Yellow)
  Widget _buildTeamACard() {
    final isVsBot = _selectedMode == 1;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFF5252).withValues(alpha: 0.8),
          width: 1.6,
        ),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4A081A),
            Color(0xFF2C0410),
            Color(0xFF160107),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          // Ambient Crimson Neon Bloom
          BoxShadow(
            color: const Color(0xFFFF1744).withValues(alpha: 0.4),
            blurRadius: 16,
            spreadRadius: 1,
          ),
          // Deep Black 3D Elevation Drop Shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Top specular gloss
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 28,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                children: [
                  // Team A Header Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD50000),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFFFD54F),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD50000)
                                  .withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Text(
                          "TEAM A",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 10.5,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Colored glowing dots
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE53935),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFB300),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          "Red & Yellow (Opposite Corners)",
                          style: TextStyle(
                            color: Color(0xFFFFCDD2),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Player 1 Input (Red)
                  _buildPlayerInput(
                    controller: _p1Controller,
                    label: isVsBot ? "Player 1 (You)" : "Player 1",
                    dotColor: LudoColors.red,
                  ),
                  const SizedBox(height: 6),

                  // Player 3 Input (Yellow)
                  _buildPlayerInput(
                    controller: _p3Controller,
                    label: isVsBot ? "Teammate (AI Bot)" : "Player 3 (Teammate)",
                    dotColor: LudoColors.yellow,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Central 3D "VS" Battle Medallion
  Widget _buildVsMedallion() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1.5,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0xFFFFD54F)],
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
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
              border: Border.all(
                color: const Color(0xFFFFFDE7),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8F00).withValues(alpha: 0.65),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Text(
              "VS",
              style: TextStyle(
                color: Color(0xFF2E1100),
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1.5,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFD54F), Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// TEAM B: 3D Battle Card (Earth & Ocean: Green & Blue)
  Widget _buildTeamBCard() {
    final isVsBot = _selectedMode == 1;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF40C4FF).withValues(alpha: 0.8),
          width: 1.6,
        ),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF06331A),
            Color(0xFF041F2C),
            Color(0xFF020D1A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          // Ambient Emerald/Cyan Neon Bloom
          BoxShadow(
            color: const Color(0xFF00E676).withValues(alpha: 0.35),
            blurRadius: 16,
            spreadRadius: 1,
          ),
          // Deep Black 3D Elevation Drop Shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Top specular gloss
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 28,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                children: [
                  // Team B Header Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C853),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF80D8FF),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00C853)
                                  .withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Text(
                          "TEAM B",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 10.5,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Colored glowing dots
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Color(0xFF43A047),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E88E5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          "Green & Blue (Opposite Corners)",
                          style: TextStyle(
                            color: Color(0xFFB2EBF2),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Player 2 Input (Green)
                  _buildPlayerInput(
                    controller: _p2Controller,
                    label: isVsBot ? "Opponent 1 (AI Bot)" : "Player 2",
                    dotColor: LudoColors.green,
                  ),
                  const SizedBox(height: 6),

                  // Player 4 Input (Blue)
                  _buildPlayerInput(
                    controller: _p4Controller,
                    label: isVsBot ? "Opponent 2 (AI Bot)" : "Player 4",
                    dotColor: LudoColors.blue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerInput({
    required TextEditingController controller,
    required String label,
    required Color dotColor,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF050E22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withValues(alpha: 0.8),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.0,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: label,
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 3D Rules Capsule Box
  Widget _buildRulesBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF140832),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB300).withValues(alpha: 0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.shield_rounded, color: Color(0xFFFFD54F), size: 15),
              SizedBox(width: 6),
              Text(
                "2v2 TEAM UP RULES",
                style: TextStyle(
                  color: Color(0xFFFFD54F),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          _buildRuleItem("• Teammates cannot capture or kill each other's gotis."),
          _buildRuleItem(
              "• When a player's 4 gotis finish, their turns help move partner's gotis."),
          _buildRuleItem("• First team to bring all 8 tokens Home wins the match!"),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFFFF9C4),
          fontSize: 10.0,
          fontWeight: FontWeight.w500,
          height: 1.3,
        ),
      ),
    );
  }

  /// 3D Action Button: START 2V2 MATCH
  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: GestureDetector(
        onTap: _startMatch,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFFFFDE7),
              width: 1.5,
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
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.play_arrow_rounded,
                  size: 24, color: Color(0xFF2E1100)),
              SizedBox(width: 6),
              Text(
                "START 2V2 MATCH",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1.2,
                  color: Color(0xFF2E1100),
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
