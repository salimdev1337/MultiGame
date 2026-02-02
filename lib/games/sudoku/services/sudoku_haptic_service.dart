import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';
import '../providers/sudoku_settings_provider.dart';

/// Service for providing haptic feedback during Sudoku gameplay.
///
/// Manages vibration feedback with the following features:
/// - Respects haptics enabled/disabled setting
/// - Different vibration patterns for different actions
/// - Checks device capability before attempting vibration
/// - Graceful degradation on unsupported devices
///
/// Haptic feedback events:
/// - Light tap: Cell selection
/// - Medium tap: Number entry, button press
/// - Strong tap: Error, invalid move
/// - Pattern: Victory celebration
class SudokuHapticService {
  final SudokuSettingsProvider _settings;

  /// Whether the device supports vibration
  bool? _hasVibrator;

  SudokuHapticService({required SudokuSettingsProvider settings})
      : _settings = settings;

  /// Initializes the haptic service.
  ///
  /// Checks if the device has vibration capability.
  /// Should be called once when the service is created.
  Future<void> initialize() async {
    try {
      _hasVibrator = await Vibration.hasVibrator();
    } catch (e) {
      debugPrint('Error checking vibration capability: $e');
      _hasVibrator = false;
    }
  }

  /// Checks if haptics can be played.
  ///
  /// Returns true if:
  /// - Haptics are enabled in settings
  /// - Device has vibration capability
  bool get _canVibrate {
    return _settings.hapticsEnabled && (_hasVibrator ?? false);
  }

  /// Performs a light haptic tap.
  ///
  /// Used for subtle feedback like cell selection.
  /// Duration: 10ms
  Future<void> lightTap() async {
    if (!_canVibrate) return;

    try {
      await Vibration.vibrate(duration: 10);
    } catch (e) {
      debugPrint('Error performing light haptic: $e');
    }
  }

  /// Performs a medium haptic tap.
  ///
  /// Used for standard feedback like number entry or button press.
  /// Duration: 20ms
  Future<void> mediumTap() async {
    if (!_canVibrate) return;

    try {
      await Vibration.vibrate(duration: 20);
    } catch (e) {
      debugPrint('Error performing medium haptic: $e');
    }
  }

  /// Performs a strong haptic tap.
  ///
  /// Used for error feedback or invalid moves.
  /// Duration: 40ms
  Future<void> strongTap() async {
    if (!_canVibrate) return;

    try {
      await Vibration.vibrate(duration: 40);
    } catch (e) {
      debugPrint('Error performing strong haptic: $e');
    }
  }

  /// Performs a double tap pattern.
  ///
  /// Used for special actions like hints.
  /// Pattern: 15ms on, 50ms off, 15ms on
  Future<void> doubleTap() async {
    if (!_canVibrate) return;

    try {
      await Vibration.vibrate(
        pattern: [0, 15, 50, 15],
      );
    } catch (e) {
      debugPrint('Error performing double tap haptic: $e');
    }
  }

  /// Performs a success pattern.
  ///
  /// Used for victory/completion celebration.
  /// Pattern: Three ascending taps
  Future<void> successPattern() async {
    if (!_canVibrate) return;

    try {
      await Vibration.vibrate(
        pattern: [0, 30, 100, 40, 100, 50],
      );
    } catch (e) {
      debugPrint('Error performing success haptic: $e');
    }
  }

  /// Performs an error shake pattern.
  ///
  /// Used when player makes an invalid move.
  /// Pattern: Quick burst of vibrations
  Future<void> errorShake() async {
    if (!_canVibrate) return;

    try {
      await Vibration.vibrate(
        pattern: [0, 50, 50, 50],
      );
    } catch (e) {
      debugPrint('Error performing error shake haptic: $e');
    }
  }

  /// Cancels any ongoing vibration.
  ///
  /// Useful for stopping patterns early if needed.
  Future<void> cancel() async {
    try {
      await Vibration.cancel();
    } catch (e) {
      debugPrint('Error cancelling vibration: $e');
    }
  }
}
