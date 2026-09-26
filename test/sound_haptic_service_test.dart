import 'package:flutter_test/flutter_test.dart';
import 'package:ludo/logic/ludo_game_controller.dart';
import 'package:ludo/models/game_state.dart';
import 'package:ludo/services/sound_haptic_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SoundHapticService.resetDebounce();
    SoundHapticService.soundEnabled = true;
    SoundHapticService.vibrationEnabled = true;
  });

  group('SoundHapticService Global Settings Tests', () {
    test('Default values are enabled', () {
      expect(SoundHapticService.soundEnabled, isTrue);
      expect(SoundHapticService.isSoundEnabled, isTrue);
      expect(SoundHapticService.vibrationEnabled, isTrue);
      expect(SoundHapticService.isVibrationEnabled, isTrue);
      expect(SoundHapticService.isHapticsEnabled, isTrue);
    });

    test('soundEnabled and isSoundEnabled setters work synchronously and identically', () {
      SoundHapticService.soundEnabled = false;
      expect(SoundHapticService.soundEnabled, isFalse);
      expect(SoundHapticService.isSoundEnabled, isFalse);

      SoundHapticService.isSoundEnabled = true;
      expect(SoundHapticService.soundEnabled, isTrue);
      expect(SoundHapticService.isSoundEnabled, isTrue);
    });

    test('vibrationEnabled, isVibrationEnabled, and isHapticsEnabled setters work identically', () {
      SoundHapticService.vibrationEnabled = false;
      expect(SoundHapticService.vibrationEnabled, isFalse);
      expect(SoundHapticService.isVibrationEnabled, isFalse);
      expect(SoundHapticService.isHapticsEnabled, isFalse);

      SoundHapticService.isHapticsEnabled = true;
      expect(SoundHapticService.vibrationEnabled, isTrue);
      expect(SoundHapticService.isVibrationEnabled, isTrue);
      expect(SoundHapticService.isHapticsEnabled, isTrue);
    });

    test('toggleSound toggles sound state', () async {
      expect(SoundHapticService.soundEnabled, isTrue);
      await SoundHapticService.toggleSound();
      expect(SoundHapticService.soundEnabled, isFalse);
      await SoundHapticService.toggleSound();
      expect(SoundHapticService.soundEnabled, isTrue);
    });

    test('toggleVibration and toggleHaptics toggle vibration state', () async {
      expect(SoundHapticService.vibrationEnabled, isTrue);
      await SoundHapticService.toggleVibration();
      expect(SoundHapticService.vibrationEnabled, isFalse);
      await SoundHapticService.toggleHaptics();
      expect(SoundHapticService.vibrationEnabled, isTrue);
    });
  });

  group('SoundHapticService Dice Feedback Tests', () {
    test('playDiceRollSound and onDiceResult execute without throwing when enabled', () {
      expect(() => SoundHapticService.playDiceRollSound(), returnsNormally);
      expect(() => SoundHapticService.onDiceResult(), returnsNormally);
      expect(() => SoundHapticService.onDiceSettle(), returnsNormally);
    });

    test('playDiceRollSound and onDiceResult execute without throwing when disabled', () {
      SoundHapticService.soundEnabled = false;
      SoundHapticService.vibrationEnabled = false;

      expect(() => SoundHapticService.playDiceRollSound(), returnsNormally);
      expect(() => SoundHapticService.onDiceResult(), returnsNormally);
      expect(() => SoundHapticService.onDiceThrow(), returnsNormally);
      expect(() => SoundHapticService.onDiceTapPress(), returnsNormally);
      expect(() => SoundHapticService.onDiceShake(), returnsNormally);
      expect(() => SoundHapticService.onDiceFirstLanding(), returnsNormally);
    });

    test('Rapid consecutive calls are safely debounced without throwing', () {
      for (int i = 0; i < 10; i++) {
        expect(() => SoundHapticService.playDiceRollSound(), returnsNormally);
        expect(() => SoundHapticService.onDiceResult(), returnsNormally);
      }
    });
  });

  group('SoundHapticService Token Movement & Special Events Tests', () {
    test('Token step sound and landing haptic execute without throwing', () {
      expect(() => SoundHapticService.playTokenStepSound(), returnsNormally);
      expect(() => SoundHapticService.onTokenStepLanding(), returnsNormally);
      expect(() => SoundHapticService.onTokenStep(), returnsNormally);
    });

    test('All special event methods execute cleanly', () {
      expect(() => SoundHapticService.onTokenOpen(), returnsNormally);
      expect(() => SoundHapticService.onTokenCapture(), returnsNormally);
      expect(() => SoundHapticService.onCapture(), returnsNormally);
      expect(() => SoundHapticService.onSafeCellLanding(), returnsNormally);
      expect(() => SoundHapticService.onSafeStopLanding(), returnsNormally);
      expect(() => SoundHapticService.onHomeStretchEnter(), returnsNormally);
      expect(() => SoundHapticService.onHomeGoal(), returnsNormally);
      expect(() => SoundHapticService.onVictory(), returnsNormally);
    });

    test('Special event methods execute cleanly when sound and vibration are disabled', () {
      SoundHapticService.soundEnabled = false;
      SoundHapticService.vibrationEnabled = false;

      expect(() => SoundHapticService.playTokenStepSound(), returnsNormally);
      expect(() => SoundHapticService.onTokenStepLanding(), returnsNormally);
      expect(() => SoundHapticService.onTokenOpen(), returnsNormally);
      expect(() => SoundHapticService.onTokenCapture(), returnsNormally);
      expect(() => SoundHapticService.onSafeCellLanding(), returnsNormally);
      expect(() => SoundHapticService.onHomeStretchEnter(), returnsNormally);
      expect(() => SoundHapticService.onHomeGoal(), returnsNormally);
      expect(() => SoundHapticService.onVictory(), returnsNormally);
    });
  });

  group('LudoGameController Sound & Vibration Integration Tests', () {
    test('Game controller dice throw animation triggers playDiceRollSound without crashing', () async {
      final controller = LudoGameController();
      controller.initGame(GameMode.twoPlayer);

      expect(
        () => controller.playDiceThrowAnimation(roll: 6, isHuman: true),
        returnsNormally,
      );

      controller.dispose();
    });

    test('Moving token from base triggers onTokenOpen and step progression cleanly', () async {
      final controller = LudoGameController();
      controller.initGame(GameMode.twoPlayer);

      final token = controller.state.currentPlayer.tokens.first;
      expect(token.isInBase, isTrue);

      // Simulate rolling 6 and moving first token
      controller.state.currentDiceValue = 6;
      controller.state.phase = TurnPhase.waitingForMove;

      final moveFuture = controller.moveToken(token);
      await expectLater(moveFuture, completes);

      expect(token.step, equals(0));
      expect(controller.state.currentPlayer.hasOpenedFirstToken, isTrue);

      controller.dispose();
    });

    test('Moving token across board with sound and vibration disabled executes cleanly', () async {
      SoundHapticService.soundEnabled = false;
      SoundHapticService.vibrationEnabled = false;

      final controller = LudoGameController();
      controller.initGame(GameMode.twoPlayer);

      final token = controller.state.currentPlayer.tokens.first;
      token.step = 0; // already out

      controller.state.currentDiceValue = 3;
      controller.state.phase = TurnPhase.waitingForMove;

      final moveFuture = controller.moveToken(token);
      await expectLater(moveFuture, completes);

      expect(token.step, equals(3));

      controller.dispose();
    });
  });
}
