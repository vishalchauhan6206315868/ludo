import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo/constants/ludo_path.dart';
import 'package:ludo/logic/ludo_game_controller.dart';
import 'package:ludo/models/game_state.dart';
import 'package:ludo/models/ludo_player.dart';
import 'package:ludo/screens/game_screen.dart';
import 'package:ludo/widgets/pass_n_play_handoff_overlay.dart';
import 'package:ludo/widgets/pass_n_play_setup_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LudoGameController.isFastBotForTesting = true;
  });

  group('Pass N Play Controller & Rules Tests', () {
    test('Pass N Play with 2 players has 2 human players with Red and Yellow', () {
      final controller = LudoGameController(
        mode: GameMode.passNPlay,
        passNPlayPlayerCount: 2,
      );

      expect(controller.state.players.length, 2);
      expect(controller.state.players[0].color, PlayerColor.red);
      expect(controller.state.players[0].isBot, false);
      expect(controller.state.players[0].name, "Player 1");

      expect(controller.state.players[1].color, PlayerColor.yellow);
      expect(controller.state.players[1].isBot, false);
      expect(controller.state.players[1].name, "Player 2");

      expect(controller.state.phase, TurnPhase.waitingForRoll);
      expect(controller.turnSecondsRemaining, LudoGameController.maxTurnSeconds);
      controller.dispose();
    });

    test('Pass N Play with 3 players has 3 human players with Red, Green, Yellow', () {
      final controller = LudoGameController(
        mode: GameMode.passNPlay,
        passNPlayPlayerCount: 3,
      );

      expect(controller.state.players.length, 3);
      expect(controller.state.players[0].color, PlayerColor.red);
      expect(controller.state.players[0].isBot, false);
      expect(controller.state.players[1].color, PlayerColor.green);
      expect(controller.state.players[1].isBot, false);
      expect(controller.state.players[2].color, PlayerColor.yellow);
      expect(controller.state.players[2].isBot, false);
      controller.dispose();
    });

    test('Pass N Play with 4 players has 4 human players with Red, Green, Yellow, Blue', () {
      final controller = LudoGameController(
        mode: GameMode.passNPlay,
        passNPlayPlayerCount: 4,
      );

      expect(controller.state.players.length, 4);
      expect(controller.state.players[0].color, PlayerColor.red);
      expect(controller.state.players[1].color, PlayerColor.green);
      expect(controller.state.players[2].color, PlayerColor.yellow);
      expect(controller.state.players[3].color, PlayerColor.blue);
      for (final p in controller.state.players) {
        expect(p.isBot, false);
      }
      controller.dispose();
    });

    test('Pass N Play respects configured custom player names', () {
      final controller = LudoGameController(
        mode: GameMode.passNPlay,
        customPlayerNames: ["Alice", "Bob", "Charlie"],
      );

      expect(controller.state.players.length, 3);
      expect(controller.state.players[0].name, "Alice");
      expect(controller.state.players[1].name, "Bob");
      expect(controller.state.players[2].name, "Charlie");
      controller.dispose();
    });

    test('Turn flow for 2 players (P1 -> P2 -> P1) switches automatically without handoff', () {
      final controller = LudoGameController(
        mode: GameMode.passNPlay,
        passNPlayPlayerCount: 2,
      );

      expect(controller.state.currentPlayerIndex, 0);
      expect(controller.state.phase, TurnPhase.waitingForRoll);

      // Player 1 turn ends on timeout -> automatically switches to Player 2
      controller.forceTurnTimeout();
      expect(controller.state.currentPlayerIndex, 1);
      expect(controller.state.phase, TurnPhase.waitingForRoll);
      expect(controller.isTimerPaused, false);
      expect(controller.state.statusMessage, contains("Player 2's turn"));

      // Player 2 turn ends on timeout -> automatically switches back to Player 1
      controller.forceTurnTimeout();
      expect(controller.state.currentPlayerIndex, 0);
      expect(controller.state.phase, TurnPhase.waitingForRoll);
      expect(controller.isTimerPaused, false);
      expect(controller.state.statusMessage, contains("Player 1's turn"));

      controller.dispose();
    });

    test('Turn flow for 3 players (P1 -> P2 -> P3 -> P1) switches automatically without handoff', () {
      final controller = LudoGameController(
        mode: GameMode.passNPlay,
        passNPlayPlayerCount: 3,
      );

      expect(controller.state.currentPlayerIndex, 0);
      expect(controller.state.phase, TurnPhase.waitingForRoll);

      // P1 -> P2
      controller.forceTurnTimeout();
      expect(controller.state.currentPlayerIndex, 1);
      expect(controller.state.phase, TurnPhase.waitingForRoll);
      expect(controller.isTimerPaused, false);

      // P2 -> P3
      controller.forceTurnTimeout();
      expect(controller.state.currentPlayerIndex, 2);
      expect(controller.state.phase, TurnPhase.waitingForRoll);
      expect(controller.isTimerPaused, false);

      // P3 -> P1
      controller.forceTurnTimeout();
      expect(controller.state.currentPlayerIndex, 0);
      expect(controller.state.phase, TurnPhase.waitingForRoll);
      expect(controller.isTimerPaused, false);

      controller.dispose();
    });

    test('Turn flow for 4 players (P1 -> P2 -> P3 -> P4 -> P1) switches automatically without handoff', () {
      final controller = LudoGameController(
        mode: GameMode.passNPlay,
        passNPlayPlayerCount: 4,
      );

      // P1 -> P2
      controller.forceTurnTimeout();
      expect(controller.state.currentPlayerIndex, 1);
      expect(controller.state.phase, TurnPhase.waitingForRoll);
      expect(controller.isTimerPaused, false);

      // P2 -> P3
      controller.forceTurnTimeout();
      expect(controller.state.currentPlayerIndex, 2);
      expect(controller.state.phase, TurnPhase.waitingForRoll);
      expect(controller.isTimerPaused, false);

      // P3 -> P4
      controller.forceTurnTimeout();
      expect(controller.state.currentPlayerIndex, 3);
      expect(controller.state.phase, TurnPhase.waitingForRoll);
      expect(controller.isTimerPaused, false);

      // P4 -> P1
      controller.forceTurnTimeout();
      expect(controller.state.currentPlayerIndex, 0);
      expect(controller.state.phase, TurnPhase.waitingForRoll);
      expect(controller.isTimerPaused, false);

      controller.dispose();
    });

    test('Extra turn after rolling 6 keeps current player active without handoff', () async {
      final controller = LudoGameController(
        mode: GameMode.passNPlay,
        passNPlayPlayerCount: 2,
      );

      // Move goti out of base first so player is playing
      final p1 = controller.state.players[0];
      p1.hasOpenedFirstToken = true;
      p1.tokens[0].step = 10;

      // Player rolls 6
      controller.state.phase = TurnPhase.waitingForMove;
      controller.state.currentDiceValue = 6;
      final result = await controller.moveToken(p1.tokens[0]);

      expect(result.extraTurn, true);
      // Still Player 1
      expect(controller.state.currentPlayerIndex, 0);
      // Ready to roll bonus turn without handoff screen
      expect(controller.state.phase, TurnPhase.waitingForRoll);
      controller.dispose();
    });

    test('Capture extra turn keeps current player active without handoff', () async {
      final controller = LudoGameController(
        mode: GameMode.passNPlay,
        passNPlayPlayerCount: 2,
      );

      final p1 = controller.state.players[0]; // Red
      final p2 = controller.state.players[1]; // Yellow

      p1.hasOpenedFirstToken = true;
      p2.hasOpenedFirstToken = true;

      // Yellow on non-safe coordinate commonTrack[10] (step 36 from Yellow start 26)
      p2.tokens[0].step = 36;
      final targetCoord = p2.tokens[0].coordinate;
      expect(LudoPath.isSafeCoord(targetCoord), false);

      // Place Red 3 steps behind Yellow (commonTrack[7])
      p1.tokens[0].step = 7;
      controller.state.phase = TurnPhase.waitingForMove;
      controller.state.currentDiceValue = 3;

      final result = await controller.moveToken(p1.tokens[0]);
      expect(result.captured, true);
      expect(result.extraTurn, true);
      expect(p2.tokens[0].isInBase, true);

      // Same player active with bonus roll
      expect(controller.state.currentPlayerIndex, 0);
      expect(controller.state.phase, TurnPhase.waitingForRoll);
      controller.dispose();
    });

    test('Normal token move completion advances turn to next player immediately without handoff', () async {
      final controller = LudoGameController(
        mode: GameMode.passNPlay,
        passNPlayPlayerCount: 2,
      );

      final p1 = controller.state.players[0];
      p1.hasOpenedFirstToken = true;
      p1.tokens[0].step = 10;

      // Player rolls 2 (not 6, no extra turn)
      controller.state.phase = TurnPhase.waitingForMove;
      controller.state.currentDiceValue = 2;
      final result = await controller.moveToken(p1.tokens[0]);

      expect(result.extraTurn, false);
      expect(controller.state.currentPlayerIndex, 1);
      expect(controller.state.phase, TurnPhase.waitingForRoll);
      expect(controller.isTimerPaused, false);
      controller.dispose();
    });

    test('No legal move automatically advances turn to next player immediately without handoff', () async {
      final controller = LudoGameController(
        mode: GameMode.passNPlay,
        passNPlayPlayerCount: 2,
      );

      // All gotis in base, roll is 3 (not 6) -> no legal moves
      controller.state.phase = TurnPhase.waitingForRoll;
      await controller.onPhysicalDiceThrowComplete(3);

      // Turn automatically passed to Player 2 immediately without handoff
      expect(controller.state.currentPlayerIndex, 1);
      expect(controller.state.phase, TurnPhase.waitingForRoll);
      expect(controller.isTimerPaused, false);
      controller.dispose();
    });

    test('Legacy onPlayerReady is safely handled if waitingForPlayerHandoff phase occurs', () {
      final controller = LudoGameController(
        mode: GameMode.passNPlay,
        passNPlayPlayerCount: 2,
        initialState: GameState(
          players: [
            LudoPlayer(color: PlayerColor.red, name: "P1", isBot: false),
            LudoPlayer(color: PlayerColor.yellow, name: "P2", isBot: false),
          ],
          mode: GameMode.passNPlay,
          currentPlayerIndex: 1,
          phase: TurnPhase.waitingForPlayerHandoff,
        ),
      );

      // Initial state with waitingForPlayerHandoff auto-normalizes to waitingForRoll
      expect(controller.state.phase, TurnPhase.waitingForRoll);
      expect(controller.isTimerPaused, false);

      // onPlayerReady is safely callable without error
      controller.onPlayerReady();
      expect(controller.state.phase, TurnPhase.waitingForRoll);
      controller.dispose();
    });
  });

  group('Pass N Play Setup Dialog Widget Tests', () {
    testWidgets('PassNPlaySetupDialog allows selecting 2P, 3P, 4P and custom names',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      PassNPlayConfig? resultConfig;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                resultConfig = await showDialog<PassNPlayConfig>(
                  context: context,
                  builder: (_) => const PassNPlaySetupDialog(),
                );
              },
              child: const Text('Open Setup'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Setup'));
      await tester.pumpAndSettle();

      expect(find.text('PASS N PLAY SETUP'), findsOneWidget);
      expect(find.text('2 Players'), findsOneWidget);
      expect(find.text('3 Players'), findsOneWidget);
      expect(find.text('4 Players'), findsOneWidget);

      // Switch to 3 Players
      await tester.tap(find.byKey(const Key('option_3p')));
      await tester.pumpAndSettle();

      // Enter custom name for Player 1
      await tester.enterText(
          find.byKey(const Key('player_name_input_0')), 'Captain America');
      await tester.pumpAndSettle();

      // Start Pass N Play
      await tester.tap(find.byKey(const Key('start_pass_n_play_button')));
      await tester.pumpAndSettle();

      expect(resultConfig, isNotNull);
      expect(resultConfig!.playerCount, 3);
      expect(resultConfig!.playerNames[0], 'Captain America');
      expect(resultConfig!.playerNames[1], 'Player 2');
      expect(resultConfig!.playerNames[2], 'Player 3');
    });
  });

  group('Pass N Play GameScreen & Handoff Overlay Widget Tests', () {
    testWidgets('GameScreen does not show PassNPlayHandoffOverlay and handles exit dialog cleanly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(
            mode: GameMode.passNPlay,
            passNPlayPlayerCount: 2,
            customPlayerNames: ["Alice", "Bob"],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Pass & Play (2 Players)'), findsOneWidget);
      expect(find.bySemanticsLabel('Alice'), findsOneWidget);
      expect(find.bySemanticsLabel('Bob'), findsOneWidget);

      // Initially no handoff overlay
      expect(find.byType(PassNPlayHandoffOverlay), findsNothing);

      // Trigger timeout to move into handoff
      final dynamic state = tester.state(find.byType(GameScreen));
      state.widget;
      // Access controller via timeout test:
      // Tap rules or use back button to verify dialog:
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify requirement 30: "Exit Game?" with "CANCEL" and "EXIT"
      expect(find.text('Exit Game?'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);
      expect(find.text('EXIT'), findsOneWidget);

      // Cancel exit
      await tester.tap(find.text('CANCEL'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Exit Game?'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('Handoff overlay displays next player and I\'M READY button starts turn',
        (WidgetTester tester) async {
      bool readyTapped = false;
      final player = LudoPlayer(
        color: PlayerColor.yellow,
        name: "Player 2",
        isBot: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const Center(child: Text("Board Content")),
                PassNPlayHandoffOverlay(
                  nextPlayer: player,
                  onReady: () {
                    readyTapped = true;
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PASS THE DEVICE'), findsOneWidget);
      expect(find.text('Pass the device to'), findsOneWidget);
      expect(find.text('PLAYER 2'), findsOneWidget);
      expect(find.text("I'M READY"), findsOneWidget);

      await tester.tap(find.byKey(const Key('pass_n_play_ready_button')));
      await tester.pumpAndSettle();

      expect(readyTapped, true);
    });
  });
}
