import 'package:flutter/material.dart';
import 'package:multigame/design_system/ds_theme.dart';
import 'package:multigame/models/app_theme_preset.dart';
import 'package:multigame/models/avatar_preset.dart';
import 'package:multigame/services/themes/theme_service.dart';

/// Provider for app theme and avatar customisation.
///
/// Handles theme selection, avatar selection, and animation speed.
/// Persists choices via [ThemeService].
class ThemeProvider extends ChangeNotifier {
  ThemeProvider({required ThemeService service}) : _service = service;

  final ThemeService _service;

  ThemePreset _currentTheme = ThemePreset.defaultTheme;
  String? _currentAvatarId;
  double _animationSpeed = ThemeService.defaultAnimationSpeed;
  bool _isLoaded = false;

  // ── Getters ──────────────────────────────────────────────────────────────

  ThemePreset get currentTheme => _currentTheme;
  AppThemePreset get currentThemePreset =>
      AppThemePreset.fromPreset(_currentTheme);
  String? get currentAvatarId => _currentAvatarId;
  double get animationSpeed => _animationSpeed;
  bool get isLoaded => _isLoaded;

  AvatarPreset? get currentAvatar => _currentAvatarId == null
      ? null
      : AvatarPreset.defaults
            .where((a) => a.id == _currentAvatarId)
            .firstOrNull;

  // ── Load ─────────────────────────────────────────────────────────────────

  Future<void> loadTheme() async {
    _currentTheme = await _service.getSelectedTheme();
    _currentAvatarId = await _service.getSelectedAvatar();
    _animationSpeed = await _service.getAnimationSpeed();
    _isLoaded = true;
    notifyListeners();
  }

  // ── Theme ─────────────────────────────────────────────────────────────────

  Future<void> setTheme(ThemePreset preset) async {
    if (_currentTheme == preset) return;
    _currentTheme = preset;
    await _service.setSelectedTheme(preset);
    notifyListeners();
  }

  // ── Avatar ────────────────────────────────────────────────────────────────

  Future<void> setAvatar(String avatarId) async {
    if (_currentAvatarId == avatarId) return;
    _currentAvatarId = avatarId;
    await _service.setSelectedAvatar(avatarId);
    notifyListeners();
  }

  // ── Animation Speed ───────────────────────────────────────────────────────

  Future<void> setAnimationSpeed(double multiplier) async {
    final clamped = multiplier.clamp(0.5, 2.0);
    if (_animationSpeed == clamped) return;
    _animationSpeed = clamped;
    await _service.setAnimationSpeed(clamped);
    notifyListeners();
  }

  // ── Theme Data ────────────────────────────────────────────────────────────

  /// Build a [ThemeData] for the current preset with optional high contrast.
  ThemeData getThemeData({bool highContrast = false}) {
    return DSTheme.buildDynamicTheme(
      primary: currentThemePreset.primary,
      secondary: currentThemePreset.secondary,
      background: currentThemePreset.background,
      surface: currentThemePreset.surface,
      highContrast: highContrast,
    );
  }
}
