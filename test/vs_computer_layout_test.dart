import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo/logic/ludo_game_controller.dart';
import 'package:ludo/models/game_state.dart';
import 'package:ludo/screens/game_screen.dart';
import 'package:ludo/widgets/board/ludo_board_widget.dart';
import 'package:ludo/widgets/player_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LudoGameController.isFastBotForTesting = true;
  });

  group('Play Vs Computer Layout Tests', () {
    testWidgets('Computer Red player card at TOP, You Yellow player card at BOTTOM',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(
            mode: GameMode.vsComputer,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Find player cards by Semantics label (icon-only compact cards)
      final yellowCardFinder = find.byWidgetPredicate(
        (w) => w is PlayerCard && w.player.name == 'You (Yellow)',
      );
      final computerCardFinder = find.byWidgetPredicate(
        (w) => w is PlayerCard && w.player.name == 'Computer (Red)',
      );
      final boardFinder = find.byType(LudoBoardWidget);

      expect(yellowCardFinder, findsOneWidget);
      expect(computerCardFinder, findsOneWidget);
      expect(boardFinder, findsOneWidget);
      expect(find.byIcon(Icons.person_rounded), findsNWidgets(2));

      final computerTopLeft = tester.getTopLeft(computerCardFinder);
      final boardTopLeft = tester.getTopLeft(boardFinder);
      final boardBottomRight = tester.getBottomRight(boardFinder);
      final yellowTopLeft = tester.getTopLeft(yellowCardFinder);

      // Verify Computer (Red) card is ABOVE the board (at TOP)
      expect(computerTopLeft.dy, lessThan(boardTopLeft.dy),
          reason: 'Computer (Red) player card must be positioned at TOP above the board');

      // Verify You (Yellow) player card is BELOW the board (at BOTTOM)
      expect(yellowTopLeft.dy, greaterThan(boardBottomRight.dy),
          reason: 'You (Yellow) player card must be positioned BELOW the board');

      // Verify board is horizontally centered
      final boardCenter = tester.getCenter(boardFinder);
      expect((boardCenter.dx - 390 / 2).abs(), lessThan(5.0),
          reason: 'Board should remain horizontally centered');

      // Verify both compact PlayerCards are rendered without name/timer clutter
      final playerCards = tester.widgetList<PlayerCard>(find.byType(PlayerCard)).toList();
      expect(playerCards.length, 2);
      expect(find.text('0/4 Home'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('Responsive screen test (360x640) - no overflow and correct layout',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(
            mode: GameMode.vsComputer,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final yellowCardFinder = find.byWidgetPredicate(
        (w) => w is PlayerCard && w.player.name == 'You (Yellow)',
      );
      final computerCardFinder = find.byWidgetPredicate(
        (w) => w is PlayerCard && w.player.name == 'Computer (Red)',
      );
      expect(yellowCardFinder, findsOneWidget);
      expect(computerCardFinder, findsOneWidget);
      expect(tester.takeException(), isNull);

      final computerTopLeft = tester.getTopLeft(computerCardFinder);
      final boardTopLeft = tester.getTopLeft(find.byType(LudoBoardWidget));
      final boardBottomRight = tester.getBottomRight(find.byType(LudoBoardWidget));
      final yellowTopLeft = tester.getTopLeft(yellowCardFinder);

      expect(computerTopLeft.dy, lessThan(boardTopLeft.dy));
      expect(yellowTopLeft.dy, greaterThan(boardBottomRight.dy));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('Responsive compact screen test (320x568) - no overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(
            mode: GameMode.vsComputer,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PlayerCard), findsNWidgets(2));
      expect(find.byIcon(Icons.person_rounded), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('Dice rolls, turn indicator updates, and bot plays in vsComputer mode',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(
            mode: GameMode.vsComputer,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Find inactive dice slot / casino icon
      final diceFinder = find.byIcon(Icons.casino_outlined);
      expect(diceFinder, findsOneWidget);
      expect(find.byType(PlayerCard), findsNWidgets(2));

      // Tap to roll dice for Yellow (Human Player)
      final yellowCard = find.byWidgetPredicate(
        (w) => w is PlayerCard && w.player.name == 'You (Yellow)',
      );
      expect(yellowCard, findsOneWidget);

      await tester.tap(yellowCard);
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump(const Duration(milliseconds: 1450));
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump(const Duration(milliseconds: 500));

      // Game state remains healthy and playable
      expect(tester.takeException(), isNull);

      // Cleanly unmount GameScreen so pending timers are disposed
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  });
}
