import 'package:flutter/material.dart';
import '../constants/ludo_colors.dart';
import '../constants/ludo_path.dart';
import 'token.dart';

class LudoPlayer {
  final PlayerColor color;
  String name; // online matches replace the placeholder name with the real player's name
  final bool isBot;
  final List<Token> tokens;
  final String? teamId; // 'A' or 'B' in Team Up mode
  int? rank; // 1 for 1st place, 2 for 2nd, etc.
  bool hasEverOpenedToken;
  bool isSurrendered;

  LudoPlayer({
    required this.color,
    required this.name,
    this.isBot = false,
    this.teamId,
    List<Token>? tokens,
    this.rank,
    this.hasEverOpenedToken = false,
    this.isSurrendered = false,
  }) : tokens = tokens ??
            List.generate(
              4,
              (index) => Token(id: index, color: color),
            );

  bool isTeammateWith(LudoPlayer other) =>
      teamId != null && other.teamId != null && teamId == other.teamId;

  bool get hasOpenedFirstToken =>
      hasEverOpenedToken || tokens.any((t) => t.step >= 0);

  set hasOpenedFirstToken(bool value) {
    hasEverOpenedToken = value;
  }

  Color get primaryColor {
    switch (color) {
      case PlayerColor.red:
        return LudoColors.red;
      case PlayerColor.green:
        return LudoColors.green;
      case PlayerColor.yellow:
        return LudoColors.yellow;
      case PlayerColor.blue:
        return LudoColors.blue;
    }
  }

  Color get darkColor {
    switch (color) {
      case PlayerColor.red:
        return LudoColors.redDark;
      case PlayerColor.green:
        return LudoColors.greenDark;
      case PlayerColor.yellow:
        return LudoColors.yellowDark;
      case PlayerColor.blue:
        return LudoColors.blueDark;
    }
  }

  Color get lightColor {
    switch (color) {
      case PlayerColor.red:
        return LudoColors.redLight;
      case PlayerColor.green:
        return LudoColors.greenLight;
      case PlayerColor.yellow:
        return LudoColors.yellowLight;
      case PlayerColor.blue:
        return LudoColors.blueLight;
    }
  }

  int get finishedCount => tokens.where((t) => t.hasReachedGoal).length;
  bool get hasFinished => finishedCount == 4;

  List<Token> getMovableTokens(int diceValue) {
    if (diceValue < 1 || diceValue > 6) return [];
    return tokens.where((t) => t.canMove(diceValue)).toList();
  }

  bool canMove(int diceValue) {
    return getMovableTokens(diceValue).isNotEmpty;
  }
}
