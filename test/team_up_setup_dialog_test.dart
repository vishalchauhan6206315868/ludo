import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo/widgets/team_up_setup_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TeamUpSetupDialog Tests', () {
    testWidgets('Renders all elements: Header, Mode tabs, Team A & B cards, Rules, and Start button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TeamUpSetupDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header
      expect(find.text('TEAM UP (2 VS 2)'), findsOneWidget);
      expect(find.text('Offline Duo Cooperative Battles'), findsOneWidget);

      // Mode Selector Tabs
      expect(find.text("Pass 'N' Play"), findsOneWidget);
      expect(find.text("Vs Computer"), findsOneWidget);

      // Team Cards & VS Medallion
      expect(find.text('TEAM A'), findsOneWidget);
      expect(find.text('TEAM B'), findsOneWidget);
      expect(find.text('VS'), findsOneWidget);

      // Rules Box
      expect(find.text('2v2 TEAM UP RULES'), findsOneWidget);

      // Action Button
      expect(find.text('START 2V2 MATCH'), findsOneWidget);
    });

    testWidgets('Switching to Vs Computer updates player names appropriately',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TeamUpSetupDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially Pass 'N' Play default
      expect(find.text('Player 1 (Red)'), findsOneWidget);

      // Tap Vs Computer
      await tester.tap(find.text('Vs Computer'));
      await tester.pumpAndSettle();

      // Expect Vs Computer defaults
      expect(find.text('You (Red)'), findsOneWidget);
      expect(find.text('Bot Ally (Yellow)'), findsOneWidget);
    });

    testWidgets('Renders cleanly on small mobile screen (320x568) without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TeamUpSetupDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('TEAM UP (2 VS 2)'), findsOneWidget);
      expect(find.text('START 2V2 MATCH'), findsOneWidget);
    });
  });
}
