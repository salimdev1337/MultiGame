/// App-Wide Haptic Feedback Service
/// Provides tactile feedback for user interactions
/// Part of Phase 6: Micro-interactions & Feedback
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vibration/vibration.dart';
import 'package:multigame/utils/secure_logger.dart';

/// App-wide haptic feedback service
///
/// Provides various haptic patterns for different interaction types:
/// - Light tap: Button presses, selections
/// - Medium tap: Important actions, confirmations
/// - Strong tap: Critical actions, warnings
/// - Success: Achievements, game wins
/// - Error: Mistakes, invalid actions
/// - Warning: Alerts, important notifications
class HapticFeedbackService {
  static const String _storageKey = 'app_haptics_enabled';
  static const String _hapticFailed = 'Haptic feedback failed';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  bool? _hasVibrator;
  bool _hapticsEnabled = true;

  /// Initialize the service
  Future<void> initialize() async {
    try {
      // Check device capability
      _hasVibrator = await Vibration.hasVibrator();

      // Load user preference
      final stored = await _storage.read(key: _storageKey);
      _hapticsEnabled = stored != 'false'; // Default to true

      SecureLogger.log(
        'Haptic service initialized (enabled: $_hapticsEnabled, capable: $_hasVibrator)',
        tag: 'Haptics',
      );
    } catch (e) {
      SecureLogger.error(
        'Failed to initialize haptic service',
        error: e,
        tag: 'Haptics',
      );
      _hasVibrator = false;
    }
  }

  /// Check if haptics can be triggered
  bool get _canVibrate {
    return _hapticsEnabled && (_hasVibrator ?? false);
  }

  /// Get current enabled state
  bool get isEnabled => _hapticsEnabled;

  /// Enable or disable haptics
  Future<void> setEnabled(bool enabled) async {
    _hapticsEnabled = enabled;
    try {
      await _storage.write(
        key: _storageKey,
        value: enabled.toString(),
      );
    } catch (e) {
      SecureLogger.error(
        'Failed to save haptic preference',
        error: e,
        tag: 'Haptics',
      );
    }
  }

  // ==========================================
  // Basic Feedback Patterns
  // ==========================================

  /// Light tap (10ms) - For button presses, selections
  Future<void> lightTap() async {
    if (!_canVibrate) return;

    try {
      await Vibration.vibrate(duration: 10);
    } catch (e) {
      SecureLogger.error(_hapticFailed, error: e, tag: 'Haptics');
    }
  }

  /// Medium tap (20ms) - For important actions
  Future<void> mediumTap() async {
    if (!_canVibrate) return;

    try {
      await Vibration.vibrate(duration: 20);
    } catch (e) {
      SecureLogger.error(_hapticFailed, error: e, tag: 'Haptics');
    }
  }

  /// Strong tap (40ms) - For critical actions
  Future<void> strongTap() async {
    if (!_canVibrate) return;

    try {
      await Vibration.vibrate(duration: 40);
    } catch (e) {
      SecureLogger.error(_hapticFailed, error: e, tag: 'Haptics');
    }
  }

  /// Double tap pattern - For toggle actions
  Future<void> doubleTap() async {
    if (!_canVibrate) return;

    try {
      await Vibration.vibrate(pattern: [0, 15, 50, 15]);
    } catch (e) {
      SecureLogger.error(_hapticFailed, error: e, tag: 'Haptics');
    }
  }

  // ==========================================
  // Semantic Feedback Patterns
  // ==========================================

  /// Success pattern - For achievements, completions
  /// Pattern: short - pause - medium - pause - long
  Future<void> success() async {
    if (!_canVibrate) return;

    try {
      await Vibration.vibrate(pattern: [0, 30, 100, 40, 100, 50]);
    } catch (e) {
      SecureLogger.error(_hapticFailed, error: e, tag: 'Haptics');
    }
  }

  /// Error pattern - For mistakes, invalid actions
  /// Pattern: three quick vibrations (shake)
  Future<void> error() async {
    if (!_canVibrate) return;

    try {
      await Vibration.vibrate(pattern: [0, 50, 50, 50, 50, 50]);
    } catch (e) {
      SecureLogger.error(_hapticFailed, error: e, tag: 'Haptics');
    }
  }

  /// Warning pattern - For alerts, important notifications
  /// Pattern: two medium vibrations
  Future<void> warning() async {
    if (!_canVibrate) return;

    try {
      await Vibration.vibrate(pattern: [0, 40, 80, 40]);
    } catch (e) {
      SecureLogger.error(_hapticFailed, error: e, tag: 'Haptics');
    }
  }

  /// Notification pattern - For new messages, updates
  /// Pattern: single medium vibration
  Future<void> notification() async {
    if (!_canVibrate) return;

    try {
      await Vibration.vibrate(duration: 30);
    } catch (e) {
      SecureLogger.error(_hapticFailed, error: e, tag: 'Haptics');
    }
  }

  /// Selection change - For picker scrolls, list selections
  Future<void> selectionChanged() async {
    if (!_canVibrate) return;

    try {
      await Vibration.vibrate(duration: 5);
    } catch (e) {
      SecureLogger.error(_hapticFailed, error: e, tag: 'Haptics');
    }
  }

  /// Impact - For collisions, game events
  /// Pattern: strong single impact
  Future<void> impact() async {
    if (!_canVibrate) return;

    try {
      await Vibration.vibrate(duration: 50);
    } catch (e) {
      SecureLogger.error(_hapticFailed, error: e, tag: 'Haptics');
    }
  }

  // ==========================================
  // Advanced Patterns
  // ==========================================

  /// Long press start - For long-press interactions
  Future<void> longPressStart() async {
    if (!_canVibrate) return;

    try {
      await Vibration.vibrate(duration: 25);
    } catch (e) {
      SecureLogger.error(_hapticFailed, error: e, tag: 'Haptics');
    }
  }

  /// Celebration pattern - For major achievements
  /// Pattern: Three ascending vibrations
  Future<void> celebration() async {
    if (!_canVibrate) return;

    try {
      await Vibration.vibrate(pattern: [0, 30, 50, 40, 50, 50, 50, 60]);
    } catch (e) {
      SecureLogger.error(_hapticFailed, error: e, tag: 'Haptics');
    }
  }

  /// Custom pattern
  /// Pass your own vibration pattern
  Future<void> customPattern(List<int> pattern) async {
    if (!_canVibrate) return;

    try {
      await Vibration.vibrate(pattern: pattern);
    } catch (e) {
      SecureLogger.error(_hapticFailed, error: e, tag: 'Haptics');
    }
  }

  /// Cancel any ongoing vibration
  Future<void> cancel() async {
    try {
      await Vibration.cancel();
    } catch (e) {
      SecureLogger.error(
        'Failed to cancel vibration',
        error: e,
        tag: 'Haptics',
      );
    }
  }
}
