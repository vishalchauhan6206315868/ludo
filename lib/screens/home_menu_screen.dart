import 'dart:math' as math;
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
import '../widgets/logout_dialog.dart';
import '../widgets/player_selection_dialog.dart';
import '../widgets/profile_dialog.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/team_up_setup_dialog.dart';
import '../widgets/tournaments_dialog.dart';
import '../widgets/tournament_payment_dialog.dart';
import 'game_screen.dart';
import 'leaderboard_screen.dart';
import 'login_screen.dart';
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
              mySeatIndex: room.seatIndex ?? (data['isHost'] == true ? 0 : 1),
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
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => const LogoutDialog(),
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
                  cacheWidth: 1080,
                  filterQuality: FilterQuality.medium,
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
          // Profile Avatar with Golden Ring & Mini Imperial Crown on Top-Left
          GestureDetector(
            onTap: _openProfileDialog,
            child: Tooltip(
              message: "View Profile",
              child: SizedBox(
                width: avatarSize + 6,
                height: avatarSize + 6,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Avatar Ring with Radiant Golden Aura
                    Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF141F36),
                        border: Border.all(color: const Color(0xFFFFD700), width: 1.8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.45),
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

                    // Mini Golden Imperial Crown Perched on Top-Left
                    Positioned(
                      top: -6,
                      left: -4,
                      child: Transform.rotate(
                        angle: -0.25,
                        child: Icon(
                          Icons.military_tech_rounded,
                          color: const Color(0xFFFFD700),
                          size: isCompact ? 16 : 20,
                          shadows: const [
                            Shadow(color: Color(0xFFFFB300), blurRadius: 6),
                            Shadow(color: Colors.black87, blurRadius: 3, offset: Offset(0, 1)),
                          ],
                        ),
                      ),
                    ),
                  ],
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8E24AA), Color(0xFF5E1275)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFD700), width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFAB47BC).withValues(alpha: 0.35),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 12),
                          const SizedBox(width: 3),
                          Text(
                            "LVL ${_userProfile?.level ?? 1}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
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
                horizontal: isCompact ? 7 : 10,
                vertical: isCompact ? 4 : 5.5,
              ),
              margin: EdgeInsets.only(right: isCompact ? 5 : 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF142448),
                    Color(0xFF09142A),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFFD700),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                    blurRadius: 8,
                    spreadRadius: 0.5,
                  ),
                  const BoxShadow(
                    color: Colors.black45,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Golden Rupee Coin
                    Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFF9C4), Color(0xFFFFB300), Color(0xFFFF8F00)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x66FFB300),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          "₹",
                          style: TextStyle(
                            color: Color(0xFF3E2723),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formattedCoins,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: isCompact ? 11.5 : 13.0,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Plus Action Button
                    Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFFDE7), Color(0xFFFFB300), Color(0xFFFF8F00)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x66FFB300),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 13,
                        color: Color(0xFF3E2723),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Action 1: Leaderboard / Stats Button
          _buildActionButton(
            size: actionBtnSize,
            iconSize: isCompact ? 18 : 20,
            icon: Icons.bar_chart_rounded,
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
          SizedBox(width: isCompact ? 5 : 7),

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
          SizedBox(width: isCompact ? 5 : 7),

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
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1B2A4A),
            Color(0xFF0F1B33),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: const Color(0x4480D8FF), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.18),
            blurRadius: 6,
            spreadRadius: 0.2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 6,
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

  // --- Card 0: TOURNAMENTS (First Row Left) ---
  Widget _buildTournamentsCard(BuildContext context, [double height = 136]) {
    return GameModeCard(
      cardKey: const Key('tournaments_card'),
      title: "TOURNAMENTS",
      height: height,
      isShield: true,
      glowColor: const Color(0xFFFF1744),
      accentColor: const Color(0xFFFFD700),
      cardGradient: const [
        Color(0xFF880E4F),
        Color(0xFF5E1335),
        Color(0xFF38071D),
        Color(0xFF1F030F),
      ],
      illustration: const TournamentsIllustration(),
      onTap: () => _openTournamentsMode(context),
    );
  }

  // --- Card 1: PLAY WITH FRIENDS (Second Row Left) ---
  Widget _buildPlayWithFriendsCard(BuildContext context, [double height = 136]) {
    return GameModeCard(
      cardKey: const Key('play_with_friends_card'),
      title: "PLAY WITH FRIENDS",
      height: height,
      isShield: true,
      glowColor: const Color(0xFF00E676),
      accentColor: const Color(0xFFFFD700),
      cardGradient: const [
        Color(0xFF1B5E20),
        Color(0xFF004D40),
        Color(0xFF052414),
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
      isShield: true,
      glowColor: const Color(0xFF00E5FF),
      accentColor: const Color(0xFF80D8FF),
      cardGradient: const [
        Color(0xFF0077B6),
        Color(0xFF023E8A),
        Color(0xFF011848),
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
      isShield: true,
      glowColor: const Color(0xFFE040FB),
      accentColor: const Color(0xFFFFD700),
      cardGradient: const [
        Color(0xFF7B1FA2),
        Color(0xFF4A148C),
        Color(0xFF1E0038),
      ],
      illustration: const TeamUpIllustration(),
      onTap: () => _openTeamUpMode(context),
    );
  }

  // --- Card 4: PLAY VS COMPUTER (Second Row Middle) ---
  Widget _buildPlayVsComputerCard(BuildContext context, [double height = 136]) {
    return GameModeCard(
      cardKey: const Key('play_vs_computer_card'),
      title: "PLAY VS COMPUTER",
      height: height,
      isShield: true,
      glowColor: const Color(0xFF2979FF),
      accentColor: const Color(0xFFFFD700),
      cardGradient: const [
        Color(0xFF0D47A1),
        Color(0xFF0A2B66),
        Color(0xFF031433),
      ],
      illustration: const PlayVsComputerIllustration(),
      onTap: () => _startGame(context, GameMode.vsComputer),
    );
  }

  // --- Card 5: PASS N PLAY (Second Row Right) ---
  Widget _buildPassNPlayCard(BuildContext context, [double height = 136]) {
    return GameModeCard(
      cardKey: const Key('pass_n_play_card'),
      title: "PASS N PLAY",
      height: height,
      isShield: true,
      glowColor: const Color(0xFFFFB300),
      accentColor: const Color(0xFFFFD700),
      cardGradient: const [
        Color(0xFF8D5B18),
        Color(0xFF5A3305),
        Color(0xFF2E1601),
      ],
      illustration: const PassNPlayIllustration(),
      onTap: _openPassNPlaySetup,
    );
  }

  // --- Game Modes Section: 3 in First Row, 3 in Second Row ---
  Widget _buildGameModesSection(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = constraints.maxWidth < 350 ? 8.0 : 10.0;
        final rowSpacing = constraints.maxWidth < 350 ? 12.0 : 14.0;
        final cardWidth = (constraints.maxWidth - (2 * spacing)) / 3;
        final cardHeight = (cardWidth * 1.20).clamp(124.0, 144.0);

        return Column(
          children: [
            // FIRST ROW — THREE CARDS HORIZONTALLY: TOURNAMENTS, ONLINE, TEAM UP
            Row(
              children: [
                Expanded(
                  child: _buildTournamentsCard(context, cardHeight),
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

            // SECOND ROW — THREE CARDS HORIZONTALLY: PLAY WITH FRIENDS, PLAY VS COMPUTER, PASS N PLAY
            Row(
              children: [
                Expanded(
                  child: _buildPlayWithFriendsCard(context, cardHeight),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: _buildPlayVsComputerCard(context, cardHeight),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: _buildPassNPlayCard(context, cardHeight),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  int _getTournamentEntryFee(String tournamentName) {
    final lower = tournamentName.toLowerCase();
    if (lower.contains('grand')) return 1000;
    if (lower.contains('daily')) return 250;
    if (lower.contains('blitz') || lower.contains('weekend')) return 500;
    return 250;
  }

  void _openTournamentPaymentSheet(
    BuildContext context,
    String tournamentName,
    int prizePool,
    int entryFee,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => TournamentPaymentDialog(
        tournamentName: tournamentName,
        prizePool: prizePool,
        entryFee: entryFee,
        initialBalance: _userProfile?.coins,
        onPaymentSuccess: (paidAmount, paymentMethod) async {
          await _loadUserInfo();
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Joined $tournamentName! Entry Fee: $paidAmount Coins paid via $paymentMethod 🏆',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: const Color(0xFF1E0845),
              duration: const Duration(seconds: 2),
            ),
          );
          _startGame(context, GameMode.vsComputer);
        },
      ),
    );
  }

  void _openTournamentsMode(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => TournamentsDialog(
        onJoinTournament: (tournamentName, prize) {
          final entryFee = _getTournamentEntryFee(tournamentName);
          _openTournamentPaymentSheet(context, tournamentName, prize, entryFee);
        },
        onJoinWithDetails: (tournamentName, prize, entryFee) {
          _openTournamentPaymentSheet(context, tournamentName, prize, entryFee);
        },
      ),
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
            horizontal: constraints.maxWidth < 360 ? 10 : 16,
            vertical: isShortScreen ? 2 : 4,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
              maxWidth: 440,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Royal 3D Crown, Laurel Wreath & LUDO SUPREME Branding
                _buildRoyalBrandingHeader(isShort: isShortScreen),

                // 2. 3D Floating Isometric Ludo Board with Pawns & Die
                _buildIsometricLudoBoardSection(context, isShort: isShortScreen),

                SizedBox(height: isShortScreen ? 4 : 8),

                // Resume Match Card (if exists)
                if (_hasSavedMatch && _savedState != null) ...[
                  _buildResumeCard(context, _savedState!),
                  SizedBox(height: isShortScreen ? 8 : 12),
                ],

                // 3. Six 3D Game Mode Cards (3 in Row 1, 3 in Row 2)
                _buildGameModesSection(context),

                SizedBox(height: isShortScreen ? 8 : 14),

                // 4. How to Play & Rules Link (Golden Bordered Capsule Pill)
                _buildRulesLink(context),

                SizedBox(height: isShortScreen ? 4 : 8),

                // 5. Palace Floor Decor: Floating Corner 3D Dice & Center Crown Arch
                _buildPalaceFooterDecor(context, isShort: isShortScreen),

                SizedBox(height: isShortScreen ? 4 : 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- 1. Royal 3D Crown, Laurel Wreath & LUDO SUPREME Branding ---
  Widget _buildRoyalBrandingHeader({required bool isShort}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown flanked by Laurel Wreaths & Sunburst Rays
        SizedBox(
          width: 140,
          height: isShort ? 34 : 42,
          child: CustomPaint(
            painter: _HeaderCrownLaurelPainter(),
          ),
        ),
        const SizedBox(height: 2),

        // LUDO 3D Golden Chrome Metallic Typography with Flanking 3D Dice
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Left Flanking 3D Die
              _FloatingLogoDie(angle: -0.28, isShort: isShort, pipPattern: 3),
              SizedBox(width: isShort ? 8 : 12),

              // "LUDO" Golden Metallic Title
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFFFFFDE7),
                    Color(0xFFFFEA79),
                    Color(0xFFFFB300),
                    Color(0xFFFF8F00),
                    Color(0xFF793B00),
                  ],
                  stops: [0.0, 0.25, 0.55, 0.82, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds),
                child: Text(
                  "LUDO",
                  style: TextStyle(
                    fontSize: isShort ? 30 : 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4.0,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        color: Color(0xFF3E1800),
                        offset: Offset(0, 3.5),
                        blurRadius: 7,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(width: isShort ? 8 : 12),
              // Right Flanking 3D Die
              _FloatingLogoDie(angle: 0.28, isShort: isShort, pipPattern: 5),
            ],
          ),
        ),
        const SizedBox(height: 3),

        // SUPREME 3D Crimson Red Ribbon Banner with Gold Border (matches reference image)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 4.0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFF3D00),
                Color(0xFFD50000),
                Color(0xFFB71C1C),
                Color(0xFF7F0000),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFFFD700),
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5252).withValues(alpha: 0.55),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
              const BoxShadow(
                color: Colors.black54,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            "SUPREME",
            style: TextStyle(
              fontSize: isShort ? 12.5 : 14.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.8,
              color: Colors.white,
              shadows: const [
                Shadow(
                  color: Colors.black87,
                  offset: Offset(0, 1.5),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),

        // Tagline: THE CLASSIC BOARD GAME EXPERIENCE
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            "THE CLASSIC BOARD GAME EXPERIENCE",
            style: TextStyle(
              color: const Color(0xFFCFD8DC),
              fontSize: isShort ? 8.5 : 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
        ),
        const SizedBox(height: 3),

        // 5-Star Golden Rating Arch
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final isCenter = index == 2;
            final isNearCenter = index == 1 || index == 3;
            final starSize = isCenter ? (isShort ? 13.0 : 15.0) : (isNearCenter ? (isShort ? 10.5 : 12.0) : (isShort ? 9.0 : 10.0));
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Icon(
                Icons.star_rounded,
                color: const Color(0xFFFFD700),
                size: starSize,
                shadows: const [
                  Shadow(
                    color: Color(0xFFFFB300),
                    blurRadius: 6,
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  // --- 5. Palace Footer Decor: Floating Corner Dice & Center Crown Arch ---
  Widget _buildPalaceFooterDecor(BuildContext context, {required bool isShort}) {
    return SizedBox(
      height: isShort ? 36 : 46,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Left Floating 3D Corner Die
          Positioned(
            left: 10,
            bottom: 4,
            child: _FloatingLogoDie(angle: -0.35, isShort: isShort, sizeMultiplier: 1.15, pipPattern: 6),
          ),

          // Center Crown Arch over the bottom navigation bar
          Positioned(
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.military_tech_rounded,
                  color: const Color(0xFFFFD700),
                  size: isShort ? 22 : 28,
                  shadows: const [
                    Shadow(color: Color(0xFFFFB300), blurRadius: 10),
                    Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                Container(
                  width: 50,
                  height: 2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1),
                    gradient: const LinearGradient(
                      colors: [
                        Colors.transparent,
                        Color(0xFFFFD700),
                        Color(0xFFFFEA79),
                        Color(0xFFFFD700),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Right Floating 3D Corner Die
          Positioned(
            right: 10,
            bottom: 4,
            child: _FloatingLogoDie(angle: 0.35, isShort: isShort, sizeMultiplier: 1.15, pipPattern: 2),
          ),
        ],
      ),
    );
  }

  // --- 2. 3D Floating Isometric Ludo Board Canvas ---
  Widget _buildIsometricLudoBoardSection(BuildContext context, {required bool isShort}) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final boardHeight = (screenWidth * 0.45).clamp(135.0, 185.0);

    return SizedBox(
      width: double.infinity,
      height: boardHeight,
      child: CustomPaint(
        painter: _IsometricBoardPainter(),
      ),
    );
  }

  // --- How to Play & Rules Link ---
  Widget _buildRulesLink(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF08142C).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.70),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _showRules(context),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 7),
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
                  SizedBox(width: 8),
                  Text(
                    "How to Play & Rules",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(width: 6),
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

/// 3D Golden Crown flanked by Laurel Wreaths and radiating light rays
class _HeaderCrownLaurelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.58;

    // 1. Sunburst Light Rays behind crown
    final rayPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD700).withValues(alpha: 0.45),
          const Color(0xFFFFB300).withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy - 2), radius: 36))
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    for (int i = -5; i <= 5; i++) {
      final angle = -math.pi / 2 + (i * (math.pi / 16));
      final p1 = Offset(cx + math.cos(angle) * 14, (cy - 4) + math.sin(angle) * 14);
      final p2 = Offset(cx + math.cos(angle) * 34, (cy - 4) + math.sin(angle) * 34);
      canvas.drawLine(p1, p2, rayPaint);
    }

    // 2. Laurel Wreath Branches (Left and Right)
    final goldLeafPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF59D), Color(0xFFFFD700), Color(0xFFFF8F00)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(cx - 44, cy - 18, 88, 32))
      ..style = PaintingStyle.fill;

    final leafStroke = Paint()
      ..color = const Color(0xFF5D4037)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    void drawLeaf(double x, double y, double rotation, double length, double width) {
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      final leafPath = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(length * 0.5, -width, length, 0)
        ..quadraticBezierTo(length * 0.5, width, 0, 0)
        ..close();
      canvas.drawPath(leafPath, goldLeafPaint);
      canvas.drawPath(leafPath, leafStroke);
      canvas.restore();
    }

    // Left Laurel Branch (5 leaves)
    drawLeaf(cx - 16, cy + 8, -math.pi * 0.85, 9, 3.5);
    drawLeaf(cx - 24, cy + 4, -math.pi * 0.72, 10, 4.0);
    drawLeaf(cx - 30, cy - 2, -math.pi * 0.58, 11, 4.0);
    drawLeaf(cx - 32, cy - 9, -math.pi * 0.42, 11, 4.0);
    drawLeaf(cx - 27, cy - 16, -math.pi * 0.28, 10, 3.5);

    // Right Laurel Branch (5 leaves)
    drawLeaf(cx + 16, cy + 8, -math.pi * 0.15, 9, 3.5);
    drawLeaf(cx + 24, cy + 4, -math.pi * 0.28, 10, 4.0);
    drawLeaf(cx + 30, cy - 2, -math.pi * 0.42, 11, 4.0);
    drawLeaf(cx + 32, cy - 9, -math.pi * 0.58, 11, 4.0);
    drawLeaf(cx + 27, cy - 16, -math.pi * 0.72, 10, 3.5);

    // 3. Velvet interior crown cap
    final velvetPath = Path()
      ..moveTo(cx - 19, cy + 4)
      ..quadraticBezierTo(cx - 20, cy - 8, cx, cy - 13)
      ..quadraticBezierTo(cx + 20, cy - 8, cx + 19, cy + 4)
      ..close();
    final velvetPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFE91E63), Color(0xFF880E4F), Color(0xFF31021A)],
        center: Alignment(0, -0.3),
        radius: 0.85,
      ).createShader(Rect.fromLTWH(cx - 20, cy - 14, 40, 20));
    canvas.drawPath(velvetPath, velvetPaint);

    // 4. Crown Gold Body & 5 Peaks
    final crownPath = Path()
      ..moveTo(cx - 22, cy + 6)
      ..lineTo(cx - 23, cy - 4) // Outer left peak
      ..lineTo(cx - 16, cy + 1) // valley
      ..lineTo(cx - 11, cy - 9) // Mid left peak
      ..lineTo(cx - 5, cy + 0) // valley
      ..lineTo(cx, cy - 15) // Tall Center Peak
      ..lineTo(cx + 5, cy + 0) // valley
      ..lineTo(cx + 11, cy - 9) // Mid right peak
      ..lineTo(cx + 16, cy + 1) // valley
      ..lineTo(cx + 23, cy - 4) // Outer right peak
      ..lineTo(cx + 22, cy + 6)
      ..quadraticBezierTo(cx, cy + 9, cx - 22, cy + 6)
      ..close();

    final crownGoldPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFFDE7),
          Color(0xFFFFEA79),
          Color(0xFFFFB300),
          Color(0xFFFF8F00),
          Color(0xFFB26A00),
        ],
        stops: [0.0, 0.25, 0.55, 0.82, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(cx - 24, cy - 16, 48, 26))
      ..style = PaintingStyle.fill;

    final crownShadowPaint = Paint()
      ..color = const Color(0x66000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawPath(crownPath.shift(const Offset(0, 1.8)), crownShadowPaint);
    canvas.drawPath(crownPath, crownGoldPaint);

    final crownOutlinePaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(crownPath, crownOutlinePaint);

    // 5. Golden Spheres / Pearls on Peak tips
    void drawPeakPearl(double x, double y, double radius) {
      final pearlPaint = Paint()
        ..shader = RadialGradient(
          colors: const [Color(0xFFFFFFFF), Color(0xFFFFD54F), Color(0xFFFF8F00)],
          center: const Alignment(-0.35, -0.35),
          radius: 0.8,
        ).createShader(Rect.fromCircle(center: Offset(x, y), radius: radius));
      canvas.drawCircle(Offset(x, y), radius, pearlPaint);
      canvas.drawCircle(Offset(x, y), radius, leafStroke);
    }

    drawPeakPearl(cx, cy - 15, 3.2);
    drawPeakPearl(cx - 11, cy - 9, 2.4);
    drawPeakPearl(cx + 11, cy - 9, 2.4);
    drawPeakPearl(cx - 23, cy - 4, 1.9);
    drawPeakPearl(cx + 23, cy - 4, 1.9);

    // 6. Base Arch Band with Gems
    final bandPath = Path()
      ..moveTo(cx - 22, cy + 4)
      ..quadraticBezierTo(cx, cy + 7, cx + 22, cy + 4)
      ..lineTo(cx + 21, cy + 8)
      ..quadraticBezierTo(cx, cy + 11, cx - 21, cy + 8)
      ..close();

    final bandPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFEA79), Color(0xFFFFB300), Color(0xFFE65100)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(cx - 22, cy + 4, 44, 7));
    canvas.drawPath(bandPath, bandPaint);

    // Gems on band
    canvas.drawCircle(Offset(cx, cy + 8), 1.8, Paint()..color = const Color(0xFFE91E63));
    canvas.drawCircle(Offset(cx - 10, cy + 7), 1.5, Paint()..color = const Color(0xFF00E5FF));
    canvas.drawCircle(Offset(cx + 10, cy + 7), 1.5, Paint()..color = const Color(0xFF00E5FF));

    // Center Crown Ruby Diamond on Center Peak
    final rubyPath = Path()
      ..moveTo(cx, cy - 9)
      ..lineTo(cx + 3.2, cy - 5.5)
      ..lineTo(cx, cy - 2)
      ..lineTo(cx - 3.2, cy - 5.5)
      ..close();
    final rubyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF5252), Color(0xFFD50000), Color(0xFF880E4F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(cx - 3.5, cy - 9, 7, 7));
    canvas.drawPath(rubyPath, rubyPaint);
    canvas.drawPath(rubyPath, leafStroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3D Perspective Isometric Ludo Board with Pillars, 4 Quadrants, Pawns & 3D Center Die
class _IsometricBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.48;

    // Board perspective parameters
    final baseHalfWidth = (size.width * 0.38).clamp(110.0, 155.0);
    final baseHalfHeight = (size.height * 0.36).clamp(48.0, 68.0);
    const depthExtrusion = 10.0; // 3D bevel thickness

    // Helper: Map normalized 2D board coords (bx, by) in [-1, 1] to perspective screen coords
    Offset toBoard(double bx, double by) {
      final perspective = 1.0 + (by * 0.28);
      final x = cx + bx * (baseHalfWidth * perspective);
      final y = cy + by * baseHalfHeight;
      return Offset(x, y);
    }

    // --- 1. Background Palace Hall Pillars & Royal Banners ---
    _drawPalacePillarsAndBanners(canvas, size);

    // --- 2. Board Contact & Ambient Shadow ---
    final shadowPath = Path()
      ..moveTo(toBoard(-1.03, -1.03).dx, toBoard(-1.03, -1.03).dy + depthExtrusion + 4)
      ..lineTo(toBoard(1.03, -1.03).dx, toBoard(1.03, -1.03).dy + depthExtrusion + 4)
      ..lineTo(toBoard(1.03, 1.03).dx, toBoard(1.03, 1.03).dy + depthExtrusion + 6)
      ..lineTo(toBoard(-1.03, 1.03).dx, toBoard(-1.03, 1.03).dy + depthExtrusion + 6)
      ..close();
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0),
    );

    // --- 3. 3D Golden Bevel Extrusion (Front & Side Faces) ---
    final frontFacePath = Path()
      ..moveTo(toBoard(-1.0, 1.0).dx, toBoard(-1.0, 1.0).dy)
      ..lineTo(toBoard(1.0, 1.0).dx, toBoard(1.0, 1.0).dy)
      ..lineTo(toBoard(1.0, 1.0).dx, toBoard(1.0, 1.0).dy + depthExtrusion)
      ..lineTo(toBoard(-1.0, 1.0).dx, toBoard(-1.0, 1.0).dy + depthExtrusion)
      ..close();

    final frontBevelPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF8D6E12),
          Color(0xFFFFB300),
          Color(0xFFFFD54F),
          Color(0xFFFF8F00),
          Color(0xFF5D4037),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(cx - baseHalfWidth * 1.3, cy + baseHalfHeight, baseHalfWidth * 2.6, depthExtrusion));
    canvas.drawPath(frontFacePath, frontBevelPaint);

    // Left bevel face
    final leftFacePath = Path()
      ..moveTo(toBoard(-1.0, -1.0).dx, toBoard(-1.0, -1.0).dy)
      ..lineTo(toBoard(-1.0, 1.0).dx, toBoard(-1.0, 1.0).dy)
      ..lineTo(toBoard(-1.0, 1.0).dx, toBoard(-1.0, 1.0).dy + depthExtrusion)
      ..lineTo(toBoard(-1.0, -1.0).dx, toBoard(-1.0, -1.0).dy + depthExtrusion * 0.6)
      ..close();
    final leftBevelPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF3E2723), Color(0xFF6D4C41), Color(0xFF8D6E12)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(cx - baseHalfWidth * 1.3, cy - baseHalfHeight, baseHalfWidth, baseHalfHeight * 2));
    canvas.drawPath(leftFacePath, leftBevelPaint);

    // Right bevel face
    final rightFacePath = Path()
      ..moveTo(toBoard(1.0, -1.0).dx, toBoard(1.0, -1.0).dy)
      ..lineTo(toBoard(1.0, 1.0).dx, toBoard(1.0, 1.0).dy)
      ..lineTo(toBoard(1.0, 1.0).dx, toBoard(1.0, 1.0).dy + depthExtrusion)
      ..lineTo(toBoard(1.0, -1.0).dx, toBoard(1.0, -1.0).dy + depthExtrusion * 0.6)
      ..close();
    final rightBevelPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF3E2723), Color(0xFF5D4037), Color(0xFF8D6E12)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(cx + baseHalfWidth * 0.5, cy - baseHalfHeight, baseHalfWidth, baseHalfHeight * 2));
    canvas.drawPath(rightFacePath, rightBevelPaint);

    // --- 4. Outer Metallic Golden Rim Frame ---
    final boardFramePath = Path()
      ..moveTo(toBoard(-1.0, -1.0).dx, toBoard(-1.0, -1.0).dy)
      ..lineTo(toBoard(1.0, -1.0).dx, toBoard(1.0, -1.0).dy)
      ..lineTo(toBoard(1.0, 1.0).dx, toBoard(1.0, 1.0).dy)
      ..lineTo(toBoard(-1.0, 1.0).dx, toBoard(-1.0, 1.0).dy)
      ..close();

    final goldRimPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFFDE7),
          Color(0xFFFFEA79),
          Color(0xFFFFB300),
          Color(0xFFFF8F00),
          Color(0xFF8D6E12),
        ],
        stops: [0.0, 0.25, 0.55, 0.85, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: baseHalfWidth * 1.3))
      ..style = PaintingStyle.fill;
    canvas.drawPath(boardFramePath, goldRimPaint);

    // Inner surface backing
    final innerSurfacePath = Path()
      ..moveTo(toBoard(-0.95, -0.95).dx, toBoard(-0.95, -0.95).dy)
      ..lineTo(toBoard(0.95, -0.95).dx, toBoard(0.95, -0.95).dy)
      ..lineTo(toBoard(0.95, 0.95).dx, toBoard(0.95, 0.95).dy)
      ..lineTo(toBoard(-0.95, 0.95).dx, toBoard(-0.95, 0.95).dy)
      ..close();
    canvas.drawPath(innerSurfacePath, Paint()..color = const Color(0xFFFAF7F2));

    // --- 5. Four Colored Quadrants (Bases) ---
    // Helper to draw a colored quadrant base with 4 pawn sockets
    void drawQuadrant({
      required double x1,
      required double y1,
      required double x2,
      required double y2,
      required Color baseColor,
      required Color darkColor,
    }) {
      final quadPath = Path()
        ..moveTo(toBoard(x1, y1).dx, toBoard(x1, y1).dy)
        ..lineTo(toBoard(x2, y1).dx, toBoard(x2, y1).dy)
        ..lineTo(toBoard(x2, y2).dx, toBoard(x2, y2).dy)
        ..lineTo(toBoard(x1, y2).dx, toBoard(x1, y2).dy)
        ..close();

      final quadPaint = Paint()
        ..shader = LinearGradient(
          colors: [baseColor, darkColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromPoints(toBoard(x1, y1), toBoard(x2, y2)));
      canvas.drawPath(quadPath, quadPaint);

      // White inner panel
      final innerPadX = (x2 - x1) * 0.15;
      final innerPadY = (y2 - y1) * 0.15;
      final whitePath = Path()
        ..moveTo(toBoard(x1 + innerPadX, y1 + innerPadY).dx, toBoard(x1 + innerPadX, y1 + innerPadY).dy)
        ..lineTo(toBoard(x2 - innerPadX, y1 + innerPadY).dx, toBoard(x2 - innerPadX, y1 + innerPadY).dy)
        ..lineTo(toBoard(x2 - innerPadX, y2 - innerPadY).dx, toBoard(x2 - innerPadX, y2 - innerPadY).dy)
        ..lineTo(toBoard(x1 + innerPadX, y2 - innerPadY).dx, toBoard(x1 + innerPadX, y2 - innerPadY).dy)
        ..close();
      canvas.drawPath(whitePath, Paint()..color = Colors.white);

      // 4 pawn circles inside white panel
      final cx1 = x1 + (x2 - x1) * 0.34;
      final cx2 = x1 + (x2 - x1) * 0.66;
      final cy1 = y1 + (y2 - y1) * 0.34;
      final cy2 = y1 + (y2 - y1) * 0.66;
      final dotPaint = Paint()..color = baseColor;
      for (final p in [
        toBoard(cx1, cy1),
        toBoard(cx2, cy1),
        toBoard(cx1, cy2),
        toBoard(cx2, cy2),
      ]) {
        canvas.drawOval(Rect.fromCenter(center: p, width: 7.0, height: 4.5), dotPaint);
      }
    }

    // Top-Left: RED
    drawQuadrant(
      x1: -0.92,
      y1: -0.92,
      x2: -0.22,
      y2: -0.22,
      baseColor: const Color(0xFFE53935),
      darkColor: const Color(0xFFB71C1C),
    );

    // Top-Right: GREEN
    drawQuadrant(
      x1: 0.22,
      y1: -0.92,
      x2: 0.92,
      y2: -0.22,
      baseColor: const Color(0xFF43A047),
      darkColor: const Color(0xFF1B5E20),
    );

    // Bottom-Left: BLUE
    drawQuadrant(
      x1: -0.92,
      y1: 0.22,
      x2: -0.22,
      y2: 0.92,
      baseColor: const Color(0xFF1E88E5),
      darkColor: const Color(0xFF0D47A1),
    );

    // Bottom-Right: YELLOW
    drawQuadrant(
      x1: 0.22,
      y1: 0.22,
      x2: 0.92,
      y2: 0.92,
      baseColor: const Color(0xFFFFB300),
      darkColor: const Color(0xFFE65100),
    );

    // --- 6. Colored Home Run Paths & Center Triangle ---
    // Red home track (horizontal from left to center)
    final redTrack = Path()
      ..moveTo(toBoard(-0.92, -0.07).dx, toBoard(-0.92, -0.07).dy)
      ..lineTo(toBoard(-0.20, -0.07).dx, toBoard(-0.20, -0.07).dy)
      ..lineTo(toBoard(-0.20, 0.07).dx, toBoard(-0.20, 0.07).dy)
      ..lineTo(toBoard(-0.92, 0.07).dx, toBoard(-0.92, 0.07).dy)
      ..close();
    canvas.drawPath(redTrack, Paint()..color = const Color(0xFFE53935));

    // Green home track (vertical from top to center)
    final greenTrack = Path()
      ..moveTo(toBoard(-0.07, -0.92).dx, toBoard(-0.07, -0.92).dy)
      ..lineTo(toBoard(0.07, -0.92).dx, toBoard(0.07, -0.92).dy)
      ..lineTo(toBoard(0.07, -0.20).dx, toBoard(0.07, -0.20).dy)
      ..lineTo(toBoard(-0.07, -0.20).dx, toBoard(-0.07, -0.20).dy)
      ..close();
    canvas.drawPath(greenTrack, Paint()..color = const Color(0xFF43A047));

    // Blue home track (vertical from bottom to center)
    final blueTrack = Path()
      ..moveTo(toBoard(-0.07, 0.20).dx, toBoard(-0.07, 0.20).dy)
      ..lineTo(toBoard(0.07, 0.20).dx, toBoard(0.07, 0.20).dy)
      ..lineTo(toBoard(0.07, 0.92).dx, toBoard(0.07, 0.92).dy)
      ..lineTo(toBoard(-0.07, 0.92).dx, toBoard(-0.07, 0.92).dy)
      ..close();
    canvas.drawPath(blueTrack, Paint()..color = const Color(0xFF1E88E5));

    // Yellow home track (horizontal from right to center)
    final yellowTrack = Path()
      ..moveTo(toBoard(0.20, -0.07).dx, toBoard(0.20, -0.07).dy)
      ..lineTo(toBoard(0.92, -0.07).dx, toBoard(0.92, -0.07).dy)
      ..lineTo(toBoard(0.92, 0.07).dx, toBoard(0.92, 0.07).dy)
      ..lineTo(toBoard(0.20, 0.07).dx, toBoard(0.20, 0.07).dy)
      ..close();
    canvas.drawPath(yellowTrack, Paint()..color = const Color(0xFFFFB300));

    // Center Home Finish Triangles
    final centerPt = toBoard(0.0, 0.0);
    // Red Triangle (Left)
    final redTri = Path()
      ..moveTo(centerPt.dx, centerPt.dy)
      ..lineTo(toBoard(-0.20, -0.20).dx, toBoard(-0.20, -0.20).dy)
      ..lineTo(toBoard(-0.20, 0.20).dx, toBoard(-0.20, 0.20).dy)
      ..close();
    canvas.drawPath(redTri, Paint()..color = const Color(0xFFD32F2F));

    // Green Triangle (Top)
    final greenTri = Path()
      ..moveTo(centerPt.dx, centerPt.dy)
      ..lineTo(toBoard(-0.20, -0.20).dx, toBoard(-0.20, -0.20).dy)
      ..lineTo(toBoard(0.20, -0.20).dx, toBoard(0.20, -0.20).dy)
      ..close();
    canvas.drawPath(greenTri, Paint()..color = const Color(0xFF388E3C));

    // Yellow Triangle (Right)
    final yellowTri = Path()
      ..moveTo(centerPt.dx, centerPt.dy)
      ..lineTo(toBoard(0.20, -0.20).dx, toBoard(0.20, -0.20).dy)
      ..lineTo(toBoard(0.20, 0.20).dx, toBoard(0.20, 0.20).dy)
      ..close();
    canvas.drawPath(yellowTri, Paint()..color = const Color(0xFFFFA000));

    // Blue Triangle (Bottom)
    final blueTri = Path()
      ..moveTo(centerPt.dx, centerPt.dy)
      ..lineTo(toBoard(-0.20, 0.20).dx, toBoard(-0.20, 0.20).dy)
      ..lineTo(toBoard(0.20, 0.20).dx, toBoard(0.20, 0.20).dy)
      ..close();
    canvas.drawPath(blueTri, Paint()..color = const Color(0xFF1976D2));

    // Track grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFCFD8DC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    for (double i = -0.92; i <= 0.92; i += 0.14) {
      canvas.drawLine(toBoard(i, -0.20), toBoard(i, 0.20), gridPaint);
      canvas.drawLine(toBoard(-0.20, i), toBoard(0.20, i), gridPaint);
    }

    // --- 7. Standing 3D Pawns ---
    // Helper to draw a rich 3D turned pawn
    void drawPawn3D({
      required Offset boardPos,
      required Color primaryColor,
      required Color darkColor,
      required Color lightColor,
      double scale = 1.0,
    }) {
      final px = boardPos.dx;
      final py = boardPos.dy;

      // Soft contact shadow on board
      canvas.drawOval(
        Rect.fromCenter(center: Offset(px, py + 1), width: 18 * scale, height: 7 * scale),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      );

      // Base ring
      final baseRect = Rect.fromCenter(center: Offset(px, py - 3 * scale), width: 14 * scale, height: 6 * scale);
      canvas.drawOval(
        baseRect,
        Paint()
          ..shader = LinearGradient(
            colors: [lightColor, primaryColor, darkColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(baseRect),
      );

      // Torso / Stem
      final torsoPath = Path()
        ..moveTo(px - 5 * scale, py - 4 * scale)
        ..quadraticBezierTo(px - 2.5 * scale, py - 12 * scale, px - 3.5 * scale, py - 15 * scale)
        ..lineTo(px + 3.5 * scale, py - 15 * scale)
        ..quadraticBezierTo(px + 2.5 * scale, py - 12 * scale, px + 5 * scale, py - 4 * scale)
        ..close();
      canvas.drawPath(
        torsoPath,
        Paint()
          ..shader = LinearGradient(
            colors: [lightColor, primaryColor, darkColor],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(Rect.fromLTWH(px - 6 * scale, py - 16 * scale, 12 * scale, 14 * scale)),
      );

      // Golden Collar Ring
      canvas.drawOval(
        Rect.fromCenter(center: Offset(px, py - 15 * scale), width: 8.5 * scale, height: 3.5 * scale),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFFFDE7), Color(0xFFFFD700), Color(0xFFFF8F00)],
          ).createShader(Rect.fromLTWH(px - 5 * scale, py - 17 * scale, 10 * scale, 4 * scale)),
      );

      // 3D Spherical Head with Specular Gloss
      final headCenter = Offset(px, py - 20 * scale);
      final headRadius = 5.2 * scale;
      final headPaint = Paint()
        ..shader = RadialGradient(
          colors: [Colors.white, lightColor, primaryColor, darkColor],
          stops: const [0.0, 0.22, 0.65, 1.0],
          center: const Alignment(-0.35, -0.40),
          radius: 0.85,
        ).createShader(Rect.fromCircle(center: headCenter, radius: headRadius));
      canvas.drawCircle(headCenter, headRadius, headPaint);

      // Bright specular glint
      canvas.drawCircle(
        Offset(headCenter.dx - 1.8 * scale, headCenter.dy - 1.8 * scale),
        1.3 * scale,
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );
    }

    // Draw 4 pawns proudly positioned in their home corners
    drawPawn3D(
      boardPos: toBoard(-0.55, -0.55),
      primaryColor: const Color(0xFFE53935),
      darkColor: const Color(0xFF880E4F),
      lightColor: const Color(0xFFFF8A80),
      scale: 1.05,
    );
    drawPawn3D(
      boardPos: toBoard(0.55, -0.55),
      primaryColor: const Color(0xFF2E7D32),
      darkColor: const Color(0xFF003300),
      lightColor: const Color(0xFF81C784),
      scale: 1.05,
    );
    drawPawn3D(
      boardPos: toBoard(-0.55, 0.55),
      primaryColor: const Color(0xFF1565C0),
      darkColor: const Color(0xFF0D47A1),
      lightColor: const Color(0xFF64B5F6),
      scale: 1.15,
    );
    drawPawn3D(
      boardPos: toBoard(0.55, 0.55),
      primaryColor: const Color(0xFFFF8F00),
      darkColor: const Color(0xFFE65100),
      lightColor: const Color(0xFFFFD54F),
      scale: 1.15,
    );

    // --- 8. Center 3D Isometric White Die ---
    _drawCenter3DDie(canvas, centerPt);
  }

  void _drawPalacePillarsAndBanners(Canvas canvas, Size size) {
    // Left Pillar
    final leftPillarRect = Rect.fromLTWH(0, 0, 26, size.height);
    final leftPillarPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1E2F54), Color(0xFF0D1B36), Color(0xFF060B18)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(leftPillarRect);
    canvas.drawRect(leftPillarRect, leftPillarPaint);

    // Left Purple Banner
    final leftBannerPath = Path()
      ..moveTo(8, 0)
      ..lineTo(22, 0)
      ..lineTo(22, size.height * 0.75)
      ..lineTo(15, size.height * 0.82)
      ..lineTo(8, size.height * 0.75)
      ..close();
    final bannerPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF8E24AA), Color(0xFF6A1B9A), Color(0xFF4A148C)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(8, 0, 14, size.height * 0.85));
    canvas.drawPath(leftBannerPath, bannerPaint);
    // Gold crown insignia on left banner
    canvas.drawCircle(Offset(15, size.height * 0.38), 3.0, Paint()..color = const Color(0xFFFFD700));

    // Right Pillar
    final rightPillarRect = Rect.fromLTWH(size.width - 26, 0, 26, size.height);
    final rightPillarPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF060B18), Color(0xFF0D1B36), Color(0xFF1E2F54)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(rightPillarRect);
    canvas.drawRect(rightPillarRect, rightPillarPaint);

    // Right Purple Banner
    final rightBannerPath = Path()
      ..moveTo(size.width - 22, 0)
      ..lineTo(size.width - 8, 0)
      ..lineTo(size.width - 8, size.height * 0.75)
      ..lineTo(size.width - 15, size.height * 0.82)
      ..lineTo(size.width - 22, size.height * 0.75)
      ..close();
    canvas.drawPath(rightBannerPath, bannerPaint);
    // Gold crown insignia on right banner
    canvas.drawCircle(Offset(size.width - 15, size.height * 0.38), 3.0, Paint()..color = const Color(0xFFFFD700));
  }

  void _drawCenter3DDie(Canvas canvas, Offset center) {
    final dx = center.dx;
    final dy = center.dy - 6;

    // Golden Motion Vortex Aura Rings around spinning center die
    final auraPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = const SweepGradient(
        colors: [
          Colors.transparent,
          Color(0xFFFFD700),
          Color(0xFFFFF9C4),
          Color(0xFFFFB300),
          Colors.transparent,
        ],
        stops: [0.0, 0.35, 0.6, 0.85, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(dx, dy), radius: 30));

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(1.0, 0.52); // Isometric board perspective compression
    canvas.drawOval(Rect.fromCircle(center: Offset.zero, radius: 30), auraPaint);
    canvas.drawOval(
      Rect.fromCircle(center: Offset.zero, radius: 23),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFFFFEA79).withValues(alpha: 0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
    // Dynamic sparkle dots
    final sparklePaint = Paint()..color = const Color(0xFFFFD700);
    canvas.drawCircle(const Offset(24, -10), 2.0, sparklePaint);
    canvas.drawCircle(const Offset(-22, 12), 1.6, sparklePaint);
    canvas.drawCircle(const Offset(15, 18), 1.8, sparklePaint);
    canvas.restore();

    // Contact drop shadow on board
    canvas.drawOval(
      Rect.fromCenter(center: Offset(dx, dy + 18), width: 34, height: 14),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0),
    );

    // 1. Top Face (Diamond/Rhombus - Bright white)
    final topFace = Path()
      ..moveTo(dx, dy - 18)
      ..lineTo(dx + 16, dy - 9)
      ..lineTo(dx, dy)
      ..lineTo(dx - 16, dy - 9)
      ..close();
    final topPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(dx - 16, dy - 18, 32, 18));
    canvas.drawPath(topFace, topPaint);

    // 2. Left Face (Medium light white)
    final leftFace = Path()
      ..moveTo(dx - 16, dy - 9)
      ..lineTo(dx, dy)
      ..lineTo(dx, dy + 16)
      ..lineTo(dx - 16, dy + 7)
      ..close();
    final leftPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(dx - 16, dy - 9, 16, 25));
    canvas.drawPath(leftFace, leftPaint);

    // 3. Right Face (Shaded white)
    final rightFace = Path()
      ..moveTo(dx, dy)
      ..lineTo(dx + 16, dy - 9)
      ..lineTo(dx + 16, dy + 7)
      ..lineTo(dx, dy + 16)
      ..close();
    final rightPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFCBD5E1), Color(0xFF94A3B8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(dx, dy - 9, 16, 25));
    canvas.drawPath(rightFace, rightPaint);

    // Outer subtle border stroke
    final edgePaint = Paint()
      ..color = const Color(0xFF64748B).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawPath(topFace, edgePaint);
    canvas.drawPath(leftFace, edgePaint);
    canvas.drawPath(rightFace, edgePaint);

    // Center Pip on Top Face (Indented black circle)
    final pipPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF0F172A), Color(0xFF334155)],
        radius: 0.8,
      ).createShader(Rect.fromCircle(center: Offset(dx, dy - 9), radius: 2.8));
    canvas.drawOval(Rect.fromCenter(center: Offset(dx, dy - 9), width: 5.2, height: 3.2), pipPaint);

    // Pips on Left Face (3 dots diagonal)
    for (int i = -1; i <= 1; i++) {
      final pipPos = Offset(dx - 8 + (i * 4.5), dy + 3.5 + (i * 4.5));
      canvas.drawOval(Rect.fromCenter(center: pipPos, width: 3.2, height: 3.8), pipPaint);
    }

    // Pips on Right Face (2 dots diagonal)
    canvas.drawOval(Rect.fromCenter(center: Offset(dx + 5, dy + 2), width: 3.2, height: 3.8), pipPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(dx + 11, dy + 9), width: 3.2, height: 3.8), pipPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3D Floating Ivory Die for the Supreme Title Header and Palace Footer Decor
class _FloatingLogoDie extends StatelessWidget {
  final double angle;
  final bool isShort;
  final double sizeMultiplier;
  final int pipPattern;

  const _FloatingLogoDie({
    required this.angle,
    required this.isShort,
    this.sizeMultiplier = 1.0,
    this.pipPattern = 3,
  });

  @override
  Widget build(BuildContext context) {
    final baseSize = (isShort ? 32.0 : 38.0) * sizeMultiplier;
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: baseSize,
        height: baseSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(baseSize * 0.22),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF8FAFC),
              Color(0xFFE2E8F0),
              Color(0xFFCBD5E1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.85),
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.40),
              blurRadius: 10,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.65),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: CustomPaint(
          painter: _DiePipsPainter(pipCount: pipPattern),
        ),
      ),
    );
  }
}

/// Custom painter for dice pips (dots) on 3D Floating Ivory Dice
class _DiePipsPainter extends CustomPainter {
  final int pipCount;
  const _DiePipsPainter({required this.pipCount});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final pipRadius = w * 0.088;

    final pipPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF090D16), Color(0xFF1E293B)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    void drawPip(double x, double y) {
      canvas.drawCircle(Offset(x, y), pipRadius, pipPaint);
      canvas.drawCircle(Offset(x, y), pipRadius, rimPaint);
    }

    final cx = w * 0.5;
    final cy = h * 0.5;
    final l = w * 0.26;
    final r = w * 0.74;
    final t = h * 0.26;
    final b = h * 0.74;

    switch (pipCount) {
      case 1:
        drawPip(cx, cy);
        break;
      case 2:
        drawPip(l, t);
        drawPip(r, b);
        break;
      case 3:
        drawPip(l, t);
        drawPip(cx, cy);
        drawPip(r, b);
        break;
      case 4:
        drawPip(l, t);
        drawPip(r, t);
        drawPip(l, b);
        drawPip(r, b);
        break;
      case 5:
        drawPip(l, t);
        drawPip(r, t);
        drawPip(cx, cy);
        drawPip(l, b);
        drawPip(r, b);
        break;
      case 6:
      default:
        drawPip(l, t);
        drawPip(l, cy);
        drawPip(l, b);
        drawPip(r, t);
        drawPip(r, cy);
        drawPip(r, b);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _DiePipsPainter oldDelegate) => oldDelegate.pipCount != pipCount;
}


