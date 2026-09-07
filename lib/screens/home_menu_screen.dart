import 'package:flutter/material.dart';
import '../constants/ludo_colors.dart';
import '../models/game_state.dart';
import '../services/auth_service.dart';
import 'game_screen.dart';
import 'login_screen.dart';

class HomeMenuScreen extends StatefulWidget {
  const HomeMenuScreen({super.key});

  @override
  State<HomeMenuScreen> createState() => _HomeMenuScreenState();
}

class _HomeMenuScreenState extends State<HomeMenuScreen> {
  String _userName = 'Player';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final name = await AuthService.getUserName();
    if (mounted) {
      setState(() {
        _userName = name;
      });
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LudoColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Confirm Logout",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          "Are you sure you want to log out of Ludo Supreme?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LudoColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.amber, Color(0xFFFF8F00)],
                ),
              ),
              child: const Icon(Icons.person, color: Colors.black87, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              "Hi, $_userName",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Logout",
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Game Logo & App Icon
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.45),
                          blurRadius: 28,
                          spreadRadius: 3,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(color: Colors.amber, width: 2.0),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    "LUDO SUPREME",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "The Classic Board Game Experience",
                    style: TextStyle(
                      color: LudoColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Four Player Color Dots Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildColorDot(LudoColors.red),
                      _buildColorDot(LudoColors.green),
                      _buildColorDot(LudoColors.yellow),
                      _buildColorDot(LudoColors.blue),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Menu Buttons
                  _buildMenuCard(
                    context: context,
                    title: "Play vs Computer",
                    subtitle: "Challenge the smart Ludo Bot",
                    icon: Icons.smart_toy_rounded,
                    gradientColors: [
                      const Color(0xFF7C3AED),
                      const Color(0xFF4F46E5)
                    ],
                    onTap: () => _startGame(context, GameMode.vsComputer),
                  ),

                  const SizedBox(height: 16),

                  _buildMenuCard(
                    context: context,
                    title: "2 Players Match",
                    subtitle: "Local Pass & Play 1v1",
                    icon: Icons.people_outline_rounded,
                    gradientColors: [
                      const Color(0xFF0284C7),
                      const Color(0xFF0369A1)
                    ],
                    onTap: () => _startGame(context, GameMode.twoPlayer),
                  ),

                  const SizedBox(height: 16),

                  _buildMenuCard(
                    context: context,
                    title: "4 Players Classic",
                    subtitle: "Full 4-player battle arena",
                    icon: Icons.groups_rounded,
                    gradientColors: [
                      const Color(0xFFE11D48),
                      const Color(0xFFBE123C)
                    ],
                    onTap: () => _startGame(context, GameMode.fourPlayer),
                  ),

                  const SizedBox(height: 28),

                  // Quick How to Play Dialog
                  TextButton.icon(
                    onPressed: () => _showRules(context),
                    icon: const Icon(Icons.info_outline_rounded,
                        color: Colors.amber, size: 18),
                    label: const Text(
                      "How to Play & Rules",
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildColorDot(Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: 8,
            spreadRadius: 1,
          )
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: gradientColors.first.withValues(alpha: 0.3),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: LudoColors.surfaceDark,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white12, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.first.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: LudoColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white38,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startGame(BuildContext context, GameMode mode) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GameScreen(mode: mode)),
    );
  }

  void _showRules(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: LudoColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.menu_book_rounded, color: Colors.amber),
            SizedBox(width: 8),
            Text("Ludo Rules", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "• Roll a 6 to release a pawn from your home base.",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              SizedBox(height: 8),
              Text(
                "• Rolling a 6 gives you a bonus roll!",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              SizedBox(height: 8),
              Text(
                "• Landing on an opponent sends their pawn back to base and awards an extra roll.",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              SizedBox(height: 8),
              Text(
                "• Pawns on safe Star cells can never be captured.",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              SizedBox(height: 8),
              Text(
                "• Navigate all 4 pawns through your colored home track into the center finish to win!",
                style: TextStyle(color: Colors.white70, fontSize: 13),
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
    );
  }
}
