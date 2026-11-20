import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo/constants/ludo_path.dart';
import 'package:ludo/logic/ludo_game_controller.dart';
import 'package:ludo/models/game_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LudoGameController.isFastBotForTesting = true;
  });

  tearDown(() {
    LudoGameController.isFastBotForTesting = false;
  });

  group('Team Up Mode Initialization', () {
    test('Initializes 4 players in Team Up mode with correct team assignments', () {
      final controller = LudoGameController(mode: GameMode.teamUp);
      final players = controller.state.players;

      expect(players.length, equals(4));

      // Red - Team A
      expect(players[0].color, equals(PlayerColor.red));
      expect(players[0].teamId, equals('A'));

      // Green - Team B
      expect(players[1].color, equals(PlayerColor.green));
      expect(players[1].teamId, equals('B'));

      // Yellow - Team A (Red's partner)
      expect(players[2].color, equals(PlayerColor.yellow));
      expect(players[2].teamId, equals('A'));

      // Blue - Team B (Green's partner)
      expect(players[3].color, equals(PlayerColor.blue));
      expect(players[3].teamId, equals('B'));

      // Partner helper verification
      expect(players[0].isTeammateWith(players[2]), isTrue);
      expect(players[1].isTeammateWith(players[3]), isTrue);
      expect(players[0].isTeammateWith(players[1]), isFalse);
      expect(players[0].isTeammateWith(players[3]), isFalse);

      controller.dispose();
    });

    test('Initializes Vs Bot Team Up with correct bot flags', () {
      final controller = LudoGameController(
        mode: GameMode.teamUp,
        isTeamUpVsBot: true,
      );
      final players = controller.state.players;

      expect(players[0].isBot, isFalse); // Red (User)
      expect(players[1].isBot, isTrue);  // Green (Bot Opponent 1)
      expect(players[2].isBot, isTrue);  // Yellow (Bot Ally)
      expect(players[3].isBot, isTrue);  // Blue (Bot Opponent 2)

      controller.dispose();
    });
  });

  group('Team Up Capture Rules', () {
    test('Teammates do NOT capture each other on non-safe track squares', () async {
      final controller = LudoGameController(mode: GameMode.teamUp);
      final p1 = controller.state.players[0]; // Red (Team A)
      final p3 = controller.state.players[2]; // Yellow (Team A)

      // Track cell 28 is non-safe.
      // Yellow starts at 26, so Yellow step 2 is track cell 28.
      p3.tokens[0].step = 2;
      expect(LudoPath.isSafeCoord(p3.tokens[0].coordinate), isFalse);

      // Red starts at 0, so Red step 26 is track cell 26.
      p1.tokens[0].step = 26;

      // Roll 2 for Red to land exactly on Yellow's square
      controller.state.currentPlayerIndex = 0;
      controller.state.phase = TurnPhase.waitingForMove;
      controller.state.currentDiceValue = 2;

      await controller.moveToken(p1.tokens[0]);

      // Both tokens now share the same coordinate
      expect(p1.tokens[0].step, equals(28));
      expect(p1.tokens[0].coordinate, equals(p3.tokens[0].coordinate));

      // Yellow token must NOT be captured back to base!
      expect(p3.tokens[0].step, equals(2));
      expect(p3.tokens[0].isInBase, isFalse);

      controller.dispose();
    });

    test('Opponent tokens ARE captured when landed upon', () async {
      final controller = LudoGameController(mode: GameMode.teamUp);
      final p1 = controller.state.players[0]; // Red (Team A)
      final p2 = controller.state.players[1]; // Green (Team B)

      // Track cell 28 is non-safe.
      // Green starts at 13, so Green step 15 is track cell 28.
      p2.tokens[0].step = 15;
      expect(LudoPath.isSafeCoord(p2.tokens[0].coordinate), isFalse);

      // Red step 26
      p1.tokens[0].step = 26;

      // Roll 2 for Red to land on Green's square
      controller.state.currentPlayerIndex = 0;
      controller.state.phase = TurnPhase.waitingForMove;
      controller.state.currentDiceValue = 2;

      await controller.moveToken(p1.tokens[0]);

      // Red reaches step 28
      expect(p1.tokens[0].step, equals(28));
      // Green token MUST be sent back to base (-1)
      expect(p2.tokens[0].step, equals(-1));
      expect(p2.tokens[0].isInBase, isTrue);

      controller.dispose();
    });
  });

  group('Team Up Co-op Finished Player Movement', () {
    test('When Player 1 finished all 4 tokens, Player 1 can move partner tokens', () async {
      final controller = LudoGameController(mode: GameMode.teamUp);
      final p1 = controller.state.players[0]; // Red
      final p3 = controller.state.players[2]; // Yellow

      // Finish all 4 of Red's tokens
      for (final t in p1.tokens) {
        t.step = 56;
      }
      expect(p1.hasFinished, isTrue);

      // Yellow token 0 is in play at step 10
      p3.tokens[0].step = 10;

      // It is Red's turn, Red rolls 3
      controller.state.currentPlayerIndex = 0;
      controller.state.phase = TurnPhase.waitingForMove;
      controller.state.currentDiceValue = 3;

      // Red moves Yellow's token
      await controller.moveToken(p3.tokens[0]);

      expect(p3.tokens[0].step, equals(13));

      controller.dispose();
    });
  });

  group('Team Up Victory Condition', () {
    test('Game ends when all 8 tokens of Team A reach Goal', () async {
      final controller = LudoGameController(mode: GameMode.teamUp);
      final p1 = controller.state.players[0]; // Red (Team A)
      final p3 = controller.state.players[2]; // Yellow (Team A)

      // Finish all 4 tokens of Red
      for (final t in p1.tokens) {
        t.step = 56;
      }

      // Finish first 3 tokens of Yellow
      for (int i = 0; i < 3; i++) {
        p3.tokens[i].step = 56;
      }

      // Yellow token 3 is 1 step away from Goal (step 55)
      p3.tokens[3].step = 55;

      // Yellow rolls 1 to reach Goal
      controller.state.currentPlayerIndex = 2;
      controller.state.phase = TurnPhase.waitingForMove;
      controller.state.currentDiceValue = 1;

      await controller.moveToken(p3.tokens[3]);

      // All 8 tokens are now finished
      expect(p3.tokens[3].step, equals(56));
      expect(p3.tokens[3].hasReachedGoal, isTrue);
      expect(controller.state.isGameOver, isTrue);
      expect(controller.state.winningTeam, equals('A'));

      controller.dispose();
    });
  });
}
