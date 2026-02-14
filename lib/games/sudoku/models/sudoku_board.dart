// Sudoku board model - see docs/SUDOKU_ARCHITECTURE.md

import 'sudoku_cell.dart';

class SudokuBoard {
  final List<List<SudokuCell>> grid;

  SudokuBoard({List<List<SudokuCell>>? grid})
    : grid =
          grid ??
          List.generate(9, (_) => List.generate(9, (_) => SudokuCell()));

  factory SudokuBoard.empty() {
    return SudokuBoard();
  }

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
          isFixed: value != 0,
        );
      });
    });

    return SudokuBoard(grid: grid);
  }

  SudokuCell getCell(int row, int col) {
    _validatePosition(row, col);
    return grid[row][col];
  }

  void setCell(int row, int col, SudokuCell cell) {
    _validatePosition(row, col);
    grid[row][col] = cell;
  }

  List<SudokuCell> getRow(int row) {
    if (row < 0 || row >= 9) {
      throw ArgumentError('Row must be 0-8, got $row');
    }
    return List.from(grid[row]);
  }

  List<SudokuCell> getColumn(int col) {
    if (col < 0 || col >= 9) {
      throw ArgumentError('Column must be 0-8, got $col');
    }
    return List.generate(9, (row) => grid[row][col]);
  }

  List<SudokuCell> getBox(int row, int col) {
    _validatePosition(row, col);

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

  List<SudokuCell> getBoxByIndex(int boxIndex) {
    if (boxIndex < 0 || boxIndex >= 9) {
      throw ArgumentError('Box index must be 0-8, got $boxIndex');
    }

    final boxRow = (boxIndex ~/ 3) * 3;
    final boxCol = (boxIndex % 3) * 3;

    return getBox(boxRow, boxCol);
  }

  bool get isFull {
    return grid.every((row) => row.every((cell) => cell.hasValue));
  }

  bool get hasEmptyCells {
    return grid.any((row) => row.any((cell) => cell.isEmpty));
  }

  int get emptyCount {
    return grid.fold(0, (sum, row) {
      return sum + row.where((cell) => cell.isEmpty).length;
    });
  }

  int get filledCount => 81 - emptyCount;

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

  void clearErrors() {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        grid[row][col].isError = false;
      }
    }
  }

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

  List<List<int>> toValues() {
    return List.generate(9, (row) {
      return List.generate(9, (col) {
        return grid[row][col].value ?? 0;
      });
    });
  }

  Map<String, dynamic> toJson() {
    return {
      'grid': grid
          .map((row) => row.map((cell) => cell.toJson()).toList())
          .toList(),
    };
  }

  factory SudokuBoard.fromJson(Map<String, dynamic> json) {
    final gridData = json['grid'] as List<dynamic>;
    final grid = gridData.map((rowData) {
      final row = rowData as List<dynamic>;
      return row
          .map(
            (cellData) => SudokuCell.fromJson(cellData as Map<String, dynamic>),
          )
          .toList();
    }).toList();
    return SudokuBoard(grid: grid);
  }

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

  void _validatePosition(int row, int col) {
    if (row < 0 || row >= 9 || col < 0 || col >= 9) {
      throw ArgumentError('Position must be 0-8, got ($row, $col)');
    }
  }
}
