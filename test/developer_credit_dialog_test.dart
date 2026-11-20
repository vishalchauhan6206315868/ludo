import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo/widgets/developer_credit_dialog.dart';

void main() {
  group('Developer Credit Feature Tests', () {
    testWidgets('DeveloperCreditDialog renders required credit text and OK button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DeveloperCreditDialog(),
          ),
        ),
      );

      // Verify "Developed by" text is present
      expect(find.text("Developed by"), findsOneWidget);

      // Verify exact developer name "Vishal Chauhan"
      expect(find.text("Vishal Chauhan"), findsOneWidget);

      // Verify DEVELOPER badge is present
      expect(find.text("DEVELOPER"), findsOneWidget);

      // Verify OK button exists
      expect(find.text("OK"), findsOneWidget);

      // Verify terminal/developer icon is rendered
      expect(find.byIcon(Icons.terminal_rounded), findsOneWidget);
    });

    testWidgets('Tapping OK button dismisses DeveloperCreditDialog', (tester) async {
      bool dialogPopped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (_) => const DeveloperCreditDialog(),
                  );
                  dialogPopped = true;
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      // Tap to open dialog
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Vishal Chauhan'), findsOneWidget);
      expect(dialogPopped, isFalse);

      // Tap OK button
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Vishal Chauhan'), findsNothing);
      expect(dialogPopped, isTrue);
    });
  });
}

