import 'package:flutter_test/flutter_test.dart';
import 'package:ludo/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthService Tests', () {
    test('Initial login status is false', () async {
      final loggedIn = await AuthService.isLoggedIn();
      expect(loggedIn, false);
    });

    test('Initializes sample credentials', () async {
      await AuthService.initSampleData();
      final loginSuccess = await AuthService.loginUser(
        emailOrName: AuthService.defaultEmail,
        password: AuthService.defaultPassword,
      );
      expect(loginSuccess, true);
      expect(await AuthService.isLoggedIn(), true);
      expect(await AuthService.getUserName(), AuthService.defaultName);
    });

    test('Registers new user and sets session', () async {
      final testEmail = 'john_${DateTime.now().millisecondsSinceEpoch}@example.com';
      final registered = await AuthService.registerUser(
        name: 'John Doe',
        email: testEmail,
        password: 'secretpassword',
      );
      expect(registered, true);
      expect(await AuthService.isLoggedIn(), true);
      expect(await AuthService.getUserName(), 'John Doe');
      expect(await AuthService.getUserEmail(), testEmail);
    });

    test('Logout clears session', () async {
      await AuthService.loginAsGuest();
      expect(await AuthService.isLoggedIn(), true);

      await AuthService.logout();
      expect(await AuthService.isLoggedIn(), false);
    });
  });
}
