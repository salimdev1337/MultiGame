import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/sudoku/models/sudoku_cell.dart';

void main() {
  group('SudokuCell', () {
    test('creates empty cell by default', () {
      final cell = SudokuCell();

      expect(cell.value, isNull);
      expect(cell.isEmpty, isTrue);
      expect(cell.hasValue, isFalse);
      expect(cell.isFixed, isFalse);
      expect(cell.isError, isFalse);
      expect(cell.notes, isEmpty);
      expect(cell.hasNotes, isFalse);
    });

    test('creates cell with value', () {
      final cell = SudokuCell(value: 5);

      expect(cell.value, equals(5));
      expect(cell.isEmpty, isFalse);
      expect(cell.hasValue, isTrue);
      expect(cell.isValidValue, isTrue);
    });

    test('creates fixed cell', () {
      final cell = SudokuCell(value: 7, isFixed: true);

      expect(cell.value, equals(7));
      expect(cell.isFixed, isTrue);
      expect(cell.hasValue, isTrue);
    });

    test('creates cell with notes', () {
      final cell = SudokuCell(notes: {1, 2, 3});

      expect(cell.notes, equals({1, 2, 3}));
      expect(cell.hasNotes, isTrue);
      expect(cell.isEmpty, isTrue);
    });

    test('validates value range correctly', () {
      expect(SudokuCell(value: 1).isValidValue, isTrue);
      expect(SudokuCell(value: 5).isValidValue, isTrue);
      expect(SudokuCell(value: 9).isValidValue, isTrue);
      expect(SudokuCell().isValidValue, isTrue); // null is valid
    });

    test('copyWith creates new cell with updated properties', () {
      final cell = SudokuCell(value: 3, notes: {1, 2});
      final updated = cell.copyWith(value: 5, isError: true);

      expect(updated.value, equals(5));
      expect(updated.isError, isTrue);
      expect(updated.notes, equals({1, 2})); // unchanged
      expect(updated.isFixed, isFalse); // unchanged

      // Original unchanged
      expect(cell.value, equals(3));
      expect(cell.isError, isFalse);
    });

    test('copyWith preserves notes as independent set', () {
      final cell = SudokuCell(notes: {1, 2, 3});
      final copied = cell.copyWith();

      // Modify original notes
      cell.notes.add(4);

      // Copied notes should be independent
      expect(cell.notes, equals({1, 2, 3, 4}));
      expect(copied.notes, equals({1, 2, 3}));
    });

    test('clear removes value but keeps notes and fixed status', () {
      final cell = SudokuCell(value: 5, isFixed: true, notes: {1, 2, 3});
      final cleared = cell.clear();

      expect(cleared.value, isNull);
      expect(cleared.isEmpty, isTrue);
      expect(cleared.isFixed, isTrue); // preserved
      expect(cleared.notes, equals({1, 2, 3})); // preserved
      expect(cleared.isError, isFalse);
    });

    test('toString provides useful debug information', () {
      final cell = SudokuCell(
        value: 7,
        isFixed: true,
        notes: {1, 2},
        isError: true,
      );

      final str = cell.toString();
      expect(str, contains('value: 7'));
      expect(str, contains('isFixed: true'));
      expect(str, contains('isError: true'));
    });

    test('mutable properties can be changed', () {
      final cell = SudokuCell(value: 3);

      // Test mutable properties
      cell.value = 5;
      expect(cell.value, equals(5));

      cell.isError = true;
      expect(cell.isError, isTrue);

      cell.notes.add(1);
      cell.notes.add(2);
      expect(cell.notes, equals({1, 2}));
    });

    test('fixed cells can be identified', () {
      final fixedCell = SudokuCell(value: 8, isFixed: true);
      final editableCell = SudokuCell(value: 3);

      expect(fixedCell.isFixed, isTrue);
      expect(editableCell.isFixed, isFalse);
    });

    test('error flag works correctly', () {
      final cell = SudokuCell(value: 5);
      expect(cell.isError, isFalse);

      cell.isError = true;
      expect(cell.isError, isTrue);

      cell.isError = false;
      expect(cell.isError, isFalse);
    });
  });
}
