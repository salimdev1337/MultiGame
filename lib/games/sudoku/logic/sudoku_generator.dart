import 'dart:math';
import '../models/sudoku_board.dart';
import '../models/sudoku_cell.dart';
import 'sudoku_solver.dart';

/// Difficulty levels for Sudoku puzzles.
///
/// Each difficulty determines how many cells to remove from
/// a complete board, affecting puzzle complexity.
enum SudokuDifficulty {
  /// Easy: 36-40 clues (41-45 cells removed)
  /// Good for beginners, straightforward logic
  easy,

  /// Medium: 32-35 clues (46-49 cells removed)
  /// Requires basic Sudoku strategies
  medium,

  /// Hard: 28-31 clues (50-53 cells removed)
  /// Requires advanced techniques
  hard,

  /// Expert: 24-27 clues (54-57 cells removed)
  /// Very challenging, minimal clues
  expert,
}

/// Generates valid Sudoku puzzles with guaranteed unique solutions.
///
/// This class creates playable Sudoku puzzles by:
/// 1. Generating a complete valid board
/// 2. Strategically removing cells based on difficulty
/// 3. Ensuring each puzzle has exactly one solution
///
/// The generator uses randomization to create different puzzles
/// each time, providing variety for players.
class SudokuGenerator {
  final Random _random;

  /// Creates a new generator with an optional random seed.
  ///
  /// If [seed] is provided, the generator will produce
  /// deterministic puzzles (useful for testing).
  SudokuGenerator({int? seed}) : _random = Random(seed);

  /// Generates a new Sudoku puzzle at the specified difficulty.
  ///
  /// Returns a [SudokuBoard] with some cells filled (fixed clues)
  /// and others empty for the player to solve.
  ///
  /// The puzzle is guaranteed to have exactly one solution.
  ///
  /// Example:
  /// ```dart
  /// final generator = SudokuGenerator();
  /// final puzzle = generator.generate(SudokuDifficulty.medium);
  /// print('Empty cells: ${puzzle.emptyCount}');
  /// ```
  SudokuBoard generate(SudokuDifficulty difficulty) {
    // Step 1: Generate a complete valid board
    final completeBoard = _generateCompleteBoard();

    // Step 2: Remove cells based on difficulty
    final puzzle = _removeClues(completeBoard, difficulty);

    return puzzle;
  }

  /// Generates a complete, valid Sudoku board (all 81 cells filled).
  ///
  /// Uses a randomized filling approach for variety:
  /// 1. Fill diagonal 3x3 boxes (they don't conflict with each other)
  /// 2. Use solver to complete the rest
  SudokuBoard _generateCompleteBoard() {
    final board = SudokuBoard.empty();

    // Fill the three diagonal 3x3 boxes first
    // These boxes don't share rows/columns with each other,
    // so they can be filled independently
    _fillDiagonalBoxes(board);

    // Use the solver to fill the remaining cells
    // This gives us a complete valid board
    SudokuSolver.solve(board);

    return board;
  }

  /// Fills the three diagonal 3x3 boxes with random valid values.
  ///
  /// Diagonal boxes: (0,0), (3,3), (6,6)
  /// These boxes are independent and don't conflict with each other.
  void _fillDiagonalBoxes(SudokuBoard board) {
    // Fill box at (0, 0)
    _fillBox(board, 0, 0);

    // Fill box at (3, 3)
    _fillBox(board, 3, 3);

    // Fill box at (6, 6)
    _fillBox(board, 6, 6);
  }

  /// Fills a 3x3 box starting at (startRow, startCol) with random values 1-9.
  void _fillBox(SudokuBoard board, int startRow, int startCol) {
    // Create a shuffled list of numbers 1-9
    final numbers = List.generate(9, (i) => i + 1)..shuffle(_random);

    int index = 0;
    for (int row = startRow; row < startRow + 3; row++) {
      for (int col = startCol; col < startCol + 3; col++) {
        board.getCell(row, col).value = numbers[index++];
      }
    }
  }

  /// Removes cells from a complete board based on difficulty level.
  ///
  /// Uses a strategic removal approach:
  /// 1. Randomly select cells to remove
  /// 2. Temporarily remove the cell
  /// 3. Check if puzzle still has unique solution
  /// 4. If yes, keep it removed; if no, restore the cell
  /// 5. Continue until target number of clues reached
  SudokuBoard _removeClues(SudokuBoard completeBoard, SudokuDifficulty difficulty) {
    final puzzle = completeBoard.clone();

    // Determine target number of clues (filled cells)
    final targetClues = _getTargetClues(difficulty);
    final cellsToRemove = 81 - targetClues;

    // Create a list of all cell positions
    final positions = <_Position>[];
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        positions.add(_Position(row, col));
      }
    }

    // Shuffle positions for randomness
    positions.shuffle(_random);

    int removedCount = 0;

    // Try to remove cells while maintaining unique solution
    for (final pos in positions) {
      if (removedCount >= cellsToRemove) {
        break;
      }

      final cell = puzzle.getCell(pos.row, pos.col);
      final originalValue = cell.value;

      // Temporarily remove the cell
      cell.value = null;

      // Check if puzzle still has unique solution
      if (SudokuSolver.hasUniqueSolution(puzzle)) {
        // Keep it removed
        removedCount++;
      } else {
        // Restore the cell (removing it would create multiple solutions)
        cell.value = originalValue;
      }
    }

    // Mark all remaining filled cells as fixed (part of the puzzle)
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        final cell = puzzle.grid[row][col];
        if (cell.hasValue) {
          // Create a new cell with isFixed = true
          puzzle.grid[row][col] = SudokuCell(
            value: cell.value,
            isFixed: true,
          );
        }
      }
    }

    return puzzle;
  }

  /// Returns the target number of clues (filled cells) for a difficulty.
  ///
  /// More clues = easier puzzle
  /// Fewer clues = harder puzzle
  int _getTargetClues(SudokuDifficulty difficulty) {
    switch (difficulty) {
      case SudokuDifficulty.easy:
        // 36-40 clues: easier to solve
        return 36 + _random.nextInt(5);

      case SudokuDifficulty.medium:
        // 32-35 clues: moderate difficulty
        return 32 + _random.nextInt(4);

      case SudokuDifficulty.hard:
        // 28-31 clues: challenging
        return 28 + _random.nextInt(4);

      case SudokuDifficulty.expert:
        // 24-27 clues: very difficult
        return 24 + _random.nextInt(4);
    }
  }

  /// Generates multiple puzzles at once (useful for pre-generation).
  ///
  /// Example:
  /// ```dart
  /// final generator = SudokuGenerator();
  /// final puzzles = generator.generateBatch(
  ///   difficulty: SudokuDifficulty.medium,
  ///   count: 10,
  /// );
  /// ```
  List<SudokuBoard> generateBatch({
    required SudokuDifficulty difficulty,
    required int count,
  }) {
    return List.generate(count, (_) => generate(difficulty));
  }
}

/// Helper class to store row/col position.
class _Position {
  final int row;
  final int col;

  _Position(this.row, this.col);
}
