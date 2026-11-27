import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo/models/room_model.dart';
import 'package:ludo/widgets/room_lobby_dialog.dart';
import 'package:ludo/widgets/social_share_bottom_sheet.dart';

void main() {
  RoomModel createTestRoom({
    String code = 'LUDO77',
    int maxPlayers = 2,
    int entryFee = 200,
    String gameMode = 'twoPlayer',
  }) {
    return RoomModel(
      id: 'room_test_1',
      roomCode: code,
      host: 'host_u1',
      gameMode: gameMode,
      entryFee: entryFee,
      maxPlayers: maxPlayers,
      status: 'waiting',
      players: ['Host User'],
      playerIds: const ['host_u1'],
      createdAt: DateTime.now(),
    );
  }

  group('SocialShareBottomSheet Invite Message Generator Tests', () {
    test('generateInviteMessage includes dynamic room code, mode, and entry fee', () {
      final room = createTestRoom(code: 'XK92LP', entryFee: 500, gameMode: 'twoPlayer');
      final msg = SocialShareBottomSheet.generateInviteMessage(room);

      expect(msg, contains('XK92LP'));
      expect(msg, contains('2 Players Match'));
      expect(msg, contains('500 Coins'));
      expect(msg, contains('Ludo Supreme Match Invitation!'));
      expect(msg, contains('https://ludoapi-jupm.onrender.com/join/XK92LP'));
      expect(msg, contains('Join directly:'));
    });

    test('generateInviteMessage formats free entry and 4-player mode properly', () {
      final room = createTestRoom(code: 'FREE4P', entryFee: 0, gameMode: 'fourPlayer', maxPlayers: 4);
      final msg = SocialShareBottomSheet.generateInviteMessage(room);

      expect(msg, contains('FREE4P'));
      expect(msg, contains('4 Players Match'));
      expect(msg, contains('Free Entry'));
    });
  });

  group('SocialShareBottomSheet 3D Royal Gaming UI Widget Tests', () {
    testWidgets('Renders all 3D gaming elements, badges, ribbons, and actions', (WidgetTester tester) async {
      final room = createTestRoom(code: 'ROYAL8', entryFee: 150, gameMode: 'twoPlayer');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialShareBottomSheet(room: room, autoCopied: false),
          ),
        ),
      );
      await tester.pump();

      // 1. 3D Golden Ribbon Title & Subtitle
      expect(find.text('Room Code Copied!'), findsOneWidget);
      expect(find.text('Invite your friends to join your match.'), findsOneWidget);

      // 2. Hex Neon Room Code Capsule & Gold Copy Button
      expect(find.text('ROOM CODE'), findsOneWidget);
      expect(find.text('ROYAL8'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);

      // 3. Primary Red & Gold Mega Action Button
      expect(find.text('Share / Invite Friends'), findsOneWidget);

      // 4. All 8 3D Social Media Badges with Mini Gold Ribbons
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('WhatsApp Status'), findsOneWidget);
      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('Facebook'), findsOneWidget);
      expect(find.text('X / Twitter'), findsOneWidget);
      expect(find.text('Snapchat'), findsOneWidget);
      expect(find.text('Telegram'), findsOneWidget);
      expect(find.text('More Apps'), findsOneWidget);

      // 5. Bottom Navigation & Close Button
      expect(find.text('Back to Lobby'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('Tapping Copy inside 3D capsule toggles state to Copied and reverts', (WidgetTester tester) async {
      final room = createTestRoom(code: 'TEST99', entryFee: 100);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialShareBottomSheet(room: room, autoCopied: false),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Copy'), findsOneWidget);
      await tester.tap(find.text('Copy'));
      await tester.pump();

      expect(find.text('Copied'), findsOneWidget);

      // Advance timer so no pending timers remain
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Copy'), findsOneWidget);
    });

    testWidgets('autoCopied = true initially renders Copied state', (WidgetTester tester) async {
      final room = createTestRoom(code: 'AUTO11');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialShareBottomSheet(room: room, autoCopied: true),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Copied'), findsOneWidget);
    });

    testWidgets('Tapping Back to Lobby or Close button pops dialog', (WidgetTester tester) async {
      final room = createTestRoom(code: 'BACK01');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => SocialShareBottomSheet.show(ctx, room: room),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SocialShareBottomSheet), findsOneWidget);
      expect(find.text('Back to Lobby'), findsOneWidget);

      await tester.tap(find.text('Back to Lobby'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SocialShareBottomSheet), findsNothing);
    });

    testWidgets('Renders on 360x780 mobile screen with zero RenderFlex overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final room = createTestRoom(code: 'DEV360', entryFee: 100);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialShareBottomSheet(room: room, autoCopied: false),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Room Code Copied!'), findsOneWidget);
      expect(find.text('Facebook'), findsOneWidget);
      expect(find.text('More Apps'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders on small 320x568 screen with zero RenderFlex overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final room = createTestRoom(code: 'MINI32', entryFee: 50);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SocialShareBottomSheet(room: room, autoCopied: false),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Room Code Copied!'), findsOneWidget);
      expect(find.text('Facebook'), findsOneWidget);
      expect(find.text('More Apps'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('RoomLobbyDialog Social Share Integration Tests', () {
    testWidgets('Renders dedicated SHARE / INVITE FRIENDS button', (WidgetTester tester) async {
      final room = createTestRoom(code: 'SHARE1');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomLobbyDialog(room: room, isHost: true, enableSocket: false),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('SHARE / INVITE FRIENDS'), findsOneWidget);
      expect(find.text('WhatsApp, IG & more'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Tapping dedicated SHARE / INVITE FRIENDS button opens 3D SocialShareBottomSheet', (WidgetTester tester) async {
      final room = createTestRoom(code: 'OPEN99');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomLobbyDialog(room: room, isHost: true, enableSocket: false),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('SHARE / INVITE FRIENDS'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Verify 3D bottom sheet opened
      expect(find.byType(SocialShareBottomSheet), findsOneWidget);
      expect(find.text('Room Code Copied!'), findsOneWidget);
      expect(find.text('OPEN99'), findsWidgets); // on lobby and in bottom sheet
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('Share / Invite Friends'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Tapping Tap to Copy Code opens 3D SocialShareBottomSheet with Copied state', (WidgetTester tester) async {
      final room = createTestRoom(code: 'COPY55');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoomLobbyDialog(room: room, isHost: true, enableSocket: false),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('Tap to Copy Code'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Verify bottom sheet opened with autoCopied = true
      expect(find.byType(SocialShareBottomSheet), findsOneWidget);
      expect(find.text('Copied'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);

      // Advance timer so no copy timer remains
      await tester.pump(const Duration(seconds: 3));

      await tester.pumpWidget(const SizedBox());
    });
  });
}
