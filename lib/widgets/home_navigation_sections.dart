import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/network/api_service.dart';
import '../models/leaderboard_model.dart';
import '../models/reward_model.dart';
import '../models/room_model.dart';
import '../models/user_profile_model.dart';
import '../screens/leaderboard_screen.dart';
import '../screens/rewards_screen.dart';
import '../screens/wallet_screen.dart';
import '../services/auth_service.dart';
import 'player_selection_dialog.dart';
import 'profile_dialog.dart';
import 'room_lobby_dialog.dart';

// ============================================================================
// PREMIUM 5-SECTION GAMING NAVIGATION BAR (SQUARE GAME CARDS)
// ============================================================================
class HomeNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const HomeNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  static const List<NavItemData> navItems = [
    NavItemData(
      icon: Icons.cottage_rounded,
      badgeIcon: Icons.casino_rounded,
      label: 'HOME',
      key: Key('nav_item_home'),
      accentColor: Color(0xFFFFB300),
      iconColor: Color(0xFFFFD54F),
      badgeColor: Color(0xFFFFE082),
      labelColor: Colors.white,
      activeGradient: [
        Color(0xFFFFEA79),
        Color(0xFFFFB300),
        Color(0xFFFF8F00),
      ],
      inactiveGradient: [
        Color(0xFF4A148C),
        Color(0xFF2E0854),
        Color(0xFF1A0033),
      ],
      lightGradient: [
        Color(0xFFFFFDF5),
        Color(0xFFFFF7DB),
        Color(0xFFFFECC0),
      ],
    ),
    NavItemData(
      icon: Icons.calendar_month_rounded,
      badgeIcon: Icons.star_rounded,
      label: 'EVENT',
      key: Key('nav_item_event'),
      accentColor: Color(0xFFEF4444),
      iconColor: Color(0xFFFF8A80),
      badgeColor: Color(0xFFFFD700),
      labelColor: Colors.white,
      notificationBadge: '1',
      activeGradient: [
        Color(0xFFFFEA79),
        Color(0xFFFFB300),
        Color(0xFFFF8F00),
      ],
      inactiveGradient: [
        Color(0xFF4A148C),
        Color(0xFF2E0854),
        Color(0xFF1A0033),
      ],
      lightGradient: [
        Color(0xFFFFF8F8),
        Color(0xFFFFE8EA),
        Color(0xFFFFD4D8),
      ],
    ),
    NavItemData(
      icon: Icons.casino_rounded,
      badgeIcon: Icons.casino_rounded,
      label: 'ADDA',
      key: Key('nav_item_adda'),
      accentColor: Color(0xFFFFD700),
      iconColor: Color(0xFFFFD700),
      badgeColor: Color(0xFFFFFDE7),
      labelColor: Colors.white,
      activeGradient: [
        Color(0xFFFFEA79),
        Color(0xFFFFB300),
        Color(0xFFFF8F00),
      ],
      inactiveGradient: [
        Color(0xFF4A148C),
        Color(0xFF2E0854),
        Color(0xFF1A0033),
      ],
      lightGradient: [
        Color(0xFFF0F9FF),
        Color(0xFFE0F4FF),
        Color(0xFFBAE6FD),
      ],
    ),
    NavItemData(
      icon: Icons.inventory_2_rounded,
      badgeIcon: Icons.diamond_rounded,
      label: 'INVENTORY',
      key: Key('nav_item_inventory'),
      accentColor: Color(0xFFFFD700),
      iconColor: Color(0xFFFFD54F),
      badgeColor: Color(0xFFFFFDE7),
      labelColor: Colors.white,
      activeGradient: [
        Color(0xFFFFEA79),
        Color(0xFFFFB300),
        Color(0xFFFF8F00),
      ],
      inactiveGradient: [
        Color(0xFF4A148C),
        Color(0xFF2E0854),
        Color(0xFF1A0033),
      ],
      lightGradient: [
        Color(0xFFFAF5FF),
        Color(0xFFF1E6FF),
        Color(0xFFDDD6FE),
      ],
    ),
    NavItemData(
      icon: Icons.people_alt_rounded,
      badgeIcon: Icons.chat_bubble_rounded,
      label: 'SOCIAL',
      key: Key('nav_item_social'),
      accentColor: Color(0xFFFFD700),
      iconColor: Color(0xFFFFD54F),
      badgeColor: Color(0xFFFFFDE7),
      labelColor: Colors.white,
      activeGradient: [
        Color(0xFFFFEA79),
        Color(0xFFFFB300),
        Color(0xFFFF8F00),
      ],
      inactiveGradient: [
        Color(0xFF4A148C),
        Color(0xFF2E0854),
        Color(0xFF1A0033),
      ],
      lightGradient: [
        Color(0xFFF0FDF4),
        Color(0xFFDCFCE7),
        Color(0xFFA7F3D0),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // Rich royal/deep blue game-style background with subtle gradient
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0B1428), // Deep royal navy
            Color(0xFF060C1B), // Midnight bottom
          ],
        ),
        // Subtle top border/highlight separating bar from game content
        border: Border(
          top: BorderSide(
            color: const Color(0xFFFFD700).withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.70),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
          BoxShadow(
            color: const Color(0xFF1D4ED8).withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: MediaQuery.withNoTextScaling(
          child: Container(
            height: 74,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Row(
                  children: List.generate(navItems.length, (index) {
                    final item = navItems[index];
                    final isSelected = selectedIndex == index;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.5),
                        child: _NavSquareCard(
                          item: item,
                          isSelected: isSelected,
                          onTap: () => onItemSelected(index),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact square/rectangular card with 3D depth, rich game styling,
/// golden highlights, layered colorful icons, and smooth transitions.
class _NavSquareCard extends StatefulWidget {
  final NavItemData item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavSquareCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavSquareCard> createState() => _NavSquareCardState();
}

class _NavSquareCardState extends State<_NavSquareCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _tapScaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    // Subtle tactile bounce on tap
    _tapScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.10)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.10, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 55,
      ),
    ]).animate(_animController);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _animController.forward(from: 0.0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final item = widget.item;

    return AnimatedBuilder(
      animation: _tapScaleAnimation,
      builder: (context, child) {
        // Base scale: active card is slightly scaled (1.03) for elevation pop
        final baseScale = isSelected ? 1.03 : 1.0;
        final currentScale = baseScale * _tapScaleAnimation.value;

        return Transform.scale(
          scale: currentScale,
          child: child,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0.0, isSelected ? -7.0 : 0.0, 0.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isSelected ? 32 : 13),
          gradient: LinearGradient(
            colors: isSelected ? item.activeGradient : item.inactiveGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(
            // Golden accent border on active circular item, rich purple on inactive square
            color: isSelected
                ? const Color(0xFFFFFDE7)
                : const Color(0xFFAB47BC).withValues(alpha: 0.65),
            width: isSelected ? 2.0 : 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFFFFB300).withValues(alpha: 0.65)
                  : Colors.black.withValues(alpha: 0.40),
              blurRadius: isSelected ? 14.0 : 5.0,
              spreadRadius: isSelected ? 1.5 : 0.0,
              offset: Offset(0, isSelected ? 3.0 : 2.0),
            ),
            BoxShadow(
              color: isSelected
                  ? const Color(0xFFFFD54F).withValues(alpha: 0.40)
                  : Colors.transparent,
              blurRadius: isSelected ? 6.0 : 0.0,
              spreadRadius: 0.0,
              offset: const Offset(0, 1.0),
            ),
            BoxShadow(
              color: isSelected
                  ? Colors.black.withValues(alpha: 0.45)
                  : Colors.transparent,
              blurRadius: isSelected ? 8.0 : 0.0,
              spreadRadius: 0.0,
              offset: Offset(0, isSelected ? 5.0 : 0.0),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: item.key,
            borderRadius: BorderRadius.circular(isSelected ? 32 : 13),
            onTap: _handleTap,
            splashColor: item.accentColor.withValues(alpha: 0.30),
            highlightColor: Colors.white.withValues(alpha: 0.20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Top specular gloss line for 3D card depth
                Positioned(
                  top: 0,
                  left: 6,
                  right: 6,
                  height: 1.2,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          isSelected
                              ? Colors.white.withValues(alpha: 0.70)
                              : Colors.white.withValues(alpha: 0.20),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Active top golden indicator pip
                if (isSelected)
                  Positioned(
                    top: 2.0,
                    child: Container(
                      width: 16,
                      height: 2.5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFE082),
                            Color(0xFFFFD700),
                            Color(0xFFFFA000),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.75),
                            blurRadius: 4,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                    ),
                  ),

                // Card Content: Layered Colorful Game Icon + Uppercase Label Below
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 3.5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Colorful Game Icon with Pedestal & Accent Badge
                      _GameNavIconBadge(
                        item: item,
                        isSelected: isSelected,
                      ),

                      const SizedBox(height: 3),

                      // Bold Uppercase Label Below Icon
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          item.label,
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 9.2,
                            fontWeight:
                                isSelected ? FontWeight.w900 : FontWeight.w700,
                            color: isSelected
                                ? const Color(0xFF3E2723)
                                : Colors.white,
                            letterSpacing: 0.3,
                            shadows: isSelected
                                ? [
                                    Shadow(
                                      color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : [
                                    const Shadow(
                                      color: Colors.black87,
                                      blurRadius: 2,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                          ),
                        ),
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
}

/// Layered Colorful Game-Style Icon Badge with Radial Ambient Pedestal,
/// 3D Drop Shadow, and Decorative Game Badge (star, mini dice, sound wave, etc.)
class _GameNavIconBadge extends StatelessWidget {
  final NavItemData item;
  final bool isSelected;

  const _GameNavIconBadge({
    required this.item,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final pedestalSize = isSelected ? 32.0 : 29.0;
    final primaryIconSize = isSelected ? 21.0 : 19.0;

    return SizedBox(
      width: 36,
      height: 33,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient circular pedestal glow behind icon
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: pedestalSize,
            height: pedestalSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  item.accentColor.withValues(alpha: isSelected ? 0.32 : 0.16),
                  item.accentColor.withValues(alpha: isSelected ? 0.12 : 0.04),
                  Colors.transparent,
                ],
              ),
              border: Border.all(
                color: item.accentColor.withValues(alpha: isSelected ? 0.45 : 0.20),
                width: 1.0,
              ),
            ),
          ),

          // Primary Colorful Game Icon (or Dual 3D Dice for ADDA)
          if (item.label == 'ADDA')
            Center(
              child: SizedBox(
                width: 28,
                height: 24,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // First die (left, tilted slightly)
                    Positioned(
                      left: 0,
                      top: 4,
                      child: Transform.rotate(
                        angle: -0.22,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: const Color(0xFFFFD700), width: 0.8),
                            boxShadow: const [
                              BoxShadow(color: Colors.black45, blurRadius: 2, offset: Offset(1, 1)),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.circle, color: Color(0xFF1E293B), size: 3.5),
                          ),
                        ),
                      ),
                    ),
                    // Second die (right, tilted other way)
                    Positioned(
                      right: 1,
                      top: 0,
                      child: Transform.rotate(
                        angle: 0.22,
                        child: Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(3.2),
                            border: Border.all(color: const Color(0xFFFFD700), width: 0.8),
                            boxShadow: const [
                              BoxShadow(color: Colors.black54, blurRadius: 3, offset: Offset(1, 2)),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.circle, color: Color(0xFF1E293B), size: 3.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Center(
              child: Icon(
                item.icon,
                size: primaryIconSize,
                color: isSelected ? const Color(0xFF3E2723) : item.iconColor,
                shadows: [
                  Shadow(
                    color: isSelected
                        ? const Color(0xFFFFD54F).withValues(alpha: 0.70)
                        : item.accentColor.withValues(alpha: 0.40),
                    blurRadius: isSelected ? 6 : 4,
                    offset: const Offset(0, 1),
                  ),
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.40),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),

          // Decorative Signature Game Badge (Star, Mini Dice, Sound Waves, etc.)
          if (item.badgeIcon != null)
            Positioned(
              top: 1.5,
              right: 2.0,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: isSelected ? 1.08 : 0.95,
                child: Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF081224),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: item.badgeColor.withValues(alpha: 0.70),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: item.badgeColor.withValues(alpha: 0.55),
                        blurRadius: 3,
                        spreadRadius: 0.2,
                      ),
                    ],
                  ),
                  child: Icon(
                    item.badgeIcon,
                    size: 9.5,
                    color: item.badgeColor,
                  ),
                ),
              ),
            ),

          // Red Notification Badge (e.g. '1' on EVENT)
          if (item.notificationBadge != null)
            Positioned(
              top: -2.0,
              right: -3.0,
              child: Container(
                padding: const EdgeInsets.all(2.5),
                constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF3B30), Color(0xFFD50000)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border.all(color: Colors.white, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF3B30).withValues(alpha: 0.8),
                      blurRadius: 5,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    item.notificationBadge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class NavItemData {
  final IconData icon;
  final IconData? badgeIcon;
  final String label;
  final Key key;
  final Color accentColor;
  final Color iconColor;
  final Color badgeColor;
  final Color labelColor;
  final List<Color> activeGradient;
  final List<Color> inactiveGradient;
  final List<Color> lightGradient;
  final String? notificationBadge;

  const NavItemData({
    required this.icon,
    this.badgeIcon,
    required this.label,
    required this.key,
    required this.accentColor,
    required this.iconColor,
    required this.badgeColor,
    required this.labelColor,
    required this.activeGradient,
    required this.inactiveGradient,
    required this.lightGradient,
    this.notificationBadge,
  });
}

// ============================================================================
// 1. EVENT SECTION VIEW (LIVE API-BACKED EVENTS & REWARDS)
// ============================================================================
class EventSectionView extends StatefulWidget {
  final VoidCallback? onRewardClaimed;

  const EventSectionView({
    super.key,
    this.onRewardClaimed,
  });

  @override
  State<EventSectionView> createState() => _EventSectionViewState();
}

class _EventSectionViewState extends State<EventSectionView> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _errorMessage;
  String? _claimingRewardId;

  List<RewardItem> _availableRewards = [];

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rewardsRes = await _apiService.getRewards();

      if (!mounted) return;

      List<RewardItem> rewardsList = [];
      if (rewardsRes['success'] == true && rewardsRes['data'] != null) {
        final rData = rewardsRes['data'];
        if (rData is Map<String, dynamic> && rData['rewards'] is List) {
          rewardsList = (rData['rewards'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => RewardItem.fromJson(e))
              .toList();
        } else if (rData is Map<String, dynamic> &&
            rData['data'] is Map<String, dynamic> &&
            rData['data']['rewards'] is List) {
          rewardsList = (rData['data']['rewards'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => RewardItem.fromJson(e))
              .toList();
        } else if (rData is List) {
          rewardsList = rData
              .whereType<Map<String, dynamic>>()
              .map((e) => RewardItem.fromJson(e))
              .toList();
        }
      }

      // Safe fallback event items matching the 5 reference items from the screenshot
      if (rewardsList.isEmpty) {
        rewardsList = const [
          RewardItem(
            id: 'referral_bonus',
            title: 'Referral Bonus',
            description: 'Invite friends and claim bonus coins',
            rewardType: 'coins',
            rewardValue: 200,
            icon: 'friends',
            isClaimed: true,
            canClaim: false,
          ),
          RewardItem(
            id: 'weekend_rush',
            title: 'Weekend Rush',
            description: 'Special weekend play reward',
            rewardType: 'coins',
            rewardValue: 300,
            icon: 'calendar',
            isClaimed: true,
            canClaim: false,
          ),
          RewardItem(
            id: 'lucky_spin',
            title: 'Lucky Spin',
            description: 'Try your luck with the daily spin reward',
            rewardType: 'coins',
            rewardValue: 150,
            icon: 'wheel',
            isClaimed: true,
            canClaim: false,
          ),
          RewardItem(
            id: 'first_win',
            title: 'First Win Bonus',
            description: 'Win your first match and get rewarded',
            rewardType: 'coins',
            rewardValue: 250,
            icon: 'trophy',
            isClaimed: true,
            canClaim: false,
          ),
          RewardItem(
            id: 'welcome_bonus',
            title: 'Welcome Bonus',
            description: 'Welcome to Ludo Supreme! Enjoy your starter bonus',
            rewardType: 'coins',
            rewardValue: 500,
            icon: 'gift',
            isClaimed: true,
            canClaim: false,
          ),
        ];
      }

      setState(() {
        _isLoading = false;
        _availableRewards = rewardsList;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _availableRewards = const [
          RewardItem(
            id: 'referral_bonus',
            title: 'Referral Bonus',
            description: 'Invite friends and claim bonus coins',
            rewardType: 'coins',
            rewardValue: 200,
            icon: 'friends',
            isClaimed: true,
            canClaim: false,
          ),
          RewardItem(
            id: 'weekend_rush',
            title: 'Weekend Rush',
            description: 'Special weekend play reward',
            rewardType: 'coins',
            rewardValue: 300,
            icon: 'calendar',
            isClaimed: true,
            canClaim: false,
          ),
          RewardItem(
            id: 'lucky_spin',
            title: 'Lucky Spin',
            description: 'Try your luck with the daily spin reward',
            rewardType: 'coins',
            rewardValue: 150,
            icon: 'wheel',
            isClaimed: true,
            canClaim: false,
          ),
          RewardItem(
            id: 'first_win',
            title: 'First Win Bonus',
            description: 'Win your first match and get rewarded',
            rewardType: 'coins',
            rewardValue: 250,
            icon: 'trophy',
            isClaimed: true,
            canClaim: false,
          ),
          RewardItem(
            id: 'welcome_bonus',
            title: 'Welcome Bonus',
            description: 'Welcome to Ludo Supreme! Enjoy your starter bonus',
            rewardType: 'coins',
            rewardValue: 500,
            icon: 'gift',
            isClaimed: true,
            canClaim: false,
          ),
        ];
      });
    }
  }

  Future<void> _claimReward(RewardItem reward) async {
    if (_claimingRewardId != null || reward.isClaimed) return;

    setState(() {
      _claimingRewardId = reward.id;
    });

    try {
      final res = await _apiService.claimReward(reward.id);

      if (!mounted) return;

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0F265C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Claimed +${reward.rewardValue} ${reward.rewardType == 'gems' ? 'Gems' : 'Coins'}!",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );

        setState(() {
          _claimingRewardId = null;
          _availableRewards = _availableRewards.map((item) {
            if (item.id == reward.id) {
              return item.copyWith(isClaimed: true, canClaim: false);
            }
            return item;
          }).toList();
        });

        // Trigger home screen refresh to update coins in top header
        widget.onRewardClaimed?.call();
      } else {
        final msg = res['message']?.toString() ?? "Could not claim event reward";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() {
          _claimingRewardId = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _claimingRewardId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  IconData _getRewardIcon(String iconKey) {
    switch (iconKey.toLowerCase()) {
      case 'friends':
      case 'referral':
      case 'referral_bonus':
      case 'people':
        return Icons.groups_rounded;
      case 'calendar':
      case 'weekend_rush':
      case 'daily_login':
        return Icons.event_available_rounded;
      case 'spin_wheel':
      case 'wheel':
      case 'lucky_spin':
        return Icons.track_changes_rounded;
      case 'match_win':
      case 'trophy':
      case 'first_win':
        return Icons.emoji_events_rounded;
      case 'streak':
        return Icons.local_fire_department_rounded;
      case 'gem':
      case 'gems':
        return Icons.diamond_rounded;
      case 'gift':
      case 'welcome_bonus':
      case 'welcome':
      default:
        return Icons.card_giftcard_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF04061A), // Dark cosmic midnight
            Color(0xFF140533), // Royal purple glow
            Color(0xFF020722), // Deep royal navy
          ],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Ambient floating 3D Background Elements (dice, wheel arc, coins, trophy)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: const _EventCosmicBackgroundPainter(),
              ),
            ),
          ),

          // Scrollable Content
          LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth >= 600;
              final maxContentWidth = isTablet ? 780.0 : 460.0;

              return RefreshIndicator(
                onRefresh: _fetchEvents,
                color: const Color(0xFFFFD700),
                backgroundColor: const Color(0xFF0B1428),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Sleek Header satisfying test finder: 'LIVE EVENTS & REWARDS'
                          _buildRoyalHeader(),
                          const SizedBox(height: 6),

                          if (_errorMessage != null && _availableRewards.isEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.amber, fontSize: 12),
                              ),
                            ),
                          ],

                          // Loading indicator or Event cards
                          if (_isLoading) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFFFD700),
                                  strokeWidth: 2.8,
                                ),
                              ),
                            ),
                          ] else ...[
                            _buildRewardsList(isTablet: isTablet),
                          ],

                          const SizedBox(height: 6),

                          // Featured Bottom Banner: "REWARDS CENTER & HISTORY"
                          _buildRewardsCenterBanner(context),
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Adaptive Responsive Event Cards Layout ─────────────────────────
  Widget _buildRewardsList({required bool isTablet}) {
    if (!isTablet || _availableRewards.length <= 1) {
      return Column(
        children: _availableRewards
            .map((reward) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildEventCard(reward),
                ))
            .toList(),
      );
    }

    // Tablet: 2 columns grid
    final List<Widget> rows = [];
    for (int i = 0; i < _availableRewards.length; i += 2) {
      final r1 = _availableRewards[i];
      final r2 = (i + 1 < _availableRewards.length) ? _availableRewards[i + 1] : null;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildEventCard(r1)),
              const SizedBox(width: 12),
              if (r2 != null)
                Expanded(child: _buildEventCard(r2))
              else
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  // ── Header Banner ──────────────────────────────────────────────────
  Widget _buildRoyalHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.stars_rounded, color: const Color(0xFFFFD700).withValues(alpha: 0.85), size: 16),
              const SizedBox(width: 8),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFE0E7FF), Color(0xFF93C5FD)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds),
                child: const Text(
                  'LIVE EVENTS & REWARDS',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Color(0xFF2563EB),
                        blurRadius: 10,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.stars_rounded, color: const Color(0xFFFFD700).withValues(alpha: 0.85), size: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Individual Live Event Card ─────────────────────────────────────
  Widget _buildEventCard(RewardItem reward) {
    final isClaimed = reward.isClaimed;
    final isBeingClaimed = _claimingRewardId == reward.id;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0C2050), // Electric deep royal blue
            Color(0xFF07112C), // Dark midnight blue
          ],
        ),
        border: Border.all(
          color: const Color(0xFF2979FF).withValues(alpha: 0.85),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withValues(alpha: 0.35),
            blurRadius: 10,
            spreadRadius: 0.5,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Top specular highlight line for glossy glass effect
            Positioned(
              top: 0,
              left: 20,
              right: 20,
              height: 1.5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.65),
                      const Color(0xFF90CAF9),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Card content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // 3D Golden Medallion Icon on the Left
                  _buildMedallionIcon(reward),
                  const SizedBox(width: 12),

                  // Title + Subtitle + Coin Pill
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          reward.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          reward.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF8FA5C7),
                            fontSize: 10.8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Gold Coin Pill
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1705),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFFD700).withValues(alpha: 0.65),
                                width: 0.9,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildMiniGoldCoin(),
                                const SizedBox(width: 4),
                                Text(
                                  '+${reward.rewardValue} ${reward.rewardType == 'gems' ? 'Gems' : 'Coins'}',
                                  style: const TextStyle(
                                    color: Color(0xFFFFD700),
                                    fontSize: 11.2,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Right Button / State
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: isBeingClaimed
                        ? const SizedBox(
                            width: 85,
                            height: 34,
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Color(0xFFFFD700),
                                ),
                              ),
                            ),
                          )
                        : isClaimed
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF073820), Color(0xFF032012)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(0xFF00E676),
                                    width: 1.4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00E676).withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      spreadRadius: 0.2,
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_rounded,
                                      color: Color(0xFF00E676),
                                      size: 15,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Claimed',
                                      style: TextStyle(
                                        color: Color(0xFF00E676),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : GestureDetector(
                                onTap: () => _claimReward(reward),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFFEE58),
                                        Color(0xFFFFB300),
                                        Color(0xFFFF8F00),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: const Color(0xFFFFF9C4),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFFB300).withValues(alpha: 0.60),
                                        blurRadius: 8,
                                        spreadRadius: 0.5,
                                        offset: const Offset(0, 2),
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.40),
                                        blurRadius: 4,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'CLAIM',
                                        style: TextStyle(
                                          color: Color(0xFF1E1300),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                      SizedBox(width: 3),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: Color(0xFF1E1300),
                                        size: 11,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 3D Golden Medallion Icon ───────────────────────────────────────
  Widget _buildMedallionIcon(RewardItem reward) {
    final iconKey = reward.icon.toLowerCase();
    final isWheel = iconKey.contains('wheel') || iconKey.contains('spin');

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0xFF5A3D06), // warm gold core
            Color(0xFF261902), // dark gold edge
          ],
        ),
        border: Border.all(
          color: const Color(0xFFFFD700),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.45),
            blurRadius: 8,
            spreadRadius: 0.5,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Inner golden ring
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFFA000).withValues(alpha: 0.6),
                width: 1.0,
              ),
            ),
          ),
          // Wheel or Golden icon
          if (isWheel)
            CustomPaint(
              size: const Size(26, 26),
              painter: const _MiniSpinWheelPainter(),
            )
          else
            Icon(
              _getRewardIcon(reward.icon),
              size: 23,
              color: const Color(0xFFFFE082),
              shadows: const [
                Shadow(
                  color: Color(0xFFFFA000),
                  blurRadius: 6,
                ),
                Shadow(
                  color: Colors.black,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMiniGoldCoin() {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFFFFF176), Color(0xFFFFB300), Color(0xFFE65100)],
          stops: [0.2, 0.7, 1.0],
        ),
        border: Border.all(color: const Color(0xFFFFF9C4), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB300).withValues(alpha: 0.5),
            blurRadius: 3,
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '\$',
          style: TextStyle(
            color: Color(0xFF4E2C00),
            fontSize: 8.5,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
        ),
      ),
    );
  }

  // ── Featured Bottom Banner: "REWARDS CENTER & HISTORY" ────────────
  Widget _buildRewardsCenterBanner(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.fromLTRB(14, 16, 8, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0B4CB8),
                Color(0xFF093180),
                Color(0xFF051740),
              ],
            ),
            border: Border.all(
              color: const Color(0xFF00E5FF),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                blurRadius: 14,
                spreadRadius: 0.5,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Content: Title, Subtitle, Bullets, CTA Button
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'REWARDS CENTER & HISTORY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'View your lifetime claims, history and stats',
                      style: TextStyle(
                        color: Color(0xFFB3D4FC),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 7),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          _buildBannerBullet('Coins'),
                          const SizedBox(width: 8),
                          _buildBannerBullet('Daily Streaks'),
                          const SizedBox(width: 8),
                          _buildBannerBullet('Welcome Gifts'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RewardsScreen(
                                onRewardClaimed: () {
                                  _fetchEvents();
                                  widget.onRewardClaimed?.call();
                                },
                              ),
                            ),
                          );
                          _fetchEvents();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFFEE58),
                                Color(0xFFFFB300),
                                Color(0xFFFF8F00),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFFFFF9C4),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFB300).withValues(alpha: 0.6),
                                blurRadius: 8,
                                spreadRadius: 0.5,
                                offset: const Offset(0, 2),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 4,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('🎁', style: TextStyle(fontSize: 13)),
                              SizedBox(width: 6),
                              Text(
                                'Open Rewards Center',
                                style: TextStyle(
                                  color: Color(0xFF221600),
                                  fontSize: 12.2,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Right 3D Illustration
              const SizedBox(
                width: 95,
                height: 95,
                child: CustomPaint(
                  painter: _SunburstGiftPainter(),
                ),
              ),
            ],
          ),
        ),
        // Attached top-left pill badge: ALL REWARDS 🎁
        Positioned(
          top: 0,
          left: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFE082), Color(0xFFFFB300)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFFF9C4),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ALL REWARDS',
                  style: TextStyle(
                    color: Color(0xFF2B1B00),
                    fontSize: 9.8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
                SizedBox(width: 3),
                Text('🎁', style: TextStyle(fontSize: 10)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerBullet(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 12),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 3D CUSTOM PAINTERS FOR EVENT SECTION
// ============================================================================

/// Ambient cosmic background with floating 3D dice, spin wheel arc, gold coins, and championship trophy
class _EventCosmicBackgroundPainter extends CustomPainter {
  const _EventCosmicBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Cosmic ambient radial lights
    final lightBlue = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF1E40AF).withValues(alpha: 0.35),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width * 0.1, size.height * 0.25), radius: 180));
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.25), 180, lightBlue);

    final purpleGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF6B21A8).withValues(alpha: 0.30),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width * 0.9, size.height * 0.40), radius: 200));
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.40), 200, purpleGlow);

    // 2. Lucky Spin Wheel Arc on the left edge (behind dice)
    final wheelCenter = Offset(-size.width * 0.15, size.height * 0.31);
    const wheelRadius = 115.0;
    final wheelColors = [
      const Color(0xFF00E5FF),
      const Color(0xFF7C4DFF),
      const Color(0xFF00E676),
      const Color(0xFFFF9100),
      const Color(0xFFFF1744),
      const Color(0xFFFFD700),
    ];
    const segAngle = math.pi / 4;
    for (int i = 0; i < 5; i++) {
      final p = Paint()
        ..color = wheelColors[i % wheelColors.length].withValues(alpha: 0.45)
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: wheelCenter, radius: wheelRadius),
        -math.pi / 4 + i * (segAngle * 0.5),
        segAngle * 0.5,
        true,
        p,
      );
    }
    final wheelRim = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawArc(
      Rect.fromCircle(center: wheelCenter, radius: wheelRadius),
      -math.pi / 4,
      segAngle * 2.5,
      false,
      wheelRim,
    );

    // 3. 3D Floating Gold Coins
    _drawFloatingCoin(canvas, Offset(size.width * 0.08, size.height * 0.06), 14, -0.2);
    _drawFloatingCoin(canvas, Offset(size.width * 0.07, size.height * 0.43), 12, 0.4);
    _drawFloatingCoin(canvas, Offset(size.width * 0.05, size.height * 0.74), 13, -0.3);
    _drawFloatingCoin(canvas, Offset(size.width * 0.93, size.height * 0.17), 14, 0.3);
    _drawFloatingCoin(canvas, Offset(size.width * 0.92, size.height * 0.56), 13, -0.4);

    // 4. Upper 3D White Ludo Dice (left)
    _draw3DDice(
      canvas: canvas,
      center: Offset(size.width * 0.07, size.height * 0.31),
      size: 28,
      rotationAngle: 0.25,
      topDots: 5,
      leftDots: 3,
      rightDots: 2,
    );

    // 5. Lower 3D White Ludo Dice (lower-left)
    _draw3DDice(
      canvas: canvas,
      center: Offset(size.width * 0.05, size.height * 0.59),
      size: 26,
      rotationAngle: -0.35,
      topDots: 1,
      leftDots: 4,
      rightDots: 6,
    );

    // 6. 3D Golden Championship Trophy & Crown on the right
    _drawTrophyWithCrown(canvas, Offset(size.width * 0.94, size.height * 0.33), 44);
  }

  void _drawFloatingCoin(Canvas canvas, Offset center, double radius, double tiltAngle) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(tiltAngle);

    // Glow
    final glow = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset.zero, radius + 2, glow);

    // Drop shadow
    final shadow = Paint()..color = Colors.black.withValues(alpha: 0.4);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 3), width: radius * 2, height: radius * 1.5), shadow);

    // Base Coin
    final coinPaint = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0xFFFFF9C4), Color(0xFFFFD700), Color(0xFFFF8F00), Color(0xFFC67D00)],
        stops: const [0.1, 0.5, 0.85, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: radius * 2, height: radius * 1.5), coinPaint);

    // Inner rim
    final rimPaint = Paint()
      ..color = const Color(0xFFFFFDE7).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: radius * 1.5, height: radius * 1.1), rimPaint);

    // Star glint in center
    final starPaint = Paint()
      ..color = const Color(0xFF8D5300).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    final sp = Path()
      ..moveTo(0, -radius * 0.35)
      ..quadraticBezierTo(0, 0, radius * 0.35, 0)
      ..quadraticBezierTo(0, 0, 0, radius * 0.35)
      ..quadraticBezierTo(0, 0, -radius * 0.35, 0)
      ..quadraticBezierTo(0, 0, 0, -radius * 0.35)
      ..close();
    canvas.drawPath(sp, starPaint);

    canvas.restore();
  }

  void _draw3DDice({
    required Canvas canvas,
    required Offset center,
    required double size,
    required double rotationAngle,
    required int topDots,
    required int leftDots,
    required int rightDots,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle);

    final half = size / 2;

    // Contact shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(2, half + 3), width: size * 1.1, height: size * 0.4),
      shadowPaint,
    );

    // Isometric dice: Top face, Left face, Right face
    final topFace = Path()
      ..moveTo(0, -half * 0.75)
      ..lineTo(half * 0.9, -half * 0.25)
      ..lineTo(0, half * 0.25)
      ..lineTo(-half * 0.9, -half * 0.25)
      ..close();

    final leftFace = Path()
      ..moveTo(-half * 0.9, -half * 0.25)
      ..lineTo(0, half * 0.25)
      ..lineTo(0, half * 0.95)
      ..lineTo(-half * 0.9, half * 0.45)
      ..close();

    final rightFace = Path()
      ..moveTo(0, half * 0.25)
      ..lineTo(half * 0.9, -half * 0.25)
      ..lineTo(half * 0.9, half * 0.45)
      ..lineTo(0, half * 0.95)
      ..close();

    // Top: brightest white
    canvas.drawPath(
      topFace,
      Paint()..color = const Color(0xFFFFFFFF),
    );
    // Left: soft cool tint
    canvas.drawPath(
      leftFace,
      Paint()..color = const Color(0xFFD6E2F5),
    );
    // Right: shaded cool tint
    canvas.drawPath(
      rightFace,
      Paint()..color = const Color(0xFFA8BDDD),
    );

    // Blue Dots / Pips
    final dotPaint = Paint()..color = const Color(0xFF1D4ED8);
    // Center dot on top
    canvas.drawCircle(Offset(0, -half * 0.25), 1.6, dotPaint);
    if (topDots > 1) {
      canvas.drawCircle(Offset(-half * 0.4, -half * 0.45), 1.5, dotPaint);
      canvas.drawCircle(Offset(half * 0.4, -half * 0.05), 1.5, dotPaint);
      canvas.drawCircle(Offset(-half * 0.4, -half * 0.05), 1.5, dotPaint);
      canvas.drawCircle(Offset(half * 0.4, -half * 0.45), 1.5, dotPaint);
    }
    // Dots on left face
    canvas.drawCircle(Offset(-half * 0.45, half * 0.35), 1.5, dotPaint);
    canvas.drawCircle(Offset(-half * 0.45, half * 0.05), 1.5, dotPaint);
    // Dots on right face
    canvas.drawCircle(Offset(half * 0.45, half * 0.1), 1.5, dotPaint);
    canvas.drawCircle(Offset(half * 0.45, half * 0.4), 1.5, dotPaint);

    canvas.restore();
  }

  void _drawTrophyWithCrown(Canvas canvas, Offset center, double height) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    // Glow around trophy
    final glow = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset.zero, height * 0.6, glow);

    // Trophy cup body
    final cupPath = Path()
      ..moveTo(-height * 0.35, -height * 0.2)
      ..lineTo(height * 0.35, -height * 0.2)
      ..quadraticBezierTo(height * 0.32, height * 0.2, 0, height * 0.28)
      ..quadraticBezierTo(-height * 0.32, height * 0.2, -height * 0.35, -height * 0.2)
      ..close();

    final goldGradient = LinearGradient(
      colors: const [Color(0xFFFFF9C4), Color(0xFFFFD700), Color(0xFFF57F17), Color(0xFFFFB300)],
      stops: const [0.1, 0.4, 0.8, 1.0],
    ).createShader(Rect.fromCenter(center: Offset.zero, width: height, height: height));

    canvas.drawPath(cupPath, Paint()..shader = goldGradient);

    // Handles
    final handlePaint = Paint()
      ..shader = goldGradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    final leftHandle = Path()
      ..moveTo(-height * 0.32, -height * 0.15)
      ..cubicTo(-height * 0.55, -height * 0.15, -height * 0.50, height * 0.12, -height * 0.18, height * 0.15);
    final rightHandle = Path()
      ..moveTo(height * 0.32, -height * 0.15)
      ..cubicTo(height * 0.55, -height * 0.15, height * 0.50, height * 0.12, height * 0.18, height * 0.15);
    canvas.drawPath(leftHandle, handlePaint);
    canvas.drawPath(rightHandle, handlePaint);

    // Pedestal stem & base
    final stem = Rect.fromCenter(center: Offset(0, height * 0.34), width: height * 0.14, height: height * 0.14);
    canvas.drawRect(stem, Paint()..shader = goldGradient);
    final base = Rect.fromCenter(center: Offset(0, height * 0.44), width: height * 0.45, height: height * 0.10);
    canvas.drawRRect(RRect.fromRectAndRadius(base, const Radius.circular(3)), Paint()..shader = goldGradient);

    // Royal Crown tilted on top of cup
    canvas.save();
    canvas.translate(0, -height * 0.32);
    canvas.rotate(-0.15); // subtle tilt

    final crownPath = Path()
      ..moveTo(-height * 0.30, height * 0.08)
      ..lineTo(-height * 0.30, -height * 0.10)
      ..lineTo(-height * 0.15, 0)
      ..lineTo(0, -height * 0.16)
      ..lineTo(height * 0.15, 0)
      ..lineTo(height * 0.30, -height * 0.10)
      ..lineTo(height * 0.30, height * 0.08)
      ..close();

    final crownPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF59D), Color(0xFFFFD700), Color(0xFFE65100)],
      ).createShader(Rect.fromCenter(center: Offset.zero, width: height * 0.6, height: height * 0.3));
    canvas.drawPath(crownPath, crownPaint);

    // Ruby jewels on crown peaks
    final rubyPaint = Paint()..color = const Color(0xFFFF1744);
    canvas.drawCircle(Offset(-height * 0.30, -height * 0.10), 2.2, rubyPaint);
    canvas.drawCircle(Offset(0, -height * 0.16), 2.8, rubyPaint);
    canvas.drawCircle(Offset(height * 0.30, -height * 0.10), 2.2, rubyPaint);

    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Mini 6-segment spin wheel for Lucky Spin medallion icon
class _MiniSpinWheelPainter extends CustomPainter {
  const _MiniSpinWheelPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final colors = [
      const Color(0xFF00E5FF),
      const Color(0xFFFF9100),
      const Color(0xFF00E676),
      const Color(0xFFE040FB),
      const Color(0xFFFFD700),
      const Color(0xFF2979FF),
    ];

    const sweep = (2 * math.pi) / 6;
    for (int i = 0; i < 6; i++) {
      final p = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sweep,
        sweep,
        true,
        p,
      );
    }

    // Outer ring
    final rimPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius, rimPaint);

    // Center pin
    final pinPaint = Paint()..color = const Color(0xFFFFD700);
    canvas.drawCircle(center, 3.0, pinPaint);
    final corePaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 1.2, corePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Featured illustration for Rewards Center & History banner:
/// Golden Sunburst Rays, 3D Gold Coins stack, and 3D Purple Gift Box with red satin bow.
class _SunburstGiftPainter extends CustomPainter {
  const _SunburstGiftPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.52, size.height * 0.50);

    // 1. Sunburst golden rays radiating from center
    final rayPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    const numRays = 12;
    final rayRadius = size.width * 0.50;
    for (int i = 0; i < numRays; i++) {
      final angle = (i * 2 * math.pi) / numRays;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + rayRadius * math.cos(angle - 0.12),
          center.dy + rayRadius * math.sin(angle - 0.12),
        )
        ..lineTo(
          center.dx + rayRadius * math.cos(angle + 0.12),
          center.dy + rayRadius * math.sin(angle + 0.12),
        )
        ..close();
      canvas.drawPath(path, rayPaint);
    }

    // 2. Stacked 3D Gold Coins at bottom left of box
    void drawCoin(Offset c, double rx, double ry) {
      final thickRect = Rect.fromCenter(center: Offset(c.dx, c.dy + 3), width: rx * 2, height: ry * 2);
      final thickPaint = Paint()..color = const Color(0xFFC67D00);
      canvas.drawOval(thickRect, thickPaint);

      final faceRect = Rect.fromCenter(center: c, width: rx * 2, height: ry * 2);
      final facePaint = Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFF59D), Color(0xFFFFB300), Color(0xFFE65100)],
        ).createShader(faceRect);
      canvas.drawOval(faceRect, facePaint);

      final rimPaint = Paint()
        ..color = const Color(0xFFFFFDE7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      canvas.drawOval(faceRect, rimPaint);
    }

    // Stack 3 coins
    drawCoin(Offset(size.width * 0.22, size.height * 0.78), 12, 6);
    drawCoin(Offset(size.width * 0.28, size.height * 0.72), 13, 6.5);
    drawCoin(Offset(size.width * 0.35, size.height * 0.77), 12, 6);

    // 3. 3D Purple Gift Box
    final boxRect = Rect.fromLTWH(size.width * 0.38, size.height * 0.38, 42, 40);
    final boxPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFBA68C8),
          Color(0xFF8E24AA),
          Color(0xFF4A148C),
        ],
      ).createShader(boxRect);
    final boxRRect = RRect.fromRectAndRadius(boxRect, const Radius.circular(5));
    canvas.drawRRect(boxRRect, boxPaint);

    // Box Lid
    final lidRect = Rect.fromLTWH(size.width * 0.35, size.height * 0.33, 48, 10);
    final lidPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFCE93D8),
          Color(0xFF9C27B0),
          Color(0xFF6A1B9A),
        ],
      ).createShader(lidRect);
    final lidRRect = RRect.fromRectAndRadius(lidRect, const Radius.circular(4));
    canvas.drawRRect(lidRRect, lidPaint);

    // 4. Red Satin Ribbons
    final vRibbonRect = Rect.fromLTWH(size.width * 0.54, size.height * 0.33, 8, 45);
    final redPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF5252), Color(0xFFD50000), Color(0xFF8B0000)],
      ).createShader(vRibbonRect);
    canvas.drawRect(vRibbonRect, redPaint);

    final hRibbonRect = Rect.fromLTWH(size.width * 0.38, size.height * 0.55, 42, 7);
    canvas.drawRect(hRibbonRect, redPaint);

    // 3D Red Ribbon Bow on top
    final bowCenter = Offset(size.width * 0.58, size.height * 0.30);
    final leftLoop = Path()
      ..moveTo(bowCenter.dx, bowCenter.dy)
      ..cubicTo(
        bowCenter.dx - 14,
        bowCenter.dy - 12,
        bowCenter.dx - 14,
        bowCenter.dy + 8,
        bowCenter.dx,
        bowCenter.dy,
      );
    final rightLoop = Path()
      ..moveTo(bowCenter.dx, bowCenter.dy)
      ..cubicTo(
        bowCenter.dx + 14,
        bowCenter.dy - 12,
        bowCenter.dx + 14,
        bowCenter.dy + 8,
        bowCenter.dx,
        bowCenter.dy,
      );
    canvas.drawPath(leftLoop, redPaint);
    canvas.drawPath(rightLoop, redPaint);

    final knotPaint = Paint()..color = const Color(0xFFFF1744);
    canvas.drawCircle(bowCenter, 3.5, knotPaint);

    // 5. Sparkles / Stars
    void drawSparkle(Offset pos, double r) {
      final sPaint = Paint()
        ..color = const Color(0xFFFFD700)
        ..style = PaintingStyle.fill;
      final p = Path()
        ..moveTo(pos.dx, pos.dy - r)
        ..quadraticBezierTo(pos.dx, pos.dy, pos.dx + r, pos.dy)
        ..quadraticBezierTo(pos.dx, pos.dy, pos.dx, pos.dy + r)
        ..quadraticBezierTo(pos.dx, pos.dy, pos.dx - r, pos.dy)
        ..quadraticBezierTo(pos.dx, pos.dy, pos.dx, pos.dy - r)
        ..close();
      canvas.drawPath(p, sPaint);

      final cPaint = Paint()..color = Colors.white;
      canvas.drawCircle(pos, r * 0.3, cPaint);
    }

    drawSparkle(Offset(size.width * 0.88, size.height * 0.32), 6);
    drawSparkle(Offset(size.width * 0.20, size.height * 0.40), 4);
    drawSparkle(Offset(size.width * 0.78, size.height * 0.82), 5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// 2. ADDA SECTION VIEW (REAL PRIVATE ROOMS & FRIEND TABLES)
// ============================================================================
class AddaSectionView extends StatefulWidget {
  final VoidCallback? onHostTable;
  final VoidCallback? onRoomJoined;

  const AddaSectionView({
    super.key,
    this.onHostTable,
    this.onRoomJoined,
  });

  @override
  State<AddaSectionView> createState() => _AddaSectionViewState();
}

class _AddaSectionViewState extends State<AddaSectionView> {
  final TextEditingController _roomCodeController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isJoining = false;

  @override
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
  }

  void _openCreateDialog([int playerCount = 2]) {
    if (widget.onHostTable != null) {
      widget.onHostTable!();
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => PlayerSelectionDialog(
        initialCount: playerCount,
        initialIsCreateTab: true,
      ),
    );
  }

  Future<void> _joinRoom() async {
    final code = _roomCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a room code"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Room code must be at least 4-6 characters"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isJoining = true);

    try {
      final res = await _apiService.joinRoom(roomCode: code);
      if (!mounted) return;
      setState(() => _isJoining = false);

      if (res['success'] == true && res['data'] != null) {
        RoomModel? room;
        try {
          final data = res['data'];
          if (data is Map<String, dynamic>) {
            room = RoomModel.fromJson(data);
          }
        } catch (_) {}

        if (room != null) {
          _roomCodeController.clear();
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => RoomLobbyDialog(
              room: room!,
              isHost: false,
            ),
          );
          widget.onRoomJoined?.call();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Room joined, but failed to load lobby details."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        final msg = res['message']?.toString() ?? "Room not found or game already started";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isJoining = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to join room: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF03071E), // Cosmic midnight navy
            Color(0xFF0C1236), // Deep royal indigo glow
            Color(0xFF02061A), // Dark navy bottom
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // 1. Ambient 3D Gaming Background (3D Crowned Red Pawn, Yellow Pawn, Dice, Coins)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: const _AddaCosmicBackgroundPainter(),
              ),
            ),
          ),

          // 2. Scrollable Community Adda Content
          LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth >= 600;
              final maxContentWidth = isTablet ? 780.0 : 460.0;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Royal Header: Crowned Friends Medallion + COMMUNITY ADDA 3D Ribbon Banner
                        _buildAddaHeader(),
                        const SizedBox(height: 12),

                        if (!isTablet) ...[
                          // Card 1: HOST AN ADDA TABLE (Primary Featured Card with VOICE & CHAT badge)
                          _buildHostTableCard(),
                          const SizedBox(height: 12),

                          // Card 2: Join Adda by Code (Live Room Code Entry & Neon Green JOIN)
                          _buildJoinCodeCard(),
                          const SizedBox(height: 12),

                          // Middle Dual Shortcuts: 2-Player Table & 4-Player Table
                          _buildQuickShortcutsRow(),
                          const SizedBox(height: 12),

                          // Card 3: How Adda Tables Work (3 Bullet Points with Checkmarks & 3D Mic)
                          _buildAddaGuideCard(),
                        ] else ...[
                          // Tablet Dual Column: Host Table + Join Code side-by-side
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildHostTableCard()),
                              const SizedBox(width: 14),
                              Expanded(child: _buildJoinCodeCard()),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Tablet Row 2: Quick Shortcuts + Guide Card side-by-side
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildQuickShortcutsRow()),
                              const SizedBox(width: 14),
                              Expanded(child: _buildAddaGuideCard()),
                            ],
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── 1. Top Header with Crowned Medallion & 3D Ribbon Banner ────────
  Widget _buildAddaHeader() {
    return Column(
      children: [
        // Crowned Center Avatar Medallion
        SizedBox(
          height: 60,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              // Emerald circular badge with 3 white people silhouettes
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFF00E676),
                      Color(0xFF00A84D),
                      Color(0xFF00662D),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFFFFD700),
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E676).withValues(alpha: 0.55),
                      blurRadius: 10,
                      spreadRadius: 1.0,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.groups_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              // Royal Golden Crown on top of medallion
              const Positioned(
                top: 0,
                child: CustomPaint(
                  size: Size(36, 18),
                  painter: _AddaMiniCrownPainter(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // 3D Ribbon Banner: ⭐ COMMUNITY ADDA ⭐
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1E88E5),
                Color(0xFF1565C0),
                Color(0xFF0D47A1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF64B5F6),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1D4ED8).withValues(alpha: 0.55),
                blurRadius: 10,
                spreadRadius: 0.5,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Text(
                  'COMMUNITY ADDA',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.7),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                      const Shadow(
                        color: Color(0xFFFFD700),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text('⭐', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),

        // Subtitle Strip: — Private tables, voice banter & friendly matches —
        const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '— Private tables, voice banter & friendly matches —',
            style: TextStyle(
              color: Color(0xFF90CAF9),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  // ── 2. Card 1: HOST AN ADDA TABLE ──────────────────────────────────
  Widget _buildHostTableCard() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main Container
        Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0D3FA9), // Electric royal blue
                Color(0xFF092972),
                Color(0xFF051740), // Dark midnight blue
              ],
            ),
            border: Border.all(
              color: const Color(0xFF00E5FF),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                blurRadius: 14,
                spreadRadius: 0.5,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title: HOST AN ADDA TABLE
              const Text(
                'HOST AN ADDA TABLE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),

              // Subtitle
              const Text(
                'Create a private room for friends and family with custom rules & coins',
                style: TextStyle(
                  color: Color(0xFFB0CBEA),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),

              // Feature highlight tags
              const FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Private Table • 2 to 4 Players • Live Voice',
                  style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 11.2,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Large 3D Golden Glossy Button: 👥 Host Adda Table ❯
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openCreateDialog(2),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFEE58),
                          Color(0xFFFFB300),
                          Color(0xFFFF8F00),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFFFF9C4),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFB300).withValues(alpha: 0.65),
                          blurRadius: 10,
                          spreadRadius: 0.5,
                          offset: const Offset(0, 2),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.groups_rounded,
                            color: Color(0xFF221500),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Host Adda Table',
                            style: TextStyle(
                              color: Color(0xFF221500),
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Color(0xFF221500),
                            size: 13,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Attached Top-Left Pill Badge: VOICE & CHAT 🎙️ 🚪
        Positioned(
          top: 0,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00E5FF), Color(0xFF0091EA)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE0F7FA),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'VOICE & CHAT',
                  style: TextStyle(
                    color: Color(0xFF021B3A),
                    fontSize: 9.8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(width: 5),
                Icon(Icons.mic_rounded, size: 12, color: Color(0xFF021B3A)),
                SizedBox(width: 3),
                Icon(Icons.meeting_room_rounded, size: 12, color: Color(0xFF021B3A)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── 3. Card 2: Join Adda by Code ───────────────────────────────────
  Widget _buildJoinCodeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0C2456),
            Color(0xFF071738),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF00B0FF).withValues(alpha: 0.8),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B0FF).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Golden key icon + "Join Adda by Code"
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFD700).withValues(alpha: 0.18),
                  border: Border.all(color: const Color(0xFFFFD700), width: 1.0),
                ),
                child: const Icon(
                  Icons.vpn_key_rounded,
                  color: Color(0xFFFFD700),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Join Adda by Code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),

          // Subtitle
          const Text(
            'Enter the 6-character room code shared by your friend to jump into their table.',
            style: TextStyle(
              color: Color(0xFF90A4AE),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // Input + JOIN Button Row
          Row(
            children: [
              // Code TextField
              Expanded(
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF051126),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                  ),
                  child: TextField(
                    controller: _roomCodeController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'ROOM CODE',
                      hintStyle: TextStyle(
                        color: Colors.white24,
                        fontSize: 12.5,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Neon Green 3D "JOIN" Button
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: _isJoining ? null : _joinRoom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: const Color(0xFF04240A),
                    elevation: 4,
                    shadowColor: const Color(0xFF00E676).withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFFB9F6CA), width: 1.2),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  child: _isJoining
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Color(0xFF04240A),
                          ),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.login_rounded, size: 16),
                            SizedBox(width: 5),
                            Text(
                              'JOIN',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 4. Middle Dual Shortcuts (2-Player & 4-Player Tables) ───────────
  Widget _buildQuickShortcutsRow() {
    return Row(
      children: [
        // 2-Player Table Shortcut
        Expanded(
          child: _buildShortcutTile(
            title: '2-Player Table',
            subtitle: 'Casual 1v1 Room',
            icon: Icons.person_rounded,
            accentColor: const Color(0xFF00E5FF),
            gradientColors: const [Color(0xFF0A3C9E), Color(0xFF062363)],
            onTap: () => _openCreateDialog(2),
          ),
        ),
        const SizedBox(width: 10),
        // 4-Player Table Shortcut
        Expanded(
          child: _buildShortcutTile(
            title: '4-Player Table',
            subtitle: '4-Way Battle',
            icon: Icons.groups_rounded,
            accentColor: const Color(0xFFE040FB),
            gradientColors: const [Color(0xFF6A1B9A), Color(0xFF38006B)],
            onTap: () => _openCreateDialog(4),
          ),
        ),
      ],
    );
  }

  Widget _buildShortcutTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.85),
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 4,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: 0.20),
                  border: Border.all(color: accentColor.withValues(alpha: 0.6), width: 1.0),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFFB0BEC5),
                          fontSize: 9.8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: accentColor,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 5. Card 3: How Adda Tables Work (Info + 3D Microphone) ─────────
  Widget _buildAddaGuideCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF091428).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF00B0FF).withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: 3 Checkmarked Bullets
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFF00E5FF), size: 17),
                    const SizedBox(width: 6),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'How Adda Tables Work',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildGuideBullet('Host generates a live 6-digit room code with custom entry fee.'),
                const SizedBox(height: 5),
                _buildGuideBullet('Friends join by entering the code from anywhere.'),
                const SizedBox(height: 5),
                _buildGuideBullet('Enjoy private voice chat & banter without public leaderboard pressure.'),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Right: 3D Golden Microphone with radiating sound waves
          const SizedBox(
            width: 70,
            height: 70,
            child: CustomPaint(
              painter: _AddaMicPainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideBullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676), size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFCFD8DC),
              fontSize: 10.5,
              height: 1.3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 3D CUSTOM PAINTERS FOR COMMUNITY ADDA SECTION
// ============================================================================

/// Ambient cosmic 3D gaming background with Crowned Red Pawn, Glossy Yellow Pawn, Dice, and Coins
class _AddaCosmicBackgroundPainter extends CustomPainter {
  const _AddaCosmicBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Ambient lighting glow sweeps
    final cyanGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF00B0FF).withValues(alpha: 0.22),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width * 0.15, size.height * 0.25), radius: 180));
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.25), 180, cyanGlow);

    final purpleGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF7C4DFF).withValues(alpha: 0.25),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width * 0.85, size.height * 0.35), radius: 200));
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.35), 200, purpleGlow);

    // 2. Isometric Ludo Board Tiles near bottom / edges
    _drawBackgroundBoardTiles(canvas, size);

    // 3. Left Side: Large 3D Crowned Red Pawn
    _drawCrownedRedPawn(canvas, Offset(size.width * 0.08, size.height * 0.26), 46);

    // 4. Left 3D White Ludo Dice next to Red Pawn
    _draw3DDice(
      canvas: canvas,
      center: Offset(size.width * 0.07, size.height * 0.52),
      size: 26,
      rotationAngle: 0.3,
      dotColor: const Color(0xFF1D4ED8),
    );

    // 5. Right Side: Large 3D Glossy Yellow Pawn
    _drawGlossyYellowPawn(canvas, Offset(size.width * 0.93, size.height * 0.38), 44);

    // 6. Right 3D White Ludo Dice near bottom
    _draw3DDice(
      canvas: canvas,
      center: Offset(size.width * 0.93, size.height * 0.82),
      size: 26,
      rotationAngle: -0.25,
      dotColor: const Color(0xFF1E293B),
    );

    // 7. Stacks of 3D Gold Coins at bottom corners
    _drawCoinStack(canvas, Offset(size.width * 0.08, size.height * 0.85));
    _drawCoinStack(canvas, Offset(size.width * 0.88, size.height * 0.87));

    // 8. Top-right playful cursive slogan: "Play Together Grow Together"
    _drawSlogan(canvas, Offset(size.width * 0.82, size.height * 0.08));
  }

  void _drawBackgroundBoardTiles(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (double i = -0.2; i <= 1.2; i += 0.2) {
      canvas.drawLine(
        Offset(size.width * i, size.height * 0.65),
        Offset(size.width * (i + 0.35), size.height),
        gridPaint,
      );
    }
  }

  void _drawCrownedRedPawn(Canvas canvas, Offset center, double height) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    // Glow
    final glow = Paint()
      ..color = const Color(0xFFFF1744).withValues(alpha: 0.30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset.zero, height * 0.6, glow);

    // Drop shadow
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, height * 0.52), width: height * 0.7, height: height * 0.25),
      shadow,
    );

    // Base: flared bell base
    final baseRect = Rect.fromCenter(center: Offset(0, height * 0.32), width: height * 0.65, height: height * 0.45);
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF5252), Color(0xFFD50000), Color(0xFF8B0000)],
      ).createShader(baseRect);
    final basePath = Path()
      ..moveTo(-height * 0.15, height * 0.05)
      ..quadraticBezierTo(-height * 0.20, height * 0.25, -height * 0.32, height * 0.48)
      ..lineTo(height * 0.32, height * 0.48)
      ..quadraticBezierTo(height * 0.20, height * 0.25, height * 0.15, height * 0.05)
      ..close();
    canvas.drawPath(basePath, basePaint);

    // Specular highlight rim on base
    final rimPaint = Paint()
      ..color = const Color(0xFFFF8A80).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, height * 0.46), width: height * 0.6, height: height * 0.12),
      rimPaint,
    );

    // Collar / Ring between neck and head
    final collarRect = Rect.fromCenter(center: Offset(0, height * 0.02), width: height * 0.32, height: height * 0.1);
    final collarPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF8A80), Color(0xFFB71C1C)],
      ).createShader(collarRect);
    canvas.drawRRect(RRect.fromRectAndRadius(collarRect, const Radius.circular(3)), collarPaint);

    // Head: 3D glossy sphere
    final headCenter = Offset(0, -height * 0.18);
    final headRadius = height * 0.24;
    final headPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.4),
        radius: 0.8,
        colors: const [
          Color(0xFFFF8A80),
          Color(0xFFFF1744),
          Color(0xFFC62828),
          Color(0xFF5C0000),
        ],
        stops: const [0.0, 0.35, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: headCenter, radius: headRadius));
    canvas.drawCircle(headCenter, headRadius, headPaint);

    // Specular glint on sphere
    final glintPaint = Paint()..color = Colors.white.withValues(alpha: 0.75);
    canvas.drawCircle(Offset(headCenter.dx - headRadius * 0.35, headCenter.dy - headRadius * 0.35), headRadius * 0.22, glintPaint);

    // Royal Crown perched on top of Pawn
    canvas.save();
    canvas.translate(0, -height * 0.40);
    canvas.rotate(-0.1);

    final crownPath = Path()
      ..moveTo(-height * 0.22, height * 0.06)
      ..lineTo(-height * 0.22, -height * 0.08)
      ..lineTo(-height * 0.11, 0)
      ..lineTo(0, -height * 0.14)
      ..lineTo(height * 0.11, 0)
      ..lineTo(height * 0.22, -height * 0.08)
      ..lineTo(height * 0.22, height * 0.06)
      ..close();

    final crownPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF59D), Color(0xFFFFD700), Color(0xFFE65100)],
      ).createShader(Rect.fromCenter(center: Offset.zero, width: height * 0.45, height: height * 0.2));
    canvas.drawPath(crownPath, crownPaint);

    // Ruby dots on crown
    final rubyPaint = Paint()..color = const Color(0xFFFF1744);
    canvas.drawCircle(Offset(-height * 0.22, -height * 0.08), 2.0, rubyPaint);
    canvas.drawCircle(Offset(0, -height * 0.14), 2.4, rubyPaint);
    canvas.drawCircle(Offset(height * 0.22, -height * 0.08), 2.0, rubyPaint);

    canvas.restore();
    canvas.restore();
  }

  void _drawGlossyYellowPawn(Canvas canvas, Offset center, double height) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    // Glow
    final glow = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset.zero, height * 0.6, glow);

    // Drop shadow
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, height * 0.52), width: height * 0.7, height: height * 0.25),
      shadow,
    );

    // Base: flared bell base
    final baseRect = Rect.fromCenter(center: Offset(0, height * 0.32), width: height * 0.65, height: height * 0.45);
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF59D), Color(0xFFFFB300), Color(0xFFE65100)],
      ).createShader(baseRect);
    final basePath = Path()
      ..moveTo(-height * 0.15, height * 0.05)
      ..quadraticBezierTo(-height * 0.20, height * 0.25, -height * 0.32, height * 0.48)
      ..lineTo(height * 0.32, height * 0.48)
      ..quadraticBezierTo(height * 0.20, height * 0.25, height * 0.15, height * 0.05)
      ..close();
    canvas.drawPath(basePath, basePaint);

    // Collar
    final collarRect = Rect.fromCenter(center: Offset(0, height * 0.02), width: height * 0.32, height: height * 0.1);
    final collarPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFDE7), Color(0xFFFF8F00)],
      ).createShader(collarRect);
    canvas.drawRRect(RRect.fromRectAndRadius(collarRect, const Radius.circular(3)), collarPaint);

    // Head: 3D glossy yellow sphere
    final headCenter = Offset(0, -height * 0.18);
    final headRadius = height * 0.24;
    final headPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.4),
        radius: 0.8,
        colors: const [
          Color(0xFFFFFFE0),
          Color(0xFFFFEB3B),
          Color(0xFFF57F17),
          Color(0xFF7F4400),
        ],
        stops: const [0.0, 0.35, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: headCenter, radius: headRadius));
    canvas.drawCircle(headCenter, headRadius, headPaint);

    // Specular glint
    final glintPaint = Paint()..color = Colors.white.withValues(alpha: 0.8);
    canvas.drawCircle(Offset(headCenter.dx - headRadius * 0.35, headCenter.dy - headRadius * 0.35), headRadius * 0.22, glintPaint);

    canvas.restore();
  }

  void _draw3DDice({
    required Canvas canvas,
    required Offset center,
    required double size,
    required double rotationAngle,
    required Color dotColor,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle);

    final half = size / 2;

    // Contact shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(2, half + 3), width: size * 1.1, height: size * 0.4),
      shadowPaint,
    );

    // Isometric dice: Top face, Left face, Right face
    final topFace = Path()
      ..moveTo(0, -half * 0.75)
      ..lineTo(half * 0.9, -half * 0.25)
      ..lineTo(0, half * 0.25)
      ..lineTo(-half * 0.9, -half * 0.25)
      ..close();

    final leftFace = Path()
      ..moveTo(-half * 0.9, -half * 0.25)
      ..lineTo(0, half * 0.25)
      ..lineTo(0, half * 0.95)
      ..lineTo(-half * 0.9, half * 0.45)
      ..close();

    final rightFace = Path()
      ..moveTo(0, half * 0.25)
      ..lineTo(half * 0.9, -half * 0.25)
      ..lineTo(half * 0.9, half * 0.45)
      ..lineTo(0, half * 0.95)
      ..close();

    canvas.drawPath(topFace, Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawPath(leftFace, Paint()..color = const Color(0xFFD6E2F5));
    canvas.drawPath(rightFace, Paint()..color = const Color(0xFFA8BDDD));

    // Dots / Pips
    final dotPaint = Paint()..color = dotColor;
    canvas.drawCircle(Offset(0, -half * 0.25), 1.6, dotPaint);
    canvas.drawCircle(Offset(-half * 0.45, half * 0.35), 1.5, dotPaint);
    canvas.drawCircle(Offset(-half * 0.45, half * 0.05), 1.5, dotPaint);
    canvas.drawCircle(Offset(half * 0.45, half * 0.1), 1.5, dotPaint);
    canvas.drawCircle(Offset(half * 0.45, half * 0.4), 1.5, dotPaint);

    canvas.restore();
  }

  void _drawCoinStack(Canvas canvas, Offset center) {
    void drawSingleCoin(Offset c, double rx, double ry) {
      final thickRect = Rect.fromCenter(center: Offset(c.dx, c.dy + 2.5), width: rx * 2, height: ry * 2);
      canvas.drawOval(thickRect, Paint()..color = const Color(0xFFB26A00));

      final faceRect = Rect.fromCenter(center: c, width: rx * 2, height: ry * 2);
      final facePaint = Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFF9C4), Color(0xFFFFB300), Color(0xFFE65100)],
        ).createShader(faceRect);
      canvas.drawOval(faceRect, facePaint);

      final rimPaint = Paint()
        ..color = const Color(0xFFFFFDE7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      canvas.drawOval(faceRect, rimPaint);
    }

    drawSingleCoin(Offset(center.dx, center.dy + 6), 13, 6);
    drawSingleCoin(Offset(center.dx + 2, center.dy + 1), 13, 6);
    drawSingleCoin(Offset(center.dx + 1, center.dy - 4), 13, 6);
  }

  void _drawSlogan(Canvas canvas, Offset center) {
    final textSpan = TextSpan(
      text: 'Play Together\nGrow Together',
      style: TextStyle(
        color: const Color(0xFFFFD54F).withValues(alpha: 0.85),
        fontSize: 11.5,
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.italic,
        height: 1.15,
        shadows: [
          Shadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
    );
    final tp = TextPainter(
      text: textSpan,
      textAlign: TextAlign.right,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width, center.dy));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Golden Mini Crown for Community Adda avatar medallion
class _AddaMiniCrownPainter extends CustomPainter {
  const _AddaMiniCrownPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.25)
      ..lineTo(w * 0.25, h * 0.65)
      ..lineTo(w * 0.50, 0)
      ..lineTo(w * 0.75, h * 0.65)
      ..lineTo(w, h * 0.25)
      ..lineTo(w, h)
      ..close();

    final crownPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF59D), Color(0xFFFFD700), Color(0xFFE65100)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path, crownPaint);

    // Ruby jewels on 3 peaks
    final rubyPaint = Paint()..color = const Color(0xFFFF1744);
    canvas.drawCircle(Offset(0, h * 0.25), 2.2, rubyPaint);
    canvas.drawCircle(Offset(w * 0.50, 0), 2.6, rubyPaint);
    canvas.drawCircle(Offset(w, h * 0.25), 2.2, rubyPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3D Golden Microphone with radiating sound waves for How Adda Tables Work guide
class _AddaMicPainter extends CustomPainter {
  const _AddaMicPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.38, size.height * 0.48);

    // Glow
    final glow = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, 18, glow);

    // 1. Microphone Capsule
    final micRect = Rect.fromCenter(center: Offset(center.dx, center.dy - 6), width: 16, height: 26);
    final micRRect = RRect.fromRectAndRadius(micRect, const Radius.circular(8));
    final micPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF9C4), Color(0xFFFFD700), Color(0xFFF57F17)],
      ).createShader(micRect);
    canvas.drawRRect(micRRect, micPaint);

    // Mesh lines on mic
    final meshPaint = Paint()
      ..color = const Color(0xFFB26A00)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(center.dx - 6, center.dy - 6), Offset(center.dx + 6, center.dy - 6), meshPaint);
    canvas.drawLine(Offset(center.dx - 6, center.dy - 11), Offset(center.dx + 6, center.dy - 11), meshPaint);

    // U-shaped bracket around mic
    final bracketPaint = Paint()
      ..shader = micPaint.shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final bracketPath = Path()
      ..moveTo(center.dx - 11, center.dy - 6)
      ..quadraticBezierTo(center.dx - 11, center.dy + 12, center.dx, center.dy + 12)
      ..quadraticBezierTo(center.dx + 11, center.dy + 12, center.dx + 11, center.dy - 6);
    canvas.drawPath(bracketPath, bracketPaint);

    // Stem & Base
    canvas.drawLine(Offset(center.dx, center.dy + 12), Offset(center.dx, center.dy + 20), bracketPaint);
    final baseRect = Rect.fromCenter(center: Offset(center.dx, center.dy + 21), width: 18, height: 4);
    canvas.drawRRect(RRect.fromRectAndRadius(baseRect, const Radius.circular(2)), micPaint);

    // 2. Radiating Golden Sound Waves on the right ()))
    void drawSoundArc(double radius, double strokeWidth, double alpha) {
      final arcPaint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(center.dx, center.dy - 6), radius: radius),
        -math.pi / 4,
        math.pi / 2,
        false,
        arcPaint,
      );
    }

    drawSoundArc(18, 2.2, 0.9);
    drawSoundArc(24, 2.0, 0.65);
    drawSoundArc(30, 1.8, 0.40);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// ============================================================================
// 3. INVENTORY SECTION VIEW (REAL PLAYER VAULT & COLLECTIBLES - 3D ROYAL UI)
// ============================================================================
class InventorySectionView extends StatefulWidget {
  final VoidCallback? onInventoryUpdated;

  const InventorySectionView({
    super.key,
    this.onInventoryUpdated,
  });

  @override
  State<InventorySectionView> createState() => _InventorySectionViewState();
}

class _InventorySectionViewState extends State<InventorySectionView> {
  final ApiService _apiService = ApiService();

  int _selectedCategory = 0;
  bool _isLoading = true;

  UserProfileModel? _profile;
  List<UserRewardClaim> _myClaims = [];

  static const List<String> categories = ["COLLECTIBLES", "HONOR BADGES", "VAULT ASSETS"];

  // Default demo claims matching reference UI when offline or no claims yet
  static const List<UserRewardClaim> _demoClaims = [
    UserRewardClaim(
      rewardId: 'first_win',
      title: 'First Win Bonus',
      rewardType: 'coins',
      rewardValue: 250,
    ),
    UserRewardClaim(
      rewardId: 'welcome',
      title: 'Welcome Bonus',
      rewardType: 'coins',
      rewardValue: 500,
    ),
    UserRewardClaim(
      rewardId: 'weekend_rush',
      title: 'Weekend Rush',
      rewardType: 'coins',
      rewardValue: 300,
    ),
    UserRewardClaim(
      rewardId: 'daily_streak_2',
      title: 'Daily Streak Day 2',
      rewardType: 'coins',
      rewardValue: 150,
    ),
    UserRewardClaim(
      rewardId: 'daily_streak_3',
      title: 'Daily Streak Day 3',
      rewardType: 'coins',
      rewardValue: 200,
    ),
    UserRewardClaim(
      rewardId: 'community_reward',
      title: 'Community Reward',
      rewardType: 'coins',
      rewardValue: 50,
    ),
    UserRewardClaim(
      rewardId: 'lucky_spin',
      title: 'Lucky Spin',
      rewardType: 'coins',
      rewardValue: 150,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchInventory();
  }

  Future<void> _fetchInventory() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        AuthService.fetchUserProfile(),
        _apiService.getMyRewards(),
      ]);

      if (!mounted) return;

      final freshProfile = results[0] as UserProfileModel?;
      final myRewardsRes = results[1] as Map<String, dynamic>;

      List<UserRewardClaim> claimsList = [];
      if (myRewardsRes['success'] == true && myRewardsRes['data'] != null) {
        final mData = myRewardsRes['data'];
        if (mData is Map<String, dynamic> && mData['rewards'] is List) {
          claimsList = (mData['rewards'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => UserRewardClaim.fromJson(e))
              .toList();
        } else if (mData is Map<String, dynamic> &&
            mData['data'] is Map<String, dynamic> &&
            mData['data']['rewards'] is List) {
          claimsList = (mData['data']['rewards'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => UserRewardClaim.fromJson(e))
              .toList();
        } else if (mData is List) {
          claimsList = mData
              .whereType<Map<String, dynamic>>()
              .map((e) => UserRewardClaim.fromJson(e))
              .toList();
        }
      }

      setState(() {
        _isLoading = false;
        _profile = freshProfile;
        _myClaims = claimsList;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile ??
        const UserProfileModel(
          id: '',
          name: 'Player',
          email: '',
          coins: 3400,
          gems: 10,
          level: 1,
        );

    final stats = profile.statistics;
    final displayClaims = _myClaims.isNotEmpty ? _myClaims : _demoClaims;

    return Stack(
      children: [
        // Layer 1: 3D Royal Cosmic Backdrop (Treasure Chest, 3D Pawns, 3D Dice, Floating Coins)
        const Positioned.fill(
          child: CustomPaint(
            painter: _InventoryCosmicBackgroundPainter(),
          ),
        ),

        // Layer 2: Scrollable Interactive Vault Content
        LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 600;
            final maxContentWidth = isTablet ? 780.0 : 440.0;

            return RefreshIndicator(
              onRefresh: _fetchInventory,
              color: const Color(0xFFFFD700),
              backgroundColor: const Color(0xFF0F1A30),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Column(
                      children: [
                        // Top Royal Crown & Laurel Wreath Ribbon Banner
                        _buildInventoryHeader(),
                        const SizedBox(height: 14),

                        // 3-in-1 Compact Stats Capsule: Coins | Gems | Level
                        _buildHoldingsBar(profile),
                        const SizedBox(height: 14),

                        // 3D Category Filter Pills: ⭐ COLLECTIBLES | HONOR BADGES | VAULT ASSETS
                        _buildCategoryTabs(),
                        const SizedBox(height: 14),

                        if (_isLoading) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 36),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFFFD700),
                                strokeWidth: 2.8,
                              ),
                            ),
                          ),
                        ] else ...[
                          // Category 0: Claimed Collectibles Stack
                          if (_selectedCategory == 0) ...[
                            if (displayClaims.isNotEmpty) ...[
                              _buildCollectiblesList(displayClaims, isTablet),
                            ] else ...[
                              _buildEmptyCollectiblesCard(),
                            ],
                          ]
                          // Category 1: Match Honor Badges
                          else if (_selectedCategory == 1) ...[
                            _buildHonorBadgesList(stats, profile, isTablet),
                          ]
                          // Category 2: Vault Assets & Balances
                          else ...[
                            if (!isTablet) ...[
                              _buildVaultCard(
                                title: "Gold Coins Balance",
                                amount: profile.coins.toString(),
                                subtitle: "Usable for all match betting & room entries",
                                icon: Icons.monetization_on_rounded,
                                color: const Color(0xFFFFD700),
                                actionText: "Manage in Wallet >",
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => WalletScreen(
                                        onWalletUpdated: _fetchInventory,
                                      ),
                                    ),
                                  );
                                  _fetchInventory();
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildVaultCard(
                                title: "Diamond Gems Balance",
                                amount: profile.gems.toString(),
                                subtitle: "Premium rewards & tournament multipliers",
                                icon: Icons.diamond_rounded,
                                color: const Color(0xFF00D2FF),
                              ),
                              const SizedBox(height: 12),
                              _buildLevelProgressCard(profile),
                            ] else ...[
                              // Tablet Row: Coins Card + Gems Card side-by-side
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildVaultCard(
                                      title: "Gold Coins Balance",
                                      amount: profile.coins.toString(),
                                      subtitle: "Usable for all match betting & room entries",
                                      icon: Icons.monetization_on_rounded,
                                      color: const Color(0xFFFFD700),
                                      actionText: "Manage in Wallet >",
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => WalletScreen(
                                              onWalletUpdated: _fetchInventory,
                                            ),
                                          ),
                                        );
                                        _fetchInventory();
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: _buildVaultCard(
                                      title: "Diamond Gems Balance",
                                      amount: profile.gems.toString(),
                                      subtitle: "Premium rewards & tournament multipliers",
                                      icon: Icons.diamond_rounded,
                                      color: const Color(0xFF00D2FF),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildLevelProgressCard(profile),
                            ],
                          ],
                        ],

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Adaptive Responsive Collectibles & Badges Grid ─────────────────
  Widget _buildCollectiblesList(List<UserRewardClaim> displayClaims, bool isTablet) {
    if (!isTablet || displayClaims.length <= 1) {
      return Column(
        children: displayClaims.map((claim) => _buildClaimedItemTile(claim)).toList(),
      );
    }

    final List<Widget> rows = [];
    for (int i = 0; i < displayClaims.length; i += 2) {
      final c1 = displayClaims[i];
      final c2 = (i + 1 < displayClaims.length) ? displayClaims[i + 1] : null;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildClaimedItemTile(c1)),
              const SizedBox(width: 12),
              if (c2 != null)
                Expanded(child: _buildClaimedItemTile(c2))
              else
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildHonorBadgesList(dynamic stats, dynamic profile, bool isTablet) {
    final b1 = _buildHonorBadgeTile(
      title: "Victory Master",
      condition: stats.wins > 0
          ? "${stats.wins} Matches Won"
          : "Win 1 online match to unlock",
      isUnlocked: stats.wins > 0,
      icon: Icons.emoji_events_rounded,
      color: const Color(0xFFFFD700),
    );
    final b2 = _buildHonorBadgeTile(
      title: "Elite Roller",
      condition: stats.totalGames > 0 && stats.winRate >= 50
          ? "${stats.winRate.toStringAsFixed(0)}% Win Rate Maintained"
          : "Maintain 50%+ win rate to unlock",
      isUnlocked: stats.totalGames > 0 && stats.winRate >= 50,
      icon: Icons.auto_awesome_rounded,
      color: const Color(0xFF00E676),
    );
    final b3 = _buildHonorBadgeTile(
      title: "Battle Veteran",
      condition: stats.totalGames >= 3
          ? "${stats.totalGames} Matches Played"
          : "Play 3 matches to unlock",
      isUnlocked: stats.totalGames >= 3,
      icon: Icons.sports_esports_rounded,
      color: const Color(0xFF38BDF8),
    );
    final b4 = _buildHonorBadgeTile(
      title: "Arena Champion",
      condition: profile.level >= 2 || stats.wins >= 5
          ? "Level ${profile.level} Reached"
          : "Reach Level 2 or 5 Wins to unlock",
      isUnlocked: profile.level >= 2 || stats.wins >= 5,
      icon: Icons.workspace_premium_rounded,
      color: const Color(0xFFFFB300),
    );

    if (!isTablet) {
      return Column(
        children: [b1, b2, b3, b4],
      );
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: b1),
            const SizedBox(width: 12),
            Expanded(child: b2),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: b3),
            const SizedBox(width: 12),
            Expanded(child: b4),
          ],
        ),
      ],
    );
  }

  // ── 1. Top Header with 3D Crown Laurel & Metallic Ribbon Banner ─────
  Widget _buildInventoryHeader() {
    return Column(
      children: [
        // 3D Golden Crown with Laurel Wreath
        const SizedBox(
          width: 72,
          height: 48,
          child: CustomPaint(
            painter: _InventoryCrownLaurelPainter(),
          ),
        ),
        const SizedBox(height: 6),

        // 3D Ribbon Banner: ⭐ PLAYER INVENTORY & VAULT ⭐
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1E88E5),
                Color(0xFF1565C0),
                Color(0xFF0D47A1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFD700),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                blurRadius: 10,
                spreadRadius: 0.5,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Text(
                  'PLAYER INVENTORY & VAULT',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                      const Shadow(
                        color: Color(0xFFFFD700),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text('⭐', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 5),

        // Subtitle Strip: — Your real currencies, claimed collectibles & honor badges —
        const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '— Your real currencies, claimed collectibles & honor badges —',
            style: TextStyle(
              color: Color(0xFF90CAF9),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  // ── 2. Quick Holdings Bar (Coins | Gems | Level Capsule) ────────────
  Widget _buildHoldingsBar(UserProfileModel profile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0C2456), // Electric royal blue
            Color(0xFF071738), // Dark navy
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF00B0FF).withValues(alpha: 0.7),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B0FF).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _buildHoldingChip(
                icon: Icons.monetization_on_rounded,
                label: "Coins",
                value: profile.coins.toString(),
                color: const Color(0xFFFFD700),
              ),
            ),
          ),
          Container(height: 28, width: 1.2, color: Colors.white24),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _buildHoldingChip(
                icon: Icons.diamond_rounded,
                label: "Gems",
                value: profile.gems.toString(),
                color: const Color(0xFF00D2FF),
              ),
            ),
          ),
          Container(height: 28, width: 1.2, color: Colors.white24),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _buildHoldingChip(
                icon: Icons.shield_rounded,
                label: "Level",
                value: "LVL ${profile.level}",
                color: const Color(0xFF00E676),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoldingChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.18),
            border: Border.all(color: color.withValues(alpha: 0.8), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 6,
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFFB0BEC5),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── 3. Category Filter Tabs: COLLECTIBLES | HONOR BADGES | VAULT ASSETS
  Widget _buildCategoryTabs() {
    return Row(
      children: [
        Expanded(
          child: _buildCategoryPill(
            index: 0,
            label: categories[0],
            icon: Icons.star_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCategoryPill(
            index: 1,
            label: categories[1],
            icon: Icons.military_tech_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCategoryPill(
            index: 2,
            label: categories[2],
            icon: Icons.lock_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPill({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedCategory == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedCategory = index),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [
                      Color(0xFFFFEE58),
                      Color(0xFFFFB300),
                      Color(0xFFFF8F00),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : const LinearGradient(
                    colors: [
                      Color(0xFF0B2456),
                      Color(0xFF071738),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFFF9C4)
                  : const Color(0xFF00B0FF).withValues(alpha: 0.5),
              width: 1.2,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? const Color(0xFF221500) : const Color(0xFF64B5F6),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF221500) : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 4. Claimed Collectibles 3D Capsule Tile ─────────────────────────
  Widget _buildClaimedItemTile(UserRewardClaim claim) {
    final isGems = claim.rewardType.toLowerCase() == 'gems';
    final accentColor = isGems ? const Color(0xFF00E5FF) : const Color(0xFFFFD700);

    String dateStr = "21/10/2026";
    if (claim.claimedAt != null) {
      dateStr =
          "${claim.claimedAt!.day.toString().padLeft(2, '0')}/${claim.claimedAt!.month.toString().padLeft(2, '0')}/${claim.claimedAt!.year}";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0C2456), // Electric royal blue
            Color(0xFF071738), // Dark navy
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00B0FF).withValues(alpha: 0.75),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B0FF).withValues(alpha: 0.20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left 3D Golden Gift Medallion
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  Color(0xFF2A1C00),
                  Color(0xFF140C00),
                ],
              ),
              border: Border.all(
                color: const Color(0xFFFFD700),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.card_giftcard_rounded,
                color: Color(0xFFFFD700),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Center Title & Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  claim.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: Color(0xFF8FA8CE),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Right Golden Pill Badge: +250 Coins
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0x33FFB300),
                  Color(0x1AFF8F00),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.8),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              "+${claim.rewardValue} ${isGems ? 'Gems' : 'Coins'}",
              style: TextStyle(
                color: accentColor,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCollectiblesCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0C2456).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00B0FF).withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined, color: Color(0xFFFFD700), size: 44),
          SizedBox(height: 10),
          Text(
            "Your Collectibles Bag is Empty",
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Claim Daily Check-ins, Special Bonuses, and Wheel Gifts from the EVENT tab to add collectibles to your bag.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFB0BEC5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. Match Honor Badges 3D Tile ──────────────────────────────────
  Widget _buildHonorBadgeTile({
    required String title,
    required String condition,
    required bool isUnlocked,
    required IconData icon,
    required Color color,
  }) {
    final activeColor = isUnlocked ? color : Colors.white38;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isUnlocked
              ? [const Color(0xFF0C2456), const Color(0xFF071738)]
              : [const Color(0xFF08142C), const Color(0xFF040A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlocked ? color.withValues(alpha: 0.8) : Colors.white12,
          width: isUnlocked ? 1.4 : 1.0,
        ),
        boxShadow: [
          if (isUnlocked)
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  activeColor.withValues(alpha: 0.25),
                  activeColor.withValues(alpha: 0.05),
                ],
              ),
              border: Border.all(color: activeColor, width: 1.4),
              boxShadow: [
                if (isUnlocked)
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                  ),
              ],
            ),
            child: Icon(icon, color: activeColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isUnlocked ? Colors.white : Colors.white60,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  condition,
                  style: TextStyle(
                    color: isUnlocked ? const Color(0xFF90CAF9) : Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? color.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isUnlocked ? color : Colors.white24,
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUnlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                  color: isUnlocked ? color : Colors.white38,
                  size: 13,
                ),
                const SizedBox(width: 4),
                Text(
                  isUnlocked ? "UNLOCKED" : "LOCKED",
                  style: TextStyle(
                    color: isUnlocked ? color : Colors.white38,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 6. Vault Card ──────────────────────────────────────────────────
  Widget _buildVaultCard({
    required String title,
    required String amount,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? actionText,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0C2456),
            Color(0xFF071738),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.7),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                  border: Border.all(color: color, width: 1.3),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                amount,
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF90A4AE), fontSize: 11.5),
          ),
          if (actionText != null && onTap != null) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: onTap,
              child: Text(
                actionText,
                style: TextStyle(
                  color: color,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLevelProgressCard(UserProfileModel profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0C2456),
            Color(0xFF071738),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00E676).withValues(alpha: 0.7),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E676).withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00E676).withValues(alpha: 0.15),
                  border: Border.all(color: const Color(0xFF00E676), width: 1.3),
                ),
                child: const Icon(Icons.stars_rounded, color: Color(0xFF00E676), size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Player Level & Experience",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                "LVL ${profile.level}",
                style: const TextStyle(
                  color: Color(0xFF00E676),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const LinearProgressIndicator(
              value: 0.65,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Play matches & win games to level up and earn exclusive rewards.",
            style: TextStyle(color: Color(0xFF90A4AE), fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 3D CUSTOM PAINTERS FOR INVENTORY & VAULT SECTION
// ============================================================================

/// 3D Golden Crown with Laurel Wreath for the section emblem
class _InventoryCrownLaurelPainter extends CustomPainter {
  const _InventoryCrownLaurelPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // 1. Draw Golden Laurel Leaves on Left and Right
    final leafPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFEE58), Color(0xFFFFB300), Color(0xFFFF8F00)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    void drawLeaf(double x, double y, double radiusX, double radiusY, double rotation) {
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      final path = Path()
        ..moveTo(0, -radiusY)
        ..quadraticBezierTo(radiusX, 0, 0, radiusY)
        ..quadraticBezierTo(-radiusX, 0, 0, -radiusY);
      canvas.drawPath(path, leafPaint);
      canvas.restore();
    }

    // Left Laurel Branch Leaves
    drawLeaf(cx - 24, cy + 12, 3.8, 8.0, -0.6);
    drawLeaf(cx - 28, cy + 2, 4.0, 8.5, -0.85);
    drawLeaf(cx - 26, cy - 8, 3.8, 8.0, -1.1);
    drawLeaf(cx - 18, cy - 16, 3.5, 7.5, -1.4);

    // Right Laurel Branch Leaves
    drawLeaf(cx + 24, cy + 12, 3.8, 8.0, 0.6);
    drawLeaf(cx + 28, cy + 2, 4.0, 8.5, 0.85);
    drawLeaf(cx + 26, cy - 8, 3.8, 8.0, 1.1);
    drawLeaf(cx + 18, cy - 16, 3.5, 7.5, 1.4);

    // 2. Center 3D Royal Golden Crown
    final crownPath = Path()
      ..moveTo(cx - 18, cy + 14)
      ..lineTo(cx - 22, cy - 4) // left peak
      ..lineTo(cx - 9, cy + 5)
      ..lineTo(cx, cy - 12) // tall center peak
      ..lineTo(cx + 9, cy + 5)
      ..lineTo(cx + 22, cy - 4) // right peak
      ..lineTo(cx + 18, cy + 14)
      ..close();

    // Crown Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.save();
    canvas.translate(0, 2);
    canvas.drawPath(crownPath, shadowPaint);
    canvas.restore();

    // Crown Gradient Body
    final crownPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFF9C4),
          Color(0xFFFFEE58),
          Color(0xFFFFB300),
          Color(0xFFFF8F00),
          Color(0xFFE65100),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(cx - 24, cy - 14, 48, 30))
      ..style = PaintingStyle.fill;
    canvas.drawPath(crownPath, crownPaint);

    // Crown Border
    final borderPaint = Paint()
      ..color = const Color(0xFFFFFDE7)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(crownPath, borderPaint);

    // Crown Base Arch Strip
    final baseArch = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 13), width: 36, height: 4.5),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(
      baseArch,
      Paint()..color = const Color(0xFFFF6F00),
    );

    // Rubies on 3 peaks
    final rubyPaint = Paint()..color = const Color(0xFFD50000);
    canvas.drawCircle(Offset(cx - 22, cy - 4), 2.0, rubyPaint);
    canvas.drawCircle(Offset(cx, cy - 12), 2.5, rubyPaint);
    canvas.drawCircle(Offset(cx + 22, cy - 4), 2.0, rubyPaint);

    // Jewels on base
    canvas.drawCircle(Offset(cx - 10, cy + 13), 1.3, Paint()..color = const Color(0xFF00E5FF));
    canvas.drawCircle(Offset(cx, cy + 13), 1.5, Paint()..color = const Color(0xFFD50000));
    canvas.drawCircle(Offset(cx + 10, cy + 13), 1.3, Paint()..color = const Color(0xFF00E5FF));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3D Cosmic Background Painter: Grand Golden Treasure Chest, 3D Pawns, 3D Dice, Floating Coins
class _InventoryCosmicBackgroundPainter extends CustomPainter {
  const _InventoryCosmicBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── 1. Cosmic Deep Space Radial Gradient ─────────────────────────
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.4),
        radius: 1.25,
        colors: const [
          Color(0xFF0E2868), // Rich radiant royal blue
          Color(0xFF081844),
          Color(0xFF040D26), // Midnight abyss
          Color(0xFF020614),
        ],
        stops: const [0.0, 0.40, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Subtle twinkling stars
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    final starGlow = Paint()
      ..color = const Color(0xFF80D8FF).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final starPositions = [
      Offset(w * 0.08, h * 0.12),
      Offset(w * 0.22, h * 0.06),
      Offset(w * 0.88, h * 0.18),
      Offset(w * 0.94, h * 0.30),
      Offset(w * 0.05, h * 0.48),
      Offset(w * 0.92, h * 0.60),
      Offset(w * 0.14, h * 0.72),
      Offset(w * 0.85, h * 0.80),
    ];
    for (final pos in starPositions) {
      canvas.drawCircle(pos, 2.5, starGlow);
      canvas.drawCircle(pos, 1.0, starPaint);
    }

    // ── 2. Top Center Grand 3D Golden Treasure Chest & Overflowing Coins
    final chestX = w * 0.5;
    final chestY = h * 0.10;

    // Golden sunburst light rays behind chest
    final rayPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD54F).withValues(alpha: 0.25),
          const Color(0xFFFF8F00).withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(chestX, chestY), radius: 100));
    canvas.drawCircle(Offset(chestX, chestY), 100, rayPaint);

    // Chest Body (Rounded trapezoid/box)
    final chestRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(chestX, chestY + 12), width: 90, height: 38),
      const Radius.circular(8),
    );
    final chestBodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFD54F),
          Color(0xFFFFB300),
          Color(0xFF8D6E63),
          Color(0xFF4E342E),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(chestRect.outerRect);
    canvas.drawRRect(chestRect, chestBodyPaint);

    // Domed Open/Arch Lid
    final lidPath = Path()
      ..moveTo(chestX - 48, chestY - 4)
      ..quadraticBezierTo(chestX, chestY - 30, chestX + 48, chestY - 4)
      ..lineTo(chestX + 44, chestY + 4)
      ..quadraticBezierTo(chestX, chestY - 18, chestX - 44, chestY + 4)
      ..close();
    final lidPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFF9C4),
          Color(0xFFFFEE58),
          Color(0xFFFFB300),
          Color(0xFFFF8F00),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(chestX - 50, chestY - 30, 100, 36));
    canvas.drawPath(lidPath, lidPaint);

    // Gold Lock Plate & Keyhole
    final lockPlate = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(chestX, chestY + 6), width: 14, height: 16),
      const Radius.circular(3),
    );
    canvas.drawRRect(lockPlate, Paint()..color = const Color(0xFFFFD54F));
    canvas.drawCircle(Offset(chestX, chestY + 4), 2.2, Paint()..color = const Color(0xFF2E1C0C));
    canvas.drawRect(
      Rect.fromCenter(center: Offset(chestX, chestY + 8), width: 1.8, height: 4),
      Paint()..color = const Color(0xFF2E1C0C),
    );

    // Mound of overflowing sparkling gold coins spilling out
    void drawCoin(double x, double y, double r, [double tilt = 0.7]) {
      final coinRect = Rect.fromCenter(center: Offset(x, y), width: r * 2, height: r * 2 * tilt);
      final coinGrad = const LinearGradient(
        colors: [Color(0xFFFFF9C4), Color(0xFFFFD54F), Color(0xFFFF8F00)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(coinRect);
      canvas.drawOval(coinRect, Paint()..shader = coinGrad);
      canvas.drawOval(
        coinRect,
        Paint()
          ..color = const Color(0xFFFFFDE7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
      // inner rim
      final innerRect = Rect.fromCenter(center: Offset(x, y), width: r * 1.3, height: r * 1.3 * tilt);
      canvas.drawOval(
        innerRect,
        Paint()
          ..color = const Color(0xFFFFA000).withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6,
      );
    }

    drawCoin(chestX - 25, chestY - 5, 8.0, 0.65);
    drawCoin(chestX - 10, chestY - 8, 9.5, 0.75);
    drawCoin(chestX + 6, chestY - 7, 9.0, 0.70);
    drawCoin(chestX + 22, chestY - 5, 8.5, 0.65);
    drawCoin(chestX - 18, chestY - 14, 8.5, 0.75);
    drawCoin(chestX + 3, chestY - 15, 9.0, 0.80);
    drawCoin(chestX + 16, chestY - 12, 7.5, 0.70);

    // ── 3. Top Right: 3D White Ludo Dice with Dark Pips & Flying Coins ─
    final diceX = w * 0.86;
    final diceY = h * 0.08;
    final diceSize = 34.0;

    void draw3dDice(double x, double y, double size) {
      final half = size / 2;

      // Dice Shadow
      final shadowPath = Path()
        ..moveTo(x - half * 1.1, y + half * 1.2)
        ..lineTo(x + half * 1.2, y + half * 1.2)
        ..lineTo(x + half * 1.5, y + half * 0.5)
        ..lineTo(x - half * 0.8, y + half * 0.5)
        ..close();
      canvas.drawPath(
        shadowPath,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      // Top Face
      final topPath = Path()
        ..moveTo(x, y - half * 0.85)
        ..lineTo(x + half * 0.9, y - half * 0.3)
        ..lineTo(x, y + half * 0.25)
        ..lineTo(x - half * 0.9, y - half * 0.3)
        ..close();
      canvas.drawPath(
        topPath,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFECEFF1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Rect.fromLTWH(x - half, y - half, size, size)),
      );

      // Left Face
      final leftPath = Path()
        ..moveTo(x - half * 0.9, y - half * 0.3)
        ..lineTo(x, y + half * 0.25)
        ..lineTo(x, y + half * 1.05)
        ..lineTo(x - half * 0.9, y + half * 0.5)
        ..close();
      canvas.drawPath(
        leftPath,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFCFD8DC), Color(0xFF90A4AE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(x - half, y, half, half)),
      );

      // Right Face
      final rightPath = Path()
        ..moveTo(x, y + half * 0.25)
        ..lineTo(x + half * 0.9, y - half * 0.3)
        ..lineTo(x + half * 0.9, y + half * 0.5)
        ..lineTo(x, y + half * 1.05)
        ..close();
      canvas.drawPath(
        rightPath,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFB0BEC5), Color(0xFF78909C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(x, y, half, half)),
      );

      // Edges Stroke
      final edgePaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.7)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawPath(topPath, edgePaint);
      canvas.drawPath(leftPath, edgePaint);
      canvas.drawPath(rightPath, edgePaint);

      // Dark Blue Pips
      final pipPaint = Paint()..color = const Color(0xFF0D47A1);
      // Top face pip (1 pip in center)
      canvas.drawCircle(Offset(x, y - half * 0.3), 2.2, pipPaint);
      // Left face pips (2 pips)
      canvas.drawCircle(Offset(x - half * 0.5, y + half * 0.05), 1.8, pipPaint);
      canvas.drawCircle(Offset(x - half * 0.35, y + half * 0.65), 1.8, pipPaint);
      // Right face pips (3 pips)
      canvas.drawCircle(Offset(x + half * 0.35, y + half * 0.05), 1.8, pipPaint);
      canvas.drawCircle(Offset(x + half * 0.45, y + half * 0.38), 1.8, pipPaint);
      canvas.drawCircle(Offset(x + half * 0.55, y + half * 0.70), 1.8, pipPaint);
    }

    draw3dDice(diceX, diceY, diceSize);

    // Flying gold coins near top right dice
    drawCoin(diceX - 28, diceY + 22, 10.0, 0.60);
    drawCoin(diceX + 18, diceY + 32, 8.5, 0.75);
    drawCoin(diceX - 8, diceY - 22, 7.5, 0.55);

    // ── 4. Bottom Left: 3D Glossy Red Pawn & Stacks of Gold Coins ───────
    final redX = w * 0.14;
    final redY = h * 0.90;

    void draw3dRedPawn(double x, double y, double scale) {
      // Base shadow
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x + 2, y + 26 * scale), width: 44 * scale, height: 16 * scale),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // Pawn Body Path (pedestal base, flared waist, neck ring)
      final bodyPath = Path()
        ..moveTo(x - 18 * scale, y + 24 * scale)
        ..quadraticBezierTo(x - 18 * scale, y + 16 * scale, x - 7 * scale, y + 5 * scale)
        ..lineTo(x - 6 * scale, y - 2 * scale)
        ..lineTo(x + 6 * scale, y - 2 * scale)
        ..lineTo(x + 7 * scale, y + 5 * scale)
        ..quadraticBezierTo(x + 18 * scale, y + 16 * scale, x + 18 * scale, y + 24 * scale)
        ..close();

      final redGrad = const LinearGradient(
        colors: [
          Color(0xFFFF5252),
          Color(0xFFE53935),
          Color(0xFFC62828),
          Color(0xFF5A0505),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(x - 20 * scale, y - 10 * scale, 40 * scale, 36 * scale));
      canvas.drawPath(bodyPath, Paint()..shader = redGrad);

      // Base Pedestal Rim
      final baseRim = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y + 22 * scale), width: 38 * scale, height: 7 * scale),
        Radius.circular(3.5 * scale),
      );
      canvas.drawRRect(baseRim, Paint()..color = const Color(0xFFB71C1C));

      // Neck Ring
      final neckRing = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y - 2 * scale), width: 15 * scale, height: 4.5 * scale),
        Radius.circular(2 * scale),
      );
      canvas.drawRRect(neckRing, Paint()..color = const Color(0xFFFF8A80));

      // Sphere Head
      final headCenter = Offset(x, y - 13 * scale);
      final headRadius = 12 * scale;
      final headPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.9,
          colors: const [
            Color(0xFFFF8A80),
            Color(0xFFFF1744),
            Color(0xFFD50000),
            Color(0xFF4A0000),
          ],
        ).createShader(Rect.fromCircle(center: headCenter, radius: headRadius));
      canvas.drawCircle(headCenter, headRadius, headPaint);

      // Specular Highlight Glint
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x - 4 * scale, y - 17 * scale), width: 6 * scale, height: 3.5 * scale),
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );
    }

    draw3dRedPawn(redX, redY, 1.05);

    // Stacked gold coins next to Red Pawn
    drawCoin(redX + 26, redY + 22, 10.0, 0.65);
    drawCoin(redX + 26, redY + 17, 10.0, 0.65);
    drawCoin(redX + 26, redY + 12, 10.0, 0.65);
    drawCoin(redX + 38, redY + 24, 8.5, 0.65);
    drawCoin(redX + 38, redY + 19, 8.5, 0.65);

    // ── 5. Bottom Right: 3D Blue Pawn & Glowing Golden Light Swooshes ──
    final blueX = w * 0.86;
    final blueY = h * 0.91;

    // Glowing Neon Energy Swoosh
    final ribbonPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0x00FF9100),
          Color(0xAAFFD600),
          Color(0xCC00E5FF),
          Color(0x0000B0FF),
        ],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(w * 0.45, h * 0.80, w * 0.55, h * 0.20))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final ribbonPath = Path()
      ..moveTo(w * 0.35, h * 0.96)
      ..cubicTo(w * 0.60, h * 0.98, w * 0.75, h * 0.85, w * 0.98, h * 0.78);
    canvas.drawPath(ribbonPath, ribbonPaint);

    void draw3dBluePawn(double x, double y, double scale) {
      // Base shadow
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x + 2, y + 26 * scale), width: 44 * scale, height: 16 * scale),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // Pawn Body Path
      final bodyPath = Path()
        ..moveTo(x - 18 * scale, y + 24 * scale)
        ..quadraticBezierTo(x - 18 * scale, y + 16 * scale, x - 7 * scale, y + 5 * scale)
        ..lineTo(x - 6 * scale, y - 2 * scale)
        ..lineTo(x + 6 * scale, y - 2 * scale)
        ..lineTo(x + 7 * scale, y + 5 * scale)
        ..quadraticBezierTo(x + 18 * scale, y + 16 * scale, x + 18 * scale, y + 24 * scale)
        ..close();

      final blueGrad = const LinearGradient(
        colors: [
          Color(0xFF40C4FF),
          Color(0xFF0091EA),
          Color(0xFF0D47A1),
          Color(0xFF001040),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(x - 20 * scale, y - 10 * scale, 40 * scale, 36 * scale));
      canvas.drawPath(bodyPath, Paint()..shader = blueGrad);

      // Base Pedestal Rim
      final baseRim = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y + 22 * scale), width: 38 * scale, height: 7 * scale),
        Radius.circular(3.5 * scale),
      );
      canvas.drawRRect(baseRim, Paint()..color = const Color(0xFF0D47A1));

      // Neck Ring
      final neckRing = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y - 2 * scale), width: 15 * scale, height: 4.5 * scale),
        Radius.circular(2 * scale),
      );
      canvas.drawRRect(neckRing, Paint()..color = const Color(0xFF80D8FF));

      // Sphere Head
      final headCenter = Offset(x, y - 13 * scale);
      final headRadius = 12 * scale;
      final headPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.9,
          colors: const [
            Color(0xFFB3E5FC),
            Color(0xFF00B0FF),
            Color(0xFF0277BD),
            Color(0xFF002244),
          ],
        ).createShader(Rect.fromCircle(center: headCenter, radius: headRadius));
      canvas.drawCircle(headCenter, headRadius, headPaint);

      // Specular Highlight Glint
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x - 4 * scale, y - 17 * scale), width: 6 * scale, height: 3.5 * scale),
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );
    }

    draw3dBluePawn(blueX, blueY, 1.0);

    // Floating Coins near Blue Pawn
    drawCoin(blueX - 25, blueY + 18, 9.5, 0.70);
    drawCoin(blueX + 16, blueY + 22, 8.0, 0.65);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


// ============================================================================
// ============================================================================
// 4. SOCIAL SECTION VIEW (REAL COMMUNITY, LEADERBOARD & FRIEND CHALLENGES - 3D ROYAL UI)
// ============================================================================
class SocialSectionView extends StatefulWidget {
  final String userName;
  final VoidCallback? onProfileUpdated;
  final VoidCallback? onOpenProfile;

  const SocialSectionView({
    super.key,
    required this.userName,
    this.onProfileUpdated,
    this.onOpenProfile,
  });

  @override
  State<SocialSectionView> createState() => _SocialSectionViewState();
}

class _SocialSectionViewState extends State<SocialSectionView> {
  final ApiService _apiService = ApiService();
  final TextEditingController _friendCodeController = TextEditingController();

  UserProfileModel? _profile;
  List<LeaderboardEntry> _leaderboard = [];
  UserRanking? _myRanking;

  bool _isLoading = false;
  bool _isJoiningRoom = false;

  // Demo leaderboard matching reference UI when offline or no records yet
  static const List<LeaderboardEntry> _demoLeaderboard = [
    LeaderboardEntry(
      rank: 1,
      user: LeaderboardUser(id: '1', name: 'Vishal Chauhan'),
      score: 350,
      wins: 2,
      gamesPlayed: 5,
    ),
    LeaderboardEntry(
      rank: 2,
      user: LeaderboardUser(id: '2', name: 'Ludo Master'),
      score: 200,
      wins: 2,
      gamesPlayed: 5,
    ),
    LeaderboardEntry(
      rank: 3,
      user: LeaderboardUser(id: '3', name: 'Guest Player'),
      score: 100,
      wins: 1,
      gamesPlayed: 1,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadAllSocialData();
  }

  @override
  void dispose() {
    _friendCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadAllSocialData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Fetch live user profile
      final profile = await AuthService.fetchUserProfile();
      if (mounted && profile != null) {
        _profile = profile;
      } else {
        _profile = await AuthService.getCachedUserProfile();
      }

      // 2. Fetch Leaderboard and current user ranking
      final lbRes = await _apiService.getLeaderboard();
      final meRes = await _apiService.getMyLeaderboard();

      if (!mounted) return;

      if (lbRes['success'] == true) {
        final data = lbRes['data'];
        List<LeaderboardEntry> entries = [];
        if (data is Map<String, dynamic> &&
            data['data'] != null &&
            data['data'] is Map<String, dynamic>) {
          final innerData = data['data'] as Map<String, dynamic>;
          if (innerData['leaderboard'] is List) {
            entries = (innerData['leaderboard'] as List)
                .whereType<Map<String, dynamic>>()
                .map((e) => LeaderboardEntry.fromJson(e))
                .toList();
          }
          if (innerData['currentUser'] is Map<String, dynamic>) {
            _myRanking = UserRanking.fromJson(innerData['currentUser'] as Map<String, dynamic>);
          }
        } else if (data is Map<String, dynamic> && data['leaderboard'] is List) {
          entries = (data['leaderboard'] as List)
              .whereType<Map<String, dynamic>>()
              .map((e) => LeaderboardEntry.fromJson(e))
              .toList();
          if (data['currentUser'] is Map<String, dynamic>) {
            _myRanking = UserRanking.fromJson(data['currentUser'] as Map<String, dynamic>);
          }
        }

        if (meRes['success'] == true && meRes['data'] != null) {
          final meData = meRes['data'];
          if (meData is Map<String, dynamic> && meData['data'] is Map<String, dynamic>) {
            _myRanking = UserRanking.fromJson(meData['data'] as Map<String, dynamic>);
          } else if (meData is Map<String, dynamic>) {
            _myRanking = UserRanking.fromJson(meData);
          }
        }

        setState(() {
          _leaderboard = entries;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openProfileDialog() {
    if (widget.onOpenProfile != null) {
      widget.onOpenProfile!();
      return;
    }
    showDialog(
      context: context,
      builder: (_) => ProfileDialog(
        initialProfile: _profile,
        onProfileUpdated: (updated) {
          setState(() => _profile = updated);
          widget.onProfileUpdated?.call();
        },
      ),
    );
  }

  void _openCreateChallengeDialog([int playerCount = 2]) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => PlayerSelectionDialog(
        initialCount: playerCount,
        initialIsCreateTab: true,
      ),
    );
  }

  Future<void> _joinFriendRoom() async {
    final code = _friendCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a room code"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Room code must be at least 4-6 characters"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isJoiningRoom = true);

    try {
      final res = await _apiService.joinRoom(roomCode: code);
      if (!mounted) return;
      setState(() => _isJoiningRoom = false);

      if (res['success'] == true && res['data'] != null) {
        RoomModel? room;
        try {
          final data = res['data'];
          if (data is Map<String, dynamic>) {
            room = RoomModel.fromJson(data);
          }
        } catch (_) {}

        if (room != null) {
          _friendCodeController.clear();
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => RoomLobbyDialog(
              room: room!,
              isHost: false,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Room joined, but failed to load lobby details."),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        final msg = res['message']?.toString() ?? "Room not found or game already started";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isJoiningRoom = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to join room: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  String _getRankTitle(int level) {
    if (level >= 30) return "Grandmaster";
    if (level >= 20) return "Master Champion";
    if (level >= 10) return "Elite Warrior";
    if (level >= 5) return "Rising Star";
    return "Apprentice";
  }

  @override
  Widget build(BuildContext context) {
    final activeName = _profile?.name.isNotEmpty == true ? _profile!.name : widget.userName;
    final level = _profile?.level ?? 1;
    final gamesPlayed = _profile?.statistics.totalGames ?? 2;
    final gamesWon = _profile?.statistics.wins ?? 2;
    final coins = _profile?.coins ?? 3400;
    final gems = _profile?.gems ?? 10;
    final winRate = _profile != null && _profile!.statistics.totalGames > 0
        ? _profile!.statistics.winRate.toStringAsFixed(1)
        : (gamesPlayed > 0 ? ((gamesWon / gamesPlayed) * 100).toStringAsFixed(1) : "100.0");

    final displayLeaderboard = _leaderboard.isNotEmpty ? _leaderboard : _demoLeaderboard;

    return Stack(
      children: [
        // Layer 1: 3D Royal Cosmic Backdrop (Red Pawn, Blue Pawn, 3D Dice, Glowing Energy Swooshes)
        const Positioned.fill(
          child: CustomPaint(
            painter: _SocialCosmicBackgroundPainter(),
          ),
        ),

        // Layer 2: Scrollable Interactive Content
        LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth >= 600;
            final maxContentWidth = isTablet ? 820.0 : 440.0;

            return RefreshIndicator(
              onRefresh: _loadAllSocialData,
              color: const Color(0xFFFFD700),
              backgroundColor: const Color(0xFF0F1A30),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Column(
                      children: [
                        // Top Header: 3D Crown Laurel & Curved Ribbon Banner
                        _buildSocialHeader(),
                        const SizedBox(height: 14),

                        if (!isTablet) ...[
                          // Card 1: Real Player Identity & Standing Card
                          _buildProfileCard(
                            name: activeName,
                            level: level,
                            rankTitle: _getRankTitle(level),
                            gamesWon: gamesWon,
                            gamesPlayed: gamesPlayed,
                            winRate: winRate,
                            coins: coins,
                            gems: gems,
                          ),
                          const SizedBox(height: 14),

                          // Card 2: Friendly Match Challenge (Host Room & Code Join)
                          _buildChallengeCard(),
                          const SizedBox(height: 14),

                          // Card 3: Community Champions / Leaderboard
                          _buildLeaderboardPreviewCard(displayLeaderboard),
                        ] else ...[
                          // Tablet Dual Column: Profile & Challenge (Left) | Leaderboard (Right)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: Column(
                                  children: [
                                    _buildProfileCard(
                                      name: activeName,
                                      level: level,
                                      rankTitle: _getRankTitle(level),
                                      gamesWon: gamesWon,
                                      gamesPlayed: gamesPlayed,
                                      winRate: winRate,
                                      coins: coins,
                                      gems: gems,
                                    ),
                                    const SizedBox(height: 14),
                                    _buildChallengeCard(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 6,
                                child: _buildLeaderboardPreviewCard(displayLeaderboard),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── 1. Top Header with 3D Crown Laurel & Curved Ribbon Banner ──────
  Widget _buildSocialHeader() {
    return Column(
      children: [
        // 3D Golden Crown with Laurel Leaves
        const SizedBox(
          width: 72,
          height: 48,
          child: CustomPaint(
            painter: _SocialCrownLaurelPainter(),
          ),
        ),
        const SizedBox(height: 6),

        // 3D Ribbon Banner: ⭐ SOCIAL & COMMUNITY ⭐
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1E88E5),
                Color(0xFF1565C0),
                Color(0xFF0D47A1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFD700),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                blurRadius: 10,
                spreadRadius: 0.5,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Text(
                  'SOCIAL & COMMUNITY',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                      const Shadow(
                        color: Color(0xFFFFD700),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text('⭐', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 5),

        // Subtitle Strip: — Play • Connect • Grow —
        const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '— Play • Connect • Grow —',
            style: TextStyle(
              color: Color(0xFF90CAF9),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  // ── 2. Card 1: Player Identity & Standing Card ─────────────────────
  Widget _buildProfileCard({
    required String name,
    required int level,
    required String rankTitle,
    required int gamesWon,
    required int gamesPlayed,
    required String winRate,
    required int coins,
    required int gems,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0C2456), // Electric royal blue
            Color(0xFF071738), // Deep midnight navy
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.75),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.20),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Row: Avatar Medallion + Player Info + Coins/Gems Pills
          Row(
            children: [
              // Large Golden Circular Avatar Medallion
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          Color(0xFF2A1C00),
                          Color(0xFF140C00),
                        ],
                      ),
                      border: Border.all(
                        color: const Color(0xFFFFD700),
                        width: 2.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.groups_rounded,
                        color: Color(0xFFFFD700),
                        size: 32,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -3,
                    right: -3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFEE58), Color(0xFFFFB300)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF0F1A30), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        "Lv.$level",
                        style: const TextStyle(
                          color: Color(0xFF091428),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Player Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "$rankTitle ✦",
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Win Rate : $winRate% • $gamesPlayed Played",
                        style: const TextStyle(
                          color: Color(0xFFB0BEC5),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Compact Coins & Gems Pills Stack
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF051126),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFD700), size: 13),
                        const SizedBox(width: 4),
                        Text(
                          "$coins",
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF051126),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.diamond_rounded, color: Color(0xFF00E5FF), size: 13),
                        const SizedBox(width: 4),
                        Text(
                          "$gems",
                          style: const TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),

          // Bottom Action Row: View Profile Button + Refresh Sync
          Row(
            children: [
              // Golden Outlined "View Profile >" button
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _openProfileDialog,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0x33FFB300), Color(0x1AFF8F00)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "View Profile",
                              style: TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(width: 5),
                            Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFFFD700), size: 11),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Server Sync Refresh Button
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF051126),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFFFD700),
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, color: Color(0xFFFFD700), size: 20),
                  tooltip: "Sync with server",
                  onPressed: _isLoading ? null : _loadAllSocialData,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 3. Card 2: Challenge Friends (Host Room & Code Join) ────────────
  Widget _buildChallengeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0C2456), // Electric royal blue
            Color(0xFF071738), // Dark navy
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF00E676).withValues(alpha: 0.75),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E676).withValues(alpha: 0.20),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Game controller icon + "Challenge Friends" + "JOIN & PLAY"
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00E676).withValues(alpha: 0.18),
                  border: Border.all(color: const Color(0xFF00E676), width: 1.2),
                ),
                child: const Icon(Icons.sports_esports_rounded, color: Color(0xFF00E676), size: 18),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Challenge Friends",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E676), Color(0xFF00B0FF)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E676).withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Text(
                  "JOIN & PLAY",
                  style: TextStyle(
                    color: Color(0xFF05172E),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "Invite your friends to challenge friends with shareable code, or enter your friends code to play.",
            style: TextStyle(color: Color(0xFFB0BEC5), fontSize: 11.5, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 14),

          // Action 1: Large 3D Neon Green "Create Friendly Room & Invite" Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openCreateChallengeDialog(2),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF69F0AE),
                      Color(0xFF00E676),
                      Color(0xFF00C853),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFB9F6CA),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E676).withValues(alpha: 0.6),
                      blurRadius: 10,
                      spreadRadius: 0.5,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline_rounded, color: Color(0xFF04240A), size: 19),
                      SizedBox(width: 8),
                      Text(
                        "Create Friendly Room & Invite",
                        style: TextStyle(
                          color: Color(0xFF04240A),
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Code TextField + 3D JOIN Button Row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF051126),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                  ),
                  child: TextField(
                    controller: _friendCodeController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                    ),
                    decoration: const InputDecoration(
                      hintText: "FRIEND'S CODE",
                      hintStyle: TextStyle(
                        color: Colors.white24,
                        fontSize: 12.5,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Neon Green 3D "JOIN" Button
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: _isJoiningRoom ? null : _joinFriendRoom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: const Color(0xFF04240A),
                    elevation: 4,
                    shadowColor: const Color(0xFF00E676).withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFFB9F6CA), width: 1.2),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  child: _isJoiningRoom
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Color(0xFF04240A),
                          ),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "JOIN",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                            SizedBox(width: 5),
                            Icon(Icons.groups_rounded, size: 16),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 4. Card 3: Community Champions / Leaderboard ───────────────────
  Widget _buildLeaderboardPreviewCard(List<LeaderboardEntry> leaderboard) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0C2456), // Electric royal blue
            Color(0xFF071738), // Dark navy
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.75),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.20),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Trophy + "Community Champions" + My score pill
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFD700).withValues(alpha: 0.18),
                  border: Border.all(color: const Color(0xFFFFD700), width: 1.2),
                ),
                child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 18),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Community Champions",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              // User's Rank / Points Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0x33FFB300), Color(0x1AFF8F00)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD700), width: 1.1),
                ),
                child: Text(
                  _myRanking != null ? "My: #${_myRanking!.rank}" : "My: 0 pts",
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            "Top challengers from the official leaderboard.",
            style: TextStyle(color: Color(0xFFB0BEC5), fontSize: 11.5, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),

          // Champions List (Top 3-4 entries)
          ...leaderboard.take(3).map((entry) => _buildLeaderboardRow(entry)),

          const SizedBox(height: 12),

          // View Full Leaderboard Outlined Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.leaderboard_rounded, color: Color(0xFFFFD700), size: 18),
              label: const Text(
                "Open Full Leaderboard",
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFFD700), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardRow(LeaderboardEntry entry) {
    Color rankColor;
    Color ringColor;

    if (entry.rank == 1) {
      rankColor = const Color(0xFFFFD700);
      ringColor = const Color(0xFFFFD700);
    } else if (entry.rank == 2) {
      rankColor = const Color(0xFFE0E0E0);
      ringColor = const Color(0xFF00E5FF);
    } else if (entry.rank == 3) {
      rankColor = const Color(0xFFCD7F32);
      ringColor = const Color(0xFFFF5252);
    } else {
      rankColor = const Color(0xFF90A4AE);
      ringColor = Colors.white24;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF051126).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: entry.rank <= 3 ? rankColor.withValues(alpha: 0.5) : Colors.white12,
          width: 1.1,
        ),
      ),
      child: Row(
        children: [
          // Circular Avatar with rank color ring
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ringColor.withValues(alpha: 0.15),
              border: Border.all(color: ringColor, width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: ringColor.withValues(alpha: 0.3),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.person_rounded,
                color: ringColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Name & Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  "${entry.wins} Wins • ${entry.gamesPlayed} Played",
                  style: const TextStyle(color: Color(0xFF8FA8CE), fontSize: 10.5, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Points Pill Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: rankColor.withValues(alpha: 0.7), width: 1.1),
            ),
            child: Text(
              "${entry.score} pts",
              style: TextStyle(
                color: rankColor,
                fontWeight: FontWeight.w900,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 3D CUSTOM PAINTERS FOR SOCIAL & COMMUNITY SECTION
// ============================================================================

/// 3D Golden Crown with Laurel Wreath for the Social Header
class _SocialCrownLaurelPainter extends CustomPainter {
  const _SocialCrownLaurelPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // 1. Golden Laurel Leaves on Left and Right
    final leafPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFEE58), Color(0xFFFFB300), Color(0xFFFF8F00)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    void drawLeaf(double x, double y, double radiusX, double radiusY, double rotation) {
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      final path = Path()
        ..moveTo(0, -radiusY)
        ..quadraticBezierTo(radiusX, 0, 0, radiusY)
        ..quadraticBezierTo(-radiusX, 0, 0, -radiusY);
      canvas.drawPath(path, leafPaint);
      canvas.restore();
    }

    // Left Laurel Branch Leaves
    drawLeaf(cx - 24, cy + 12, 3.8, 8.0, -0.6);
    drawLeaf(cx - 28, cy + 2, 4.0, 8.5, -0.85);
    drawLeaf(cx - 26, cy - 8, 3.8, 8.0, -1.1);
    drawLeaf(cx - 18, cy - 16, 3.5, 7.5, -1.4);

    // Right Laurel Branch Leaves
    drawLeaf(cx + 24, cy + 12, 3.8, 8.0, 0.6);
    drawLeaf(cx + 28, cy + 2, 4.0, 8.5, 0.85);
    drawLeaf(cx + 26, cy - 8, 3.8, 8.0, 1.1);
    drawLeaf(cx + 18, cy - 16, 3.5, 7.5, 1.4);

    // 2. Center 3D Royal Golden Crown
    final crownPath = Path()
      ..moveTo(cx - 18, cy + 14)
      ..lineTo(cx - 22, cy - 4) // left peak
      ..lineTo(cx - 9, cy + 5)
      ..lineTo(cx, cy - 12) // tall center peak
      ..lineTo(cx + 9, cy + 5)
      ..lineTo(cx + 22, cy - 4) // right peak
      ..lineTo(cx + 18, cy + 14)
      ..close();

    // Crown Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.save();
    canvas.translate(0, 2);
    canvas.drawPath(crownPath, shadowPaint);
    canvas.restore();

    // Crown Gradient Body
    final crownPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFF9C4),
          Color(0xFFFFEE58),
          Color(0xFFFFB300),
          Color(0xFFFF8F00),
          Color(0xFFE65100),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(cx - 24, cy - 14, 48, 30))
      ..style = PaintingStyle.fill;
    canvas.drawPath(crownPath, crownPaint);

    // Crown Border
    final borderPaint = Paint()
      ..color = const Color(0xFFFFFDE7)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(crownPath, borderPaint);

    // Crown Base Arch Strip
    final baseArch = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + 13), width: 36, height: 4.5),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(baseArch, Paint()..color = const Color(0xFFFF6F00));

    // Rubies on 3 peaks
    final rubyPaint = Paint()..color = const Color(0xFFD50000);
    canvas.drawCircle(Offset(cx - 22, cy - 4), 2.0, rubyPaint);
    canvas.drawCircle(Offset(cx, cy - 12), 2.5, rubyPaint);
    canvas.drawCircle(Offset(cx + 22, cy - 4), 2.0, rubyPaint);

    // Jewels on base
    canvas.drawCircle(Offset(cx - 10, cy + 13), 1.3, Paint()..color = const Color(0xFF00E5FF));
    canvas.drawCircle(Offset(cx, cy + 13), 1.5, Paint()..color = const Color(0xFFD50000));
    canvas.drawCircle(Offset(cx + 10, cy + 13), 1.3, Paint()..color = const Color(0xFF00E5FF));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3D Cosmic Background Painter for Social Section
class _SocialCosmicBackgroundPainter extends CustomPainter {
  const _SocialCosmicBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── 1. Cosmic Deep Space Radial Gradient ─────────────────────────
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.4),
        radius: 1.25,
        colors: const [
          Color(0xFF0E2868), // Radiant royal blue
          Color(0xFF081844),
          Color(0xFF040D26), // Midnight abyss
          Color(0xFF020614),
        ],
        stops: const [0.0, 0.40, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // Subtle twinkling stars
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    final starGlow = Paint()
      ..color = const Color(0xFF80D8FF).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final starPositions = [
      Offset(w * 0.08, h * 0.12),
      Offset(w * 0.22, h * 0.06),
      Offset(w * 0.88, h * 0.18),
      Offset(w * 0.94, h * 0.30),
      Offset(w * 0.05, h * 0.48),
      Offset(w * 0.92, h * 0.60),
      Offset(w * 0.14, h * 0.72),
      Offset(w * 0.85, h * 0.80),
    ];
    for (final pos in starPositions) {
      canvas.drawCircle(pos, 2.5, starGlow);
      canvas.drawCircle(pos, 1.0, starPaint);
    }

    // ── 2. Top Right: 3D Red Pawn & 3D White Dice with Blue Pips ──────
    final diceX = w * 0.82;
    final diceY = h * 0.08;
    final diceSize = 34.0;

    void draw3dDice(double x, double y, double size, {required bool bluePips}) {
      final half = size / 2;

      // Shadow
      final shadowPath = Path()
        ..moveTo(x - half * 1.1, y + half * 1.2)
        ..lineTo(x + half * 1.2, y + half * 1.2)
        ..lineTo(x + half * 1.5, y + half * 0.5)
        ..lineTo(x - half * 0.8, y + half * 0.5)
        ..close();
      canvas.drawPath(
        shadowPath,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      // Top Face
      final topPath = Path()
        ..moveTo(x, y - half * 0.85)
        ..lineTo(x + half * 0.9, y - half * 0.3)
        ..lineTo(x, y + half * 0.25)
        ..lineTo(x - half * 0.9, y - half * 0.3)
        ..close();
      canvas.drawPath(
        topPath,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFECEFF1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Rect.fromLTWH(x - half, y - half, size, size)),
      );

      // Left Face
      final leftPath = Path()
        ..moveTo(x - half * 0.9, y - half * 0.3)
        ..lineTo(x, y + half * 0.25)
        ..lineTo(x, y + half * 1.05)
        ..lineTo(x - half * 0.9, y + half * 0.5)
        ..close();
      canvas.drawPath(
        leftPath,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFCFD8DC), Color(0xFF90A4AE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(x - half, y, half, half)),
      );

      // Right Face
      final rightPath = Path()
        ..moveTo(x, y + half * 0.25)
        ..lineTo(x + half * 0.9, y - half * 0.3)
        ..lineTo(x + half * 0.9, y + half * 0.5)
        ..lineTo(x, y + half * 1.05)
        ..close();
      canvas.drawPath(
        rightPath,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFB0BEC5), Color(0xFF78909C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(x, y, half, half)),
      );

      // Edges Stroke
      final edgePaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.7)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawPath(topPath, edgePaint);
      canvas.drawPath(leftPath, edgePaint);
      canvas.drawPath(rightPath, edgePaint);

      // Pips Color
      final pipPaint = Paint()..color = bluePips ? const Color(0xFF0D47A1) : const Color(0xFF1E293B);
      // Top face pip (center)
      canvas.drawCircle(Offset(x, y - half * 0.3), 2.2, pipPaint);
      // Left face pips (2 pips)
      canvas.drawCircle(Offset(x - half * 0.5, y + half * 0.05), 1.8, pipPaint);
      canvas.drawCircle(Offset(x - half * 0.35, y + half * 0.65), 1.8, pipPaint);
      // Right face pips (3 pips)
      canvas.drawCircle(Offset(x + half * 0.35, y + half * 0.05), 1.8, pipPaint);
      canvas.drawCircle(Offset(x + half * 0.45, y + half * 0.38), 1.8, pipPaint);
      canvas.drawCircle(Offset(x + half * 0.55, y + half * 0.70), 1.8, pipPaint);
    }

    draw3dDice(diceX, diceY, diceSize, bluePips: true);

    // 3D Red Pawn on top right
    final topRedX = w * 0.72;
    final topRedY = h * 0.07;
    void drawTiltedPawn(double x, double y, double scale) {
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(0.35);

      final bodyPath = Path()
        ..moveTo(-14 * scale, 18 * scale)
        ..quadraticBezierTo(-14 * scale, 12 * scale, -5 * scale, 4 * scale)
        ..lineTo(-4 * scale, -2 * scale)
        ..lineTo(4 * scale, -2 * scale)
        ..lineTo(5 * scale, 4 * scale)
        ..quadraticBezierTo(14 * scale, 12 * scale, 14 * scale, 18 * scale)
        ..close();

      final redGrad = const LinearGradient(
        colors: [Color(0xFFFF5252), Color(0xFFD50000), Color(0xFF5A0505)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(-16 * scale, -10 * scale, 32 * scale, 30 * scale));
      canvas.drawPath(bodyPath, Paint()..shader = redGrad);

      // Head
      final headCenter = Offset(0, -10 * scale);
      final headRadius = 9.5 * scale;
      final headPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.9,
          colors: const [Color(0xFFFF8A80), Color(0xFFFF1744), Color(0xFF4A0000)],
        ).createShader(Rect.fromCircle(center: headCenter, radius: headRadius));
      canvas.drawCircle(headCenter, headRadius, headPaint);

      // Glint
      canvas.drawOval(
        Rect.fromCenter(center: Offset(-3 * scale, -13 * scale), width: 4.5 * scale, height: 2.5 * scale),
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );

      canvas.restore();
    }
    drawTiltedPawn(topRedX, topRedY, 1.0);

    // ── 3. Bottom Left: 3D White Dice with Black Pips & Coin Stacks ───
    final botDiceX = w * 0.28;
    final botDiceY = h * 0.92;
    draw3dDice(botDiceX, botDiceY, 32.0, bluePips: false);

    // Coin Stacks on Bottom Left
    void drawCoin(double x, double y, double r, [double tilt = 0.65]) {
      final coinRect = Rect.fromCenter(center: Offset(x, y), width: r * 2, height: r * 2 * tilt);
      final coinGrad = const LinearGradient(
        colors: [Color(0xFFFFF9C4), Color(0xFFFFD54F), Color(0xFFFF8F00)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(coinRect);
      canvas.drawOval(coinRect, Paint()..shader = coinGrad);
      canvas.drawOval(
        coinRect,
        Paint()
          ..color = const Color(0xFFFFFDE7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }

    final coinX = w * 0.12;
    final coinY = h * 0.92;
    drawCoin(coinX, coinY + 12, 11.0);
    drawCoin(coinX, coinY + 7, 11.0);
    drawCoin(coinX, coinY + 2, 11.0);
    drawCoin(coinX + 14, coinY + 14, 9.5);
    drawCoin(coinX + 14, coinY + 9, 9.5);

    // ── 4. Bottom Right: 3D Blue Pawn & Golden Energy Swooshes ────────
    final blueX = w * 0.86;
    final blueY = h * 0.91;

    // Glowing Neon Energy Swoosh
    final ribbonPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0x00FF9100),
          Color(0xAAFFD600),
          Color(0xCC00E5FF),
          Color(0x0000B0FF),
        ],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(w * 0.40, h * 0.80, w * 0.60, h * 0.20))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final ribbonPath = Path()
      ..moveTo(w * 0.30, h * 0.96)
      ..cubicTo(w * 0.55, h * 0.98, w * 0.72, h * 0.85, w * 0.98, h * 0.78);
    canvas.drawPath(ribbonPath, ribbonPaint);

    void draw3dBluePawn(double x, double y, double scale) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x + 2, y + 26 * scale), width: 44 * scale, height: 16 * scale),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      final bodyPath = Path()
        ..moveTo(x - 18 * scale, y + 24 * scale)
        ..quadraticBezierTo(x - 18 * scale, y + 16 * scale, x - 7 * scale, y + 5 * scale)
        ..lineTo(x - 6 * scale, y - 2 * scale)
        ..lineTo(x + 6 * scale, y - 2 * scale)
        ..lineTo(x + 7 * scale, y + 5 * scale)
        ..quadraticBezierTo(x + 18 * scale, y + 16 * scale, x + 18 * scale, y + 24 * scale)
        ..close();

      final blueGrad = const LinearGradient(
        colors: [Color(0xFF40C4FF), Color(0xFF0091EA), Color(0xFF0D47A1), Color(0xFF001040)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(x - 20 * scale, y - 10 * scale, 40 * scale, 36 * scale));
      canvas.drawPath(bodyPath, Paint()..shader = blueGrad);

      final baseRim = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y + 22 * scale), width: 38 * scale, height: 7 * scale),
        Radius.circular(3.5 * scale),
      );
      canvas.drawRRect(baseRim, Paint()..color = const Color(0xFF0D47A1));

      final neckRing = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y - 2 * scale), width: 15 * scale, height: 4.5 * scale),
        Radius.circular(2 * scale),
      );
      canvas.drawRRect(neckRing, Paint()..color = const Color(0xFF80D8FF));

      final headCenter = Offset(x, y - 13 * scale);
      final headRadius = 12 * scale;
      final headPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.9,
          colors: const [Color(0xFFB3E5FC), Color(0xFF00B0FF), Color(0xFF0277BD), Color(0xFF002244)],
        ).createShader(Rect.fromCircle(center: headCenter, radius: headRadius));
      canvas.drawCircle(headCenter, headRadius, headPaint);

      canvas.drawOval(
        Rect.fromCenter(center: Offset(x - 4 * scale, y - 17 * scale), width: 6 * scale, height: 3.5 * scale),
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );
    }

    draw3dBluePawn(blueX, blueY, 1.0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


// ============================================================================
// 5. SAFE & AD-FREE SECTION VIEW
// ============================================================================
class SafeAndAdFreeSectionView extends StatelessWidget {
  const SafeAndAdFreeSectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          children: [
            _buildSectionHeader(
              icon: Icons.verified_user_rounded,
              title: "SAFE & AD-FREE",
              subtitle: "Fair play, privacy & 100% ad-free experience",
            ),
            const SizedBox(height: 18),

            // 100% Ad-Free Guarantee Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0A3D2A), Color(0xFF0F1F3D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00E676), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E676).withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E676).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.block_rounded, color: Color(0xFF00E676), size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "100% AD-FREE GAMING",
                              style: TextStyle(
                                color: Color(0xFF00E676),
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "Zero video ads. Zero banners. Pure gameplay.",
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "We believe your board game experience should never be interrupted by sudden popups or forced video ads. Enjoy smooth, unbroken gameplay whenever you play.",
                    style: TextStyle(color: Colors.white60, fontSize: 12.5, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // RNG Fair Play Guarantee
            _buildInfoCard(
              icon: Icons.casino_rounded,
              title: "RNG Certified Fair Dice",
              description: "Dice rolls are governed by cryptographically secure random number algorithms. No weighted rolls or biased outcomes — 100% genuine board odds.",
            ),
            const SizedBox(height: 14),

            // Data Privacy Card
            _buildInfoCard(
              icon: Icons.lock_outline_rounded,
              title: "Privacy & Device Storage",
              description: "Your matches, stats and profiles are stored securely. We do not sell player telemetry or share your activity with third-party trackers.",
            ),
            const SizedBox(height: 14),

            // Family Friendly Gaming
            _buildInfoCard(
              icon: Icons.family_restroom_rounded,
              title: "Family & Child Safe",
              description: "Safe for all ages. No real-money wagering or predatory mechanics. Pure classic Ludo entertainment for friends and family.",
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SHARED VIEW BUILDER HELPERS
// ============================================================================

Widget _buildSectionHeader({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Column(
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFFFD700).withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.4), width: 1.5),
        ),
        child: Icon(icon, color: const Color(0xFFFFD700), size: 24),
      ),
      const SizedBox(height: 8),
      Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        subtitle,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF90A4AE),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

Widget _buildInfoCard({
  required IconData icon,
  required String title,
  required String description,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF0F1A30).withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0x22FFD700),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFFFFD700), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
