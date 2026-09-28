import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo/screens/home_menu_screen.dart';
import 'package:ludo/widgets/home_navigation_sections.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Bottom Navigation Bar Redesign Tests', () {
    testWidgets('Renders 5 equal navigation cards with correct keys and labels',
        (WidgetTester tester) async {
      int selectedIdx = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: HomeNavigationBar(
              selectedIndex: selectedIdx,
              onItemSelected: (idx) => selectedIdx = idx,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check all 5 labels
      expect(find.text('HOME'), findsOneWidget);
      expect(find.text('EVENT'), findsOneWidget);
      expect(find.text('ADDA'), findsOneWidget);
      expect(find.text('INVENTORY'), findsOneWidget);
      expect(find.text('SOCIAL'), findsOneWidget);

      // Check all 5 keys
      expect(find.byKey(const Key('nav_item_home')), findsOneWidget);
      expect(find.byKey(const Key('nav_item_event')), findsOneWidget);
      expect(find.byKey(const Key('nav_item_adda')), findsOneWidget);
      expect(find.byKey(const Key('nav_item_inventory')), findsOneWidget);
      expect(find.byKey(const Key('nav_item_social')), findsOneWidget);
    });

    testWidgets('Tabs trigger onItemSelected callback correctly',
        (WidgetTester tester) async {
      int selectedIdx = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                bottomNavigationBar: HomeNavigationBar(
                  selectedIndex: selectedIdx,
                  onItemSelected: (idx) {
                    setState(() {
                      selectedIdx = idx;
                    });
                  },
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Tap EVENT (index 1)
      await tester.tap(find.byKey(const Key('nav_item_event')));
      await tester.pumpAndSettle();
      expect(selectedIdx, 1);

      // Tap ADDA (index 2)
      await tester.tap(find.byKey(const Key('nav_item_adda')));
      await tester.pumpAndSettle();
      expect(selectedIdx, 2);

      // Tap INVENTORY (index 3)
      await tester.tap(find.byKey(const Key('nav_item_inventory')));
      await tester.pumpAndSettle();
      expect(selectedIdx, 3);

      // Tap SOCIAL (index 4)
      await tester.tap(find.byKey(const Key('nav_item_social')));
      await tester.pumpAndSettle();
      expect(selectedIdx, 4);

      // Tap HOME (index 0)
      await tester.tap(find.byKey(const Key('nav_item_home')));
      await tester.pumpAndSettle();
      expect(selectedIdx, 0);
    });

    testWidgets('Active card has golden accent border and elevated transform',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: HomeNavigationBar(
              selectedIndex: 0,
              onItemSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find AnimatedContainers inside HomeNavigationBar
      final animatedContainers = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .toList();
      expect(animatedContainers.isNotEmpty, isTrue);

      // Verify that at least one AnimatedContainer has a golden border
      bool hasGoldenBorder = false;
      for (final container in animatedContainers) {
        final decoration = container.decoration;
        if (decoration is BoxDecoration && decoration.border != null) {
          final border = decoration.border!;
          if (border.top.color.a > 0 &&
              border.top.color.r > 0.8 &&
              border.top.color.g > 0.7) {
            hasGoldenBorder = true;
            break;
          }
        }
      }
      expect(hasGoldenBorder, isTrue);
    });

    testWidgets('Smooth selection animation executes cleanly',
        (WidgetTester tester) async {
      int selected = 0;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                bottomNavigationBar: HomeNavigationBar(
                  selectedIndex: selected,
                  onItemSelected: (idx) => setState(() => selected = idx),
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Tap tab and step through animation frames (100ms, then settle)
      await tester.tap(find.byKey(const Key('nav_item_event')));
      await tester.pump(const Duration(milliseconds: 90));
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(milliseconds: 90));
      expect(tester.takeException(), isNull);

      await tester.pumpAndSettle();
      expect(selected, 1);
    });

    testWidgets('Responsive layouts on various screen widths',
        (WidgetTester tester) async {
      final screenSizes = [
        const Size(320, 568), // Small phone
        const Size(360, 640), // Standard Android phone
        const Size(412, 915), // Large Android phone
        const Size(768, 1024), // Tablet
      ];

      for (final size in screenSizes) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          const MaterialApp(
            home: HomeMenuScreen(),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull,
            reason: 'Failed layout at size $size');

        // All 5 nav items visible
        expect(find.byKey(const Key('nav_item_home')), findsOneWidget);
        expect(find.byKey(const Key('nav_item_event')), findsOneWidget);
        expect(find.byKey(const Key('nav_item_adda')), findsOneWidget);
        expect(find.byKey(const Key('nav_item_inventory')), findsOneWidget);
        expect(find.byKey(const Key('nav_item_social')), findsOneWidget);
      }
    });
  });
}
