import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/online_game_mode.dart';

/// Reusable gaming card representing a selectable Online Game Mode.
///
/// Follows the visual identity of Ludo Supreme:
/// - Mode-specific deep gaming gradients
/// - 3D metallic golden beveled border on selection
/// - Multi-layer ambient gold bloom & 3D depth shadows
/// - Glowing live online green dot indicator with player count
/// - Animated gold checkmark selection circle
class OnlineGameModeCard extends StatefulWidget {
  final OnlineGameMode mode;
  final bool isSelected;
  final VoidCallback onSelect;

  const OnlineGameModeCard({
    super.key,
    required this.mode,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  State<OnlineGameModeCard> createState() => _OnlineGameModeCardState();
}

class _OnlineGameModeCardState extends State<OnlineGameModeCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final mode = widget.mode;
    final isSelected = widget.isSelected;

    return AnimatedScale(
      scale: _isPressed ? 0.97 : (isSelected ? 1.015 : 1.0),
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          // Metallic Gold Outer Bevel Frame when selected, subtle rim when unselected
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    Color(0xFFFFFDE7), // Highlight reflection
                    Color(0xFFFFE082),
                    Color(0xFFFFB300), // Pure rich gold
                    Color(0xFFFF8F00),
                    Color(0xFF8D4B00), // Deep bronze bevel
                    Color(0xFFFFD54F),
                  ],
                  stops: [0.0, 0.20, 0.45, 0.70, 0.90, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.16),
                    Colors.white.withValues(alpha: 0.04),
                    const Color(0xFFFFD700).withValues(alpha: 0.12),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          boxShadow: [
            if (isSelected) ...[
              // Layer 1: Mode Accent + Gold Bloom Halo
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.42),
                blurRadius: 18,
                spreadRadius: 1.5,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: mode.glowColor.withValues(alpha: 0.35),
                blurRadius: 14,
                spreadRadius: 0.5,
              ),
              // Layer 2: Deep 3D Drop Shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.75),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ] else ...[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ],
        ),
        padding: EdgeInsets.all(isSelected ? 2.5 : 1.2),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isSelected ? 17.5 : 18.8),
            // Inner secondary border
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFFD700).withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.08),
              width: 1.0,
            ),
            // Mode-specific Rich Radial/Linear Deep Gaming Gradient
            gradient: LinearGradient(
              colors: mode.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: Key('online_mode_card_${mode.id}'),
              borderRadius: BorderRadius.circular(18),
              splashColor: mode.accentColor.withValues(alpha: 0.2),
              highlightColor: Colors.transparent,
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              onTap: () {
                try {
                  HapticFeedback.selectionClick();
                } catch (_) {}
                widget.onSelect();
              },
              child: Stack(
                children: [
                  // Subtle Specular Curved Gloss Highlight (Depth Effect)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 38,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(17),
                          topRight: Radius.circular(17),
                        ),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: isSelected ? 0.16 : 0.08),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),

                  // Card Content
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 13.0,
                    ),
                    child: Row(
                      children: [
                        // LEFT: Mode Icon with Emblem Backing
                        _buildModeIcon(mode, isSelected),

                        const SizedBox(width: 10),

                        // CENTER: Selection Info, Mode Title, Subtitle, Players & Online Dot
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Top line: Mode Title & Badge
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      mode.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.0,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withValues(alpha: 0.8),
                                            offset: const Offset(0, 1.5),
                                            blurRadius: 3,
                                          ),
                                          if (isSelected)
                                            Shadow(
                                              color: mode.glowColor.withValues(alpha: 0.6),
                                              blurRadius: 8,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  _buildBadge(mode.badgeText, isSelected, mode.accentColor),
                                ],
                              ),
                              const SizedBox(height: 3),

                              // Description
                              Text(
                                mode.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 5),

                              // Bottom line: Green online indicator & "Players: XXXX"
                              Row(
                                children: [
                                  _buildPulsingGreenIndicator(),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      "Players: ${mode.formattedPlayerCount}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFFB0BEC5),
                                        fontSize: 11.0,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // RIGHT: Selection Circle Indicator
                        _buildSelectionIndicator(isSelected),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Stylized icon backing matching Ludo Supreme royal theme
  Widget _buildModeIcon(OnlineGameMode mode, bool isSelected) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            mode.accentColor.withValues(alpha: isSelected ? 0.35 : 0.20),
            Colors.black.withValues(alpha: 0.45),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isSelected
              ? const Color(0xFFFFD700)
              : mode.accentColor.withValues(alpha: 0.4),
          width: isSelected ? 1.8 : 1.2,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: mode.glowColor.withValues(alpha: 0.45),
              blurRadius: 10,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Center(
        child: Icon(
          mode.icon,
          color: isSelected ? const Color(0xFFFFD700) : Colors.white,
          size: 28,
        ),
      ),
    );
  }

  /// Small mode category pill tag
  Widget _buildBadge(String text, bool isSelected, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFFFD700).withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected
              ? const Color(0xFFFFD700).withValues(alpha: 0.7)
              : Colors.white24,
          width: 0.8,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? const Color(0xFFFFD700) : Colors.white70,
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  /// Live green online dot with luminous glow
  Widget _buildPulsingGreenIndicator() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF00E676),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E676).withValues(alpha: 0.85),
            blurRadius: 6,
            spreadRadius: 1.5,
          ),
        ],
      ),
    );
  }

  /// Selection Circle Indicator:
  /// - Gold checked circle when selected
  /// - Empty circular outline when unselected
  Widget _buildSelectionIndicator(bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isSelected
            ? const LinearGradient(
                colors: [
                  Color(0xFFFFF9C4),
                  Color(0xFFFFD700),
                  Color(0xFFFF8F00),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isSelected ? null : Colors.black.withValues(alpha: 0.35),
        border: Border.all(
          color: isSelected
              ? const Color(0xFFFFFDE7)
              : const Color(0xFFFFD700).withValues(alpha: 0.45),
          width: isSelected ? 1.8 : 1.6,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.65),
              blurRadius: 10,
              spreadRadius: 1,
            ),
        ],
      ),
      child: isSelected
          ? const Center(
              child: Icon(
                Icons.check_rounded,
                color: Color(0xFF2B1300),
                size: 19,
                weight: 700,
              ),
            )
          : null,
    );
  }
}
