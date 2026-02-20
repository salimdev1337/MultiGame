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

  final FlutterSecureStorage _storage;

  HapticFeedbackService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  bool? _hasVibrator;
  bool _hapticsEnabled = true;

  /// Initialize the service
  Future<void> initialize() async {
    try {
      _hasVibrator = await Vibration.hasVibrator();
      final stored = await _storage.read(key: _storageKey);
      _hapticsEnabled = stored != 'false';
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

  bool get _canVibrate => _hapticsEnabled && (_hasVibrator ?? false);
  bool get isEnabled => _hapticsEnabled;

  Future<void> setEnabled(bool enabled) async {
    _hapticsEnabled = enabled;
    try {
      await _storage.write(key: _storageKey, value: enabled.toString());
    } catch (e) {
      SecureLogger.error(
        'Failed to save haptic preference',
        error: e,
        tag: 'Haptics',
      );
    }
  }

  Future<void> _safeVibrate({int? duration, List<int>? pattern}) async {
    if (!_canVibrate) return;
    try {
      if (pattern != null) {
        await Vibration.vibrate(pattern: pattern);
      } else {
        await Vibration.vibrate(duration: duration ?? 10);
      }
    } catch (e) {
      SecureLogger.error(_hapticFailed, error: e, tag: 'Haptics');
    }
  }

  // ==========================================
  // Basic Feedback Patterns
  // ==========================================

  /// Light tap (10ms) - For button presses, selections
  Future<void> lightTap() => _safeVibrate(duration: 10);

  /// Medium tap (20ms) - For important actions
  Future<void> mediumTap() => _safeVibrate(duration: 20);

  /// Strong tap (40ms) - For critical actions
  Future<void> strongTap() => _safeVibrate(duration: 40);

  /// Double tap pattern - For toggle actions
  Future<void> doubleTap() => _safeVibrate(pattern: [0, 15, 50, 15]);

  // ==========================================
  // Semantic Feedback Patterns
  // ==========================================

  /// Success pattern - For achievements, completions
  Future<void> success() => _safeVibrate(pattern: [0, 30, 100, 40, 100, 50]);

  /// Error pattern - For mistakes, invalid actions
  Future<void> error() => _safeVibrate(pattern: [0, 50, 50, 50, 50, 50]);

  /// Warning pattern - For alerts, important notifications
  Future<void> warning() => _safeVibrate(pattern: [0, 40, 80, 40]);

  /// Notification pattern - For new messages, updates
  Future<void> notification() => _safeVibrate(duration: 30);

  /// Selection change - For picker scrolls, list selections
  Future<void> selectionChanged() => _safeVibrate(duration: 5);

  /// Impact - For collisions, game events
  Future<void> impact() => _safeVibrate(duration: 50);

  // ==========================================
  // Advanced Patterns
  // ==========================================

  /// Long press start - For long-press interactions
  Future<void> longPressStart() => _safeVibrate(duration: 25);

  /// Celebration pattern - For major achievements
  Future<void> celebration() =>
      _safeVibrate(pattern: [0, 30, 50, 40, 50, 50, 50, 60]);

  /// Custom pattern
  Future<void> customPattern(List<int> pattern) =>
      _safeVibrate(pattern: pattern);

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

  /// Dispose the service — cancels any in-progress vibration
  Future<void> dispose() async {
    await cancel();
  }
}
