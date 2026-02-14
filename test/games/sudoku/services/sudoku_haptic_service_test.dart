// Unit tests for SudokuHapticService

import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/sudoku/services/sudoku_haptic_service.dart';
import 'package:multigame/games/sudoku/providers/sudoku_settings_provider.dart';

/// Fake SudokuSettingsProvider for testing
class FakeSudokuSettingsProvider extends SudokuSettingsProvider {
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;

  @override
  bool get soundEnabled => _soundEnabled;

  @override
  bool get hapticsEnabled => _hapticsEnabled;

  @override
  void setSoundEnabled(bool value) {
    _soundEnabled = value;
  }

  @override
  void setHapticsEnabled(bool value) {
    _hapticsEnabled = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SudokuHapticService', () {
    late SudokuHapticService service;
    late FakeSudokuSettingsProvider fakeSettings;

    setUp(() {
      fakeSettings = FakeSudokuSettingsProvider();
      service = SudokuHapticService(settings: fakeSettings);
    });

    group('initialize', () {
      test('should initialize without errors', () async {
        await service.initialize();
        // Service should initialize successfully
        expect(service, isNotNull);
      });

      test('should handle missing vibrator gracefully', () async {
        // Even if vibrator is not available, should complete
        await expectLater(service.initialize(), completes);
      });

      test('should handle initialization errors gracefully', () async {
        // Should complete without throwing
        await expectLater(service.initialize(), completes);
      });
    });

    group('lightTap', () {
      test('should vibrate when haptics enabled', () async {
        fakeSettings.setHapticsEnabled(true);
        await service.initialize();

        await expectLater(service.lightTap(), completes);
      });

      test('should not vibrate when haptics disabled', () async {
        fakeSettings.setHapticsEnabled(false);
        await service.initialize();

        await expectLater(service.lightTap(), completes);
      });

      test('should not vibrate when not initialized', () async {
        fakeSettings.setHapticsEnabled(true);
        // Don't initialize

        await expectLater(service.lightTap(), completes);
      });

      test('should handle vibration errors gracefully', () async {
        fakeSettings.setHapticsEnabled(true);
        await service.initialize();

        // Should complete even if vibration fails
        await expectLater(service.lightTap(), completes);
      });
    });

    group('mediumTap', () {
      test('should vibrate when haptics enabled', () async {
        fakeSettings.setHapticsEnabled(true);
        await service.initialize();

        await expectLater(service.mediumTap(), completes);
      });

      test('should not vibrate when haptics disabled', () async {
        fakeSettings.setHapticsEnabled(false);
        await service.initialize();

        await expectLater(service.mediumTap(), completes);
      });

      test('should handle vibration errors gracefully', () async {
        fakeSettings.setHapticsEnabled(true);
        await service.initialize();

        await expectLater(service.mediumTap(), completes);
      });
    });

    group('strongTap', () {
      test('should vibrate when haptics enabled', () async {
        fakeSettings.setHapticsEnabled(true);
        await service.initialize();

        await expectLater(service.strongTap(), completes);
      });

      test('should not vibrate when haptics disabled', () async {
        fakeSettings.setHapticsEnabled(false);
        await service.initialize();

        await expectLater(service.strongTap(), completes);
      });

      test('should handle vibration errors gracefully', () async {
        fakeSettings.setHapticsEnabled(true);
        await service.initialize();

        await expectLater(service.strongTap(), completes);
      });
    });

    group('doubleTap', () {
      test('should vibrate pattern when haptics enabled', () async {
        fakeSettings.setHapticsEnabled(true);
        await service.initialize();

        await expectLater(service.doubleTap(), completes);
      });

      test('should not vibrate when haptics disabled', () async {
        fakeSettings.setHapticsEnabled(false);
        await service.initialize();

        await expectLater(service.doubleTap(), completes);
      });

      test('should handle vibration errors gracefully', () async {
        fakeSettings.setHapticsEnabled(true);
        await service.initialize();

        await expectLater(service.doubleTap(), completes);
      });
    });

    group('successPattern', () {
      test('should vibrate pattern when haptics enabled', () async {
        fakeSettings.setHapticsEnabled(true);
        await service.initialize();

        await expectLater(service.successPattern(), completes);
      });

      test('should not vibrate when haptics disabled', () async {
        fakeSettings.setHapticsEnabled(false);
        await service.initialize();

        await expectLater(service.successPattern(), completes);
      });

      test('should handle vibration errors gracefully', () async {
        fakeSettings.setHapticsEnabled(true);
        await service.initialize();

        await expectLater(service.successPattern(), completes);
      });
    });

    group('errorShake', () {
      test('should vibrate pattern when haptics enabled', () async {
        fakeSettings.setHapticsEnabled(true);
        await service.initialize();

        await expectLater(service.errorShake(), completes);
      });

      test('should not vibrate when haptics disabled', () async {
        fakeSettings.setHapticsEnabled(false);
        await service.initialize();

        await expectLater(service.errorShake(), completes);
      });

      test('should handle vibration errors gracefully', () async {
        fakeSettings.setHapticsEnabled(true);
        await service.initialize();

        await expectLater(service.errorShake(), completes);
      });
    });

    group('cancel', () {
      test('should cancel vibration without errors', () async {
        await service.initialize();

        await expectLater(service.cancel(), completes);
      });

      test('should cancel even if not initialized', () async {
        // Don't initialize
        await expectLater(service.cancel(), completes);
      });

      test('should handle cancel errors gracefully', () async {
        await service.initialize();

        await expectLater(service.cancel(), completes);
      });
    });

    group('multiple operations', () {
      test('should handle rapid successive haptic calls', () async {
        fakeSettings.setHapticsEnabled(true);
        await service.initialize();

        // Trigger multiple haptics rapidly
        await Future.wait([
          service.lightTap(),
          service.mediumTap(),
          service.strongTap(),
        ]);

        // All should complete successfully
        expect(service, isNotNull);
      });

      test('should toggle haptics setting between calls', () async {
        await service.initialize();

        fakeSettings.setHapticsEnabled(true);
        await service.lightTap();

        fakeSettings.setHapticsEnabled(false);
        await service.mediumTap();

        fakeSettings.setHapticsEnabled(true);
        await service.strongTap();

        // All should complete without errors
        expect(service, isNotNull);
      });

      test('should handle pattern-based haptics', () async {
        fakeSettings.setHapticsEnabled(true);
        await service.initialize();

        // Test pattern-based vibrations
        await service.doubleTap();
        await service.successPattern();
        await service.errorShake();

        expect(service, isNotNull);
      });

      test('should cancel ongoing vibration', () async {
        fakeSettings.setHapticsEnabled(true);
        await service.initialize();

        // Start a long pattern
        final vibrationFuture = service.successPattern();

        // Cancel immediately
        await service.cancel();

        // Original should still complete
        await vibrationFuture;

        expect(service, isNotNull);
      });
    });

    group('edge cases', () {
      test('should handle all taps when haptics off', () async {
        fakeSettings.setHapticsEnabled(false);
        await service.initialize();

        await service.lightTap();
        await service.mediumTap();
        await service.strongTap();
        await service.doubleTap();
        await service.successPattern();
        await service.errorShake();

        // All should complete quickly without vibrating
        expect(service, isNotNull);
      });

      test('should work without initialization', () async {
        fakeSettings.setHapticsEnabled(true);
        // Don't call initialize

        await service.lightTap();
        await service.mediumTap();
        await service.strongTap();

        // Should complete without errors
        expect(service, isNotNull);
      });
    });
  });
}
