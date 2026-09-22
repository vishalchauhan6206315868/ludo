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

  const PlayerCard({
    super.key,
    required this.player,
    required this.isCurrentTurn,
    required this.controller,
    this.boardSize,
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

    return AnimatedContainer(
      clipBehavior: Clip.none,
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrentTurn
            ? player.primaryColor.withValues(alpha: 0.15)
            : LudoColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Player Avatar Circle with circular countdown timer ring
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (isCurrentTurn && !state.isGameOver)
                SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 2.8,
                    valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                    backgroundColor: Colors.white12,
                  ),
                ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: player.primaryColor,
                  boxShadow: [
                    if (isCurrentTurn)
                      BoxShadow(
                        color: player.primaryColor
                            .withValues(alpha: 0.8),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: Icon(
                  player.isBot ? Icons.smart_toy_rounded : Icons.person_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),

          // Player Name & Progress & Timer
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    player.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isCurrentTurn && !state.isGameOver) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: timerColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: timerColor.withValues(alpha: 0.6),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.timer_rounded,
                              size: 10, color: timerColor),
                          const SizedBox(width: 3),
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
              const SizedBox(height: 3),
              Row(
                children: [
                  Text(
                    "${player.finishedCount}/4 In Home",
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                    ),
                  ),
                  if (player.hasFinished) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.emoji_events_rounded,
                        color: Colors.amber, size: 14),
                  ]
                ],
              ),
            ],
          ),

          const SizedBox(width: 12),

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
              size: 46,
            )
          else
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.casino_outlined,
                  color: Colors.white38, size: 22),
            ),
        ],
      ),
    );
  }
}
