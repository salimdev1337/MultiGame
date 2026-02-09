// Sudoku haptic service - see docs/SUDOKU_SERVICES.md

import 'package:vibration/vibration.dart';
import 'package:multigame/utils/secure_logger.dart';
import '../providers/sudoku_settings_provider.dart';

class SudokuHapticService {
  final SudokuSettingsProvider _settings;

  bool? _hasVibrator;

  SudokuHapticService({required SudokuSettingsProvider settings})
    : _settings = settings;

  Future<void> initialize() async {
    try {
      _hasVibrator = await Vibration.hasVibrator();
    } catch (e) {
      SecureLogger.error(
        'Failed to check vibration capability',
        error: e,
        tag: 'Haptics',
      );
      _hasVibrator = false;
    }
  }

  bool get _canVibrate {
    return _settings.hapticsEnabled && (_hasVibrator ?? false);
  }

  Future<void> lightTap() async {
    if (!_canVibrate) return;

    try {
      await Vibration.vibrate(duration: 10);
    } catch (e) {
      SecureLogger.error('Haptic feedback failed', error: e, tag: 'Haptics');
    }
  }

  Future<void> mediumTap() async {
    if (!_canVibrate) return;

    try {
      await Vibration.vibrate(duration: 20);
    } catch (e) {
      SecureLogger.error('Haptic feedback failed', error: e, tag: 'Haptics');
    }
  }

  Future<void> strongTap() async {
    if (!_canVibrate) return;

    try {
      await Vibration.vibrate(duration: 40);
    } catch (e) {
      SecureLogger.error('Haptic feedback failed', error: e, tag: 'Haptics');
    }
  }

  Future<void> doubleTap() async {
    if (!_canVibrate) return;

    try {
      await Vibration.vibrate(pattern: [0, 15, 50, 15]);
    } catch (e) {
      SecureLogger.error('Haptic feedback failed', error: e, tag: 'Haptics');
    }
  }

  Future<void> successPattern() async {
    if (!_canVibrate) return;

    try {
      await Vibration.vibrate(pattern: [0, 30, 100, 40, 100, 50]);
    } catch (e) {
      SecureLogger.error('Haptic feedback failed', error: e, tag: 'Haptics');
    }
  }

  Future<void> errorShake() async {
    if (!_canVibrate) return;

    try {
      await Vibration.vibrate(pattern: [0, 50, 50, 50]);
    } catch (e) {
      SecureLogger.error('Haptic feedback failed', error: e, tag: 'Haptics');
    }
  }

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
