import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:multigame/services/achievement_service.dart';

/// Provider for managing 2048 game state
class Game2048Provider extends ChangeNotifier {
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
  final AchievementService _achievementService = AchievementService();

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

  Game2048Provider() {
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
      List<int> column = [];
      for (int i = 0; i < 4; i++) {
        if (_grid[i][j] != 0) {
          column.add(_grid[i][j]);
        }
      }

      List<int> newColumn = [];
      int i = 0;
      while (i < column.length) {
        if (i + 1 < column.length && column[i] == column[i + 1]) {
          int merged = column[i] * 2;
          newColumn.add(merged);
          _score += merged;
          i += 2;
        } else {
          newColumn.add(column[i]);
          i++;
        }
      }

      while (newColumn.length < 4) {
        newColumn.add(0);
      }

      for (int i = 0; i < 4; i++) {
        if (_grid[i][j] != newColumn[i]) {
          moved = true;
        }
        _grid[i][j] = newColumn[i];
      }
    }
    return moved;
  }

  /// Move tiles down
  bool _moveDown() {
    bool moved = false;
    for (int j = 0; j < 4; j++) {
      List<int> column = [];
      for (int i = 3; i >= 0; i--) {
        if (_grid[i][j] != 0) {
          column.add(_grid[i][j]);
        }
      }

      List<int> newColumn = [];
      int i = 0;
      while (i < column.length) {
        if (i + 1 < column.length && column[i] == column[i + 1]) {
          int merged = column[i] * 2;
          newColumn.add(merged);
          _score += merged;
          i += 2;
        } else {
          newColumn.add(column[i]);
          i++;
        }
      }

      while (newColumn.length < 4) {
        newColumn.add(0);
      }

      for (int i = 0; i < 4; i++) {
        if (_grid[3 - i][j] != newColumn[i]) {
          moved = true;
        }
        _grid[3 - i][j] = newColumn[i];
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
