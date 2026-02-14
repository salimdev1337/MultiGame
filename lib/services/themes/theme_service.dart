import 'package:multigame/models/app_theme_preset.dart';
import 'package:multigame/repositories/secure_storage_repository.dart';

/// Persists and retrieves user theme preferences.
class ThemeService {
  ThemeService({required SecureStorageRepository storage}) : _storage = storage;

  final SecureStorageRepository _storage;

  static const _themeKey = 'selected_theme_preset';
  static const _avatarKey = 'selected_avatar_id';
  static const _animationSpeedKey = 'animation_speed_multiplier';

  static const defaultAnimationSpeed = 1.0;

  // ── Theme ────────────────────────────────────────────────────────────────

  Future<ThemePreset> getSelectedTheme() async {
    final raw = await _storage.read(_themeKey);
    if (raw == null) return ThemePreset.defaultTheme;
    try {
      return ThemePreset.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => ThemePreset.defaultTheme,
      );
    } catch (_) {
      return ThemePreset.defaultTheme;
    }
  }

  Future<void> setSelectedTheme(ThemePreset preset) async {
    await _storage.write(_themeKey, preset.name);
  }

  // ── Avatar ───────────────────────────────────────────────────────────────

  Future<String?> getSelectedAvatar() async {
    return _storage.read(_avatarKey);
  }

  Future<void> setSelectedAvatar(String avatarId) async {
    await _storage.write(_avatarKey, avatarId);
  }

  // ── Animation Speed ──────────────────────────────────────────────────────

  Future<double> getAnimationSpeed() async {
    final raw = await _storage.read(_animationSpeedKey);
    if (raw == null) return defaultAnimationSpeed;
    return double.tryParse(raw) ?? defaultAnimationSpeed;
  }

  Future<void> setAnimationSpeed(double multiplier) async {
    final clamped = multiplier.clamp(0.5, 2.0);
    await _storage.write(_animationSpeedKey, clamped.toString());
  }
}
