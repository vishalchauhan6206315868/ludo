import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo/services/sound_haptic_service.dart';
import 'package:ludo/widgets/dice/animated_dice.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AnimatedDice Multi-stage Physical Throw Tests', () {
    test('generateDiceTrajectory produces 5 safe waypoints incorporating boardSize', () {
      final rng = Random(12345);
      final boardSize = const Size(360.0, 360.0);

      // Run multiple iterations to exercise different trajectory paths (normal, center, short)
      for (int i = 0; i < 20; i++) {
        final waypoints = generateDiceTrajectory(
          start: Offset.zero,
          finalPosition: const Offset(4.0, -145.0),
          boardSize: boardSize,
          isTopPlayer: false,
          random: rng,
        );

        expect(waypoints.length, 5);
        expect(waypoints.first, Offset.zero);
        expect(waypoints.last, const Offset(4.0, -145.0));

        // Check all waypoints are within safe lateral boundaries
        for (final pt in waypoints) {
          expect(pt.dx >= -40.0 && pt.dx <= 40.0, true,
              reason: 'Waypoint lateral offset must be safely bounded');
        }
      }
    });

    test('evaluateSpline smoothly interpolates Catmull-Rom curve without NaN', () {
      final waypoints = [
        Offset.zero,
        const Offset(-18.0, -35.0),
        const Offset(2.0, -75.0),
        const Offset(16.0, -115.0),
        const Offset(0.0, -145.0),
      ];

      for (double t = 0.0; t <= 1.0; t += 0.05) {
        final pos = DiceThrowPhysics.evaluateSpline(waypoints, t);
        expect(pos.dx.isNaN, false);
        expect(pos.dy.isNaN, false);
      }

      final startPos = DiceThrowPhysics.evaluateSpline(waypoints, 0.0);
      final endPos = DiceThrowPhysics.evaluateSpline(waypoints, 1.0);
      expect(startPos, Offset.zero);
      expect(endPos, const Offset(0.0, -145.0));
    });

    testWidgets('AnimatedDice renders with initial value and boardSize', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedDice(
                value: 6,
                canRoll: true,
                isHuman: true,
                boardSize: Size(360, 360),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedDice), findsOneWidget);
    });

    testWidgets('Human tap triggers onRoll and ignores multiple rapid taps while animating', (WidgetTester tester) async {
      int rollCallCount = 0;
      int? completedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedDice(
                value: 5,
                canRoll: true,
                isHuman: true,
                boardSize: const Size(360, 360),
                onRoll: () {
                  rollCallCount++;
                },
                onThrowComplete: (val) {
                  completedValue = val;
                },
              ),
            ),
          ),
        ),
      );

      // Initial tap
      await tester.tap(find.byType(AnimatedDice));
      await tester.pump(); // Start press animation

      expect(rollCallCount, 1, reason: 'First tap must trigger onRoll');

      // Attempt rapid second and third taps during animation
      await tester.tap(find.byType(AnimatedDice));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(AnimatedDice));
      await tester.pump(const Duration(milliseconds: 50));

      expect(rollCallCount, 1, reason: 'Rapid subsequent taps while animating must be ignored');

      // Advance past press phase (110ms) and throw flight (1350ms) + settle pause (380ms) + spring back (280ms)
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump(const Duration(milliseconds: 1400));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(completedValue, 5, reason: 'Animation must settle on the authoritative dice value');
    });

    testWidgets('SoundHapticService methods for dice throw execute without throwing exceptions', (WidgetTester tester) async {
      expect(() => SoundHapticService.onDiceTapPress(), returnsNormally);
      expect(() => SoundHapticService.onDiceThrow(), returnsNormally);
      expect(() => SoundHapticService.onDiceFirstLanding(), returnsNormally);
      expect(() => SoundHapticService.onDiceSettle(), returnsNormally);
    });
  });
}
