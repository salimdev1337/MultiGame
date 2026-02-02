import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/sudoku/logic/sudoku_solver.dart';
import 'package:multigame/games/sudoku/logic/sudoku_validator.dart';
import 'package:multigame/games/sudoku/models/sudoku_board.dart';

void main() {
  group('SudokuSolver', () {
    group('solve()', () {
      test('should solve a simple puzzle', () {
        // Arrange: Easy puzzle with many clues
        final board = SudokuBoard.fromValues([
          [5, 3, 0, 0, 7, 0, 0, 0, 0],
          [6, 0, 0, 1, 9, 5, 0, 0, 0],
          [0, 9, 8, 0, 0, 0, 0, 6, 0],
          [8, 0, 0, 0, 6, 0, 0, 0, 3],
          [4, 0, 0, 8, 0, 3, 0, 0, 1],
          [7, 0, 0, 0, 2, 0, 0, 0, 6],
          [0, 6, 0, 0, 0, 0, 2, 8, 0],
          [0, 0, 0, 4, 1, 9, 0, 0, 5],
          [0, 0, 0, 0, 8, 0, 0, 7, 9],
        ]);

        // Act
        final solved = SudokuSolver.solve(board);

        // Assert
        expect(solved, isTrue, reason: 'Puzzle should be solvable');
        expect(board.isFull, isTrue, reason: 'Board should be full');
        expect(SudokuValidator.isSolved(board), isTrue,
            reason: 'Board should be valid and complete');
      });

      test('should solve a harder puzzle', () {
        // Arrange: More difficult puzzle with fewer clues
        final board = SudokuBoard.fromValues([
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 3, 0, 8, 5],
          [0, 0, 1, 0, 2, 0, 0, 0, 0],
          [0, 0, 0, 5, 0, 7, 0, 0, 0],
          [0, 0, 4, 0, 0, 0, 1, 0, 0],
          [0, 9, 0, 0, 0, 0, 0, 0, 0],
          [5, 0, 0, 0, 0, 0, 0, 7, 3],
          [0, 0, 2, 0, 1, 0, 0, 0, 0],
          [0, 0, 0, 0, 4, 0, 0, 0, 9],
        ]);

        // Act
        final solved = SudokuSolver.solve(board);

        // Assert
        expect(solved, isTrue);
        expect(board.isFull, isTrue);
        expect(SudokuValidator.isSolved(board), isTrue);
      });

      test('should return false for unsolvable puzzle', () {
        // Arrange: Invalid puzzle (two 5s in first row)
        final board = SudokuBoard.fromValues([
          [5, 5, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
        ]);

        // Act
        final solved = SudokuSolver.solve(board);

        // Assert
        expect(solved, isFalse, reason: 'Invalid puzzle should not be solvable');
      });

      test('should return true for already solved puzzle', () {
        // Arrange: Complete valid solution
        final board = SudokuBoard.fromValues([
          [5, 3, 4, 6, 7, 8, 9, 1, 2],
          [6, 7, 2, 1, 9, 5, 3, 4, 8],
          [1, 9, 8, 3, 4, 2, 5, 6, 7],
          [8, 5, 9, 7, 6, 1, 4, 2, 3],
          [4, 2, 6, 8, 5, 3, 7, 9, 1],
          [7, 1, 3, 9, 2, 4, 8, 5, 6],
          [9, 6, 1, 5, 3, 7, 2, 8, 4],
          [2, 8, 7, 4, 1, 9, 6, 3, 5],
          [3, 4, 5, 2, 8, 6, 1, 7, 9],
        ]);

        // Act
        final solved = SudokuSolver.solve(board);

        // Assert
        expect(solved, isTrue);
        expect(SudokuValidator.isSolved(board), isTrue);
      });
    });

    group('getSolution()', () {
      test('should return solved copy without modifying original', () {
        // Arrange
        final original = SudokuBoard.fromValues([
          [5, 3, 0, 0, 7, 0, 0, 0, 0],
          [6, 0, 0, 1, 9, 5, 0, 0, 0],
          [0, 9, 8, 0, 0, 0, 0, 6, 0],
          [8, 0, 0, 0, 6, 0, 0, 0, 3],
          [4, 0, 0, 8, 0, 3, 0, 0, 1],
          [7, 0, 0, 0, 2, 0, 0, 0, 6],
          [0, 6, 0, 0, 0, 0, 2, 8, 0],
          [0, 0, 0, 4, 1, 9, 0, 0, 5],
          [0, 0, 0, 0, 8, 0, 0, 7, 9],
        ]);
        final originalEmptyCount = original.emptyCount;

        // Act
        final solved = SudokuSolver.getSolution(original);

        // Assert
        expect(solved, isNotNull);
        expect(solved!.isFull, isTrue);
        expect(SudokuValidator.isSolved(solved), isTrue);
        expect(original.emptyCount, equals(originalEmptyCount),
            reason: 'Original board should not be modified');
      });

      test('should return null for unsolvable puzzle', () {
        // Arrange: Invalid puzzle
        final board = SudokuBoard.fromValues([
          [5, 5, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
        ]);

        // Act
        final solved = SudokuSolver.getSolution(board);

        // Assert
        expect(solved, isNull);
      });
    });

    group('getHint()', () {
      test('should return correct value for empty cell', () {
        // Arrange
        final board = SudokuBoard.fromValues([
          [5, 3, 0, 0, 7, 0, 0, 0, 0],
          [6, 0, 0, 1, 9, 5, 0, 0, 0],
          [0, 9, 8, 0, 0, 0, 0, 6, 0],
          [8, 0, 0, 0, 6, 0, 0, 0, 3],
          [4, 0, 0, 8, 0, 3, 0, 0, 1],
          [7, 0, 0, 0, 2, 0, 0, 0, 6],
          [0, 6, 0, 0, 0, 0, 2, 8, 0],
          [0, 0, 0, 4, 1, 9, 0, 0, 5],
          [0, 0, 0, 0, 8, 0, 0, 7, 9],
        ]);

        // Act: Get hint for cell (0, 2) which is empty
        final hint = SudokuSolver.getHint(board, 0, 2);

        // Assert
        expect(hint, isNotNull);
        expect(hint! >= 1 && hint <= 9, isTrue);

        // Verify the hint is valid
        expect(SudokuValidator.canPlaceValue(board, 0, 2, hint), isTrue);
      });

      test('should return null for filled cell', () {
        // Arrange
        final board = SudokuBoard.fromValues([
          [5, 3, 0, 0, 7, 0, 0, 0, 0],
          [6, 0, 0, 1, 9, 5, 0, 0, 0],
          [0, 9, 8, 0, 0, 0, 0, 6, 0],
          [8, 0, 0, 0, 6, 0, 0, 0, 3],
          [4, 0, 0, 8, 0, 3, 0, 0, 1],
          [7, 0, 0, 0, 2, 0, 0, 0, 6],
          [0, 6, 0, 0, 0, 0, 2, 8, 0],
          [0, 0, 0, 4, 1, 9, 0, 0, 5],
          [0, 0, 0, 0, 8, 0, 0, 7, 9],
        ]);

        // Act: Get hint for cell (0, 0) which has value 5
        final hint = SudokuSolver.getHint(board, 0, 0);

        // Assert
        expect(hint, isNull, reason: 'Should return null for filled cells');
      });

      test('should return null for unsolvable puzzle', () {
        // Arrange: Invalid puzzle
        final board = SudokuBoard.fromValues([
          [5, 5, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
        ]);

        // Act
        final hint = SudokuSolver.getHint(board, 0, 2);

        // Assert
        expect(hint, isNull);
      });
    });

    group('isSolvable()', () {
      test('should return true for solvable puzzle', () {
        // Arrange
        final board = SudokuBoard.fromValues([
          [5, 3, 0, 0, 7, 0, 0, 0, 0],
          [6, 0, 0, 1, 9, 5, 0, 0, 0],
          [0, 9, 8, 0, 0, 0, 0, 6, 0],
          [8, 0, 0, 0, 6, 0, 0, 0, 3],
          [4, 0, 0, 8, 0, 3, 0, 0, 1],
          [7, 0, 0, 0, 2, 0, 0, 0, 6],
          [0, 6, 0, 0, 0, 0, 2, 8, 0],
          [0, 0, 0, 4, 1, 9, 0, 0, 5],
          [0, 0, 0, 0, 8, 0, 0, 7, 9],
        ]);

        // Act
        final solvable = SudokuSolver.isSolvable(board);

        // Assert
        expect(solvable, isTrue);
      });

      test('should return false for unsolvable puzzle', () {
        // Arrange: Invalid puzzle
        final board = SudokuBoard.fromValues([
          [5, 5, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
        ]);

        // Act
        final solvable = SudokuSolver.isSolvable(board);

        // Assert
        expect(solvable, isFalse);
      });
    });

    group('getPossibleValues()', () {
      test('should return all valid values for empty cell', () {
        // Arrange: Simple board with constraints
        final board = SudokuBoard.fromValues([
          [5, 3, 0, 0, 0, 0, 0, 0, 0],
          [6, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
        ]);

        // Act: Cell (0, 2) can't be 5 or 3 (same row) or 6 (same box)
        final possible = SudokuSolver.getPossibleValues(board, 0, 2);

        // Assert
        expect(possible.contains(5), isFalse, reason: '5 is in same row');
        expect(possible.contains(3), isFalse, reason: '3 is in same row');
        expect(possible.contains(6), isFalse, reason: '6 is in same box');
        expect(possible.length, greaterThan(0));
      });

      test('should return empty set for filled cell', () {
        // Arrange
        final board = SudokuBoard.fromValues([
          [5, 3, 0, 0, 0, 0, 0, 0, 0],
          [6, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
        ]);

        // Act: Cell (0, 0) already has value 5
        final possible = SudokuSolver.getPossibleValues(board, 0, 0);

        // Assert
        expect(possible.isEmpty, isTrue);
      });

      test('should return only valid values respecting all constraints', () {
        // Arrange: Cell with multiple constraints
        final board = SudokuBoard.fromValues([
          [1, 2, 3, 0, 0, 0, 0, 0, 0],
          [4, 5, 6, 0, 0, 0, 0, 0, 0],
          [7, 8, 9, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
        ]);

        // Act: Cell (0, 3) - first box is full (1-9 used)
        // But column 3 and row 0 have no other constraints
        final possible = SudokuSolver.getPossibleValues(board, 0, 3);

        // Assert
        // Cell (0,3) can be any value 1-9 except those in row 0 (1,2,3)
        expect(possible.contains(1), isFalse);
        expect(possible.contains(2), isFalse);
        expect(possible.contains(3), isFalse);
        expect(possible.contains(4), isTrue);
        expect(possible.contains(5), isTrue);
      });
    });

    group('hasUniqueSolution()', () {
      test('should return true for puzzle with unique solution', () {
        // Arrange: Well-formed puzzle with unique solution
        final board = SudokuBoard.fromValues([
          [5, 3, 0, 0, 7, 0, 0, 0, 0],
          [6, 0, 0, 1, 9, 5, 0, 0, 0],
          [0, 9, 8, 0, 0, 0, 0, 6, 0],
          [8, 0, 0, 0, 6, 0, 0, 0, 3],
          [4, 0, 0, 8, 0, 3, 0, 0, 1],
          [7, 0, 0, 0, 2, 0, 0, 0, 6],
          [0, 6, 0, 0, 0, 0, 2, 8, 0],
          [0, 0, 0, 4, 1, 9, 0, 0, 5],
          [0, 0, 0, 0, 8, 0, 0, 7, 9],
        ]);

        // Act
        final unique = SudokuSolver.hasUniqueSolution(board);

        // Assert
        expect(unique, isTrue);
      });

      test('should return false for puzzle with multiple solutions', () {
        // Arrange: Nearly empty board - multiple solutions possible
        final board = SudokuBoard.fromValues([
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
        ]);

        // Act
        final unique = SudokuSolver.hasUniqueSolution(board);

        // Assert
        expect(unique, isFalse, reason: 'Empty board has many solutions');
      });

      test('should return false for unsolvable puzzle', () {
        // Arrange: Invalid puzzle
        final board = SudokuBoard.fromValues([
          [5, 5, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0, 0, 0],
        ]);

        // Act
        final unique = SudokuSolver.hasUniqueSolution(board);

        // Assert
        expect(unique, isFalse, reason: 'Unsolvable puzzle has no solutions');
      });
    });
  });
}
