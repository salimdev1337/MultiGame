// Sudoku settings provider - see docs/SUDOKU_ARCHITECTURE.md

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:multigame/utils/secure_logger.dart';

class SudokuSettingsProvider extends ChangeNotifier {
  static const String _keySoundEnabled = 'sudoku_sound_enabled';
  static const String _keyHapticsEnabled = 'sudoku_haptics_enabled';
  static const String _keyErrorHighlighting = 'sudoku_error_highlighting';

  bool _soundEnabled = true;
  bool _hapticsEnabled = true;
  bool _errorHighlightingEnabled = true;
  bool _isInitialized = false;
  String? _lastError;

  bool get soundEnabled => _soundEnabled;
  bool get hapticsEnabled => _hapticsEnabled;
  bool get errorHighlightingEnabled => _errorHighlightingEnabled;
  bool get isInitialized => _isInitialized;
  String? get lastError => _lastError;

  /// Clear the last error message
  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  Future<bool> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _soundEnabled = prefs.getBool(_keySoundEnabled) ?? true;
      _hapticsEnabled = prefs.getBool(_keyHapticsEnabled) ?? true;
      _errorHighlightingEnabled =
          prefs.getBool(_keyErrorHighlighting) ?? true;

      _isInitialized = true;
      notifyListeners();
      return true;
    } catch (e) {
      SecureLogger.error('Failed to load Sudoku settings', error: e, tag: 'SudokuSettings');
      _isInitialized = false;
      return false;
    }
  }

  Future<bool> toggleSound() async {
    final newValue = !_soundEnabled;
    _lastError = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySoundEnabled, newValue);
      _soundEnabled = newValue;
      notifyListeners();
      return true;
    } catch (e) {
      SecureLogger.error('Failed to save sound setting', error: e, tag: 'SudokuSettings');
      _lastError = 'Failed to save sound setting';
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleHaptics() async {
    final newValue = !_hapticsEnabled;
    _lastError = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyHapticsEnabled, newValue);
      _hapticsEnabled = newValue;
      notifyListeners();
      return true;
    } catch (e) {
      SecureLogger.error('Failed to save haptics setting', error: e, tag: 'SudokuSettings');
      _lastError = 'Failed to save haptics setting';
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleErrorHighlighting() async {
    final newValue = !_errorHighlightingEnabled;
    _lastError = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyErrorHighlighting, newValue);
      _errorHighlightingEnabled = newValue;
      notifyListeners();
      return true;
    } catch (e) {
      SecureLogger.error('Failed to save error highlighting setting', error: e, tag: 'SudokuSettings');
      _lastError = 'Failed to save error highlighting setting';
      notifyListeners();
      return false;
    }
  }

  void setSoundEnabled(bool value) {
    if (_soundEnabled != value) {
      _soundEnabled = value;
      notifyListeners();
    }
  }

  void setHapticsEnabled(bool value) {
    if (_hapticsEnabled != value) {
      _hapticsEnabled = value;
      notifyListeners();
    }
  }

  void setErrorHighlightingEnabled(bool value) {
    if (_errorHighlightingEnabled != value) {
      _errorHighlightingEnabled = value;
      notifyListeners();
    }
  }

  Future<bool> resetToDefaults() async {
    _lastError = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keySoundEnabled, true);
      await prefs.setBool(_keyHapticsEnabled, true);
      await prefs.setBool(_keyErrorHighlighting, true);

      _soundEnabled = true;
      _hapticsEnabled = true;
      _errorHighlightingEnabled = true;
      notifyListeners();
      return true;
    } catch (e) {
      SecureLogger.error('Failed to reset settings', error: e, tag: 'SudokuSettings');
      _lastError = 'Failed to reset settings';
      notifyListeners();
      return false;
    }
  }
}
