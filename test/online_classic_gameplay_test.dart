import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo/constants/ludo_path.dart';
import 'package:ludo/logic/ludo_game_controller.dart';
import 'package:ludo/models/game_state.dart';
import 'package:ludo/models/online_game_mode.dart';
import 'package:ludo/widgets/dice/animated_dice.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Online Classic Gameplay & Optimistic 3D Dice Tests', () {
    test('DiceThrowPhysics withTargetValue correctly reorients rotation to new face', () {
      final initialPhysics = DiceThrowPhysics.create(
        isTopPlayer: false,
        boardSize: const Size(360, 360),
        targetValue: 1,
      );

      for (int face = 1; face <= 6; face++) {
        final reoriented = initialPhysics.withTargetValue(face);
        final (expectedBaseX, expectedBaseY) =
            DiceThrowPhysics.getBaseOrientationForValue(face);

        // Remainder modulo 2*pi must match expectedBaseX and expectedBaseY
        final rotXMod = (reoriented.totalRotX - expectedBaseX) / (2.0 * pi);
        final rotYMod = (reoriented.totalRotY - expectedBaseY) / (2.0 * pi);

        expect((rotXMod - rotXMod.round()).abs(), lessThan(1e-5),
            reason: 'Face $face rotX must complete integer revolutions to base orientation');
        expect((rotYMod - rotYMod.round()).abs(), lessThan(1e-5),
            reason: 'Face $face rotY must complete integer revolutions to base orientation');
      }
    });

    test('Tokens in base require a 6 to open and reject non-6', () {
      final controller = LudoGameController(mode: GameMode.twoPlayer);
      final redPlayer = controller.state.players.firstWhere((p) => p.color == PlayerColor.red);

      // All 4 tokens in base
      expect(redPlayer.tokens.every((t) => t.isInBase), isTrue);

      // Rolling 1 to 5 gives NO movable tokens
      for (int roll = 1; roll <= 5; roll++) {
        expect(redPlayer.getMovableTokens(roll), isEmpty,
            reason: 'Roll $roll must not allow moving tokens out of base');
      }

      // Rolling 6 gives all 4 base tokens as movable
      final movableOnSix = redPlayer.getMovableTokens(6);
      expect(movableOnSix.length, equals(4),
          reason: 'Roll 6 must allow opening all 4 tokens from base');
      controller.dispose();
    });

    test('Online match controller handles no legal moves by transitioning turn without freezing', () async {
      final controller = LudoGameController(
        mode: GameMode.twoPlayer,
        isOnlineMatch: true,
        onlineModeType: OnlineModeType.classic,
        mySeatIndex: 0,
      );

      // Player 0 (Red) turn, all tokens in base, rolled a 3
      expect(controller.state.players[0].tokens.every((t) => t.isInBase), isTrue);

      // Simulate dice throw settle with non-6 roll
      await controller.onPhysicalDiceThrowComplete(3);

      expect(controller.state.phase, equals(TurnPhase.waitingForRoll));
      controller.dispose();
    });
  });
}
