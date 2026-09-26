import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo/models/game_state.dart';
import 'package:ludo/widgets/player_selection_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestWidget({Size? physicalSize, EdgeInsets viewInsets = EdgeInsets.zero}) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                showDialog<GameMode>(
                  context: context,
                  barrierDismissible: true,
                  builder: (_) => const PlayerSelectionDialog(),
                );
              },
              child: const Text('Open Friends Dialog'),
            ),
          ),
        ),
      ),
    );
  }

  // 1. Small Android Phone (320x568)
  testWidgets('Test 1: Small Android phone (320x568) portrait without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget());
    await tester.tap(find.text('Open Friends Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Play with Friends'), findsOneWidget);
    expect(find.text('SELECT PLAYERS'), findsOneWidget);
    expect(find.text('SELECT LOBBY'), findsOneWidget);
  });

  // 2. Normal Android Phone (360x640)
  testWidgets('Test 2: Normal Android phone (360x640) portrait without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget());
    await tester.tap(find.text('Open Friends Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Play with Friends'), findsOneWidget);
    expect(find.text('SELECT PLAYERS'), findsOneWidget);
  });

  // 3. Large Android Phone (412x915)
  testWidgets('Test 3: Large Android phone (412x915) portrait without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget());
    await tester.tap(find.text('Open Friends Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Play with Friends'), findsOneWidget);
  });

  // 4. Landscape Mode (640x360 & 800x360)
  testWidgets('Test 4: Landscape mode (640x360) without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget());
    await tester.tap(find.text('Open Friends Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Play with Friends'), findsOneWidget);
  });

  // 5. 2-Player Selection & 4-Player Selection
  testWidgets('Test 5: Player count selection (2P and 4P)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget());
    await tester.tap(find.text('Open Friends Dialog'));
    await tester.pumpAndSettle();

    // Tap 4 Friends
    await tester.tap(find.byKey(const Key('option_4')));
    await tester.pumpAndSettle();
    expect(find.text('Start 4-Player Game'), findsOneWidget);

    // Tap 2 Friends
    await tester.tap(find.byKey(const Key('option_2')));
    await tester.pumpAndSettle();
    expect(find.text('Start 2-Player Game'), findsOneWidget);
  });

  // 6. Create Room & Join Room tabs
  testWidgets('Test 6: Create Room and Join Room switching',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget());
    await tester.tap(find.text('Open Friends Dialog'));
    await tester.pumpAndSettle();

    // Switch to Join tab
    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();
    expect(find.text('JOIN LOBBY'), findsOneWidget);
    expect(find.text('Join Room'), findsOneWidget);

    // Switch back to Create tab
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(find.text('SELECT LOBBY'), findsOneWidget);
  });

  // 7. Keyboard Open during Join Room (viewInsets.bottom)
  testWidgets('Test 7: Keyboard open during Join Room without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
    });

    await tester.pumpWidget(createTestWidget());
    await tester.tap(find.text('Open Friends Dialog'));
    await tester.pumpAndSettle();

    // Switch to Join tab
    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    // Simulate keyboard opening
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();

    expect(find.text('JOIN LOBBY'), findsOneWidget);
    // Enter room code in TextField
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();
    expect(find.text('123456'), findsOneWidget);
  });
}
