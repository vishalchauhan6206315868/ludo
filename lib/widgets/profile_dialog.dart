import 'package:flutter/material.dart';
import '../models/user_profile_model.dart';
import '../screens/leaderboard_screen.dart';
import '../screens/wallet_screen.dart';
import '../services/auth_service.dart';

/// Interactive Profile Dialog that connects directly to state & backend.
class ProfileDialog extends StatefulWidget {
  final UserProfileModel? initialProfile;
  final ValueChanged<UserProfileModel>? onProfileUpdated;

  const ProfileDialog({
    super.key,
    this.initialProfile,
    this.onProfileUpdated,
  });

  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  UserProfileModel? _profile;
  bool _isLoading = false;
  String? _syncMessage;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
    _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _syncMessage = null;
    });

    try {
      final fresh = await AuthService.fetchUserProfile();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (fresh != null) {
          _profile = fresh;
          _syncMessage = "Profile updated live from server!";
        } else {
          _syncMessage = "Showing cached profile (Server offline)";
        }
      });
      if (fresh != null && widget.onProfileUpdated != null) {
        widget.onProfileUpdated!(fresh);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _syncMessage = "Sync failed. Showing cached profile.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile ??
        const UserProfileModel(
          id: '',
          name: 'Vishal Chauhan',
          email: 'vishalchauhan62063@gmail.com',
          coins: 1000,
          gems: 10,
          level: 1,
        );

    final stats = profile.statistics;

    return PlayerProfileScreen(
      playerName: profile.name.isNotEmpty ? profile.name : 'Vishal Chauhan',
      email: profile.email.isNotEmpty ? profile.email : 'vishalchauhan62063@gmail.com',
      avatar: profile.avatar,
      level: profile.level > 0 ? profile.level : 1,
      coins: profile.coins,
      gems: profile.gems,
      played: stats.totalGames,
      won: stats.wins,
      lost: stats.losses,
      winRate: stats.winRate,
      isOnline: true,
      isLoading: _isLoading,
      syncMessage: _syncMessage,
      onBack: () => Navigator.of(context).pop(),
      onSettingsTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Settings"),
            duration: Duration(milliseconds: 900),
          ),
        );
      },
      onLeaderboardTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
        );
      },
      onWalletTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const WalletScreen()),
        );
      },
      onSync: _isLoading ? null : _refreshProfile,
    );
  }
}

/// Standalone, modular Player Profile Screen UI matching the realistic 3D design.
class PlayerProfileScreen extends StatelessWidget {
  final String playerName;
  final String email;
  final int level;
  final int coins;
  final int gems;
  final int played;
  final int won;
  final int lost;
  final double? winRate;
  final bool isOnline;
  final String avatar;
  final bool isLoading;
  final String? syncMessage;
  final VoidCallback? onBack;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onLeaderboardTap;
  final VoidCallback? onWalletTap;
  final VoidCallback? onSync;

  const PlayerProfileScreen({
    super.key,
    required this.playerName,
    required this.email,
    required this.level,
    required this.coins,
    required this.gems,
    required this.played,
    required this.won,
    required this.lost,
    this.winRate,
    this.isOnline = true,
    this.avatar = '',
    this.isLoading = false,
    this.syncMessage,
    this.onBack,
    this.onSettingsTap,
    this.onLeaderboardTap,
    this.onWalletTap,
    this.onSync,
  });

  // ── Palette Constants ─────────────────────────────────────────────
  static const Color _bgDeep = Color(0xFF030A1C);
  static const Color _bgNavy = Color(0xFF071738);
  static const Color _electricBlue = Color(0xFF1B6BF3);
  static const Color _gold = Color(0xFFFFC727);
  static const Color _goldLight = Color(0xFFFFE566);
  static const Color _green = Color(0xFF00E676);
  static const Color _cyan = Color(0xFF00D2FF);
  static const Color _pink = Color(0xFFFF3366);
  static const Color _subtleText = Color(0xFF8FA7D0);

  @override
  Widget build(BuildContext context) {
    final double calculatedWinRate = winRate ??
        (played > 0 ? ((won / played) * 100).clamp(0.0, 100.0) : 0.0);

    return Scaffold(
      backgroundColor: _bgDeep,
      body: Stack(
        children: [
          // Background Cosmic Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.6),
                  radius: 1.4,
                  colors: [
                    Color(0xFF0F2656),
                    _bgNavy,
                    _bgDeep,
                  ],
                ),
              ),
            ),
          ),

          // Ambient Background Glow Circles
          Positioned(
            top: 60,
            left: -80,
            child: _buildGlowSphere(const Color(0xFF1555B8), 240),
          ),
          Positioned(
            top: 280,
            right: -90,
            child: _buildGlowSphere(const Color(0xFF007EAA), 220),
          ),
          Positioned(
            bottom: 40,
            left: -60,
            child: _buildGlowSphere(const Color(0xFF144D99), 200),
          ),

          // Faint Decorative Background Ludo Corner Graphics
          Positioned(
            bottom: -30,
            left: -30,
            width: 140,
            height: 140,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.14,
                child: Image.asset(
                  'assets/images/ludo_supreme_bg.jpg',
                  fit: BoxFit.cover,
                  cacheWidth: 280,
                  cacheHeight: 280,
                  errorBuilder: (_, _, _) => const SizedBox(),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            right: -30,
            width: 140,
            height: 140,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.14,
                child: Image.asset(
                  'assets/images/ludo_supreme_bg.jpg',
                  fit: BoxFit.cover,
                  cacheWidth: 280,
                  cacheHeight: 280,
                  errorBuilder: (_, _, _) => const SizedBox(),
                ),
              ),
            ),
          ),

          // Main Scrollable Body
          SafeArea(
            child: Column(
              children: [
                // Fixed Header Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: _buildTopBar(context),
                ),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeroCard(),
                        const SizedBox(height: 16),
                        _buildCurrencyRow(),
                        const SizedBox(height: 16),
                        _buildMatchStatistics(calculatedWinRate),
                        const SizedBox(height: 16),
                        _buildMotivationBanner(),
                        if (syncMessage != null && syncMessage!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildSyncMessageBadge(),
                        ],
                        const SizedBox(height: 16),
                        _buildSyncButton(),
                        const SizedBox(height: 10),
                      ],
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

  // ── Glow Sphere ──────────────────────────────────────────────────
  Widget _buildGlowSphere(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.28),
              color.withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  // ── Top Navigation Bar ────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back Button
        _buildCircularButton(
          icon: Icons.arrow_back_ios_new_rounded,
          iconSize: 18,
          onTap: onBack ?? () => Navigator.of(context).pop(),
        ),

        // Title with Trophy
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              color: _gold,
              size: 28,
            ),
            const SizedBox(width: 8),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Player ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  TextSpan(
                    text: 'Profile',
                    style: const TextStyle(
                      color: _gold,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Settings Button
        _buildCircularButton(
          icon: Icons.settings_rounded,
          iconSize: 22,
          onTap: onSettingsTap,
        ),
      ],
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required double iconSize,
    VoidCallback? onTap,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF133670), Color(0xFF0A1F45)],
        ),
        border: Border.all(color: const Color(0xFF225CB8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1855B8).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: Icon(icon, color: Colors.white, size: iconSize),
          ),
        ),
      ),
    );
  }

  // ── Hero Player Card ─────────────────────────────────────────────
  Widget _buildHeroCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _electricBlue, width: 1.6),
        boxShadow: [
          BoxShadow(
            color: _electricBlue.withValues(alpha: 0.30),
            blurRadius: 22,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            // Dark Container Gradient Background
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF0C2454),
                      Color(0xFF08183B),
                      Color(0xFF040E24),
                    ],
                  ),
                ),
              ),
            ),

            // Top 3D Ludo Backdrop (Pawns & Dice Scene Art)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 140,
              child: Opacity(
                opacity: 0.32,
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Colors.transparent],
                  ).createShader(bounds),
                  blendMode: BlendMode.dstIn,
                  child: Image.asset(
                    'assets/images/ludo_supreme_bg.jpg',
                    fit: BoxFit.cover,
                    cacheWidth: 800,
                    alignment: Alignment.topCenter,
                    errorBuilder: (_, _, _) => const SizedBox(),
                  ),
                ),
              ),
            ),

            // Subtle Sparkle Stars on card sides
            const Positioned(
              top: 36,
              left: 36,
              child: _SparkleStar(size: 16, color: Color(0xFF63A1FF)),
            ),
            const Positioned(
              top: 48,
              right: 42,
              child: _SparkleStar(size: 14, color: _goldLight),
            ),

            // Card Inner Content Column
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
              child: Column(
                children: [
                  // Avatar with Golden Crown, Wings, and Level Badge
                  _buildAvatarCrest(),
                  const SizedBox(height: 12),

                  // Player Name
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      playerName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),

                  // Email Row
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.mail_outline_rounded,
                          color: _subtleText,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            email,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _subtleText,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Online Status Badge Pill
                  _buildOnlinePill(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Avatar Crest with Golden Wings, Crown, & Level ────────────────
  Widget _buildAvatarCrest() {
    return SizedBox(
      width: 200,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Golden Wings on Left and Right
          Positioned(
            top: 38,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 70,
              child: CustomPaint(
                painter: _GoldenWingsPainter(),
              ),
            ),
          ),

          // Circular Golden Avatar Frame
          Positioned(
            top: 26,
            child: Container(
              width: 104,
              height: 104,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFF275),
                    Color(0xFFFFB800),
                    Color(0xFFFF8C00),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _gold.withValues(alpha: 0.65),
                    blurRadius: 26,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF144D9C), Color(0xFF091F46)],
                  ),
                ),
                child: ClipOval(
                  child: avatar.isNotEmpty
                      ? Image.network(
                          avatar,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Center(
                            child: Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 64,
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 64,
                          ),
                        ),
                ),
              ),
            ),
          ),

          // Crown on Top
          Positioned(
            top: 2,
            child: _buildCrown(),
          ),

          // Level Capsule Badge (Overlapping Bottom)
          Positioned(
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFE566), Color(0xFFFF9E00)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFF7B2), width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: _gold.withValues(alpha: 0.45),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'LVL $level',
                style: const TextStyle(
                  color: Color(0xFF0F1728),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Realistic 3D Golden Crown Widget ─────────────────────────────
  Widget _buildCrown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: 0.6),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF694), Color(0xFFFFB800), Color(0xFFFFA000)],
        ).createShader(bounds),
        child: const Icon(
          Icons.workspace_premium_rounded,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }

  // ── Online Status Pill ───────────────────────────────────────────
  Widget _buildOnlinePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isOnline
            ? const Color(0xFF003823).withValues(alpha: 0.55)
            : const Color(0xFF381F23).withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOnline ? _green : _pink,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isOnline ? _green : _pink).withValues(alpha: 0.20),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline ? _green : _pink,
              boxShadow: [
                BoxShadow(
                  color: isOnline ? _green : _pink,
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              color: isOnline ? _green : _pink,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Currency Row (Coins & Gems) ───────────────────────────────────
  Widget _buildCurrencyRow() {
    return Row(
      children: [
        // Coins Card
        Expanded(
          child: _buildCurrencyCard(
            title: 'Coins',
            amount: coins,
            accentColor: _gold,
            iconWidget: const _CoinsStackIcon(),
            onTap: onWalletTap,
          ),
        ),
        const SizedBox(width: 12),
        // Gems Card
        Expanded(
          child: _buildCurrencyCard(
            title: 'Gems',
            amount: gems,
            accentColor: _cyan,
            iconWidget: const _CyanGemIcon(),
            onTap: null,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyCard({
    required String title,
    required int amount,
    required Color accentColor,
    required Widget iconWidget,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor.withValues(alpha: 0.16),
                const Color(0xFF091A38),
                const Color(0xFF051126),
              ],
            ),
            border: Border.all(color: accentColor, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.14),
                blurRadius: 14,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              // 3D Currency Graphic Icon
              iconWidget,
              const SizedBox(width: 10),

              // Title and Amount
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _subtleText,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        amount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Chevron Right
              Icon(
                Icons.chevron_right_rounded,
                color: accentColor,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Match Statistics Card ─────────────────────────────────────────
  Widget _buildMatchStatistics(double winRateVal) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0D2554),
            Color(0xFF07193C),
            Color(0xFF041028),
          ],
        ),
        border: Border.all(color: const Color(0xFF1B55AA), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF154894).withValues(alpha: 0.22),
            blurRadius: 18,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Row with Bar Chart and Leaderboard Button
          Row(
            children: [
              const _GoldBarsIcon(),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Match Statistics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              _buildLeaderboardButton(),
            ],
          ),
          const SizedBox(height: 18),

          // 4 Columns: Played, Won, Lost, Win Rate
          Row(
            children: [
              _buildStatColumn(
                icon: Icons.sports_esports_rounded,
                value: played.toString(),
                label: 'Played',
                color: const Color(0xFF3B8CFF),
              ),
              _buildStatColumn(
                icon: Icons.emoji_events_rounded,
                value: won.toString(),
                label: 'Won',
                color: _green,
              ),
              _buildStatColumn(
                icon: Icons.heart_broken_rounded,
                value: lost.toString(),
                label: 'Lost',
                color: _pink,
              ),
              _buildStatColumn(
                icon: Icons.auto_awesome_rounded,
                value: '${winRateVal.toStringAsFixed(0)}%',
                label: 'Win Rate',
                color: _gold,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onLeaderboardTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: _gold.withValues(alpha: 0.08),
            border: Border.all(color: _gold, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: _gold.withValues(alpha: 0.15),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events_rounded, color: _gold, size: 16),
              SizedBox(width: 4),
              Text(
                'Leaderboard',
                style: TextStyle(
                  color: _gold,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded, color: _gold, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(
                color: _subtleText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Motivation Banner ─────────────────────────────────────────────
  Widget _buildMotivationBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF023631),
            Color(0xFF04243A),
            Color(0xFF061E34),
          ],
        ),
        border: Border.all(color: const Color(0xFF00E5A3), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5A3).withValues(alpha: 0.18),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        children: [
          // Concentric Glowing Bullseye Target Icon
          const _BullseyeTargetIcon(),
          const SizedBox(width: 14),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Great players ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      TextSpan(
                        text: 'never stop!',
                        style: const TextStyle(
                          color: _gold,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Play more  •  Win more  •  Be a Champion',
                  style: TextStyle(
                    color: Color(0xFF94E7D6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Decorative Star Accent
          const _SparkleStar(size: 14, color: _goldLight),
        ],
      ),
    );
  }

  // ── Sync Message Badge ────────────────────────────────────────────
  Widget _buildSyncMessageBadge() {
    final isLive = syncMessage!.toLowerCase().contains("live");
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: (isLive ? _green : _gold).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (isLive ? _green : _gold).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Text(
          syncMessage!,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isLive ? _green : _gold,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ── Sync Button ("Sync from Server") ──────────────────────────────
  Widget _buildSyncButton() {
    return Container(
      height: 62,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(31),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFF266),
            Color(0xFFFFB800),
            Color(0xFFFF9400),
          ],
        ),
        border: Border.all(color: const Color(0xFFFFF68A), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: 0.40),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(31),
          onTap: onSync,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Sync Icon or Spinner
                SizedBox(
                  width: 34,
                  height: 34,
                  child: Center(
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.8,
                              color: Color(0xFF101726),
                            ),
                          )
                        : const Icon(
                            Icons.sync_rounded,
                            color: Color(0xFF101726),
                            size: 30,
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Button Title & Endpoint Subtitle
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLoading ? 'Syncing Profile...' : 'Sync from Server',
                        style: const TextStyle(
                          color: Color(0xFF101726),
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 1),
                      const Text(
                        '/api/users/me',
                        style: TextStyle(
                          color: Color(0xFF5E4200),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                // Chevron Right
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF101726),
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom 3D Visual CustomPainters & Widgets for Realistic Fidelity
// ─────────────────────────────────────────────────────────────────────────────

/// Custom Painter for golden curved laurel wings flanking the avatar
class _GoldenWingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFEB7A),
          Color(0xFFFFB300),
          Color(0xFFFF8F00),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final centerY = size.height * 0.55;
    final centerX = size.width * 0.5;

    // Left Wing
    final leftPath = Path()
      ..moveTo(centerX - 46, centerY - 6)
      ..cubicTo(
        centerX - 72,
        centerY - 22,
        centerX - 92,
        centerY - 10,
        centerX - 96,
        centerY + 10,
      )
      ..cubicTo(
        centerX - 85,
        centerY + 8,
        centerX - 72,
        centerY + 16,
        centerX - 48,
        centerY + 8,
      )
      ..close();

    // Right Wing
    final rightPath = Path()
      ..moveTo(centerX + 46, centerY - 6)
      ..cubicTo(
        centerX + 72,
        centerY - 22,
        centerX + 92,
        centerY - 10,
        centerX + 96,
        centerY + 10,
      )
      ..cubicTo(
        centerX + 85,
        centerY + 8,
        centerX + 72,
        centerY + 16,
        centerX + 48,
        centerY + 8,
      )
      ..close();

    // Draw with subtle drop shadow
    canvas.drawShadow(leftPath, const Color(0xFFFFB300), 8, false);
    canvas.drawShadow(rightPath, const Color(0xFFFFB300), 8, false);

    canvas.drawPath(leftPath, paint);
    canvas.drawPath(rightPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3D Stack of Gold Coins Icon Graphic
class _CoinsStackIcon extends StatelessWidget {
  const _CoinsStackIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Base Coin Glow
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.55),
                  blurRadius: 14,
                ),
              ],
            ),
          ),
          // Back Coin
          Positioned(
            left: 2,
            top: 4,
            child: _buildSingleCoin(size: 30),
          ),
          // Front Coin
          Positioned(
            right: 2,
            bottom: 4,
            child: _buildSingleCoin(size: 32, isFront: true),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleCoin({required double size, bool isFront = false}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF275),
            Color(0xFFFFB800),
            Color(0xFFFF8C00),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFFFF8B2),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Container(
          width: size * 0.72,
          height: size * 0.72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFCCA000),
              width: 1.2,
            ),
          ),
          child: Center(
            child: Text(
              '\$',
              style: TextStyle(
                color: const Color(0xFF8B6000),
                fontSize: size * 0.42,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 3D Brilliant Cyan Diamond / Gem Graphic
class _CyanGemIcon extends StatelessWidget {
  const _CyanGemIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D2FF).withValues(alpha: 0.60),
            blurRadius: 16,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _FacetedGemPainter(),
      ),
    );
  }
}

/// Custom Painter for brilliant faceted cyan gem
class _FacetedGemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Top horizontal table polygon
    final topPath = Path()
      ..moveTo(w * 0.28, h * 0.22)
      ..lineTo(w * 0.72, h * 0.22)
      ..lineTo(w * 0.88, h * 0.48)
      ..lineTo(w * 0.12, h * 0.48)
      ..close();

    final topPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFB0F4FF), Color(0xFF00D4FF)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // Bottom pavilion pyramid polygon
    final bottomPath = Path()
      ..moveTo(w * 0.12, h * 0.48)
      ..lineTo(w * 0.88, h * 0.48)
      ..lineTo(w * 0.50, h * 0.88)
      ..close();

    final bottomPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF00D4FF), Color(0xFF0072B8)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // Center faceted specular highlight triangle
    final centerFacet = Path()
      ..moveTo(w * 0.40, h * 0.22)
      ..lineTo(w * 0.60, h * 0.22)
      ..lineTo(w * 0.50, h * 0.88)
      ..close();

    final facetPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    canvas.drawPath(topPath, topPaint);
    canvas.drawPath(bottomPath, bottomPaint);
    canvas.drawPath(centerFacet, facetPaint);

    // Outline stroke
    final strokePaint = Paint()
      ..color = const Color(0xFFD6FAFF)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawPath(topPath, strokePaint);
    canvas.drawPath(bottomPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3D Concentric Bullseye Target Icon in Neon Green
class _BullseyeTargetIcon extends StatelessWidget {
  const _BullseyeTargetIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF00382B),
        border: Border.all(color: const Color(0xFF00E5A3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5A3).withValues(alpha: 0.45),
            blurRadius: 12,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF00E5A3), width: 1.6),
          ),
          child: Center(
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0xFF75FFD8), Color(0xFF00C286)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 3D Gold Bar Chart Icon for Match Statistics
class _GoldBarsIcon extends StatelessWidget {
  const _GoldBarsIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      height: 26,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _bar(height: 10),
          _bar(height: 17),
          _bar(height: 24),
        ],
      ),
    );
  }

  Widget _bar({required double height}) {
    return Container(
      width: 5.5,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF070), Color(0xFFFFB800)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB800).withValues(alpha: 0.5),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}

/// Subtle Decorative Sparkle Star Widget
class _SparkleStar extends StatelessWidget {
  final double size;
  final Color color;

  const _SparkleStar({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.auto_awesome,
      size: size,
      color: color,
    );
  }
}
