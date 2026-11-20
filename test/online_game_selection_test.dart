import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo/models/online_game_mode.dart';
import 'package:ludo/screens/home_menu_screen.dart';
import 'package:ludo/screens/online/online_game_selection_screen.dart';
import 'package:ludo/screens/online/online_matchmaking_screen.dart';
import 'package:ludo/widgets/online/online_game_mode_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnlineGameMode Model Tests', () {
    test('Default modes contains 5 modes in specified order', () {
      final modes = OnlineGameMode.defaultModes;
      expect(modes.length, equals(5));
      expect(modes[0].title, equals('CLASSIC'));
      expect(modes[1].title, equals('1 KILL WIN'));
      expect(modes[2].title, equals('QUICK'));
      expect(modes[3].title, equals('POPULAR'));
      expect(modes[4].title, equals('MASK'));
    });

    test('Player count formatting works correctly with commas', () {
      final classic = OnlineGameMode.defaultModes[0];
      expect(classic.formattedPlayerCount, equals('14,250'));

      const smallCountMode = OnlineGameMode(
        id: 'test',
        title: 'TEST',
        description: 'test',
        playerCount: 450,
        icon: Icons.star,
        modeType: OnlineModeType.classic,
        gradientColors: [Colors.black, Colors.white],
        accentColor: Colors.blue,
        glowColor: Colors.blue,
        badgeText: 'TEST',
      );
      expect(smallCountMode.formattedPlayerCount, equals('450'));
    });
  });

  group('OnlineGameSelectionScreen Widget & Interaction Tests', () {
    testWidgets('Renders header, all 5 game modes, and Next button',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: OnlineGameSelectionScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('SELECT GAME'), findsOneWidget);
      expect(find.byKey(const Key('online_game_selection_back_button')), findsOneWidget);
      expect(find.byKey(const Key('online_game_selection_help_button')), findsOneWidget);
      expect(find.text('3600'), findsOneWidget); // Coins badge

      // Verify all 5 modes
      expect(find.text('CLASSIC'), findsOneWidget);
      expect(find.text('1 KILL WIN'), findsOneWidget);
      expect(find.text('QUICK'), findsOneWidget);
      expect(find.text('POPULAR'), findsOneWidget);
      expect(find.text('MASK'), findsOneWidget);

      // Verify Player counts
      expect(find.text('Players: 14,250'), findsOneWidget);
      expect(find.text('Players: 8,920'), findsOneWidget);
      expect(find.text('Players: 19,840'), findsOneWidget);
      expect(find.text('Players: 25,310'), findsOneWidget);
      expect(find.text('Players: 4,150'), findsOneWidget);

      // Verify NEXT button
      expect(find.text('NEXT'), findsOneWidget);
      expect(find.byKey(const Key('online_game_selection_next_button')), findsOneWidget);
    });

    testWidgets('CLASSIC is selected by default and displays checkmark',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: OnlineGameSelectionScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Only 1 checkmark should be visible initially (on CLASSIC)
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Verify CLASSIC card has isSelected = true
      final classicCard = tester.widget<OnlineGameModeCard>(
        find.byWidgetPredicate(
          (w) => w is OnlineGameModeCard && w.mode.id == 'classic',
        ),
      );
      expect(classicCard.isSelected, isTrue);

      final oneKillCard = tester.widget<OnlineGameModeCard>(
        find.byWidgetPredicate(
          (w) => w is OnlineGameModeCard && w.mode.id == 'one_kill_win',
        ),
      );
      expect(oneKillCard.isSelected, isFalse);
    });

    testWidgets('Tapping 1 KILL WIN switches selection smoothly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: OnlineGameSelectionScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 1 KILL WIN card
      await tester.tap(find.byKey(const Key('online_mode_card_one_kill_win')));
      await tester.pumpAndSettle();

      // Checkmark still 1 instance
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      final classicCard = tester.widget<OnlineGameModeCard>(
        find.byWidgetPredicate(
          (w) => w is OnlineGameModeCard && w.mode.id == 'classic',
        ),
      );
      expect(classicCard.isSelected, isFalse);

      final oneKillCard = tester.widget<OnlineGameModeCard>(
        find.byWidgetPredicate(
          (w) => w is OnlineGameModeCard && w.mode.id == 'one_kill_win',
        ),
      );
      expect(oneKillCard.isSelected, isTrue);
    });

    testWidgets('Tapping Help button opens Online Game Modes dialog',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: OnlineGameSelectionScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('online_game_selection_help_button')));
      await tester.pumpAndSettle();

      expect(find.text('Online Game Modes'), findsOneWidget);
      expect(find.text('UNDERSTOOD'), findsOneWidget);

      await tester.tap(find.text('UNDERSTOOD'));
      await tester.pumpAndSettle();

      expect(find.text('Online Game Modes'), findsNothing);
    });

    testWidgets('Tapping NEXT navigates to OnlineMatchmakingScreen with selected mode',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: OnlineGameSelectionScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Select QUICK mode
      await tester.tap(find.byKey(const Key('online_mode_card_quick')));
      await tester.pumpAndSettle();

      // Tap NEXT
      await tester.tap(find.byKey(const Key('online_game_selection_next_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Verify OnlineMatchmakingScreen opened with QUICK mode
      expect(find.byType(OnlineMatchmakingScreen), findsOneWidget);
      expect(find.text('SEARCHING FOR PLAYERS'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(OnlineMatchmakingScreen),
          matching: find.text('QUICK'),
        ),
        findsOneWidget,
      );

      // Verify cancel matchmaking pops back
      await tester.tap(find.byKey(const Key('cancel_matchmaking_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(OnlineGameSelectionScreen), findsOneWidget);
    });

    testWidgets('Renders without overflow on small Android device (320x568)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: OnlineGameSelectionScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('SELECT GAME'), findsOneWidget);
      expect(find.text('NEXT'), findsOneWidget);
    });

    testWidgets('Renders without overflow on large Android device (412x915)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: OnlineGameSelectionScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('SELECT GAME'), findsOneWidget);
    });
  });

  group('HomeMenuScreen to OnlineGameSelectionScreen Navigation Tests', () {
    testWidgets('Tapping ONLINE card on HomeMenuScreen opens OnlineGameSelectionScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeMenuScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure ONLINE card is visible and tap it
      final onlineCardFinder = find.byKey(const Key('online_card'));
      expect(onlineCardFinder, findsOneWidget);

      await tester.tap(onlineCardFinder);
      await tester.pumpAndSettle();

      // Verify OnlineGameSelectionScreen is shown
      expect(find.byType(OnlineGameSelectionScreen), findsOneWidget);
      expect(find.text('SELECT GAME'), findsOneWidget);

      // Verify back button works to return to HomeMenuScreen
      await tester.tap(find.byKey(const Key('online_game_selection_back_button')));
      await tester.pumpAndSettle();

      expect(find.byType(OnlineGameSelectionScreen), findsNothing);
      expect(find.byType(HomeMenuScreen), findsOneWidget);
    });
  });
}
