import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:multigame/providers/mixins/game_stats_mixin.dart';
import 'package:multigame/services/data/achievement_service.dart';
import 'package:multigame/services/data/firebase_stats_service.dart';

/// Provider for managing 2048 game state
class Game2048Provider extends ChangeNotifier with GameStatsMixin {
  final AchievementService _achievementService;
  final FirebaseStatsService _statsService;

  @override
  FirebaseStatsService get statsService => _statsService;

  // Game state
  late List<List<int>> _grid;
  int _score = 0;
  int _bestScore = 0;
  bool _gameOver = false;
  int _currentObjectiveIndex = 0;

  // Progressive objectives
  final List<int> _objectives = [256, 512, 1024, 2048];
  final List<String> _objectiveLabels = ['Easy', 'Medium', 'Hard', 'Expert'];

  final Random _random = Random();

  // Getters
  List<List<int>> get grid => _grid;
  int get score => _score;
  int get bestScore => _bestScore;
  bool get gameOver => _gameOver;
  int get currentObjectiveIndex => _currentObjectiveIndex;
  List<int> get objectives => _objectives;
  List<String> get objectiveLabels => _objectiveLabels;
  int get currentObjective => _objectives[_currentObjectiveIndex];
  String get currentObjectiveLabel => _objectiveLabels[_currentObjectiveIndex];

  Game2048Provider({
    required AchievementService achievementService,
    required FirebaseStatsService statsService,
  })  : _achievementService = achievementService,
        _statsService = statsService {
    initializeGame();
  }

  /// Initialize or reset the game
  void initializeGame() {
    _grid = List.generate(4, (_) => List.filled(4, 0));
    _score = 0;
    _gameOver = false;
    _addRandomTile();
    _addRandomTile();
    notifyListeners();
  }

  /// Add a random tile (2 or 4) to an empty cell
  void _addRandomTile() {
    List<Point<int>> emptyCells = [];
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        if (_grid[i][j] == 0) {
          emptyCells.add(Point(i, j));
        }
      }
    }

    if (emptyCells.isNotEmpty) {
      Point<int> randomCell = emptyCells[_random.nextInt(emptyCells.length)];
      _grid[randomCell.x][randomCell.y] = _random.nextInt(10) < 9 ? 2 : 4;
    }
  }

  /// Move tiles in the specified direction
  bool move(String direction) {
    if (_gameOver) return false;

    bool moved = false;

    switch (direction) {
      case 'left':
        moved = _moveLeft();
        break;
      case 'right':
        moved = _moveRight();
        break;
      case 'up':
        moved = _moveUp();
        break;
      case 'down':
        moved = _moveDown();
        break;
    }

    if (moved) {
      _addRandomTile();

      // Check if game is over (grid is full and no moves possible)
      if (!_canMove()) {
        _gameOver = true;
        _saveScore();
      }

      // Update best score
      if (_score > _bestScore) {
        _bestScore = _score;
      }

      notifyListeners();
    }

    return moved;
  }

  /// Check if any moves are possible
  bool _canMove() {
    // Check if grid has any empty cells
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        if (_grid[i][j] == 0) return true;
      }
    }
    return false;
  }

  /// Merges a compacted (no-zero) line and returns the new padded line and score delta.
  (List<int>, int) _mergeLine(List<int> line) {
    final result = <int>[];
    int score = 0;
    int i = 0;
    while (i < line.length) {
      if (i + 1 < line.length && line[i] == line[i + 1]) {
        final m = line[i] * 2;
        result.add(m);
        score += m;
        i += 2;
      } else {
        result.add(line[i++]);
      }
    }
    while (result.length < 4) { result.add(0); }
    return (result, score);
  }

  /// Move tiles left
  bool _moveLeft() {
    bool moved = false;
    for (int i = 0; i < 4; i++) {
      List<int> row = _grid[i].where((cell) => cell != 0).toList();
      List<int> newRow = [];

      int j = 0;
      while (j < row.length) {
        if (j + 1 < row.length && row[j] == row[j + 1]) {
          int merged = row[j] * 2;
          newRow.add(merged);
          _score += merged;
          j += 2;
        } else {
          newRow.add(row[j]);
          j++;
        }
      }

      while (newRow.length < 4) {
        newRow.add(0);
      }

      if (_grid[i].toString() != newRow.toString()) {
        moved = true;
      }
      _grid[i] = newRow;
    }
    return moved;
  }

  /// Move tiles right
  bool _moveRight() {
    bool moved = false;
    for (int i = 0; i < 4; i++) {
      List<int> row = _grid[i]
          .where((cell) => cell != 0)
          .toList()
          .reversed
          .toList();
      List<int> newRow = [];

      int j = 0;
      while (j < row.length) {
        if (j + 1 < row.length && row[j] == row[j + 1]) {
          int merged = row[j] * 2;
          newRow.add(merged);
          _score += merged;
          j += 2;
        } else {
          newRow.add(row[j]);
          j++;
        }
      }

      while (newRow.length < 4) {
        newRow.add(0);
      }

      newRow = newRow.reversed.toList();
      if (_grid[i].toString() != newRow.toString()) {
        moved = true;
      }
      _grid[i] = newRow;
    }
    return moved;
  }

  /// Move tiles up
  bool _moveUp() {
    bool moved = false;
    for (int j = 0; j < 4; j++) {
      final col = [for (int i = 0; i < 4; i++) if (_grid[i][j] != 0) _grid[i][j]];
      final (newCol, scoreDelta) = _mergeLine(col);
      _score += scoreDelta;
      for (int i = 0; i < 4; i++) {
        if (_grid[i][j] != newCol[i]) moved = true;
        _grid[i][j] = newCol[i];
      }
    }
    return moved;
  }

  /// Move tiles down
  bool _moveDown() {
    bool moved = false;
    for (int j = 0; j < 4; j++) {
      final col = [for (int i = 3; i >= 0; i--) if (_grid[i][j] != 0) _grid[i][j]];
      final (newCol, scoreDelta) = _mergeLine(col);
      _score += scoreDelta;
      for (int i = 0; i < 4; i++) {
        if (_grid[3 - i][j] != newCol[i]) moved = true;
        _grid[3 - i][j] = newCol[i];
      }
    }
    return moved;
  }

  /// Get the highest tile value on the grid
  int getHighestTile() {
    int highestTile = 0;
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        if (_grid[i][j] > highestTile) {
          highestTile = _grid[i][j];
        }
      }
    }
    return highestTile;
  }

  /// Check if the player reached the current objective
  bool hasReachedObjective() {
    return getHighestTile() >= currentObjective;
  }

  /// Check if the player reached at least the minimum objective
  bool hasReachedMinimumObjective() {
    return getHighestTile() >= _objectives[0];
  }

  /// Move to the next objective
  void nextObjective() {
    if (_currentObjectiveIndex < _objectives.length - 1) {
      _currentObjectiveIndex++;
      notifyListeners();
    }
  }

  /// Reset to the first objective
  void resetObjective() {
    _currentObjectiveIndex = 0;
    notifyListeners();
  }

  /// Save score to Firebase
  void _saveScore() {
    saveScore('2048', _score);
  }

  /// Record game completion achievement
  Future<void> recordGameCompletion() async {
    final highestTile = getHighestTile();

    // Determine which level was passed
    String levelPassed = 'None';
    if (highestTile >= 2048) {
      levelPassed = 'Expert (2048)';
    } else if (highestTile >= 1024) {
      levelPassed = 'Hard (1024)';
    } else if (highestTile >= 512) {
      levelPassed = 'Medium (512)';
    } else if (highestTile >= 256) {
      levelPassed = 'Easy (256)';
    }

    await _achievementService.save2048Achievement(
      score: _score,
      highestTile: highestTile,
      levelPassed: levelPassed,
    );
  }
}
