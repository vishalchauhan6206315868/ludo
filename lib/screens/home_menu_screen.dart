import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/network/api_service.dart';
import '../models/game_state.dart';
import '../models/room_model.dart';
import '../models/user_profile_model.dart';
import '../services/app_update_service.dart';
import '../services/auth_service.dart';
import '../services/game_storage_service.dart';
import '../widgets/game_mode_card.dart';
import '../widgets/home_navigation_sections.dart';
import '../widgets/player_selection_dialog.dart';
import '../widgets/profile_dialog.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/team_up_setup_dialog.dart';
import 'game_screen.dart';
import 'leaderboard_screen.dart';
import 'login_screen.dart';
import 'rewards_screen.dart';
import 'wallet_screen.dart';
import 'online/online_game_selection_screen.dart';
import 'pass_n_play_setup_screen.dart';

class HomeMenuScreen extends StatefulWidget {
  const HomeMenuScreen({super.key});

  @override
  State<HomeMenuScreen> createState() => _HomeMenuScreenState();
}

class _HomeMenuScreenState extends State<HomeMenuScreen> {
  String _userName = 'Ludo Master';
  UserProfileModel? _userProfile;
  bool _hasSavedMatch = false;
  GameState? _savedState;
  int _selectedNavIndex = 0; // 0: HOME, 1: EVENT, 2: ADDA, 3: INVENTORY, 4: SOCIAL

  static const SystemUiOverlayStyle _systemUiOverlayStyle =
      SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Color(0xFF060C1B),
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarDividerColor: Color(0xFF060C1B),
    systemNavigationBarContrastEnforced: false,
  );

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(_systemUiOverlayStyle);
    _loadUserInfo();
    _checkSavedGame();
    _checkActiveOnlineMatch();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppUpdateService.checkForUpdate(context);
      }
    });
  }

  /// App was closed / killed during an online match: offer to jump back into it.
  Future<void> _checkActiveOnlineMatch() async {
    try {
      if (!await AuthService.isLoggedIn()) return;
      final res = await ApiService().getMyActiveRoom();
      if (!mounted || res['success'] != true || res['data'] is! Map<String, dynamic>) return;
      final data = res['data'] as Map<String, dynamic>;
      if (data['room'] == null) return;

      final room = RoomModel.fromJson(data);
      // only a running match; a waiting lobby is handled by the normal create / join flow
      if (!room.hasMatch || room.status.toLowerCase() != 'playing') return;

      final rejoin = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF0F1B38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
          ),
          title: const Text("Match in progress",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text(
            "You have an online match running. Rejoin to continue playing?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Forfeit", style: TextStyle(color: Colors.redAccent)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black87,
              ),
              child: const Text("Rejoin"),
            ),
          ],
        ),
      );
      if (!mounted || rejoin == null) return;

      if (rejoin) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GameScreen(
              mode: room.maxPlayers >= 4
                  ? GameMode.fourPlayer
                  : (room.maxPlayers == 3 || room.gameMode == 'threePlayer'
                      ? GameMode.threePlayer
                      : GameMode.twoPlayer),
              sessionId: room.sessionId,
              roomCode: room.roomCode,
              isOnlineMatch: true,
              isHost: data['isHost'] == true,
              mySeatIndex: room.seatIndex ?? 0,
            ),
          ),
        );
      } else {
        await ApiService().surrenderGame(sessionId: room.sessionId!);
      }
    } catch (e) {
      debugPrint('Active online match check failed: $e');
    }
  }

  Future<void> _loadUserInfo() async {
    // 1. Instant load from local storage
    final cached = await AuthService.getCachedUserProfile();
    if (mounted && cached != null) {
      setState(() {
        _userProfile = cached;
        if (cached.name.isNotEmpty && cached.name != 'Player') {
          _userName = cached.name;
        }
      });
    }

    // 2. Fetch fresh live profile from /api/users/me
    final live = await AuthService.fetchUserProfile();
    if (mounted && live != null) {
      setState(() {
        _userProfile = live;
        if (live.name.isNotEmpty && live.name != 'Player') {
          _userName = live.name;
        }
      });
    }
  }

  void _openProfileDialog() {
    showDialog(
      context: context,
      builder: (_) => ProfileDialog(
        initialProfile: _userProfile,
        onProfileUpdated: (updated) {
          setState(() {
            _userProfile = updated;
            if (updated.name.isNotEmpty) {
              _userName = updated.name;
            }
          });
        },
      ),
    );
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

  bool _isExitDialogOpen = false;

  Future<void> _handleBackPress() async {
    // If on a secondary tab, return smoothly to the main Home tab first
    if (_selectedNavIndex != 0) {
      setState(() {
        _selectedNavIndex = 0;
      });
      return;
    }

    if (_isExitDialogOpen || !mounted) return;
    _isExitDialogOpen = true;

    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.all(2.6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFF8C2),
                Color(0xFFFFCA28),
                Color(0xFFB26A00),
                Color(0xFFFFE082),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFCA28).withValues(alpha: 0.35),
                blurRadius: 20,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.72),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF142B78),
                  Color(0xFF09174A),
                  Color(0xFF060E30),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFF59D), Color(0xFFFFCA28), Color(0xFFFF8F00)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFCA28).withValues(alpha: 0.45),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.exit_to_app_rounded,
                    color: Color(0xFF3E1800),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  "Exit Game?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFFF5C0),
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Are you sure you want to exit Ludo Supreme?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0288D1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(
                              color: Color(0xFF80D8FF),
                              width: 1.4,
                            ),
                          ),
                        ),
                        child: const Text(
                          "No, Stay",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB300),
                          foregroundColor: const Color(0xFF3E1800),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(
                              color: Color(0xFFFFF8C2),
                              width: 1.4,
                            ),
                          ),
                        ),
                        child: const Text(
                          "Yes, Exit",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    _isExitDialogOpen = false;

    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: _systemUiOverlayStyle,
        child: MediaQuery.withClampedTextScaling(
        minScaleFactor: 0.85,
        maxScaleFactor: 1.15,
        child: Scaffold(
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
                bottom: false,
                child: Column(
                  children: [
                    // Top Header Bar
                    _buildHeaderBar(context),

                    // Dynamic Section Content
                    Expanded(
                      child: _buildCurrentSection(),
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
        ),
      ),
    ),
    );
  }

  // --- Top Header Bar ---
  Widget _buildHeaderBar(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 440;
    final coins = _userProfile?.coins ?? 1000;
    final avatarUrl = _userProfile?.avatar;

    // Compact coins text formatting
    String formattedCoins;
    if (coins >= 1000000) {
      formattedCoins = "${(coins / 1000000).toStringAsFixed(1)}M";
    } else if (coins >= 10000) {
      formattedCoins = "${(coins / 1000).toStringAsFixed(1)}k";
    } else {
      formattedCoins = coins.toString();
    }

    final avatarSize = isCompact ? 36.0 : 44.0;
    final actionBtnSize = isCompact ? 34.0 : 42.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 20,
        vertical: isCompact ? 6 : 10,
      ),
      child: Row(
        children: [
          // Profile Avatar with Golden Ring (Clickable -> Opens Profile Dialog)
          GestureDetector(
            onTap: _openProfileDialog,
            child: Tooltip(
              message: "View Profile",
              child: Container(
                width: avatarSize,
                height: avatarSize,
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
                child: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? ClipOval(
                        child: Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.person,
                            color: const Color(0xFFFFD700),
                            size: isCompact ? 22 : 26,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.person,
                        color: const Color(0xFFFFD700),
                        size: isCompact ? 22 : 26,
                      ),
              ),
            ),
          ),
          SizedBox(width: isCompact ? 8 : 12),

          // User Greeting & Subtitle (Clickable -> Opens Profile Dialog)
          Expanded(
            child: GestureDetector(
              onTap: _openProfileDialog,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: isCompact ? 14 : 16,
                        fontFamily: 'Roboto',
                      ),
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
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "LVL ${_userProfile?.level ?? 1}",
                            style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!isCompact) ...[
                          const SizedBox(width: 4),
                          const Text(
                            "• Stats",
                            style: TextStyle(
                              color: Color(0xFF90A4AE),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Coins Chip (Clickable -> Opens Wallet Screen)
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WalletScreen(
                    onWalletUpdated: _loadUserInfo,
                  ),
                ),
              );
              _loadUserInfo();
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 8 : 10,
                vertical: isCompact ? 5 : 6,
              ),
              margin: EdgeInsets.only(right: isCompact ? 5 : 8),
              decoration: BoxDecoration(
                color: const Color(0xFF141F36),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.monetization_on_rounded,
                      color: const Color(0xFFFFD700),
                      size: isCompact ? 14 : 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formattedCoins,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isCompact ? 11 : 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Action: Rewards Button (On regular / wide screens)
          if (!isCompact) ...[
            _buildActionButton(
              size: actionBtnSize,
              iconSize: isCompact ? 18 : 20,
              icon: Icons.card_giftcard_rounded,
              tooltip: "Rewards",
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RewardsScreen(
                      onRewardClaimed: _loadUserInfo,
                    ),
                  ),
                );
                _loadUserInfo();
              },
            ),
            SizedBox(width: isCompact ? 6 : 8),
          ],

          // Action 1: Leaderboard Button
          _buildActionButton(
            size: actionBtnSize,
            iconSize: isCompact ? 18 : 20,
            icon: Icons.leaderboard_rounded,
            tooltip: "Leaderboard",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LeaderboardScreen(),
                ),
              );
            },
          ),
          SizedBox(width: isCompact ? 5 : 8),

          // Action 2: Settings Button
          _buildActionButton(
            size: actionBtnSize,
            iconSize: isCompact ? 18 : 20,
            icon: Icons.settings_rounded,
            tooltip: "Settings",
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => const SettingsDialog(),
              );
            },
          ),
          SizedBox(width: isCompact ? 5 : 8),

          // Action 3: Exit / Logout Button
          _buildActionButton(
            size: actionBtnSize,
            iconSize: isCompact ? 18 : 20,
            icon: Icons.logout_rounded,
            tooltip: "Exit Game",
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    double size = 42,
    double iconSize = 20,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF162038).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(size * 0.28),
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
          borderRadius: BorderRadius.circular(size * 0.28),
          onTap: onTap,
          child: Icon(icon, color: const Color(0xFFECEFF1), size: iconSize),
        ),
      ),
    );
  }

  // --- Center 3D Card Emblem on Glowing Pedestal with Crown ---
  Widget _buildHeroEmblem({double scale = 1.0}) {
    final emblem = SizedBox(
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

    if (scale != 1.0) {
      return Transform.scale(
        scale: scale,
        child: emblem,
      );
    }
    return emblem;
  }

  // --- Branding Title ---
  Widget _buildBrandingTitle({bool isShort = false}) {
    return Column(
      children: [
        // Mini Golden Crown
        Icon(
          Icons.military_tech_rounded,
          color: const Color(0xFFFFD700),
          size: isShort ? 16 : 20,
        ),
        const SizedBox(height: 2),

        // LUDO SUPREME 3D Metallic Text
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "LUDO ",
                style: TextStyle(
                  color: const Color(0xFFEDEDED),
                  fontSize: isShort ? 26 : 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                  shadows: const [
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
                child: Text(
                  "SUPREME",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isShort ? 26 : 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                    shadows: const [
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
        Text(
          "THE CLASSIC BOARD GAME EXPERIENCE",
          style: TextStyle(
            color: const Color(0xFFB0BEC5),
            fontSize: isShort ? 9.5 : 11,
            fontWeight: FontWeight.w700,
            letterSpacing: isShort ? 1.6 : 2.2,
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

  // --- Card 1: PLAY WITH FRIENDS (First Row Left) ---
   Widget _buildPlayWithFriendsCard(BuildContext context, [double height = 136]) {
     return GameModeCard(
       cardKey: const Key('play_with_friends_card'),
      title: "PLAY WITH FRIENDS",
      height: height,
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


  // --- Card 2: ONLINE (First Row Middle) ---
  Widget _buildOnlineCard(BuildContext context, [double height = 136]) {
    return GameModeCard(
      cardKey: const Key('online_card'),
      title: "ONLINE",
      height: height,
      glowColor: const Color(0xFF00E5FF),
      accentColor: const Color(0xFF80D8FF),
      cardGradient: const [
        Color(0xFF0E4EAE),
        Color(0xFF093175),
        Color(0xFF031438),
      ],
      illustration: const OnlineIllustration(),
      onTap: () => _openOnlineMode(context),
    );
  }

  // --- Card 3: TEAM UP (First Row Right) ---
  Widget _buildTeamUpCard(BuildContext context, [double height = 136]) {
    return GameModeCard(
      cardKey: const Key('team_up_card'),
      title: "TEAM UP",
      height: height,
      glowColor: const Color(0xFFFFB300),
      accentColor: const Color(0xFFFFD700),
      cardGradient: const [
        Color(0xFF1E3898),
        Color(0xFF122266),
        Color(0xFF060D2D),
      ],
      illustration: const TeamUpIllustration(),
      onTap: () => _openTeamUpMode(context),
    );
  }

  // --- Card 4: PLAY VS COMPUTER (Second Row Left - Centered) ---
  Widget _buildPlayVsComputerCard(BuildContext context, [double height = 136]) {
    return GameModeCard(
      cardKey: const Key('play_vs_computer_card'),
      title: "PLAY VS COMPUTER",
      height: height,
      glowColor: const Color(0xFFFFB300),
      accentColor: const Color(0xFFFFD700),
      cardGradient: const [
        Color(0xFF0F265C),
        Color(0xFF08173E),
        Color(0xFF030718),
      ],
      illustration: const PlayVsComputerIllustration(),
      onTap: () => _startGame(context, GameMode.vsComputer),
    );
  }

  // --- Card 5: PASS N PLAY (Second Row Right - Centered) ---
  Widget _buildPassNPlayCard(BuildContext context, [double height = 136]) {
    return GameModeCard(
      cardKey: const Key('pass_n_play_card'),
      title: "PASS N PLAY",
      height: height,
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

  // --- Game Modes Section: 3 in First Row, 2 Centered in Second Row ---
  Widget _buildGameModesSection(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = constraints.maxWidth < 350 ? 8.0 : 10.0;
        final rowSpacing = constraints.maxWidth < 350 ? 12.0 : 14.0;
        final cardWidth = (constraints.maxWidth - (2 * spacing)) / 3;
        final cardHeight = (cardWidth * 1.20).clamp(124.0, 144.0);

        return Column(
          children: [
            // FIRST ROW — THREE CARDS HORIZONTALLY
            Row(
              children: [
                Expanded(
                  child: _buildPlayWithFriendsCard(context, cardHeight),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: _buildOnlineCard(context, cardHeight),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: _buildTeamUpCard(context, cardHeight),
                ),
              ],
            ),

            SizedBox(height: rowSpacing),

            // SECOND ROW — TWO CARDS HORIZONTALLY AND CENTERED
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _buildPlayVsComputerCard(context, cardHeight),
                  ),
                  SizedBox(width: spacing),
                  SizedBox(
                    width: cardWidth,
                    child: _buildPassNPlayCard(context, cardHeight),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _openOnlineMode(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const OnlineGameSelectionScreen(),
      ),
    );
  }

  void _openTeamUpMode(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const TeamUpSetupDialog(),
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
        return EventSectionView(
          onRewardClaimed: _loadUserInfo,
        );
      case 2:
        return AddaSectionView(
          onHostTable: _openFriendsSelection,
        );
      case 3:
        return InventorySectionView(
          onInventoryUpdated: _loadUserInfo,
        );
      case 4:
        return SocialSectionView(
          userName: _userName,
          onProfileUpdated: _loadUserInfo,
          onOpenProfile: _openProfileDialog,
        );
      case 5:
        return const SafeAndAdFreeSectionView();
      case 0:
      default:
        return _buildHomeDashboard();
    }
  }

  // --- 1. HOME DASHBOARD ---
  Widget _buildHomeDashboard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isShortScreen = constraints.maxHeight < 640;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth < 360 ? 12 : 20,
            vertical: isShortScreen ? 4 : 8,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
              maxWidth: 440,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 3D Emblem & Pedestal
                _buildHeroEmblem(scale: isShortScreen ? 0.85 : 1.0),

                SizedBox(height: isShortScreen ? 6 : 12),

                // Branding Title (LUDO SUPREME + Tagline)
                _buildBrandingTitle(isShort: isShortScreen),

                SizedBox(height: isShortScreen ? 8 : 16),

                // 4-Color Player Indicator Dots & Glowing Divider
                _buildColorDotsWithSlider(),

                SizedBox(height: isShortScreen ? 14 : 24),

                // Resume Match Card (if exists)
                if (_hasSavedMatch && _savedState != null) ...[
                  _buildResumeCard(context, _savedState!),
                  SizedBox(height: isShortScreen ? 10 : 16),
                ],

                // ==========================================
                // GAME MODE CARDS SECTION (3 + 2 Centered)
                // ==========================================
                _buildGameModesSection(context),

                SizedBox(height: isShortScreen ? 14 : 22),

                // How to Play & Rules Link
                _buildRulesLink(context),

                SizedBox(height: isShortScreen ? 8 : 14),
              ],
            ),
          ),
        );
      },
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
    final result = await showDialog<dynamic>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const PlayerSelectionDialog(),
    );

    if (result != null && mounted) {
      if (result is GameMode) {
        _startGame(context, result);
      } else if (result is Map) {
        final mode = result['mode'] as GameMode? ?? GameMode.twoPlayer;
        final sessionId = result['sessionId'] as String?;
        final roomCode = result['roomCode'] as String?;
        final isOnlineMatch = result['isOnlineMatch'] as bool? ?? (sessionId != null && sessionId.isNotEmpty);
        final isHost = result['isHost'] as bool? ?? true;
        final mySeatIndex = result['mySeatIndex'] as int? ?? (isHost ? 0 : 1);
        _startGame(
          context,
          mode,
          null,
          sessionId,
          roomCode,
          isOnlineMatch,
          isHost,
          mySeatIndex,
        );
      }
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
      case GameMode.teamUp:
        return "Team Up (2v2)";
    }
  }

  Future<void> _startGame(
    BuildContext context,
    GameMode mode, [
    GameState? state,
    String? sessionId,
    String? roomCode,
    bool isOnlineMatch = false,
    bool isHost = true,
    int mySeatIndex = 0,
  ]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          mode: mode,
          restoredState: state,
          sessionId: sessionId,
          roomCode: roomCode,
          isOnlineMatch: isOnlineMatch,
          isHost: isHost,
          mySeatIndex: mySeatIndex,
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

