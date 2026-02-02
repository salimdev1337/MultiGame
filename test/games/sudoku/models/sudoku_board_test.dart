import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/sudoku/models/sudoku_board.dart';
import 'package:multigame/games/sudoku/models/sudoku_cell.dart';

void main() {
  group('SudokuBoard', () {
    test('creates empty board by default', () {
      final board = SudokuBoard();

      expect(board.grid.length, equals(9));
      expect(board.grid[0].length, equals(9));
      expect(board.hasEmptyCells, isTrue);
      expect(board.isFull, isFalse);
      expect(board.emptyCount, equals(81));
      expect(board.filledCount, equals(0));
    });

    test('creates empty board via factory', () {
      final board = SudokuBoard.empty();

      expect(board.emptyCount, equals(81));
      expect(board.isFull, isFalse);
    });

    test('creates board from values', () {
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

      expect(board.getCell(0, 0).value, equals(5));
      expect(board.getCell(0, 0).isFixed, isTrue);
      expect(board.getCell(0, 2).value, isNull);
      expect(board.getCell(0, 2).isFixed, isFalse);
    });

    test('fromValues throws on invalid board size', () {
      expect(
        () => SudokuBoard.fromValues([
          [1, 2, 3]
        ]),
        throwsArgumentError,
      );
    });

    test('fromValues throws on invalid values', () {
      final invalidValues = List.generate(9, (_) => List.filled(9, 10));

      expect(() => SudokuBoard.fromValues(invalidValues), throwsArgumentError);
    });

    test('getCell returns correct cell', () {
      final board = SudokuBoard();
      board.grid[3][4].value = 7;

      final cell = board.getCell(3, 4);
      expect(cell.value, equals(7));
    });

    test('getCell throws on invalid position', () {
      final board = SudokuBoard();

      expect(() => board.getCell(-1, 0), throwsArgumentError);
      expect(() => board.getCell(0, 9), throwsArgumentError);
      expect(() => board.getCell(10, 5), throwsArgumentError);
    });

    test('setCell updates cell correctly', () {
      final board = SudokuBoard();
      final newCell = SudokuCell(value: 8, isFixed: true);

      board.setCell(2, 5, newCell);

      expect(board.getCell(2, 5).value, equals(8));
      expect(board.getCell(2, 5).isFixed, isTrue);
    });

    test('setCell throws on invalid position', () {
      final board = SudokuBoard();
      final cell = SudokuCell(value: 5);

      expect(() => board.setCell(-1, 0, cell), throwsArgumentError);
      expect(() => board.setCell(0, 9, cell), throwsArgumentError);
    });

    test('getRow returns all cells in row', () {
      final board = SudokuBoard();
      for (int col = 0; col < 9; col++) {
        board.grid[2][col].value = col + 1;
      }

      final row = board.getRow(2);

      expect(row.length, equals(9));
      expect(row[0].value, equals(1));
      expect(row[8].value, equals(9));
    });

    test('getRow throws on invalid row', () {
      final board = SudokuBoard();

      expect(() => board.getRow(-1), throwsArgumentError);
      expect(() => board.getRow(9), throwsArgumentError);
    });

    test('getColumn returns all cells in column', () {
      final board = SudokuBoard();
      for (int row = 0; row < 9; row++) {
        board.grid[row][3].value = row + 1;
      }

      final col = board.getColumn(3);

      expect(col.length, equals(9));
      expect(col[0].value, equals(1));
      expect(col[8].value, equals(9));
    });

    test('getColumn throws on invalid column', () {
      final board = SudokuBoard();

      expect(() => board.getColumn(-1), throwsArgumentError);
      expect(() => board.getColumn(9), throwsArgumentError);
    });

    test('getBox returns 9 cells in 3x3 box', () {
      final board = SudokuBoard();
      // Fill top-left box (rows 0-2, cols 0-2)
      int value = 1;
      for (int row = 0; row < 3; row++) {
        for (int col = 0; col < 3; col++) {
          board.grid[row][col].value = value++;
        }
      }

      final box = board.getBox(1, 1); // Center of top-left box

      expect(box.length, equals(9));
      expect(box[0].value, equals(1)); // (0,0)
      expect(box[4].value, equals(5)); // (1,1)
      expect(box[8].value, equals(9)); // (2,2)
    });

    test('getBox works for all positions in same box', () {
      final board = SudokuBoard();

      // All positions in top-left box should return same cells
      final box1 = board.getBox(0, 0);
      final box2 = board.getBox(1, 2);
      final box3 = board.getBox(2, 1);

      expect(box1.length, equals(box2.length));
      expect(box2.length, equals(box3.length));
    });

    test('getBoxByIndex returns correct box', () {
      final board = SudokuBoard();

      // Test all 9 boxes
      for (int boxIndex = 0; boxIndex < 9; boxIndex++) {
        final box = board.getBoxByIndex(boxIndex);
        expect(box.length, equals(9), reason: 'Box $boxIndex should have 9 cells');
      }

      // Box 0 = top-left, Box 8 = bottom-right
      final topLeftBox = board.getBoxByIndex(0);
      final bottomRightBox = board.getBoxByIndex(8);

      expect(topLeftBox, isNotNull);
      expect(bottomRightBox, isNotNull);
    });

    test('getBoxByIndex throws on invalid index', () {
      final board = SudokuBoard();

      expect(() => board.getBoxByIndex(-1), throwsArgumentError);
      expect(() => board.getBoxByIndex(9), throwsArgumentError);
    });

    test('isFull returns true when all cells filled', () {
      final board = SudokuBoard();
      expect(board.isFull, isFalse);

      // Fill all cells
      for (int row = 0; row < 9; row++) {
        for (int col = 0; col < 9; col++) {
          board.grid[row][col].value = 5;
        }
      }

      expect(board.isFull, isTrue);
      expect(board.hasEmptyCells, isFalse);
    });

    test('emptyCount and filledCount work correctly', () {
      final board = SudokuBoard();
      expect(board.emptyCount, equals(81));
      expect(board.filledCount, equals(0));

      // Fill some cells
      board.grid[0][0].value = 1;
      board.grid[1][1].value = 2;
      board.grid[2][2].value = 3;

      expect(board.emptyCount, equals(78));
      expect(board.filledCount, equals(3));
    });

    test('reset clears non-fixed cells only', () {
      final board = SudokuBoard();

      // Add fixed cells
      board.grid[0][0] = SudokuCell(value: 5, isFixed: true);
      board.grid[1][1] = SudokuCell(value: 7, isFixed: true);

      // Add user entries
      board.grid[2][2] = SudokuCell(value: 3, isFixed: false);
      board.grid[3][3] = SudokuCell(value: 9, isFixed: false);
      board.grid[3][3].notes.add(1);
      board.grid[3][3].isError = true;

      board.reset();

      // Fixed cells preserved
      expect(board.grid[0][0].value, equals(5));
      expect(board.grid[1][1].value, equals(7));

      // User entries cleared
      expect(board.grid[2][2].value, isNull);
      expect(board.grid[3][3].value, isNull);
      expect(board.grid[3][3].notes, isEmpty);
      expect(board.grid[3][3].isError, isFalse);
    });

    test('clearErrors removes all error flags', () {
      final board = SudokuBoard();

      // Set some errors
      board.grid[0][0].isError = true;
      board.grid[5][5].isError = true;
      board.grid[8][8].isError = true;

      board.clearErrors();

      // All errors cleared
      for (int row = 0; row < 9; row++) {
        for (int col = 0; col < 9; col++) {
          expect(board.grid[row][col].isError, isFalse);
        }
      }
    });

    test('clone creates independent copy', () {
      final original = SudokuBoard();
      original.grid[0][0].value = 5;
      original.grid[1][1].notes.add(3);

      final copy = original.clone();

      // Verify copy matches
      expect(copy.grid[0][0].value, equals(5));
      expect(copy.grid[1][1].notes, contains(3));

      // Modify original
      original.grid[0][0].value = 9;
      original.grid[1][1].notes.add(7);

      // Copy should be unchanged
      expect(copy.grid[0][0].value, equals(5));
      expect(copy.grid[1][1].notes, equals({3}));
    });

    test('toValues converts board to 2D array', () {
      final board = SudokuBoard();
      board.grid[0][0].value = 5;
      board.grid[1][1].value = 3;
      board.grid[2][2].value = 7;

      final values = board.toValues();

      expect(values.length, equals(9));
      expect(values[0].length, equals(9));
      expect(values[0][0], equals(5));
      expect(values[1][1], equals(3));
      expect(values[2][2], equals(7));
      expect(values[0][1], equals(0)); // Empty cells = 0
    });

    test('toString produces readable output', () {
      final board = SudokuBoard();
      board.grid[0][0].value = 5;
      board.grid[4][4].value = 9;

      final str = board.toString();

      expect(str, contains('5'));
      expect(str, contains('9'));
      expect(str, contains('.')); // Empty cells
      expect(str, contains('|')); // Box separators
      expect(str, contains('-')); // Row separators
    });

    test('round-trip conversion preserves board state', () {
      final original = SudokuBoard();
      original.grid[0][0].value = 1;
      original.grid[4][4].value = 5;
      original.grid[8][8].value = 9;

      final values = original.toValues();
      final restored = SudokuBoard.fromValues(values);

      expect(restored.getCell(0, 0).value, equals(1));
      expect(restored.getCell(4, 4).value, equals(5));
      expect(restored.getCell(8, 8).value, equals(9));
    });
  });
}
