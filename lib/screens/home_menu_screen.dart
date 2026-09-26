import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../services/auth_service.dart';
import '../services/game_storage_service.dart';
import '../widgets/pass_n_play_setup_dialog.dart';
import '../widgets/player_selection_dialog.dart';
import '../widgets/settings_dialog.dart';
import 'game_screen.dart';
import 'login_screen.dart';

class HomeMenuScreen extends StatefulWidget {
  const HomeMenuScreen({super.key});

  @override
  State<HomeMenuScreen> createState() => _HomeMenuScreenState();
}

class _HomeMenuScreenState extends State<HomeMenuScreen> {
  String _userName = 'Ludo Master';
  bool _hasSavedMatch = false;
  GameState? _savedState;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _checkSavedGame();
  }

  Future<void> _loadUserInfo() async {
    final name = await AuthService.getUserName();
    if (mounted && name.isNotEmpty && name != 'Player') {
      setState(() {
        _userName = name;
      });
    }
  }

  Future<void> _checkSavedGame() async {
    final hasGame = await GameStorageService.hasSavedGame();
    if (hasGame) {
      final state = await GameStorageService.loadSavedGame();
      if (mounted) {
        setState(() {
          _hasSavedMatch = state != null;
          _savedState = state;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _hasSavedMatch = false;
          _savedState = null;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF10192D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x33FFD700)),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFFFD700), size: 22),
            SizedBox(width: 10),
            Text(
              "Exit / Logout",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  Future<void> _discardSavedMatch() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF10192D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x33FFD700)),
        ),
        title: const Text("Discard Saved Match?",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          "Are you sure you want to discard your saved match progress?",
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Discard"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await GameStorageService.clearSavedGame();
      _checkSavedGame();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060B19),
      body: Stack(
        children: [
          // 1. Luxury Background Wallpaper with Pawns & Gold dust
          Positioned.fill(
            child: Image.asset(
              'assets/images/ludo_supreme_bg.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF060B19), Color(0xFF0F1A34), Color(0xFF060B19)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          // 2. Dark Luxury Gradient Overlay for Contrast
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0x99060B19),
                    Color(0x73060B19),
                    Color(0xD9060B19),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 3. Main Content
          SafeArea(
            child: Column(
              children: [
                // Top Header Bar
                _buildHeaderBar(context),

                // Scrollable Body Content
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 3D Emblem & Pedestal
                            _buildHeroEmblem(),

                            const SizedBox(height: 12),

                            // Branding Title (LUDO SUPREME + Tagline)
                            _buildBrandingTitle(),

                            const SizedBox(height: 16),

                            // 4-Color Player Indicator Dots & Glowing Divider
                            _buildColorDotsWithSlider(),

                            const SizedBox(height: 24),

                            // Resume Match Card (if exists)
                            if (_hasSavedMatch && _savedState != null) ...[
                              _buildResumeCard(context, _savedState!),
                              const SizedBox(height: 16),
                            ],

                            // Card 1: Play with Friends (Online Rooms)
                            _buildFriendsCard(context),

                            const SizedBox(height: 14),

                            // Card 2: Pass N Play (Local Same-Device Multiplayer)
                            _buildPassNPlayCard(context),

                            const SizedBox(height: 14),

                            // Card 3: Play vs Computer
                            _buildComputerCard(context),

                            const SizedBox(height: 28),

                            // Bottom 4 Feature Badges
                            _buildBottomFeatures(),

                            const SizedBox(height: 18),

                            // How to Play & Rules Link
                            _buildRulesLink(context),

                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Top Header Bar ---
  Widget _buildHeaderBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // Profile Avatar with Golden Ring
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF141F36),
              border: Border.all(color: const Color(0xFFFFD700), width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              color: Color(0xFFFFD700),
              size: 26,
            ),
          ),
          const SizedBox(width: 12),

          // User Greeting & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: const TextStyle(fontSize: 16, fontFamily: 'Roboto'),
                    children: [
                      const TextSpan(
                        text: "Hi, ",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: _userName,
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Ready to Roll Today?",
                  style: TextStyle(
                    color: Color(0xFF90A4AE),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Action 1: Settings Button
          _buildActionButton(
            icon: Icons.settings_rounded,
            tooltip: "Settings",
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => const SettingsDialog(),
              );
            },
          ),
          const SizedBox(width: 10),

          // Action 2: Exit / Logout Button
          _buildActionButton(
            icon: Icons.logout_rounded,
            tooltip: "Exit Game",
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFF162038).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Icon(icon, color: const Color(0xFFECEFF1), size: 20),
        ),
      ),
    );
  }

  // --- Center 3D Card Emblem on Glowing Pedestal with Crown ---
  Widget _buildHeroEmblem() {
    return SizedBox(
      width: 190,
      height: 185,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 1. Bottom 3D Glowing Pedestal
          Positioned(
            bottom: 4,
            child: Container(
              width: 160,
              height: 36,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.all(Radius.elliptical(160, 36)),
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFF3A2B14),
                    Color(0xFF14203D),
                    Color(0xFF060B19),
                  ],
                  radius: 0.85,
                ),
                border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.7),
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                    blurRadius: 22,
                    spreadRadius: 3,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: const Color(0xFF00B4D8).withValues(alpha: 0.25),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 120,
                  height: 18,
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.all(Radius.elliptical(120, 18)),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFD700).withValues(alpha: 0.6),
                        const Color(0xFFFF8F00).withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2. The 3D Rounded Gold Card Badge
          Positioned(
            top: 14,
            child: Container(
              width: 136,
              height: 136,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFE082),
                    Color(0xFFFFB300),
                    Color(0xFFFF8F00),
                    Color(0xFFFF6F00),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.45),
                    blurRadius: 26,
                    spreadRadius: 4,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.65),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(3.2), // Metallic golden frame rim
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(23),
                  color: const Color(0xFF0A1329),
                  border: Border.all(
                    color: const Color(0xFF1E2F54),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset(
                    'assets/images/ludo_supreme_emblem.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          colors: [Color(0xFF2A1B4E), Color(0xFF0B1736)],
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.casino_rounded,
                            color: Color(0xFFFFD700), size: 64),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. Golden Royal Crown on Top of Card
          Positioned(
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.military_tech_rounded,
                color: Color(0xFFFFD700),
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Branding Title ---
  Widget _buildBrandingTitle() {
    return Column(
      children: [
        // Mini Golden Crown
        const Icon(
          Icons.military_tech_rounded,
          color: Color(0xFFFFD700),
          size: 20,
        ),
        const SizedBox(height: 2),

        // LUDO SUPREME 3D Metallic Text
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "LUDO ",
              style: TextStyle(
                color: Color(0xFFEDEDED),
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.5,
                shadows: [
                  Shadow(
                    color: Colors.black87,
                    offset: Offset(0, 3),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFFFFF176),
                  Color(0xFFFFD54F),
                  Color(0xFFFFB300),
                  Color(0xFFFF8F00),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(bounds),
              child: const Text(
                "SUPREME",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                  shadows: [
                    Shadow(
                      color: Color(0x66FF8F00),
                      offset: Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Tagline
        const Text(
          "THE CLASSIC BOARD GAME EXPERIENCE",
          style: TextStyle(
            color: Color(0xFFB0BEC5),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.2,
          ),
        ),
      ],
    );
  }

  // --- 4 Player Color Dots & Golden Slider ---
  Widget _buildColorDotsWithSlider() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGlowingDot(const Color(0xFFE53935)),
            _buildGlowingDot(const Color(0xFF43A047)),
            _buildGlowingDot(const Color(0xFFFFB300)),
            _buildGlowingDot(const Color(0xFF1E88E5)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: 38,
          height: 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlowingDot(Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: 11,
      height: 11,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.7),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  // --- Card 1: Play with Friends (PASS & PLAY) ---
  Widget _buildFriendsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFB300),
          width: 1.8,
        ),
        gradient: const LinearGradient(
          colors: [
            Color(0xF0201A12),
            Color(0xF0121728),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB300).withValues(alpha: 0.30),
            blurRadius: 22,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: const Color(0xFFFFB300).withValues(alpha: 0.2),
          onTap: _openFriendsSelection,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                // Golden Rounded Square Icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB74D), Color(0xFFFF8F00), Color(0xFFE65100)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF8F00).withValues(alpha: 0.45),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),

                // Title + PASS & PLAY badge + Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Flexible(
                            child: Text(
                              "Play with Friends",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            key: const Key('friends_pass_n_play_badge'),
                            onTap: _openPassNPlaySetup,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB300),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFB300).withValues(alpha: 0.4),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Text(
                                "PASS & PLAY",
                                style: TextStyle(
                                  color: Color(0xFF1B1B1B),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        "Pass & Play with 2, 3 or 4 friends",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFFB0BEC5),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Circular Chevron Button
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0x33FFB300),
                    border: Border.all(color: const Color(0xFFFFB300), width: 1.2),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFFFD54F),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Card 2: Pass N Play (Local Multiplayer) ---
  Widget _buildPassNPlayCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00E676),
          width: 1.8,
        ),
        gradient: const LinearGradient(
          colors: [
            Color(0xF00F291E),
            Color(0xF00D1F2D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E676).withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('pass_n_play_card'),
          borderRadius: BorderRadius.circular(20),
          splashColor: const Color(0xFF00E676).withValues(alpha: 0.2),
          onTap: _openPassNPlaySetup,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                // Emerald/Cyan Rounded Square Icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E676), Color(0xFF00B0FF), Color(0xFF1DE9B6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E676).withValues(alpha: 0.45),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.phonelink_ring_rounded,
                    color: Color(0xFF060B19),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),

                // Title + LOCAL badge + Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Flexible(
                            child: Text(
                              "Pass N Play",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E676),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E676).withValues(alpha: 0.4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Text(
                              "LOCAL",
                              style: TextStyle(
                                color: Color(0xFF060B19),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        "Pass & play on 1 device with 2, 3 or 4 players",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFFB0BEC5),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Circular Chevron Button
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0x3300E676),
                    border: Border.all(color: const Color(0xFF00E676), width: 1.2),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF69F0AE),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Card 3: Play vs Computer ---
  Widget _buildComputerCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00B4D8),
          width: 1.8,
        ),
        gradient: const LinearGradient(
          colors: [
            Color(0xF00D1B2A),
            Color(0xF0101730),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B4D8).withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: const Color(0xFF00B4D8).withValues(alpha: 0.2),
          onTap: () => _startGame(context, GameMode.vsComputer),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                // Cyan/Purple Rounded Square Icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8A4FFF), Color(0xFF4361EE), Color(0xFF3A0CA3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4361EE).withValues(alpha: 0.45),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),

                // Title & Subtitle
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Play vs Computer",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        "Challenge the smart Ludo Bot",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFFB0BEC5),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Circular Chevron Button
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0x3300B4D8),
                    border: Border.all(color: const Color(0xFF00B4D8), width: 1.2),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF00E5FF),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Resume Saved Match Card ---
  Widget _buildResumeCard(BuildContext context, GameState state) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF8D6E12),
            Color(0xFF5D420A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _startGame(context, state.mode, state),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Color(0xFFFFD700), size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "RESUME SAVED MATCH",
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${_getModeName(state.mode)} • ${state.currentPlayer.name}'s turn",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: "Discard Match",
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.white70, size: 20),
                  onPressed: _discardSavedMatch,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Bottom 4 Feature Badges ---
  Widget _buildBottomFeatures() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A30).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFeatureBadge(
              icon: Icons.emoji_events_rounded,
              iconColor: const Color(0xFFFFB300),
              title: "Classic Mode",
            ),
          ),
          Expanded(
            child: _buildFeatureBadge(
              icon: Icons.groups_rounded,
              iconColor: const Color(0xFF8A4FFF),
              title: "2-4 Players",
            ),
          ),
          Expanded(
            child: _buildFeatureBadge(
              icon: Icons.bar_chart_rounded,
              iconColor: const Color(0xFF00B4D8),
              title: "Fun & Strategy",
            ),
          ),
          Expanded(
            child: _buildFeatureBadge(
              icon: Icons.verified_user_rounded,
              iconColor: const Color(0xFF43A047),
              title: "Safe & Ad-Free",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge({
    required IconData icon,
    required Color iconColor,
    required String title,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: iconColor.withValues(alpha: 0.3), width: 1.0),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              maxLines: 1,
              style: const TextStyle(
                color: Color(0xFFB0BEC5),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- How to Play & Rules Link ---
  Widget _buildRulesLink(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showRules(context),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Color(0xFFFFD700),
                size: 16,
              ),
              SizedBox(width: 6),
              Text(
                "How to Play & Rules",
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFFFD700),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openFriendsSelection() async {
    final selectedMode = await showDialog<GameMode>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const PlayerSelectionDialog(),
    );

    if (selectedMode != null && mounted) {
      _startGame(context, selectedMode);
    }
  }

  Future<void> _openPassNPlaySetup() async {
    final config = await showDialog<PassNPlayConfig>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const PassNPlaySetupDialog(),
    );

    if (config != null && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GameScreen(
            mode: GameMode.passNPlay,
            passNPlayPlayerCount: config.playerCount,
            customPlayerNames: config.playerNames,
          ),
        ),
      );
      _checkSavedGame();
    }
  }

  String _getModeName(GameMode mode) {
    switch (mode) {
      case GameMode.twoPlayer:
        return "2 Players";
      case GameMode.threePlayer:
        return "3 Players";
      case GameMode.fourPlayer:
        return "4 Players";
      case GameMode.vsComputer:
        return "Vs Computer";
      case GameMode.passNPlay:
        return "Pass N Play";
    }
  }

  Future<void> _startGame(BuildContext context, GameMode mode,
      [GameState? state]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          mode: mode,
          restoredState: state,
        ),
      ),
    );
    _checkSavedGame();
  }

  void _showRules(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF10192D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x44FFD700)),
        ),
        title: const Row(
          children: [
            Icon(Icons.menu_book_rounded, color: Color(0xFFFFD700)),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                "Ludo Rules",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
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
            child: const Text("Got it!",
                style: TextStyle(
                    color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}
