import 'dart:math';

import '../models/connect_four_enums.dart';

// ── Board helpers ─────────────────────────────────────────────────────────────

/// Returns the row index where a piece lands when dropped in [col],
/// or -1 if the column is full.
int landingRow(List<List<int>> grid, int col) {
  for (int row = 0; row < kCFRows; row++) {
    if (grid[col][row] == 0) {
      return row;
    }
  }
  return -1; // column full
}

/// Returns true if [col] has at least one empty cell.
bool canDrop(List<List<int>> grid, int col) => landingRow(grid, col) != -1;

/// Returns a new grid with [player]'s piece in [col] at [row].
List<List<int>> dropPiece(List<List<int>> grid, int col, int row, int player) {
  final next = [
    for (var c = 0; c < kCFCols; c++) List<int>.from(grid[c]),
  ];
  next[col][row] = player;
  return next;
}

/// Returns the list of columns that still accept a piece.
List<int> validColumns(List<List<int>> grid) {
  return [
    for (var c = 0; c < kCFCols; c++)
      if (canDrop(grid, c)) c,
  ];
}

// ── Win detection ─────────────────────────────────────────────────────────────

/// Checks whether [player] has 4-in-a-row after placing at ([col],[row]).
/// Returns the winning [(col,row)] list or empty if none.
List<(int, int)> checkWin(List<List<int>> grid, int col, int row, int player) {
  // Directions: horizontal, vertical, diagonal /, diagonal \
  const directions = [
    (1, 0),
    (0, 1),
    (1, 1),
    (1, -1),
  ];

  for (final (dc, dr) in directions) {
    final line = _collectLine(grid, col, row, dc, dr, player);
    if (line.length >= 4) {
      return line.sublist(0, 4);
    }
  }
  return [];
}

List<(int, int)> _collectLine(
  List<List<int>> grid,
  int col,
  int row,
  int dc,
  int dr,
  int player,
) {
  final cells = <(int, int)>[];
  // Walk in negative direction
  var c = col - dc;
  var r = row - dr;
  while (_inBounds(c, r) && grid[c][r] == player) {
    cells.insert(0, (c, r));
    c -= dc;
    r -= dr;
  }
  // The piece itself
  cells.add((col, row));
  // Walk in positive direction
  c = col + dc;
  r = row + dr;
  while (_inBounds(c, r) && grid[c][r] == player) {
    cells.add((c, r));
    c += dc;
    r += dr;
  }
  return cells;
}

bool _inBounds(int col, int row) =>
    col >= 0 && col < kCFCols && row >= 0 && row < kCFRows;

/// Returns true if the board is completely full (draw condition).
bool isDraw(List<List<int>> grid) {
  for (var c = 0; c < kCFCols; c++) {
    if (canDrop(grid, c)) {
      return false;
    }
  }
  return true;
}

// ── Bot AI (minimax with alpha-beta pruning) ──────────────────────────────────

/// Returns the column the bot should play.
int getBotMove(
  List<List<int>> grid,
  ConnectFourDifficulty difficulty,
  int botPlayer,
) {
  final valid = validColumns(grid);
  if (valid.isEmpty) {
    return -1;
  }

  if (difficulty == ConnectFourDifficulty.easy) {
    return _easyMove(grid, valid, botPlayer);
  }

  final depth = difficulty == ConnectFourDifficulty.medium ? 4 : 7;
  return _minimaxMove(grid, depth, botPlayer);
}

int _easyMove(List<List<int>> grid, List<int> valid, int botPlayer) {
  // Easy: win if possible, block if needed, otherwise random
  for (final col in valid) {
    final row = landingRow(grid, col);
    if (row == -1) {
      continue;
    }
    final next = dropPiece(grid, col, row, botPlayer);
    if (checkWin(next, col, row, botPlayer).isNotEmpty) {
      return col;
    }
  }
  final opponent = botPlayer == 1 ? 2 : 1;
  for (final col in valid) {
    final row = landingRow(grid, col);
    if (row == -1) {
      continue;
    }
    final next = dropPiece(grid, col, row, opponent);
    if (checkWin(next, col, row, opponent).isNotEmpty) {
      return col;
    }
  }
  return valid[Random().nextInt(valid.length)];
}

int _minimaxMove(List<List<int>> grid, int depth, int botPlayer) {
  final valid = validColumns(grid);
  var bestScore = double.negativeInfinity;
  var bestCol = valid[valid.length ~/ 2]; // center preference as default

  for (final col in valid) {
    final row = landingRow(grid, col);
    if (row == -1) {
      continue;
    }
    final next = dropPiece(grid, col, row, botPlayer);
    final score = _minimax(
      next,
      depth - 1,
      false,
      botPlayer,
      double.negativeInfinity,
      double.infinity,
      col,
      row,
    );
    if (score > bestScore) {
      bestScore = score;
      bestCol = col;
    }
  }
  return bestCol;
}

double _minimax(
  List<List<int>> grid,
  int depth,
  bool isMaximising,
  int botPlayer,
  double alpha,
  double beta,
  int lastCol,
  int lastRow,
) {
  final opponent = botPlayer == 1 ? 2 : 1;
  final lastPlayer = isMaximising ? opponent : botPlayer;

  // Terminal: last move won
  if (checkWin(grid, lastCol, lastRow, lastPlayer).isNotEmpty) {
    return isMaximising ? -10000.0 - depth : 10000.0 + depth;
  }
  if (isDraw(grid) || depth == 0) {
    return _scoreBoard(grid, botPlayer);
  }

  final valid = validColumns(grid);
  final currentPlayer = isMaximising ? botPlayer : opponent;
  double value = isMaximising ? double.negativeInfinity : double.infinity;

  for (final col in valid) {
    final row = landingRow(grid, col);
    if (row == -1) {
      continue;
    }
    final next = dropPiece(grid, col, row, currentPlayer);
    final score = _minimax(
      next,
      depth - 1,
      !isMaximising,
      botPlayer,
      alpha,
      beta,
      col,
      row,
    );
    if (isMaximising) {
      value = max(value, score);
      alpha = max(alpha, value);
    } else {
      value = min(value, score);
      beta = min(beta, value);
    }
    if (beta <= alpha) {
      break;
    }
  }
  return value;
}

/// Heuristic board score for the bot (positive = good for bot).
double _scoreBoard(List<List<int>> grid, int botPlayer) {
  var score = 0.0;
  final opponent = botPlayer == 1 ? 2 : 1;

  // Centre column preference
  for (var row = 0; row < kCFRows; row++) {
    if (grid[3][row] == botPlayer) {
      score += 3;
    } else if (grid[3][row] == opponent) {
      score -= 3;
    }
  }

  // Score all windows of 4
  const directions = [(1, 0), (0, 1), (1, 1), (1, -1)];
  for (var col = 0; col < kCFCols; col++) {
    for (var row = 0; row < kCFRows; row++) {
      for (final (dc, dr) in directions) {
        score += _scoreWindow(grid, col, row, dc, dr, botPlayer, opponent);
      }
    }
  }
  return score;
}

double _scoreWindow(
  List<List<int>> grid,
  int col,
  int row,
  int dc,
  int dr,
  int bot,
  int opp,
) {
  var botCount = 0;
  var oppCount = 0;
  var empty = 0;

  for (var i = 0; i < 4; i++) {
    final c = col + dc * i;
    final r = row + dr * i;
    if (!_inBounds(c, r)) {
      return 0;
    }
    final cell = grid[c][r];
    if (cell == bot) {
      botCount++;
    } else if (cell == opp) {
      oppCount++;
    } else {
      empty++;
    }
  }

  if (oppCount > 0 && botCount > 0) {
    return 0; // mixed window — no value
  }
  if (botCount == 3 && empty == 1) {
    return 5;
  }
  if (botCount == 2 && empty == 2) {
    return 2;
  }
  if (oppCount == 3 && empty == 1) {
    return -4;
  }
  return 0;
}
