import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo/models/room_model.dart';
import 'package:ludo/widgets/room_lobby_dialog.dart';

void main() {
  RoomModel createTestRoom({
    String code = '939Z6S',
    int maxPlayers = 2,
    int entryFee = 100,
    List<String>? players,
    String status = 'waiting',
  }) {
    return RoomModel(
      id: 'room_123',
      roomCode: code,
      host: 'host_01',
      gameMode: maxPlayers == 4 ? 'fourPlayer' : 'twoPlayer',
      entryFee: entryFee,
      maxPlayers: maxPlayers,
      status: status,
      players: players ?? ['Host Player'],
      playerIds: const ['host_01'],
      createdAt: DateTime.now(),
    );
  }

  group('RoomLobbyDialog 3D Royal Redesign Tests', () {
    testWidgets('Renders 2-player room lobby dialog with all 3D components', (WidgetTester tester) async {
      final room = createTestRoom(code: '939Z6S', maxPlayers: 2, entryFee: 100);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomLobbyDialog(room: room, isHost: true, enableSocket: false),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      // Verify Header
      expect(find.text('GAME ROOM '), findsOneWidget);
      expect(find.text('CREATED'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Verify Room Code & Share hint
      expect(find.text('939Z6S'), findsOneWidget);
      expect(find.text('Share this Room Code with your friends to join:'), findsOneWidget);
      expect(find.text('Tap to Copy Code'), findsOneWidget);

      // Verify 3-in-1 Meta Metrics Bar
      expect(find.text('2 Players'), findsOneWidget);
      expect(find.text('Fee: 100'), findsOneWidget);
      expect(find.text('Waiting'), findsWidgets);

      // Verify Player Slots
      expect(find.text('Lobby Players:'), findsOneWidget);
      expect(find.text('Host (You)'), findsOneWidget);
      expect(find.text('Red'), findsOneWidget);
      expect(find.text('Green'), findsOneWidget);

      // Verify Action Buttons
      expect(find.text('Cancel Room'), findsOneWidget);
      expect(find.text('Waiting for Players...'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Renders 4-player room lobby dialog with all 4 seat slots', (WidgetTester tester) async {
      final room = createTestRoom(code: 'ABCD12', maxPlayers: 4, entryFee: 250);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomLobbyDialog(room: room, isHost: true, enableSocket: false),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('ABCD12'), findsOneWidget);
      expect(find.text('4 Players'), findsOneWidget);
      expect(find.text('Fee: 250'), findsOneWidget);
      expect(find.text('Red'), findsOneWidget);
      expect(find.text('Green'), findsOneWidget);
      expect(find.text('Yellow'), findsOneWidget);
      expect(find.text('Blue'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Tapping copy code updates text to Code Copied!', (WidgetTester tester) async {
      final room = createTestRoom(code: 'COPY99', maxPlayers: 2, entryFee: 50);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomLobbyDialog(room: room, isHost: true, enableSocket: false),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Tap to Copy Code'), findsOneWidget);

      await tester.tap(find.text('Tap to Copy Code'));
      await tester.pump();

      expect(find.text('Code Copied!'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Small screen (320x568) renders without RenderFlex overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final room = createTestRoom(code: 'MINI01', maxPlayers: 2, entryFee: 100);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomLobbyDialog(room: room, isHost: true, enableSocket: false),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('GAME ROOM '), findsOneWidget);
      expect(find.text('MINI01'), findsOneWidget);
      expect(find.text('2 Players'), findsOneWidget);
      expect(find.text('Cancel Room'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
