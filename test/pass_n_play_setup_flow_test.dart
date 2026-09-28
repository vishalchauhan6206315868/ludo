import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo/logic/ludo_game_controller.dart';
import 'package:ludo/screens/game_screen.dart';
import 'package:ludo/screens/home_menu_screen.dart';
import 'package:ludo/screens/pass_n_play_setup_screen.dart';
import 'package:ludo/screens/pass_n_play_player_setup_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LudoGameController.isFastBotForTesting = true;
  });

  group('Pass N Play Setup Screen (Select Players) Tests', () {
    testWidgets('Renders header, SELECT PLAYERS, 3 options, and NEXT button',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: PassNPlaySetupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PASS N PLAY'), findsOneWidget);
      expect(find.text('SELECT PLAYERS'), findsOneWidget);
      expect(find.text('2 PLAYERS'), findsOneWidget);
      expect(find.text('3 PLAYERS'), findsOneWidget);
      expect(find.text('4 PLAYERS'), findsOneWidget);
      expect(find.byKey(const Key('next_button')), findsOneWidget);
    });

    testWidgets('Tapping player cards changes selection',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: PassNPlaySetupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 3 Players
      await tester.tap(find.byKey(const Key('select_card_3p')));
      await tester.pumpAndSettle();

      // Tap 4 Players
      await tester.tap(find.byKey(const Key('select_card_4p')));
      await tester.pumpAndSettle();

      // Tap 2 Players
      await tester.tap(find.byKey(const Key('select_card_2p')));
      await tester.pumpAndSettle();
    });

    testWidgets('Help dialog opens and closes', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: PassNPlaySetupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('pass_n_play_help_button')));
      await tester.pumpAndSettle();

      expect(find.text('Pass N Play Rules'), findsOneWidget);
      await tester.tap(find.text('GOT IT'));
      await tester.pumpAndSettle();

      expect(find.text('Pass N Play Rules'), findsNothing);
    });

    testWidgets('Tapping NEXT navigates to Player Setup screen with selected count',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: PassNPlaySetupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Select 3 players
      await tester.tap(find.byKey(const Key('select_card_3p')));
      await tester.pumpAndSettle();

      // Tap Next
      await tester.tap(find.byKey(const Key('next_button')));
      await tester.pumpAndSettle();

      expect(find.byType(PassNPlayPlayerSetupScreen), findsOneWidget);
      expect(find.text('PLAYER CONFIGURATION'), findsOneWidget);
      expect(find.text('PLAYER 1'), findsOneWidget);
      expect(find.text('PLAYER 2'), findsOneWidget);
      expect(find.text('PLAYER 3'), findsOneWidget);
      // Player 4 must NOT be present
      expect(find.text('PLAYER 4'), findsNothing);
    });
  });

  group('Pass N Play Player Setup Screen Tests', () {
    testWidgets('2-Player setup shows exactly 2 player cards with Red and Yellow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: PassNPlayPlayerSetupScreen(playerCount: 2),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PLAYER 1'), findsOneWidget);
      expect(find.text('RED'), findsOneWidget);
      expect(find.text('PLAYER 2'), findsOneWidget);
      expect(find.text('YELLOW'), findsOneWidget);
      expect(find.text('PLAYER 3'), findsNothing);
      expect(find.text('PLAYER 4'), findsNothing);
    });

    testWidgets('4-Player setup shows 4 player cards with Red, Green, Yellow, Blue',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: PassNPlayPlayerSetupScreen(playerCount: 4),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PLAYER 1'), findsOneWidget);
      expect(find.text('RED'), findsOneWidget);
      expect(find.text('PLAYER 2'), findsOneWidget);
      expect(find.text('GREEN'), findsOneWidget);
      expect(find.text('PLAYER 3'), findsOneWidget);
      expect(find.text('YELLOW'), findsOneWidget);
      expect(find.text('PLAYER 4'), findsOneWidget);
      expect(find.text('BLUE'), findsOneWidget);
    });

    testWidgets('Custom player names are passed and START GAME launches GameScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: PassNPlayPlayerSetupScreen(playerCount: 2),
        ),
      );
      await tester.pumpAndSettle();

      // Enter custom name for player 1
      await tester.enterText(
          find.byKey(const Key('player_name_input_0')), 'Iron Man');
      await tester.enterText(
          find.byKey(const Key('player_name_input_1')), 'Spider Man');
      await tester.pumpAndSettle();

      // Tap Start Game
      await tester.tap(find.byKey(const Key('start_game_button')));
      await tester.pumpAndSettle();

      // Verify GameScreen is pushed with Pass N Play mode
      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.text('Iron Man'), findsWidgets);
      expect(find.text('Spider Man'), findsWidgets);
    });

    testWidgets('Back button navigates back cleanly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: PassNPlaySetupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap NEXT to go to Player Setup
      await tester.tap(find.byKey(const Key('next_button')));
      await tester.pumpAndSettle();
      expect(find.byType(PassNPlayPlayerSetupScreen), findsOneWidget);

      // Tap back button
      await tester.tap(find.byKey(const Key('player_setup_back_button')));
      await tester.pumpAndSettle();
      expect(find.byType(PassNPlaySetupScreen), findsOneWidget);
      expect(find.byType(PassNPlayPlayerSetupScreen), findsNothing);
    });
  });

  group('Home Menu to Pass N Play Navigation Test', () {
    testWidgets('Tapping Pass N Play card on Home Menu opens PassNPlaySetupScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeMenuScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Pass N Play card
      await tester.tap(find.byKey(const Key('pass_n_play_card')));
      await tester.pumpAndSettle();

      expect(find.byType(PassNPlaySetupScreen), findsOneWidget);
      expect(find.text('SELECT PLAYERS'), findsOneWidget);
    });
  });

  group('Responsive Layout Tests', () {
    testWidgets('PassNPlaySetupScreen renders on 320x568 small phone without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: PassNPlaySetupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('SELECT PLAYERS'), findsOneWidget);
    });

    testWidgets('PassNPlayPlayerSetupScreen renders on 320x568 small phone without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: PassNPlayPlayerSetupScreen(playerCount: 4),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('PLAYER CONFIGURATION'), findsOneWidget);
    });
  });
}
