// Sudoku sound service - see docs/SUDOKU_SERVICES.md

import 'package:audioplayers/audioplayers.dart';
import 'package:multigame/utils/secure_logger.dart';
import '../providers/sudoku_settings_provider.dart';

class SudokuSoundService {
  final SudokuSettingsProvider _settings;
  final AudioPlayer _player = AudioPlayer();

  bool _isInitialized = false;

  SudokuSoundService({required SudokuSettingsProvider settings})
    : _settings = settings;

  Future<void> initialize() async {
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setVolume(0.6);
      _isInitialized = true;
    } catch (e) {
      SecureLogger.error(
        'Failed to initialize sound service',
        error: e,
        tag: 'Sound',
      );
      _isInitialized = false;
    }
  }

  Future<void> _playSound({
    required double frequency,
    required int duration,
    double volume = 1.0,
  }) async {
    if (!_settings.soundEnabled || !_isInitialized) {
      return;
    }

    try {
      SecureLogger.log(
        'Playing sound: ${frequency}Hz, ${duration}ms, vol=$volume',
        tag: 'Sound',
      );
    } catch (e) {
      SecureLogger.error('Sound playback failed', error: e, tag: 'Sound');
    }
  }

  Future<void> playSelectCell() async {
    await _playSound(frequency: 800, duration: 50, volume: 0.3);
  }

  Future<void> playNumberEntry() async {
    await _playSound(frequency: 1200, duration: 100, volume: 0.5);
  }

  Future<void> playError() async {
    await _playSound(frequency: 300, duration: 200, volume: 0.6);
  }

  Future<void> playHint() async {
    await _playSound(frequency: 1500, duration: 150, volume: 0.5);
  }

  Future<void> playVictory() async {
    await _playSound(frequency: 800, duration: 100, volume: 0.7);
    await Future.delayed(const Duration(milliseconds: 100));
    await _playSound(frequency: 1000, duration: 100, volume: 0.7);
    await Future.delayed(const Duration(milliseconds: 100));
    await _playSound(frequency: 1200, duration: 200, volume: 0.7);
  }

  Future<void> playUndo() async {
    await _playSound(frequency: 900, duration: 80, volume: 0.4);
  }

  Future<void> playErase() async {
    await _playSound(frequency: 700, duration: 100, volume: 0.4);
  }

  Future<void> playNotesToggle() async {
    await _playSound(frequency: 1000, duration: 60, volume: 0.3);
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
