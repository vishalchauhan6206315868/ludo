import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo/constants/ludo_path.dart';
import 'package:ludo/logic/ludo_game_controller.dart';
import 'package:ludo/models/game_state.dart';
import 'package:ludo/models/online_game_mode.dart';
import 'package:ludo/services/auth_service.dart';
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

    test('Player 2 (Joined Player, isHost: false) initializes with mySeatIndex 1 (Green)', () {
      final p2Controller = LudoGameController(
        mode: GameMode.twoPlayer,
        isOnlineMatch: true,
        isHost: false,
        mySeatIndex: 1,
      );

      expect(p2Controller.mySeatIndex, equals(1));
      expect(p2Controller.state.players[1].color, equals(PlayerColor.green));
      expect(p2Controller.state.players[1].name, contains('(Green)'));

      // Initially Player 0 (Host, Red) has the turn:
      p2Controller.state.currentPlayerIndex = 0;
      expect(p2Controller.isMyTurn, isFalse, reason: 'Joined player should not have turn when Player 0 is active');

      // When turn switches to Player 1 (Joined player, Green):
      p2Controller.state.currentPlayerIndex = 1;
      expect(p2Controller.isMyTurn, isTrue, reason: 'Joined player should have turn when Player 1 is active');

      p2Controller.dispose();
    });

    test('Joined player with initial seat 0 is automatically corrected to seat 1', () {
      final p2Controller = LudoGameController(
        mode: GameMode.twoPlayer,
        isOnlineMatch: true,
        isHost: false,
        mySeatIndex: 0, // erroneously passed 0
      );

      // Must be corrected to seat 1 because isHost is false
      expect(p2Controller.mySeatIndex, equals(1));
      p2Controller.dispose();
    });

    test('AuthService.getUserIdFromJwt correctly decodes MongoDB User ID from JWT', () {
      // Sample JWT with payload {"id":"67448cf18899aabbccddeeff","role":"user"}
      // Header: {"alg":"HS256","typ":"JWT"} -> eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9
      // Payload: eyJpZCI6IjY3NDQ4Y2YxODg5OWFhYmJjY2RkZWVmZiIsInJvbGUiOiJ1c2VyIn0
      const testToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY3NDQ4Y2YxODg5OWFhYmJjY2RkZWVmZiIsInJvbGUiOiJ1c2VyIn0.signature';
      final decodedId = AuthService.getUserIdFromJwt(testToken);
      expect(decodedId, equals('67448cf18899aabbccddeeff'));
    });
  });
}
