import '../models/sudoku_board.dart';
import 'sudoku_validator.dart';

/// Solves Sudoku puzzles using backtracking algorithm.
///
/// This class implements a recursive backtracking solver that:
/// 1. Finds an empty cell
/// 2. Tries values 1-9 in that cell
/// 3. Checks if the value is valid (no conflicts)
/// 4. Recursively solves the rest of the board
/// 5. Backtracks if stuck (no valid value works)
///
/// Used by:
/// - Solution validation: verify puzzle has a unique solution
/// - Hint system: find correct values for empty cells
/// - Puzzle generator: check if generated puzzles are solvable
class SudokuSolver {
  /// Solves the given Sudoku board using backtracking.
  ///
  /// Modifies the board in-place by filling empty cells.
  /// Returns true if a solution was found, false if unsolvable.
  ///
  /// Example:
  /// ```dart
  /// final board = SudokuBoard.fromValues(puzzleData);
  /// if (SudokuSolver.solve(board)) {
  ///   print('Solved!');
  /// } else {
  ///   print('No solution exists');
  /// }
  /// ```
  static bool solve(SudokuBoard board) {
    // Find the next empty cell
    final emptyCell = _findEmptyCell(board);

    // Base case: no empty cells means board is solved
    if (emptyCell == null) {
      return true;
    }

    final row = emptyCell.row;
    final col = emptyCell.col;

    // Try values 1-9
    for (int value = 1; value <= 9; value++) {
      // Check if this value can be placed without conflicts
      if (SudokuValidator.canPlaceValue(board, row, col, value)) {
        // Place the value
        board.getCell(row, col).value = value;

        // Recursively try to solve the rest
        if (solve(board)) {
          return true; // Solution found!
        }

        // Backtrack: this value didn't lead to a solution
        board.getCell(row, col).value = null;
      }
    }

    // No value worked - trigger backtracking
    return false;
  }

  /// Solves the board and returns a solved copy without modifying the original.
  ///
  /// Returns null if the board is unsolvable.
  ///
  /// Example:
  /// ```dart
  /// final original = SudokuBoard.fromValues(puzzleData);
  /// final solved = SudokuSolver.getSolution(original);
  /// if (solved != null) {
  ///   // Original board unchanged, use solved board
  /// }
  /// ```
  static SudokuBoard? getSolution(SudokuBoard board) {
    final copy = board.clone();
    if (solve(copy)) {
      return copy;
    }
    return null;
  }

  /// Checks if the board has a unique solution.
  ///
  /// This is critical for puzzle generation - valid Sudoku puzzles
  /// must have exactly one solution (not zero, not multiple).
  ///
  /// Returns true only if exactly one solution exists.
  ///
  /// Note: This is computationally expensive as it needs to find
  /// all solutions. Use sparingly.
  static bool hasUniqueSolution(SudokuBoard board) {
    final copy = board.clone();
    final solutionCount = _countSolutions(copy, 0, 2);
    return solutionCount == 1;
  }

  /// Finds a valid value for a specific cell.
  ///
  /// Used by the hint system to help players.
  /// Returns the correct value (1-9) or null if cell is already filled
  /// or board is unsolvable.
  ///
  /// Example:
  /// ```dart
  /// final hint = SudokuSolver.getHint(board, row, col);
  /// if (hint != null) {
  ///   board.getCell(row, col).value = hint;
  /// }
  /// ```
  static int? getHint(SudokuBoard board, int row, int col) {
    // Cell already filled
    if (board.getCell(row, col).hasValue) {
      return null;
    }

    // Solve a copy to find the correct value
    final solved = getSolution(board);
    if (solved == null) {
      return null; // Board is unsolvable
    }

    return solved.getCell(row, col).value;
  }

  /// Finds the next empty cell on the board.
  ///
  /// Uses a simple left-to-right, top-to-bottom scan.
  /// Returns null if no empty cells exist (board is full).
  static Position? _findEmptyCell(SudokuBoard board) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (board.getCell(row, col).isEmpty) {
          return Position(row, col);
        }
      }
    }
    return null; // No empty cells
  }

  /// Counts the number of solutions for a board, up to a maximum.
  ///
  /// Used by hasUniqueSolution() to determine if exactly one solution exists.
  /// Stops counting after finding [maxCount] solutions for efficiency.
  ///
  /// Returns:
  /// - 0 if no solutions exist
  /// - 1 if exactly one solution exists
  /// - 2+ if multiple solutions exist (ambiguous puzzle)
  static int _countSolutions(SudokuBoard board, int count, int maxCount) {
    if (count >= maxCount) {
      return count; // Stop early - we only need to know if > 1
    }

    final emptyCell = _findEmptyCell(board);

    // Base case: no empty cells means we found a solution
    if (emptyCell == null) {
      return count + 1;
    }

    final row = emptyCell.row;
    final col = emptyCell.col;

    // Try all values
    for (int value = 1; value <= 9; value++) {
      if (SudokuValidator.canPlaceValue(board, row, col, value)) {
        board.getCell(row, col).value = value;

        // Recursively count solutions
        count = _countSolutions(board, count, maxCount);

        // Backtrack
        board.getCell(row, col).value = null;

        // Early exit if we found multiple solutions
        if (count >= maxCount) {
          return count;
        }
      }
    }

    return count;
  }

  /// Checks if a board is solvable (has at least one solution).
  ///
  /// This is faster than hasUniqueSolution() since it stops
  /// after finding the first solution.
  static bool isSolvable(SudokuBoard board) {
    final copy = board.clone();
    return solve(copy);
  }

  /// Gets all possible valid values for a specific cell.
  ///
  /// Returns a Set of integers (1-9) that can be legally placed
  /// in the given cell without creating conflicts.
  ///
  /// Useful for:
  /// - Auto-filling notes/pencil marks
  /// - Advanced hint systems
  /// - Puzzle difficulty analysis
  static Set<int> getPossibleValues(SudokuBoard board, int row, int col) {
    // Cell already filled
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
