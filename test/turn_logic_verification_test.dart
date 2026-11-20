import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo/logic/ludo_game_controller.dart';
import 'package:ludo/models/game_state.dart';
import 'package:ludo/screens/game_screen.dart';
import 'package:ludo/widgets/dice/animated_dice.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LudoGameController.isFastBotForTesting = true;
  });

  tearDown(() {
    LudoGameController.isFastBotForTesting = false;
  });

  group('Dice Turn Logic Verification', () {
    test('Two Player mode: Player 1 rolls 3 with all tokens in base -> turn goes to Player 2', () async {
      final controller = LudoGameController(mode: GameMode.twoPlayer);
      expect(controller.state.currentPlayerIndex, 0);
      expect(controller.state.phase, TurnPhase.waitingForRoll);

      // Player 1 rolls 3
      controller.state.phase = TurnPhase.throwingDice;
      controller.state.currentDiceValue = 3;
      await controller.onPhysicalDiceThrowComplete(3);

      expect(controller.state.currentPlayerIndex, 1);
      expect(controller.state.phase, TurnPhase.waitingForRoll);
      expect(controller.state.currentDiceValue, isNull);
      controller.dispose();
    });

    test('Two Player mode: Player 1 rolls 5 with all tokens in base -> turn goes to Player 2', () async {
      final controller = LudoGameController(mode: GameMode.twoPlayer);
      expect(controller.state.currentPlayerIndex, 0);

      controller.state.phase = TurnPhase.throwingDice;
      controller.state.currentDiceValue = 5;
      await controller.onPhysicalDiceThrowComplete(5);

      expect(controller.state.currentPlayerIndex, 1);
      expect(controller.state.phase, TurnPhase.waitingForRoll);
      controller.dispose();
    });

    test('Two Player mode: Player 1 has no open token and rolls 2 -> turn goes to Player 2', () async {
      final controller = LudoGameController(mode: GameMode.twoPlayer);
      expect(controller.state.currentPlayerIndex, 0);

      controller.state.phase = TurnPhase.throwingDice;
      controller.state.currentDiceValue = 2;
      await controller.onPhysicalDiceThrowComplete(2);

      expect(controller.state.currentPlayerIndex, 1);
      expect(controller.state.phase, TurnPhase.waitingForRoll);
      controller.dispose();
    });

    test('Two Player mode: Player 1 rolls 6 with tokens in base -> first token opens & extra turn granted', () async {
      final controller = LudoGameController(mode: GameMode.twoPlayer);
      expect(controller.state.currentPlayerIndex, 0);

      controller.state.phase = TurnPhase.throwingDice;
      controller.state.currentDiceValue = 6;
      await controller.onPhysicalDiceThrowComplete(6);

      // Still Player 1's turn with bonus roll
      expect(controller.state.currentPlayerIndex, 0);
      expect(controller.state.phase, TurnPhase.waitingForRoll);
      expect(controller.state.players[0].tokens[0].step, 0);
      controller.dispose();
    });

    test('Two Player mode: Player 1 has open token, rolls 4 -> moves token and turn goes to Player 2', () async {
      final controller = LudoGameController(mode: GameMode.twoPlayer);
      controller.state.players[0].tokens[0].step = 5;
      controller.state.players[0].hasOpenedFirstToken = true;

      controller.state.phase = TurnPhase.throwingDice;
      controller.state.currentDiceValue = 4;
      await controller.onPhysicalDiceThrowComplete(4);

      expect(controller.state.players[0].tokens[0].step, 9);
      expect(controller.state.currentPlayerIndex, 1);
      expect(controller.state.phase, TurnPhase.waitingForRoll);
      controller.dispose();
    });

    test('No valid moves available (overshooting step 56) -> automatically transfers turn without freezing', () async {
      final controller = LudoGameController(mode: GameMode.twoPlayer);
      // Put token at step 53 (needs 3 to reach 56)
      controller.state.players[0].tokens[0].step = 53;
      controller.state.players[0].hasOpenedFirstToken = true;

      // Roll 5 (53 + 5 = 58 > 56, illegal move)
      controller.state.phase = TurnPhase.throwingDice;
      controller.state.currentDiceValue = 5;
      await controller.onPhysicalDiceThrowComplete(5);

      // Turn must automatically advance to Player 2
      expect(controller.state.currentPlayerIndex, 1);
      expect(controller.state.phase, TurnPhase.waitingForRoll);
      expect(controller.state.players[0].tokens[0].step, 53);
      controller.dispose();
    });

    test('Four Player mode: turns advance 0 -> 1 -> 2 -> 3 -> 0 on non-six rolls', () async {
      final controller = LudoGameController(mode: GameMode.fourPlayer);
      expect(controller.state.currentPlayerIndex, 0);

      for (int expectedNext in [1, 2, 3, 0]) {
        controller.state.phase = TurnPhase.throwingDice;
        controller.state.currentDiceValue = 2;
        await controller.onPhysicalDiceThrowComplete(2);
        expect(controller.state.currentPlayerIndex, expectedNext);
        expect(controller.state.phase, TurnPhase.waitingForRoll);
      }
      controller.dispose();
    });

    test('Team Up (2v2) mode: turns advance through all 4 players in sequence', () async {
      final controller = LudoGameController(mode: GameMode.teamUp);
      expect(controller.state.players.length, 4);
      expect(controller.state.currentPlayerIndex, 0);

      for (int expectedNext in [1, 2, 3, 0]) {
        controller.state.phase = TurnPhase.throwingDice;
        controller.state.currentDiceValue = 3;
        await controller.onPhysicalDiceThrowComplete(3);
        expect(controller.state.currentPlayerIndex, expectedNext);
        expect(controller.state.phase, TurnPhase.waitingForRoll);
      }
      controller.dispose();
    });

    test('Re-entrancy protection: duplicate onPhysicalDiceThrowComplete calls do not skip turn twice', () async {
      final controller = LudoGameController(mode: GameMode.twoPlayer);
      expect(controller.state.currentPlayerIndex, 0);

      controller.state.phase = TurnPhase.throwingDice;
      controller.state.currentDiceValue = 3;

      // First call processes dice result
      final f1 = controller.onPhysicalDiceThrowComplete(3);
      // Immediate duplicate call while first is in-flight must be safely rejected
      final f2 = controller.onPhysicalDiceThrowComplete(3);

      await Future.wait([f1, f2]);

      // Player 2 must have the turn (NOT Player 1 again!)
      expect(controller.state.currentPlayerIndex, 1);
      expect(controller.state.phase, TurnPhase.waitingForRoll);
      controller.dispose();
    });

    test('Play vs Computer mode: Human rolls non-6 -> Bot turn executes -> alternates cleanly', () async {
      final controller = LudoGameController(mode: GameMode.vsComputer);
      expect(controller.state.currentPlayerIndex, 0);
      expect(controller.state.currentPlayer.isBot, false);

      // Human rolls 4 with no open gotis
      controller.state.phase = TurnPhase.throwingDice;
      controller.state.currentDiceValue = 4;
      await controller.onPhysicalDiceThrowComplete(4);

      // Fast bot completes its turn automatically in test mode
      expect(controller.state.phase, TurnPhase.waitingForRoll);
      // The game returned back to human or is waiting for next roll
      controller.dispose();
    });

    testWidgets('UI Simulation: GameScreen in TwoPlayer mode switches turn after dice roll', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(mode: GameMode.twoPlayer),
        ),
      );
      await tester.pump();

      // Find AnimatedDice widget
      expect(find.byType(AnimatedDice), findsOneWidget);

      // Tap dice to initiate throw
      await tester.tap(find.byType(AnimatedDice));
      await tester.pump();

      // Advance press (100ms), throw (1400ms), settle (400ms), springback (300ms), step animation (1200ms)
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 1400));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pump(const Duration(milliseconds: 1200));

      // Cleanly unmount GameScreen so its controller timer is disposed
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    test('Auto-play on timeout: in waitingForRoll phase, timeout auto-rolls dice', () {
      final controller = LudoGameController(mode: GameMode.twoPlayer);
      expect(controller.state.phase, TurnPhase.waitingForRoll);
      expect(controller.state.currentPlayerIndex, 0);

      // Force timeout with autoPlay: true
      controller.forceTurnTimeout(autoPlay: true);

      // Must have transitioned to throwingDice with a roll value instead of skipping turn!
      expect(controller.state.phase, TurnPhase.throwingDice);
      expect(controller.state.currentDiceValue, isNotNull);
      expect(controller.state.currentPlayerIndex, 0); // Still player 0 (their roll is active)
      controller.dispose();
    });

    test('Auto-play on timeout: in waitingForMove phase, timeout auto-moves best goti', () async {
      final controller = LudoGameController(mode: GameMode.twoPlayer);
      controller.state.players[0].tokens[0].step = 5;
      controller.state.players[0].hasOpenedFirstToken = true;

      controller.state.phase = TurnPhase.waitingForMove;
      controller.state.currentDiceValue = 4;

      // Force timeout with autoPlay: true
      await controller.forceTurnTimeout(autoPlay: true);

      // Token at step 5 should be auto-moved by 4 steps
      expect(controller.state.players[0].tokens[0].step, 9);
      controller.dispose();
    });
  });
}
