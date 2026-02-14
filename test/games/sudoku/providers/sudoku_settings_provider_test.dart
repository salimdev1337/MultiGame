import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:multigame/games/sudoku/providers/sudoku_settings_provider.dart';

void main() {
  group('SudokuSettingsProvider', () {
    late SudokuSettingsProvider provider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      provider = SudokuSettingsProvider();
    });

    group('initialization', () {
      test('initializes with default values before loading', () {
        expect(provider.soundEnabled, true);
        expect(provider.hapticsEnabled, true);
        expect(provider.errorHighlightingEnabled, true);
        expect(provider.isInitialized, false);
        expect(provider.lastError, isNull);
      });

      test('loads settings from SharedPreferences successfully', () async {
        SharedPreferences.setMockInitialValues({
          'sudoku_sound_enabled': false,
          'sudoku_haptics_enabled': false,
          'sudoku_error_highlighting': false,
        });

        provider = SudokuSettingsProvider();
        final result = await provider.initialize();

        expect(result, true);
        expect(provider.soundEnabled, false);
        expect(provider.hapticsEnabled, false);
        expect(provider.errorHighlightingEnabled, false);
        expect(provider.isInitialized, true);
      });

      test('uses default values when no saved settings exist', () async {
        final result = await provider.initialize();

        expect(result, true);
        expect(provider.soundEnabled, true);
        expect(provider.hapticsEnabled, true);
        expect(provider.errorHighlightingEnabled, true);
        expect(provider.isInitialized, true);
      });

      test('notifies listeners after initialization', () async {
        var notified = false;
        provider.addListener(() => notified = true);

        await provider.initialize();

        expect(notified, true);
      });
    });

    group('toggleSound', () {
      test('toggles sound setting on and off', () async {
        await provider.initialize();

        expect(provider.soundEnabled, true);

        final result1 = await provider.toggleSound();
        expect(result1, true);
        expect(provider.soundEnabled, false);

        final result2 = await provider.toggleSound();
        expect(result2, true);
        expect(provider.soundEnabled, true);
      });

      test('persists sound setting to SharedPreferences', () async {
        await provider.initialize();

        await provider.toggleSound();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('sudoku_sound_enabled'), false);
      });

      test('notifies listeners when sound is toggled', () async {
        await provider.initialize();

        var notified = false;
        provider.addListener(() => notified = true);

        await provider.toggleSound();

        expect(notified, true);
      });

      test('clears last error before toggling', () async {
        await provider.initialize();
        provider.clearError(); // Simulate having an error

        await provider.toggleSound();

        expect(provider.lastError, isNull);
      });
    });

    group('toggleHaptics', () {
      test('toggles haptics setting on and off', () async {
        await provider.initialize();

        expect(provider.hapticsEnabled, true);

        final result1 = await provider.toggleHaptics();
        expect(result1, true);
        expect(provider.hapticsEnabled, false);

        final result2 = await provider.toggleHaptics();
        expect(result2, true);
        expect(provider.hapticsEnabled, true);
      });

      test('persists haptics setting to SharedPreferences', () async {
        await provider.initialize();

        await provider.toggleHaptics();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('sudoku_haptics_enabled'), false);
      });

      test('notifies listeners when haptics is toggled', () async {
        await provider.initialize();

        var notified = false;
        provider.addListener(() => notified = true);

        await provider.toggleHaptics();

        expect(notified, true);
      });
    });

    group('toggleErrorHighlighting', () {
      test('toggles error highlighting setting on and off', () async {
        await provider.initialize();

        expect(provider.errorHighlightingEnabled, true);

        final result1 = await provider.toggleErrorHighlighting();
        expect(result1, true);
        expect(provider.errorHighlightingEnabled, false);

        final result2 = await provider.toggleErrorHighlighting();
        expect(result2, true);
        expect(provider.errorHighlightingEnabled, true);
      });

      test(
        'persists error highlighting setting to SharedPreferences',
        () async {
          await provider.initialize();

          await provider.toggleErrorHighlighting();

          final prefs = await SharedPreferences.getInstance();
          expect(prefs.getBool('sudoku_error_highlighting'), false);
        },
      );

      test('notifies listeners when error highlighting is toggled', () async {
        await provider.initialize();

        var notified = false;
        provider.addListener(() => notified = true);

        await provider.toggleErrorHighlighting();

        expect(notified, true);
      });
    });

    group('setSoundEnabled', () {
      test('updates sound setting and notifies listeners', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setSoundEnabled(false);

        expect(provider.soundEnabled, false);
        expect(notified, true);
      });

      test('does not notify if value is unchanged', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setSoundEnabled(true); // Already true

        expect(notified, false);
      });
    });

    group('setHapticsEnabled', () {
      test('updates haptics setting and notifies listeners', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setHapticsEnabled(false);

        expect(provider.hapticsEnabled, false);
        expect(notified, true);
      });

      test('does not notify if value is unchanged', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setHapticsEnabled(true); // Already true

        expect(notified, false);
      });
    });

    group('setErrorHighlightingEnabled', () {
      test('updates error highlighting setting and notifies listeners', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setErrorHighlightingEnabled(false);

        expect(provider.errorHighlightingEnabled, false);
        expect(notified, true);
      });

      test('does not notify if value is unchanged', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.setErrorHighlightingEnabled(true); // Already true

        expect(notified, false);
      });
    });

    group('resetToDefaults', () {
      test('resets all settings to default values', () async {
        await provider.initialize();

        // Change all settings
        await provider.toggleSound();
        await provider.toggleHaptics();
        await provider.toggleErrorHighlighting();

        expect(provider.soundEnabled, false);
        expect(provider.hapticsEnabled, false);
        expect(provider.errorHighlightingEnabled, false);

        // Reset
        final result = await provider.resetToDefaults();

        expect(result, true);
        expect(provider.soundEnabled, true);
        expect(provider.hapticsEnabled, true);
        expect(provider.errorHighlightingEnabled, true);
      });

      test('persists default values to SharedPreferences', () async {
        await provider.initialize();
        await provider.toggleSound();

        await provider.resetToDefaults();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('sudoku_sound_enabled'), true);
        expect(prefs.getBool('sudoku_haptics_enabled'), true);
        expect(prefs.getBool('sudoku_error_highlighting'), true);
      });

      test('notifies listeners after reset', () async {
        await provider.initialize();

        var notified = false;
        provider.addListener(() => notified = true);

        await provider.resetToDefaults();

        expect(notified, true);
      });

      test('clears last error before reset', () async {
        await provider.initialize();

        await provider.resetToDefaults();

        expect(provider.lastError, isNull);
      });
    });

    group('clearError', () {
      test('clears the last error message', () {
        provider.clearError();

        expect(provider.lastError, isNull);
      });

      test('notifies listeners when error is cleared', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider.clearError();

        expect(notified, true);
      });
    });

    group('integration scenarios', () {
      test('handles full settings lifecycle', () async {
        // Initialize
        await provider.initialize();
        expect(provider.isInitialized, true);

        // Toggle settings
        await provider.toggleSound();
        expect(provider.soundEnabled, false);

        await provider.toggleHaptics();
        expect(provider.hapticsEnabled, false);

        // Reset to defaults
        await provider.resetToDefaults();
        expect(provider.soundEnabled, true);
        expect(provider.hapticsEnabled, true);
        expect(provider.errorHighlightingEnabled, true);
      });

      test('settings persist across provider instances', () async {
        await provider.initialize();
        await provider.toggleSound();
        await provider.toggleHaptics();

        // Create new provider instance
        final newProvider = SudokuSettingsProvider();
        await newProvider.initialize();

        expect(newProvider.soundEnabled, false);
        expect(newProvider.hapticsEnabled, false);
      });
    });
  });
}
