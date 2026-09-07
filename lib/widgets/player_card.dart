import 'package:flutter/material.dart';
import '../constants/ludo_colors.dart';
import '../logic/ludo_game_controller.dart';
import '../models/ludo_player.dart';
import '../models/game_state.dart';
import 'dice/animated_dice.dart';

class PlayerCard extends StatelessWidget {
  final LudoPlayer player;
  final bool isCurrentTurn;
  final LudoGameController controller;

  const PlayerCard({
    super.key,
    required this.player,
    required this.isCurrentTurn,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final canRoll = isCurrentTurn &&
        state.phase == TurnPhase.waitingForRoll &&
        !player.isBot;

    return AnimatedContainer(
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
          // Player Avatar Circle
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [player.lightColor, player.primaryColor, player.darkColor],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 3,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: Icon(
              player.isBot ? Icons.smart_toy_rounded : Icons.person_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),

          // Player Name & Progress
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                player.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Text(
                    "Home: ${player.finishedCount}/4",
                    style: TextStyle(
                      color: player.finishedCount > 0
                          ? Colors.amber
                          : LudoColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

          // Dice area
          if (isCurrentTurn)
            AnimatedDice(
              value: state.currentDiceValue,
              isRolling: state.phase == TurnPhase.animatingMove &&
                  state.currentDiceValue == null,
              canRoll: canRoll,
              onRoll: controller.rollDice,
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
