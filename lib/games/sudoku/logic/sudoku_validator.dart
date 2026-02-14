// Sudoku validation logic - see docs/SUDOKU_ALGORITHMS.md

import '../models/sudoku_board.dart';

class Position {
  final int row;
  final int col;

  const Position(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position && row == other.row && col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => 'Position($row, $col)';
}

class SudokuValidator {
  static bool isValidBoard(SudokuBoard board) {
    return getConflictPositions(board).isEmpty;
  }

  static bool isSolved(SudokuBoard board) {
    return board.isFull && isValidBoard(board);
  }

  static Set<Position> getConflictPositions(SudokuBoard board) {
    final conflicts = <Position>{};

    for (int row = 0; row < 9; row++) {
      conflicts.addAll(_findRowConflicts(board, row));
    }

    for (int col = 0; col < 9; col++) {
      conflicts.addAll(_findColumnConflicts(board, col));
    }

    for (int boxIndex = 0; boxIndex < 9; boxIndex++) {
      conflicts.addAll(_findBoxConflicts(board, boxIndex));
    }

    return conflicts;
  }

  static bool canPlaceValue(SudokuBoard board, int row, int col, int value) {
    if (value < 1 || value > 9) return false;
    if (_hasValueInRow(board, row, col, value)) return false;
    if (_hasValueInColumn(board, row, col, value)) return false;
    if (_hasValueInBox(board, row, col, value)) return false;
    return true;
  }

  static bool _hasValueInRow(SudokuBoard board, int row, int col, int value) {
    final rowCells = board.getRow(row);
    for (int c = 0; c < 9; c++) {
      if (c != col && rowCells[c].value == value) return true;
    }
    return false;
  }

  static bool _hasValueInColumn(
    SudokuBoard board,
    int row,
    int col,
    int value,
  ) {
    final colCells = board.getColumn(col);
    for (int r = 0; r < 9; r++) {
      if (r != row && colCells[r].value == value) return true;
    }
    return false;
  }

  static bool _hasValueInBox(SudokuBoard board, int row, int col, int value) {
    final boxStartRow = (row ~/ 3) * 3;
    final boxStartCol = (col ~/ 3) * 3;
    for (int r = boxStartRow; r < boxStartRow + 3; r++) {
      for (int c = boxStartCol; c < boxStartCol + 3; c++) {
        if ((r != row || c != col) && board.getCell(r, c).value == value) {
          return true;
        }
      }
    }
    return false;
  }

  static Set<Position> _findRowConflicts(SudokuBoard board, int row) {
    final conflicts = <Position>{};
    final seen = <int, int>{};

    for (int col = 0; col < 9; col++) {
      final cell = board.getCell(row, col);
      if (cell.isEmpty) continue;

      final value = cell.value!;
      if (seen.containsKey(value)) {
        conflicts.add(Position(row, seen[value]!));
        conflicts.add(Position(row, col));
      } else {
        seen[value] = col;
      }
    }

    return conflicts;
  }

  static Set<Position> _findColumnConflicts(SudokuBoard board, int col) {
    final conflicts = <Position>{};
    final seen = <int, int>{};

    for (int row = 0; row < 9; row++) {
      final cell = board.getCell(row, col);
      if (cell.isEmpty) continue;

      final value = cell.value!;
      if (seen.containsKey(value)) {
        conflicts.add(Position(seen[value]!, col));
        conflicts.add(Position(row, col));
      } else {
        seen[value] = row;
      }
    }

    return conflicts;
  }

  static Set<Position> _findBoxConflicts(SudokuBoard board, int boxIndex) {
    final conflicts = <Position>{};
    final seen = <int, Position>{};

    final boxRow = (boxIndex ~/ 3) * 3;
    final boxCol = (boxIndex % 3) * 3;

    for (int r = boxRow; r < boxRow + 3; r++) {
      for (int c = boxCol; c < boxCol + 3; c++) {
        final cell = board.getCell(r, c);
        if (cell.isEmpty) continue;

        final value = cell.value!;
        if (seen.containsKey(value)) {
          conflicts.add(seen[value]!);
          conflicts.add(Position(r, c));
        } else {
          seen[value] = Position(r, c);
        }
      }
    }

    return conflicts;
  }
}
