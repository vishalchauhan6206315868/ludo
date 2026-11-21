import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo/logic/ludo_game_controller.dart';
import 'package:ludo/screens/game_screen.dart';
import 'package:ludo/screens/home_menu_screen.dart';
import 'package:ludo/screens/pass_n_play_setup_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LudoGameController.isFastBotForTesting = true;
  });

  group('Home Dashboard 3 Game Mode Cards UI & Layout Tests', () {
    testWidgets('Renders all 6 game mode cards with correct titles and keys',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
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

      // Check all 6 card keys
      expect(find.byKey(const Key('tournaments_card')), findsOneWidget);
      expect(find.byKey(const Key('online_card')), findsOneWidget);
      expect(find.byKey(const Key('team_up_card')), findsOneWidget);
      expect(find.byKey(const Key('play_with_friends_card')), findsOneWidget);
      expect(find.byKey(const Key('play_vs_computer_card')), findsOneWidget);
      expect(find.byKey(const Key('pass_n_play_card')), findsOneWidget);

      // Check titles
      expect(find.text('TOURNAMENTS'), findsOneWidget);
      expect(find.text('ONLINE'), findsOneWidget);
      expect(find.text('TEAM UP'), findsOneWidget);
      expect(find.text('PLAY WITH FRIENDS'), findsOneWidget);
      expect(find.text('PLAY VS COMPUTER'), findsOneWidget);
      expect(find.text('PASS N PLAY'), findsOneWidget);

      // Verify legacy features ("Classic Mode", "2-4 Players", "Fun & Strategy") are removed
      expect(find.text('Classic Mode'), findsNothing);
      expect(find.text('2-4 Players'), findsNothing);
      expect(find.text('Fun & Strategy'), findsNothing);
    });

    testWidgets('Tapping TOURNAMENTS opens TournamentsDialog',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
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

      await tester.tap(find.byKey(const Key('tournaments_card')));
      await tester.pumpAndSettle();

      expect(find.text('LUDO TOURNAMENTS'), findsOneWidget);
      expect(find.text('GRAND CHAMPIONSHIP'), findsOneWidget);
      expect(find.text('DAILY KNOCKOUT'), findsOneWidget);
      expect(find.text('WEEKEND BLITZ'), findsOneWidget);
    });

    testWidgets('Tapping PLAY WITH FRIENDS opens player count selection dialog',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
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

      await tester.ensureVisible(find.byKey(const Key('play_with_friends_card')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('play_with_friends_card')));
      await tester.pumpAndSettle();

      expect(find.text('How many friends want to play?'), findsOneWidget);
      expect(find.text('👥 2 Friends'), findsOneWidget);
      expect(find.text('Start 2-Player Game'), findsOneWidget);
    });

    testWidgets('Tapping PASS N PLAY opens PassNPlaySetupScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
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

      await tester.ensureVisible(find.byKey(const Key('pass_n_play_card')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pass_n_play_card')));
      await tester.pumpAndSettle();

      expect(find.byType(PassNPlaySetupScreen), findsOneWidget);
      expect(find.text('SELECT PLAYERS'), findsOneWidget);
      expect(find.text('2 PLAYERS'), findsOneWidget);
      expect(find.text('3 PLAYERS'), findsOneWidget);
      expect(find.text('4 PLAYERS'), findsOneWidget);
    });

    testWidgets('Tapping PLAY VS COMPUTER opens GameScreen in vsComputer mode',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
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

      await tester.ensureVisible(find.byKey(const Key('play_vs_computer_card')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('play_vs_computer_card')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(GameScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('Small screen (320x568) renders without RenderFlex overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
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

      expect(tester.takeException(), isNull);
      expect(find.text('PLAY WITH FRIENDS'), findsOneWidget);
      expect(find.text('PASS N PLAY'), findsOneWidget);
      expect(find.text('PLAY VS COMPUTER'), findsOneWidget);
    });

    testWidgets('Tablet / Desktop screen (800x1200) renders centered and balanced',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
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

      expect(tester.takeException(), isNull);
      expect(find.text('PLAY WITH FRIENDS'), findsOneWidget);
      expect(find.text('PASS N PLAY'), findsOneWidget);
      expect(find.text('PLAY VS COMPUTER'), findsOneWidget);
    });
  });

  group('Modern 5-Section Navigation System Tests', () {
    testWidgets('Renders all 5 navigation tabs with HOME as default selected',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
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

      // Check all 5 navigation bar items
      expect(find.byKey(const Key('nav_item_home')), findsOneWidget);
      expect(find.byKey(const Key('nav_item_event')), findsOneWidget);
      expect(find.byKey(const Key('nav_item_adda')), findsOneWidget);
      expect(find.byKey(const Key('nav_item_inventory')), findsOneWidget);
      expect(find.byKey(const Key('nav_item_social')), findsOneWidget);

      // Verify HOME is default: game mode cards are visible
      expect(find.byKey(const Key('play_with_friends_card')), findsOneWidget);
      expect(find.byKey(const Key('pass_n_play_card')), findsOneWidget);
    });

    testWidgets('Navigating to EVENT displays events and tournament hub',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
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

      // Tap EVENT tab
      await tester.tap(find.byKey(const Key('nav_item_event')));
      await tester.pumpAndSettle();

      expect(find.text('LIVE EVENTS & REWARDS'), findsOneWidget);
      expect(find.text('REWARDS CENTER & HISTORY'), findsOneWidget);
      expect(find.byKey(const Key('play_with_friends_card')), findsNothing);
    });

    testWidgets('Navigating to ADDA displays community hangout area',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
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

      // Tap ADDA tab
      await tester.tap(find.byKey(const Key('nav_item_adda')));
      await tester.pumpAndSettle();

      expect(find.text('COMMUNITY ADDA'), findsOneWidget);
      expect(find.text('HOST AN ADDA TABLE'), findsOneWidget);
      expect(find.text('Join Adda by Code'), findsOneWidget);
    });

    testWidgets('Navigating to INVENTORY displays customization vault',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
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

      // Tap INVENTORY tab
      await tester.tap(find.byKey(const Key('nav_item_inventory')));
      await tester.pumpAndSettle();

      expect(find.text('PLAYER INVENTORY & VAULT'), findsOneWidget);
      expect(find.text('COLLECTIBLES'), findsOneWidget);
      expect(find.text('HONOR BADGES'), findsOneWidget);
      expect(find.text('VAULT ASSETS'), findsOneWidget);
    });

    testWidgets('Navigating to SOCIAL displays player profile and friends',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
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

      // Tap SOCIAL tab
      await tester.tap(find.byKey(const Key('nav_item_social')));
      await tester.pumpAndSettle();

      expect(find.text('SOCIAL & COMMUNITY'), findsOneWidget);
      expect(find.text('Challenge Friends'), findsOneWidget);
      expect(find.text('Create Friendly Room & Invite'), findsOneWidget);
    });

    testWidgets('Navigating back to HOME restores dashboard and gameplay entry points',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
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

      // Go to SOCIAL
      await tester.tap(find.byKey(const Key('nav_item_social')));
      await tester.pumpAndSettle();
      expect(find.text('SOCIAL & COMMUNITY'), findsOneWidget);

      // Return to HOME
      await tester.tap(find.byKey(const Key('nav_item_home')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('play_with_friends_card')), findsOneWidget);
      expect(find.byKey(const Key('pass_n_play_card')), findsOneWidget);
      expect(find.byKey(const Key('play_vs_computer_card')), findsOneWidget);
    });

    testWidgets('All 5 sections render on small screen (320x568) without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
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

      // Check all 5 tabs on small screen
      for (final tabKey in [
        'nav_item_home',
        'nav_item_event',
        'nav_item_adda',
        'nav_item_inventory',
        'nav_item_social',
      ]) {
        await tester.tap(find.byKey(Key(tabKey)));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Overflow in tab $tabKey');
      }
    });

    testWidgets('All 5 sections render on tablet screen (820x1180) in dynamic multi-column layout without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(820, 1180);
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

      // Check all 5 tabs on tablet screen
      for (final tabKey in [
        'nav_item_home',
        'nav_item_event',
        'nav_item_adda',
        'nav_item_inventory',
        'nav_item_social',
      ]) {
        await tester.tap(find.byKey(Key(tabKey)));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Tablet overflow in tab $tabKey');
      }
    });
  });
}
