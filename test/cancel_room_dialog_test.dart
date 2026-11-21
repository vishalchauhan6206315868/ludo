import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo/widgets/cancel_room_dialog.dart';

void main() {
  group('CancelRoomDialog 3D Royal Confirmation Tests', () {
    testWidgets('Renders Cancel Room? dialog for host with all 3D components', (WidgetTester tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await CancelRoomDialog.show(context, isHost: true);
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify Title
      expect(find.text('Cancel '), findsOneWidget);
      expect(find.text('Room?'), findsOneWidget);

      // Verify Body Text with highlighted keywords
      expect(find.textContaining('Are you sure you want to cancel this room?'), findsOneWidget);
      expect(find.textContaining('removed'), findsOneWidget);
      expect(find.textContaining('refunded.'), findsOneWidget);

      // Verify Star Divider
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);

      // Verify Buttons
      expect(find.text('Stay'), findsOneWidget);
      expect(find.text('Cancel Room'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

      // Tap Stay and verify it returns false
      await tester.tap(find.text('Stay'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('Tapping Cancel Room returns true', (WidgetTester tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await CancelRoomDialog.show(context, isHost: true);
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel Room'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('Renders Leave Room? dialog for guest player', (WidgetTester tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await CancelRoomDialog.show(context, isHost: false);
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify Guest Title & Text
      expect(find.text('Leave '), findsOneWidget);
      expect(find.text('Room?'), findsOneWidget);
      expect(find.textContaining('Are you sure you want to leave this room?'), findsOneWidget);
      expect(find.text('Leave'), findsOneWidget);
      expect(find.text('Stay'), findsOneWidget);

      // Tap Leave and verify true
      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('Small screen (320x568) renders without RenderFlex overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  CancelRoomDialog.show(context, isHost: true);
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel '), findsOneWidget);
      expect(find.text('Stay'), findsOneWidget);
      expect(find.text('Cancel Room'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
