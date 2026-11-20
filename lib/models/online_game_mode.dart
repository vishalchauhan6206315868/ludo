import 'package:flutter/material.dart';

/// The 5 supported online game modes in Ludo Supreme.
enum OnlineModeType {
  classic,
  oneKillWin,
  quick,
  popular,
  mask,
}

/// Data-driven configuration model for Online Game Modes.
///
/// Prepares for future backend integration where active player counts,
/// available lobbies, and matchmaking statuses are populated dynamically.
class OnlineGameMode {
  final String id;
  final String title;
  final String description;
  final int playerCount;
  final IconData icon;
  final OnlineModeType modeType;
  final List<Color> gradientColors;
  final Color accentColor;
  final Color glowColor;
  final String badgeText;

  const OnlineGameMode({
    required this.id,
    required this.title,
    required this.description,
    required this.playerCount,
    required this.icon,
    required this.modeType,
    required this.gradientColors,
    required this.accentColor,
    required this.glowColor,
    required this.badgeText,
  });

  /// Formatted player count with comma separators (e.g. 14,250).
  String get formattedPlayerCount {
    final str = playerCount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  /// Default 5 online modes specified for Ludo Supreme:
  /// A. CLASSIC
  /// B. 1 KILL WIN
  /// C. QUICK
  /// D. POPULAR
  /// E. MASK
  static const List<OnlineGameMode> defaultModes = [
    OnlineGameMode(
      id: 'classic',
      title: 'CLASSIC',
      description: 'Traditional 4-token Ludo race to home',
      playerCount: 14250, // TODO: Replace with live count from matchmaking server
      icon: Icons.casino_rounded,
      modeType: OnlineModeType.classic,
      gradientColors: [
        Color(0xFF134094),
        Color(0xFF0C2766),
        Color(0xFF06153B),
      ],
      accentColor: Color(0xFF4FC3F7),
      glowColor: Color(0xFF29B6F6),
      badgeText: 'TRADITIONAL',
    ),
    OnlineGameMode(
      id: 'one_kill_win',
      title: '1 KILL WIN',
      description: 'First pawn capture claims absolute victory',
      playerCount: 8920, // TODO: Replace with live count from matchmaking server
      icon: Icons.shield_rounded,
      modeType: OnlineModeType.oneKillWin,
      gradientColors: [
        Color(0xFFB71C1C),
        Color(0xFF880E4F),
        Color(0xFF3E0617),
      ],
      accentColor: Color(0xFFFF8A80),
      glowColor: Color(0xFFFF5252),
      badgeText: 'TACTICAL',
    ),
    OnlineGameMode(
      id: 'quick',
      title: 'QUICK',
      description: 'High-speed match with rapid 10s turns',
      playerCount: 19840, // TODO: Replace with live count from matchmaking server
      icon: Icons.bolt_rounded,
      modeType: OnlineModeType.quick,
      gradientColors: [
        Color(0xFF1B5E20),
        Color(0xFF0E3D14),
        Color(0xFF051B08),
      ],
      accentColor: Color(0xFFB9F6CA),
      glowColor: Color(0xFF00E676),
      badgeText: 'FAST PACE',
    ),
    OnlineGameMode(
      id: 'popular',
      title: 'POPULAR',
      description: 'Most active tournament lobbies with top prizes',
      playerCount: 25310, // TODO: Replace with live count from matchmaking server
      icon: Icons.local_fire_department_rounded,
      modeType: OnlineModeType.popular,
      gradientColors: [
        Color(0xFF6A1B9A),
        Color(0xFF4A148C),
        Color(0xFF220542),
      ],
      accentColor: Color(0xFFEA80FC),
      glowColor: Color(0xFFD500F9),
      badgeText: 'TRENDING',
    ),
    OnlineGameMode(
      id: 'mask',
      title: 'MASK',
      description: 'Hidden pawn values & mystery tactical surprises',
      playerCount: 4150, // TODO: Replace with live count from matchmaking server
      icon: Icons.masks_rounded,
      modeType: OnlineModeType.mask,
      gradientColors: [
        Color(0xFF00695C),
        Color(0xFF004D40),
        Color(0xFF00251A),
      ],
      accentColor: Color(0xFF84FFFF),
      glowColor: Color(0xFF00E5FF),
      badgeText: 'SPECIAL',
    ),
  ];
}
