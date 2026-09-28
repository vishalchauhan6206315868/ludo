import 'package:flutter/material.dart';

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
// 1. EVENT SECTION VIEW
// ============================================================================
class EventSectionView extends StatelessWidget {
  const EventSectionView({super.key});

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
              icon: Icons.emoji_events_rounded,
              title: "EVENTS & TOURNAMENTS",
              subtitle: "Championships, Daily Quests & Arena Cups",
            ),
            const SizedBox(height: 18),

            // Featured Tournament Card
            _buildFeatureCard(
              title: "SUPREME GRAND PRIX",
              badge: "LIVE TOURNAMENT",
              badgeColor: const Color(0xFFFFB300),
              subtitle: "4-Player Knockout Championship • Free Entry",
              rewardText: "Prize: 10,000 Coins + Diamond Crown",
              icon: Icons.military_tech_rounded,
              gradientColors: [const Color(0xFF2E1A47), const Color(0xFF101B3B)],
              buttonText: "Register Now",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Tournament registration opens this Friday!"),
                    backgroundColor: Color(0xFF1B2E5C),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),

            // Daily Quests Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1A30).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0x33FFD700)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.checklist_rounded, color: Color(0xFFFFD700), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Daily Quests",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Resets in 8h",
                        style: TextStyle(color: Color(0xFF90A4AE), fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildQuestRow("Roll three 6s in a single match", "2/3", 0.66, "250 XP"),
                  const Divider(color: Colors.white12, height: 16),
                  _buildQuestRow("Play 1 Pass N Play match with friends", "1/1", 1.0, "500 Coins"),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Clean Tournament Schedule Placeholder
            _buildInfoCard(
              icon: Icons.calendar_month_rounded,
              title: "Next Arena Cup",
              description: "Season 4 Knockout Round kicks off Saturday at 6:00 PM. No active matches currently in progress.",
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Widget _buildQuestRow(String title, String progressText, double progress, String reward) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
            Text(
              reward,
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFB300)),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(progressText, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// 2. ADDA SECTION VIEW
// ============================================================================
class AddaSectionView extends StatelessWidget {
  const AddaSectionView({super.key});

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
              icon: Icons.coffee_rounded,
              title: "COMMUNITY ADDA",
              subtitle: "Hangout, banter, and casual rooms with players",
            ),
            const SizedBox(height: 18),

            // Create Adda Lounge Table Card
            _buildFeatureCard(
              title: "HOST AN ADDA LOUNGE",
              badge: "VOICE & CHAT",
              badgeColor: const Color(0xFF00E5FF),
              subtitle: "Start a casual lounge table for friends and club members",
              rewardText: "Casual • No Rank Pressure • Custom Rules",
              icon: Icons.forum_rounded,
              gradientColors: [const Color(0xFF0F3A4B), const Color(0xFF0D1E3A)],
              buttonText: "Create Adda Table",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Adda Lounge Table hosting ready for next update!"),
                    backgroundColor: Color(0xFF00695C),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),

            // Community Clubs Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1A30).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0x3300E5FF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.groups_rounded, color: Color(0xFF00E5FF), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Popular Clubs",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildClubTile("Royal Ludo Kings", "342 Members", Icons.shield_rounded),
                  const Divider(color: Colors.white12, height: 14),
                  _buildClubTile("Delhi Dice Masters", "198 Members", Icons.local_fire_department_rounded),
                  const Divider(color: Colors.white12, height: 14),
                  _buildClubTile("Weekend Speed Rollers", "512 Members", Icons.bolt_rounded),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Global Chat Placeholder
            _buildInfoCard(
              icon: Icons.chat_bubble_outline_rounded,
              title: "Global Player Lounge",
              description: "Live chat with players across the world will be enabled here in the next community update.",
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Widget _buildClubTile(String name, String members, IconData icon) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0x2200E5FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF00E5FF), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                members,
                style: const TextStyle(color: Color(0xFF90A4AE), fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF00E5FF), width: 1),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text(
            "Join",
            style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 3. INVENTORY SECTION VIEW
// ============================================================================
class InventorySectionView extends StatefulWidget {
  const InventorySectionView({super.key});

  @override
  State<InventorySectionView> createState() => _InventorySectionViewState();
}

class _InventorySectionViewState extends State<InventorySectionView> {
  int _selectedCategory = 0;
  int _equippedDiceIndex = 0;

  static const List<String> categories = ["DICE SKINS", "TOKEN PAWNS", "BOARDS", "BADGES"];

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
              icon: Icons.inventory_2_rounded,
              title: "PLAYER INVENTORY",
              subtitle: "Customize your dice, pawns, board themes & collectibles",
            ),
            const SizedBox(height: 16),

            // Category Chips
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
                          fontSize: 11,
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

            // Items Grid for Selected Category
            if (_selectedCategory == 0) ...[
              _buildDiceItem(0, "Classic Ivory", "Default", Icons.casino_rounded, const Color(0xFFE2E8F0)),
              _buildDiceItem(1, "Golden Royale", "Legendary", Icons.workspace_premium_rounded, const Color(0xFFFFD700)),
              _buildDiceItem(2, "Cyber Neon", "Epic", Icons.bolt_rounded, const Color(0xFF00E5FF)),
              _buildDiceItem(3, "Ruby Magma", "Rare", Icons.local_fire_department_rounded, const Color(0xFFFF5252)),
            ] else if (_selectedCategory == 1) ...[
              _buildSimpleItem("Supreme Royal Pawns", "Equipped", Icons.military_tech_rounded, const Color(0xFFFFD700)),
              _buildSimpleItem("Crystal Prism Pawns", "Unlocked", Icons.diamond_rounded, const Color(0xFF64B5F6)),
              _buildSimpleItem("Minimalist Pawns", "Unlocked", Icons.circle_rounded, const Color(0xFF81C784)),
            ] else if (_selectedCategory == 2) ...[
              _buildSimpleItem("Royal Palace Velvet", "Equipped", Icons.dashboard_rounded, const Color(0xFFFFD700)),
              _buildSimpleItem("Cyberpunk Arena", "Unlocked", Icons.grid_4x4_rounded, const Color(0xFF00E5FF)),
              _buildSimpleItem("Classic Wooden Board", "Unlocked", Icons.texture_rounded, const Color(0xFFBCAAA4)),
            ] else ...[
              _buildSimpleItem("Dice Master 2026", "Gold Badge", Icons.military_tech_rounded, const Color(0xFFFFD700)),
              _buildSimpleItem("First Victory Trophy", "Silver Badge", Icons.emoji_events_rounded, const Color(0xFFB0BEC5)),
              _buildSimpleItem("Pass N Play Veteran", "Bronze Badge", Icons.sports_esports_rounded, const Color(0xFFFFB74D)),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDiceItem(int index, String name, String rarity, IconData icon, Color color) {
    final isEquipped = _equippedDiceIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A30).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEquipped ? const Color(0xFFFFD700) : Colors.white12,
          width: isEquipped ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, color: color, size: 24),
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
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  rarity,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _equippedDiceIndex = index);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("$name equipped!"),
                  duration: const Duration(milliseconds: 900),
                  backgroundColor: const Color(0xFF1B2E5C),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isEquipped ? const Color(0xFFFFD700) : const Color(0xFF1C2B4A),
              foregroundColor: isEquipped ? const Color(0xFF091428) : Colors.white70,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              isEquipped ? "EQUIPPED" : "EQUIP",
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleItem(String name, String status, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A30).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
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
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: Color(0xFFFFD700), size: 20),
        ],
      ),
    );
  }
}

// ============================================================================
// 4. SOCIAL SECTION VIEW
// ============================================================================
class SocialSectionView extends StatelessWidget {
  final String userName;

  const SocialSectionView({super.key, required this.userName});

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
              icon: Icons.people_alt_rounded,
              title: "SOCIAL & FRIENDS",
              subtitle: "Player profiles, friends list & challenges",
            ),
            const SizedBox(height: 16),

            // Profile Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B2E5C), Color(0xFF0F1A30)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0x44FFD700)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF141F36),
                      border: Border.all(color: const Color(0xFFFFD700), width: 2),
                    ),
                    child: const Icon(Icons.person, color: Color(0xFFFFD700), size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Level 14 • Grandmaster Rank",
                          style: TextStyle(color: Color(0xFFFFD700), fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Win Rate: 68% • 42 Matches Won",
                          style: TextStyle(color: Color(0xFF90A4AE), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Online Friends
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1A30).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.wifi_tethering_rounded, color: Color(0xFF00E676), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Online Friends (2)",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFriendRow("Rahul_LudoKing", "Free to Play", true),
                  const Divider(color: Colors.white12, height: 16),
                  _buildFriendRow("Sneha_Rolls", "In Match (Turn 12)", false),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Share Invite Code
            _buildFeatureCard(
              title: "INVITE YOUR FRIENDS",
              badge: "BONUS COINS",
              badgeColor: const Color(0xFFFFD700),
              subtitle: "Share invite code: LUDO-8821 to earn rewards!",
              rewardText: "Both get 500 Coins on first game",
              icon: Icons.share_rounded,
              gradientColors: [const Color(0xFF193254), const Color(0xFF0E1A33)],
              buttonText: "Copy Invite Code",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Invite Code copied to clipboard: LUDO-8821"),
                    backgroundColor: Color(0xFF1B2E5C),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Widget _buildFriendRow(String name, String status, bool canInvite) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF162544),
            border: Border.all(
              color: canInvite ? const Color(0xFF00E676) : Colors.white24,
            ),
          ),
          child: const Icon(Icons.person, color: Colors.white70, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                status,
                style: TextStyle(
                  color: canInvite ? const Color(0xFF00E676) : const Color(0xFF90A4AE),
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (canInvite) ...[
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: const Color(0xFF091428),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              "Challenge",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ],
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
