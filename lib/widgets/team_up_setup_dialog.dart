import 'package:flutter/material.dart';
import '../constants/ludo_colors.dart';
import '../models/game_state.dart';
import '../screens/game_screen.dart';

class TeamUpSetupDialog extends StatefulWidget {
  const TeamUpSetupDialog({super.key});

  @override
  State<TeamUpSetupDialog> createState() => _TeamUpSetupDialogState();
}

class _TeamUpSetupDialogState extends State<TeamUpSetupDialog> {
  // Mode selection: 0 = Pass 'N' Play (Local 4 Players), 1 = Vs Computer (You + Bot vs Bots)
  int _selectedMode = 0;

  final TextEditingController _p1Controller = TextEditingController(text: "Player 1");
  final TextEditingController _p2Controller = TextEditingController(text: "Player 2");
  final TextEditingController _p3Controller = TextEditingController(text: "Player 3");
  final TextEditingController _p4Controller = TextEditingController(text: "Player 4");

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
      _p1Controller.text.trim().isEmpty ? (_selectedMode == 1 ? "You" : "Player 1") : _p1Controller.text.trim(),
      _p2Controller.text.trim().isEmpty ? (_selectedMode == 1 ? "Bot 1" : "Player 2") : _p2Controller.text.trim(),
      _p3Controller.text.trim().isEmpty ? (_selectedMode == 1 ? "Bot Ally" : "Player 3") : _p3Controller.text.trim(),
      _p4Controller.text.trim().isEmpty ? (_selectedMode == 1 ? "Bot 2" : "Player 4") : _p4Controller.text.trim(),
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
    final screenHeight = MediaQuery.sizeOf(context).height;
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = (screenHeight * 0.90) - viewInsets;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: maxHeight.clamp(300.0, 680.0),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0C1730),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFFD700), width: 1.8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.25),
              blurRadius: 24,
              spreadRadius: 2,
            ),
            const BoxShadow(
              color: Colors.black54,
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mode Selector Tabs
                    _buildModeSelector(),
                    const SizedBox(height: 16),

                    // Teams Visual Cards
                    _buildTeamsCard(),
                    const SizedBox(height: 14),

                    // Rules Box
                    _buildRulesBox(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Action Buttons
            _buildBottomAction(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF14203D),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
        border: Border(
          bottom: BorderSide(color: Color(0x33FFD700), width: 1.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFD700).withValues(alpha: 0.15),
              border: Border.all(color: const Color(0xFFFFD700), width: 1.2),
            ),
            child: const Icon(Icons.groups_rounded, color: Color(0xFFFFD700), size: 22),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TEAM UP (2 VS 2)",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Offline Duo Cooperative Battles",
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF070E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
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
          const SizedBox(width: 4),
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF2855C7), Color(0xFF142F80)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          border: isSelected
              ? Border.all(color: const Color(0xFFFFD700), width: 1.2)
              : Border.all(color: Colors.transparent),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? const Color(0xFFFFD700) : Colors.white60,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected ? const Color(0xFFFFD700).withValues(alpha: 0.9) : Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamsCard() {
    final isVsBot = _selectedMode == 1;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A34),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          // TEAM A Header
          _buildTeamBadge(
            teamName: "TEAM A",
            colorsDesc: "Red & Yellow (Opposite Corners)",
            color: const Color(0xFFE53935),
            color2: const Color(0xFFFFB300),
          ),
          const SizedBox(height: 8),

          // Team A inputs
          _buildPlayerInput(
            controller: _p1Controller,
            label: isVsBot ? "Player 1 (You)" : "Player 1",
            dotColor: LudoColors.red,
            readOnly: false,
          ),
          const SizedBox(height: 6),
          _buildPlayerInput(
            controller: _p3Controller,
            label: isVsBot ? "Teammate (AI Bot)" : "Player 3 (Teammate)",
            dotColor: LudoColors.yellow,
            readOnly: false,
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(child: Divider(color: Colors.white24, thickness: 0.8)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    "VS",
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Colors.white24, thickness: 0.8)),
              ],
            ),
          ),

          // TEAM B Header
          _buildTeamBadge(
            teamName: "TEAM B",
            colorsDesc: "Green & Blue (Opposite Corners)",
            color: const Color(0xFF43A047),
            color2: const Color(0xFF1E88E5),
          ),
          const SizedBox(height: 8),

          // Team B inputs
          _buildPlayerInput(
            controller: _p2Controller,
            label: isVsBot ? "Opponent 1 (AI Bot)" : "Player 2",
            dotColor: LudoColors.green,
            readOnly: false,
          ),
          const SizedBox(height: 6),
          _buildPlayerInput(
            controller: _p4Controller,
            label: isVsBot ? "Opponent 2 (AI Bot)" : "Player 4",
            dotColor: LudoColors.blue,
            readOnly: false,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamBadge({
    required String teamName,
    required String colorsDesc,
    required Color color,
    required Color color2,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.6)),
          ),
          child: Text(
            teamName,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color2, shape: BoxShape.circle)),
          ],
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            colorsDesc,
            style: const TextStyle(color: Colors.white60, fontSize: 10),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerInput({
    required TextEditingController controller,
    required String label,
    required Color dotColor,
    required bool readOnly,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF070E1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
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
                  color: dotColor.withValues(alpha: 0.6),
                  blurRadius: 5,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
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

  Widget _buildRulesBox() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF14203D).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_rounded, color: Color(0xFFFFD700), size: 14),
              SizedBox(width: 6),
              Text(
                "2v2 TEAM UP RULES",
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildRuleItem("• Teammates cannot capture or kill each other's gotis."),
          _buildRuleItem("• When a player's 4 gotis finish, their turns help move partner's gotis."),
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
          color: Colors.white70,
          fontSize: 10.5,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF14203D),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
        border: Border(
          top: BorderSide(color: Color(0x33FFD700), width: 1.2),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton(
          onPressed: _startMatch,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFB300),
            foregroundColor: const Color(0xFF0F1A34),
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow_rounded, size: 22, color: Color(0xFF0F1A34)),
              SizedBox(width: 6),
              Text(
                "START 2V2 MATCH",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1.0,
                  color: Color(0xFF0F1A34),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
