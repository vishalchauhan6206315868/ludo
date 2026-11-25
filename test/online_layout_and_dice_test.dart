import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo/models/game_state.dart';
import 'package:ludo/constants/ludo_path.dart';
import 'package:ludo/screens/game_screen.dart';
import 'package:ludo/widgets/board/ludo_board_widget.dart';
import 'package:ludo/widgets/dice/animated_dice.dart';
import 'package:ludo/widgets/player_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Online 2-Player Match Layout and Dice Tests', () {
    testWidgets('Device A (Seat 0, Red): Opponent (Green) at TOP-LEFT, You (Red) at BOTTOM-RIGHT',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Device A: mySeatIndex = 0 (Red)
      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(
            mode: GameMode.twoPlayer,
            isOnlineMatch: true,
            mySeatIndex: 0,
            sessionId: 'test-session-dev-a',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final boardFinder = find.byType(LudoBoardWidget);
      expect(boardFinder, findsOneWidget);

      final opponentCardFinder = find.byWidgetPredicate(
        (w) => w is PlayerCard && w.player.color == PlayerColor.green,
      );
      final myCardFinder = find.byWidgetPredicate(
        (w) => w is PlayerCard && w.player.color == PlayerColor.red,
      );

      expect(opponentCardFinder, findsOneWidget);
      expect(myCardFinder, findsOneWidget);

      final oppTopLeft = tester.getTopLeft(opponentCardFinder);
      final myTopLeft = tester.getTopLeft(myCardFinder);
      final boardTopLeft = tester.getTopLeft(boardFinder);
      final boardBottomRight = tester.getBottomRight(boardFinder);

      // Opponent (Green) is above the board (Top) and to the left
      expect(oppTopLeft.dy, lessThan(boardTopLeft.dy),
          reason: 'Opponent card must be at the TOP above board');
      expect(oppTopLeft.dx, lessThan(390 / 2),
          reason: 'Opponent card must be aligned to the LEFT');

      // You (Red) is below the board (Bottom) and to the right
      expect(myTopLeft.dy, greaterThan(boardBottomRight.dy),
          reason: 'My player card must be at the BOTTOM below board');
      expect(myTopLeft.dx, greaterThan(100),
          reason: 'My player card must be aligned to the RIGHT');

      // Both players have their 3D dice visible at all times
      final diceFinders = find.byType(AnimatedDice);
      expect(diceFinders, findsNWidgets(2));

      // At start (Turn = Seat 0 / Red): My dice can roll, opponent cannot
      final diceWidgets = tester.widgetList<AnimatedDice>(diceFinders).toList();
      final myDice = diceWidgets.firstWhere((d) => d.canRoll == true);
      final oppDice = diceWidgets.firstWhere((d) => d.canRoll == false);
      expect(myDice.canRoll, isTrue);
      expect(oppDice.canRoll, isFalse);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('Device B (Seat 1, Green): Opponent (Red) at TOP-LEFT, You (Green) at BOTTOM-RIGHT',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Device B: mySeatIndex = 1 (Green)
      await tester.pumpWidget(
        const MaterialApp(
          home: GameScreen(
            mode: GameMode.twoPlayer,
            isOnlineMatch: true,
            mySeatIndex: 1,
            sessionId: 'test-session-dev-b',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final boardFinder = find.byType(LudoBoardWidget);
      expect(boardFinder, findsOneWidget);

      final opponentCardFinder = find.byWidgetPredicate(
        (w) => w is PlayerCard && w.player.color == PlayerColor.red,
      );
      final myCardFinder = find.byWidgetPredicate(
        (w) => w is PlayerCard && w.player.color == PlayerColor.green,
      );

      expect(opponentCardFinder, findsOneWidget);
      expect(myCardFinder, findsOneWidget);

      final oppTopLeft = tester.getTopLeft(opponentCardFinder);
      final myTopLeft = tester.getTopLeft(myCardFinder);
      final boardTopLeft = tester.getTopLeft(boardFinder);
      final boardBottomRight = tester.getBottomRight(boardFinder);

      // Opponent (Red) is above the board (Top) and to the left
      expect(oppTopLeft.dy, lessThan(boardTopLeft.dy),
          reason: 'Opponent card must be at the TOP above board');

      // You (Green) is below the board (Bottom) and to the right
      expect(myTopLeft.dy, greaterThan(boardBottomRight.dy),
          reason: 'My player card must be at the BOTTOM below board');

      // Both players have their 3D dice visible at all times
      final diceFinders = find.byType(AnimatedDice);
      expect(diceFinders, findsNWidgets(2));

      // At start (Turn = Seat 0 / Red): On Device B, Red is opponent, so neither can be rolled by Device B
      final diceWidgets = tester.widgetList<AnimatedDice>(diceFinders).toList();
      for (final d in diceWidgets) {
        expect(d.canRoll, isFalse, reason: 'Device B cannot roll during Red turn');
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  });
}
