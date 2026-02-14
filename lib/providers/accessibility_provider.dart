import 'package:flutter/material.dart';
import 'package:multigame/design_system/ds_animations.dart';
import 'package:multigame/services/accessibility/accessibility_service.dart';

/// Provider for accessibility settings
///
/// Manages app-wide accessibility state including reduced motion,
/// high contrast mode, font scaling, and screen reader support.
/// Persists settings via AccessibilityService.
class AccessibilityProvider extends ChangeNotifier {
  final AccessibilityService _service;

  bool _reducedMotionEnabled = AccessibilityService.defaultReducedMotion;
  bool _highContrastEnabled = AccessibilityService.defaultHighContrast;
  double _fontScale = AccessibilityService.defaultFontScale;
  bool _screenReaderEnabled = AccessibilityService.defaultScreenReader;
  bool _isLoaded = false;

  AccessibilityProvider({required AccessibilityService service})
    : _service = service;

  // ==========================================
  // Getters
  // ==========================================

  bool get reducedMotionEnabled => _reducedMotionEnabled;
  bool get highContrastEnabled => _highContrastEnabled;
  double get fontScale => _fontScale;
  bool get screenReaderEnabled => _screenReaderEnabled;
  bool get isLoaded => _isLoaded;

  // ==========================================
  // Load Settings
  // ==========================================

  /// Load all settings from persistent storage
  /// Must be called during app initialization
  Future<void> loadSettings() async {
    final settings = await _service.getAllSettings();

    _reducedMotionEnabled = settings.reducedMotion;
    _highContrastEnabled = settings.highContrast;
    _fontScale = settings.fontScale;
    _screenReaderEnabled = settings.screenReaderEnabled;
    _isLoaded = true;

    // Apply to design system
    DSAnimations.setReducedMotion(_reducedMotionEnabled);

    notifyListeners();
  }

  // ==========================================
  // Reduced Motion
  // ==========================================

  Future<void> setReducedMotion(bool enabled) async {
    if (_reducedMotionEnabled == enabled) return;
    _reducedMotionEnabled = enabled;
    DSAnimations.setReducedMotion(enabled);
    await _service.setReducedMotion(enabled);
    notifyListeners();
  }

  Future<void> toggleReducedMotion() =>
      setReducedMotion(!_reducedMotionEnabled);

  // ==========================================
  // High Contrast
  // ==========================================

  Future<void> setHighContrast(bool enabled) async {
    if (_highContrastEnabled == enabled) return;
    _highContrastEnabled = enabled;
    await _service.setHighContrast(enabled);
    notifyListeners();
  }

  Future<void> toggleHighContrast() => setHighContrast(!_highContrastEnabled);

  // ==========================================
  // Font Scale
  // ==========================================

  Future<void> setFontScale(double scale) async {
    final clamped = scale.clamp(0.8, 2.0);
    if (_fontScale == clamped) return;
    _fontScale = clamped;
    await _service.setFontScale(clamped);
    notifyListeners();
  }

  // ==========================================
  // Screen Reader
  // ==========================================

  Future<void> setScreenReaderEnabled(bool enabled) async {
    if (_screenReaderEnabled == enabled) return;
    _screenReaderEnabled = enabled;
    await _service.setScreenReaderEnabled(enabled);
    notifyListeners();
  }

  Future<void> toggleScreenReader() =>
      setScreenReaderEnabled(!_screenReaderEnabled);

  // ==========================================
  // System Sync
  // ==========================================

  /// Sync with system accessibility preferences
  Future<void> syncWithSystem(BuildContext context) async {
    await _service.syncWithSystem(context);
    await loadSettings();
  }

  // ==========================================
  // Reset
  // ==========================================

  Future<void> resetToDefaults() async {
    await _service.resetToDefaults();
    _reducedMotionEnabled = AccessibilityService.defaultReducedMotion;
    _highContrastEnabled = AccessibilityService.defaultHighContrast;
    _fontScale = AccessibilityService.defaultFontScale;
    _screenReaderEnabled = AccessibilityService.defaultScreenReader;
    DSAnimations.setReducedMotion(false);
    notifyListeners();
  }
}
