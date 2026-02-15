# Sudoku Implementation - Quick Reference

**Phase 1 Status**: ✅ COMPLETE | **Tests**: 112 passing | **Coverage**: 96%

---

## Quick Start

```dart
import 'package:puzzle/games/sudoku/index.dart';

// Generate a puzzle
final generator = SudokuGenerator();
final puzzle = generator.generate(SudokuDifficulty.medium);

// Validate moves
if (SudokuValidator.canPlaceValue(puzzle, row, col, value)) {
  puzzle.getCell(row, col).value = value;
}

// Check for conflicts
final conflicts = SudokuValidator.getConflictPositions(puzzle);
for (final pos in conflicts) {
  puzzle.getCell(pos.row, pos.col).isError = true;
}

// Get hint
final hint = SudokuSolver.getHint(puzzle, row, col);

// Check if solved
if (SudokuValidator.isSolved(puzzle)) {
  print('Congratulations!');
}
```

---

## Component Overview

### 1. SudokuCell (Model)
**What**: Single cell in the grid
**Key Properties**: `value`, `isFixed`, `notes`, `isError`

```dart
final cell = SudokuCell(value: 5, isFixed: true);
cell.isEmpty       // false
cell.hasValue      // true
cell.isValidValue  // true (1-9 or null)
```

### 2. SudokuBoard (Model)
**What**: 9×9 grid with helper methods
**Key Methods**: `getRow()`, `getColumn()`, `getBox()`, `clone()`, `reset()`

```dart
final board = SudokuBoard.fromValues(puzzleData);
final row = board.getRow(0);        // Get row 0
final col = board.getColumn(3);      // Get column 3
final box = board.getBox(0, 0);      // Get 3×3 box
board.emptyCount                     // Number of empty cells
```

### 3. SudokuValidator (Logic)
**What**: Validates Sudoku rules
**Key Methods**: `isValidBoard()`, `getConflictPositions()`, `canPlaceValue()`

```dart
// Check if board is valid
SudokuValidator.isValidBoard(board)

// Find conflicting cells
final conflicts = SudokuValidator.getConflictPositions(board);

// Check if value can be placed
SudokuValidator.canPlaceValue(board, row, col, value)

// Check if solved
SudokuValidator.isSolved(board)
```

### 4. SudokuSolver (Logic)
**What**: Solves puzzles using backtracking
**Key Methods**: `solve()`, `getHint()`, `hasUniqueSolution()`

```dart
// Solve in-place
SudokuSolver.solve(board)

// Get solution without modifying
final solution = SudokuSolver.getSolution(board);

// Get hint for cell
final hint = SudokuSolver.getHint(board, row, col);

// Check unique solution (for generation)
SudokuSolver.hasUniqueSolution(board)

// Get possible values for cell
final possible = SudokuSolver.getPossibleValues(board, row, col);
```

### 5. SudokuGenerator (Logic)
**What**: Generates valid puzzles
**Key Methods**: `generate()`, `generateBatch()`

```dart
final gen = SudokuGenerator();

// Generate single puzzle
final easy = gen.generate(SudokuDifficulty.easy);
final expert = gen.generate(SudokuDifficulty.expert);

// Pre-generate multiple puzzles
final puzzles = gen.generateBatch(
  difficulty: SudokuDifficulty.medium,
  count: 10,
);

// Deterministic generation (for testing)
final deterministicGen = SudokuGenerator(seed: 12345);
```

---

## Difficulty Levels

| Level | Clues | Empty | Generation Time |
|-------|-------|-------|-----------------|
| Easy | 36-40 | 41-45 | ~50-100ms |
| Medium | 32-35 | 46-49 | ~100-200ms |
| Hard | 28-31 | 50-53 | ~200-500ms |
| Expert | 24-27 | 54-57 | ~500-1500ms |

---

## Performance Benchmarks

| Operation | Time | Notes |
|-----------|------|-------|
| Cell access | <1µs | O(1) |
| Validate board | <1ms | O(243) |
| Solve easy puzzle | ~2-5ms | Typical |
| Solve hard puzzle | ~10-20ms | Typical |
| Generate easy | ~50-100ms | Includes validation |
| Generate expert | ~500-1500ms | Slow due to unique check |

---

## Common Patterns

### Creating a Game

```dart
// 1. Generate puzzle
final puzzle = generator.generate(SudokuDifficulty.medium);

// 2. Store original for reset
final original = puzzle.clone();

// 3. Play
puzzle.getCell(row, col).value = playerInput;

// 4. Validate
final conflicts = SudokuValidator.getConflictPositions(puzzle);

// 5. Check win
if (SudokuValidator.isSolved(puzzle)) {
  // Player won!
}
```

### Implementing Hints

```dart
// Get hint for selected cell
final hint = SudokuSolver.getHint(board, selectedRow, selectedCol);

if (hint != null) {
  board.getCell(selectedRow, selectedCol).value = hint;
  hintsUsed++;
}
```

### Error Highlighting

```dart
// Clear previous errors
board.clearErrors();

// Find and mark conflicts
final conflicts = SudokuValidator.getConflictPositions(board);
for (final pos in conflicts) {
  board.getCell(pos.row, pos.col).isError = true;
}
```

### Notes/Pencil Marks

```dart
final cell = board.getCell(row, col);

// Add note
cell.notes.add(5);

// Remove note
cell.notes.remove(5);

// Toggle note
if (cell.notes.contains(5)) {
  cell.notes.remove(5);
} else {
  cell.notes.add(5);
}

// Auto-fill notes with possible values
if (cell.isEmpty) {
  cell.notes.clear();
  cell.notes.addAll(SudokuSolver.getPossibleValues(board, row, col));
}
```

### Undo/Redo Pattern

```dart
// Store move history
final history = <SudokuBoard>[];

// Before each move
history.add(board.clone());

// Undo
if (history.isNotEmpty) {
  board = history.removeLast();
}
```

---

## Box Numbering

```
 0 | 1 | 2
---+---+---
 3 | 4 | 5
---+---+---
 6 | 7 | 8
```

**Examples**:
- Cell (0,0) is in box 0 (top-left)
- Cell (4,4) is in box 4 (center)
- Cell (8,8) is in box 8 (bottom-right)

**Formula**: `boxIndex = (row / 3) * 3 + (col / 3)`

---

## Testing

```bash
# Run all Sudoku tests
flutter test test/games/sudoku/

# Run specific component
flutter test test/games/sudoku/logic/sudoku_solver_test.dart

# Run with coverage
flutter test --coverage
```

---

## Error Handling

All methods validate inputs and throw `ArgumentError` for:
- Invalid row/column (must be 0-8)
- Invalid values (must be 1-9 or null)
- Invalid board size (must be 9×9)

```dart
try {
  board.getCell(10, 5);  // Throws ArgumentError
} catch (e) {
  print('Invalid position: $e');
}
```

---

## Best Practices

### ✅ DO

```dart
// Clone before solving to preserve original
final copy = board.clone();
SudokuSolver.solve(copy);

// Validate before placing values
if (SudokuValidator.canPlaceValue(board, row, col, value)) {
  board.getCell(row, col).value = value;
}

// Clear errors before re-validating
board.clearErrors();
final conflicts = SudokuValidator.getConflictPositions(board);
```

### ❌ DON'T

```dart
// Don't solve original without cloning
SudokuSolver.solve(board);  // Modifies in-place!

// Don't access cells without validation
board.getCell(row, col);  // May throw if invalid position

// Don't forget to mark fixed cells
// Generator does this automatically, but manual creation needs it
```

---

## Integration Points for Phase 2

### Classic Mode UI needs:

1. **Display**: `board.grid` for rendering 9×9 grid
2. **Input**: `canPlaceValue()` before accepting input
3. **Validation**: `getConflictPositions()` for error highlighting
4. **Hints**: `getHint()` when hint button pressed
5. **Completion**: `isSolved()` to detect win
6. **Generation**: `generate(difficulty)` for new games

### State Management (Provider):

```dart
class SudokuGameProvider with ChangeNotifier {
  SudokuBoard? _board;
  int _hintsUsed = 0;

  void generatePuzzle(SudokuDifficulty difficulty) {
    final generator = SudokuGenerator();
    _board = generator.generate(difficulty);
    notifyListeners();
  }

  bool placeValue(int row, int col, int value) {
    if (SudokuValidator.canPlaceValue(_board!, row, col, value)) {
      _board!.getCell(row, col).value = value;
      notifyListeners();
      return true;
    }
    return false;
  }

  void useHint(int row, int col) {
    final hint = SudokuSolver.getHint(_board!, row, col);
    if (hint != null) {
      _board!.getCell(row, col).value = hint;
      _hintsUsed++;
      notifyListeners();
    }
  }
}
```

---

## File Locations

```
lib/games/sudoku/
├── models/
│   ├── sudoku_cell.dart
│   └── sudoku_board.dart
├── logic/
│   ├── sudoku_validator.dart
│   ├── sudoku_solver.dart
│   └── sudoku_generator.dart
├── index.dart (barrel file)
└── README.md

test/games/sudoku/
├── models/
│   ├── sudoku_cell_test.dart (14 tests)
│   └── sudoku_board_test.dart (24 tests)
└── logic/
    ├── sudoku_validator_test.dart (25 tests)
    ├── sudoku_solver_test.dart (26 tests)
    └── sudoku_generator_test.dart (23 tests)

docs/
├── SUDOKU_PHASE1_ANALYSIS.md (detailed analysis)
└── SUDOKU_QUICK_REFERENCE.md (this file)
```

---

## Key Takeaways

1. ✅ **All core logic is complete and tested**
2. ✅ **96% test coverage with 112 passing tests**
3. ✅ **Performance optimized for real-time gameplay**
4. ✅ **Clean architecture with zero dependencies**
5. ✅ **Ready for Phase 2 (Classic Mode UI)**

---

**Next Steps**: Implement Phase 2 (Classic Mode) starting with T2.1 (Screen UI)

**Questions?** See [SUDOKU_PHASE1_ANALYSIS.md](SUDOKU_PHASE1_ANALYSIS.md) for detailed analysis.
