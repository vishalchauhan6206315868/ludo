import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo/constants/ludo_path.dart';
import 'package:ludo/logic/ludo_game_controller.dart';
import 'package:ludo/models/game_state.dart';
import 'package:ludo/models/ludo_player.dart';
import 'package:ludo/services/sound_haptic_service.dart';
import 'package:ludo/widgets/celebration/passed_celebration_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LudoGameController.isFastBotForTesting = true;
    SoundHapticService.resetDebounce();
    SoundHapticService.soundEnabled = true;
    SoundHapticService.vibrationEnabled = true;
  });

  group('Home Goal Passed Celebration & Sound Tests', () {
    test('Token reaching Home triggers PassedCelebrationData and bonus turn', () async {
      final controller = LudoGameController();
      controller.initGame(GameMode.twoPlayer);

      final p1 = controller.state.players[0];
      final token = p1.tokens.first;

      // Position token 2 steps away from Home (step 54)
      token.step = 54;
      controller.state.phase = TurnPhase.waitingForMove;
      controller.state.currentDiceValue = 2;

      // Move token to Home (step 56)
      final moveFuture = controller.moveToken(token, autoAdvanceTurn: true);

      // In fast bot mode, check that moveResult reaches Home and awards extraTurn
      final result = await moveFuture;
      expect(result.reachedHome, isTrue);
      expect(result.extraTurn, isTrue);
      expect(token.hasReachedGoal, isTrue);
      expect(controller.state.statusMessage, contains("Bonus turn for"));
      expect(controller.state.currentPlayerIndex, equals(0)); // Retains turn for bonus roll
    });

    test('SoundHapticService onHomeGoal executes safely with sound and vibration toggles', () {
      expect(() => SoundHapticService.onHomeGoal(), returnsNormally);

      // Sound disabled
      SoundHapticService.soundEnabled = false;
      SoundHapticService.resetDebounce();
      expect(() => SoundHapticService.onHomeGoal(), returnsNormally);

      // Vibration disabled
      SoundHapticService.vibrationEnabled = false;
      SoundHapticService.resetDebounce();
      expect(() => SoundHapticService.onHomeGoal(), returnsNormally);
    });

    testWidgets('PassedCelebrationOverlay renders card-free wave & firework celebration', (tester) async {
      final player = LudoPlayer(color: PlayerColor.red, name: "Player 1 (Red)");
      final token = player.tokens.first;
      token.step = 56;

      final celebration = PassedCelebrationData(
        token: token,
        player: player,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PassedCelebrationOverlay(
                celebration: celebration,
                cellSize: 24.0,
                boardSize: 360.0,
              ),
            ),
          ),
        ),
      );

      // Mid-animation frame: renders pure visual CustomPaint with no blocking center card
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.descendant(
          of: find.byType(PassedCelebrationOverlay),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
      expect(find.text("PASSED!"), findsNothing);
      expect(find.text("+1 BONUS ROLL 🎲"), findsNothing);

      // Advance through animation to completion
      await tester.pump(const Duration(milliseconds: 1200));
    });
  });
}
