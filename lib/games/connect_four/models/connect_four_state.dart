import 'package:flutter/foundation.dart';

import 'connect_four_enums.dart';

/// Immutable representation of the Connect Four board.
/// grid[col][row], col 0..6 left→right, row 0..5 bottom→top.
/// 0 = empty, 1 = player 1 (yellow), 2 = player 2 (red).
@immutable
class ConnectFourState {
  const ConnectFourState({
    this.grid = const [],
    this.phase = ConnectFourPhase.idle,
    this.mode = ConnectFourMode.solo,
    this.difficulty = ConnectFourDifficulty.medium,
    this.currentPlayer = 1,
    this.winLine = const [],
    this.dropAnimCol = -1,
  });

  /// 7×6 grid: grid[col][row], values 0/1/2.
  final List<List<int>> grid;

  final ConnectFourPhase phase;
  final ConnectFourMode mode;
  final ConnectFourDifficulty difficulty;

  /// Whose turn it is: 1 or 2.
  final int currentPlayer;

  /// The 4 winning [col, row] pairs; empty if no winner yet.
  final List<(int col, int row)> winLine;

  /// Column where a piece is currently animating in (-1 = none).
  final int dropAnimCol;

  bool get isOver => phase == ConnectFourPhase.won || phase == ConnectFourPhase.draw;

  /// Whether the human is waiting for the bot to move.
  bool get isBotTurn => mode == ConnectFourMode.solo && currentPlayer == 2;

  ConnectFourState copyWith({
    List<List<int>>? grid,
    ConnectFourPhase? phase,
    ConnectFourMode? mode,
    ConnectFourDifficulty? difficulty,
    int? currentPlayer,
    List<(int col, int row)>? winLine,
    int? dropAnimCol,
  }) {
    return ConnectFourState(
      grid: grid ?? this.grid,
      phase: phase ?? this.phase,
      mode: mode ?? this.mode,
      difficulty: difficulty ?? this.difficulty,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      winLine: winLine ?? this.winLine,
      dropAnimCol: dropAnimCol ?? this.dropAnimCol,
    );
  }

  /// Creates an empty 7×6 grid.
  static List<List<int>> emptyGrid() =>
      List.generate(kCFCols, (_) => List.filled(kCFRows, 0));
}
