import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/sudoku/logic/sudoku_validator.dart';
import 'package:multigame/games/sudoku/models/sudoku_board.dart';

void main() {
  group('Position', () {
    test('creates position with row and col', () {
      final pos = Position(3, 5);
      expect(pos.row, equals(3));
      expect(pos.col, equals(5));
    });

    test('equality works correctly', () {
      final pos1 = Position(2, 4);
      final pos2 = Position(2, 4);
      final pos3 = Position(2, 5);

      expect(pos1, equals(pos2));
      expect(pos1, isNot(equals(pos3)));
    });

    test('hashCode works correctly', () {
      final pos1 = Position(2, 4);
      final pos2 = Position(2, 4);

      expect(pos1.hashCode, equals(pos2.hashCode));
    });

    test('toString provides readable output', () {
      final pos = Position(3, 7);
      expect(pos.toString(), equals('Position(3, 7)'));
    });
  });

  group('SudokuValidator', () {
    test('validates empty board as valid', () {
      final board = SudokuBoard.empty();
      expect(SudokuValidator.isValidBoard(board), isTrue);
    });

    test('validates partially filled valid board', () {
      final values = [
        [5, 3, 0, 0, 7, 0, 0, 0, 0],
        [6, 0, 0, 1, 9, 5, 0, 0, 0],
        [0, 9, 8, 0, 0, 0, 0, 6, 0],
        [8, 0, 0, 0, 6, 0, 0, 0, 3],
        [4, 0, 0, 8, 0, 3, 0, 0, 1],
        [7, 0, 0, 0, 2, 0, 0, 0, 6],
        [0, 6, 0, 0, 0, 0, 2, 8, 0],
        [0, 0, 0, 4, 1, 9, 0, 0, 5],
        [0, 0, 0, 0, 8, 0, 0, 7, 9],
      ];

      final board = SudokuBoard.fromValues(values);
      expect(SudokuValidator.isValidBoard(board), isTrue);
    });

    test('detects row conflict', () {
      final board = SudokuBoard.empty();
      board.grid[0][0].value = 5;
      board.grid[0][3].value = 5; // Duplicate in row 0

      expect(SudokuValidator.isValidBoard(board), isFalse);
    });

    test('detects column conflict', () {
      final board = SudokuBoard.empty();
      board.grid[0][0].value = 7;
      board.grid[4][0].value = 7; // Duplicate in column 0

      expect(SudokuValidator.isValidBoard(board), isFalse);
    });

    test('detects box conflict', () {
      final board = SudokuBoard.empty();
      board.grid[0][0].value = 3;
      board.grid[2][2].value = 3; // Duplicate in top-left box

      expect(SudokuValidator.isValidBoard(board), isFalse);
    });

    test('detects multiple conflicts', () {
      final board = SudokuBoard.empty();
      board.grid[0][0].value = 5;
      board.grid[0][1].value = 5; // Row conflict
      board.grid[1][0].value = 5; // Column conflict
      board.grid[2][2].value = 5; // Box conflict

      final conflicts = SudokuValidator.getConflictPositions(board);
      expect(conflicts.length, greaterThanOrEqualTo(4));
    });

    test('getConflictPositions returns all conflicting cells', () {
      final board = SudokuBoard.empty();
      board.grid[0][0].value = 5;
      board.grid[0][5].value = 5; // Row conflict

      final conflicts = SudokuValidator.getConflictPositions(board);

      expect(conflicts, contains(Position(0, 0)));
      expect(conflicts, contains(Position(0, 5)));
    });

    test('getConflictPositions returns empty set for valid board', () {
      final values = [
        [5, 3, 0, 0, 7, 0, 0, 0, 0],
        [6, 0, 0, 1, 9, 5, 0, 0, 0],
        [0, 9, 8, 0, 0, 0, 0, 6, 0],
        [8, 0, 0, 0, 6, 0, 0, 0, 3],
        [4, 0, 0, 8, 0, 3, 0, 0, 1],
        [7, 0, 0, 0, 2, 0, 0, 0, 6],
        [0, 6, 0, 0, 0, 0, 2, 8, 0],
        [0, 0, 0, 4, 1, 9, 0, 0, 5],
        [0, 0, 0, 0, 8, 0, 0, 7, 9],
      ];

      final board = SudokuBoard.fromValues(values);
      final conflicts = SudokuValidator.getConflictPositions(board);

      expect(conflicts, isEmpty);
    });

    test('isSolved returns false for incomplete board', () {
      final board = SudokuBoard.empty();
      board.grid[0][0].value = 5;

      expect(SudokuValidator.isSolved(board), isFalse);
    });

    test('isSolved returns false for full board with conflicts', () {
      // Fill board with all 5s (invalid)
      final board = SudokuBoard.empty();
      for (int row = 0; row < 9; row++) {
        for (int col = 0; col < 9; col++) {
          board.grid[row][col].value = 5;
        }
      }

      expect(SudokuValidator.isSolved(board), isFalse);
    });

    test('isSolved returns true for correctly solved board', () {
      // Known valid complete Sudoku solution
      final values = [
        [5, 3, 4, 6, 7, 8, 9, 1, 2],
        [6, 7, 2, 1, 9, 5, 3, 4, 8],
        [1, 9, 8, 3, 4, 2, 5, 6, 7],
        [8, 5, 9, 7, 6, 1, 4, 2, 3],
        [4, 2, 6, 8, 5, 3, 7, 9, 1],
        [7, 1, 3, 9, 2, 4, 8, 5, 6],
        [9, 6, 1, 5, 3, 7, 2, 8, 4],
        [2, 8, 7, 4, 1, 9, 6, 3, 5],
        [3, 4, 5, 2, 8, 6, 1, 7, 9],
      ];

      final board = SudokuBoard.fromValues(values);
      expect(SudokuValidator.isSolved(board), isTrue);
    });

    test('canPlaceValue returns true for valid placement', () {
      final board = SudokuBoard.empty();
      expect(SudokuValidator.canPlaceValue(board, 0, 0, 5), isTrue);
    });

    test('canPlaceValue returns false for row conflict', () {
      final board = SudokuBoard.empty();
      board.grid[0][3].value = 5;

      expect(SudokuValidator.canPlaceValue(board, 0, 0, 5), isFalse);
    });

    test('canPlaceValue returns false for column conflict', () {
      final board = SudokuBoard.empty();
      board.grid[4][0].value = 7;

      expect(SudokuValidator.canPlaceValue(board, 0, 0, 7), isFalse);
    });

    test('canPlaceValue returns false for box conflict', () {
      final board = SudokuBoard.empty();
      board.grid[2][2].value = 3;

      expect(SudokuValidator.canPlaceValue(board, 0, 0, 3), isFalse);
    });

    test('canPlaceValue returns false for invalid values', () {
      final board = SudokuBoard.empty();

      expect(SudokuValidator.canPlaceValue(board, 0, 0, 0), isFalse);
      expect(SudokuValidator.canPlaceValue(board, 0, 0, 10), isFalse);
      expect(SudokuValidator.canPlaceValue(board, 0, 0, -1), isFalse);
    });

    test('canPlaceValue allows replacing value at same position', () {
      final board = SudokuBoard.empty();
      board.grid[0][0].value = 5;

      // Should allow placing 5 at same position (replacing itself)
      expect(SudokuValidator.canPlaceValue(board, 0, 0, 5), isTrue);
    });

    test('ignores empty cells in conflict detection', () {
      final board = SudokuBoard.empty();
      board.grid[0][0].value = null;
      board.grid[0][1].value = null;
      board.grid[0][2].value = 5;

      expect(SudokuValidator.isValidBoard(board), isTrue);
    });

    test('detects all conflicting positions in row', () {
      final board = SudokuBoard.empty();
      board.grid[0][0].value = 5;
      board.grid[0][3].value = 5;
      board.grid[0][7].value = 5; // Three 5s in row 0

      final conflicts = SudokuValidator.getConflictPositions(board);

      expect(conflicts, contains(Position(0, 0)));
      expect(conflicts, contains(Position(0, 3)));
      expect(conflicts, contains(Position(0, 7)));
    });

    test('detects all conflicting positions in column', () {
      final board = SudokuBoard.empty();
      board.grid[0][0].value = 7;
      board.grid[4][0].value = 7;
      board.grid[8][0].value = 7; // Three 7s in column 0

      final conflicts = SudokuValidator.getConflictPositions(board);

      expect(conflicts, contains(Position(0, 0)));
      expect(conflicts, contains(Position(4, 0)));
      expect(conflicts, contains(Position(8, 0)));
    });

    test('detects all conflicting positions in box', () {
      final board = SudokuBoard.empty();
      board.grid[0][0].value = 9;
      board.grid[1][1].value = 9;
      board.grid[2][2].value = 9; // Three 9s in top-left box

      final conflicts = SudokuValidator.getConflictPositions(board);

      expect(conflicts, contains(Position(0, 0)));
      expect(conflicts, contains(Position(1, 1)));
      expect(conflicts, contains(Position(2, 2)));
    });

    test('works correctly with different box indices', () {
      final board = SudokuBoard.empty();

      // Top-right box (index 2)
      board.grid[0][6].value = 4;
      board.grid[1][7].value = 4;

      // Bottom-left box (index 6)
      board.grid[6][0].value = 8;
      board.grid[7][1].value = 8;

      final conflicts = SudokuValidator.getConflictPositions(board);

      expect(conflicts, contains(Position(0, 6)));
      expect(conflicts, contains(Position(1, 7)));
      expect(conflicts, contains(Position(6, 0)));
      expect(conflicts, contains(Position(7, 1)));
    });
  });
}
