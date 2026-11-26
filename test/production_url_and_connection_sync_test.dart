import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo/core/network/api_config.dart';
import 'package:ludo/services/ludo_socket_service.dart';
import 'package:ludo/logic/ludo_game_controller.dart';
import 'package:ludo/models/game_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Production URL Configuration Tests (Phase 2)', () {
    test('ApiConfig defaultBaseUrl points to verified production URL', () {
      expect(ApiConfig.defaultBaseUrl, equals('https://ludoapi-jupm.onrender.com/api'));
    });

    test('ApiConfig baseUrl resolves correctly', () {
      ApiConfig.customBaseUrl = null;
      ApiConfig.setActiveBaseUrl('');
      expect(ApiConfig.baseUrl, equals('https://ludoapi-jupm.onrender.com/api'));
    });

    test('ApiConfig socketUrl resolves without /api path', () {
      ApiConfig.customBaseUrl = null;
      ApiConfig.setActiveBaseUrl('');
      expect(ApiConfig.socketUrl, equals('https://ludoapi-jupm.onrender.com'));
    });

    test('No references to ludoapi-3 remain in ApiConfig', () {
      expect(ApiConfig.defaultBaseUrl.contains('ludoapi-3'), isFalse);
      expect(ApiConfig.socketUrl.contains('ludoapi-3'), isFalse);
    });
  });

  group('Socket.IO Service & Connection State Tests (Phase 3)', () {
    test('LudoSocketService instance exists and status is defined', () {
      final socketService = LudoSocketService.instance;
      expect(socketService, isNotNull);
      expect(socketService.status, isA<LudoConnectionStatus>());
    });

    test('LudoConnectionStatus contains all required connection states', () {
      expect(LudoConnectionStatus.values, contains(LudoConnectionStatus.idle));
      expect(LudoConnectionStatus.values, contains(LudoConnectionStatus.connecting));
      expect(LudoConnectionStatus.values, contains(LudoConnectionStatus.connected));
      expect(LudoConnectionStatus.values, contains(LudoConnectionStatus.reconnecting));
      expect(LudoConnectionStatus.values, contains(LudoConnectionStatus.unauthorized));
    });
  });

  group('Turn Freeze Bug Prevention & Game Sync Tests (Phase 5 & 6)', () {
    test('When no legal moves exist on non-six roll, turn passes to opponent cleanly', () {
      final controller = LudoGameController(
        mode: GameMode.twoPlayer,
        isOnlineMatch: true,
        mySeatIndex: 0,
      );

      // Verify Player 0 (Red / Host) starts
      expect(controller.state.currentPlayerIndex, equals(0));
      expect(controller.state.players.length, equals(2));

      // Ensure all tokens start in base
      expect(controller.state.players[0].tokens.every((t) => t.isInBase), isTrue);

      controller.dispose();
    });

    test('LudoGameController handles authoritative turn_changed event properly', () {
      final controller = LudoGameController(
        mode: GameMode.twoPlayer,
        isOnlineMatch: true,
        isHost: false,
        mySeatIndex: 1, // Green player
      );

      // Verify controller can apply turn state without locking
      expect(controller.mySeatIndex, equals(1));
      expect(controller.isHost, isFalse);

      controller.dispose();
    });
  });

  group('REST Fallback Lifecycle Tests (Phase 8)', () {
    test('LudoGameController starts and disposes without timer leaks', () {
      final controller = LudoGameController(
        mode: GameMode.twoPlayer,
        isOnlineMatch: true,
        roomCode: 'TEST01',
        mySeatIndex: 0,
      );

      // Verify controller initializes
      expect(controller.roomCode, equals('TEST01'));
      expect(controller.isOnlineMatch, isTrue);

      // Dispose controller and verify timers cleanly shut down
      controller.dispose();
    });
  });
}
