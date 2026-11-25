import 'package:flutter_test/flutter_test.dart';
import 'package:ludo/services/nearby_matchmaking_service.dart';

void main() {
  group('NearbyMatchmakingService & Model Tests', () {
    test('NearbyMatchData.fromMap correctly parses match payload', () {
      final payload = {
        'roomId': 'room_123',
        'roomCode': 'LUDO99',
        'sessionId': 'session_abc',
        'entryFee': 100,
        'prizePool': 180,
        'opponent': {
          'id': 'user_opp',
          'name': 'Rahul Sharma',
          'avatar': 'https://example.com/avatar.png',
          'seatIndex': 1,
          'color': 'Green',
        },
        'you': {
          'seatIndex': 0,
          'color': 'Red',
        },
        'state': {
          'status': 'in_progress',
          'turn': {'seatIndex': 0, 'status': 'WAITING_FOR_ROLL'},
        },
      };

      final data = NearbyMatchData.fromMap(payload, radiusKm: 10);

      expect(data.roomId, 'room_123');
      expect(data.roomCode, 'LUDO99');
      expect(data.sessionId, 'session_abc');
      expect(data.entryFee, 100);
      expect(data.prizePool, 180);
      expect(data.radiusKm, 10);
      expect(data.opponent['name'], 'Rahul Sharma');
      expect(data.opponent['color'], 'Green');
      expect(data.you['seatIndex'], 0);
      expect(data.you['color'], 'Red');
      expect(data.gameState, isNotNull);
      expect(data.gameState!['status'], 'in_progress');
    });

    test('NearbyMatchData handles missing or partial data gracefully', () {
      final emptyPayload = <String, dynamic>{};
      final data = NearbyMatchData.fromMap(emptyPayload);

      expect(data.roomId, '');
      expect(data.roomCode, '');
      expect(data.sessionId, '');
      expect(data.entryFee, 0);
      expect(data.prizePool, 0);
      expect(data.radiusKm, 5); // default radius
      expect(data.opponent, isEmpty);
      expect(data.you, isEmpty);
      expect(data.gameState, isNull);
    });

    test('NearbyMatchmakingService initial state is idle and default radius is 5 km', () {
      final service = NearbyMatchmakingService.instance;
      service.reset();

      expect(service.currentState, NearbyMatchmakingState.idle);
      expect(service.elapsedSeconds, 0);
      expect(service.errorMessage, isNull);
      expect(service.matchData, isNull);
      expect(service.selectedRadiusKm, 5);
    });

    test('NearbyMatchmakingService radius selection updates value notifier', () {
      final service = NearbyMatchmakingService.instance;
      service.setRadius(25);
      expect(service.selectedRadiusKm, 25);

      service.setRadius(1);
      expect(service.selectedRadiusKm, 1);

      service.setRadius(10);
      expect(service.selectedRadiusKm, 10);

      service.setRadius(5);
      expect(service.selectedRadiusKm, 5);
    });
  });
}
