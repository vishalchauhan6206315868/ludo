import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../services/auth_service.dart';
import '../services/game_storage_service.dart';
import '../widgets/game_mode_card.dart';
import '../widgets/home_navigation_sections.dart';
import '../widgets/player_selection_dialog.dart';
import '../widgets/settings_dialog.dart';
import 'game_screen.dart';
import 'login_screen.dart';
import 'pass_n_play_setup_screen.dart';

class HomeMenuScreen extends StatefulWidget {
  const HomeMenuScreen({super.key});

  @override
  State<HomeMenuScreen> createState() => _HomeMenuScreenState();
}

class _HomeMenuScreenState extends State<HomeMenuScreen> {
  String _userName = 'Ludo Master';
  bool _hasSavedMatch = false;
  GameState? _savedState;
  int _selectedNavIndex = 0; // 0: HOME, 1: EVENT, 2: ADDA, 3: INVENTORY, 4: SOCIAL

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

                // Dynamic Section Content
                Expanded(
                  child: Center(
                    child: _buildCurrentSection(),
                  ),
                ),

                // Modern 5-Section Gaming Navigation Bar
                HomeNavigationBar(
                  selectedIndex: _selectedNavIndex,
                  onItemSelected: (idx) {
                    setState(() {
                      _selectedNavIndex = idx;
                    });
                  },
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
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

  // --- Card 1: PLAY WITH FRIENDS (Top Row Left) ---
  Widget _buildPlayWithFriendsCard(BuildContext context) {
    return GameModeCard(
      cardKey: const Key('play_with_friends_card'),
      title: "PLAY WITH FRIENDS",
      height: 144,
      glowColor: const Color(0xFFFFB300),
      accentColor: const Color(0xFFFFD700),
      cardGradient: const [
        Color(0xFF1544A2),
        Color(0xFF0C2B72),
        Color(0xFF040F2D),
      ],
      illustration: const PlayWithFriendsIllustration(),
      onTap: _openFriendsSelection,
    );
  }

  // --- Card 2: PASS N PLAY (Top Row Right) ---
  Widget _buildPassNPlayCard(BuildContext context) {
    return GameModeCard(
      cardKey: const Key('pass_n_play_card'),
      title: "PASS N PLAY",
      height: 144,
      glowColor: const Color(0xFFFFB300),
      accentColor: const Color(0xFFFFD700),
      cardGradient: const [
        Color(0xFF261D5C),
        Color(0xFF141344),
        Color(0xFF060924),
      ],
      illustration: const PassNPlayIllustration(),
      onTap: _openPassNPlaySetup,
    );
  }

  // --- Card 3: PLAY VS COMPUTER (Centered Below Top Row) ---
  Widget _buildPlayVsComputerCard(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Horizontally centered, responsive width, proportionally larger & taller
        final cardWidth = (constraints.maxWidth * 0.74).clamp(205.0, 255.0);
        return SizedBox(
          width: cardWidth,
          child: GameModeCard(
            cardKey: const Key('play_vs_computer_card'),
            title: "PLAY VS COMPUTER",
            height: 172,
            isVertical: true,
            glowColor: const Color(0xFFFFB300),
            accentColor: const Color(0xFFFFD700),
            cardGradient: const [
              Color(0xFF0F265C),
              Color(0xFF08173E),
              Color(0xFF030718),
            ],
            showPedestalShadow: true,
            illustration: const PlayVsComputerIllustration(),
            onTap: () => _startGame(context, GameMode.vsComputer),
          ),
        );
      },
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

  // --- Section Router ---
  Widget _buildCurrentSection() {
    switch (_selectedNavIndex) {
      case 1:
        return const EventSectionView();
      case 2:
        return const AddaSectionView();
      case 3:
        return const InventorySectionView();
      case 4:
        return SocialSectionView(userName: _userName);
      case 5:
        return const SafeAndAdFreeSectionView();
      case 0:
      default:
        return _buildHomeDashboard();
    }
  }

  // --- 1. HOME DASHBOARD ---
  Widget _buildHomeDashboard() {
    return SingleChildScrollView(
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

            // ==========================================
            // GAME MODE CARDS SECTION (3 CARDS)
            // ==========================================

            // TOP ROW: PLAY WITH FRIENDS + PASS N PLAY
            Row(
              children: [
                Expanded(
                  child: _buildPlayWithFriendsCard(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPassNPlayCard(context),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // BELOW (CENTERED): PLAY VS COMPUTER
            Center(
              child: _buildPlayVsComputerCard(context),
            ),

            const SizedBox(height: 22),

            // How to Play & Rules Link
            _buildRulesLink(context),

            const SizedBox(height: 14),
          ],
        ),
      ),
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
          child: FittedBox(
            fit: BoxFit.scaleDown,
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
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PassNPlaySetupScreen(),
      ),
    );
    if (mounted) {
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
