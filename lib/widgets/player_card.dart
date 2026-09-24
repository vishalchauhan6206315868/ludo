import 'package:flutter/material.dart';
import '../constants/ludo_colors.dart';
import '../constants/ludo_path.dart';
import '../logic/ludo_game_controller.dart';
import '../models/ludo_player.dart';
import '../models/game_state.dart';
import 'dice/animated_dice.dart';

class PlayerCard extends StatelessWidget {
  final LudoPlayer player;
  final bool isCurrentTurn;
  final LudoGameController controller;
  final Size? boardSize;
  final double? diceSize;
  final bool isCompact;

  const PlayerCard({
    super.key,
    required this.player,
    required this.isCurrentTurn,
    required this.controller,
    this.boardSize,
    this.diceSize,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final canRoll = isCurrentTurn &&
        state.phase == TurnPhase.waitingForRoll &&
        !player.isBot &&
        !controller.isBotPlaying &&
        !state.currentPlayer.isBot;

    final secondsRemaining = controller.turnSecondsRemaining;
    final progress = secondsRemaining / LudoGameController.maxTurnSeconds;
    final timerColor = secondsRemaining > 5
        ? Colors.greenAccent
        : (secondsRemaining > 2 ? Colors.amber : Colors.redAccent);

    // Determine if this player's card is on the top row of the screen
    final isTop = (state.mode == GameMode.fourPlayer &&
            (player.color == PlayerColor.red ||
                player.color == PlayerColor.green)) ||
        (state.mode != GameMode.fourPlayer && player.color != PlayerColor.red);

    final effectiveDiceSize = isCompact
        ? (diceSize != null ? diceSize!.clamp(30.0, 36.0) : 36.0)
        : (diceSize ?? 46.0);
    final horizontalPad = isCompact
        ? 6.0
        : (effectiveDiceSize > 56.0 ? 16.0 : 12.0);
    final verticalPad = isCompact
        ? 5.0
        : (effectiveDiceSize > 56.0 ? 12.0 : 9.0);

    final avatarOuterSize = isCompact ? 32.0 : 44.0;
    final avatarInnerSize = isCompact ? 26.0 : 36.0;
    final avatarIconSize = isCompact ? 14.0 : 20.0;
    final innerSpacing = isCompact ? 4.0 : 10.0;

    return AnimatedContainer(
      clipBehavior: Clip.none,
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPad,
        vertical: verticalPad,
      ),
      decoration: BoxDecoration(
        color: isCurrentTurn
            ? player.primaryColor.withValues(alpha: 0.15)
            : LudoColors.surfaceDark,
        borderRadius: BorderRadius.circular(isCompact ? 10 : 16),
        border: Border.all(
          color: isCurrentTurn ? player.primaryColor : Colors.white12,
          width: isCurrentTurn ? 2.5 : 1.0,
        ),
        boxShadow: [
          if (isCurrentTurn)
            BoxShadow(
              color: player.primaryColor.withValues(alpha: 0.35),
              blurRadius: 14,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Row(
        mainAxisSize: isCompact ? MainAxisSize.max : MainAxisSize.min,
        children: [
          // Player Avatar Circle with circular countdown timer ring
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (isCurrentTurn && !state.isGameOver)
                SizedBox(
                  width: avatarOuterSize,
                  height: avatarOuterSize,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: isCompact ? 2.0 : 2.8,
                    valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                    backgroundColor: Colors.white12,
                  ),
                ),
              Container(
                width: avatarInnerSize,
                height: avatarInnerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: player.primaryColor,
                  boxShadow: [
                    if (isCurrentTurn)
                      BoxShadow(
                        color: player.primaryColor.withValues(alpha: 0.8),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: Icon(
                  player.isBot ? Icons.smart_toy_rounded : Icons.person_rounded,
                  color: Colors.white,
                  size: avatarIconSize,
                ),
              ),
            ],
          ),
          SizedBox(width: innerSpacing),

          // Player Name & Progress & Timer (Wrapped in Expanded to prevent any overflow)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        player.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isCompact ? 10 : 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isCurrentTurn && !state.isGameOver) ...[
                      const SizedBox(width: 3),
                      if (isCompact)
                        Text(
                          "${controller.turnSecondsRemaining}s",
                          style: TextStyle(
                            color: timerColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: timerColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: timerColor.withValues(alpha: 0.6),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.timer_rounded,
                                  size: 10, color: timerColor),
                              const SizedBox(width: 2),
                              Text(
                                "${controller.turnSecondsRemaining}s",
                                style: TextStyle(
                                  color: timerColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isCompact
                            ? "${player.finishedCount}/4"
                            : "${player.finishedCount}/4 Home",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: isCompact ? 9 : 11,
                        ),
                      ),
                    ),
                    if (player.hasFinished) ...[
                      const SizedBox(width: 2),
                      Icon(Icons.emoji_events_rounded,
                          color: Colors.amber, size: isCompact ? 10 : 14),
                    ]
                  ],
                ),
              ],
            ),
          ),

          SizedBox(width: innerSpacing),

          // Physical 3D Dice area
          if (isCurrentTurn)
            AnimatedDice(
              value: state.currentDiceValue,
              isRolling: state.phase == TurnPhase.throwingDice,
              canRoll: canRoll,
              isTopPlayer: isTop,
              isHuman: !player.isBot,
              boardSize: boardSize,
              onRoll: controller.onPhysicalDiceThrowStart,
              onThrowComplete: (finalValue) {
                if (!player.isBot) {
                  controller.onPhysicalDiceThrowComplete(finalValue);
                }
              },
              size: effectiveDiceSize,
            )
          else
            Container(
              width: (effectiveDiceSize - 6.0).clamp(32.0, 62.0),
              height: (effectiveDiceSize - 6.0).clamp(32.0, 62.0),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(
                  ((effectiveDiceSize - 6.0) * 0.22).clamp(6.0, 14.0),
                ),
              ),
              child: Icon(
                Icons.casino_outlined,
                color: Colors.white38,
                size: (effectiveDiceSize * 0.48).clamp(16.0, 32.0),
              ),
            ),
        ],
      ),
    );
  }
}
