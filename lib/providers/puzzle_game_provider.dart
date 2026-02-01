import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:multigame/games/puzzle_game_logic.dart';
import 'package:multigame/providers/mixins/game_stats_mixin.dart';
import 'package:multigame/services/data/achievement_service.dart';
import 'package:multigame/services/data/firebase_stats_service.dart';
import 'package:multigame/utils/secure_logger.dart';

/// Provider for managing puzzle game state
class PuzzleGameNotifier extends ChangeNotifier with GameStatsMixin {
  final AchievementService _achievementService;
  final FirebaseStatsService _statsService;

  @override
  FirebaseStatsService get statsService => _statsService;

  PuzzleGame? _game;
  int _gridSize = 4;
  int _moveCount = 0;
  int _elapsedSeconds = 0;
  Timer? _timer;

  PuzzleGameNotifier({
    required AchievementService achievementService,
    required FirebaseStatsService statsService,
  })  : _achievementService = achievementService,
        _statsService = statsService;

  // Getters
  PuzzleGame? get game => _game;
  int get gridSize => _gridSize;
  int get moveCount => _moveCount;
  int get elapsedSeconds => _elapsedSeconds;
  bool get isGameInitialized => _game != null;

  /// Initialize the game
  Future<void> initializeGame() async {
    _setMoveCount(0);

    _game = PuzzleGame(gridSize: _gridSize);
    await _game!.loadPuzzleImages();

    _startTimer();
    notifyListeners();
  }

  /// Reset the current game with the same image
  Future<void> resetGame() async {
    if (_game == null) return;

    _setMoveCount(0);

    await _game!.loadPuzzleImages();
    _startTimer();
    notifyListeners();
  }

  /// Start a new game with a new image
  Future<void> newImageGame() async {
    if (_game == null) return;

    _setMoveCount(0);

    await _game!.loadNewPuzzle();
    _startTimer();
    notifyListeners();
  }

  /// Change grid size and reinitialize game
  Future<void> changeGridSize(int newSize) async {
    if (newSize == _gridSize) return;

    _gridSize = newSize;
    _setMoveCount(0);

    _game = PuzzleGame(gridSize: _gridSize);
    await _game!.loadPuzzleImages();
    _startTimer();
    notifyListeners();
  }

  /// Move a puzzle piece
  bool movePiece(int position) {
    if (_game == null || !_game!.movePiece(position)) {
      return false;
    }

    _setMoveCount(_moveCount + 1);

    // Check if game is solved
    if (_game!.isSolved) {
      _cancelTimer();
      _saveScore();
      notifyListeners();
      return true;
    }

    notifyListeners();
    return true;
  }

  /// Start or restart the timer
  void _startTimer() {
    _cancelTimer();
    _elapsedSeconds = 0;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_game == null || _game!.isSolved) {
        _cancelTimer();
        return;
      }

      _elapsedSeconds++;
      notifyListeners();
    });
  }

  /// Cancel the timer
  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Stop the timer (used when game is won)
  void stopTimer() {
    _cancelTimer();
    notifyListeners();
  }

  /// Set move count
  void _setMoveCount(int value) {
    if (_moveCount != value) {
      _moveCount = value;
      notifyListeners();
    }
  }

  /// Record game completion and get new achievements
  Future<List<String>> recordGameCompletion() async {
    if (_game == null) return [];

    return await _achievementService.recordGameCompletion(
      gridSize: _gridSize,
      moves: _moveCount,
      seconds: _elapsedSeconds,
    );
  }

  /// Save score to Firebase
  void _saveScore() {
    if (_moveCount > 0) {
      // Calculate score based on moves and time (lower is better)
      // Score = 10000 - (moves * 10) - elapsed seconds
      final score = (10000 - (_moveCount * 10) - _elapsedSeconds).clamp(
        0,
        10000,
      );

      SecureLogger.firebase('Saving puzzle score', details: 'score: $score');
      saveScore('puzzle', score);
    }
  }

  /// Format time as MM:SS
  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }
}
