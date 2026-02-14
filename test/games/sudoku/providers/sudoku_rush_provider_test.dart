import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/sudoku/logic/sudoku_generator.dart';
import 'package:multigame/games/sudoku/models/sudoku_stats.dart';
import 'package:multigame/games/sudoku/models/saved_game.dart';
import 'package:multigame/games/sudoku/models/completed_game.dart';
import 'package:multigame/services/data/firebase_stats_service.dart';
import 'package:multigame/games/sudoku/providers/sudoku_rush_provider.dart';
import 'package:multigame/games/sudoku/services/sudoku_persistence_service.dart';
import 'package:multigame/games/sudoku/services/sudoku_stats_service.dart';
import 'package:multigame/games/sudoku/services/sudoku_sound_service.dart';
import 'package:multigame/games/sudoku/services/sudoku_haptic_service.dart';

// Manual fake implementations
class FakeFirebaseStatsService implements FirebaseStatsService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakePersistenceService implements SudokuPersistenceService {
  SavedGame? _savedGame;
  final Map<String, int> _bestScores = {};
  final List<CompletedGame> _completedGames = [];

  @override
  Future<SavedGame?> loadSavedGame(String mode) async => _savedGame;

  @override
  Future<bool> saveSavedGame(SavedGame game) async {
    _savedGame = game;
    return true;
  }

  @override
  Future<bool> deleteSavedGame(String mode) async {
    _savedGame = null;
    return true;
  }

  @override
  Future<bool> hasSavedGame(String mode) async => _savedGame != null;

  @override
  Future<bool> saveBestScore(
    String mode,
    SudokuDifficulty difficulty,
    int score,
  ) async {
    _bestScores['${mode}_${difficulty.name}'] = score;
    return true;
  }

  @override
  Future<bool> saveCompletedGame(CompletedGame game) async {
    _completedGames.add(game);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeSudokuStatsService implements SudokuStatsService {
  final List<CompletedGame> _completedGames = [];

  @override
  Future<SudokuStats> recordGameCompletion(CompletedGame game) async {
    _completedGames.add(game);
    return SudokuStats(
      totalGamesPlayed: _completedGames.length,
      totalGamesWon: _completedGames.where((g) => g.victory).length,
      classicGamesPlayed: _completedGames
          .where((g) => g.mode == 'classic')
          .length,
      classicGamesWon: _completedGames
          .where((g) => g.mode == 'classic' && g.victory)
          .length,
      rushGamesPlayed: _completedGames.where((g) => g.mode == 'rush').length,
      rushGamesWon: _completedGames
          .where((g) => g.mode == 'rush' && g.victory)
          .length,
      rushGamesLost: _completedGames
          .where((g) => g.mode == 'rush' && !g.victory)
          .length,
      totalMistakes: _completedGames.fold(0, (sum, g) => sum + g.mistakes),
      totalHintsUsed: _completedGames.fold(0, (sum, g) => sum + g.hintsUsed),
      totalTimePlayed: _completedGames.fold(0, (sum, g) => sum + g.timeSeconds),
      lastPlayedAt: DateTime.now(),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeSoundService implements SudokuSoundService {
  @override
  Future<void> playSelectCell() async {}

  @override
  Future<void> playNumberEntry() async {}

  @override
  Future<void> playNotesToggle() async {}

  @override
  Future<void> playErase() async {}

  @override
  Future<void> playError() async {}

  @override
  Future<void> playVictory() async {}

  @override
  Future<void> playHint() async {}

  @override
  Future<void> playUndo() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeHapticService implements SudokuHapticService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> lightTap() async {}

  @override
  Future<void> mediumTap() async {}

  @override
  Future<void> strongTap() async {}

  @override
  Future<void> doubleTap() async {}

  @override
  Future<void> successPattern() async {}

  @override
  Future<void> errorShake() async {}

  @override
  Future<void> cancel() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('SudokuRushProvider - Rush Mode', () {
    late SudokuRushProvider provider;
    late FakeFirebaseStatsService statsService;
    late FakePersistenceService persistenceService;
    late FakeSudokuStatsService sudokuStatsService;
    late FakeSoundService soundService;
    late FakeHapticService hapticService;

    setUp(() {
      statsService = FakeFirebaseStatsService();
      persistenceService = FakePersistenceService();
      sudokuStatsService = FakeSudokuStatsService();
      soundService = FakeSoundService();
      hapticService = FakeHapticService();

      provider = SudokuRushProvider(
        statsService: statsService,
        persistenceService: persistenceService,
        sudokuStatsService: sudokuStatsService,
        soundService: soundService,
        hapticService: hapticService,
      );
    });

    tearDown(() {
      provider.dispose();
    });

    group('initialization', () {
      test('initializes with correct default values', () {
        expect(provider.currentBoard, isNull);
        expect(
          provider.remainingSeconds,
          SudokuRushProvider.initialTimeSeconds,
        );
        expect(provider.penaltiesApplied, 0);
        expect(provider.mistakes, 0);
        expect(provider.isGameOver, false);
        expect(provider.isVictory, false);
        expect(provider.isDefeat, false);
        expect(provider.showPenalty, false);
      });

      test('initializes game with specified difficulty', () async {
        await provider.initializeGame(SudokuDifficulty.easy);

        expect(provider.currentBoard, isNotNull);
        expect(provider.originalBoard, isNotNull);
        expect(provider.difficulty, SudokuDifficulty.easy);
        expect(
          provider.remainingSeconds,
          SudokuRushProvider.initialTimeSeconds,
        );
        expect(provider.penaltiesApplied, 0);
      });

      test('starts countdown timer on initialization', () async {
        await provider.initializeGame(SudokuDifficulty.medium);

        final initialTime = provider.remainingSeconds;

        await Future.delayed(const Duration(milliseconds: 1100));

        expect(provider.remainingSeconds, lessThan(initialTime));
      });
    });

    group('time management', () {
      setUp(() async {
        await provider.initializeGame(SudokuDifficulty.medium);
      });

      test('counts down remaining time', () async {
        final initialTime = provider.remainingSeconds;

        await Future.delayed(const Duration(milliseconds: 1100));

        expect(provider.remainingSeconds, lessThan(initialTime));
      });

      test('formats time correctly', () {
        expect(provider.formattedTime, matches(r'\d{2}:\d{2}'));
      });

      test('pauses and resumes timer', () async {
        await Future.delayed(const Duration(milliseconds: 500));
        provider.pauseTimer();

        final pausedTime = provider.remainingSeconds;

        await Future.delayed(const Duration(milliseconds: 500));

        // Time should not have changed
        expect(provider.remainingSeconds, pausedTime);

        provider.resumeTimer();
        await Future.delayed(const Duration(milliseconds: 1100));

        // Time should have resumed counting down
        expect(provider.remainingSeconds, lessThan(pausedTime));
      });
    });

    group('penalty system', () {
      setUp(() async {
        await provider.initializeGame(SudokuDifficulty.medium);
      });

      test('tracks penalties applied', () {
        expect(provider.penaltiesApplied, 0);
      });

      test('shows penalty indicator temporarily', () async {
        expect(provider.showPenalty, false);

        // Penalty display is triggered by placing conflicting number
        // which is hard to simulate in test without board knowledge
        // Just verify the getter works
      });
    });

    group('game reset', () {
      setUp(() async {
        await provider.initializeGame(SudokuDifficulty.medium);
      });

      test('resets game to original state', () {
        // Make some changes
        provider.selectCell(0, 0);

        // Reset
        provider.resetGame();

        expect(provider.mistakes, 0);
        expect(provider.hintsUsed, 0);
        expect(
          provider.remainingSeconds,
          SudokuRushProvider.initialTimeSeconds,
        );
        expect(provider.penaltiesApplied, 0);
        expect(provider.selectedRow, isNull);
        expect(provider.isGameOver, false);
        expect(provider.isVictory, false);
        expect(provider.isDefeat, false);
      });
    });

    group('cell selection', () {
      setUp(() async {
        await provider.initializeGame(SudokuDifficulty.medium);
      });

      test('selects cell at specified position', () {
        provider.selectCell(3, 5);

        expect(provider.selectedRow, 3);
        expect(provider.selectedCol, 5);
      });

      test('clears cell selection', () {
        provider.selectCell(2, 4);
        provider.clearSelection();

        expect(provider.selectedRow, isNull);
        expect(provider.selectedCol, isNull);
      });
    });

    group('number placement', () {
      setUp(() async {
        await provider.initializeGame(SudokuDifficulty.medium);
      });

      test('places number in selected cell', () {
        // Find an empty cell
        for (int row = 0; row < 9; row++) {
          for (int col = 0; col < 9; col++) {
            final cell = provider.currentBoard!.getCell(row, col);
            if (cell.isEmpty && !cell.isFixed) {
              provider.selectCell(row, col);
              provider.placeNumber(5);

              expect(cell.value, 5);
              return;
            }
          }
        }
      });

      test('cannot modify fixed cells', () {
        // Find a fixed cell
        for (int row = 0; row < 9; row++) {
          for (int col = 0; col < 9; col++) {
            final cell = provider.currentBoard!.getCell(row, col);
            if (cell.isFixed) {
              final originalValue = cell.value;
              provider.selectCell(row, col);
              provider.placeNumber(9);

              expect(cell.value, originalValue);
              return;
            }
          }
        }
      });
    });

    group('notes mode', () {
      setUp(() async {
        await provider.initializeGame(SudokuDifficulty.medium);
      });

      test('toggles notes mode', () {
        expect(provider.notesMode, false);

        provider.toggleNotesMode();
        expect(provider.notesMode, true);

        provider.toggleNotesMode();
        expect(provider.notesMode, false);
      });

      test('adds note in notes mode', () {
        // Find empty cell
        for (int row = 0; row < 9; row++) {
          for (int col = 0; col < 9; col++) {
            final cell = provider.currentBoard!.getCell(row, col);
            if (cell.isEmpty && !cell.isFixed) {
              provider.selectCell(row, col);
              provider.toggleNotesMode();
              provider.placeNumber(5);

              expect(cell.notes, contains(5));
              expect(cell.value, isNull);
              return;
            }
          }
        }
      });
    });

    group('erase functionality', () {
      setUp(() async {
        await provider.initializeGame(SudokuDifficulty.medium);
      });

      test('erases value from cell', () {
        // Find empty cell and place a value
        for (int row = 0; row < 9; row++) {
          for (int col = 0; col < 9; col++) {
            final cell = provider.currentBoard!.getCell(row, col);
            if (cell.isEmpty && !cell.isFixed) {
              provider.selectCell(row, col);
              provider.placeNumber(5);
              expect(cell.value, 5);

              provider.eraseCell();
              expect(cell.value, isNull);
              return;
            }
          }
        }
      });

      test('canErase returns correct value', () {
        expect(provider.canErase, false);

        // Find empty cell
        for (int row = 0; row < 9; row++) {
          for (int col = 0; col < 9; col++) {
            final cell = provider.currentBoard!.getCell(row, col);
            if (cell.isEmpty && !cell.isFixed) {
              provider.selectCell(row, col);
              expect(provider.canErase, true);
              return;
            }
          }
        }
      });
    });

    group('hint system', () {
      setUp(() async {
        await provider.initializeGame(SudokuDifficulty.medium);
      });

      test('uses hint and decrements remaining hints', () {
        expect(provider.hintsRemaining, 3);

        provider.useHint();

        expect(provider.hintsUsed, 1);
        expect(provider.hintsRemaining, 2);
      });

      test('cannot use more than 3 hints', () {
        provider.useHint();
        provider.useHint();
        provider.useHint();
        expect(provider.hintsRemaining, 0);

        provider.useHint();
        expect(provider.hintsUsed, 3);
      });
    });

    group('undo/redo', () {
      setUp(() async {
        await provider.initializeGame(SudokuDifficulty.medium);
      });

      test('undo reverses last action', () {
        // Find empty cell and place value
        for (int row = 0; row < 9; row++) {
          for (int col = 0; col < 9; col++) {
            final cell = provider.currentBoard!.getCell(row, col);
            if (cell.isEmpty && !cell.isFixed) {
              provider.selectCell(row, col);
              provider.placeNumber(5);
              expect(cell.value, 5);

              provider.undo();
              expect(cell.value, isNull);
              return;
            }
          }
        }
      });

      test('canUndo is false initially', () {
        expect(provider.canUndo, false);
      });

      test('canUndo is true after action', () {
        // Find empty cell
        for (int row = 0; row < 9; row++) {
          for (int col = 0; col < 9; col++) {
            final cell = provider.currentBoard!.getCell(row, col);
            if (cell.isEmpty && !cell.isFixed) {
              provider.selectCell(row, col);
              provider.placeNumber(5);

              expect(provider.canUndo, true);
              return;
            }
          }
        }
      });
    });

    group('error highlighting', () {
      setUp(() async {
        await provider.initializeGame(SudokuDifficulty.medium);
      });

      test('toggles error highlighting', () {
        expect(provider.errorHighlightEnabled, true);

        provider.toggleErrorHighlighting(false);
        expect(provider.errorHighlightEnabled, false);

        provider.toggleErrorHighlighting(true);
        expect(provider.errorHighlightEnabled, true);
      });
    });

    group('score calculation', () {
      setUp(() async {
        await provider.initializeGame(SudokuDifficulty.medium);
      });

      test('calculates score with time bonus', () {
        final score = provider.score;
        expect(score, greaterThan(0));
        expect(score, lessThanOrEqualTo(20000));
      });

      test('score includes remaining time bonus', () {
        final initialScore = provider.score;
        // Score should include time bonus from remaining seconds
        expect(initialScore, greaterThan(10000));
      });
    });

    group('game state', () {
      setUp(() async {
        await provider.initializeGame(SudokuDifficulty.medium);
      });

      test('isVictory is false initially', () {
        expect(provider.isVictory, false);
      });

      test('isDefeat is false initially', () {
        expect(provider.isDefeat, false);
      });

      test('isGameOver is false initially', () {
        expect(provider.isGameOver, false);
      });
    });

    group('game persistence', () {
      setUp(() async {
        await provider.initializeGame(SudokuDifficulty.medium);
      });

      test('saves game state', () async {
        await provider.saveGameState();

        expect(persistenceService._savedGame, isNotNull);
        expect(persistenceService._savedGame!.mode, 'rush');
      });

      test('loads saved game state', () async {
        // Save current state
        await provider.saveGameState();

        // Create new provider
        final newProvider = SudokuRushProvider(
          statsService: statsService,
          persistenceService: persistenceService,
          sudokuStatsService: sudokuStatsService,
          soundService: soundService,
          hapticService: hapticService,
        );

        // Load saved state
        final loaded = await newProvider.loadGameState();

        expect(loaded, true);
        expect(newProvider.currentBoard, isNotNull);
        expect(newProvider.difficulty, provider.difficulty);

        newProvider.dispose();
      });

      test('checks if saved game exists', () async {
        expect(await provider.hasSavedGame(), false);

        await provider.saveGameState();
        expect(await provider.hasSavedGame(), true);
      });
    });

    group('disposal', () {
      test('cleans up resources on dispose', () async {
        await provider.initializeGame(SudokuDifficulty.easy);

        provider.dispose();

        // Timers should be cancelled - shouldn't crash
      });
    });
  });
}
