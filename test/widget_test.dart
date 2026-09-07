import 'package:flutter_test/flutter_test.dart';
import 'package:ludo/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('LudoApp splash screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LudoApp());
    expect(find.text('LUDO SUPREME'), findsOneWidget);
    expect(find.text('The Royal Board Game Experience'), findsOneWidget);

    // Fast-forward past the splash timer (2.2s)
    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pumpAndSettle();

    // After splash on first run, it navigates to LoginScreen
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
