import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo/widgets/game_exit_dialog.dart';

void main() {
  group('GameExitDialog Widget Tests', () {
    testWidgets('Renders default exit dialog with title, message, and action buttons',
        (WidgetTester tester) async {
      bool? confirmed;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog<bool>(
                    context: context,
                    builder: (ctx) => GameExitDialog(
                      onCancel: () {
                        confirmed = false;
                        Navigator.pop(ctx, false);
                      },
                      onConfirm: () {
                        confirmed = true;
                        Navigator.pop(ctx, true);
                      },
                    ),
                  );
                },
                child: const Text('OPEN DIALOG'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('OPEN DIALOG'));
      await tester.pumpAndSettle();

      // Verify title & messages
      expect(find.text('Exit to Main Menu?'), findsOneWidget);
      expect(find.textContaining('saved automatically'), findsOneWidget);
      expect(find.text('Continue Playing'), findsOneWidget);
      expect(find.text('Save & Exit'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Tap Continue Playing
      await tester.tap(find.text('Continue Playing'));
      await tester.pumpAndSettle();

      expect(confirmed, isFalse);
      expect(find.byType(GameExitDialog), findsNothing);
    });

    testWidgets('Tapping Save & Exit confirms exit', (WidgetTester tester) async {
      bool? confirmed;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog<bool>(
                    context: context,
                    builder: (ctx) => GameExitDialog(
                      onCancel: () {
                        confirmed = false;
                        Navigator.pop(ctx, false);
                      },
                      onConfirm: () {
                        confirmed = true;
                        Navigator.pop(ctx, true);
                      },
                    ),
                  );
                },
                child: const Text('OPEN DIALOG'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN DIALOG'));
      await tester.pumpAndSettle();

      // Tap Save & Exit
      await tester.tap(find.text('Save & Exit'));
      await tester.pumpAndSettle();

      expect(confirmed, isTrue);
      expect(find.byType(GameExitDialog), findsNothing);
    });

    testWidgets('Tapping X close button dismisses dialog with cancel',
        (WidgetTester tester) async {
      bool? confirmed;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog<bool>(
                    context: context,
                    builder: (ctx) => GameExitDialog(
                      onCancel: () {
                        confirmed = false;
                        Navigator.pop(ctx, false);
                      },
                      onConfirm: () {
                        confirmed = true;
                        Navigator.pop(ctx, true);
                      },
                    ),
                  );
                },
                child: const Text('OPEN DIALOG'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN DIALOG'));
      await tester.pumpAndSettle();

      // Tap X button
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(confirmed, isFalse);
      expect(find.byType(GameExitDialog), findsNothing);
    });

    testWidgets('Supports custom parameters for Pass N Play mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog<bool>(
                    context: context,
                    builder: (ctx) => const GameExitDialog(
                      title: "Exit Game?",
                      message:
                          "Are you sure you want to exit the current Pass N Play match? Your progress will be saved.",
                      highlightText: "Your progress will be saved",
                      cancelText: "CANCEL",
                      confirmText: "EXIT",
                    ),
                  );
                },
                child: const Text('OPEN DIALOG'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN DIALOG'));
      await tester.pumpAndSettle();

      expect(find.text('Exit Game?'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);
      expect(find.text('EXIT'), findsOneWidget);
      expect(find.textContaining('Your progress will be saved'), findsOneWidget);
    });

    testWidgets('Renders on 320x568 small phone without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GameExitDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Exit to Main Menu?'), findsOneWidget);
      expect(find.text('Continue Playing'), findsOneWidget);
      expect(find.text('Save & Exit'), findsOneWidget);
    });
  });
}
