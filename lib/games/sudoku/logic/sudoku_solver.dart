// Sudoku backtracking solver - see docs/SUDOKU_ALGORITHMS.md

import '../models/sudoku_board.dart';
import 'sudoku_validator.dart';

class SudokuSolver {
  static bool solve(SudokuBoard board) {
    final emptyCell = _findEmptyCell(board);

    if (emptyCell == null) {
      return true;
    }

    final row = emptyCell.row;
    final col = emptyCell.col;

    for (int value = 1; value <= 9; value++) {
      if (SudokuValidator.canPlaceValue(board, row, col, value)) {
        board.getCell(row, col).value = value;

        if (solve(board)) {
          return true;
        }

        board.getCell(row, col).value = null;
      }
    }

    return false;
  }

  static SudokuBoard? getSolution(SudokuBoard board) {
    final copy = board.clone();
    if (solve(copy)) {
      return copy;
    }
    return null;
  }

  static bool hasUniqueSolution(SudokuBoard board) {
    final copy = board.clone();
    final solutionCount = _countSolutions(copy, 0, 2);
    return solutionCount == 1;
  }

  static int? getHint(SudokuBoard board, int row, int col) {
    if (board.getCell(row, col).hasValue) {
      return null;
    }

    final solved = getSolution(board);
    if (solved == null) {
      return null;
    }

    return solved.getCell(row, col).value;
  }

  static Position? _findEmptyCell(SudokuBoard board) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (board.getCell(row, col).isEmpty) {
          return Position(row, col);
        }
      }
    }
    return null;
  }

  static int _countSolutions(SudokuBoard board, int count, int maxCount) {
    if (count >= maxCount) {
      return count;
    }

    final emptyCell = _findEmptyCell(board);

    if (emptyCell == null) {
      return count + 1;
    }

    final row = emptyCell.row;
    final col = emptyCell.col;

    for (int value = 1; value <= 9; value++) {
      if (SudokuValidator.canPlaceValue(board, row, col, value)) {
        board.getCell(row, col).value = value;

        count = _countSolutions(board, count, maxCount);

        board.getCell(row, col).value = null;

        if (count >= maxCount) {
          return count;
        }
      }
    }

    return count;
  }

  static bool isSolvable(SudokuBoard board) {
    final copy = board.clone();
    return solve(copy);
  }

  static Set<int> getPossibleValues(SudokuBoard board, int row, int col) {
    if (board.getCell(row, col).hasValue) {
      return {};
    }

    final possibleValues = <int>{};
    for (int value = 1; value <= 9; value++) {
      if (SudokuValidator.canPlaceValue(board, row, col, value)) {
        possibleValues.add(value);
      }
    }
    return possibleValues;
  }
}
