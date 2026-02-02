import '../models/sudoku_board.dart';

/// Position on the Sudoku board (row, col)
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

/// Validates Sudoku board for conflicts and rule violations.
///
/// This class provides pure validation functions that detect:
/// - Duplicate values in rows
/// - Duplicate values in columns
/// - Duplicate values in 3x3 boxes
///
/// Used by:
/// - Classic Mode: real-time error highlighting
/// - Rush Mode: penalty detection
/// - Solver: solution verification
class SudokuValidator {
  /// Checks if the entire board is valid (no conflicts).
  ///
  /// Returns true if:
  /// - All rows have no duplicate non-empty values
  /// - All columns have no duplicate non-empty values
  /// - All 3x3 boxes have no duplicate non-empty values
  static bool isValidBoard(SudokuBoard board) {
    return getConflictPositions(board).isEmpty;
  }

  /// Checks if the board is completely solved correctly.
  ///
  /// Returns true only if:
  /// - Board is full (all cells filled)
  /// - Board is valid (no conflicts)
  static bool isSolved(SudokuBoard board) {
    return board.isFull && isValidBoard(board);
  }

  /// Finds all cells that have conflicts with other cells.
  ///
  /// Returns a Set of Positions for cells that violate Sudoku rules.
  /// Empty cells are never included in conflict detection.
  static Set<Position> getConflictPositions(SudokuBoard board) {
    final conflicts = <Position>{};

    // Check all rows
    for (int row = 0; row < 9; row++) {
      conflicts.addAll(_findRowConflicts(board, row));
    }

    // Check all columns
    for (int col = 0; col < 9; col++) {
      conflicts.addAll(_findColumnConflicts(board, col));
    }

    // Check all 3x3 boxes
    for (int boxIndex = 0; boxIndex < 9; boxIndex++) {
      conflicts.addAll(_findBoxConflicts(board, boxIndex));
    }

    return conflicts;
  }

  /// Checks if a specific value can be placed at a position without conflicts.
  ///
  /// Returns true if placing [value] at [row, col] would not create
  /// any conflicts with existing values in the same row, column, or box.
  ///
  /// This is used by:
  /// - Solver: to determine valid moves during backtracking
  /// - Hint system: to validate suggested values
  static bool canPlaceValue(
    SudokuBoard board,
    int row,
    int col,
    int value,
  ) {
    if (value < 1 || value > 9) {
      return false;
    }

    // Check row
    final rowCells = board.getRow(row);
    for (int c = 0; c < 9; c++) {
      if (c != col && rowCells[c].value == value) {
        return false; // Conflict in row
      }
    }

    // Check column
    final colCells = board.getColumn(col);
    for (int r = 0; r < 9; r++) {
      if (r != row && colCells[r].value == value) {
        return false; // Conflict in column
      }
    }

    // Check 3x3 box
    final boxStartRow = (row ~/ 3) * 3;
    final boxStartCol = (col ~/ 3) * 3;

    for (int r = boxStartRow; r < boxStartRow + 3; r++) {
      for (int c = boxStartCol; c < boxStartCol + 3; c++) {
        if (r != row || c != col) {
          if (board.getCell(r, c).value == value) {
            return false; // Conflict in box
          }
        }
      }
    }

    return true; // No conflicts
  }

  /// Finds duplicate values in a specific row.
  ///
  /// Returns positions of ALL cells involved in conflicts.
  /// Empty cells are ignored.
  static Set<Position> _findRowConflicts(SudokuBoard board, int row) {
    final conflicts = <Position>{};
    final seen = <int, int>{}; // value -> first column position

    for (int col = 0; col < 9; col++) {
      final cell = board.getCell(row, col);
      if (cell.isEmpty) continue;

      final value = cell.value!;
      if (seen.containsKey(value)) {
        // Found duplicate - mark both positions
        conflicts.add(Position(row, seen[value]!));
        conflicts.add(Position(row, col));
      } else {
        seen[value] = col;
      }
    }

    return conflicts;
  }

  /// Finds duplicate values in a specific column.
  static Set<Position> _findColumnConflicts(SudokuBoard board, int col) {
    final conflicts = <Position>{};
    final seen = <int, int>{}; // value -> first row position

    for (int row = 0; row < 9; row++) {
      final cell = board.getCell(row, col);
      if (cell.isEmpty) continue;

      final value = cell.value!;
      if (seen.containsKey(value)) {
        // Found duplicate - mark both positions
        conflicts.add(Position(seen[value]!, col));
        conflicts.add(Position(row, col));
      } else {
        seen[value] = row;
      }
    }

    return conflicts;
  }

  /// Finds duplicate values in a specific 3x3 box.
  static Set<Position> _findBoxConflicts(SudokuBoard board, int boxIndex) {
    final conflicts = <Position>{};
    final seen = <int, Position>{}; // value -> first position

    final boxRow = (boxIndex ~/ 3) * 3;
    final boxCol = (boxIndex % 3) * 3;

    for (int r = boxRow; r < boxRow + 3; r++) {
      for (int c = boxCol; c < boxCol + 3; c++) {
        final cell = board.getCell(r, c);
        if (cell.isEmpty) continue;

        final value = cell.value!;
        if (seen.containsKey(value)) {
          // Found duplicate - mark both positions
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
