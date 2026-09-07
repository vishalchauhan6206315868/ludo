import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserPassword = 'user_password';

  // Default sample credentials
  static const String defaultEmail = 'admin@ludo.com';
  static const String defaultPassword = 'password123';
  static const String defaultName = 'Ludo Master';

  /// Initialize default sample user in SharedPreferences if not already present
  static Future<void> initSampleData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_keyUserEmail)) {
      await prefs.setString(_keyUserEmail, defaultEmail);
      await prefs.setString(_keyUserPassword, defaultPassword);
      await prefs.setString(_keyUserName, defaultName);
    }
  }

  /// Check if user has an active session
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Get current user name
  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName) ?? 'Player';
  }

  /// Get current user email
  static Future<String> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail) ?? '';
  }

  /// Register a new user
  static Future<bool> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, name.trim());
    await prefs.setString(_keyUserEmail, email.trim().toLowerCase());
    await prefs.setString(_keyUserPassword, password);
    await prefs.setBool(_keyIsLoggedIn, true);
    return true;
  }

  /// Authenticate existing user
  static Future<bool> loginUser({
    required String emailOrName,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(_keyUserEmail)?.toLowerCase();
    final savedName = prefs.getString(_keyUserName)?.toLowerCase();
    final savedPassword = prefs.getString(_keyUserPassword);

    final input = emailOrName.trim().toLowerCase();

    // Check against saved user or default credentials
    final matchesSaved = (input == savedEmail || input == savedName) &&
        password == savedPassword;
    final matchesDefault = (input == defaultEmail.toLowerCase() ||
            input == defaultName.toLowerCase()) &&
        password == defaultPassword;

    if (matchesSaved || matchesDefault) {
      await prefs.setBool(_keyIsLoggedIn, true);
      if (matchesDefault && !prefs.containsKey(_keyUserName)) {
        await prefs.setString(_keyUserName, defaultName);
        await prefs.setString(_keyUserEmail, defaultEmail);
        await prefs.setString(_keyUserPassword, defaultPassword);
      }
      return true;
    }

    return false;
  }

  /// Guest quick login
  static Future<void> loginAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, 'Guest Player');
    await prefs.setBool(_keyIsLoggedIn, true);
  }

  /// Logout user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
  }
}
