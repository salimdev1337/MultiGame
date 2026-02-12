import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:multigame/utils/secure_logger.dart';

class SudokuSettingsState {
  static const _keySoundEnabled = 'sudoku_sound_enabled';
  static const _keyHapticsEnabled = 'sudoku_haptics_enabled';
  static const _keyErrorHighlighting = 'sudoku_error_highlighting';

  final bool soundEnabled;
  final bool hapticsEnabled;
  final bool errorHighlightingEnabled;
  final bool isInitialized;
  final String? lastError;

  const SudokuSettingsState({
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.errorHighlightingEnabled = true,
    this.isInitialized = false,
    this.lastError,
  });

  SudokuSettingsState copyWith({
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? errorHighlightingEnabled,
    bool? isInitialized,
    String? lastError,
    bool clearError = false,
  }) {
    return SudokuSettingsState(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      errorHighlightingEnabled:
          errorHighlightingEnabled ?? this.errorHighlightingEnabled,
      isInitialized: isInitialized ?? this.isInitialized,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

class SudokuSettingsNotifier extends AsyncNotifier<SudokuSettingsState> {
  @override
  Future<SudokuSettingsState> build() async {
    final prefs = await SharedPreferences.getInstance();
    return SudokuSettingsState(
      soundEnabled:
          prefs.getBool(SudokuSettingsState._keySoundEnabled) ?? true,
      hapticsEnabled:
          prefs.getBool(SudokuSettingsState._keyHapticsEnabled) ?? true,
      errorHighlightingEnabled:
          prefs.getBool(SudokuSettingsState._keyErrorHighlighting) ?? true,
      isInitialized: true,
    );
  }

  Future<void> toggleSound() async {
    final current = state.valueOrNull;
    if (current == null) return;
    final newValue = !current.soundEnabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(SudokuSettingsState._keySoundEnabled, newValue);
      state = AsyncData(current.copyWith(soundEnabled: newValue, clearError: true));
    } catch (e) {
      SecureLogger.error('Failed to save sound setting', error: e,
          tag: 'SudokuSettings');
      state = AsyncData(current.copyWith(lastError: 'Failed to save sound setting'));
    }
  }

  Future<void> toggleHaptics() async {
    final current = state.valueOrNull;
    if (current == null) return;
    final newValue = !current.hapticsEnabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(SudokuSettingsState._keyHapticsEnabled, newValue);
      state = AsyncData(current.copyWith(hapticsEnabled: newValue, clearError: true));
    } catch (e) {
      SecureLogger.error('Failed to save haptics setting', error: e,
          tag: 'SudokuSettings');
      state = AsyncData(current.copyWith(lastError: 'Failed to save haptics setting'));
    }
  }

  Future<void> toggleErrorHighlighting() async {
    final current = state.valueOrNull;
    if (current == null) return;
    final newValue = !current.errorHighlightingEnabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
          SudokuSettingsState._keyErrorHighlighting, newValue);
      state = AsyncData(current.copyWith(
          errorHighlightingEnabled: newValue, clearError: true));
    } catch (e) {
      SecureLogger.error('Failed to save error highlighting setting',
          error: e, tag: 'SudokuSettings');
      state = AsyncData(current.copyWith(
          lastError: 'Failed to save error highlighting setting'));
    }
  }

  Future<void> resetToDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(SudokuSettingsState._keySoundEnabled, true);
      await prefs.setBool(SudokuSettingsState._keyHapticsEnabled, true);
      await prefs.setBool(SudokuSettingsState._keyErrorHighlighting, true);
      state = const AsyncData(SudokuSettingsState(isInitialized: true));
    } catch (e) {
      SecureLogger.error('Failed to reset settings', error: e,
          tag: 'SudokuSettings');
    }
  }

  void clearError() {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(clearError: true));
    }
  }
}

/// Not autoDispose — settings persist across the app lifetime.
final sudokuSettingsProvider =
    AsyncNotifierProvider<SudokuSettingsNotifier, SudokuSettingsState>(
        SudokuSettingsNotifier.new);
