import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo/models/room_model.dart';
import 'package:ludo/services/deep_link_service.dart';
import 'package:ludo/widgets/room_invitation_dialog.dart';

void main() {
  group('DeepLinkService URI Parser & Validation Tests', () {
    test('Extracts room code from HTTPS App Link with path', () {
      final uri = Uri.parse('https://ludoapi-jupm.onrender.com/join/HYYKM3');
      final code = DeepLinkService.extractRoomCode(uri);
      expect(code, equals('HYYKM3'));
    });

    test('Normalizes lowercase room code to uppercase', () {
      final uri = Uri.parse('https://ludoapi-jupm.onrender.com/join/hyykm3');
      final code = DeepLinkService.extractRoomCode(uri);
      expect(code, equals('HYYKM3'));
    });

    test('Extracts room code from HTTPS App Link with query param', () {
      final uri = Uri.parse('https://ludoapi-jupm.onrender.com/join?code=AB12CD');
      final code = DeepLinkService.extractRoomCode(uri);
      expect(code, equals('AB12CD'));
    });

    test('Extracts room code from custom scheme ludosupreme://join?code=...', () {
      final uri = Uri.parse('ludosupreme://join?code=XK92LP');
      final code = DeepLinkService.extractRoomCode(uri);
      expect(code, equals('XK92LP'));
    });

    test('Extracts room code from custom scheme ludosupreme://join/:code', () {
      final uri = Uri.parse('ludosupreme://join/ROYAL7');
      final code = DeepLinkService.extractRoomCode(uri);
      expect(code, equals('ROYAL7'));
    });

    test('Rejects malformed room codes (too short or special characters)', () {
      expect(DeepLinkService.extractRoomCode(Uri.parse('https://ludoapi-jupm.onrender.com/join/')), isNull);
      expect(DeepLinkService.extractRoomCode(Uri.parse('https://ludoapi-jupm.onrender.com/join/A1')), isNull); // < 4 chars
      expect(DeepLinkService.extractRoomCode(Uri.parse('https://ludoapi-jupm.onrender.com/join/ABC_123')), isNull); // invalid char
      expect(DeepLinkService.extractRoomCode(Uri.parse('https://ludoapi-jupm.onrender.com/join/TOOLONGROOMCODE12345')), isNull); // > 10 chars
    });
  });

  group('PendingRoomInvitation Lifecycle & Expiration Tests', () {
    test('Pending invitation retains room code and rawUrl', () {
      final invite = PendingRoomInvitation(
        roomCode: 'TEST01',
        rawUrl: 'https://ludoapi-jupm.onrender.com/join/TEST01',
        timestamp: DateTime.now(),
      );

      expect(invite.roomCode, equals('TEST01'));
      expect(invite.rawUrl, contains('TEST01'));
      expect(invite.isExpired, isFalse);
    });

    test('Pending invitation expires after 15 minutes', () {
      final expiredInvite = PendingRoomInvitation(
        roomCode: 'OLD123',
        timestamp: DateTime.now().subtract(const Duration(minutes: 16)),
      );

      expect(expiredInvite.isExpired, isTrue);
    });
  });

  group('RoomInvitationDialog Widget Tests', () {
    RoomModel createTestRoom({
      String code = 'HYYKM3',
      int entryFee = 100,
      int maxPlayers = 2,
    }) {
      return RoomModel(
        id: 'room_inv_1',
        roomCode: code,
        host: 'host_u1',
        gameMode: maxPlayers == 4 ? 'fourPlayer' : 'twoPlayer',
        entryFee: entryFee,
        maxPlayers: maxPlayers,
        status: 'waiting',
        players: const ['Host Player'],
        playerIds: const ['host_u1'],
        createdAt: DateTime.now(),
      );
    }

    testWidgets('Renders all match details and action buttons', (WidgetTester tester) async {
      final room = createTestRoom(code: 'INV777', entryFee: 200, maxPlayers: 2);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomInvitationDialog(
              room: room,
              userBalance: 500,
              onConfirmJoin: () {},
              onCancel: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify title & room code
      expect(find.text('MATCH INVITATION'), findsOneWidget);
      expect(find.text('INV777'), findsOneWidget);

      // Verify chips
      expect(find.text('2 Players Match'), findsOneWidget);
      expect(find.text('200 Coins'), findsOneWidget);
      expect(find.text('1/2 Joined'), findsOneWidget);

      // Verify buttons
      expect(find.text('JOIN MATCH'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);
    });

    testWidgets('Tapping JOIN MATCH triggers onConfirmJoin callback', (WidgetTester tester) async {
      final room = createTestRoom();
      bool joined = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomInvitationDialog(
              room: room,
              userBalance: 500,
              onConfirmJoin: () => joined = true,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('JOIN MATCH'));
      await tester.pump();

      expect(joined, isTrue);
    });

    testWidgets('Tapping CANCEL triggers onCancel callback', (WidgetTester tester) async {
      final room = createTestRoom();
      bool cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomInvitationDialog(
              room: room,
              userBalance: 500,
              onConfirmJoin: () {},
              onCancel: () => cancelled = true,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('CANCEL'));
      await tester.pump();

      expect(cancelled, isTrue);
    });
  });
}
