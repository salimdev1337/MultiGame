import 'sudoku_cell.dart';

/// Represents a complete 9x9 Sudoku board.
///
/// The board is organized as a 2D grid where:
/// - grid[row][col] accesses a specific cell
/// - Rows and columns are indexed 0-8
/// - The board is divided into nine 3x3 boxes (also indexed 0-8)
///
/// Box numbering:
/// ```
/// 0 | 1 | 2
/// --+---+--
/// 3 | 4 | 5
/// --+---+--
/// 6 | 7 | 8
/// ```
class SudokuBoard {
  /// The 9x9 grid of cells
  final List<List<SudokuCell>> grid;

  /// Creates a Sudoku board with an optional initial grid.
  /// If no grid is provided, creates an empty 9x9 board.
  SudokuBoard({List<List<SudokuCell>>? grid})
      : grid = grid ??
            List.generate(
              9,
              (_) => List.generate(9, (_) => SudokuCell()),
            );

  /// Creates an empty 9x9 board (all cells empty)
  factory SudokuBoard.empty() {
    return SudokuBoard();
  }

  /// Creates a board from a 2D integer array.
  /// 0 represents empty cells, 1-9 represent fixed puzzle clues.
  factory SudokuBoard.fromValues(List<List<int>> values) {
    if (values.length != 9 || values.any((row) => row.length != 9)) {
      throw ArgumentError('Board must be 9x9');
    }

    final grid = List.generate(9, (row) {
      return List.generate(9, (col) {
        final value = values[row][col];
        if (value < 0 || value > 9) {
          throw ArgumentError('Values must be 0-9');
        }
        return SudokuCell(
          value: value == 0 ? null : value,
          isFixed: value != 0, // Non-zero values are fixed
        );
      });
    });

    return SudokuBoard(grid: grid);
  }

  /// Gets the cell at the specified position
  SudokuCell getCell(int row, int col) {
    _validatePosition(row, col);
    return grid[row][col];
  }

  /// Sets a cell at the specified position
  void setCell(int row, int col, SudokuCell cell) {
    _validatePosition(row, col);
    grid[row][col] = cell;
  }

  /// Returns all cells in the specified row (0-8)
  List<SudokuCell> getRow(int row) {
    if (row < 0 || row >= 9) {
      throw ArgumentError('Row must be 0-8, got $row');
    }
    return List.from(grid[row]);
  }

  /// Returns all cells in the specified column (0-8)
  List<SudokuCell> getColumn(int col) {
    if (col < 0 || col >= 9) {
      throw ArgumentError('Column must be 0-8, got $col');
    }
    return List.generate(9, (row) => grid[row][col]);
  }

  /// Returns all cells in the 3x3 box containing the specified position
  List<SudokuCell> getBox(int row, int col) {
    _validatePosition(row, col);

    // Calculate the top-left corner of the 3x3 box
    final boxStartRow = (row ~/ 3) * 3;
    final boxStartCol = (col ~/ 3) * 3;

    final cells = <SudokuCell>[];
    for (int r = boxStartRow; r < boxStartRow + 3; r++) {
      for (int c = boxStartCol; c < boxStartCol + 3; c++) {
        cells.add(grid[r][c]);
      }
    }
    return cells;
  }

  /// Returns all cells in the specified box by box index (0-8)
  ///
  /// Box layout:
  /// ```
  /// 0 | 1 | 2
  /// --+---+--
  /// 3 | 4 | 5
  /// --+---+--
  /// 6 | 7 | 8
  /// ```
  List<SudokuCell> getBoxByIndex(int boxIndex) {
    if (boxIndex < 0 || boxIndex >= 9) {
      throw ArgumentError('Box index must be 0-8, got $boxIndex');
    }

    final boxRow = (boxIndex ~/ 3) * 3;
    final boxCol = (boxIndex % 3) * 3;

    return getBox(boxRow, boxCol);
  }

  /// Returns true if all cells have values
  bool get isFull {
    return grid.every((row) => row.every((cell) => cell.hasValue));
  }

  /// Returns true if the board has at least one empty cell
  bool get hasEmptyCells {
    return grid.any((row) => row.any((cell) => cell.isEmpty));
  }

  /// Counts the number of empty cells
  int get emptyCount {
    return grid.fold(0, (sum, row) {
      return sum + row.where((cell) => cell.isEmpty).length;
    });
  }

  /// Counts the number of filled cells
  int get filledCount => 81 - emptyCount;

  /// Resets all non-fixed cells (clears user entries, keeps puzzle clues)
  void reset() {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        final cell = grid[row][col];
        if (!cell.isFixed) {
          cell.value = null;
          cell.notes.clear();
          cell.isError = false;
        }
      }
    }
  }

  /// Clears all error flags on the board
  void clearErrors() {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        grid[row][col].isError = false;
      }
    }
  }

  /// Creates a deep copy of this board
  SudokuBoard clone() {
    final newGrid = List.generate(9, (row) {
      return List.generate(9, (col) {
        final cell = grid[row][col];
        return SudokuCell(
          value: cell.value,
          isFixed: cell.isFixed,
          notes: Set.from(cell.notes),
          isError: cell.isError,
        );
      });
    });
    return SudokuBoard(grid: newGrid);
  }

  /// Converts the board to a 2D integer array (for saving/loading)
  /// 0 represents empty cells, 1-9 represent values
  List<List<int>> toValues() {
    return List.generate(9, (row) {
      return List.generate(9, (col) {
        return grid[row][col].value ?? 0;
      });
    });
  }

  /// Converts the board to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'grid': grid.map((row) => row.map((cell) => cell.toJson()).toList()).toList(),
    };
  }

  /// Creates a board from JSON
  factory SudokuBoard.fromJson(Map<String, dynamic> json) {
    final gridData = json['grid'] as List<dynamic>;
    final grid = gridData.map((rowData) {
      final row = rowData as List<dynamic>;
      return row.map((cellData) => SudokuCell.fromJson(cellData as Map<String, dynamic>)).toList();
    }).toList();
    return SudokuBoard(grid: grid);
  }

  /// Returns a string representation of the board (useful for debugging)
  @override
  String toString() {
    final buffer = StringBuffer();
    for (int row = 0; row < 9; row++) {
      if (row % 3 == 0 && row != 0) {
        buffer.writeln('------+-------+------');
      }
      for (int col = 0; col < 9; col++) {
        if (col % 3 == 0 && col != 0) {
          buffer.write('| ');
        }
        final value = grid[row][col].value;
        buffer.write(value == null ? '.' : value.toString());
        buffer.write(' ');
      }
      buffer.writeln();
    }
    return buffer.toString();
  }

  /// Validates that row and column are in valid range (0-8)
  void _validatePosition(int row, int col) {
    if (row < 0 || row >= 9 || col < 0 || col >= 9) {
      throw ArgumentError('Position must be 0-8, got ($row, $col)');
    }
  }
}
