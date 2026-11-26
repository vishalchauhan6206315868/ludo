import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo/constants/ludo_path.dart';
import 'package:ludo/models/player_identity.dart';
import 'package:ludo/models/room_model.dart';
import 'package:ludo/logic/ludo_game_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PlayerIdentity Model & Parsing Tests', () {
    test('tryParse parses standard backend player payload', () {
      final json = {
        'player': {
          'userId': 'user_123',
          'seatIndex': 0,
          'color': 'RED',
          'isHost': true,
        }
      };

      final identity = PlayerIdentity.tryParse(json);
      expect(identity, isNotNull);
      expect(identity!.userId, equals('user_123'));
      expect(identity.seatIndex, equals(0));
      expect(identity.color, equals('RED'));
      expect(identity.playerColor, equals(PlayerColor.red));
      expect(identity.isHost, isTrue);
    });

    test('tryParse parses joiner payload (seat 1, GREEN, isHost false)', () {
      final json = {
        'me': {
          'userId': 'user_456',
          'seatIndex': 1,
          'color': 'GREEN',
          'isHost': false,
        }
      };

      final identity = PlayerIdentity.tryParse(json);
      expect(identity, isNotNull);
      expect(identity!.userId, equals('user_456'));
      expect(identity.seatIndex, equals(1));
      expect(identity.color, equals('GREEN'));
      expect(identity.playerColor, equals(PlayerColor.green));
      expect(identity.isHost, isFalse);
    });

    test('tryParse handles direct map and normalizes colors', () {
      final json = {
        'userId': 'user_789',
        'seatIndex': 1,
        'color': 'green',
        'isHost': false,
      };

      final identity = PlayerIdentity.tryParse(json);
      expect(identity, isNotNull);
      expect(identity!.color, equals('GREEN'));
      expect(identity.playerColor, equals(PlayerColor.green));
    });

    test('tryParse finds matching user in players list', () {
      final json = {
        'players': [
          {'userId': 'host_uid', 'seatIndex': 0, 'color': 'RED', 'isHost': true},
          {'userId': 'joiner_uid', 'seatIndex': 1, 'color': 'GREEN', 'isHost': false},
        ]
      };

      final hostIdentity = PlayerIdentity.tryParse(json, expectedUserId: 'host_uid');
      expect(hostIdentity, isNotNull);
      expect(hostIdentity!.seatIndex, equals(0));
      expect(hostIdentity.color, equals('RED'));
      expect(hostIdentity.isHost, isTrue);

      final joinerIdentity = PlayerIdentity.tryParse(json, expectedUserId: 'joiner_uid');
      expect(joinerIdentity, isNotNull);
      expect(joinerIdentity!.seatIndex, equals(1));
      expect(joinerIdentity.color, equals('GREEN'));
      expect(joinerIdentity.isHost, isFalse);
    });
  });

  group('RoomModel PlayerIdentity Integration', () {
    test('RoomModel parses identity from REST response', () {
      final data = {
        '_id': 'room_abc',
        'roomCode': 'ABCDEF',
        'status': 'WAITING',
        'entryFee': 100,
        'gameMode': 'twoPlayer',
        'maxPlayers': 2,
        'host': 'user_host',
        'players': ['user_host', 'user_joiner'],
        'seatIndex': 1,
        'assignedColor': 'GREEN',
        'player': {
          'userId': 'user_joiner',
          'seatIndex': 1,
          'color': 'GREEN',
          'isHost': false,
        }
      };

      final room = RoomModel.fromJson(data);
      expect(room.seatIndex, equals(1));
      expect(room.assignedColor, equals('GREEN'));
      expect(room.identity, isNotNull);
      expect(room.identity!.seatIndex, equals(1));
      expect(room.identity!.color, equals('GREEN'));
      expect(room.identity!.isHost, isFalse);
    });
  });

  group('LudoGameController Player Identity & Turn Mapping', () {
    test('Host controller correctly sets seat 0, Red, and Host role', () {
      final hostIdentity = PlayerIdentity(
        userId: 'host_123',
        seatIndex: 0,
        color: 'RED',
        isHost: true,
      );

      final controller = LudoGameController(
        isOnlineMatch: true,
        isHost: true,
        mySeatIndex: 0,
        playerIdentity: hostIdentity,
      );

      expect(controller.mySeatIndex, equals(0));
      expect(controller.isHost, isTrue);
      expect(controller.myColor, equals(PlayerColor.red));
      expect(controller.myColorName, equals('RED'));
      expect(controller.myPlayer.color, equals(PlayerColor.red));

      // Seat 0 should have "You" in name, Seat 1 should have "Opponent"
      expect(controller.state.players[0].name, contains('You'));
      expect(controller.state.players[1].name, contains('Opponent'));

      // In initial state, turn is seat 0 (Red)
      expect(controller.state.currentPlayerIndex, equals(0));
      expect(controller.isMyTurn, isTrue);
    });

    test('Challenger/Joiner controller correctly sets seat 1, Green, and Joiner role', () {
      final joinerIdentity = PlayerIdentity(
        userId: 'joiner_456',
        seatIndex: 1,
        color: 'GREEN',
        isHost: false,
      );

      final controller = LudoGameController(
        isOnlineMatch: true,
        isHost: false,
        mySeatIndex: 1,
        playerIdentity: joinerIdentity,
      );

      expect(controller.mySeatIndex, equals(1));
      expect(controller.isHost, isFalse);
      expect(controller.myColor, equals(PlayerColor.green));
      expect(controller.myColorName, equals('GREEN'));
      expect(controller.myPlayer.color, equals(PlayerColor.green));

      // Seat 0 should have "Opponent", Seat 1 should have "You"
      expect(controller.state.players[0].name, contains('Opponent'));
      expect(controller.state.players[1].name, contains('You'));

      // In initial state (seat 0 turn), joiner is waiting for opponent
      expect(controller.state.currentPlayerIndex, equals(0));
      expect(controller.isMyTurn, isFalse);

      // When turn switches to seat 1, joiner gets turn
      controller.state.currentPlayerIndex = 1;
      expect(controller.isMyTurn, isTrue);
    });

    test('Joiner controller does not accidentally default to seat 0', () {
      // Even if mySeatIndex passed is 0, if isHost is false and online match, it must become 1
      final controller = LudoGameController(
        isOnlineMatch: true,
        isHost: false,
        mySeatIndex: 0,
      );

      expect(controller.mySeatIndex, equals(1));
      expect(controller.isHost, isFalse);
      expect(controller.myColor, equals(PlayerColor.green));
    });
  });
}
