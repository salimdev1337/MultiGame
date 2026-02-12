import 'dart:async';
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

  final List<Offset> snake;
  final Offset food;
  final Direction currentDirection;
  final GameMode gameMode;
  final bool playing;
  final bool initialized;
  final int score;
  final int highScore;

  const SnakeState({
    this.snake = const [Offset(10, 10)],
    this.food = const Offset(5, 5),
    this.currentDirection = Direction.right,
    this.gameMode = GameMode.classic,
    this.playing = false,
    this.initialized = false,
    this.score = 0,
    this.highScore = 0,
  });

  Duration get tickRate => gameMode == GameMode.speed
      ? const Duration(milliseconds: 120)
      : const Duration(milliseconds: 200);

  SnakeState copyWith({
    List<Offset>? snake,
    Offset? food,
    Direction? currentDirection,
    GameMode? gameMode,
    bool? playing,
    bool? initialized,
    int? score,
    int? highScore,
  }) {
    return SnakeState(
      snake: snake ?? this.snake,
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
  Direction _nextDirection = Direction.right;
  final Random _random = Random();

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
    _nextDirection = Direction.right;
    final food = _spawnFood([const Offset(10, 10)]);
    state = state.copyWith(
      snake: [const Offset(10, 10)],
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
    if (state.playing) {
      _timer?.cancel();
      state = state.copyWith(playing: false);
    } else {
      state = state.copyWith(playing: true);
      _startTimer();
    }
  }

  void changeDirection(Direction d) {
    final cur = state.currentDirection;
    if ((cur == Direction.up && d == Direction.down) ||
        (cur == Direction.down && d == Direction.up) ||
        (cur == Direction.left && d == Direction.right) ||
        (cur == Direction.right && d == Direction.left)) {
      return;
    }
    _nextDirection = d;
  }

  void _startTimer() {
    _timer = Timer.periodic(state.tickRate, (_) {
      if (state.playing) { _tick(); }
    });
  }

  Offset _spawnFood(List<Offset> snake) {
    Offset pos;
    do {
      pos = Offset(
        _random.nextInt(SnakeState.gridSize).toDouble(),
        _random.nextInt(SnakeState.gridSize).toDouble(),
      );
    } while (snake.contains(pos));
    return pos;
  }

  void _tick() {
    final dir = _nextDirection;
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

    if (state.snake.contains(next)) {
      _gameOver();
      return;
    }

    final newSnake = [next, ...state.snake];
    int newScore = state.score;
    Offset newFood = state.food;

    if (next == state.food) {
      newScore += 10;
      newFood = _spawnFood(newSnake);
    } else {
      newSnake.removeLast();
    }

    state = state.copyWith(
      snake: newSnake,
      food: newFood,
      currentDirection: dir,
      score: newScore,
    );
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    state = const SnakeState();
  }

  void _gameOver() {
    _timer?.cancel();
    final newHigh = state.score > state.highScore ? state.score : state.highScore;
    state = state.copyWith(playing: false, highScore: newHigh);
    saveScore('snake', state.score);
  }
}

final snakeProvider =
    NotifierProvider.autoDispose<SnakeNotifier, SnakeState>(SnakeNotifier.new);
