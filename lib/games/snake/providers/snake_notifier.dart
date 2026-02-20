import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/providers/mixins/game_stats_notifier.dart';
import 'package:multigame/providers/services_providers.dart';
import 'package:multigame/services/data/firebase_stats_service.dart';

enum Direction { up, down, left, right }

enum GameMode { classic, wrap, speed }

class SnakeState {
  static const int gridSize = 20;

  // Cache all 400 grid cells once — used by _spawnFood
  static final Set<Offset> _allCells = {
    for (int x = 0; x < gridSize; x++)
      for (int y = 0; y < gridSize; y++) Offset(x.toDouble(), y.toDouble()),
  };
  static Set<Offset> get allCells => _allCells;

  final List<Offset> snake;
  final Set<Offset> snakeSet; // O(1) collision lookup
  final List<Offset>
  previousSnake; // snapshot before last tick (for interpolation)
  final int lastTickUs; // microseconds epoch at last tick
  final bool foodEaten; // true only on the tick food was collected

  final Offset food;
  final Direction currentDirection;
  final GameMode gameMode;
  final bool playing;
  final bool initialized;
  final int score;
  final int highScore;

  const SnakeState({
    this.snake = const [Offset(10, 10)],
    this.snakeSet = const {},
    this.previousSnake = const [Offset(10, 10)],
    this.lastTickUs = 0,
    this.foodEaten = false,
    this.food = const Offset(5, 5),
    this.currentDirection = Direction.right,
    this.gameMode = GameMode.classic,
    this.playing = false,
    this.initialized = false,
    this.score = 0,
    this.highScore = 0,
  });

  Duration get tickRate => switch (gameMode) {
    GameMode.speed => const Duration(milliseconds: 80),
    _ => const Duration(milliseconds: 150),
  };

  SnakeState copyWith({
    List<Offset>? snake,
    List<Offset>? previousSnake,
    int? lastTickUs,
    bool? foodEaten,
    Offset? food,
    Direction? currentDirection,
    GameMode? gameMode,
    bool? playing,
    bool? initialized,
    int? score,
    int? highScore,
  }) {
    final nextSnake = snake ?? this.snake;
    return SnakeState(
      snake: nextSnake,
      snakeSet: nextSnake.toSet(), // always derived from snake
      previousSnake: previousSnake ?? this.previousSnake,
      lastTickUs: lastTickUs ?? this.lastTickUs,
      foodEaten: foodEaten ?? this.foodEaten,
      food: food ?? this.food,
      currentDirection: currentDirection ?? this.currentDirection,
      gameMode: gameMode ?? this.gameMode,
      playing: playing ?? this.playing,
      initialized: initialized ?? this.initialized,
      score: score ?? this.score,
      highScore: highScore ?? this.highScore,
    );
  }
}

class SnakeNotifier extends GameStatsNotifier<SnakeState> {
  Timer? _timer;
  final Queue<Direction> _inputQueue = Queue();

  // Accumulator for the 16 ms polling game loop.
  Duration _accumulated = Duration.zero;
  DateTime _lastTimerFire = DateTime.now();
  final Random _random = Random();

  // Incrementally-maintained set of cells not occupied by snake or food.
  // Avoids recomputing allCells.difference(occupied) on every food spawn.
  final Set<Offset> _freeCells = {};

  @override
  FirebaseStatsService get statsService =>
      ref.read(firebaseStatsServiceProvider);

  @override
  SnakeState build() {
    ref.onDispose(() => _timer?.cancel());
    return const SnakeState();
  }

  void startGame() {
    _timer?.cancel();
    _inputQueue.clear();
    _accumulated = Duration.zero;
    _lastTimerFire = DateTime.now();
    const initialSnake = [Offset(10, 10)];
    _freeCells
      ..clear()
      ..addAll(SnakeState.allCells)
      ..removeAll(initialSnake);
    final food = _spawnFood();
    state = state.copyWith(
      snake: initialSnake,
      previousSnake: initialSnake,
      lastTickUs: 0,
      foodEaten: false,
      food: food,
      currentDirection: Direction.right,
      score: 0,
      playing: true,
      initialized: true,
    );
    _startTimer();
  }

  void setGameMode(GameMode mode) {
    state = state.copyWith(gameMode: mode);
    startGame();
  }

  void togglePause() {
    // No timer cancel/recreate — timer guards with `if (state.playing)` already
    state = state.copyWith(playing: !state.playing);
  }

  void changeDirection(Direction d) {
    // Use last queued direction as effective current to allow rapid double-tap.
    final effectiveCurrent = _inputQueue.isNotEmpty
        ? _inputQueue.last
        : state.currentDirection;
    if (_isReverse(effectiveCurrent, d)) {
      return;
    }

    if (_inputQueue.length >= 2) {
      // Replace the stale future direction instead of silently dropping the
      // new input. Guard against creating a [A, reverse(A)] death sequence.
      if (_isReverse(_inputQueue.first, d)) {
        return;
      }
      _inputQueue.removeLast();
    }
    _inputQueue.addLast(d);
  }

  bool _isReverse(Direction a, Direction b) =>
      (a == Direction.up && b == Direction.down) ||
      (a == Direction.down && b == Direction.up) ||
      (a == Direction.left && b == Direction.right) ||
      (a == Direction.right && b == Direction.left);

  void _startTimer() {
    _accumulated = Duration.zero;
    _lastTimerFire = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!state.playing) {
        return;
      }
      final now = DateTime.now();
      _accumulated += now.difference(_lastTimerFire);
      _lastTimerFire = now;
      while (_accumulated >= state.tickRate) {
        _accumulated -= state.tickRate;
        _tick();
      }
    });
  }

  Offset _spawnFood() {
    if (_freeCells.isEmpty) return const Offset(0, 0); // board full = win
    final food = _freeCells.elementAt(_random.nextInt(_freeCells.length));
    _freeCells.remove(food);
    return food;
  }

  void _tick() {
    // Dequeue buffered input or keep current direction
    final dir = _inputQueue.isNotEmpty
        ? _inputQueue.removeFirst()
        : state.currentDirection;

    final head = state.snake.first;
    Offset next;

    switch (dir) {
      case Direction.up:
        next = Offset(head.dx, head.dy - 1);
      case Direction.down:
        next = Offset(head.dx, head.dy + 1);
      case Direction.left:
        next = Offset(head.dx - 1, head.dy);
      case Direction.right:
        next = Offset(head.dx + 1, head.dy);
    }

    if (state.gameMode == GameMode.wrap) {
      next = Offset(
        (next.dx + SnakeState.gridSize) % SnakeState.gridSize,
        (next.dy + SnakeState.gridSize) % SnakeState.gridSize,
      );
    } else if (next.dx < 0 ||
        next.dy < 0 ||
        next.dx >= SnakeState.gridSize ||
        next.dy >= SnakeState.gridSize) {
      _gameOver();
      return;
    }

    // O(1) collision detection via Set
    if (state.snakeSet.contains(next)) {
      _gameOver();
      return;
    }

    final prevSnake = state.snake; // snapshot before mutation
    final newSnake = [next, ...state.snake];
    int newScore = state.score;
    Offset newFood = state.food;
    final bool ate = next == state.food;

    // Update _freeCells incrementally — new head is now occupied.
    // (food cell was already removed from _freeCells when it was spawned)
    _freeCells.remove(next);

    if (ate) {
      newScore += 10;
      newFood = _spawnFood(); // picks from _freeCells, removes chosen cell
    } else {
      final removedTail = newSnake.removeLast();
      _freeCells.add(removedTail); // freed tail cell
    }

    state = state.copyWith(
      previousSnake: prevSnake,
      lastTickUs: DateTime.now().microsecondsSinceEpoch,
      foodEaten: ate,
      snake: newSnake,
      food: newFood,
      currentDirection: dir,
      score: newScore,
    );
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    _inputQueue.clear();
    state = const SnakeState();
  }

  void _gameOver() {
    _timer?.cancel();
    final newHigh = state.score > state.highScore
        ? state.score
        : state.highScore;
    state = state.copyWith(playing: false, highScore: newHigh);
    saveScore('snake', state.score);
  }
}

final snakeProvider = NotifierProvider.autoDispose<SnakeNotifier, SnakeState>(
  SnakeNotifier.new,
);
