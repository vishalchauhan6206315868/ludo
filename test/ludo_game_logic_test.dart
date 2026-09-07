import 'package:flutter_test/flutter_test.dart';
import 'package:ludo/constants/ludo_path.dart';
import 'package:ludo/logic/ludo_game_controller.dart';
import 'package:ludo/models/game_state.dart';
import 'package:ludo/models/token.dart';

void main() {
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
    });

    test('Controller initializes with 4 players for fourPlayer mode', () {
      final controller = LudoGameController(mode: GameMode.fourPlayer);
      expect(controller.state.players.length, 4);
      expect(controller.state.players[0].color, PlayerColor.red);
      expect(controller.state.players[1].color, PlayerColor.green);
      expect(controller.state.players[2].color, PlayerColor.yellow);
      expect(controller.state.players[3].color, PlayerColor.blue);
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
    });
  });
}
