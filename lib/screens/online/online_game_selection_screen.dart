import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/online_game_mode.dart';
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
/// Features:
/// - Ludo Supreme Royal Sapphire & Gold visual theme
/// - Single mode selection with golden check indicators
/// - Data-driven mode configurations
/// - Interactive Next button with blue gradient, gold glow, and press animation
/// - Responsive layout supporting small to large Android devices without overflow
class OnlineGameSelectionScreen extends StatefulWidget {
  final List<OnlineGameMode>? modes;

  const OnlineGameSelectionScreen({
    super.key,
    this.modes,
  });

  @override
  State<OnlineGameSelectionScreen> createState() => _OnlineGameSelectionScreenState();
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

  /// Hook for future backend integration to fetch real-time player counts and room statistics
  Future<void> _loadOnlineLobbyStats() async {
    // TODO: Connect to backend service (e.g. OnlineLobbyService.fetchActivePlayerCounts())
    // final stats = await OnlineLobbyService.getPlayerCounts();
    // if (mounted) {
    //   setState(() { ... update mode counts ... });
    // }
  }

  void _selectMode(OnlineGameMode mode) {
    setState(() {
      _selectedMode = mode;
    });
  }

  void _onNext() {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}

    // Pass the currently selected mode to the matchmaking flow
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
            Icon(Icons.help_outline_rounded, color: Color(0xFFFFD700), size: 24),
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
          // 1. Luxury Background Wallpaper with dark overlay
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

          // 2. Dark Luxury Gradient Overlay for Contrast & Readability
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xF0060B19),
                    Color(0xD9060E22),
                    Color(0xF8030712),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 3. Screen Content
          SafeArea(
            child: Column(
              children: [
                // Top Header (Back, "SELECT GAME", Coins & Help)
                _buildHeader(context),

                // Main Selectable Modes List (Responsive Scroll)
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18.0,
                          vertical: 12.0,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 540),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Subtitle banner
                                _buildSectionBanner(),

                                const SizedBox(height: 12),

                                // Entry Fee & Prize Pool Selector
                                _buildEntryFeeSelector(),

                                const SizedBox(height: 14),

                                // Data-driven list of 5 game modes with staggered entrance animation
                                ...List.generate(_modes.length, (index) {
                                  final mode = _modes[index];
                                  final isSelected = _selectedMode.id == mode.id;

                                  final start = (index * 0.12).clamp(0.0, 1.0);
                                  final end = (start + 0.4).clamp(0.0, 1.0);

                                  final itemAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                                    CurvedAnimation(
                                      parent: _animController,
                                      curve: Interval(start, end, curve: Curves.easeOutCubic),
                                    ),
                                  );

                                  return AnimatedBuilder(
                                    animation: itemAnimation,
                                    builder: (context, child) {
                                      return Opacity(
                                        opacity: itemAnimation.value,
                                        child: Transform.translate(
                                          offset: Offset(0, 20 * (1 - itemAnimation.value)),
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

                // Bottom Action Bar: NEXT Button
                _buildBottomBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Header with Back Button, Center Title "SELECT GAME", Coins Badge and Help Button
  Widget _buildHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isNarrow ? 10 : 16,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF091530).withValues(alpha: 0.88),
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFFFFD700).withValues(alpha: 0.22),
                width: 1.0,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Back Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  key: const Key('online_game_selection_back_button'),
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

              SizedBox(width: isNarrow ? 6 : 10),

              // Center Title
              Expanded(
                child: Center(
                  child: Text(
                    "SELECT GAME",
                    key: const Key('online_game_selection_title'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isNarrow ? 16 : 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: isNarrow ? 1.2 : 2.0,
                      shadows: const [
                        Shadow(
                          color: Color(0x66FFD700),
                          offset: Offset(0, 2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(width: isNarrow ? 6 : 8),

              // Coins Badge
              _buildCoinsBadge(),

              SizedBox(width: isNarrow ? 6 : 8),

              // Help / Question Mark Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  key: const Key('online_game_selection_help_button'),
                  borderRadius: BorderRadius.circular(12),
                  onTap: _showHelpDialog,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF132244),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.35),
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
      },
    );
  }

  /// Coins balance pill matching Ludo Supreme luxury look
  Widget _buildCoinsBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF181202),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.75),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.monetization_on_rounded,
            color: Color(0xFFFFD700),
            size: 15,
          ),
          const SizedBox(width: 4),
          Text(
            "$_coins",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Section instruction banner
  Widget _buildSectionBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFF0C1935).withValues(alpha: 0.65),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF122858),
            ),
            child: const Icon(
              Icons.sports_esports_rounded,
              color: Color(0xFFFFD700),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
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
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Select a game mode below to enter the live multiplayer lobby",
                  style: TextStyle(
                    color: Color(0xFF90A4AE),
                    fontSize: 11,
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

  Widget _buildEntryFeeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1833).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.monetization_on_rounded,
                    color: Color(0xFFFFD700),
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    "ENTRY FEE",
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A3B22),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF00E676).withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: Color(0xFFFFD700),
                      size: 12,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      "Prize: $_currentPrizePool",
                      style: const TextStyle(
                        color: Color(0xFF00E676),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF050E22),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFFFD700),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.2),
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
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "$_currentEntryFee",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          "COINS",
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
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
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isEnabled
                ? const Color(0xFF132857)
                : const Color(0xFF0A1428),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isEnabled
                  ? const Color(0xFFFFD700).withValues(alpha: 0.7)
                  : Colors.white12,
              width: 1.2,
            ),
          ),
          child: Icon(
            icon,
            color: isEnabled ? const Color(0xFFFFD700) : Colors.white24,
            size: 20,
          ),
        ),
      ),
    );
  }

  /// Bottom pinned action bar with glowing blue "NEXT" button
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF091428).withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFFFD700).withValues(alpha: 0.25),
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: _NextButton(
            onPressed: _onNext,
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
          borderRadius: BorderRadius.circular(16),
          // Metallic Gold outer border
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
            // Golden Glow
            BoxShadow(
              color: const Color(0xFFFFB300).withValues(
                alpha: _isPressed ? 0.65 : 0.45,
              ),
              blurRadius: _isPressed ? 14 : 20,
              spreadRadius: 1.5,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(2.0), // Golden border thickness
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            // Blue Gradient as required
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1E88E5), // Cobalt top
                Color(0xFF1565C0), // Royal blue middle
                Color(0xFF0D47A1), // Deep navy bottom
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('online_game_selection_next_button'),
              borderRadius: BorderRadius.circular(14),
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
                            color: Color(0x66000000),
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
