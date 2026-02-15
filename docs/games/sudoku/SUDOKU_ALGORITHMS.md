# Sudoku Algorithms Guide

**Related Files**:
- [lib/games/sudoku/logic/sudoku_generator.dart](../lib/games/sudoku/logic/sudoku_generator.dart)
- [lib/games/sudoku/logic/sudoku_solver.dart](../lib/games/sudoku/logic/sudoku_solver.dart)
- [lib/games/sudoku/logic/sudoku_validator.dart](../lib/games/sudoku/logic/sudoku_validator.dart)

**See Also**:
- [SUDOKU_ARCHITECTURE.md](SUDOKU_ARCHITECTURE.md)
- [SUDOKU_SERVICES.md](SUDOKU_SERVICES.md)
- [ARCHITECTURE.md](ARCHITECTURE.md)

## Table of Contents
1. [Overview](#overview)
2. [Puzzle Generation](#puzzle-generation)
3. [Solving Algorithm](#solving-algorithm)
4. [Validation System](#validation-system)

## Overview

The Sudoku game implements three core algorithms as pure functions with no external dependencies:

- **Generator**: Creates valid puzzles with unique solutions
- **Solver**: Uses backtracking to solve puzzles and provide hints
- **Validator**: Detects conflicts and verifies solutions

All algorithms work with the SudokuBoard and SudokuCell models.

## Puzzle Generation

### SudokuGenerator Class

**File**: `lib/games/sudoku/logic/sudoku_generator.dart`

**Purpose**: Generates valid Sudoku puzzles with guaranteed unique solutions.

The generator creates playable Sudoku puzzles by:
1. Generating a complete valid board
2. Strategically removing cells based on difficulty
3. Ensuring each puzzle has exactly one solution

The generator uses randomization to create different puzzles each time, providing variety for players.

### Difficulty Levels

Each difficulty determines how many cells to remove from a complete board, affecting puzzle complexity.

| Difficulty | Clues (Filled Cells)| Cells Removed| Description                               |
|------------|---------------------|--------------|-------------------------------------------|
| Easy       | 36-40 clues         | 41-45 cells  | Good for beginners, straightforward logic |
| Medium     | 32-35 clues         | 46-49 cells  | Requires basic Sudoku strategies          |
| Hard       | 28-31 clues         | 50-53 cells  | Requires advanced techniques              |
| Expert     | 24-27 clues         | 54-57 cells  | Very challenging, minimal clues           |

### Complete Board Generation

**Method**: `_generateCompleteBoard()`

**Strategy**: Diagonal Box Filling + Backtracking Solver

#### Algorithm Steps:

**Step 1: Fill Diagonal 3×3 Boxes**

The board is divided into nine 3×3 boxes:
```
Box 0 | Box 1 | Box 2
------+-------+------
Box 3 | Box 4 | Box 5
------+-------+------
Box 6 | Box 7 | Box 8
```

Diagonal boxes (0, 4, 8) at positions (0,0), (3,3), and (6,6) don't share rows or columns with each other, allowing independent filling.

**Process**:
1. Fill box at (0, 0) - Top-left
2. Fill box at (3, 3) - Center
3. Fill box at (6, 6) - Bottom-right

Each box is filled with a shuffled list of numbers 1-9, guaranteeing no conflicts within the box.

**Step 2: Solve Remaining Cells**

The solver (see [Solving Algorithm](#solving-algorithm)) fills the remaining cells using backtracking.

#### Why This Approach?

- **Randomized Foundation**: Diagonal boxes provide variety across generated puzzles
- **Deterministic Completion**: Solver completes the puzzle efficiently
- **Performance**: Much faster than pure random trial-and-error

### Cell Removal Strategy

**Method**: `_removeClues(completeBoard, difficulty)`

Uses a strategic removal approach to create the puzzle:

#### Algorithm Steps:

1. **Determine Target**: Calculate target number of clues based on difficulty
2. **Create Position List**: Generate list of all 81 cell positions
3. **Shuffle Positions**: Randomize order for unbiased removal
4. **Strategic Removal Loop**:
   - For each position:
     - Temporarily remove the cell value
     - Check if puzzle still has unique solution (expensive check!)
     - If yes: keep it removed
     - If no: restore the cell (removing would create multiple solutions)
   - Continue until target number of clues reached

5. **Mark Fixed Cells**: All remaining filled cells become fixed (part of puzzle, cannot be edited)

#### Why Check for Unique Solution?

Valid Sudoku puzzles must have **exactly one solution**:
- **Zero solutions** = Unsolvable puzzle (frustrating for players)
- **Multiple solutions** = Ambiguous puzzle (not a valid Sudoku)
- **One solution** = Valid, challenging puzzle

This check is computationally expensive (must find all solutions up to 2), which is why Expert difficulty puzzles take longer to generate.

### Generator Constructor

**Optional Seed Parameter**: If seed is provided, the generator produces deterministic puzzles (useful for testing).

Example:
```dart
final generator = SudokuGenerator(seed: 12345);
final puzzle = generator.generate(SudokuDifficulty.medium);
```

### Batch Generation

**Method**: `generateBatch(difficulty, count)`

Generates multiple puzzles at once (useful for pre-generation).

Example:
```dart
final generator = SudokuGenerator();
final puzzles = generator.generateBatch(
  difficulty: SudokuDifficulty.medium,
  count: 10,
);
```

---

## Solving Algorithm

### SudokuSolver Class

**File**: `lib/games/sudoku/logic/sudoku_solver.dart`

**Purpose**: Solves Sudoku puzzles using backtracking algorithm.

This class implements a recursive backtracking solver that:
1. Finds an empty cell
2. Tries values 1-9 in that cell
3. Checks if the value is valid (no conflicts)
4. Recursively solves the rest of the board
5. Backtracks if stuck (no valid value works)

**Used by**:
- Solution validation: verify puzzle has a unique solution
- Hint system: find correct values for empty cells
- Puzzle generator: check if generated puzzles are solvable

### Core Solving Method

**Method**: `solve(board)`

Modifies the board in-place by filling empty cells.

**Returns**: `true` if a solution was found, `false` if unsolvable.

#### Algorithm (Recursive Backtracking):

1. **Find Empty Cell**: Scan board left-to-right, top-to-bottom for first empty cell
2. **Base Case**: If no empty cells found, board is solved → return `true`
3. **Try Values 1-9**:
   - For each value:
     - Check if value can be placed without conflicts (using validator)
     - If valid:
       - Place the value
       - Recursively solve the rest of the board
       - If recursive call succeeds → return `true` (solution found!)
       - Otherwise, **backtrack**: remove the value and try next number
4. **No Valid Value**: If all values 1-9 fail → return `false` (trigger backtracking)

#### Example:
```dart
final board = SudokuBoard.fromValues(puzzleData);
if (SudokuSolver.solve(board)) {
  print('Solved!');
} else {
  print('No solution exists');
}
```

### Non-Destructive Solving

**Method**: `getSolution(board)`

Solves the board and returns a solved copy without modifying the original.

**Returns**: Solved board or `null` if unsolvable.

Example:
```dart
final original = SudokuBoard.fromValues(puzzleData);
final solved = SudokuSolver.getSolution(original);
if (solved != null) {
  // Original board unchanged, use solved board
}
```

### Unique Solution Check

**Method**: `hasUniqueSolution(board)`

Checks if the board has a unique solution.

This is critical for puzzle generation - valid Sudoku puzzles must have **exactly one solution** (not zero, not multiple).

**Returns**: `true` only if exactly one solution exists.

**Note**: This is computationally expensive as it needs to find all solutions. Uses `_countSolutions()` with early termination after finding 2 solutions. Use sparingly.

### Hint System

**Method**: `getHint(board, row, col)`

Finds a valid value for a specific cell.

Used by the hint system to help players.

**Returns**: The correct value (1-9) or `null` if:
- Cell is already filled
- Board is unsolvable

**Process**:
1. Check if cell is already filled → return `null`
2. Solve a copy of the board to find the correct value
3. Return the value at the specified position from solved board

Example:
```dart
final hint = SudokuSolver.getHint(board, row, col);
if (hint != null) {
  board.getCell(row, col).value = hint;
}
```

### Solution Counting

**Method**: `_countSolutions(board, count, maxCount)`

Counts the number of solutions for a board, up to a maximum.

Used by `hasUniqueSolution()` to determine if exactly one solution exists.

Stops counting after finding `maxCount` solutions for efficiency.

**Returns**:
- 0 if no solutions exist
- 1 if exactly one solution exists
- 2+ if multiple solutions exist (ambiguous puzzle)

**Early Exit Optimization**: Stops as soon as `maxCount` solutions are found (typically maxCount=2), avoiding unnecessary computation.

### Solvability Check

**Method**: `isSolvable(board)`

Checks if a board is solvable (has at least one solution).

This is faster than `hasUniqueSolution()` since it stops after finding the first solution.

### Possible Values Analysis

**Method**: `getPossibleValues(board, row, col)`

Gets all possible valid values for a specific cell.

**Returns**: A Set of integers (1-9) that can be legally placed in the given cell without creating conflicts.

**Use Cases**:
- Auto-filling notes/pencil marks
- Advanced hint systems
- Puzzle difficulty analysis

**Note**: Returns empty set if cell is already filled.

---

## Validation System

### SudokuValidator Class

**File**: `lib/games/sudoku/logic/sudoku_validator.dart`

**Purpose**: Validates Sudoku board for conflicts and rule violations.

This class provides pure validation functions that detect:
- Duplicate values in rows
- Duplicate values in columns
- Duplicate values in 3×3 boxes

**Used by**:
- Classic Mode: real-time error highlighting
- Rush Mode: penalty detection
- Solver: solution verification

### Board Validation

**Method**: `isValidBoard(board)`

Checks if the entire board is valid (no conflicts).

**Returns**: `true` if:
- All rows have no duplicate non-empty values
- All columns have no duplicate non-empty values
- All 3×3 boxes have no duplicate non-empty values

**Implementation**: Uses `getConflictPositions()` and returns `true` if no conflicts found.

### Solution Verification

**Method**: `isSolved(board)`

Checks if the board is completely solved correctly.

**Returns**: `true` only if:
- Board is full (all cells filled)
- Board is valid (no conflicts)

### Conflict Detection

**Method**: `getConflictPositions(board)`

Finds all cells that have conflicts with other cells.

**Returns**: A Set of `Position` objects for cells that violate Sudoku rules.

**Note**: Empty cells are never included in conflict detection.

#### Algorithm:

1. Check all 9 rows for duplicates → collect conflict positions
2. Check all 9 columns for duplicates → collect conflict positions
3. Check all 9 boxes for duplicates → collect conflict positions
4. Return union of all conflict positions

### Value Placement Check

**Method**: `canPlaceValue(board, row, col, value)`

Checks if a specific value can be placed at a position without conflicts.

**Returns**: `true` if placing `value` at `[row, col]` would not create any conflicts with existing values in the same row, column, or box.

**Parameters**:
- `board`: The current board state
- `row`, `col`: Target position (0-8)
- `value`: The value to test (1-9)

**Used by**:
- Solver: to determine valid moves during backtracking
- Hint system: to validate suggested values

#### Algorithm:

1. **Value Range Check**: Return `false` if value not in range 1-9
2. **Check Row**: Scan row for duplicate value (excluding target cell)
   - If found → return `false` (conflict in row)
3. **Check Column**: Scan column for duplicate value (excluding target cell)
   - If found → return `false` (conflict in column)
4. **Check 3×3 Box**:
   - Calculate box start position: `(row // 3) * 3`, `(col // 3) * 3`
   - Scan all 9 cells in box for duplicate (excluding target cell)
   - If found → return `false` (conflict in box)
5. **No Conflicts**: Return `true`

### Conflict Detection Internals

#### Row Conflict Detection

**Method**: `_findRowConflicts(board, row)`

Finds duplicate values in a specific row.

**Returns**: Positions of ALL cells involved in conflicts. Empty cells are ignored.

**Algorithm**:
- Use a map to track first occurrence of each value
- When duplicate found, mark both positions as conflicts

#### Column Conflict Detection

**Method**: `_findColumnConflicts(board, col)`

Finds duplicate values in a specific column.

Same algorithm as row conflicts, but scans vertically.

#### Box Conflict Detection

**Method**: `_findBoxConflicts(board, boxIndex)`

Finds duplicate values in a specific 3×3 box.

**Box Index**: 0-8 (see box numbering diagram in [Puzzle Generation](#puzzle-generation))

**Algorithm**:
- Calculate box starting position from box index
- Scan all 9 cells in the box
- Track and report duplicate positions

### Position Class

**File**: `lib/games/sudoku/logic/sudoku_validator.dart`

Simple helper class to store row/col position on the board.

**Properties**:
- `row`: 0-8
- `col`: 0-8

Implements equality and hashCode for use in Sets.

---

## Performance Considerations

### Generator Performance

- **Easy/Medium**: Fast generation (< 1 second)
- **Hard**: Moderate generation time (1-3 seconds)
- **Expert**: Can take several seconds due to uniqueness checks

**Optimization**: Diagonal box filling reduces search space significantly.

### Solver Performance

- **Best Case**: O(1) if board is already solved
- **Worst Case**: O(9^n) where n is number of empty cells
- **Typical**: Very fast for puzzles with 30+ clues

**Backtracking** is efficient because it prunes invalid branches early.

### Validator Performance

- **Board Validation**: O(81) - scans all cells once
- **Conflict Detection**: O(243) - checks 9 rows + 9 columns + 9 boxes
- **Value Placement Check**: O(27) - checks 1 row + 1 column + 1 box

All validation operations are very fast (< 1ms).

---

## Testing Strategy

All algorithm classes are pure functions with no dependencies, making them highly testable:

1. **Generator Tests**:
   - Generated boards are valid and full
   - Puzzles have unique solutions
   - Difficulty levels produce correct clue counts
   - Deterministic generation with seeds

2. **Solver Tests**:
   - Solves known puzzles correctly
   - Detects unsolvable puzzles
   - Unique solution detection works
   - Hint system provides correct values

3. **Validator Tests**:
   - Detects row/column/box conflicts
   - Correctly identifies valid boards
   - Solution verification works
   - canPlaceValue returns correct results

**See**: `test/games/sudoku/logic/` for complete test suite
