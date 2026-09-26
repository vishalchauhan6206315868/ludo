import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundHapticService {
  static const String _keySound = 'setting_sound_enabled';
  static const String _keyHaptics = 'setting_haptics_enabled';

  static bool _soundEnabled = true;
  static bool vibrationEnabled = true;

  static AudioPlayer? _diceAudioPlayer;

  // Debounce timestamps for preventing duplicate triggers
  static int _lastDiceRollSoundTime = 0;
  static int _lastDiceResultTime = 0;
  static int _lastTokenStepSoundTime = 0;
  static int _lastTokenLandingTime = 0;
  static int _lastTokenOpenTime = 0;
  static int _lastCaptureTime = 0;
  static int _lastSafeCellTime = 0;
  static int _lastHomeStretchTime = 0;
  static int _lastHomeGoalTime = 0;
  static int _lastVictoryTime = 0;

  // ==========================================
  // GLOBAL SETTINGS GETTERS & SETTERS
  // ==========================================

  static bool get soundEnabled => _soundEnabled;
  static set soundEnabled(bool value) {
    _soundEnabled = value;
    if (!_soundEnabled) {
      stopAllSounds();
    }
  }

  static bool get isSoundEnabled => _soundEnabled;
  static set isSoundEnabled(bool value) => soundEnabled = value;

  static bool get isVibrationEnabled => vibrationEnabled;
  static set isVibrationEnabled(bool value) => vibrationEnabled = value;

  static bool get isHapticsEnabled => vibrationEnabled;
  static set isHapticsEnabled(bool value) => vibrationEnabled = value;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool(_keySound) ?? true;
      vibrationEnabled = prefs.getBool(_keyHaptics) ?? true;
    } catch (_) {}

    try {
      _diceAudioPlayer ??= AudioPlayer();
      await _diceAudioPlayer!.setReleaseMode(ReleaseMode.stop);
      await _diceAudioPlayer!.setPlayerMode(PlayerMode.lowLatency);
    } catch (e) {
      debugPrint("SoundHapticService AudioPlayer init warning: $e");
    }
  }

  static Future<void> toggleSound() async {
    soundEnabled = !_soundEnabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySound, _soundEnabled);
    } catch (_) {}
  }

  static Future<void> toggleVibration() async {
    vibrationEnabled = !vibrationEnabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHaptics, vibrationEnabled);
    } catch (_) {}
  }

  static Future<void> toggleHaptics() => toggleVibration();

  static void stopAllSounds() {
    try {
      _diceAudioPlayer?.stop().catchError((_) {});
    } catch (_) {}
  }

  // ==========================================
  // 1. DICE ROLL FEEDBACK
  // ==========================================

  /// Plays realistic dice roll/throw sound without triggering unnecessary vibrations.
  /// Debounced to avoid duplicate triggers during rapid state changes or multiple callbacks.
  static void playDiceRollSound() {
    if (!_soundEnabled) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastDiceRollSoundTime < 450) return;
    _lastDiceRollSoundTime = now;
    _playDiceAudio();
  }

  /// Optional short haptic feedback triggered strictly once when the dice settles on its final result (1-6).
  static void onDiceResult() {
    if (!vibrationEnabled) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastDiceResultTime < 350) return;
    _lastDiceResultTime = now;

    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Alias for backward compatibility
  static void onDiceSettle() => onDiceResult();

  /// Aliases and legacy dice methods kept safe and non-intrusive
  static void onDiceRoll() => playDiceRollSound();

  static void onDiceThrow() {
    playDiceRollSound();
  }

  static void onDiceTapPress() {
    // Only a gentle tap click if sound enabled, no heavy vibration cascade
    if (_soundEnabled) {
      try {
        SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }

  static void onDiceShake() {
    // Controlled: no continuous vibration during shake
  }

  static void onDicePickup() {}

  static void onDiceFirstLanding() {}

  static void onBoardCollision() {}

  // ==========================================
  // 2. TOKEN MOVEMENT FEEDBACK
  // ==========================================

  /// Audio click on each token step/hop. NO vibration!
  /// Prevents shaking the device multiple times on multi-step moves.
  static void playTokenStepSound() {
    if (!_soundEnabled) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastTokenStepSoundTime < 100) return;
    _lastTokenStepSoundTime = now;

    try {
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  /// Controlled short haptic feedback when the token finishes its movement steps and lands.
  static void onTokenStepLanding() {
    if (!vibrationEnabled) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastTokenLandingTime < 300) return;
    _lastTokenLandingTime = now;

    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Legacy token step alias
  static void onTokenStep() {
    playTokenStepSound();
  }

  // ==========================================
  // 3. SPECIAL EVENTS
  // ==========================================

  /// Token opening for the first time / leaving home base onto starting cell.
  static void onTokenOpen() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastTokenOpenTime < 400) return;
    _lastTokenOpenTime = now;

    if (vibrationEnabled) {
      try {
        HapticFeedback.lightImpact();
      } catch (_) {}
    }
    if (_soundEnabled) {
      try {
        SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }

  /// Opponent token capture event.
  static void onTokenCapture() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastCaptureTime < 400) return;
    _lastCaptureTime = now;

    if (vibrationEnabled) {
      try {
        HapticFeedback.heavyImpact();
      } catch (_) {}
    }
    if (_soundEnabled) {
      try {
        SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }
  }

  static void onCapture() => onTokenCapture();

  /// Token lands safely on a STAR / safe cell.
  static void onSafeCellLanding() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastSafeCellTime < 400) return;
    _lastSafeCellTime = now;

    if (vibrationEnabled) {
      try {
        HapticFeedback.mediumImpact();
      } catch (_) {}
    }
    if (_soundEnabled) {
      try {
        SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }

  static void onSafeStopLanding() => onSafeCellLanding();

  /// Token enters the colored home stretch.
  static void onHomeStretchEnter() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastHomeStretchTime < 400) return;
    _lastHomeStretchTime = now;

    if (vibrationEnabled) {
      try {
        HapticFeedback.lightImpact();
      } catch (_) {}
    }
    if (_soundEnabled) {
      try {
        SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }

  /// Token reaches the home triangle / goal.
  static void onHomeGoal() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastHomeGoalTime < 400) return;
    _lastHomeGoalTime = now;

    if (vibrationEnabled) {
      try {
        HapticFeedback.mediumImpact();
      } catch (_) {}
    }
    if (_soundEnabled) {
      try {
        SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }

  /// Player victory / game over fanfare.
  static void onVictory() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastVictoryTime < 500) return;
    _lastVictoryTime = now;

    if (vibrationEnabled) {
      try {
        HapticFeedback.vibrate();
      } catch (_) {}
    }
    if (_soundEnabled) {
      try {
        SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }
  }

  // ==========================================
  // HELPERS
  // ==========================================

  static Future<void> _playDiceAudio() async {
    try {
      _diceAudioPlayer ??= AudioPlayer();
      await _diceAudioPlayer!.stop().catchError((_) {});
      await _diceAudioPlayer!.play(AssetSource('sounds/dice_roll.wav')).catchError((_) {});
    } catch (e) {
      try {
        await _diceAudioPlayer?.play(AssetSource('sounds/dice_roll.mp3')).catchError((_) {});
      } catch (_) {}
    }
  }

  @visibleForTesting
  static void resetDebounce() {
    _lastDiceRollSoundTime = 0;
    _lastDiceResultTime = 0;
    _lastTokenStepSoundTime = 0;
    _lastTokenLandingTime = 0;
    _lastTokenOpenTime = 0;
    _lastCaptureTime = 0;
    _lastSafeCellTime = 0;
    _lastHomeStretchTime = 0;
    _lastHomeGoalTime = 0;
    _lastVictoryTime = 0;
  }

  static Future<void> dispose() async {
    try {
      await _diceAudioPlayer?.dispose().catchError((_) {});
      _diceAudioPlayer = null;
    } catch (_) {}
  }
}
