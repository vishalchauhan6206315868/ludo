import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/ludo_colors.dart';
import 'pass_n_play_player_setup_screen.dart';

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

              // Main Selection Body
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Decorative Crown Emblem
                              _buildEmblemBadge(),

                              const SizedBox(height: 12),

                              // Main Title & Subtitle
                              _buildTitleSection(),

                              const SizedBox(height: 22),

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

                              const SizedBox(height: 14),

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

                              const SizedBox(height: 14),

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
                                  "Blue"
                                ],
                              ),

                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bottom Next Action Bar
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
              key: const Key('pass_n_play_back_button'),
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
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
                  "STEP 1 OF 2 • SELECT PLAYERS",
                  style: TextStyle(
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
              key: const Key('pass_n_play_help_button'),
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

  Widget _buildEmblemBadge() {
    return Center(
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF8F00).withValues(alpha: 0.5),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.groups_rounded,
          color: Color(0xFF0F1A30),
          size: 28,
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "SELECT PLAYERS",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.8,
            shadows: [
              Shadow(
                color: Color(0x77FFD700),
                offset: Offset(0, 2),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Choose how many players will compete on this device",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFB0BEC5),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

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

    return AnimatedScale(
      scale: isSelected ? 1.025 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: isSelected
                ? [
                    const Color(0xFF162D55),
                    const Color(0xFF0F2040),
                  ]
                : [
                    const Color(0xFF0F1A32),
                    const Color(0xFF0A1325),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFD700)
                : Colors.white.withValues(alpha: 0.12),
            width: isSelected ? 2.4 : 1.2,
          ),
          boxShadow: [
            if (isSelected) ...[
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.38),
                blurRadius: 20,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ] else ...[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: cardKey,
            borderRadius: BorderRadius.circular(20),
            splashColor: const Color(0xFFFFD700).withValues(alpha: 0.15),
            onTap: () {
              try {
                HapticFeedback.selectionClick();
              } catch (_) {}
              setState(() {
                _selectedPlayerCount = count;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Player Count Pill Badge
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: isSelected
                            ? [
                                const Color(0xFFFFE082),
                                const Color(0xFFFFB300),
                                const Color(0xFFFF8F00),
                              ]
                            : [
                                const Color(0xFF1A2A48),
                                const Color(0xFF121F38),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFFD700)
                            : Colors.white.withValues(alpha: 0.15),
                        width: 1.2,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color:
                                const Color(0xFFFF8F00).withValues(alpha: 0.4),
                            blurRadius: 10,
                          ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        "${count}P",
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF10192D)
                              : Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Middle: Title, Subtitle, and Token Row
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 2,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFFCFD8DC),
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFFFD700)
                                        .withValues(alpha: 0.25)
                                    : Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFFFD700)
                                      : Colors.white24,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                badgeText,
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFFFFD700)
                                      : Colors.white70,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF90A4AE),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Tokens preview wrap
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: List.generate(colors.length, (i) {
                            return _buildMiniTokenBadge(
                              colors[i],
                              colorNames[i],
                              isSelected,
                            );
                          }),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Selection Indicator Radio Check
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                            )
                          : null,
                      color: isSelected ? null : const Color(0xFF0C162A),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFFD700)
                            : Colors.white.withValues(alpha: 0.3),
                        width: isSelected ? 1.5 : 1.5,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color:
                                const Color(0xFFFF8F00).withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Color(0xFF10192D),
                            size: 18,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniTokenBadge(Color color, String name, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isSelected ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: isSelected ? 0.8 : 0.4),
          width: 0.9,
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
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.8),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            name,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.bold,
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
                  key: const Key('next_button'),
                  borderRadius: BorderRadius.circular(16),
                  onTap: _onNext,
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "NEXT",
                          style: TextStyle(
                            color: Color(0xFF10192D),
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFF10192D),
                          size: 24,
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
