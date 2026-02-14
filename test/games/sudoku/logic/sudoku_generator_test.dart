import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/sudoku/logic/sudoku_generator.dart';
import 'package:multigame/games/sudoku/logic/sudoku_solver.dart';
import 'package:multigame/games/sudoku/logic/sudoku_validator.dart';

void main() {
  group('SudokuGenerator', () {
    late SudokuGenerator generator;

    setUp(() {
      // Use a fixed seed for reproducible tests
      generator = SudokuGenerator(seed: 12345);
    });

    group('generate()', () {
      test('should generate valid easy puzzle', () {
        // Act
        final puzzle = generator.generate(SudokuDifficulty.easy);

        // Assert
        expect(puzzle, isNotNull);
        expect(
          SudokuValidator.isValidBoard(puzzle),
          isTrue,
          reason: 'Generated puzzle should have no conflicts',
        );
        expect(
          puzzle.hasEmptyCells,
          isTrue,
          reason: 'Puzzle should have empty cells to solve',
        );
        expect(
          puzzle.filledCount,
          greaterThan(0),
          reason: 'Puzzle should have clues',
        );
      });

      test('should generate valid medium puzzle', () {
        // Act
        final puzzle = generator.generate(SudokuDifficulty.medium);

        // Assert
        expect(puzzle, isNotNull);
        expect(SudokuValidator.isValidBoard(puzzle), isTrue);
        expect(puzzle.hasEmptyCells, isTrue);
        expect(puzzle.filledCount, greaterThan(0));
      });

      test('should generate valid hard puzzle', () {
        // Act
        final puzzle = generator.generate(SudokuDifficulty.hard);

        // Assert
        expect(puzzle, isNotNull);
        expect(SudokuValidator.isValidBoard(puzzle), isTrue);
        expect(puzzle.hasEmptyCells, isTrue);
        expect(puzzle.filledCount, greaterThan(0));
      });

      test('should generate valid expert puzzle', () {
        // Act
        final puzzle = generator.generate(SudokuDifficulty.expert);

        // Assert
        expect(puzzle, isNotNull);
        expect(SudokuValidator.isValidBoard(puzzle), isTrue);
        expect(puzzle.hasEmptyCells, isTrue);
        expect(puzzle.filledCount, greaterThan(0));
      });

      test('should generate solvable puzzle', () {
        // Act
        final puzzle = generator.generate(SudokuDifficulty.medium);

        // Assert
        expect(
          SudokuSolver.isSolvable(puzzle),
          isTrue,
          reason: 'Generated puzzle must be solvable',
        );
      });

      test(
        'should generate puzzle with unique solution',
        () {
          // Act
          final puzzle = generator.generate(SudokuDifficulty.medium);

          // Assert
          expect(
            SudokuSolver.hasUniqueSolution(puzzle),
            isTrue,
            reason: 'Generated puzzle must have exactly one solution',
          );
        },
        timeout: const Timeout(Duration(seconds: 10)),
      );

      test('should mark filled cells as fixed', () {
        // Act
        final puzzle = generator.generate(SudokuDifficulty.medium);

        // Assert
        for (int row = 0; row < 9; row++) {
          for (int col = 0; col < 9; col++) {
            final cell = puzzle.getCell(row, col);
            if (cell.hasValue) {
              expect(
                cell.isFixed,
                isTrue,
                reason: 'All clue cells should be marked as fixed',
              );
            } else {
              expect(
                cell.isFixed,
                isFalse,
                reason: 'Empty cells should not be fixed',
              );
            }
          }
        }
      });

      test('should generate different puzzles each time', () {
        // Arrange: Use random generator (no seed)
        final randomGenerator = SudokuGenerator();

        // Act: Generate two puzzles
        final puzzle1 = randomGenerator.generate(SudokuDifficulty.medium);
        final puzzle2 = randomGenerator.generate(SudokuDifficulty.medium);

        // Assert: Puzzles should be different
        final values1 = puzzle1.toValues();
        final values2 = puzzle2.toValues();

        bool isDifferent = false;
        for (int row = 0; row < 9; row++) {
          for (int col = 0; col < 9; col++) {
            if (values1[row][col] != values2[row][col]) {
              isDifferent = true;
              break;
            }
          }
          if (isDifferent) break;
        }

        expect(
          isDifferent,
          isTrue,
          reason: 'Generated puzzles should be different',
        );
      });
    });

    group('difficulty levels', () {
      test('easy puzzle should have 36-40 clues', () {
        // Act
        final puzzle = generator.generate(SudokuDifficulty.easy);

        // Assert
        expect(
          puzzle.filledCount,
          greaterThanOrEqualTo(36),
          reason: 'Easy puzzle should have at least 36 clues',
        );
        expect(
          puzzle.filledCount,
          lessThanOrEqualTo(40),
          reason: 'Easy puzzle should have at most 40 clues',
        );
      });

      test('medium puzzle should have 32-35 clues', () {
        // Act
        final puzzle = generator.generate(SudokuDifficulty.medium);

        // Assert
        expect(
          puzzle.filledCount,
          greaterThanOrEqualTo(32),
          reason: 'Medium puzzle should have at least 32 clues',
        );
        expect(
          puzzle.filledCount,
          lessThanOrEqualTo(35),
          reason: 'Medium puzzle should have at most 35 clues',
        );
      });

      test('hard puzzle should have 28-31 clues', () {
        // Act
        final puzzle = generator.generate(SudokuDifficulty.hard);

        // Assert
        expect(
          puzzle.filledCount,
          greaterThanOrEqualTo(28),
          reason: 'Hard puzzle should have at least 28 clues',
        );
        expect(
          puzzle.filledCount,
          lessThanOrEqualTo(31),
          reason: 'Hard puzzle should have at most 31 clues',
        );
      });

      test('expert puzzle should have 24-27 clues', () {
        // Act
        final puzzle = generator.generate(SudokuDifficulty.expert);

        // Assert
        expect(
          puzzle.filledCount,
          greaterThanOrEqualTo(24),
          reason: 'Expert puzzle should have at least 24 clues',
        );
        expect(
          puzzle.filledCount,
          lessThanOrEqualTo(27),
          reason: 'Expert puzzle should have at most 27 clues',
        );
      });

      test('easy puzzle should have more clues than expert', () {
        // Act
        final easyPuzzle = generator.generate(SudokuDifficulty.easy);
        final expertPuzzle = generator.generate(SudokuDifficulty.expert);

        // Assert
        expect(
          easyPuzzle.filledCount,
          greaterThan(expertPuzzle.filledCount),
          reason: 'Easy puzzles should have more clues than expert',
        );
      });
    });

    group('generateBatch()', () {
      test('should generate multiple puzzles', () {
        // Act
        final puzzles = generator.generateBatch(
          difficulty: SudokuDifficulty.medium,
          count: 3,
        );

        // Assert
        expect(
          puzzles.length,
          equals(3),
          reason: 'Should generate requested number of puzzles',
        );

        // Verify all puzzles are valid
        for (final puzzle in puzzles) {
          expect(SudokuValidator.isValidBoard(puzzle), isTrue);
          expect(SudokuSolver.isSolvable(puzzle), isTrue);
        }
      });

      test('should generate puzzles of correct difficulty', () {
        // Act
        final puzzles = generator.generateBatch(
          difficulty: SudokuDifficulty.hard,
          count: 2,
        );

        // Assert
        for (final puzzle in puzzles) {
          expect(puzzle.filledCount, greaterThanOrEqualTo(28));
          expect(puzzle.filledCount, lessThanOrEqualTo(31));
        }
      });
    });

    group('deterministic generation', () {
      test('should generate same puzzle with same seed', () {
        // Arrange: Two generators with same seed
        final gen1 = SudokuGenerator(seed: 99999);
        final gen2 = SudokuGenerator(seed: 99999);

        // Act: Generate puzzles
        final puzzle1 = gen1.generate(SudokuDifficulty.medium);
        final puzzle2 = gen2.generate(SudokuDifficulty.medium);

        // Assert: Puzzles should be identical
        final values1 = puzzle1.toValues();
        final values2 = puzzle2.toValues();

        bool isIdentical = true;
        for (int row = 0; row < 9; row++) {
          for (int col = 0; col < 9; col++) {
            if (values1[row][col] != values2[row][col]) {
              isIdentical = false;
              break;
            }
          }
          if (!isIdentical) break;
        }

        expect(
          isIdentical,
          isTrue,
          reason: 'Same seed should produce identical puzzles',
        );
      });
    });

    group('puzzle quality', () {
      test('generated puzzle should be solvable by solver', () {
        // Act
        final puzzle = generator.generate(SudokuDifficulty.medium);
        final puzzleCopy = puzzle.clone();

        // Assert: Solver should be able to solve it
        final solved = SudokuSolver.solve(puzzleCopy);
        expect(solved, isTrue);
        expect(SudokuValidator.isSolved(puzzleCopy), isTrue);
      });

      test('solved puzzle should have no conflicts', () {
        // Act
        final puzzle = generator.generate(SudokuDifficulty.medium);
        SudokuSolver.solve(puzzle);

        // Assert
        final conflicts = SudokuValidator.getConflictPositions(puzzle);
        expect(
          conflicts.isEmpty,
          isTrue,
          reason: 'Solved puzzle should have no conflicts',
        );
      });

      test(
        'should not remove cells that create ambiguity',
        () {
          // Act: Generate puzzle
          final puzzle = generator.generate(SudokuDifficulty.medium);

          // Assert: Puzzle must have unique solution
          // (This is already tested, but emphasizing the quality check)
          expect(SudokuSolver.hasUniqueSolution(puzzle), isTrue);
        },
        timeout: const Timeout(Duration(seconds: 10)),
      );
    });

    group('edge cases', () {
      test('should handle generating many puzzles in sequence', () {
        // Act: Generate 5 puzzles
        final puzzles = <dynamic>[];
        for (int i = 0; i < 5; i++) {
          puzzles.add(generator.generate(SudokuDifficulty.easy));
        }

        // Assert: All should be valid
        expect(puzzles.length, equals(5));
        for (final puzzle in puzzles) {
          expect(SudokuValidator.isValidBoard(puzzle), isTrue);
        }
      });

      test('should generate valid puzzle at all difficulty levels', () {
        // Act & Assert: Generate at each difficulty
        for (final difficulty in SudokuDifficulty.values) {
          final puzzle = generator.generate(difficulty);
          expect(
            SudokuValidator.isValidBoard(puzzle),
            isTrue,
            reason: '$difficulty puzzle should be valid',
          );
          expect(
            SudokuSolver.isSolvable(puzzle),
            isTrue,
            reason: '$difficulty puzzle should be solvable',
          );
        }
      });
    });
  });
}
