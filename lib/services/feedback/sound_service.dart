/// App-Wide Sound Service
/// Provides audio feedback for user interactions
/// Part of Phase 6: Micro-interactions & Feedback
library;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:multigame/utils/secure_logger.dart';

/// App-wide sound service
///
/// Provides audio feedback for various interactions:
/// - UI sounds: taps, selections, toggles
/// - Feedback sounds: success, error, warning
/// - Game sounds: move, collect, achievement
class SoundService {
  static const String _storageKey = 'app_sound_enabled';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  AudioPlayer? _player;
  bool _soundEnabled = true;
  bool _isInitialized = false;

  /// Initialize the service
  Future<void> initialize() async {
    try {
      // Configure audio player
      _player = AudioPlayer();
      await _player!.setReleaseMode(ReleaseMode.stop);
      await _player!.setVolume(0.6);

      // Load user preference
      final stored = await _storage.read(key: _storageKey);
      _soundEnabled = stored != 'false'; // Default to true

      _isInitialized = true;

      SecureLogger.log(
        'Sound service initialized (enabled: $_soundEnabled)',
        tag: 'Sound',
      );
    } catch (e) {
      SecureLogger.error(
        'Failed to initialize sound service',
        error: e,
        tag: 'Sound',
      );
      _isInitialized = false;
    }
  }

  /// Get current enabled state
  bool get isEnabled => _soundEnabled;

  /// Enable or disable sounds
  Future<void> setEnabled(bool enabled) async {
    _soundEnabled = enabled;
    try {
      await _storage.write(
        key: _storageKey,
        value: enabled.toString(),
      );
    } catch (e) {
      SecureLogger.error(
        'Failed to save sound preference',
        error: e,
        tag: 'Sound',
      );
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      await _player?.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      SecureLogger.error('Failed to set volume', error: e, tag: 'Sound');
    }
  }

  /// Internal method to play a tone
  Future<void> _playTone({
    required double frequency,
    required int duration,
    double volume = 1.0,
  }) async {
    if (!_soundEnabled || !_isInitialized) {
      return;
    }

    try {
      // Note: This logs the sound parameters
      // In a production app, you would use actual sound files or synthesize tones
      SecureLogger.log(
        'Sound: ${frequency}Hz, ${duration}ms, vol=$volume',
        tag: 'Sound',
      );
    } catch (e) {
      SecureLogger.error('Sound playback failed', error: e, tag: 'Sound');
    }
  }

  // ==========================================
  // UI Sounds
  // ==========================================

  /// Light tap sound - For button presses
  Future<void> tap() async {
    await _playTone(frequency: 800, duration: 30, volume: 0.3);
  }

  /// Selection sound - For list/option selections
  Future<void> select() async {
    await _playTone(frequency: 1000, duration: 50, volume: 0.4);
  }

  /// Toggle sound - For switches, checkboxes
  Future<void> toggle() async {
    await _playTone(frequency: 1200, duration: 40, volume: 0.35);
  }

  /// Pop sound - For modals, dialogs opening
  Future<void> pop() async {
    await _playTone(frequency: 900, duration: 60, volume: 0.4);
  }

  /// Dismiss sound - For modals, dialogs closing
  Future<void> dismiss() async {
    await _playTone(frequency: 700, duration: 50, volume: 0.3);
  }

  /// Page transition sound
  Future<void> pageTransition() async {
    await _playTone(frequency: 850, duration: 70, volume: 0.3);
  }

  // ==========================================
  // Feedback Sounds
  // ==========================================

  /// Success sound - For successful actions
  Future<void> success() async {
    // Ascending three-note pattern
    await _playTone(frequency: 800, duration: 80, volume: 0.6);
    await Future.delayed(const Duration(milliseconds: 80));
    await _playTone(frequency: 1000, duration: 80, volume: 0.6);
    await Future.delayed(const Duration(milliseconds: 80));
    await _playTone(frequency: 1200, duration: 150, volume: 0.6);
  }

  /// Error sound - For errors, mistakes
  Future<void> error() async {
    // Low descending tone
    await _playTone(frequency: 400, duration: 100, volume: 0.6);
    await Future.delayed(const Duration(milliseconds: 50));
    await _playTone(frequency: 300, duration: 150, volume: 0.6);
  }

  /// Warning sound - For warnings, alerts
  Future<void> warning() async {
    // Two medium beeps
    await _playTone(frequency: 900, duration: 100, volume: 0.5);
    await Future.delayed(const Duration(milliseconds: 100));
    await _playTone(frequency: 900, duration: 100, volume: 0.5);
  }

  /// Info/Notification sound
  Future<void> notification() async {
    await _playTone(frequency: 1100, duration: 100, volume: 0.5);
  }

  // ==========================================
  // Game Sounds
  // ==========================================

  /// Move/action sound - For game moves
  Future<void> move() async {
    await _playTone(frequency: 950, duration: 60, volume: 0.4);
  }

  /// Collect sound - For collecting items
  Future<void> collect() async {
    await _playTone(frequency: 1400, duration: 80, volume: 0.5);
  }

  /// Achievement unlocked sound
  Future<void> achievement() async {
    // Celebratory ascending pattern
    await _playTone(frequency: 800, duration: 70, volume: 0.7);
    await Future.delayed(const Duration(milliseconds: 60));
    await _playTone(frequency: 1000, duration: 70, volume: 0.7);
    await Future.delayed(const Duration(milliseconds: 60));
    await _playTone(frequency: 1200, duration: 70, volume: 0.7);
    await Future.delayed(const Duration(milliseconds: 60));
    await _playTone(frequency: 1500, duration: 150, volume: 0.7);
  }

  /// Level up sound
  Future<void> levelUp() async {
    // Quick ascending scale
    for (var i = 0; i < 5; i++) {
      await _playTone(
        frequency: 800 + (i * 100),
        duration: 50,
        volume: 0.6,
      );
      await Future.delayed(const Duration(milliseconds: 40));
    }
  }

  /// Game over sound
  Future<void> gameOver() async {
    // Descending sad tone
    await _playTone(frequency: 800, duration: 100, volume: 0.6);
    await Future.delayed(const Duration(milliseconds: 80));
    await _playTone(frequency: 600, duration: 100, volume: 0.6);
    await Future.delayed(const Duration(milliseconds: 80));
    await _playTone(frequency: 400, duration: 200, volume: 0.6);
  }

  /// Victory/win sound
  Future<void> victory() async {
    // Triumphant fanfare
    await _playTone(frequency: 800, duration: 100, volume: 0.7);
    await Future.delayed(const Duration(milliseconds: 100));
    await _playTone(frequency: 1000, duration: 100, volume: 0.7);
    await Future.delayed(const Duration(milliseconds: 100));
    await _playTone(frequency: 1200, duration: 200, volume: 0.7);
  }

  /// Hint/help sound
  Future<void> hint() async {
    await _playTone(frequency: 1500, duration: 120, volume: 0.5);
  }

  /// Undo sound
  Future<void> undo() async {
    await _playTone(frequency: 900, duration: 70, volume: 0.4);
  }

  /// Countdown tick sound
  Future<void> tick() async {
    await _playTone(frequency: 1100, duration: 30, volume: 0.4);
  }

  /// Countdown final seconds (urgent tick)
  Future<void> urgentTick() async {
    await _playTone(frequency: 1300, duration: 40, volume: 0.6);
  }

  // ==========================================
  // Advanced Features
  // ==========================================

  /// Stop any currently playing sound
  Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (e) {
      SecureLogger.error('Failed to stop sound', error: e, tag: 'Sound');
    }
  }

  /// Dispose of the service
  Future<void> dispose() async {
    try {
      await _player?.dispose();
    } catch (e) {
      SecureLogger.error('Failed to dispose sound service', error: e, tag: 'Sound');
    }
  }
}
