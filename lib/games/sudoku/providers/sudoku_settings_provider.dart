import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for Sudoku game settings and preferences.
///
/// Manages user preferences with persistent storage:
/// - Sound effects toggle
/// - Haptic feedback toggle
/// - Error highlighting toggle
/// - Theme preferences (future: light/dark)
///
/// All settings are persisted using SharedPreferences and loaded on init.
class SudokuSettingsProvider extends ChangeNotifier {
  // Settings keys for SharedPreferences
  static const String _keySoundEnabled = 'sudoku_sound_enabled';
  static const String _keyHapticsEnabled = 'sudoku_haptics_enabled';
  static const String _keyErrorHighlighting = 'sudoku_error_highlighting';

  // Settings state
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;
  bool _errorHighlightingEnabled = true;
  bool _isInitialized = false;

  // Getters
  bool get soundEnabled => _soundEnabled;
  bool get hapticsEnabled => _hapticsEnabled;
  bool get errorHighlightingEnabled => _errorHighlightingEnabled;
  bool get isInitialized => _isInitialized;

  /// Initializes settings by loading from SharedPreferences.
  ///
  /// Should be called once when the provider is created.
  /// Returns true if successful, false if error occurred.
  Future<bool> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load settings (default to true if not found)
      _soundEnabled = prefs.getBool(_keySoundEnabled) ?? true;
      _hapticsEnabled = prefs.getBool(_keyHapticsEnabled) ?? true;
      _errorHighlightingEnabled =
          prefs.getBool(_keyErrorHighlighting) ?? true;

      _isInitialized = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error loading Sudoku settings: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Toggles sound effects on/off.
  ///
  /// Persists the setting to SharedPreferences.
  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySoundEnabled, _soundEnabled);
    } catch (e) {
      debugPrint('Error saving sound setting: $e');
    }
  }

  /// Toggles haptic feedback on/off.
  ///
  /// Persists the setting to SharedPreferences.
  Future<void> toggleHaptics() async {
    _hapticsEnabled = !_hapticsEnabled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHapticsEnabled, _hapticsEnabled);
    } catch (e) {
      debugPrint('Error saving haptics setting: $e');
    }
  }

  /// Toggles error highlighting on/off.
  ///
  /// When enabled, conflicting cells are highlighted in red.
  /// Persists the setting to SharedPreferences.
  Future<void> toggleErrorHighlighting() async {
    _errorHighlightingEnabled = !_errorHighlightingEnabled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyErrorHighlighting, _errorHighlightingEnabled);
    } catch (e) {
      debugPrint('Error saving error highlighting setting: $e');
    }
  }

  /// Sets sound enabled state directly (used for testing).
  void setSoundEnabled(bool value) {
    if (_soundEnabled != value) {
      _soundEnabled = value;
      notifyListeners();
    }
  }

  /// Sets haptics enabled state directly (used for testing).
  void setHapticsEnabled(bool value) {
    if (_hapticsEnabled != value) {
      _hapticsEnabled = value;
      notifyListeners();
    }
  }

  /// Sets error highlighting state directly (used for testing).
  void setErrorHighlightingEnabled(bool value) {
    if (_errorHighlightingEnabled != value) {
      _errorHighlightingEnabled = value;
      notifyListeners();
    }
  }

  /// Resets all settings to defaults and persists them.
  Future<void> resetToDefaults() async {
    _soundEnabled = true;
    _hapticsEnabled = true;
    _errorHighlightingEnabled = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySoundEnabled, true);
      await prefs.setBool(_keyHapticsEnabled, true);
      await prefs.setBool(_keyErrorHighlighting, true);
    } catch (e) {
      debugPrint('Error resetting settings: $e');
    }
  }
}
