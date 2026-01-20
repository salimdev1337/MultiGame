import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';

enum Direction { up, down, left, right }

enum GameMode { classic, wrap, speed }

/// Provider for managing Snake game state
class SnakeGameProvider extends ChangeNotifier {
  static const int gridSize = 20;

  // Game state
  List<Offset> _snake = [const Offset(5, 10)];
  Offset _food = const Offset(10, 10);
  Direction _currentDirection = Direction.right;
  Direction _nextDirection = Direction.right;
  GameMode _gameMode = GameMode.classic;
  Timer? _timer;
  bool _playing = true;
  int _score = 0;
  int _highScore = 0;

  // Getters
  List<Offset> get snake => _snake;
  Offset get food => _food;
  Direction get currentDirection => _currentDirection;
  GameMode get gameMode => _gameMode;
  bool get playing => _playing;
  int get score => _score;
  int get highScore => _highScore;

  Duration get tickRate {
    switch (_gameMode) {
      case GameMode.speed:
        return const Duration(milliseconds: 120);
      case GameMode.wrap:
      case GameMode.classic:
        return const Duration(milliseconds: 200);
    }
  }

  SnakeGameProvider() {
    startGame();
  }

  /// Start or restart the game
  void startGame() {
    _timer?.cancel();
    _snake = [const Offset(5, 10)];
    _currentDirection = Direction.right;
    _nextDirection = Direction.right;
    _score = 0;
    _playing = true;
    _spawnFood();
    notifyListeners();

    _timer = Timer.periodic(tickRate, (_) {
      if (_playing) _tick();
    });
  }

  /// Change game mode and restart
  void setGameMode(GameMode mode) {
    _gameMode = mode;
    startGame();
  }

  /// Spawn food at a random position
  void _spawnFood() {
    final rand = Random();
    Offset pos;
    do {
      pos = Offset(
        rand.nextInt(gridSize).toDouble(),
        rand.nextInt(gridSize).toDouble(),
      );
    } while (_snake.contains(pos));
    _food = pos;
  }

  /// Game tick - move snake and check collisions
  void _tick() {
    _currentDirection = _nextDirection;
    final head = _snake.first;
    Offset next;

    switch (_currentDirection) {
      case Direction.up:
        next = Offset(head.dx, head.dy - 1);
        break;
      case Direction.down:
        next = Offset(head.dx, head.dy + 1);
        break;
      case Direction.left:
        next = Offset(head.dx - 1, head.dy);
        break;
      case Direction.right:
        next = Offset(head.dx + 1, head.dy);
        break;
    }

    if (_gameMode == GameMode.wrap) {
      next = Offset(
        (next.dx + gridSize) % gridSize,
        (next.dy + gridSize) % gridSize,
      );
    } else {
      if (next.dx < 0 ||
          next.dy < 0 ||
          next.dx >= gridSize ||
          next.dy >= gridSize) {
        _gameOver();
        return;
      }
    }

    if (_snake.contains(next)) {
      _gameOver();
      return;
    }

    _snake.insert(0, next);

    if (next == _food) {
      _score += 10;
      _spawnFood();
    } else {
      _snake.removeLast();
    }

    notifyListeners();
  }

  /// End the game
  void _gameOver() {
    _playing = false;
    _timer?.cancel();
    // Update high score
    if (_score > _highScore) {
      _highScore = _score;
    }
    notifyListeners();
  }

  /// Change snake direction
  void changeDirection(Direction d) {
    if ((_currentDirection == Direction.up && d == Direction.down) ||
        (_currentDirection == Direction.down && d == Direction.up) ||
        (_currentDirection == Direction.left && d == Direction.right) ||
        (_currentDirection == Direction.right && d == Direction.left)) {
      return;
    }
    _nextDirection = d;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
