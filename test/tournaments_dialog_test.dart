import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo/widgets/tournaments_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TournamentsDialog Widget Tests', () {
    testWidgets('TournamentsDialog renders all 3 tournament tiers and triggers join callback',
        (WidgetTester tester) async {
      String? selectedTournament;
      int? selectedPrize;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TournamentsDialog(
              onJoinTournament: (name, prize) {
                selectedTournament = name;
                selectedPrize = prize;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Title & Subtitle
      expect(find.text('LUDO TOURNAMENTS'), findsOneWidget);
      expect(find.text('Compete with champions & win mega prizes!'), findsOneWidget);

      // Verify 3 Tournament Tiers
      expect(find.text('GRAND CHAMPIONSHIP'), findsOneWidget);
      expect(find.text('KNOCKOUT BRACKET'), findsOneWidget);
      expect(find.text('50 COINS'), findsOneWidget);

      expect(find.text('DAILY KNOCKOUT'), findsOneWidget);
      expect(find.text('LIVE NOW'), findsOneWidget);
      expect(find.text('10 COINS'), findsOneWidget);

      expect(find.text('WEEKEND BLITZ'), findsOneWidget);
      expect(find.text('SPEED ARENA'), findsOneWidget);
      expect(find.text('25 COINS'), findsOneWidget);

      // Tap REGISTER on Grand Championship
      await tester.tap(find.text('REGISTER'));
      await tester.pumpAndSettle();

      expect(selectedTournament, 'Grand Championship');
      expect(selectedPrize, 50);
    });

    testWidgets('Tapping PLAY NOW triggers Daily Knockout join callback',
        (WidgetTester tester) async {
      String? selectedTournament;
      int? selectedPrize;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TournamentsDialog(
              onJoinTournament: (name, prize) {
                selectedTournament = name;
                selectedPrize = prize;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('PLAY NOW'));
      await tester.pumpAndSettle();

      expect(selectedTournament, 'Daily Knockout');
      expect(selectedPrize, 10);
    });

    testWidgets('Tapping ENTER triggers Weekend Blitz join callback',
        (WidgetTester tester) async {
      String? selectedTournament;
      int? selectedPrize;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TournamentsDialog(
              onJoinTournament: (name, prize) {
                selectedTournament = name;
                selectedPrize = prize;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('ENTER'));
      await tester.pumpAndSettle();

      expect(selectedTournament, 'Weekend Blitz');
      expect(selectedPrize, 25);
    });

    testWidgets('Tapping close button dismisses dialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const TournamentsDialog(),
                  );
                },
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();

      expect(find.byType(TournamentsDialog), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(TournamentsDialog), findsNothing);
    });

    testWidgets('TournamentsDialog renders on 320x568 small phone without overflow',
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
            body: TournamentsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('LUDO TOURNAMENTS'), findsOneWidget);
      expect(find.text('GRAND CHAMPIONSHIP'), findsOneWidget);
      expect(find.text('DAILY KNOCKOUT'), findsOneWidget);
      expect(find.text('WEEKEND BLITZ'), findsOneWidget);
    });
  });
}
