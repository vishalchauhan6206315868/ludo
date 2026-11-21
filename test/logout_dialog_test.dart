import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo/widgets/logout_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LogoutDialog 3D Royal Gaming UI Tests', () {
    testWidgets('renders Exit / Logout 3D title, question text, and action buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: LogoutDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title parts
      expect(find.text('Exit '), findsOneWidget);
      expect(find.text('/ '), findsOneWidget);
      expect(find.text('Logout'), findsWidgets); // header title and button

      // Verify question bubble mark
      expect(find.text('?'), findsOneWidget);

      // Verify confirmation rich text elements
      expect(find.textContaining('Are you sure you want to'), findsOneWidget);
      expect(find.textContaining('Ludo Supreme'), findsOneWidget);

      // Verify Cancel and Logout 3D Buttons
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.logout_rounded), findsWidgets);
    });

    testWidgets('tapping Cancel button dismisses dialog returning false', (tester) async {
      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await showDialog<bool>(
                    context: context,
                    builder: (_) => const LogoutDialog(),
                  );
                },
                child: const Text('Open Logout Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open Dialog
      await tester.tap(find.text('Open Logout Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(LogoutDialog), findsOneWidget);

      // Tap Cancel button
      await tester.tap(find.byKey(const Key('logout_dialog_cancel_button')));
      await tester.pumpAndSettle();

      expect(find.byType(LogoutDialog), findsNothing);
      expect(dialogResult, isFalse);
    });

    testWidgets('tapping Logout button dismisses dialog returning true', (tester) async {
      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await showDialog<bool>(
                    context: context,
                    builder: (_) => const LogoutDialog(),
                  );
                },
                child: const Text('Open Logout Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open Dialog
      await tester.tap(find.text('Open Logout Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(LogoutDialog), findsOneWidget);

      // Tap Logout pill button
      await tester.tap(find.byKey(const Key('logout_dialog_confirm_button')));
      await tester.pumpAndSettle();

      expect(find.byType(LogoutDialog), findsNothing);
      expect(dialogResult, isTrue);
    });
  });
}
