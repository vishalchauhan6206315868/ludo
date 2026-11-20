import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundHapticService {
  static const String _keySound = 'setting_sound_enabled';
  static const String _keyHaptics = 'setting_haptics_enabled';

  static bool _soundEnabled = true;
  static bool vibrationEnabled = true;
  static bool _audioInitialized = false;

  static final Random _wowRandom = Random();

  static AudioPlayer? _diceAudioPlayer;
  static AudioPlayer? _homeGoalAudioPlayer;
  static AudioPlayer? _fxAudioPlayer;
  static AudioPlayer? _wowAudioPlayer;
  static AudioPlayer? _victoryAudioPlayer;
  static AudioPlayer? _memeAudioPlayer;
  static final List<AudioPlayer> _stepAudioPool = [];
  static int _stepPoolIndex = 0;
  static const int _stepPoolSize = 3;

  static const List<String> _memeSounds = [
    'sounds/meme_1_aayein.mp3',
    'sounds/meme_2_squeak.mp3',
    'sounds/meme_3_kaun_hai.mp3',
    'sounds/meme_4_sad_violin.m4a',
    'sounds/meme_5_cry.m4a',
  ];
  static int _lastMemeIndex = -1;
  static int _lastMemeTime = 0;

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
  static int _lastWowTime = 0;

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

      _homeGoalAudioPlayer ??= AudioPlayer();
      await _homeGoalAudioPlayer!.setReleaseMode(ReleaseMode.stop);
      await _homeGoalAudioPlayer!.setPlayerMode(PlayerMode.lowLatency);

      _fxAudioPlayer ??= AudioPlayer();
      await _fxAudioPlayer!.setReleaseMode(ReleaseMode.stop);
      await _fxAudioPlayer!.setPlayerMode(PlayerMode.lowLatency);

      // MediaPlayer mode supports full-length audio cleanly without SoundPool duration caps
      _wowAudioPlayer ??= AudioPlayer();
      await _wowAudioPlayer!.setReleaseMode(ReleaseMode.stop);
      await _wowAudioPlayer!.setPlayerMode(PlayerMode.mediaPlayer);

      _victoryAudioPlayer ??= AudioPlayer();
      await _victoryAudioPlayer!.setReleaseMode(ReleaseMode.stop);
      await _victoryAudioPlayer!.setPlayerMode(PlayerMode.mediaPlayer);

      _memeAudioPlayer ??= AudioPlayer();
      await _memeAudioPlayer!.setReleaseMode(ReleaseMode.stop);
      await _memeAudioPlayer!.setPlayerMode(PlayerMode.mediaPlayer);

      if (_stepAudioPool.isEmpty) {
        for (int i = 0; i < _stepPoolSize; i++) {
          final player = AudioPlayer();
          await player.setReleaseMode(ReleaseMode.stop);
          await player.setPlayerMode(PlayerMode.lowLatency);
          _stepAudioPool.add(player);
        }
      }
      _audioInitialized = true;
    } catch (e) {
      _audioInitialized = false;
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
      _homeGoalAudioPlayer?.stop().catchError((_) {});
      _fxAudioPlayer?.stop().catchError((_) {});
      _wowAudioPlayer?.stop().catchError((_) {});
      _victoryAudioPlayer?.stop().catchError((_) {});
      _memeAudioPlayer?.stop().catchError((_) {});
      for (final p in _stepAudioPool) {
        p.stop().catchError((_) {});
      }
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

  /// Crisp wooden/pop board audio on each token step/hop. NO vibration!
  /// Uses a low-latency round-robin player pool so multi-step hops never clip.
  static void playTokenStepSound() {
    if (!_soundEnabled) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastTokenStepSoundTime < 80) return;
    _lastTokenStepSoundTime = now;

    _playStepAudio();
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
      _playFxAudio('sounds/token_open.wav');
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
      _playFxAudio('sounds/token_capture.wav');
      // Play a random funny meme sound whenever a goti gets cut/captured!
      playRandomMemeSound(delayMs: 140);
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
      _playFxAudio('sounds/token_safe.wav');
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

  /// Token reaches the home triangle / goal with celebratory sound and haptics.
  static void onHomeGoal() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastHomeGoalTime < 400) return;
    _lastHomeGoalTime = now;

    if (vibrationEnabled) {
      try {
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 140), () {
          try {
            HapticFeedback.mediumImpact();
          } catch (_) {}
        });
      } catch (_) {}
    }
    if (_soundEnabled) {
      _playGoalAudio();
      maybePlayWowSound(chance: 0.45, delayMs: 220);
    }
  }

  /// Randomly plays the fun "WOW!" reaction sound alongside exciting moments
  /// (rolling a 6, cutting an opponent's goti, or passing a goti home).
  static void maybePlayWowSound({double chance = 0.38, int delayMs = 160}) {
    if (!_soundEnabled || !_audioInitialized) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    // Cooldown of 4s so "WOW!" stays fun & never spams back-to-back
    if (now - _lastWowTime < 4000) return;
    if (_wowRandom.nextDouble() >= chance) return;
    _lastWowTime = now;

    Future.delayed(Duration(milliseconds: delayMs), () {
      if (_soundEnabled) {
        _playWowAudio();
      }
    });
  }

  /// Player victory / all-4-gotis-passed 10-second Diwali fireworks celebration.
  static void onVictory() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastVictoryTime < 1000) return;
    _lastVictoryTime = now;

    if (vibrationEnabled) {
      try {
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 160), () {
          try {
            HapticFeedback.heavyImpact();
          } catch (_) {}
        });
      } catch (_) {}
    }
    if (_soundEnabled) {
      _playDiwaliVictoryAudio();
    }
  }

  // ==========================================
  // HELPERS
  // ==========================================

  static Future<void> _playDiceAudio() async {
    try {
      _diceAudioPlayer ??= AudioPlayer();
      await _diceAudioPlayer!.stop().catchError((_) {});
      await _diceAudioPlayer!.play(AssetSource('sounds/dice_roll.wav.mp3')).catchError((_) {});
    } catch (e) {
      try {
        await _diceAudioPlayer?.play(AssetSource('sounds/dice_roll.wav')).catchError((_) {});
      } catch (_) {}
    }
  }

  static Future<void> _playStepAudio() async {
    if (!_audioInitialized || _stepAudioPool.isEmpty) return;
    try {
      final player = _stepAudioPool[_stepPoolIndex % _stepAudioPool.length];
      _stepPoolIndex = (_stepPoolIndex + 1) % _stepAudioPool.length;
      await player.stop().catchError((_) {});
      await player
          .play(AssetSource('sounds/token_step.wav'), volume: 0.95)
          .catchError((_) {});
    } catch (_) {}
  }

  static Future<void> _playFxAudio(String assetPath) async {
    if (!_audioInitialized || _fxAudioPlayer == null) return;
    try {
      await _fxAudioPlayer!.stop().catchError((_) {});
      await _fxAudioPlayer!
          .play(AssetSource(assetPath), volume: 0.95)
          .catchError((_) {});
    } catch (_) {}
  }

  static Future<void> _playWowAudio() async {
    if (!_audioInitialized || _wowAudioPlayer == null) return;
    try {
      await _wowAudioPlayer!.stop().catchError((_) {});
      await _wowAudioPlayer!
          .play(AssetSource('sounds/wow.mp3'), volume: 0.95)
          .catchError((_) {});
    } catch (_) {}
  }

  /// Plays a random funny meme sound effect (never repeating the same clip twice in a row),
  /// used on goti captures and when a player rolls 7–8 times stuck in base without a 6!
  static void playRandomMemeSound({int delayMs = 140}) {
    if (!_soundEnabled || !_audioInitialized) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastMemeTime < 600) return;
    _lastMemeTime = now;

    int idx = _wowRandom.nextInt(_memeSounds.length);
    if (idx == _lastMemeIndex && _memeSounds.length > 1) {
      idx = (idx + 1 + _wowRandom.nextInt(_memeSounds.length - 1)) %
          _memeSounds.length;
    }
    _lastMemeIndex = idx;
    final assetPath = _memeSounds[idx];

    Future.delayed(Duration(milliseconds: delayMs), () {
      if (_soundEnabled) {
        _playMemeAudio(assetPath);
      }
    });
  }

  static Future<void> _playMemeAudio(String assetPath) async {
    if (!_audioInitialized || _memeAudioPlayer == null) return;
    try {
      await _memeAudioPlayer!.stop().catchError((_) {});
      await _memeAudioPlayer!
          .play(AssetSource(assetPath), volume: 1.0)
          .catchError((_) {});
    } catch (_) {}
  }

  static Future<void> _playDiwaliVictoryAudio() async {
    if (!_audioInitialized || _victoryAudioPlayer == null) return;
    try {
      await _victoryAudioPlayer!.stop().catchError((_) {});
      await _victoryAudioPlayer!
          .play(AssetSource('sounds/diwali_victory.m4a'), volume: 1.0)
          .catchError((_) {});
    } catch (_) {}
  }

  static Future<void> _playGoalAudio() async {
    try {
      _homeGoalAudioPlayer ??= AudioPlayer();
      await _homeGoalAudioPlayer!.stop().catchError((_) {});
      await _homeGoalAudioPlayer!.play(AssetSource('sounds/home_goal.wav')).catchError((_) {});
    } catch (e) {
      try {
        await _diceAudioPlayer?.play(AssetSource('sounds/dice_roll.wav.mp3')).catchError((_) {});
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
    _lastWowTime = 0;
    _lastMemeTime = 0;
  }

  static Future<void> dispose() async {
    try {
      await _diceAudioPlayer?.dispose().catchError((_) {});
      _diceAudioPlayer = null;
      await _homeGoalAudioPlayer?.dispose().catchError((_) {});
      _homeGoalAudioPlayer = null;
      await _fxAudioPlayer?.dispose().catchError((_) {});
      _fxAudioPlayer = null;
      await _wowAudioPlayer?.dispose().catchError((_) {});
      _wowAudioPlayer = null;
      await _victoryAudioPlayer?.dispose().catchError((_) {});
      _victoryAudioPlayer = null;
      await _memeAudioPlayer?.dispose().catchError((_) {});
      _memeAudioPlayer = null;
      for (final p in _stepAudioPool) {
        await p.dispose().catchError((_) {});
      }
      _stepAudioPool.clear();
      _stepPoolIndex = 0;
      _audioInitialized = false;
    } catch (_) {}
  }
}
