import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo/widgets/celebration/login_fireworks_overlay.dart';

void main() {
  group('Login Fireworks Celebration Overlay Tests', () {
    testWidgets('Renders Diwali fireworks canvas, LOGIN SUCCESSFUL badge and user name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginFireworksOverlay(
              playerName: 'Vishal',
              onComplete: () {},
            ),
          ),
        ),
      );

      // Verify custom fireworks painter is in the tree
      expect(find.byType(CustomPaint), findsWidgets);

      // Advance frames so badge scale/fade controller finishes
      await tester.pump(const Duration(milliseconds: 600));

      // Verify "LOGIN SUCCESSFUL!" header
      expect(find.text('LOGIN SUCCESSFUL!'), findsOneWidget);

      // Verify Player Name in celebration banner
      expect(find.text('Welcome back, Vishal! ✨'), findsOneWidget);

      // Verify tap-to-continue hint
      expect(find.text('Tap anywhere to enter'), findsOneWidget);

      // Finish animation duration so no frames are pending
      await tester.pump(const Duration(milliseconds: 2500));
    });

    testWidgets('Tapping anywhere triggers onComplete callback', (tester) async {
      bool completed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoginFireworksOverlay(
              playerName: 'Player 1',
              onComplete: () {
                completed = true;
              },
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(completed, isFalse);

      // Tap anywhere on the full-screen overlay
      await tester.tap(find.byType(LoginFireworksOverlay));
      await tester.pump();

      expect(completed, isTrue);

      // Finish animation duration so no frames are pending
      await tester.pump(const Duration(milliseconds: 2500));
    });
  });
}

