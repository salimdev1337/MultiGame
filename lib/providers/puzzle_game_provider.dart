import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:multigame/game_logic.dart';
import 'package:multigame/services/achievement_service.dart';

/// Provider for managing puzzle game state
class PuzzleGameNotifier extends ChangeNotifier {
  PuzzleGame? _game;
  int _gridSize = 4;
  bool _isLoading = true;
  bool _isNewImageLoading = false;
  int _moveCount = 0;
  int _elapsedSeconds = 0;
  Timer? _timer;
  bool _showImagePreview = false;
  final AchievementService _achievementService = AchievementService();

  // Getters
  PuzzleGame? get game => _game;
  int get gridSize => _gridSize;
  bool get isLoading => _isLoading;
  bool get isNewImageLoading => _isNewImageLoading;
  int get moveCount => _moveCount;
  int get elapsedSeconds => _elapsedSeconds;
  bool get showImagePreview => _showImagePreview;
  bool get isGameInitialized => _game != null;

  /// Initialize the game
  Future<void> initializeGame() async {
    _setLoading(true);
    _setMoveCount(0);

    _game = PuzzleGame(gridSize: _gridSize);
    await _game!.loadPuzzleImages();

    _setLoading(false);
    _startTimer();
    notifyListeners();
  }

  /// Reset the current game with the same image
  Future<void> resetGame() async {
    if (_game == null) return;

    _setNewImageLoading(false);
    _setMoveCount(0);

    await _game!.loadPuzzleImages();
    _startTimer();
    notifyListeners();
  }

  /// Start a new game with a new image
  Future<void> newImageGame() async {
    if (_game == null) return;

    _setNewImageLoading(true);
    _setMoveCount(0);

    await _game!.loadNewPuzzle();
    _startTimer();
    _setNewImageLoading(false);
    notifyListeners();
  }

  /// Change grid size and reinitialize game
  Future<void> changeGridSize(int newSize) async {
    if (newSize == _gridSize) return;

    _gridSize = newSize;
    _setLoading(true);
    _setMoveCount(0);

    _game = PuzzleGame(gridSize: _gridSize);
    await _game!.loadPuzzleImages();
    _startTimer();
    _setLoading(false);
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

  /// Set loading state
  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  /// Set new image loading state
  void _setNewImageLoading(bool value) {
    if (_isNewImageLoading != value) {
      _isNewImageLoading = value;
      notifyListeners();
    }
  }

  /// Set move count
  void _setMoveCount(int value) {
    if (_moveCount != value) {
      _moveCount = value;
      notifyListeners();
    }
  }

  /// Set image preview visibility
  void setShowImagePreview(bool value) {
    if (_showImagePreview != value) {
      _showImagePreview = value;
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
