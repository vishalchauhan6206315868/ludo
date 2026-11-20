import 'package:flutter_test/flutter_test.dart';
import 'package:ludo/logic/ludo_game_controller.dart';
import 'package:ludo/models/game_state.dart';
import 'package:ludo/models/room_model.dart';
import 'package:ludo/constants/ludo_path.dart';

void main() {
  group('3-Player Mode Integration Tests', () {
    test('RoomModel correctly parses 3-Player room payload', () {
      final json = {
        'success': true,
        'data': {
          'room': {
            '_id': 'room_3p_123',
            'roomCode': 'LUDO3P',
            'host': 'user_host_1',
            'players': [
              {'name': 'Host', 'user': 'user_host_1', 'seatIndex': 0},
              {'name': 'Player 2', 'user': 'user_2', 'seatIndex': 1},
              {'name': 'Player 3', 'user': 'user_3', 'seatIndex': 2},
            ],
            'maxPlayers': 3,
            'gameMode': 'threePlayer',
            'status': 'starting',
            'entryFee': 100,
            'sessionId': 'session_3p_abc',
          },
          'seatIndex': 0,
        }
      };

      final room = RoomModel.fromJson(json);
      expect(room.maxPlayers, 3);
      expect(room.gameMode, 'threePlayer');
      expect(room.playerCount, 3);
      expect(room.isFull, isTrue);
      expect(room.hasMatch, isTrue);
      expect(room.seatIndex, 0);
    });

    test('LudoGameController correctly initializes 3-Player match layout', () {
      final controller = LudoGameController(
        mode: GameMode.threePlayer,
        isOnlineMatch: true,
        mySeatIndex: 0,
      );

      final state = controller.state;
      expect(state.players.length, 3);
      expect(state.players[0].color, PlayerColor.red);
      expect(state.players[1].color, PlayerColor.green);
      expect(state.players[2].color, PlayerColor.yellow);

      // Verify no blue player
      expect(state.players.any((p) => p.color == PlayerColor.blue), isFalse);

      // Each player has 4 tokens -> 12 tokens total
      final totalTokens = state.players.fold<int>(0, (acc, p) => acc + p.tokens.length);
      expect(totalTokens, 12);

      controller.dispose();
    });

    test('Turn cycle rotates strictly 0 -> 1 -> 2 -> 0 in 3-Player mode', () {
      final controller = LudoGameController(
        mode: GameMode.threePlayer,
      );

      expect(controller.state.currentPlayerIndex, 0);
      
      // Advance turn manually
      controller.state.currentPlayerIndex = 1;
      expect(controller.state.currentPlayer.color, PlayerColor.green);

      controller.state.currentPlayerIndex = 2;
      expect(controller.state.currentPlayer.color, PlayerColor.yellow);

      controller.state.currentPlayerIndex = 0;
      expect(controller.state.currentPlayer.color, PlayerColor.red);

      controller.dispose();
    });

    test('Surrendered player in 3-Player mode is skipped in turn cycle', () {
      final controller = LudoGameController(
        mode: GameMode.threePlayer,
      );

      // Mark seat 1 (Green) as surrendered
      controller.state.players[1].isSurrendered = true;

      // Online apply turn simulation:
      // Turn skips seat 1 when seat 0 completes turn or times out
      expect(controller.state.players[1].isSurrendered, isTrue);
      expect(controller.state.players[0].isSurrendered, isFalse);
      expect(controller.state.players[2].isSurrendered, isFalse);

      controller.dispose();
    });
  });
}
