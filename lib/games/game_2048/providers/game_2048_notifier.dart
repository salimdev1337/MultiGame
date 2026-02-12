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

  /// Index into [milestones] of the highest milestone reached this game.
  /// -1 means no milestone has been reached yet.
  final int highestMilestoneIndex;

  /// Total moves made in the current game.
  final int moveCount;

  /// Combo bonus points earned on the last move (0 if no combo).
  final int lastComboBonus;

  static const List<int> milestones = [256, 512, 1024, 2048, 4096, 8192, 16384];
  static const List<String> milestoneLabels = [
    'Beginner', 'Easy', 'Medium', 'Hard', 'Expert', 'Master', 'Legend'
  ];

  const Game2048State({
    required this.grid,
    this.score = 0,
    this.bestScore = 0,
    this.gameOver = false,
    this.highestMilestoneIndex = -1,
    this.moveCount = 0,
    this.lastComboBonus = 0,
  });

  /// The next milestone tile the player is working toward (null = beyond all milestones).
  int? get nextMilestoneTile {
    final next = highestMilestoneIndex + 1;
    if (next >= milestones.length) return null;
    return milestones[next];
  }

  /// Label for the current milestone reached, or '—' if none yet.
  String get currentMilestoneLabel {
    if (highestMilestoneIndex < 0) return '—';
    return milestoneLabels[highestMilestoneIndex];
  }

  /// Tile value of the current milestone reached, or null if none yet.
  int? get currentMilestoneTile {
    if (highestMilestoneIndex < 0) return null;
    return milestones[highestMilestoneIndex];
  }

  Game2048State copyWith({
    List<List<int>>? grid,
    int? score,
    int? bestScore,
    bool? gameOver,
    int? highestMilestoneIndex,
    int? moveCount,
    int? lastComboBonus,
  }) {
    return Game2048State(
      grid: grid ?? this.grid,
      score: score ?? this.score,
      bestScore: bestScore ?? this.bestScore,
      gameOver: gameOver ?? this.gameOver,
      highestMilestoneIndex:
          highestMilestoneIndex ?? this.highestMilestoneIndex,
      moveCount: moveCount ?? this.moveCount,
      lastComboBonus: lastComboBonus ?? this.lastComboBonus,
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
    return _newGame(
        Game2048State(grid: List.generate(4, (_) => List.filled(4, 0))));
  }

  Game2048State _newGame(Game2048State base) {
    var grid = List.generate(4, (_) => List.filled(4, 0));
    grid = _addTile(grid);
    grid = _addTile(grid);
    return base.copyWith(
      grid: grid,
      score: 0,
      gameOver: false,
      highestMilestoneIndex: -1,
      moveCount: 0,
      lastComboBonus: 0,
    );
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
    int mergeCount = 0;
    bool moved = false;

    (grid, scoreDelta, mergeCount, moved) = switch (direction) {
      'left'  => _moveLeft(grid),
      'right' => _moveRight(grid),
      'up'    => _moveUp(grid),
      'down'  => _moveDown(grid),
      _       => (grid, 0, 0, false),
    };

    if (!moved) return false;

    grid = _addTile(grid);

    // Combo bonus: each extra merge beyond the first adds 10% of base delta
    final comboBonus = mergeCount > 1 ? (scoreDelta * (mergeCount - 1)) ~/ 10 : 0;
    final totalDelta = scoreDelta + comboBonus;
    final newScore = state.score + totalDelta;
    final newBest = newScore > state.bestScore ? newScore : state.bestScore;
    final gameOver = !_canMove(grid);

    // Auto-advance milestone based on highest tile on board
    final newMilestoneIndex = _computeMilestoneIndex(grid, state.highestMilestoneIndex);

    state = state.copyWith(
      grid: grid,
      score: newScore,
      bestScore: newBest,
      gameOver: gameOver,
      highestMilestoneIndex: newMilestoneIndex,
      moveCount: state.moveCount + 1,
      lastComboBonus: comboBonus,
    );

    if (gameOver) saveScore('2048', newScore);
    return true;
  }

  /// Returns the highest milestone index that has been reached given the board.
  int _computeMilestoneIndex(List<List<int>> grid, int currentIndex) {
    final highest = _getHighestTile(grid);
    int newIndex = currentIndex;
    // Check upward from current (handles multiple milestones crossed in one move)
    while (newIndex + 1 < Game2048State.milestones.length &&
        highest >= Game2048State.milestones[newIndex + 1]) {
      newIndex++;
    }
    // Also detect the very first milestone
    if (newIndex < 0 && highest >= Game2048State.milestones[0]) {
      newIndex = 0;
    }
    return newIndex;
  }

  bool _canMove(List<List<int>> grid) {
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        if (grid[i][j] == 0) return true;
      }
    }
    return false;
  }

  int _getHighestTile(List<List<int>> grid) {
    int max = 0;
    for (final row in grid) {
      for (final val in row) {
        if (val > max) max = val;
      }
    }
    return max;
  }

  int getHighestTile() => _getHighestTile(state.grid);

  (List<List<int>>, int, int, bool) _moveLeft(List<List<int>> grid) {
    bool moved = false;
    int score = 0;
    int merges = 0;
    for (int i = 0; i < 4; i++) {
      final row = grid[i].where((c) => c != 0).toList();
      final newRow = <int>[];
      int j = 0;
      while (j < row.length) {
        if (j + 1 < row.length && row[j] == row[j + 1]) {
          final m = row[j] * 2;
          newRow.add(m);
          score += m;
          merges++;
          j += 2;
        } else {
          newRow.add(row[j++]);
        }
      }
      while (newRow.length < 4) { newRow.add(0); }
      if (grid[i].toString() != newRow.toString()) moved = true;
      grid[i] = newRow;
    }
    return (grid, score, merges, moved);
  }

  (List<List<int>>, int, int, bool) _moveRight(List<List<int>> grid) {
    bool moved = false;
    int score = 0;
    int merges = 0;
    for (int i = 0; i < 4; i++) {
      final row = grid[i].where((c) => c != 0).toList().reversed.toList();
      final newRow = <int>[];
      int j = 0;
      while (j < row.length) {
        if (j + 1 < row.length && row[j] == row[j + 1]) {
          final m = row[j] * 2;
          newRow.add(m);
          score += m;
          merges++;
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
    return (grid, score, merges, moved);
  }

  (List<List<int>>, int, int, bool) _moveUp(List<List<int>> grid) {
    bool moved = false;
    int score = 0;
    int merges = 0;
    for (int j = 0; j < 4; j++) {
      final col = [for (int i = 0; i < 4; i++) if (grid[i][j] != 0) grid[i][j]];
      final newCol = <int>[];
      int i = 0;
      while (i < col.length) {
        if (i + 1 < col.length && col[i] == col[i + 1]) {
          final m = col[i] * 2;
          newCol.add(m);
          score += m;
          merges++;
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
    return (grid, score, merges, moved);
  }

  (List<List<int>>, int, int, bool) _moveDown(List<List<int>> grid) {
    bool moved = false;
    int score = 0;
    int merges = 0;
    for (int j = 0; j < 4; j++) {
      final col = [for (int i = 3; i >= 0; i--) if (grid[i][j] != 0) grid[i][j]];
      final newCol = <int>[];
      int i = 0;
      while (i < col.length) {
        if (i + 1 < col.length && col[i] == col[i + 1]) {
          final m = col[i] * 2;
          newCol.add(m);
          score += m;
          merges++;
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
    return (grid, score, merges, moved);
  }

  Future<void> recordGameCompletion() async {
    final tile = getHighestTile();
    String level = 'None';
    if (tile >= 16384) { level = 'Legend (16384)'; }
    else if (tile >= 8192) { level = 'Master (8192)'; }
    else if (tile >= 4096) { level = 'Expert (4096)'; }
    else if (tile >= 2048) { level = 'Hard (2048)'; }
    else if (tile >= 1024) { level = 'Medium (1024)'; }
    else if (tile >= 512)  { level = 'Easy (512)'; }
    else if (tile >= 256)  { level = 'Beginner (256)'; }

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
