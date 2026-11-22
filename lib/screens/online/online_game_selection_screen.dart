import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/network/api_service.dart';
import '../../models/online_game_mode.dart';
import '../../models/room_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/online/online_game_mode_card.dart';
import 'online_matchmaking_screen.dart';

/// Screen allowing players to select from the 5 Online Game Modes:
/// A. CLASSIC (Default)
/// B. 1 KILL WIN
/// C. QUICK
/// D. POPULAR
/// E. MASK
///
/// Follows Ludo Supreme Royal Gaming Design matching the reference:
/// - 3D Jeweled crown on top of "SELECT GAME" banner
/// - 3D Circular back button & help button
/// - Coins capsule pill with green add button
/// - "CHOOSE BATTLE MODE" banner with yellow gamepad icon
/// - Entry fee & prize pool selector
/// - 3D multi-layered shadow cards with custom emblems
/// - Bottom bar with blue 3D "NEXT" button and exterior pawns/dice
class OnlineGameSelectionScreen extends StatefulWidget {
  final List<OnlineGameMode>? modes;

  const OnlineGameSelectionScreen({
    super.key,
    this.modes,
  });

  @override
  State<OnlineGameSelectionScreen> createState() =>
      _OnlineGameSelectionScreenState();
}

class _OnlineGameSelectionScreenState extends State<OnlineGameSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final List<OnlineGameMode> _modes;
  late OnlineGameMode _selectedMode;
  late AnimationController _animController;
  int _coins = 3600;
  int _entryFeeIndex = 1;
  final List<int> _entryFeeOptions = [50, 100, 500, 1000, 2500, 5000];

  int get _currentEntryFee => _entryFeeOptions[_entryFeeIndex];
  int get _currentPrizePool => (_currentEntryFee * 2 * 0.9).toInt();

  void _decreaseEntryFee() {
    if (_entryFeeIndex > 0) {
      setState(() => _entryFeeIndex--);
    }
  }

  void _increaseEntryFee() {
    if (_entryFeeIndex < _entryFeeOptions.length - 1) {
      setState(() => _entryFeeIndex++);
    }
  }

  @override
  void initState() {
    super.initState();
    _modes = widget.modes ?? OnlineGameMode.defaultModes;
    // Default to CLASSIC mode as required
    _selectedMode = _modes.firstWhere(
      (m) => m.modeType == OnlineModeType.classic,
      orElse: () => _modes.first,
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _loadUserCoins();
    _loadOnlineLobbyStats();
  }

  Future<void> _loadUserCoins() async {
    try {
      final coins = await AuthService.getUserCoins();
      if (mounted) {
        setState(() {
          _coins = coins;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadOnlineLobbyStats() async {}

  void _selectMode(OnlineGameMode mode) {
    setState(() {
      _selectedMode = mode;
    });
  }

  void _onNext() {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OnlineMatchmakingScreen(
          selectedMode: _selectedMode,
          entryFee: _currentEntryFee,
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0C1833),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFFFFD700), width: 1.6),
        ),
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded,
                color: Color(0xFFFFD700), size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Online Game Modes",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRuleEntry(
                "CLASSIC",
                "Traditional Ludo race where all 4 tokens must reach the home triangle to win.",
                const Color(0xFF4FC3F7),
              ),
              const SizedBox(height: 10),
              _buildRuleEntry(
                "1 KILL WIN",
                "High-intensity tactical mode: capturing any opponent token claims instant victory!",
                const Color(0xFFFF8A80),
              ),
              const SizedBox(height: 10),
              _buildRuleEntry(
                "QUICK",
                "Fast-paced gameplay with accelerated 10-second turn timers and sprint tracks.",
                const Color(0xFFB9F6CA),
              ),
              const SizedBox(height: 10),
              _buildRuleEntry(
                "POPULAR",
                "The most actively played competitive tournament lobbies with ranked matchmaking.",
                const Color(0xFFEA80FC),
              ),
              const SizedBox(height: 10),
              _buildRuleEntry(
                "MASK",
                "Mystery mode where pawn paths and special powers remain hidden until revealed.",
                const Color(0xFF84FFFF),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "UNDERSTOOD",
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleEntry(String title, String desc, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: accentColor,
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          desc,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            height: 1.3,
          ),
        ),
      ],
    );
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

          // 3. Screen Content
          SafeArea(
            child: Column(
              children: [
                // Top Header (Back, Crown + "SELECT GAME", Coins & Help)
                _buildHeader(context),

                // Main Selectable Modes List
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14.0,
                          vertical: 8.0,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Subtitle banner: CHOOSE BATTLE MODE
                                _buildSectionBanner(),

                                const SizedBox(height: 10),

                                // Entry Fee & Prize Pool Selector
                                _buildEntryFeeSelector(),

                                const SizedBox(height: 12),

                                // Data-driven list of 5 game modes with staggered animation
                                ...List.generate(_modes.length, (index) {
                                  final mode = _modes[index];
                                  final isSelected =
                                      _selectedMode.id == mode.id;

                                  final start =
                                      (index * 0.10).clamp(0.0, 1.0);
                                  final end = (start + 0.35).clamp(0.0, 1.0);

                                  final itemAnimation = Tween<double>(
                                          begin: 0.0, end: 1.0)
                                      .animate(
                                    CurvedAnimation(
                                      parent: _animController,
                                      curve: Interval(start, end,
                                          curve: Curves.easeOutCubic),
                                    ),
                                  );

                                  return AnimatedBuilder(
                                    animation: itemAnimation,
                                    builder: (context, child) {
                                      return Opacity(
                                        opacity: itemAnimation.value,
                                        child: Transform.translate(
                                          offset: Offset(
                                              0,
                                              16 *
                                                  (1 - itemAnimation.value)),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: OnlineGameModeCard(
                                      mode: mode,
                                      isSelected: isSelected,
                                      onSelect: () => _selectMode(mode),
                                    ),
                                  );
                                }),

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

  /// Header with Back Button, 3D Crown over "SELECT GAME", Coins Badge and Help Button
  Widget _buildHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          child: Row(
            children: [
              // 3D Circular Back Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  key: const Key('online_game_selection_back_button'),
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

              // Center: Crown + "SELECT GAME" Capsule Banner
              Expanded(
                child: Stack(
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.none,
                  children: [
                    // Main Capsule Banner
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFFFFD54F),
                          width: 2.2,
                        ),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF6A1B9A),
                            Color(0xFF4A148C),
                            Color(0xFF240046),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF6A1B9A).withValues(alpha: 0.6),
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
                      child: const Center(
                        child: Text(
                          "SELECT GAME",
                          key: Key('online_game_selection_title'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.6,
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
                      ),
                    ),

                    // 3D Jeweled Golden Crown perched on top
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

              // Coins Badge with Green + Button
              _buildCoinsBadge(),

              const SizedBox(width: 6),

              // Help / Question Mark Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  key: const Key('online_game_selection_help_button'),
                  borderRadius: BorderRadius.circular(12),
                  onTap: _showHelpDialog,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF132244),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                        width: 1.0,
                      ),
                    ),
                    child: const Icon(
                      Icons.help_outline_rounded,
                      color: Color(0xFFFFD700),
                      size: 19,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Coins balance pill matching reference look with green + button
  Widget _buildCoinsBadge() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
      decoration: BoxDecoration(
        color: const Color(0xFF140F00),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFFD700),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.25),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.monetization_on_rounded,
            color: Color(0xFFFFD700),
            size: 15,
          ),
          const SizedBox(width: 3),
          Text(
            "$_coins",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          // Green Circular + button
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF00E676),
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Colors.black,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Section instruction banner: "CHOOSE BATTLE MODE"
  Widget _buildSectionBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF091B42),
        border: Border.all(
          color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E88E5).withValues(alpha: 0.3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0D47A1),
              border: Border.all(
                color: const Color(0xFFFFD700),
                width: 1.0,
              ),
            ),
            child: const Icon(
              Icons.sports_esports_rounded,
              color: Color(0xFFFFD700),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "CHOOSE BATTLE MODE",
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Select a game mode below to enter the live multiplayer lobby",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Entry fee and prize pool selector
  Widget _buildEntryFeeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF08183A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.6),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top row: ENTRY FEE & Prize Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.monetization_on_rounded,
                    color: Color(0xFFFFD700),
                    size: 15,
                  ),
                  SizedBox(width: 4),
                  Text(
                    "ENTRY FEE",
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF063A1F),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00E676),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E676).withValues(alpha: 0.35),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: Color(0xFFFFD700),
                      size: 13,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      "Prize: $_currentPrizePool",
                      style: const TextStyle(
                        color: Color(0xFF00E676),
                        fontWeight: FontWeight.w900,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Bottom row: [-], Center Pill, [+]
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFeeButton(
                icon: Icons.remove_rounded,
                onTap: _entryFeeIndex > 0 ? _decreaseEntryFee : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF030A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFFD700),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            const Color(0xFFFFD700).withValues(alpha: 0.25),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.monetization_on_rounded,
                          color: Color(0xFFFFD700),
                          size: 18,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "$_currentEntryFee",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          "COINS",
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildFeeButton(
                icon: Icons.add_rounded,
                onTap: _entryFeeIndex < _entryFeeOptions.length - 1
                    ? _increaseEntryFee
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeeButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: isEnabled
                ? const LinearGradient(
                    colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isEnabled ? null : const Color(0xFF0A1428),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEnabled
                  ? const Color(0xFFFFD700)
                  : Colors.white12,
              width: 1.4,
            ),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF0D47A1).withValues(alpha: 0.6),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            color: isEnabled ? Colors.white : Colors.white24,
            size: 22,
          ),
        ),
      ),
    );
  }

  void _showJoinRoomCodeDialog(BuildContext context) {
    final codeController = TextEditingController();
    bool isJoining = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF0C1938),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: Color(0xFFFFD700), width: 1.8),
            ),
            title: const Row(
              children: [
                Icon(Icons.vpn_key_rounded, color: Color(0xFFFFD700), size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Join Online Lobby",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Enter the 6-character room code shared by your friend:",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: codeController,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4.0,
                  ),
                  decoration: InputDecoration(
                    counterText: "",
                    filled: true,
                    fillColor: const Color(0xFF070F22),
                    hintText: "e.g. AB89X2",
                    hintStyle: const TextStyle(color: Colors.white30, fontSize: 16, letterSpacing: 1.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFFFEA79), width: 2.0),
                    ),
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isJoining ? null : () => Navigator.pop(ctx),
                child: const Text("CANCEL", style: TextStyle(color: Colors.white60)),
              ),
              ElevatedButton(
                onPressed: isJoining
                    ? null
                    : () async {
                        final code = codeController.text.trim().toUpperCase();
                        if (code.length < 4) {
                          setDialogState(() => errorMessage = "Please enter a valid room code.");
                          return;
                        }

                        setDialogState(() {
                          isJoining = true;
                          errorMessage = null;
                        });

                        try {
                          await AuthService.ensureBackendSession();
                          final res = await ApiService().joinRoom(roomCode: code);
                          if (!ctx.mounted) return;

                          if (res['success'] == true && res['data'] != null) {
                            final room = RoomModel.fromJson(res['data']);
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OnlineMatchmakingScreen(
                                  selectedMode: _selectedMode,
                                  entryFee: room.entryFee,
                                  initialRoom: room,
                                  isHost: false,
                                ),
                              ),
                            );
                            return;
                          } else {
                            setDialogState(() {
                              isJoining = false;
                              errorMessage = res['message']?.toString() ?? "Could not join room. Check code.";
                            });
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            setDialogState(() {
                              isJoining = false;
                              errorMessage = "Connection error. Please try again.";
                            });
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB300),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isJoining
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.black)),
                      )
                    : const Text("JOIN LOBBY", style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Bottom pinned action bar with blue 3D "NEXT" button & exterior pawns/dice
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
              // Bottom Exterior Pawns: Red (Left) & Blue (Right)
              const Positioned(
                bottom: -2,
                left: -8,
                child: CustomPaint(
                  size: Size(22, 32),
                  painter: _RoyalPawnPainter(color: Color(0xFFE53935)),
                ),
              ),
              const Positioned(
                bottom: -2,
                right: -8,
                child: CustomPaint(
                  size: Size(22, 32),
                  painter: _RoyalPawnPainter(color: Color(0xFF1E88E5)),
                ),
              ),

              // Dual Action Buttons: JOIN (Secondary) & NEXT (Primary)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    _JoinCodeButton(
                      onPressed: () => _showJoinRoomCodeDialog(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _NextButton(
                        onPressed: _onNext,
                      ),
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
}

/// Compact secondary button to join an existing room with code
class _JoinCodeButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _JoinCodeButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFFFFD700),
          width: 1.6,
        ),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4A148C),
            Color(0xFF2E0854),
            Color(0xFF1A0033),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A148C).withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('online_game_selection_join_code_button'),
          borderRadius: BorderRadius.circular(26),
          onTap: onPressed,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.vpn_key_rounded, color: Color(0xFFFFD700), size: 18),
                SizedBox(width: 4),
                Text(
                  "JOIN",
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// NEXT Button with Blue gradient, Golden border, Golden glow, and interactive press animation.
class _NextButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _NextButton({required this.onPressed});

  @override
  State<_NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<_NextButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutCubic,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFFDE7),
              Color(0xFFFFD54F),
              Color(0xFFFFB300),
              Color(0xFF8D4B00),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB300).withValues(
                alpha: _isPressed ? 0.65 : 0.45,
              ),
              blurRadius: _isPressed ? 14 : 20,
              spreadRadius: 1.5,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: const Color(0xFF1E88E5).withValues(alpha: 0.5),
              blurRadius: 14,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(2.2),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF29B6F6),
                Color(0xFF1E88E5),
                Color(0xFF0D47A1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('online_game_selection_next_button'),
              borderRadius: BorderRadius.circular(24),
              splashColor: const Color(0xFFFFD700).withValues(alpha: 0.25),
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              onTap: widget.onPressed,
              child: const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "NEXT",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.2,
                        shadows: [
                          Shadow(
                            color: Colors.black87,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFFFFD700),
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom Painters for Crown, Pawn, and Dice
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
