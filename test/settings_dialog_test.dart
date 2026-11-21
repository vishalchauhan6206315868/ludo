import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo/services/sound_haptic_service.dart';
import 'package:ludo/widgets/settings_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SoundHapticService.isSoundEnabled = true;
    SoundHapticService.isHapticsEnabled = true;
  });

  group('SettingsDialog Royal 3D UI Tests', () {
    testWidgets('renders 3D Game Settings title, crown, and setting rows', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SettingsDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title parts
      expect(find.text('Game '), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Verify settings rows
      expect(find.text('Sound Effects'), findsOneWidget);
      expect(find.text('Audio feedback on rolls and moves'), findsOneWidget);
      expect(find.text('Haptic Feedback'), findsOneWidget);
      expect(find.text('Vibrations on captures & turns'), findsOneWidget);

      // Verify close icon and setting icons
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
      expect(find.byIcon(Icons.vibration_rounded), findsOneWidget);
    });

    testWidgets('toggles sound and haptic state on user tap', (tester) async {
      expect(SoundHapticService.isSoundEnabled, isTrue);
      expect(SoundHapticService.isHapticsEnabled, isTrue);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SettingsDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Sound Effects row
      await tester.tap(find.text('Sound Effects'));
      await tester.pumpAndSettle();
      expect(SoundHapticService.isSoundEnabled, isFalse);

      // Tap again to enable
      await tester.tap(find.text('Sound Effects'));
      await tester.pumpAndSettle();
      expect(SoundHapticService.isSoundEnabled, isTrue);

      // Tap Haptic Feedback row
      await tester.tap(find.text('Haptic Feedback'));
      await tester.pumpAndSettle();
      expect(SoundHapticService.isHapticsEnabled, isFalse);

      // Tap again to enable
      await tester.tap(find.text('Haptic Feedback'));
      await tester.pumpAndSettle();
      expect(SoundHapticService.isHapticsEnabled, isTrue);
    });

    testWidgets('close button pops the dialog', (tester) async {
      bool dialogClosed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const SettingsDialog(),
                  ).then((_) {
                    dialogClosed = true;
                  });
                },
                child: const Text('Open Settings'),
              ),
            ),
          ),
        ),
      );

      // Open Dialog
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsDialog), findsOneWidget);

      // Tap Circular Close Button
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsDialog), findsNothing);
      expect(dialogClosed, isTrue);
    });

    testWidgets('triggers restart match callback from dialog', (tester) async {
      bool restarted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => SettingsDialog(
                      onRestart: () => restarted = true,
                    ),
                  );
                },
                child: const Text('Open Settings'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Restart Match'), findsOneWidget);

      await tester.tap(find.text('Restart Match'));
      await tester.pumpAndSettle();

      expect(restarted, isTrue);
    });

    testWidgets('triggers quit to menu callback from dialog', (tester) async {
      bool exited = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => SettingsDialog(
                      onExitToMenu: () => exited = true,
                    ),
                  );
                },
                child: const Text('Open Settings'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Quit to Main Menu'), findsOneWidget);

      await tester.tap(find.text('Quit to Main Menu'));
      await tester.pumpAndSettle();

      expect(exited, isTrue);
    });
  });
}
