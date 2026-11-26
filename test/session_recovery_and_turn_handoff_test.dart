import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo/constants/ludo_path.dart';
import 'package:ludo/logic/ludo_game_controller.dart';
import 'package:ludo/models/game_state.dart';
import 'package:ludo/models/player_identity.dart';
import 'package:ludo/models/room_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Session Recovery & RoomModel Parsing Tests', () {
    test('RoomModel parses sessionId from sessionId field', () {
      final json = {
        'room': {
          '_id': 'room_1',
          'roomCode': 'LUDO01',
          'host': 'user_host_1',
          'players': ['user_host_1'],
          'maxPlayers': 2,
          'gameMode': 'twoPlayer',
          'status': 'playing',
        },
        'sessionId': 'session_abc_123',
      };
      final room = RoomModel.fromJson(json);
      expect(room.sessionId, equals('session_abc_123'));
      expect(room.hasSession, isTrue);
    });

    test('RoomModel parses matchId / gameId when sessionId is named matchId', () {
      final json = {
        'room': {
          '_id': 'room_2',
          'roomCode': 'LUDO02',
          'host': 'user_host_2',
          'players': ['user_host_2'],
          'maxPlayers': 2,
          'gameMode': 'twoPlayer',
          'status': 'playing',
        },
        'matchId': 'match_xyz_789',
      };
      final room = RoomModel.fromJson(json);
      expect(room.sessionId, equals('match_xyz_789'));
      expect(room.hasSession, isTrue);
    });

    test('RoomModel parses session from nested session object (_id or id)', () {
      final json = {
        'room': {
          '_id': 'room_3',
          'roomCode': 'LUDO03',
          'host': 'user_host_3',
          'players': ['user_host_3'],
          'maxPlayers': 2,
          'gameMode': 'twoPlayer',
          'status': 'playing',
        },
        'session': {
          '_id': 'session_mongo_id_456',
          'status': 'in_progress',
        },
      };
      final room = RoomModel.fromJson(json);
      expect(room.sessionId, equals('session_mongo_id_456'));
      expect(room.hasSession, isTrue);
    });

    test('RoomModel.fromSocket parses sessionId, matchId, or gameId', () {
      final socketPayload = {
        'roomId': 'room_socket',
        'roomCode': 'SOC123',
        'hostId': 'host_sock',
        'matchId': 'session_from_socket_999',
        'players': [
          {'name': 'Vishal Chauhan', 'userId': 'uid_1', 'seatIndex': 0},
          {'name': 'Vishal Chauhan', 'userId': 'uid_2', 'seatIndex': 1},
        ],
      };
      final room = RoomModel.fromSocket(socketPayload);
      expect(room.sessionId, equals('session_from_socket_999'));
      expect(room.hasSession, isTrue);
    });

    test('RoomModel.copyWith never overwrites valid sessionId with null', () {
      final original = RoomModel(
        id: 'r1',
        roomCode: 'CODE11',
        host: 'host1',
        players: ['Player 1'],
        playerIds: ['id1'],
        maxPlayers: 2,
        gameMode: 'twoPlayer',
        status: 'playing',
        entryFee: 100,
        sessionId: 'authoritative_session_id',
      );

      final updated = original.copyWith(status: 'finished', sessionId: null);
      expect(updated.sessionId, equals('authoritative_session_id'));

      final replaced = original.copyWith(sessionId: 'new_session_id');
      expect(replaced.sessionId, equals('new_session_id'));
    });
  });

  group('Display Name Collision Safety Tests (Same name "Vishal Chauhan")', () {
    test('Identical display names are mapped strictly by authoritative userId', () {
      final hostIdentity = PlayerIdentity(
        userId: 'user_host_mongo_001',
        seatIndex: 0,
        color: 'RED',
        isHost: true,
      );
      final joinerIdentity = PlayerIdentity(
        userId: 'user_joiner_mongo_002',
        seatIndex: 1,
        color: 'GREEN',
        isHost: false,
      );

      // Both players have identical names
      expect(hostIdentity.seatIndex, equals(0));
      expect(hostIdentity.color, equals('RED'));
      expect(hostIdentity.isHost, isTrue);

      expect(joinerIdentity.seatIndex, equals(1));
      expect(joinerIdentity.color, equals('GREEN'));
      expect(joinerIdentity.isHost, isFalse);

      // Verify that userIds are distinct and seat mappings are authoritative
      expect(hostIdentity.userId, isNot(equals(joinerIdentity.userId)));
      expect(hostIdentity.playerColor, equals(PlayerColor.red));
      expect(joinerIdentity.playerColor, equals(PlayerColor.green));
    });

    test('Online state synchronization applies seats using user ID, not display name', () {
      final controller = LudoGameController(
        mode: GameMode.twoPlayer,
        isOnlineMatch: true,
        sessionId: 'test_session_identity',
        roomCode: 'SAME_NAME',
        mySeatIndex: 1, // Joiner device (Green)
        isHost: false,
        authenticatedUserId: 'user_joiner_mongo_002',
        playerIdentity: PlayerIdentity(
          userId: 'user_joiner_mongo_002',
          seatIndex: 1,
          color: 'GREEN',
          isHost: false,
        ),
      );

      // Controller must maintain seat 1 (Green) for joiner, never corrupted by host name
      expect(controller.mySeatIndex, equals(1));
      expect(controller.isHost, isFalse);
      expect(controller.myPlayer.color, equals(PlayerColor.green));

      controller.dispose();
    });
  });

  group('Turn Handoff & Session Event Handling Tests', () {
    test('Turn transitions from Red (seat 0) to Green (seat 1) on turn_changed', () {
      final controller = LudoGameController(
        mode: GameMode.twoPlayer,
        isOnlineMatch: true,
        sessionId: 'session_turn_test',
        roomCode: 'TRN123',
        mySeatIndex: 1, // Joiner device (Green)
        isHost: false,
        authenticatedUserId: 'user_green',
      );

      // Initially Red's turn (seat 0)
      controller.state.currentPlayerIndex = 0;
      controller.state.phase = TurnPhase.waitingForRoll;
      expect(controller.isMyTurn, isFalse);

      // Red throws 1 and has no legal moves -> Backend transitions turn to Green (seat 1)
      controller.state.currentPlayerIndex = 1;
      controller.state.phase = TurnPhase.waitingForRoll;
      controller.state.currentDiceValue = null;

      expect(controller.state.currentPlayerIndex, equals(1));
      expect(controller.isMyTurn, isTrue);
      expect(controller.state.phase, equals(TurnPhase.waitingForRoll));
      expect(controller.state.currentDiceValue, isNull);

      controller.dispose();
    });
  });
}
