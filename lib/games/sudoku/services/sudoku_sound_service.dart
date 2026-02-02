import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../providers/sudoku_settings_provider.dart';

/// Service for playing Sudoku game sound effects.
///
/// Manages audio playback with the following features:
/// - Respects sound enabled/disabled setting
/// - Multiple sound effects for different actions
/// - Non-blocking playback (doesn't interrupt gameplay)
/// - Graceful error handling for missing assets
///
/// Sound events:
/// - Cell selection: Soft tap sound
/// - Number entry: Confirmation beep
/// - Error: Alert/warning sound
/// - Hint used: Helper sound
/// - Victory: Success fanfare
/// - Undo: Reverse action sound
/// - Erase: Delete sound
class SudokuSoundService {
  final SudokuSettingsProvider _settings;
  final AudioPlayer _player = AudioPlayer();

  /// Whether the service is initialized and ready
  bool _isInitialized = false;

  SudokuSoundService({required SudokuSettingsProvider settings})
      : _settings = settings;

  /// Initializes the audio service.
  ///
  /// Should be called once when the service is created.
  /// Sets up the audio player with proper configuration.
  Future<void> initialize() async {
    try {
      // Set audio player mode for low latency sound effects
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setVolume(0.6); // 60% volume for pleasant feedback
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing Sudoku sound service: $e');
      _isInitialized = false;
    }
  }

  /// Plays a sound effect if sound is enabled.
  ///
  /// [frequency] - Frequency of the tone in Hz
  /// [duration] - Duration in milliseconds
  /// [volume] - Volume multiplier (0.0-1.0)
  Future<void> _playSound({
    required double frequency,
    required int duration,
    double volume = 1.0,
  }) async {
    // Check if sound is enabled
    if (!_settings.soundEnabled || !_isInitialized) {
      return;
    }

    try {
      // For now, we'll use a simple approach without actual audio files
      // In a production app, you would load audio assets here
      // Example: await _player.play(AssetSource('sounds/cell_select.mp3'));

      // Since we don't have audio assets, we'll use a silent approach
      // that can be extended later when assets are added
      debugPrint(
        'Sound: frequency=${frequency}Hz, duration=${duration}ms, volume=$volume',
      );

      // TODO: Add actual audio file playback when assets are available
      // await _player.play(AssetSource('sounds/...'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  /// Plays sound when a cell is selected.
  ///
  /// A soft, subtle tap sound for non-intrusive feedback.
  Future<void> playSelectCell() async {
    await _playSound(
      frequency: 800,
      duration: 50,
      volume: 0.3,
    );
  }

  /// Plays sound when a number is entered in a cell.
  ///
  /// A confirming beep to acknowledge the input.
  Future<void> playNumberEntry() async {
    await _playSound(
      frequency: 1200,
      duration: 100,
      volume: 0.5,
    );
  }

  /// Plays sound when an invalid move is made.
  ///
  /// A warning/alert sound to indicate an error.
  Future<void> playError() async {
    await _playSound(
      frequency: 300,
      duration: 200,
      volume: 0.6,
    );
  }

  /// Plays sound when a hint is used.
  ///
  /// A helpful, positive sound for assistance.
  Future<void> playHint() async {
    await _playSound(
      frequency: 1500,
      duration: 150,
      volume: 0.5,
    );
  }

  /// Plays sound when the puzzle is completed.
  ///
  /// A celebratory, triumphant sound.
  Future<void> playVictory() async {
    // Play a sequence of ascending tones for victory
    await _playSound(frequency: 800, duration: 100, volume: 0.7);
    await Future.delayed(const Duration(milliseconds: 100));
    await _playSound(frequency: 1000, duration: 100, volume: 0.7);
    await Future.delayed(const Duration(milliseconds: 100));
    await _playSound(frequency: 1200, duration: 200, volume: 0.7);
  }

  /// Plays sound when undo is pressed.
  ///
  /// A reverse-action sound effect.
  Future<void> playUndo() async {
    await _playSound(
      frequency: 900,
      duration: 80,
      volume: 0.4,
    );
  }

  /// Plays sound when erase is pressed.
  ///
  /// A deletion sound effect.
  Future<void> playErase() async {
    await _playSound(
      frequency: 700,
      duration: 100,
      volume: 0.4,
    );
  }

  /// Plays sound when notes mode is toggled.
  ///
  /// A mode-switch sound effect.
  Future<void> playNotesToggle() async {
    await _playSound(
      frequency: 1000,
      duration: 60,
      volume: 0.3,
    );
  }

  /// Disposes of the audio player resources.
  ///
  /// Should be called when the service is no longer needed.
  Future<void> dispose() async {
    await _player.dispose();
  }
}
