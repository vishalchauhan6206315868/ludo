import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundHapticService {
  static const String _keySound = 'setting_sound_enabled';
  static const String _keyHaptics = 'setting_haptics_enabled';

  static bool _soundEnabled = true;
  static bool _hapticsEnabled = true;

  static AudioPlayer? _diceAudioPlayer;
  static int _lastDiceRollTime = 0;

  static bool get isSoundEnabled => _soundEnabled;
  static bool get isHapticsEnabled => _hapticsEnabled;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool(_keySound) ?? true;
      _hapticsEnabled = prefs.getBool(_keyHaptics) ?? true;
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
    _soundEnabled = !_soundEnabled;
    if (!_soundEnabled) {
      try {
        await _diceAudioPlayer?.stop();
      } catch (_) {}
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySound, _soundEnabled);
    } catch (_) {}
  }

  static Future<void> toggleHaptics() async {
    _hapticsEnabled = !_hapticsEnabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHaptics, _hapticsEnabled);
    } catch (_) {}
  }

  static void onDicePickup() {
    try {
      if (_hapticsEnabled) {
        HapticFeedback.selectionClick();
      }
    } catch (_) {}
  }

  /// Triggered on immediate user touch/press before the throw initiates
  static void onDiceTapPress() {
    try {
      if (_hapticsEnabled) {
        HapticFeedback.lightImpact();
      }
      if (_soundEnabled) {
        SystemSound.play(SystemSoundType.click);
      }
    } catch (_) {}
  }

  static void onDiceShake() {
    try {
      if (_hapticsEnabled) {
        HapticFeedback.lightImpact();
      }
      if (_soundEnabled) {
        SystemSound.play(SystemSoundType.click);
      }
    } catch (_) {}
  }

  /// Triggered as the dice leaves the hand/tray and launches into the air
  static void onDiceThrow() {
    try {
      if (_hapticsEnabled) {
        HapticFeedback.mediumImpact();
      }
      onDiceRoll();
    } catch (_) {}
  }

  /// Triggered upon first contact of the dice with the board surface
  static void onDiceFirstLanding() {
    try {
      if (_hapticsEnabled) {
        HapticFeedback.mediumImpact();
      }
    } catch (_) {}
  }

  /// Triggered when a token arrives safely on a STOP point / safe star cell
  static void onSafeStopLanding() {
    try {
      if (_hapticsEnabled) {
        HapticFeedback.mediumImpact();
      }
      if (_soundEnabled) {
        SystemSound.play(SystemSoundType.click);
      }
    } catch (_) {}
  }

  static void onBoardCollision() {
    try {
      if (_hapticsEnabled) {
        HapticFeedback.mediumImpact();
      }
    } catch (_) {}
  }

  /// Triggered when the dice finishes all bounces and rests in its final position
  static void onDiceSettle() {
    try {
      if (_hapticsEnabled) {
        HapticFeedback.lightImpact();
      }
    } catch (_) {}
  }

  /// Realistic physical dice rolling sound effect & haptic feedback.
  /// Debounced to prevent multiple rapid triggers during a single throw.
  static void onDiceRoll() {
    try {
      if (_hapticsEnabled) {
        HapticFeedback.mediumImpact();
      }
      if (_soundEnabled) {
        final now = DateTime.now().millisecondsSinceEpoch;
        // Debounce: prevent duplicate triggers within 500ms for a single throw
        if (now - _lastDiceRollTime >= 500) {
          _lastDiceRollTime = now;
          _playDiceSound();
        }
      }
    } catch (e) {
      debugPrint("Error in onDiceRoll: $e");
    }
  }

  static Future<void> _playDiceSound() async {
    try {
      _diceAudioPlayer ??= AudioPlayer();
      await _diceAudioPlayer!.stop();
      await _diceAudioPlayer!.play(AssetSource('sounds/dice_roll.wav'));
    } catch (e) {
      debugPrint("AudioPlayer dice roll sound error (safe fallback): $e");
      try {
        await _diceAudioPlayer?.play(AssetSource('sounds/dice_roll.mp3'));
      } catch (_) {}
    }
  }

  static void onTokenStep() {
    try {
      if (_hapticsEnabled) {
        HapticFeedback.selectionClick();
      }
      if (_soundEnabled) {
        SystemSound.play(SystemSoundType.click);
      }
    } catch (_) {}
  }

  static void onCapture() {
    try {
      if (_hapticsEnabled) {
        HapticFeedback.heavyImpact();
      }
      if (_soundEnabled) {
        SystemSound.play(SystemSoundType.alert);
      }
    } catch (_) {}
  }

  static void onHomeGoal() {
    try {
      if (_hapticsEnabled) {
        HapticFeedback.mediumImpact();
      }
      if (_soundEnabled) {
        SystemSound.play(SystemSoundType.click);
      }
    } catch (_) {}
  }

  static void onVictory() {
    try {
      if (_hapticsEnabled) {
        HapticFeedback.vibrate();
      }
      if (_soundEnabled) {
        SystemSound.play(SystemSoundType.alert);
      }
    } catch (_) {}
  }

  static Future<void> dispose() async {
    try {
      await _diceAudioPlayer?.dispose();
      _diceAudioPlayer = null;
    } catch (_) {}
  }
}
