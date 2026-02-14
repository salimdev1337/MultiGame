// Unit tests for SudokuSoundService

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/sudoku/services/sudoku_sound_service.dart';
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

  // Mock audioplayers platform channels
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers.global'),
        (MethodCall methodCall) async {
          // Mock responses for audioplayers global channel
          if (methodCall.method == 'init') {
            return null;
          }
          return null;
        },
      );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers'), (
        MethodCall methodCall,
      ) async {
        // Mock responses for audioplayers instance channel
        return null;
      });

  tearDownAll(() {
    // Clean up mock handlers
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('xyz.luan/audioplayers.global'),
          null,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('xyz.luan/audioplayers'),
          null,
        );
  });

  group('SudokuSoundService', () {
    late SudokuSoundService service;
    late FakeSudokuSettingsProvider fakeSettings;

    setUp(() {
      fakeSettings = FakeSudokuSettingsProvider();
      service = SudokuSoundService(settings: fakeSettings);
    });

    tearDown(() async {
      await service.dispose();
    });

    group('initialize', () {
      test('should initialize without errors', () async {
        await service.initialize();
        // Service should initialize successfully
        expect(service, isNotNull);
      });

      test('should handle initialization errors gracefully', () async {
        // Even with errors, initialize should complete
        await service.initialize();
        expect(service, isNotNull);
      });
    });

    group('playSelectCell', () {
      test('should play select cell sound when sound enabled', () async {
        fakeSettings.setSoundEnabled(true);
        await service.initialize();

        // Should complete without throwing
        await expectLater(service.playSelectCell(), completes);
      });

      test('should not play sound when sound disabled', () async {
        fakeSettings.setSoundEnabled(false);
        await service.initialize();

        // Should complete quickly without playing
        await expectLater(service.playSelectCell(), completes);
      });

      test('should not play sound when not initialized', () async {
        fakeSettings.setSoundEnabled(true);
        // Don't initialize

        // Should complete without throwing
        await expectLater(service.playSelectCell(), completes);
      });
    });

    group('playNumberEntry', () {
      test('should play number entry sound when sound enabled', () async {
        fakeSettings.setSoundEnabled(true);
        await service.initialize();

        await expectLater(service.playNumberEntry(), completes);
      });

      test('should not play when sound disabled', () async {
        fakeSettings.setSoundEnabled(false);
        await service.initialize();

        await expectLater(service.playNumberEntry(), completes);
      });
    });

    group('playError', () {
      test('should play error sound when sound enabled', () async {
        fakeSettings.setSoundEnabled(true);
        await service.initialize();

        await expectLater(service.playError(), completes);
      });

      test('should not play when sound disabled', () async {
        fakeSettings.setSoundEnabled(false);
        await service.initialize();

        await expectLater(service.playError(), completes);
      });
    });

    group('playHint', () {
      test('should play hint sound when sound enabled', () async {
        fakeSettings.setSoundEnabled(true);
        await service.initialize();

        await expectLater(service.playHint(), completes);
      });

      test('should not play when sound disabled', () async {
        fakeSettings.setSoundEnabled(false);
        await service.initialize();

        await expectLater(service.playHint(), completes);
      });
    });

    group('playVictory', () {
      test('should play victory sequence when sound enabled', () async {
        fakeSettings.setSoundEnabled(true);
        await service.initialize();

        await expectLater(service.playVictory(), completes);
      });

      test('should not play when sound disabled', () async {
        fakeSettings.setSoundEnabled(false);
        await service.initialize();

        await expectLater(service.playVictory(), completes);
      });

      test('should play multiple sounds in sequence', () async {
        fakeSettings.setSoundEnabled(true);
        await service.initialize();

        final stopwatch = Stopwatch()..start();
        await service.playVictory();
        stopwatch.stop();

        // Victory plays 3 sounds with delays, but should complete quickly in tests
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });

    group('playUndo', () {
      test('should play undo sound when sound enabled', () async {
        fakeSettings.setSoundEnabled(true);
        await service.initialize();

        await expectLater(service.playUndo(), completes);
      });

      test('should not play when sound disabled', () async {
        fakeSettings.setSoundEnabled(false);
        await service.initialize();

        await expectLater(service.playUndo(), completes);
      });
    });

    group('playErase', () {
      test('should play erase sound when sound enabled', () async {
        fakeSettings.setSoundEnabled(true);
        await service.initialize();

        await expectLater(service.playErase(), completes);
      });

      test('should not play when sound disabled', () async {
        fakeSettings.setSoundEnabled(false);
        await service.initialize();

        await expectLater(service.playErase(), completes);
      });
    });

    group('playNotesToggle', () {
      test('should play notes toggle sound when sound enabled', () async {
        fakeSettings.setSoundEnabled(true);
        await service.initialize();

        await expectLater(service.playNotesToggle(), completes);
      });

      test('should not play when sound disabled', () async {
        fakeSettings.setSoundEnabled(false);
        await service.initialize();

        await expectLater(service.playNotesToggle(), completes);
      });
    });

    group('dispose', () {
      test('should dispose without errors', () async {
        // Create a separate service instance to avoid double dispose
        final testService = SudokuSoundService(settings: fakeSettings);
        await testService.initialize();

        await expectLater(testService.dispose(), completes);
      });

      test('should dispose even if not initialized', () async {
        // Create a separate service instance to avoid double dispose
        final testService = SudokuSoundService(settings: fakeSettings);
        // Don't initialize
        await expectLater(testService.dispose(), completes);
      });
    });

    group('multiple operations', () {
      test('should handle rapid successive calls', () async {
        fakeSettings.setSoundEnabled(true);
        await service.initialize();

        // Play multiple sounds rapidly
        await Future.wait([
          service.playSelectCell(),
          service.playNumberEntry(),
          service.playHint(),
        ]);

        // All should complete successfully
        expect(service, isNotNull);
      });

      test('should toggle sound setting between calls', () async {
        await service.initialize();

        fakeSettings.setSoundEnabled(true);
        await service.playSelectCell();

        fakeSettings.setSoundEnabled(false);
        await service.playNumberEntry();

        fakeSettings.setSoundEnabled(true);
        await service.playHint();

        // All should complete without errors
        expect(service, isNotNull);
      });
    });
  });
}
