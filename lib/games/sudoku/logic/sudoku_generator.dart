// Sudoku puzzle generator - see docs/SUDOKU_ALGORITHMS.md

import 'dart:math';
import '../models/sudoku_board.dart';
import '../models/sudoku_cell.dart';
import 'sudoku_solver.dart';

enum SudokuDifficulty {
  easy,
  medium,
  hard,
  expert,
}

class SudokuGenerator {
  final Random _random;

  SudokuGenerator({int? seed}) : _random = Random(seed);

  SudokuBoard generate(SudokuDifficulty difficulty) {
    final completeBoard = _generateCompleteBoard();
    final puzzle = _removeClues(completeBoard, difficulty);
    return puzzle;
  }

  SudokuBoard _generateCompleteBoard() {
    final board = SudokuBoard.empty();
    _fillDiagonalBoxes(board);
    SudokuSolver.solve(board);
    return board;
  }

  void _fillDiagonalBoxes(SudokuBoard board) {
    _fillBox(board, 0, 0);
    _fillBox(board, 3, 3);
    _fillBox(board, 6, 6);
  }

  void _fillBox(SudokuBoard board, int startRow, int startCol) {
    final numbers = List.generate(9, (i) => i + 1)..shuffle(_random);

    int index = 0;
    for (int row = startRow; row < startRow + 3; row++) {
      for (int col = startCol; col < startCol + 3; col++) {
        board.getCell(row, col).value = numbers[index++];
      }
    }
  }

  SudokuBoard _removeClues(SudokuBoard completeBoard, SudokuDifficulty difficulty) {
    final puzzle = completeBoard.clone();

    final targetClues = _getTargetClues(difficulty);
    final cellsToRemove = 81 - targetClues;

    final positions = <_Position>[];
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        positions.add(_Position(row, col));
      }
    }

    positions.shuffle(_random);

    int removedCount = 0;

    for (final pos in positions) {
      if (removedCount >= cellsToRemove) {
        break;
      }

      final cell = puzzle.getCell(pos.row, pos.col);
      final originalValue = cell.value;

      cell.value = null;

      if (SudokuSolver.hasUniqueSolution(puzzle)) {
        removedCount++;
      } else {
        cell.value = originalValue;
      }
    }

    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        final cell = puzzle.grid[row][col];
        if (cell.hasValue) {
          puzzle.grid[row][col] = SudokuCell(
            value: cell.value,
            isFixed: true,
          );
        }
      }
    }

    return puzzle;
  }

  int _getTargetClues(SudokuDifficulty difficulty) {
    switch (difficulty) {
      case SudokuDifficulty.easy:
        return 36 + _random.nextInt(5);

      case SudokuDifficulty.medium:
        return 32 + _random.nextInt(4);

      case SudokuDifficulty.hard:
        return 28 + _random.nextInt(4);

      case SudokuDifficulty.expert:
        return 24 + _random.nextInt(4);
    }
  }

  List<SudokuBoard> generateBatch({
    required SudokuDifficulty difficulty,
    required int count,
  }) {
    return List.generate(count, (_) => generate(difficulty));
  }
}

class _Position {
  final int row;
  final int col;

  _Position(this.row, this.col);
}
