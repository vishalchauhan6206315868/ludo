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
      accentColor: Color(0xFFF59E0B),
      iconColor: Color(0xFFFFCA28),
      badgeColor: Color(0xFFFFE082),
      labelColor: Colors.white,
      activeGradient: [
        Color(0xFF2563EB),
        Color(0xFF1D4ED8),
        Color(0xFF16347A),
      ],
      inactiveGradient: [
        Color(0xFF142347),
        Color(0xFF0E1A36),
        Color(0xFF0A1226),
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
      iconColor: Color(0xFFFF5252),
      badgeColor: Color(0xFFFFD700),
      labelColor: Colors.white,
      activeGradient: [
        Color(0xFF2563EB),
        Color(0xFF1D4ED8),
        Color(0xFF16347A),
      ],
      inactiveGradient: [
        Color(0xFF142347),
        Color(0xFF0E1A36),
        Color(0xFF0A1226),
      ],
      lightGradient: [
        Color(0xFFFFF8F8),
        Color(0xFFFFE8EA),
        Color(0xFFFFD4D8),
      ],
    ),
    NavItemData(
      icon: Icons.mic_rounded,
      badgeIcon: Icons.graphic_eq_rounded,
      label: 'ADDA',
      key: Key('nav_item_adda'),
      accentColor: Color(0xFF00B4D8),
      iconColor: Color(0xFF38BDF8),
      badgeColor: Color(0xFF7DD3FC),
      labelColor: Colors.white,
      activeGradient: [
        Color(0xFF2563EB),
        Color(0xFF1D4ED8),
        Color(0xFF16347A),
      ],
      inactiveGradient: [
        Color(0xFF142347),
        Color(0xFF0E1A36),
        Color(0xFF0A1226),
      ],
      lightGradient: [
        Color(0xFFF0F9FF),
        Color(0xFFE0F4FF),
        Color(0xFFBAE6FD),
      ],
    ),
    NavItemData(
      icon: Icons.casino_rounded,
      badgeIcon: Icons.diamond_rounded,
      label: 'INVENTORY',
      key: Key('nav_item_inventory'),
      accentColor: Color(0xFF8B5CF6),
      iconColor: Color(0xFFC084FC),
      badgeColor: Color(0xFFF0ABFC),
      labelColor: Colors.white,
      activeGradient: [
        Color(0xFF2563EB),
        Color(0xFF1D4ED8),
        Color(0xFF16347A),
      ],
      inactiveGradient: [
        Color(0xFF142347),
        Color(0xFF0E1A36),
        Color(0xFF0A1226),
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
      accentColor: Color(0xFF10B981),
      iconColor: Color(0xFF34D399),
      badgeColor: Color(0xFFA7F3D0),
      labelColor: Colors.white,
      activeGradient: [
        Color(0xFF2563EB),
        Color(0xFF1D4ED8),
        Color(0xFF16347A),
      ],
      inactiveGradient: [
        Color(0xFF142347),
        Color(0xFF0E1A36),
        Color(0xFF0A1226),
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
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0.0, isSelected ? -2.5 : 0.0, 0.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          gradient: LinearGradient(
            colors: isSelected ? item.activeGradient : item.inactiveGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(
            // Golden accent border on active item, subtle deep-blue on inactive
            color: isSelected
                ? const Color(0xFFFFD700).withValues(alpha: 0.90)
                : const Color(0xFF223A68).withValues(alpha: 0.55),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            if (isSelected) ...[
              // Soft outer electric-blue glow
              BoxShadow(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.48),
                blurRadius: 10,
                spreadRadius: 1.0,
                offset: const Offset(0, 2),
              ),
              // Subtle golden aura
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.28),
                blurRadius: 6,
                spreadRadius: 0.5,
                offset: const Offset(0, 1),
              ),
              // Contact drop shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ] else ...[
              // Inactive subtle contact drop shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: item.key,
            borderRadius: BorderRadius.circular(13),
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
                                ? Colors.white
                                : const Color(0xFFCFDCF5),
                            letterSpacing: 0.3,
                            shadows: isSelected
                                ? [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.65),
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
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

          // Primary Colorful Game Icon
          Center(
            child: Icon(
              item.icon,
              size: primaryIconSize,
              color: item.iconColor,
              shadows: [
                Shadow(
                  color: item.accentColor.withValues(alpha: isSelected ? 0.70 : 0.40),
                  blurRadius: isSelected ? 8 : 4,
                  offset: const Offset(0, 1),
                ),
                Shadow(
                  color: Colors.black.withValues(alpha: 0.50),
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
  RewardsSummary _summary = const RewardsSummary();

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
      final results = await Future.wait([
        _apiService.getRewards(),
        _apiService.getRewardsSummary(),
      ]);

      if (!mounted) return;

      final rewardsRes = results[0];
      final summaryRes = results[1];

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

      RewardsSummary summaryObj = const RewardsSummary();
      if (summaryRes['success'] == true && summaryRes['data'] != null) {
        final sData = summaryRes['data'];
        if (sData is Map<String, dynamic>) {
          summaryObj = RewardsSummary.fromJson(sData);
        }
      }

      // Safe fallback event items if backend rewards table is initially empty
      if (rewardsList.isEmpty) {
        rewardsList = const [
          RewardItem(
            id: 'daily_login',
            title: 'Daily Check-in Event',
            description: 'Log in daily to claim free coins & maintain your streak',
            rewardType: 'coins',
            rewardValue: 500,
            icon: 'daily_login',
            isClaimed: false,
            canClaim: true,
          ),
          RewardItem(
            id: 'welcome_event',
            title: 'Welcome Champion Gift',
            description: 'Exclusive newcomer welcome pack for active players',
            rewardType: 'coins',
            rewardValue: 1000,
            icon: 'trophy',
            isClaimed: false,
            canClaim: true,
          ),
          RewardItem(
            id: 'super_spin_event',
            title: 'Lucky Wheel Bonus',
            description: 'Spin the wheel to win exciting gems & multipliers',
            rewardType: 'gems',
            rewardValue: 5,
            icon: 'wheel',
            isClaimed: false,
            canClaim: true,
          ),
        ];
      }

      setState(() {
        _isLoading = false;
        _availableRewards = rewardsList;
        _summary = summaryObj;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _availableRewards = const [
          RewardItem(
            id: 'daily_login',
            title: 'Daily Check-in Event',
            description: 'Log in daily to claim free coins & maintain your streak',
            rewardType: 'coins',
            rewardValue: 500,
            icon: 'daily_login',
            isClaimed: false,
            canClaim: true,
          ),
          RewardItem(
            id: 'welcome_event',
            title: 'Welcome Champion Gift',
            description: 'Exclusive newcomer welcome pack for active players',
            rewardType: 'coins',
            rewardValue: 1000,
            icon: 'trophy',
            isClaimed: false,
            canClaim: true,
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
      case 'daily_login':
        return Icons.calendar_today_rounded;
      case 'spin_wheel':
      case 'wheel':
        return Icons.rotate_right_rounded;
      case 'match_win':
      case 'trophy':
        return Icons.emoji_events_rounded;
      case 'streak':
        return Icons.local_fire_department_rounded;
      case 'gem':
      case 'gems':
        return Icons.diamond_rounded;
      default:
        return Icons.card_giftcard_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchEvents,
      color: const Color(0xFFFFD700),
      backgroundColor: const Color(0xFF0F1A30),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            children: [
              // Header with Refresh Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildSectionHeader(
                      icon: Icons.emoji_events_rounded,
                      title: "LIVE EVENTS & REWARDS",
                      subtitle: "Claim daily bonuses, streaks & special rewards",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Live Summary Bar
              _buildSummaryBar(),
              const SizedBox(height: 16),

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
                  padding: EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFFD700),
                      strokeWidth: 2.8,
                    ),
                  ),
                ),
              ] else ...[
                // List of Live API Event Cards
                ..._availableRewards.map((reward) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _buildEventCard(reward),
                    )),
              ],

              const SizedBox(height: 10),

              // Full Rewards Center Gateway Card
              _buildFeatureCard(
                title: "REWARDS CENTER & HISTORY",
                badge: "ALL REWARDS",
                badgeColor: const Color(0xFFFFD700),
                subtitle: "View your lifetime claims, history and stats",
                rewardText: "Coins • Daily Streaks • Welcome Gifts",
                icon: Icons.card_giftcard_rounded,
                gradientColors: const [Color(0xFF1E3A8A), Color(0xFF0F1A34)],
                buttonText: "Open Rewards Center",
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
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Summary Stats Bar ─────────────────────────────────────────────
  Widget _buildSummaryBar() {
    final activeCount = _availableRewards.where((r) => !r.isClaimed).length;
    final claimedCount = _availableRewards.where((r) => r.isClaimed).length;
    final totalEarned = _summary.totalCoinsEarned > 0
        ? _summary.totalCoinsEarned
        : (_availableRewards.where((r) => r.isClaimed).fold(0, (sum, r) => sum + r.rewardValue));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1C38).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33FFD700)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _buildStatPill(
                  icon: Icons.card_giftcard_rounded,
                  label: "Available",
                  value: activeCount.toString(),
                  color: const Color(0xFFFFD700),
                ),
              ),
            ),
          ),
          Container(height: 28, width: 1, color: Colors.white12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _buildStatPill(
                  icon: Icons.check_circle_outline_rounded,
                  label: "Claimed",
                  value: claimedCount.toString(),
                  color: const Color(0xFF00E676),
                ),
              ),
            ),
          ),
          Container(height: 28, width: 1, color: Colors.white12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _buildStatPill(
                  icon: Icons.monetization_on_rounded,
                  label: "Earned",
                  value: totalEarned.toString(),
                  color: const Color(0xFFFFC107),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF90A4AE),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Individual Live Event Card ────────────────────────────────────
  Widget _buildEventCard(RewardItem reward) {
    final isGems = reward.rewardType.toLowerCase() == 'gems';
    final accentColor = isGems ? const Color(0xFF00D2FF) : const Color(0xFFFFD700);
    final isBeingClaimed = _claimingRewardId == reward.id;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF102347).withValues(alpha: 0.95),
            const Color(0xFF0A162E).withValues(alpha: 0.95),
          ],
        ),
        border: Border.all(
          color: reward.isClaimed
              ? Colors.white12
              : accentColor.withValues(alpha: 0.45),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: reward.isClaimed ? 0.04 : 0.12),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Circle
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  accentColor.withValues(alpha: 0.25),
                  accentColor.withValues(alpha: 0.08),
                ],
              ),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.6),
                width: 1.2,
              ),
            ),
            child: Icon(
              _getRewardIcon(reward.icon),
              color: accentColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // Title & Description & Reward Pill
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  reward.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  reward.description,
                  style: const TextStyle(
                    color: Color(0xFF90A4AE),
                    fontSize: 11.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isGems ? Icons.diamond_rounded : Icons.monetization_on_rounded,
                          color: accentColor,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "+${reward.rewardValue} ${isGems ? 'Gems' : 'Coins'}",
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Claim Button / State
          SizedBox(
            height: 38,
            child: isBeingClaimed
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Color(0xFFFFD700),
                      ),
                    ),
                  )
                : reward.isClaimed
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_rounded, color: Color(0xFF00E676), size: 16),
                            SizedBox(width: 4),
                            Text(
                              "Claimed",
                              style: TextStyle(
                                color: Color(0xFF00E676),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ElevatedButton(
                        onPressed: reward.canClaim ? () => _claimReward(reward) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFB300),
                          foregroundColor: const Color(0xFF0A1224),
                          elevation: 3,
                          shadowColor: const Color(0xFFFFB300).withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(19),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        child: const Text(
                          "CLAIM",
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          children: [
            // Section Header
            _buildSectionHeader(
              icon: Icons.coffee_rounded,
              title: "COMMUNITY ADDA",
              subtitle: "Private tables, voice banter & friendly matches",
            ),
            const SizedBox(height: 18),

            // Card 1: Host an Adda Lounge Table
            _buildFeatureCard(
              title: "HOST AN ADDA TABLE",
              badge: "VOICE & CHAT",
              badgeColor: const Color(0xFF00E5FF),
              subtitle: "Create a private room for friends and family with custom rules & coins",
              rewardText: "Private Table • 2 to 4 Players • Live Voice",
              icon: Icons.meeting_room_rounded,
              gradientColors: const [Color(0xFF0F3A4B), Color(0xFF0D1E3A)],
              buttonText: "Host Adda Table",
              onTap: () => _openCreateDialog(2),
            ),
            const SizedBox(height: 16),

            // Card 2: Join Adda Table by Code (Real API)
            _buildJoinCodeCard(),
            const SizedBox(height: 16),

            // Card 3: Quick Setup Shortcuts (2P and 4P Tables)
            _buildQuickShortcutsRow(),
            const SizedBox(height: 16),

            // Card 4: How Adda Works Guide
            _buildAddaGuideCard(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinCodeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A30).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x3300E5FF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.vpn_key_rounded, color: Color(0xFF00E5FF), size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Join Adda by Code",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "Enter the 6-character room code shared by your friend to jump into their table.",
            style: TextStyle(
              color: Color(0xFF90A4AE),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF081224),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
                  ),
                  child: TextField(
                    controller: _roomCodeController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                    ),
                    decoration: const InputDecoration(
                      hintText: "ROOM CODE",
                      hintStyle: TextStyle(
                        color: Colors.white24,
                        fontSize: 13,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.normal,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isJoining ? null : _joinRoom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: const Color(0xFF061428),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  child: _isJoining
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Color(0xFF061428),
                          ),
                        )
                      : const Text(
                          "JOIN",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickShortcutsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildShortcutTile(
            title: "2-Player Table",
            subtitle: "Casual 1v1 Room",
            icon: Icons.person_rounded,
            color: const Color(0xFF38BDF8),
            onTap: () => _openCreateDialog(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildShortcutTile(
            title: "4-Player Table",
            subtitle: "4-Way Battle",
            icon: Icons.groups_rounded,
            color: const Color(0xFFFFD700),
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
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1A30).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF90A4AE),
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildAddaGuideCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF091428).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFF90A4AE), size: 18),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  "How Adda Tables Work",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            "• Host generates a live 6-digit room code with custom entry fee.\n"
            "• Friends join by entering the code from anywhere.\n"
            "• Enjoy private voice chat & banter without public leaderboard pressure.",
            style: TextStyle(
              color: Color(0xFF78909C),
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 3. INVENTORY SECTION VIEW (REAL PLAYER VAULT & COLLECTIBLES)
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
          coins: 1000,
          gems: 10,
          level: 1,
        );

    final stats = profile.statistics;

    return RefreshIndicator(
      onRefresh: _fetchInventory,
      color: const Color(0xFFFFD700),
      backgroundColor: const Color(0xFF0F1A30),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            children: [
              // Header
              _buildSectionHeader(
                icon: Icons.inventory_2_rounded,
                title: "PLAYER INVENTORY & VAULT",
                subtitle: "Your real currencies, claimed collectibles & honor badges",
              ),
              const SizedBox(height: 16),

              // Live Currency Holdings Overview Bar
              _buildHoldingsBar(profile),
              const SizedBox(height: 16),

              // Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: List.generate(categories.length, (idx) {
                    final isSelected = _selectedCategory == idx;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          categories[idx],
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                            color: isSelected ? const Color(0xFF091428) : Colors.white70,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: const Color(0xFFFFD700),
                        backgroundColor: const Color(0xFF142038),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFFFFD700) : Colors.white12,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _selectedCategory = idx);
                        },
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),

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
                // Category 0: Real Claimed Collectibles
                if (_selectedCategory == 0) ...[
                  if (_myClaims.isNotEmpty) ...[
                    ..._myClaims.map((claim) => _buildClaimedItemTile(claim)),
                  ] else ...[
                    _buildEmptyCollectiblesCard(),
                  ],
                ]
                // Category 1: Real Match Honor Badges
                else if (_selectedCategory == 1) ...[
                  _buildHonorBadgeTile(
                    title: "Victory Master",
                    condition: stats.wins > 0
                        ? "${stats.wins} Matches Won"
                        : "Win 1 online match to unlock",
                    isUnlocked: stats.wins > 0,
                    icon: Icons.emoji_events_rounded,
                    color: const Color(0xFFFFD700),
                  ),
                  _buildHonorBadgeTile(
                    title: "Elite Roller",
                    condition: stats.totalGames > 0 && stats.winRate >= 50
                        ? "${stats.winRate.toStringAsFixed(0)}% Win Rate Maintained"
                        : "Maintain 50%+ win rate to unlock",
                    isUnlocked: stats.totalGames > 0 && stats.winRate >= 50,
                    icon: Icons.auto_awesome_rounded,
                    color: const Color(0xFF00E676),
                  ),
                  _buildHonorBadgeTile(
                    title: "Battle Veteran",
                    condition: stats.totalGames >= 3
                        ? "${stats.totalGames} Matches Played"
                        : "Play 3 matches to unlock",
                    isUnlocked: stats.totalGames >= 3,
                    icon: Icons.sports_esports_rounded,
                    color: const Color(0xFF38BDF8),
                  ),
                  _buildHonorBadgeTile(
                    title: "Arena Champion",
                    condition: profile.level >= 2 || stats.wins >= 5
                        ? "Level ${profile.level} Reached"
                        : "Reach Level 2 or 5 Wins to unlock",
                    isUnlocked: profile.level >= 2 || stats.wins >= 5,
                    icon: Icons.workspace_premium_rounded,
                    color: const Color(0xFFFFB300),
                  ),
                ]
                // Category 2: Vault Assets & Profile Stats
                else ...[
                  _buildVaultCard(
                    title: "Gold Coins Balance",
                    amount: profile.coins.toString(),
                    subtitle: "Usable for all match betting & room entries",
                    icon: Icons.monetization_on_rounded,
                    color: const Color(0xFFFFD700),
                    actionText: "Manage in Wallet >",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WalletScreen()),
                      );
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
                ],
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Quick Holdings Bar ────────────────────────────────────────────
  Widget _buildHoldingsBar(UserProfileModel profile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1C38).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33FFD700)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
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
          ),
          Container(height: 26, width: 1, color: Colors.white12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
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
          ),
          Container(height: 26, width: 1, color: Colors.white12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
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
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF90A4AE),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Claimed Collectible Tile ──────────────────────────────────────
  Widget _buildClaimedItemTile(UserRewardClaim claim) {
    final isGems = claim.rewardType.toLowerCase() == 'gems';
    final accentColor = isGems ? const Color(0xFF00D2FF) : const Color(0xFFFFD700);

    String dateStr = "Claimed";
    if (claim.claimedAt != null) {
      dateStr = "${claim.claimedAt!.day}/${claim.claimedAt!.month}/${claim.claimedAt!.year}";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A30).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.15),
              border: Border.all(color: accentColor.withValues(alpha: 0.5)),
            ),
            child: Icon(
              isGems ? Icons.diamond_rounded : Icons.card_giftcard_rounded,
              color: accentColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  claim.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: Color(0xFF90A4AE),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              "+${claim.rewardValue} ${isGems ? 'Gems' : 'Coins'}",
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.w900,
                fontSize: 12,
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
        color: const Color(0xFF0F1A30).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined, color: Color(0xFF90A4AE), size: 44),
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
              color: Color(0xFF90A4AE),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ── Honor Badge Tile ──────────────────────────────────────────────
  Widget _buildHonorBadgeTile({
    required String title,
    required String condition,
    required bool isUnlocked,
    required IconData icon,
    required Color color,
  }) {
    final activeColor = isUnlocked ? color : Colors.white30;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A30).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked ? color.withValues(alpha: 0.45) : Colors.white10,
          width: isUnlocked ? 1.4 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: activeColor.withValues(alpha: 0.15),
              border: Border.all(color: activeColor.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, color: activeColor, size: 24),
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
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  condition,
                  style: TextStyle(
                    color: isUnlocked ? const Color(0xFF90A4AE) : Colors.white38,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? color.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isUnlocked ? color : Colors.white24,
                width: 0.8,
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Vault Card ────────────────────────────────────────────────────
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
        color: const Color(0xFF0F1A30).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
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
        color: const Color(0xFF0F1A30).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x3300E676)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: Color(0xFF00E676), size: 26),
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
// 4. SOCIAL SECTION VIEW (REAL COMMUNITY, LEADERBOARD & FRIEND CHALLENGES)
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
    final gamesPlayed = _profile?.statistics.totalGames ?? 0;
    final gamesWon = _profile?.statistics.wins ?? 0;
    final coins = _profile?.coins ?? 0;
    final gems = _profile?.gems ?? 0;
    final winRate = _profile != null
        ? _profile!.statistics.winRate.toStringAsFixed(1)
        : (gamesPlayed > 0 ? ((gamesWon / gamesPlayed) * 100).toStringAsFixed(1) : "0.0");

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          children: [
            // Section Header
            _buildSectionHeader(
              icon: Icons.people_alt_rounded,
              title: "SOCIAL & COMMUNITY",
              subtitle: "Player standing, friendly challenges & live leaderboard",
            ),
            const SizedBox(height: 16),

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
            const SizedBox(height: 16),

            // Card 2: Friendly Match Challenge (Real Room Creation & Code Join)
            _buildChallengeCard(),
            const SizedBox(height: 16),

            // Card 3: Community Champions / Live Leaderboard
            _buildLeaderboardPreviewCard(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

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
          colors: [Color(0xFF1B2E5C), Color(0xFF0F1A30)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x55FFD700)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with level badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF141F36),
                      border: Border.all(color: const Color(0xFFFFD700), width: 2.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.25),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.person, color: Color(0xFFFFD700), size: 32),
                  ),
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF0F1A30), width: 1.5),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rankTitle,
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Win Rate: $winRate% • $gamesWon Won / $gamesPlayed Played",
                      style: const TextStyle(color: Color(0xFF90A4AE), fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFFD700),
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, color: Color(0xFFFFD700), size: 22),
                tooltip: "Sync with server",
                onPressed: _isLoading ? null : _loadAllSocialData,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),
          // Chips Row + View Full Profile button
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Coins chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF081224),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x33FFD700)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFD700), size: 14),
                          const SizedBox(width: 5),
                          Text(
                            "$coins",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Gems chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF081224),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x3300E5FF)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.diamond_rounded, color: Color(0xFF00E5FF), size: 14),
                          const SizedBox(width: 5),
                          Text(
                            "$gems",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Profile Dialog Action
                InkWell(
                  onTap: _openProfileDialog,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "View Profile",
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFFFD700), size: 10),
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

  Widget _buildChallengeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A30).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x3300E676)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sports_esports_rounded, color: Color(0xFF00E676), size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Challenge Friends",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0x2200E676),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "100% REAL",
                  style: TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "Host a private table to challenge friends with a shareable code, or enter your friend's code to play.",
            style: TextStyle(color: Color(0xFF90A4AE), fontSize: 12),
          ),
          const SizedBox(height: 14),

          // Action 1: Host Friendly Room Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: const Text(
                "Create Friendly Room & Invite",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
              ),
              onPressed: () => _openCreateChallengeDialog(2),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: const Color(0xFF061428),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 4,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Divider with "OR ENTER CODE"
          const Row(
            children: [
              Expanded(child: Divider(color: Colors.white12)),
              Flexible(
                flex: 10,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "OR ENTER FRIEND'S CODE",
                      maxLines: 1,
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.white12)),
            ],
          ),
          const SizedBox(height: 12),

          // Room Code Join input
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF081224),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x4400E676)),
                  ),
                  child: TextField(
                    controller: _friendCodeController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                    ),
                    decoration: const InputDecoration(
                      hintText: "FRIEND'S CODE",
                      hintStyle: TextStyle(
                        color: Colors.white24,
                        fontSize: 13,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.normal,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isJoiningRoom ? null : _joinFriendRoom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: const Color(0xFF061428),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  child: _isJoiningRoom
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Color(0xFF061428),
                          ),
                        )
                      : const Text(
                          "JOIN",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A30).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x33FFD700)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Community Champions",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // User's Rank Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x55FFD700)),
                ),
                child: Text(
                  _myRanking != null ? "My Rank: #${_myRanking!.rank}" : "Server Ranks",
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "Live standings from the official backend leaderboard.",
            style: TextStyle(color: Color(0xFF90A4AE), fontSize: 12),
          ),
          const SizedBox(height: 12),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFFD700),
                  strokeWidth: 2.2,
                ),
              ),
            )
          else if (_leaderboard.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Icon(Icons.leaderboard_rounded, color: Colors.white24, size: 36),
                  SizedBox(height: 6),
                  Text(
                    "No rankings recorded yet.\nPlay matches to climb the global leaderboard!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            )
          else ...[
            // Display top 3-4 entries
            ..._leaderboard.take(4).map((entry) => _buildLeaderboardRow(entry)),
          ],

          const SizedBox(height: 14),

          // View Full Leaderboard Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.leaderboard_rounded, color: Color(0xFFFFD700), size: 18),
              label: const Text(
                "Open Full Leaderboard",
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0x66FFD700)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    Widget rankBadge;

    if (entry.rank == 1) {
      rankColor = const Color(0xFFFFD700);
      rankBadge = const Text("🥇", style: TextStyle(fontSize: 18));
    } else if (entry.rank == 2) {
      rankColor = const Color(0xFFE0E0E0);
      rankBadge = const Text("🥈", style: TextStyle(fontSize: 18));
    } else if (entry.rank == 3) {
      rankColor = const Color(0xFFCD7F32);
      rankBadge = const Text("🥉", style: TextStyle(fontSize: 18));
    } else {
      rankColor = const Color(0xFF90A4AE);
      rankBadge = Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Text(
          "#${entry.rank}",
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF081224).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: entry.rank <= 3 ? rankColor.withValues(alpha: 0.3) : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 26, child: Center(child: rankBadge)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "${entry.wins} Wins • ${entry.gamesPlayed} Played",
                  style: const TextStyle(color: Color(0xFF90A4AE), fontSize: 10.5),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "${entry.score} pts",
              style: TextStyle(
                color: rankColor,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
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

Widget _buildFeatureCard({
  required String title,
  required String badge,
  required Color badgeColor,
  required String subtitle,
  required String rewardText,
  required IconData icon,
  required List<Color> gradientColors,
  required String buttonText,
  required VoidCallback onTap,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: gradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
      boxShadow: [
        BoxShadow(
          color: badgeColor.withValues(alpha: 0.2),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF091428),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: badgeColor, size: 22),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Text(
          rewardText,
          style: TextStyle(
            color: badgeColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: badgeColor,
              foregroundColor: const Color(0xFF091428),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            ),
          ),
        ),
      ],
    ),
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
