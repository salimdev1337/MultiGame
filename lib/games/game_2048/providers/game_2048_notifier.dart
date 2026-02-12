import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multigame/providers/mixins/game_stats_notifier.dart';
import 'package:multigame/providers/services_providers.dart';
import 'package:multigame/services/data/achievement_service.dart';
import 'package:multigame/services/data/firebase_stats_service.dart';

class Game2048State {
  final List<List<int>> grid;
  final int score;
  final int bestScore;
  final bool gameOver;
  final int currentObjectiveIndex;

  static const List<int> objectives = [256, 512, 1024, 2048];
  static const List<String> objectiveLabels = ['Easy', 'Medium', 'Hard', 'Expert'];

  const Game2048State({
    required this.grid,
    this.score = 0,
    this.bestScore = 0,
    this.gameOver = false,
    this.currentObjectiveIndex = 0,
  });

  int get currentObjective => objectives[currentObjectiveIndex];
  String get currentObjectiveLabel => objectiveLabels[currentObjectiveIndex];

  Game2048State copyWith({
    List<List<int>>? grid,
    int? score,
    int? bestScore,
    bool? gameOver,
    int? currentObjectiveIndex,
  }) {
    return Game2048State(
      grid: grid ?? this.grid,
      score: score ?? this.score,
      bestScore: bestScore ?? this.bestScore,
      gameOver: gameOver ?? this.gameOver,
      currentObjectiveIndex:
          currentObjectiveIndex ?? this.currentObjectiveIndex,
    );
  }
}

class Game2048Notifier extends GameStatsNotifier<Game2048State> {
  late AchievementService _achievementService;
  final Random _random = Random();

  @override
  FirebaseStatsService get statsService =>
      ref.read(firebaseStatsServiceProvider);

  @override
  Game2048State build() {
    _achievementService = ref.read(achievementServiceProvider);
    return _newGame(Game2048State(grid: List.generate(4, (_) => List.filled(4, 0))));
  }

  Game2048State _newGame(Game2048State base) {
    var grid = List.generate(4, (_) => List.filled(4, 0));
    grid = _addTile(grid);
    grid = _addTile(grid);
    return base.copyWith(grid: grid, score: 0, gameOver: false);
  }

  void initializeGame() {
    state = _newGame(state);
  }

  List<List<int>> _addTile(List<List<int>> grid) {
    final empty = <Point<int>>[];
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        if (grid[i][j] == 0) empty.add(Point(i, j));
      }
    }
    if (empty.isEmpty) return grid;
    final p = empty[_random.nextInt(empty.length)];
    final copy = grid.map((r) => List<int>.from(r)).toList();
    copy[p.x][p.y] = _random.nextInt(10) < 9 ? 2 : 4;
    return copy;
  }

  bool move(String direction) {
    if (state.gameOver) return false;
    var grid = state.grid.map((r) => List<int>.from(r)).toList();
    int scoreDelta = 0;
    bool moved = false;

    (grid, scoreDelta, moved) = switch (direction) {
      'left'  => _moveLeft(grid),
      'right' => _moveRight(grid),
      'up'    => _moveUp(grid),
      'down'  => _moveDown(grid),
      _       => (grid, 0, false),
    };

    if (!moved) return false;

    grid = _addTile(grid);
    final newScore = state.score + scoreDelta;
    final gameOver = !_canMove(grid);

    state = state.copyWith(
      grid: grid,
      score: newScore,
      bestScore: newScore > state.bestScore ? newScore : state.bestScore,
      gameOver: gameOver,
    );

    if (gameOver) saveScore('2048', newScore);
    return true;
  }

  bool _canMove(List<List<int>> grid) {
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        if (grid[i][j] == 0) return true;
        if (j + 1 < 4 && grid[i][j] == grid[i][j + 1]) return true;
        if (i + 1 < 4 && grid[i][j] == grid[i + 1][j]) return true;
      }
    }
    return false;
  }

  (List<List<int>>, int, bool) _moveLeft(List<List<int>> grid) {
    bool moved = false;
    int score = 0;
    for (int i = 0; i < 4; i++) {
      final row = grid[i].where((c) => c != 0).toList();
      final newRow = <int>[];
      int j = 0;
      while (j < row.length) {
        if (j + 1 < row.length && row[j] == row[j + 1]) {
          final m = row[j] * 2;
          newRow.add(m);
          score += m;
          j += 2;
        } else {
          newRow.add(row[j++]);
        }
      }
      while (newRow.length < 4) { newRow.add(0); }
      if (grid[i].toString() != newRow.toString()) moved = true;
      grid[i] = newRow;
    }
    return (grid, score, moved);
  }

  (List<List<int>>, int, bool) _moveRight(List<List<int>> grid) {
    bool moved = false;
    int score = 0;
    for (int i = 0; i < 4; i++) {
      final row = grid[i].where((c) => c != 0).toList().reversed.toList();
      final newRow = <int>[];
      int j = 0;
      while (j < row.length) {
        if (j + 1 < row.length && row[j] == row[j + 1]) {
          final m = row[j] * 2;
          newRow.add(m);
          score += m;
          j += 2;
        } else {
          newRow.add(row[j++]);
        }
      }
      while (newRow.length < 4) { newRow.add(0); }
      final reversed = newRow.reversed.toList();
      if (grid[i].toString() != reversed.toString()) moved = true;
      grid[i] = reversed;
    }
    return (grid, score, moved);
  }

  (List<List<int>>, int, bool) _moveUp(List<List<int>> grid) {
    bool moved = false;
    int score = 0;
    for (int j = 0; j < 4; j++) {
      final col = [for (int i = 0; i < 4; i++) if (grid[i][j] != 0) grid[i][j]];
      final newCol = <int>[];
      int i = 0;
      while (i < col.length) {
        if (i + 1 < col.length && col[i] == col[i + 1]) {
          final m = col[i] * 2;
          newCol.add(m);
          score += m;
          i += 2;
        } else {
          newCol.add(col[i++]);
        }
      }
      while (newCol.length < 4) { newCol.add(0); }
      for (int i = 0; i < 4; i++) {
        if (grid[i][j] != newCol[i]) moved = true;
        grid[i][j] = newCol[i];
      }
    }
    return (grid, score, moved);
  }

  (List<List<int>>, int, bool) _moveDown(List<List<int>> grid) {
    bool moved = false;
    int score = 0;
    for (int j = 0; j < 4; j++) {
      final col = [for (int i = 3; i >= 0; i--) if (grid[i][j] != 0) grid[i][j]];
      final newCol = <int>[];
      int i = 0;
      while (i < col.length) {
        if (i + 1 < col.length && col[i] == col[i + 1]) {
          final m = col[i] * 2;
          newCol.add(m);
          score += m;
          i += 2;
        } else {
          newCol.add(col[i++]);
        }
      }
      while (newCol.length < 4) { newCol.add(0); }
      for (int i = 0; i < 4; i++) {
        if (grid[3 - i][j] != newCol[i]) moved = true;
        grid[3 - i][j] = newCol[i];
      }
    }
    return (grid, score, moved);
  }

  int getHighestTile() {
    int max = 0;
    for (final row in state.grid) {
      for (final val in row) {
        if (val > max) max = val;
      }
    }
    return max;
  }

  bool hasReachedObjective() =>
      getHighestTile() >= state.currentObjective;

  void nextObjective() {
    if (state.currentObjectiveIndex < Game2048State.objectives.length - 1) {
      state = state.copyWith(
          currentObjectiveIndex: state.currentObjectiveIndex + 1);
    }
  }

  void resetObjective() => state = state.copyWith(currentObjectiveIndex: 0);

  Future<void> recordGameCompletion() async {
    final tile = getHighestTile();
    String level = 'None';
    if (tile >= 2048) { level = 'Expert (2048)'; }
    else if (tile >= 1024) { level = 'Hard (1024)'; }
    else if (tile >= 512) { level = 'Medium (512)'; }
    else if (tile >= 256) { level = 'Easy (256)'; }

    await _achievementService.save2048Achievement(
      score: state.score,
      highestTile: tile,
      levelPassed: level,
    );
  }
}

final game2048Provider =
    NotifierProvider.autoDispose<Game2048Notifier, Game2048State>(
        Game2048Notifier.new);
