import 'package:flutter/material.dart';
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
  final double? boardDiceSize;
  final bool isCompact;
  final bool isRightAligned;
  final Key? diceSlotKey;
  final GlobalKey? boardKey;
  final bool hideActiveDice;
  final bool handoffOnSettle;
  final void Function(
    Offset globalCenter,
    int finalValue, [
    double tiltX,
    double tiltY,
    double tiltZ,
  ])? onBoardSettle;

  const PlayerCard({
    super.key,
    required this.player,
    required this.isCurrentTurn,
    required this.controller,
    this.boardSize,
    this.boardKey,
    this.diceSize,
    this.boardDiceSize,
    this.isCompact = false,
    this.isRightAligned = false,
    this.diceSlotKey,
    this.hideActiveDice = false,
    this.handoffOnSettle = false,
    this.onBoardSettle,
  });

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final playerIdx = state.players.indexOf(player);
    final bool isThisPlayerMySeat = controller.isOnlineMatch
        ? (playerIdx == controller.mySeatIndex)
        : (controller.state.mode == GameMode.vsComputer
            ? (player.color == PlayerColor.yellow)
            : true);

    final canRoll = isCurrentTurn &&
        !player.isSurrendered &&
        state.phase == TurnPhase.waitingForRoll &&
        !player.isBot &&
        !controller.isBotPlaying &&
        !state.currentPlayer.isBot &&
        isThisPlayerMySeat;

    final bool showRoleBadge = controller.isOnlineMatch || controller.state.mode == GameMode.vsComputer;
    final bool isMe = controller.isOnlineMatch
        ? (playerIdx == controller.mySeatIndex)
        : (controller.state.mode == GameMode.vsComputer
            ? (player.color == PlayerColor.yellow)
            : false);

    // In Online 2-Player mode, opponent is always at top, and my player is always at bottom.
    final bool isTop = (controller.isOnlineMatch && state.players.length == 2)
        ? !isMe
        : (player.color == PlayerColor.red || player.color == PlayerColor.green);

    // Pod dice sits big & prominent in the corner cards ("bada hi rkh")
    final effectiveDiceSize = diceSize != null
        ? diceSize!.clamp(44.0, 76.0)
        : (isCompact ? 48.0 : 54.0);
    // Player pod avatar stays large & prominent ("bada")
    final double personBoxSize = isCompact ? 44.0 : 48.0;
    final double personIconSize = isCompact ? 30.0 : 34.0;
    final double pad = isCompact ? 5.0 : 6.0;
    final double innerSpacing = isCompact ? 6.0 : 8.0;

    final Color playerTint = player.primaryColor;
    final Color cardBg = isCurrentTurn
        ? Color.alphaBlend(
            playerTint.withValues(alpha: 0.25),
            const Color(0xFF0E172B),
          )
        : Color.alphaBlend(
            playerTint.withValues(alpha: 0.11),
            const Color(0xFF0B1324),
          );

    final Widget emptySlotWidget = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: (isCurrentTurn && canRoll && !player.isBot)
          ? controller.onPhysicalDiceThrowStart
          : null,
      child: MouseRegion(
        cursor: (isCurrentTurn && canRoll && !player.isBot)
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: Container(
          width: effectiveDiceSize,
          height: effectiveDiceSize,
          decoration: BoxDecoration(
            color: playerTint.withValues(alpha: isCurrentTurn ? 0.22 : 0.15),
            borderRadius: BorderRadius.circular(
              (effectiveDiceSize * 0.22).clamp(7.0, 14.0),
            ),
            border: Border.all(
              color: isCurrentTurn
                  ? playerTint
                  : playerTint.withValues(alpha: 0.45),
              width: isCurrentTurn ? 1.8 : 1.2,
            ),
            boxShadow: [
              if (isCurrentTurn)
                BoxShadow(
                  color: playerTint.withValues(alpha: 0.35),
                  blurRadius: 8,
                  spreadRadius: 0.5,
                ),
            ],
          ),
          child: isCurrentTurn
              ? null
              : Icon(
                  Icons.casino_outlined,
                  color: Colors.white54,
                  size: (effectiveDiceSize * 0.52).clamp(16.0, 36.0),
                ),
        ),
      ),
    );

    final occupiedCoords = <BoardCoord>[];
    for (final p in state.players) {
      for (final t in p.tokens) {
        if (!t.isInBase) {
          occupiedCoords.add(t.coordinate);
        }
      }
    }

    // Exactly one active dice is shown at a time across both online and offline modes;
    // the inactive player's slot remains empty (as in VS COMPUTER).
    final bool showPodDice = isCurrentTurn && !hideActiveDice;
    final int diceDisplayValue = (isCurrentTurn && state.currentDiceValue != null)
        ? state.currentDiceValue!
        : (controller.lastSettledDiceValue > 0 ? controller.lastSettledDiceValue : 1);

    final Widget diceWidget = KeyedSubtree(
      key: diceSlotKey,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          emptySlotWidget,
          if (showPodDice)
            AnimatedDice(
              value: diceDisplayValue,
              isRolling: isCurrentTurn && (state.phase == TurnPhase.throwingDice),
              canRoll: canRoll,
              isTopPlayer: isTop,
              isHuman: !player.isBot,
              boardSize: boardSize,
              boardKey: boardKey,
              onRoll: canRoll ? controller.onPhysicalDiceThrowStart : null,
              deferThrowToParent: false,
              handoffOnSettle: handoffOnSettle,
              onBoardSettle: onBoardSettle,
              onThrowComplete: (finalValue) {
                if (!player.isBot && isCurrentTurn) {
                  controller.onPhysicalDiceThrowComplete(finalValue);
                }
              },
              size: effectiveDiceSize,
              boardDiceSize: boardDiceSize,
              occupiedCoords: occupiedCoords,
            ),
        ],
      ),
    );

    final Widget personWidget = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: personBoxSize,
          height: personBoxSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: playerTint.withValues(alpha: isCurrentTurn ? 0.24 : 0.12),
            border: Border.all(
              color: isCurrentTurn
                  ? playerTint
                  : playerTint.withValues(alpha: 0.55),
              width: isCurrentTurn ? 2.0 : 1.1,
            ),
            boxShadow: [
              if (isCurrentTurn)
                BoxShadow(
                  color: playerTint.withValues(alpha: 0.48),
                  blurRadius: 10,
                  spreadRadius: 0.8,
                ),
            ],
          ),
          child: Icon(
            Icons.person_rounded,
            color: playerTint,
            size: personIconSize,
          ),
        ),
        if (showRoleBadge)
          Positioned(
            top: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.0),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF10B981) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: isMe ? const Color(0xFF34D399) : Colors.white24,
                  width: 0.8,
                ),
                boxShadow: [
                  if (isMe)
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                ],
              ),
              child: Text(
                isMe ? "YOU" : "OPPONENT",
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.white70,
                  fontSize: 8.0,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        if (player.hasFinished)
          const Positioned(
            top: -4,
            right: -4,
            child: Icon(
              Icons.emoji_events_rounded,
              color: Colors.amber,
              size: 14,
            ),
          ),
        if (player.isSurrendered)
          const Positioned(
            bottom: -2,
            right: -2,
            child: CircleAvatar(
              radius: 7,
              backgroundColor: Colors.redAccent,
              child: Icon(
                Icons.close_rounded,
                size: 9,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );

    final Widget podCard = AnimatedContainer(
      clipBehavior: Clip.none,
      duration: const Duration(milliseconds: 240),
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(isCompact ? 14 : 16),
        border: Border.all(
          color: isCurrentTurn
              ? playerTint
              : playerTint.withValues(alpha: 0.42),
          width: isCurrentTurn ? 2.2 : 1.2,
        ),
        boxShadow: [
          if (isCurrentTurn)
            BoxShadow(
              color: playerTint.withValues(alpha: 0.50),
              blurRadius: 14,
              spreadRadius: 1,
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: isRightAligned
            ? [
                personWidget,
                SizedBox(width: innerSpacing),
                diceWidget,
              ]
            : [
                diceWidget,
                SizedBox(width: innerSpacing),
                personWidget,
              ],
      ),
    );

    final bool showTurnArrow =
        isCurrentTurn && !state.isGameOver && state.phase == TurnPhase.waitingForRoll;
    final arrowSize = (effectiveDiceSize * 0.48).clamp(20.0, 28.0);

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: isRightAligned ? Alignment.centerRight : Alignment.centerLeft,
      child: Semantics(
        label: player.name,
        child: Opacity(
          opacity: player.isSurrendered ? 0.45 : 1.0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: isRightAligned
                ? [
                    if (showTurnArrow) ...[
                      _TurnPointerArrow(
                        pointRight: true,
                        color: playerTint,
                        size: arrowSize,
                      ),
                      const SizedBox(width: 4),
                    ],
                    podCard,
                  ]
                : [
                    podCard,
                    if (showTurnArrow) ...[
                      const SizedBox(width: 4),
                      _TurnPointerArrow(
                        pointRight: false,
                        color: playerTint,
                        size: arrowSize,
                      ),
                    ],
                  ],
          ),
        ),
      ),
    );
  }
}

/// Animated pointer arrow oscillating smoothly toward the active player's dice.
class _TurnPointerArrow extends StatefulWidget {
  final bool pointRight;
  final Color color;
  final double size;

  const _TurnPointerArrow({
    required this.pointRight,
    required this.color,
    required this.size,
  });

  @override
  State<_TurnPointerArrow> createState() => _TurnPointerArrowState();
}

class _TurnPointerArrowState extends State<_TurnPointerArrow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..repeat(reverse: true);
    _slideAnim = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnim,
      builder: (context, child) {
        final dx = widget.pointRight ? _slideAnim.value : -_slideAnim.value;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: child,
        );
      },
      child: Icon(
        widget.pointRight
            ? Icons.keyboard_double_arrow_right_rounded
            : Icons.keyboard_double_arrow_left_rounded,
        color: const Color(0xFFFFD700),
        size: widget.size,
        shadows: [
          Shadow(
            color: widget.color.withValues(alpha: 0.9),
            blurRadius: 10,
          ),
          const Shadow(
            color: Colors.black87,
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}
