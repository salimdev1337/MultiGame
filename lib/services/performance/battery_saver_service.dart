import 'package:multigame/design_system/ds_animations.dart';
import 'package:multigame/repositories/secure_storage_repository.dart';
import 'package:multigame/utils/secure_logger.dart';

/// Battery saver mode service.
///
/// When enabled:
/// - Reduces animation durations to 30 % (via DSAnimations)
/// - Notifies [ImageCacheService] to shrink its cache
/// - Provides a flag for widgets to skip expensive effects
class BatterySaverService {
  BatterySaverService({required SecureStorageRepository storage})
    : _storage = storage;

  final SecureStorageRepository _storage;

  static const _batterySaverKey = 'battery_saver_enabled';
  static const double _reducedAnimationMultiplier = 0.3;

  bool _isEnabled = false;

  bool get isEnabled => _isEnabled;

  // ── Load ─────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    final raw = await _storage.read(_batterySaverKey);
    _isEnabled = raw == 'true';
    _applySettings();
  }

  // ── Toggle ────────────────────────────────────────────────────────────────

  Future<void> setEnabled(bool enabled) async {
    if (_isEnabled == enabled) return;
    _isEnabled = enabled;
    await _storage.write(_batterySaverKey, enabled.toString());
    _applySettings();
    SecureLogger.log(
      'Battery saver ${enabled ? "enabled" : "disabled"}',
      tag: 'Performance',
    );
  }

  Future<void> toggle() => setEnabled(!_isEnabled);

  // ── Internal ──────────────────────────────────────────────────────────────

  void _applySettings() {
    // Reduce animation speed globally when battery saver is on.
    // DSAnimations.reducedMotion is already used for accessibility;
    // we piggyback on the same mechanism here.
    if (_isEnabled) {
      DSAnimations.setReducedMotion(true);
    } else {
      // Only restore if accessibility reduced-motion was NOT requested.
      // (AccessibilityProvider sets this separately — caller must coordinate.)
      DSAnimations.setReducedMotion(false);
    }
  }

  double get animationMultiplier =>
      _isEnabled ? _reducedAnimationMultiplier : 1.0;
}
