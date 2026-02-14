// Shared fake implementations for Sudoku provider tests
import 'package:multigame/games/sudoku/logic/sudoku_generator.dart';
import 'package:multigame/games/sudoku/models/sudoku_stats.dart';
import 'package:multigame/games/sudoku/models/saved_game.dart';
import 'package:multigame/games/sudoku/models/completed_game.dart';
import 'package:multigame/services/data/firebase_stats_service.dart';
import 'package:multigame/games/sudoku/services/sudoku_persistence_service.dart';
import 'package:multigame/games/sudoku/services/sudoku_stats_service.dart';
import 'package:multigame/games/sudoku/services/sudoku_sound_service.dart';
import 'package:multigame/games/sudoku/services/sudoku_haptic_service.dart';

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
  Future<void> lightTap() async {}

  @override
  Future<void> mediumTap() async {}

  @override
  Future<void> doubleTap() async {}

  @override
  Future<void> errorShake() async {}

  @override
  Future<void> successPattern() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
