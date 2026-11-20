import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo/main.dart';
import 'package:ludo/models/game_state.dart';
import 'package:ludo/screens/home_menu_screen.dart';
import 'package:ludo/widgets/player_selection_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('LudoApp splash screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LudoApp());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('LUDO SUPREME'), findsOneWidget);
    expect(find.text('PLAY • ROLL • WIN'), findsOneWidget);
    expect(find.text('POWERED BY'), findsOneWidget);
    expect(find.text('Loading...'), findsOneWidget);

    // Fast-forward past the 6-second animated splash choreography + route transition (850ms)
    await tester.pump(const Duration(milliseconds: 5650));
    await tester.pump(const Duration(milliseconds: 950));
    await tester.pumpAndSettle();

    // After splash on first run, it navigates to LoginScreen
    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets('Home menu shows Play with Friends and removes separate 2P/4P buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeMenuScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify "PLAY WITH FRIENDS" and "PASS N PLAY" and "PLAY VS COMPUTER" are present
    expect(find.text('PLAY WITH FRIENDS'), findsOneWidget);
    expect(find.text('PASS N PLAY'), findsOneWidget);
    expect(find.text('PLAY VS COMPUTER'), findsOneWidget);

    // Verify separate 2-player and 4-player buttons are removed
    expect(find.text('2 Players Match'), findsNothing);
    expect(find.text('4 Players Classic'), findsNothing);
  });

  testWidgets('Tapping Play with Friends opens player count selection dialog',
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

    // Tap "PLAY WITH FRIENDS"
    await tester.tap(find.text('PLAY WITH FRIENDS'));
    await tester.pumpAndSettle();

    // Verify dialog content
    expect(find.text('How many friends want to play?'), findsOneWidget);
    expect(find.text('👥 2 Friends'), findsOneWidget);
    expect(find.text('👥 3 Friends'), findsOneWidget);
    expect(find.text('👥 4 Friends'), findsOneWidget);
    expect(find.text('Start 2-Player Game'), findsOneWidget);

    // Tap "3 Friends"
    await tester.tap(find.byKey(const Key('option_3')));
    await tester.pumpAndSettle();
    expect(find.text('Start 3-Player Game'), findsOneWidget);

    // Tap "4 Friends"
    await tester.tap(find.byKey(const Key('option_4')));
    await tester.pumpAndSettle();
    expect(find.text('Start 4-Player Game'), findsOneWidget);

    // Back / Cancel closes dialog
    await tester.tap(find.byTooltip('Back to Home'));
    await tester.pumpAndSettle();

    expect(find.text('How many friends want to play?'), findsNothing);
    expect(find.text('PLAY WITH FRIENDS'), findsOneWidget);
  });

  testWidgets('PlayerSelectionDialog returns correct GameMode for each option',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    GameMode? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showDialog<GameMode>(
                context: context,
                builder: (_) => const PlayerSelectionDialog(),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    // 1. Test 2 Friends (default)
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start_game_button')));
    await tester.pumpAndSettle();
    expect(result, GameMode.twoPlayer);

    // 2. Test 3 Friends
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('option_3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start_game_button')));
    await tester.pumpAndSettle();
    expect(result, GameMode.threePlayer);

    // 3. Test 4 Friends
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('option_4')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('start_game_button')));
    await tester.pumpAndSettle();
    expect(result, GameMode.fourPlayer);
  });
}
