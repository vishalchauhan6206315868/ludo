import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/api_service.dart';
import '../models/user_profile_model.dart';

/// Standard result object for authentication operations
class AuthResult {
  final bool success;
  final String? message;
  final User? user;
  final bool isCancelled;

  const AuthResult({
    required this.success,
    this.message,
    this.user,
    this.isCancelled = false,
  });
}

/// Unified Authentication Service for Ludo Supreme
///
/// Supports:
/// - Firebase Authentication (Google, Anonymous/Guest, Email/Password)
/// - Offline/Demo sample credentials fallback
/// - SharedPreferences session persistence
/// - Auth state listeners
class AuthService {
  static FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserPassword = 'user_password';
  static const String _keyUserPhotoUrl = 'user_photo_url';
  static const String _keyUserUid = 'user_uid';
  static const String _keyAuthProvider = 'auth_provider'; // 'google', 'email', 'guest'
  static const String _keyCoins = 'user_coins';
  static const String _keyGems = 'user_gems';
  static const String _keyLevel = 'user_level';
  static const String _keyUserProfileJson = 'user_profile_json';

  // Default sample credentials for offline/demo use
  static const String defaultEmail = 'admin@ludo.com';
  static const String defaultPassword = 'password123';
  static const String defaultName = 'Ludo Master';

  /// Stream of Firebase auth state changes
  static Stream<User?> get authStateChanges =>
      _auth?.authStateChanges() ?? const Stream.empty();

  /// Current authenticated Firebase user (null if not logged in via Firebase)
  static User? get currentFirebaseUser => _auth?.currentUser;

  /// Initialize default sample user in SharedPreferences if not already present.
  /// Each physical device receives a unique player ID so two testing devices
  /// (such as tablet and mobile) do not conflict as the same user.
  static Future<void> initSampleData() async {
    final prefs = await SharedPreferences.getInstance();
    final currentEmail = prefs.getString(_keyUserEmail);
    if (currentEmail == null || currentEmail.isEmpty || currentEmail == defaultEmail) {
      var deviceId = prefs.getString('device_unique_id');
      if (deviceId == null || deviceId.isEmpty) {
        final rand = Random().nextInt(9000) + 1000;
        final ts = (DateTime.now().millisecondsSinceEpoch % 100000);
        deviceId = '$ts$rand';
        await prefs.setString('device_unique_id', deviceId);
      }
      final uniqueEmail = 'player_$deviceId@ludo.com';
      final uniqueName = 'Player $deviceId';
      await prefs.setString(_keyUserEmail, uniqueEmail);
      await prefs.setString(_keyUserPassword, defaultPassword);
      await prefs.setString(_keyUserName, uniqueName);
      await prefs.remove(_keyUserUid);
      // Clear any cached token from previous shared admin session
      await ApiService().clearSession();
    }
  }

  /// Check if user has an active session (either Firebase or local demo session)
  static Future<bool> isLoggedIn() async {
    if (_auth?.currentUser != null) {
      return true;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Ensures the active session has a valid backend JWT token.
  /// If missing, it will attempt login or auto-register the user on backend,
  /// or fallback to default player session.
  static Future<String?> ensureBackendSession({
    String? email,
    String? name,
    String? password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    var effectiveEmail = email ?? prefs.getString(_keyUserEmail);
    var effectiveName = name ?? prefs.getString(_keyUserName);
    final effectivePassword = password ?? (prefs.getString(_keyUserPassword) ?? defaultPassword);

    // If using default shared admin credentials or missing unique email, force re-init unique device account
    if (effectiveEmail == null || effectiveEmail.isEmpty || effectiveEmail == defaultEmail) {
      await initSampleData();
      effectiveEmail = prefs.getString(_keyUserEmail);
      effectiveName = prefs.getString(_keyUserName);
    }

    // 1. Check if token is already present (only if it's for this unique user)
    var token = await ApiService().getToken();
    if (token != null && token.isNotEmpty && prefs.getString(_keyUserEmail) != defaultEmail) {
      return token;
    }

    // Format valid email if user entered username
    final cleanEmail = (effectiveEmail ?? 'player_${Random().nextInt(9000) + 1000}@ludo.com').contains('@')
        ? (effectiveEmail ?? 'player_${Random().nextInt(9000) + 1000}@ludo.com').trim().toLowerCase()
        : '${(effectiveEmail ?? 'player_${Random().nextInt(9000) + 1000}').trim().toLowerCase()}@ludo.com';

    // 2. Try backend login with user credentials
    try {
      final loginRes = await ApiService().login(
        email: cleanEmail,
        password: effectivePassword,
      );
      if (loginRes['success'] == true) {
        final u = loginRes['data']?['user'];
        final uid = u is Map ? (u['_id'] ?? u['id'])?.toString() : null;
        if (uid != null && uid.isNotEmpty) await prefs.setString(_keyUserUid, uid);
        token = await ApiService().getToken();
        if (token != null && token.isNotEmpty) return token;
      }
    } catch (_) {}

    // 3. If login failed because user doesn't exist on backend, try auto-register
    try {
      final regRes = await ApiService().register(
        name: effectiveName ?? 'Player',
        email: cleanEmail,
        password: effectivePassword,
      );
      if (regRes['success'] == true) {
        final u = regRes['data']?['user'];
        final uid = u is Map ? (u['_id'] ?? u['id'])?.toString() : null;
        if (uid != null && uid.isNotEmpty) await prefs.setString(_keyUserUid, uid);
        token = await ApiService().getToken();
        if (token != null && token.isNotEmpty) return token;
      }
    } catch (_) {}

    // 4. Fallback to default demo session (admin@ludo.com)
    try {
      final demoRes = await ApiService().login(
        email: defaultEmail,
        password: defaultPassword,
      );
      if (demoRes['success'] == true) {
        token = await ApiService().getToken();
        if (token != null && token.isNotEmpty) return token;
      }
    } catch (_) {}

    return null;
  }

  /// Get current user name (prefers Firebase displayName, falls back to local storage)
  static Future<String> getUserName() async {
    final fbUser = _auth?.currentUser;
    if (fbUser != null && fbUser.displayName != null && fbUser.displayName!.trim().isNotEmpty) {
      return fbUser.displayName!.trim();
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName) ?? 'Player';
  }

  /// Get current user email
  static Future<String> getUserEmail() async {
    final fbUser = _auth?.currentUser;
    if (fbUser != null && fbUser.email != null && fbUser.email!.trim().isNotEmpty) {
      return fbUser.email!.trim();
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail) ?? '';
  }

  /// Get current user photo URL
  static Future<String?> getUserPhotoUrl() async {
    final fbUser = _auth?.currentUser;
    if (fbUser != null && fbUser.photoURL != null) {
      return fbUser.photoURL;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserPhotoUrl);
  }

  /// Get current user UID
  static Future<String?> getUserUid() async {
    final fbUser = _auth?.currentUser;
    if (fbUser != null) {
      return fbUser.uid;
    }
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_keyUserUid);
    if (uid != null && uid.isNotEmpty) return uid;
    final devId = prefs.getString('device_unique_id');
    if (devId != null && devId.isNotEmpty) return 'device_$devId';
    return prefs.getString(_keyUserEmail);
  }

  /// Get active authentication provider type
  static Future<String> getAuthProvider() async {
    final fbUser = _auth?.currentUser;
    if (fbUser != null) {
      if (fbUser.providerData.isNotEmpty) {
        final providerId = fbUser.providerData.first.providerId;
        if (providerId.contains('google')) return 'google';
      }
      if (fbUser.isAnonymous) return 'guest';
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAuthProvider) ?? 'local';
  }

  /// Fetch user profile from Backend REST API (/api/users/me) and cache it locally
  static Future<UserProfileModel?> fetchUserProfile() async {
    try {
      final profile = await ApiService().getUserProfile();
      if (profile != null) {
        final prefs = await SharedPreferences.getInstance();
        if (profile.name.isNotEmpty) await prefs.setString(_keyUserName, profile.name);
        if (profile.email.isNotEmpty) await prefs.setString(_keyUserEmail, profile.email);
        if (profile.id.isNotEmpty) await prefs.setString(_keyUserUid, profile.id);
        if (profile.avatar.isNotEmpty) await prefs.setString(_keyUserPhotoUrl, profile.avatar);
        await prefs.setInt(_keyCoins, profile.coins);
        await prefs.setInt(_keyGems, profile.gems);
        await prefs.setInt(_keyLevel, profile.level);
        await prefs.setString(_keyUserProfileJson, profile.toRawJson());
        return profile;
      }
    } catch (e) {
      debugPrint("Error fetching backend user profile: $e");
    }
    return getCachedUserProfile();
  }

  /// Get cached user profile from local SharedPreferences
  static Future<UserProfileModel?> getCachedUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_keyUserProfileJson);
      if (rawJson != null && rawJson.isNotEmpty) {
        return UserProfileModel.fromRawJson(rawJson);
      }
      final name = prefs.getString(_keyUserName) ?? 'Player';
      final email = prefs.getString(_keyUserEmail) ?? '';
      final uid = prefs.getString(_keyUserUid) ?? '';
      final coins = prefs.getInt(_keyCoins) ?? 1000;
      final gems = prefs.getInt(_keyGems) ?? 10;
      final level = prefs.getInt(_keyLevel) ?? 1;
      return UserProfileModel(
        id: uid,
        name: name,
        email: email,
        coins: coins,
        gems: gems,
        level: level,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get current user coin balance
  static Future<int> getUserCoins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCoins) ?? 1000;
  }

  /// Get current user gem balance
  static Future<int> getUserGems() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyGems) ?? 10;
  }

  /// Get current user level
  static Future<int> getUserLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyLevel) ?? 1;
  }

  /// Synchronize user profile into local storage for offline continuity
  static Future<void> _syncUserData(User user, {String provider = 'firebase'}) async {
    final prefs = await SharedPreferences.getInstance();
    final name = (user.displayName != null && user.displayName!.isNotEmpty)
        ? user.displayName!
        : 'Ludo Champion';
    final email = user.email ?? '';

    await prefs.setString(_keyUserName, name);
    await prefs.setString(_keyUserEmail, email);
    await prefs.setString(_keyUserUid, user.uid);
    await prefs.setString(_keyAuthProvider, provider);
    if (user.photoURL != null) {
      await prefs.setString(_keyUserPhotoUrl, user.photoURL!);
    }
    await prefs.setBool(_keyIsLoggedIn, true);

    // Ensure backend JWT session is acquired for Google / Firebase users
    await ensureBackendSession(
      email: email.isNotEmpty ? email : null,
      name: name,
    );
  }

  // ==========================================================================
  // GOOGLE SIGN IN
  // ==========================================================================
  static Future<AuthResult> signInWithGoogle() async {
    if (_auth == null) {
      return const AuthResult(
        success: false,
        message: "Firebase is not initialized",
      );
    }

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return const AuthResult(
          success: false,
          isCancelled: true,
          message: "Sign-in cancelled",
        );
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth!.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        await _syncUserData(user, provider: 'google');
        return AuthResult(success: true, user: user);
      }

      return const AuthResult(
        success: false,
        message: "Unable to complete Google sign-in. Please try again.",
      );
    } on FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuthException in Google Sign-In: ${e.code} - ${e.message}");
      return AuthResult(
        success: false,
        message: _mapFirebaseAuthError(e),
      );
    } catch (e) {
      debugPrint("Error in Google Sign-In: $e");
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('network') || errorStr.contains('socket') || errorStr.contains('connection')) {
        return const AuthResult(
          success: false,
          message: "Internet connection required",
        );
      }
      if (errorStr.contains('10') || errorStr.contains('developer_error')) {
        return const AuthResult(
          success: false,
          message: "Google Sign-In configuration error: SHA-1 fingerprint must be added to Firebase Console and google-services.json replaced.",
        );
      }
      return AuthResult(
        success: false,
        message: "Google Sign-In failed: $e",
      );
    }
  }


  // ==========================================================================
  // LEGACY / GUEST / EMAIL SIGN IN
  // ==========================================================================

  /// Guest quick login
  static Future<void> loginAsGuest() async {
    if (_auth != null) {
      try {
        final userCredential = await _auth!.signInAnonymously();
        if (userCredential.user != null) {
          await _syncUserData(userCredential.user!, provider: 'guest');
          return;
        }
      } catch (e) {
        debugPrint("Anonymous Firebase sign in skipped/failed: $e");
      }
    }

    // Local fallback for guest
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, 'Guest Player');
    await prefs.setString(_keyAuthProvider, 'guest');
    await prefs.setBool(_keyIsLoggedIn, true);

    // Acquire backend session for guest player
    await ensureBackendSession(name: 'Guest Player');
  }

  /// Register user via Backend REST API (with Firebase & local fallback)
  static Future<bool> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    lastErrorMessage = null;

    // 1. Try Backend REST API (http://localhost:5000/api/auth/register)
    try {
      final apiRes = await ApiService().register(
        name: name.trim(),
        email: email.trim(),
        password: password,
      );

      if (apiRes['success'] == true) {
        final data = apiRes['data'];
        String userName = name.trim();
        String userEmail = email.trim();
        String uid = '';

        if (data is Map<String, dynamic>) {
          final userObj = data['user'] ?? data['data'] ?? data;
          if (userObj is Map<String, dynamic>) {
            userName = userObj['name']?.toString() ??
                userObj['username']?.toString() ??
                userName;
            userEmail = userObj['email']?.toString() ?? userEmail;
            uid = userObj['id']?.toString() ??
                userObj['_id']?.toString() ??
                uid;
          }
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyUserName, userName);
        await prefs.setString(_keyUserEmail, userEmail);
        if (uid.isNotEmpty) await prefs.setString(_keyUserUid, uid);
        await prefs.setString(_keyAuthProvider, 'backend_api');
        await prefs.setBool(_keyIsLoggedIn, true);
        await fetchUserProfile();
        return true;
      } else {
        lastErrorMessage = apiRes['message'];
        // If the backend actively rejected with status 400/409 (e.g. Email already exists), fail explicitly
        final msg = (apiRes['message'] ?? '').toString().toLowerCase();
        final isSpecificRejection = msg.contains('already') ||
            msg.contains('exist') ||
            msg.contains('invalid') ||
            msg.contains('duplicate');
        if (apiRes['statusCode'] != null &&
            apiRes['statusCode'] >= 400 &&
            apiRes['statusCode'] < 500 &&
            isSpecificRejection) {
          return false;
        }
      }
    } catch (e) {
      debugPrint("Backend API registration exception: $e");
    }

    // 2. Try Firebase registration
    if (_auth != null) {
      try {
        final cred = await _auth!.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        if (cred.user != null) {
          await cred.user!.updateDisplayName(name.trim());
          await _syncUserData(cred.user!, provider: 'email');
          return true;
        }
      } catch (e) {
        debugPrint("Firebase email registration fallback: $e");
      }
    }

    // 3. Local fallback (only if backend is unreachable)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, name.trim());
    await prefs.setString(_keyUserEmail, email.trim().toLowerCase());
    await prefs.setString(_keyUserPassword, password);
    await prefs.setString(_keyAuthProvider, 'email');
    await prefs.setBool(_keyIsLoggedIn, true);
    return true;
  }

  static String? lastErrorMessage;

  /// Authenticate existing user
  static Future<bool> loginUser({
    required String emailOrName,
    required String password,
  }) async {
    lastErrorMessage = null;

    // 1. Try Backend REST API (http://localhost:5000/api/auth/login)
    try {
      final apiRes = await ApiService().login(
        email: emailOrName.trim(),
        password: password,
      );

      if (apiRes['success'] == true) {
        final data = apiRes['data'];
        String name = 'Player';
        String email = emailOrName.trim();
        String uid = '';

        if (data is Map<String, dynamic>) {
          final userObj = data['user'] ?? data['data'] ?? data;
          if (userObj is Map<String, dynamic>) {
            name = userObj['name']?.toString() ??
                userObj['username']?.toString() ??
                name;
            email = userObj['email']?.toString() ?? email;
            uid = userObj['id']?.toString() ??
                userObj['_id']?.toString() ??
                uid;
          }
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyUserName, name);
        await prefs.setString(_keyUserEmail, email);
        await prefs.setString(_keyUserPassword, password);
        if (uid.isNotEmpty) await prefs.setString(_keyUserUid, uid);
        await prefs.setString(_keyAuthProvider, 'backend_api');
        await prefs.setBool(_keyIsLoggedIn, true);
        await fetchUserProfile();
        return true;
      } else {
        lastErrorMessage = apiRes['message'];
      }
    } catch (e) {
      debugPrint("Backend API login exception: $e");
    }

    // 2. Try Firebase Email/Password
    if (_auth != null && emailOrName.contains('@')) {
      try {
        final cred = await _auth!.signInWithEmailAndPassword(
          email: emailOrName.trim(),
          password: password,
        );
        if (cred.user != null) {
          await _syncUserData(cred.user!, provider: 'email');
          return true;
        }
      } catch (e) {
        debugPrint("Firebase email login fallback: $e");
      }
    }

    // 3. Local fallback
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(_keyUserEmail)?.toLowerCase();
    final savedName = prefs.getString(_keyUserName)?.toLowerCase();
    final savedPassword = prefs.getString(_keyUserPassword);

    final input = emailOrName.trim().toLowerCase();

    final matchesSaved = (input == savedEmail || input == savedName) &&
        password == savedPassword;
    final matchesDefault = (input == defaultEmail.toLowerCase() ||
            input == defaultName.toLowerCase()) &&
        password == defaultPassword;

    if (matchesSaved || matchesDefault) {
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyAuthProvider, 'email');
      if (matchesDefault && !prefs.containsKey(_keyUserName)) {
        await prefs.setString(_keyUserName, defaultName);
        await prefs.setString(_keyUserEmail, defaultEmail);
        await prefs.setString(_keyUserPassword, defaultPassword);
      }

      await ensureBackendSession(
        email: emailOrName.contains('@') ? emailOrName.trim() : null,
        password: password,
      );
      return true;
    }

    return false;
  }

  /// Sign out from all providers (Firebase, Google, Backend API, SharedPreferences)
  static Future<void> logout() async {
    // Clear backend API session & token
    try {
      await ApiService().clearSession();
    } catch (_) {}

    if (_auth != null) {
      try {
        await _auth!.signOut();
      } catch (e) {
        debugPrint("Error signing out of Firebase: $e");
      }
    }

    try {
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
    await prefs.remove(_keyUserProfileJson);
    await prefs.remove(_keyCoins);
    await prefs.remove(_keyGems);
    await prefs.remove(_keyLevel);
  }

  /// User-friendly error message translation without technical stack traces
  static String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return "Internet connection required";
      case 'account-exists-with-different-credential':
        return "An account already exists with this email using a different sign-in method.";
      case 'invalid-credential':
        return "Invalid authentication credentials.";
      case 'user-disabled':
        return "This account has been disabled. Please contact support.";
      case 'operation-not-allowed':
        return "This sign-in provider is not enabled in Firebase Console.";
      case 'user-not-found':
      case 'wrong-password':
        return "Invalid email or password.";
      case 'popup-closed-by-user':
      case 'canceled':
        return "Sign-in cancelled";
      default:
        return "Unable to sign in. Please try again.";
    }
  }
}
