import 'package:flutter/material.dart';
import 'package:multigame/repositories/secure_storage_repository.dart';

/// Service for managing accessibility settings
///
/// Handles persistence and retrieval of user accessibility preferences
/// including reduced motion, high contrast, font scaling, and screen reader settings.
class AccessibilityService {
  final SecureStorageRepository _storage;

  // Storage keys
  static const String _reducedMotionKey = 'accessibility_reduced_motion';
  static const String _highContrastKey = 'accessibility_high_contrast';
  static const String _fontScaleKey = 'accessibility_font_scale';
  static const String _screenReaderKey = 'accessibility_screen_reader_enabled';

  /// Default values
  static const bool defaultReducedMotion = false;
  static const bool defaultHighContrast = false;
  static const double defaultFontScale = 1.0;
  static const bool defaultScreenReader = false;

  AccessibilityService({required SecureStorageRepository storage})
    : _storage = storage;

  // ==========================================
  // Reduced Motion
  // ==========================================

  /// Get user's reduced motion preference
  Future<bool> getReducedMotion() async {
    final value = await _storage.read(_reducedMotionKey);
    if (value == null) return defaultReducedMotion;
    return value.toLowerCase() == 'true';
  }

  /// Set user's reduced motion preference
  Future<void> setReducedMotion(bool enabled) async {
    await _storage.write(_reducedMotionKey, enabled.toString());
  }

  // ==========================================
  // High Contrast Mode
  // ==========================================

  /// Get user's high contrast preference
  Future<bool> getHighContrast() async {
    final value = await _storage.read(_highContrastKey);
    if (value == null) return defaultHighContrast;
    return value.toLowerCase() == 'true';
  }

  /// Set user's high contrast preference
  Future<void> setHighContrast(bool enabled) async {
    await _storage.write(_highContrastKey, enabled.toString());
  }

  // ==========================================
  // Font Scaling
  // ==========================================

  /// Get user's font scale preference (0.8 - 2.0)
  Future<double> getFontScale() async {
    final value = await _storage.read(_fontScaleKey);
    if (value == null) return defaultFontScale;
    return double.tryParse(value) ?? defaultFontScale;
  }

  /// Set user's font scale preference
  Future<void> setFontScale(double scale) async {
    // Clamp between 0.8 and 2.0
    final clampedScale = scale.clamp(0.8, 2.0);
    await _storage.write(_fontScaleKey, clampedScale.toString());
  }

  // ==========================================
  // Screen Reader Support
  // ==========================================

  /// Get user's screen reader enabled preference
  Future<bool> getScreenReaderEnabled() async {
    final value = await _storage.read(_screenReaderKey);
    if (value == null) return defaultScreenReader;
    return value.toLowerCase() == 'true';
  }

  /// Set user's screen reader enabled preference
  Future<void> setScreenReaderEnabled(bool enabled) async {
    await _storage.write(_screenReaderKey, enabled.toString());
  }

  // ==========================================
  // System Preference Detection
  // ==========================================

  /// Detect if system has reduced motion enabled
  /// Uses MediaQuery to check platform accessibility settings
  bool detectSystemReducedMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Detect system font scale
  /// Uses MediaQuery to get platform text scaling
  double detectSystemFontScale(BuildContext context) {
    return MediaQuery.textScalerOf(context).scale(1.0);
  }

  /// Detect if system has high contrast enabled
  /// Uses MediaQuery to check platform accessibility settings
  bool detectSystemHighContrast(BuildContext context) {
    return MediaQuery.highContrastOf(context);
  }

  /// Detect if system has bold text enabled
  bool detectSystemBoldText(BuildContext context) {
    return MediaQuery.boldTextOf(context);
  }

  // ==========================================
  // Reset & Sync
  // ==========================================

  /// Reset all accessibility settings to defaults
  Future<void> resetToDefaults() async {
    await setReducedMotion(defaultReducedMotion);
    await setHighContrast(defaultHighContrast);
    await setFontScale(defaultFontScale);
    await setScreenReaderEnabled(defaultScreenReader);
  }

  /// Sync settings with system preferences
  /// Useful for first-time setup to match user's system settings
  Future<void> syncWithSystem(BuildContext context) async {
    // Capture system settings before async operations
    final systemReducedMotion = detectSystemReducedMotion(context);
    final systemHighContrast = detectSystemHighContrast(context);
    final systemFontScale = detectSystemFontScale(context);

    // Only sync if user hasn't customized settings yet
    final currentReducedMotion = await getReducedMotion();
    final currentHighContrast = await getHighContrast();

    // Sync reduced motion if not customized
    if (currentReducedMotion == defaultReducedMotion && systemReducedMotion) {
      await setReducedMotion(true);
    }

    // Sync high contrast if not customized
    if (currentHighContrast == defaultHighContrast && systemHighContrast) {
      await setHighContrast(true);
    }

    // Sync font scale
    if (systemFontScale != 1.0) {
      await setFontScale(systemFontScale);
    }
  }

  // ==========================================
  // Batch Operations
  // ==========================================

  /// Get all accessibility settings at once
  Future<AccessibilitySettings> getAllSettings() async {
    return AccessibilitySettings(
      reducedMotion: await getReducedMotion(),
      highContrast: await getHighContrast(),
      fontScale: await getFontScale(),
      screenReaderEnabled: await getScreenReaderEnabled(),
    );
  }

  /// Set all accessibility settings at once
  Future<void> setAllSettings(AccessibilitySettings settings) async {
    await setReducedMotion(settings.reducedMotion);
    await setHighContrast(settings.highContrast);
    await setFontScale(settings.fontScale);
    await setScreenReaderEnabled(settings.screenReaderEnabled);
  }
}

/// Data class for accessibility settings
class AccessibilitySettings {
  final bool reducedMotion;
  final bool highContrast;
  final double fontScale;
  final bool screenReaderEnabled;

  const AccessibilitySettings({
    required this.reducedMotion,
    required this.highContrast,
    required this.fontScale,
    required this.screenReaderEnabled,
  });

  /// Create settings with default values
  factory AccessibilitySettings.defaults() {
    return const AccessibilitySettings(
      reducedMotion: AccessibilityService.defaultReducedMotion,
      highContrast: AccessibilityService.defaultHighContrast,
      fontScale: AccessibilityService.defaultFontScale,
      screenReaderEnabled: AccessibilityService.defaultScreenReader,
    );
  }

  /// Copy with modifications
  AccessibilitySettings copyWith({
    bool? reducedMotion,
    bool? highContrast,
    double? fontScale,
    bool? screenReaderEnabled,
  }) {
    return AccessibilitySettings(
      reducedMotion: reducedMotion ?? this.reducedMotion,
      highContrast: highContrast ?? this.highContrast,
      fontScale: fontScale ?? this.fontScale,
      screenReaderEnabled: screenReaderEnabled ?? this.screenReaderEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccessibilitySettings &&
        other.reducedMotion == reducedMotion &&
        other.highContrast == highContrast &&
        other.fontScale == fontScale &&
        other.screenReaderEnabled == screenReaderEnabled;
  }

  @override
  int get hashCode {
    return Object.hash(
      reducedMotion,
      highContrast,
      fontScale,
      screenReaderEnabled,
    );
  }

  @override
  String toString() {
    return 'AccessibilitySettings('
        'reducedMotion: $reducedMotion, '
        'highContrast: $highContrast, '
        'fontScale: $fontScale, '
        'screenReaderEnabled: $screenReaderEnabled'
        ')';
  }
}
