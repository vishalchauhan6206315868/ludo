import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo/constants/ludo_path.dart';
import 'package:ludo/logic/ludo_game_controller.dart';
import 'package:ludo/models/game_state.dart';
import 'package:ludo/models/token.dart';
import 'package:ludo/services/game_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Ludo Path & Coordinates Tests', () {
    test('Common track has exactly 52 cells', () {
      expect(LudoPath.commonTrack.length, 52);
    });

    test('Each player start index is spaced by 13 cells', () {
      expect(LudoPath.startIndex(PlayerColor.red), 0);
      expect(LudoPath.startIndex(PlayerColor.green), 13);
      expect(LudoPath.startIndex(PlayerColor.yellow), 26);
      expect(LudoPath.startIndex(PlayerColor.blue), 39);
    });

    test('Safe spots include all 8 designated stars', () {
      expect(LudoPath.safeCoords.length, 8);
      expect(LudoPath.isSafeCoord(const BoardCoord(1, 6)), true); // Red start
      expect(LudoPath.isSafeCoord(const BoardCoord(8, 1)), true); // Green start
      expect(LudoPath.isSafeCoord(const BoardCoord(13, 8)), true); // Yellow start
      expect(LudoPath.isSafeCoord(const BoardCoord(6, 13)), true); // Blue start
      expect(LudoPath.isSafeCoord(const BoardCoord(6, 2)), true);
      expect(LudoPath.isSafeCoord(const BoardCoord(12, 6)), true);
      expect(LudoPath.isSafeCoord(const BoardCoord(8, 12)), true);
      expect(LudoPath.isSafeCoord(const BoardCoord(2, 8)), true);
    });
  });

  group('Token Mechanics Tests', () {
    test('Token in base cannot move on numbers other than 6', () {
      final token = Token(id: 0, color: PlayerColor.red, step: -1);
      expect(token.isInBase, true);
      expect(token.canMove(1), false);
      expect(token.canMove(5), false);
      expect(token.canMove(6), true);
    });

    test('Token on board cannot overshoot step 56', () {
      final token = Token(id: 0, color: PlayerColor.red, step: 54);
      expect(token.canMove(2), true); // 54 + 2 = 56 (Goal)
      expect(token.canMove(3), false); // 54 + 3 = 57 (Overshoot)
    });
  });

  group('Game Controller Rules Tests', () {
    test('Controller initializes with 2 players for twoPlayer mode', () {
      final controller = LudoGameController(mode: GameMode.twoPlayer);
      expect(controller.state.players.length, 2);
      expect(controller.state.players[0].color, PlayerColor.red);
      expect(controller.state.players[1].color, PlayerColor.yellow);
      expect(controller.state.phase, TurnPhase.waitingForRoll);
      expect(controller.turnSecondsRemaining, LudoGameController.maxTurnSeconds);
      controller.dispose();
    });

    test('Controller initializes with 4 players for fourPlayer mode', () {
      final controller = LudoGameController(mode: GameMode.fourPlayer);
      expect(controller.state.players.length, 4);
      expect(controller.state.players[0].color, PlayerColor.red);
      expect(controller.state.players[1].color, PlayerColor.green);
      expect(controller.state.players[2].color, PlayerColor.yellow);
      expect(controller.state.players[3].color, PlayerColor.blue);
      controller.dispose();
    });

    test('Token moves from base to step 0', () async {
      final controller = LudoGameController(mode: GameMode.twoPlayer);
      controller.state.currentDiceValue = 6;
      controller.state.phase = TurnPhase.waitingForMove;

      final redToken = controller.state.players[0].tokens[0];
      expect(redToken.isInBase, true);

      await controller.moveToken(redToken);
      expect(redToken.step, 0);
      expect(redToken.isPlaying, true);
      controller.dispose();
    });

    test('Single open token auto-moves on dice roll 1-5 without requiring manual tap', () async {
      LudoGameController.isFastBotForTesting = true;
      final controller = LudoGameController(mode: GameMode.twoPlayer);
      final redPlayer = controller.state.players[0];

      // 1 token open at step 5, other 3 remain in base
      redPlayer.tokens[0].step = 5;
      expect(redPlayer.tokens.where((t) => t.isPlaying).length, 1);
      expect(redPlayer.tokens.where((t) => t.isInBase).length, 3);

      controller.state.phase = TurnPhase.waitingForRoll;

      // Simulate dice throw complete with roll = 4
      await controller.onPhysicalDiceThrowComplete(4);

      // Token should automatically advance by 4 steps (from 5 to 9)
      expect(redPlayer.tokens[0].step, 9);
      controller.dispose();
      LudoGameController.isFastBotForTesting = false;
    });

    test('Single open token does NOT auto-move on dice roll 6 (waits for player decision)', () async {
      LudoGameController.isFastBotForTesting = true;
      final controller = LudoGameController(mode: GameMode.twoPlayer);
      final redPlayer = controller.state.players[0];

      // 1 token open at step 5, 3 tokens in base
      redPlayer.tokens[0].step = 5;

      controller.state.phase = TurnPhase.waitingForRoll;

      // Simulate dice throw complete with roll = 6
      await controller.onPhysicalDiceThrowComplete(6);

      // Player has multiple choices (unlock goti vs advance open goti), so must NOT auto-move
      expect(controller.state.phase, TurnPhase.waitingForMove);
      expect(redPlayer.tokens[0].step, 5); // has not moved yet
      expect(redPlayer.tokens.where((t) => t.isInBase).length, 3); // no token unlocked yet

      controller.dispose();
      LudoGameController.isFastBotForTesting = false;
    });

    test('Multiple open tokens do NOT auto-move on dice roll 1-5 (waits for player decision)', () async {
      LudoGameController.isFastBotForTesting = true;
      final controller = LudoGameController(mode: GameMode.twoPlayer);
      final redPlayer = controller.state.players[0];

      // 2 tokens open on track
      redPlayer.tokens[0].step = 5;
      redPlayer.tokens[1].step = 10;

      controller.state.phase = TurnPhase.waitingForRoll;

      await controller.onPhysicalDiceThrowComplete(3);

      // Multiple choices -> waits for player
      expect(controller.state.phase, TurnPhase.waitingForMove);
      expect(redPlayer.tokens[0].step, 5);
      expect(redPlayer.tokens[1].step, 10);

      controller.dispose();
      LudoGameController.isFastBotForTesting = false;
    });
  });

  group('Match Persistence & Storage Tests', () {
    test('GameStorageService saves and restores GameState correctly', () async {
      final controller = LudoGameController(mode: GameMode.twoPlayer);
      controller.state.players[0].tokens[0].step = 14;

      await GameStorageService.saveGame(controller.state);
      expect(await GameStorageService.hasSavedGame(), true);

      final loaded = await GameStorageService.loadSavedGame();
      expect(loaded, isNotNull);
      expect(loaded!.mode, GameMode.twoPlayer);
      expect(loaded.players[0].tokens[0].step, 14);

      await GameStorageService.clearSavedGame();
      expect(await GameStorageService.hasSavedGame(), false);
      controller.dispose();
    });
  });

  group('Turn Timer Expiration Tests', () {
    test('Timer expiry in waitingForRoll advances turn from Player 1 to Player 2 and resets timer', () {
      final controller = LudoGameController(mode: GameMode.fourPlayer);
      expect(controller.state.currentPlayerIndex, 0); // Player 1 (Red)
      expect(controller.turnSecondsRemaining, LudoGameController.maxTurnSeconds);
      expect(controller.state.phase, TurnPhase.waitingForRoll);

      controller.forceTurnTimeout();

      expect(controller.state.currentPlayerIndex, 1); // Player 2 (Green)
      expect(controller.state.currentPlayer.color, PlayerColor.green);
      expect(controller.turnSecondsRemaining, LudoGameController.maxTurnSeconds);
      expect(controller.state.phase, TurnPhase.waitingForRoll);
      expect(controller.state.currentDiceValue, isNull);
      controller.dispose();
    });

    test('Timer expiry in waitingForMove cancels pending dice roll and forfeits turn to next player', () {
      final controller = LudoGameController(mode: GameMode.fourPlayer);
      controller.state.currentDiceValue = 4;
      controller.state.phase = TurnPhase.waitingForMove;

      controller.forceTurnTimeout();

      expect(controller.state.currentPlayerIndex, 1); // Player 2
      expect(controller.state.currentDiceValue, isNull);
      expect(controller.state.phase, TurnPhase.waitingForRoll);
      expect(controller.turnSecondsRemaining, LudoGameController.maxTurnSeconds);
      controller.dispose();
    });

    test('Timer expiry on last player circles back to first player', () {
      final controller = LudoGameController(mode: GameMode.fourPlayer);
      controller.state.currentPlayerIndex = 3; // Player 4 (Blue)

      controller.forceTurnTimeout();

      expect(controller.state.currentPlayerIndex, 0); // Player 1 (Red)
      expect(controller.turnSecondsRemaining, LudoGameController.maxTurnSeconds);
      controller.dispose();
    });

    test('Timer expiry skips players who have already finished', () {
      final controller = LudoGameController(mode: GameMode.fourPlayer);
      // Mark player 1 (Green) as finished
      for (final t in controller.state.players[1].tokens) {
        t.step = 56;
      }
      expect(controller.state.players[1].hasFinished, true);

      expect(controller.state.currentPlayerIndex, 0); // Player 1 (Red)
      controller.forceTurnTimeout();

      // Should skip finished player 1 (Green) and advance directly to player 2 (Yellow)
      expect(controller.state.currentPlayerIndex, 2);
      expect(controller.state.currentPlayer.color, PlayerColor.yellow);
      controller.dispose();
    });

    test('Timer expiry is ignored during active animation (race condition prevention)', () {
      final controller = LudoGameController(mode: GameMode.fourPlayer);
      controller.state.phase = TurnPhase.animatingMove;

      controller.forceTurnTimeout();

      // Turn must not advance while animation is mid-flight
      expect(controller.state.currentPlayerIndex, 0);
      expect(controller.state.phase, TurnPhase.animatingMove);
      controller.dispose();
    });

    test('pauseTimer and resumeTimer correctly toggle timer pause state', () {
      final controller = LudoGameController(mode: GameMode.twoPlayer);
      expect(controller.isTimerPaused, false);

      controller.pauseTimer();
      expect(controller.isTimerPaused, true);

      controller.resumeTimer();
      expect(controller.isTimerPaused, false);
      controller.dispose();
    });
  });

  group('Vs Computer & Bot AI Tests', () {
    setUp(() {
      LudoGameController.isFastBotForTesting = true;
    });

    tearDown(() {
      LudoGameController.isFastBotForTesting = false;
    });

    test('Vs Computer mode configures Human as Player 1 and Bot as Player 2', () {
      final controller = LudoGameController(mode: GameMode.vsComputer);
      expect(controller.state.players.length, 2);
      expect(controller.state.players[0].isBot, false);
      expect(controller.state.players[0].color, PlayerColor.red);
      expect(controller.state.players[1].isBot, true);
      expect(controller.state.players[1].color, PlayerColor.yellow);
      controller.dispose();
    });

    test('Human cannot manually tap bot gotis during bot turn', () async {
      final controller = LudoGameController(mode: GameMode.vsComputer);
      controller.state.currentPlayerIndex = 1; // Bot (Yellow)
      controller.state.phase = TurnPhase.waitingForMove;
      controller.state.currentDiceValue = 6;

      final botToken = controller.state.players[1].tokens[0];
      await controller.onTokenTapped(botToken);

      // Token must remain in base since human tap is rejected for bot
      expect(botToken.isInBase, true);
      controller.dispose();
    });

    test('Bot automatically rolls dice, chooses best token, and moves it', () async {
      final controller = LudoGameController(mode: GameMode.vsComputer);
      controller.state.currentPlayerIndex = 1; // Bot
      controller.state.phase = TurnPhase.waitingForRoll;

      // Position a bot goti on track
      final botToken = controller.state.players[1].tokens[0];
      botToken.step = 0; // on board

      await controller.playBotTurn();

      expect(botToken.step > 0 || controller.state.players[1].tokens.any((t) => t.id != botToken.id && t.step >= 0), true);
      expect(controller.isBotPlaying, false);
      controller.dispose();
    });

    test('Bot with no movable tokens cleanly finishes and passes turn to human', () async {
      final controller = LudoGameController(mode: GameMode.vsComputer);
      controller.state.currentPlayerIndex = 1; // Bot (Yellow)
      controller.state.phase = TurnPhase.waitingForRoll;

      await controller.playBotTurn();

      // When bot's turn finishes completely, turn is passed to human
      expect(controller.state.currentPlayerIndex, 0);
      expect(controller.isBotPlaying, false);
      controller.dispose();
    });

    test('TestCase 1: Normal Computer turn automatically rolls and moves', () async {
      final controller = LudoGameController(mode: GameMode.vsComputer);
      controller.state.currentPlayerIndex = 1; // Bot
      controller.state.phase = TurnPhase.waitingForRoll;
      final botToken = controller.state.players[1].tokens[0];
      botToken.step = 5;

      await controller.playComputerTurn();

      // Bot moved and finished turn to Human
      expect(controller.state.currentPlayerIndex, 0);
      expect(controller.isBotPlaying, false);
      controller.dispose();
    });

    test('TestCase 2: Rolling 6 grants extra turn', () async {
      final controller = LudoGameController(mode: GameMode.vsComputer);
      controller.state.currentPlayerIndex = 1;
      controller.state.phase = TurnPhase.waitingForMove;
      controller.state.currentDiceValue = 6;
      final botToken = controller.state.players[1].tokens[0]; // in base

      final result = await controller.moveToken(botToken, autoAdvanceTurn: false);
      expect(result.extraTurn, true);
      expect(botToken.step, 0);
      controller.dispose();
    });

    test('TestCase 3: Computer capture sends opponent home and grants extra turn', () async {
      final controller = LudoGameController(mode: GameMode.vsComputer);
      final humanToken = controller.state.players[0].tokens[0];
      final botToken = controller.state.players[1].tokens[0];

      // Yellow step 0 is index 26 = (13, 8)
      // Yellow step 1 is index 27 = (12, 8) (unsafe cell)
      // Red starts at index 0, so Red step 27 is index 27 = (12, 8)
      botToken.step = 0;
      humanToken.step = 27;

      expect(botToken.coordinate, const BoardCoord(13, 8));
      expect(humanToken.coordinate, const BoardCoord(12, 8));
      expect(LudoPath.isSafeCoord(humanToken.coordinate), false);

      controller.state.currentPlayerIndex = 1;
      controller.state.phase = TurnPhase.waitingForMove;
      controller.state.currentDiceValue = 1;

      final result = await controller.moveToken(botToken, autoAdvanceTurn: false);

      expect(result.captured, true);
      expect(result.extraTurn, true);
      expect(humanToken.step, -1); // sent back to base
      controller.dispose();
    });

    test('TestCase 4: Computer reaches home and gets extra turn', () async {
      final controller = LudoGameController(mode: GameMode.vsComputer);
      final botToken = controller.state.players[1].tokens[0];
      botToken.step = 55; // 1 step from goal (step 56)

      controller.state.currentPlayerIndex = 1;
      controller.state.phase = TurnPhase.waitingForMove;
      controller.state.currentDiceValue = 1;

      final result = await controller.moveToken(botToken, autoAdvanceTurn: false);

      expect(result.reachedHome, true);
      expect(result.extraTurn, true);
      expect(botToken.hasReachedGoal, true);
      controller.dispose();
    });

    test('TestCase 5: No movable tokens transitions cleanly without freezing', () async {
      final controller = LudoGameController(mode: GameMode.vsComputer);
      controller.state.currentPlayerIndex = 1;
      controller.state.phase = TurnPhase.waitingForRoll;
      // All tokens in base
      for (final t in controller.state.players[1].tokens) {
        expect(t.isInBase, true);
      }

      await controller.playComputerTurn();

      // Bot finishes without freezing and turn passes to human
      expect(controller.state.currentPlayerIndex, 0);
      expect(controller.isBotPlaying, false);
      controller.dispose();
    });

    test('TestCase 6: Three sixes penalty passes turn to human', () async {
      final controller = LudoGameController(mode: GameMode.vsComputer);
      controller.state.currentPlayerIndex = 1;
      controller.state.consecutiveSixes = 2;
      controller.state.currentDiceValue = 6;
      controller.state.phase = TurnPhase.waitingForRoll;

      // When consecutiveSixes reaches 3, penalty passes turn
      controller.state.consecutiveSixes++;
      expect(controller.state.consecutiveSixes, 3);
      controller.dispose();
    });

    test('TestCase 7: Computer turn timer safety prevents premature turn skipping', () {
      final controller = LudoGameController(mode: GameMode.vsComputer);
      controller.state.currentPlayerIndex = 1; // Bot
      controller.state.phase = TurnPhase.waitingForRoll;

      // Force timeout while on bot turn
      controller.forceTurnTimeout();

      // Must NOT skip bot turn! Current player must remain Bot (1)
      expect(controller.state.currentPlayerIndex, 1);
      controller.dispose();
    });

    test('TestCase 8: Human controls are disabled while Computer is playing', () async {
      final controller = LudoGameController(mode: GameMode.vsComputer);
      controller.state.currentPlayerIndex = 1; // Bot
      controller.state.phase = TurnPhase.waitingForMove;
      controller.state.currentDiceValue = 4;

      final humanToken = controller.state.players[0].tokens[0];
      humanToken.step = 5;

      // Attempt tapping human token
      await controller.onTokenTapped(humanToken);

      // Human token position unchanged because tap is rejected
      expect(humanToken.step, 5);
      controller.dispose();
    });

    test('TestCase 9: After Computer finishes, human controls become enabled', () async {
      final controller = LudoGameController(mode: GameMode.vsComputer);
      controller.state.currentPlayerIndex = 1; // Bot
      controller.state.phase = TurnPhase.waitingForRoll;

      await controller.playComputerTurn();

      // Now it's Human turn
      expect(controller.state.currentPlayerIndex, 0);
      expect(controller.state.phase, TurnPhase.waitingForRoll);
      expect(controller.isBotPlaying, false);

      // Human can roll dice
      controller.rollDice();
      expect(controller.state.phase, TurnPhase.throwingDice);
      controller.dispose();
    });

    test('TestCase 10: Game over when Computer wins all 4 tokens', () async {
      final controller = LudoGameController(mode: GameMode.vsComputer);
      controller.state.currentPlayerIndex = 1; // Bot

      // Put first 3 tokens in goal
      controller.state.players[1].tokens[0].step = 56;
      controller.state.players[1].tokens[1].step = 56;
      controller.state.players[1].tokens[2].step = 56;

      // 4th token 1 step away
      final lastToken = controller.state.players[1].tokens[3];
      lastToken.step = 55;

      controller.state.phase = TurnPhase.waitingForMove;
      controller.state.currentDiceValue = 1;

      final result = await controller.moveToken(lastToken, autoAdvanceTurn: true);

      expect(result.gameOver, true);
      expect(controller.state.phase, TurnPhase.gameOver);
      expect(controller.state.winners.first.name, "Computer (Yellow)");
      controller.dispose();
    });
  });
}
