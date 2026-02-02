import 'dart:convert';
import 'package:multigame/repositories/secure_storage_repository.dart';
import 'package:multigame/utils/secure_logger.dart';
import '../models/saved_game.dart';
import '../models/completed_game.dart';
import '../logic/sudoku_generator.dart';

/// Service for persisting Sudoku game state and history.
///
/// This service uses SecureStorageRepository for encrypted local storage.
/// Handles:
/// - Saving/loading unfinished games
/// - Storing completed game history
/// - Managing best scores per difficulty
class SudokuPersistenceService {
  final SecureStorageRepository _storage;

  // Storage keys
  static const String _keyClassicSavedGame = 'sudoku_saved_game_classic';
  static const String _keyRushSavedGame = 'sudoku_saved_game_rush';
  static const String _keyCompletedGames = 'sudoku_completed_games';
  static const String _keyBestScoresClassic = 'sudoku_best_scores_classic';
  static const String _keyBestScoresRush = 'sudoku_best_scores_rush';

  SudokuPersistenceService({
    SecureStorageRepository? storage,
  }) : _storage = storage ?? SecureStorageRepository();

  // ========== SAVED GAMES (Unfinished) ==========

  /// Saves an unfinished game
  Future<bool> saveSavedGame(SavedGame game) async {
    try {
      final key = game.mode == 'classic' ? _keyClassicSavedGame : _keyRushSavedGame;
      final jsonString = game.toJsonString();
      final success = await _storage.write(key, jsonString);

      if (success) {
        SecureLogger.log('Saved ${game.mode} game', tag: 'SudokuPersistence');
      }

      return success;
    } catch (e) {
      SecureLogger.error('Failed to save game', error: e, tag: 'SudokuPersistence');
      return false;
    }
  }

  /// Loads a saved game by mode ('classic' or 'rush')
  Future<SavedGame?> loadSavedGame(String mode) async {
    try {
      final key = mode == 'classic' ? _keyClassicSavedGame : _keyRushSavedGame;
      final jsonString = await _storage.read(key);

      if (jsonString == null) {
        return null;
      }

      return SavedGame.fromJsonString(jsonString);
    } catch (e) {
      SecureLogger.error('Failed to load saved game', error: e, tag: 'SudokuPersistence');
      return null;
    }
  }

  /// Deletes a saved game by mode
  Future<bool> deleteSavedGame(String mode) async {
    try {
      final key = mode == 'classic' ? _keyClassicSavedGame : _keyRushSavedGame;
      return await _storage.delete(key);
    } catch (e) {
      SecureLogger.error('Failed to delete saved game', error: e, tag: 'SudokuPersistence');
      return false;
    }
  }

  /// Checks if a saved game exists for the given mode
  Future<bool> hasSavedGame(String mode) async {
    try {
      final key = mode == 'classic' ? _keyClassicSavedGame : _keyRushSavedGame;
      return await _storage.containsKey(key);
    } catch (e) {
      SecureLogger.error('Failed to check saved game', error: e, tag: 'SudokuPersistence');
      return false;
    }
  }

  // ========== COMPLETED GAMES (History) ==========

  /// Saves a completed game to history
  Future<bool> saveCompletedGame(CompletedGame game) async {
    try {
      final games = await getCompletedGames();
      games.add(game);

      // Keep only last 100 games to avoid storage bloat
      if (games.length > 100) {
        games.removeRange(0, games.length - 100);
      }

      final jsonList = games.map((g) => g.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      final success = await _storage.write(_keyCompletedGames, jsonString);

      if (success) {
        SecureLogger.log('Saved completed game to history', tag: 'SudokuPersistence');
      }

      return success;
    } catch (e) {
      SecureLogger.error('Failed to save completed game', error: e, tag: 'SudokuPersistence');
      return false;
    }
  }

  /// Gets all completed games from history
  Future<List<CompletedGame>> getCompletedGames() async {
    try {
      final jsonString = await _storage.read(_keyCompletedGames);

      if (jsonString == null) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => CompletedGame.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      SecureLogger.error('Failed to load completed games', error: e, tag: 'SudokuPersistence');
      return [];
    }
  }

  /// Gets completed games filtered by mode
  Future<List<CompletedGame>> getCompletedGamesByMode(String mode) async {
    final allGames = await getCompletedGames();
    return allGames.where((game) => game.mode == mode).toList();
  }

  /// Gets completed games filtered by difficulty
  Future<List<CompletedGame>> getCompletedGamesByDifficulty(
    SudokuDifficulty difficulty,
  ) async {
    final allGames = await getCompletedGames();
    return allGames.where((game) => game.difficulty == difficulty).toList();
  }

  /// Clears all completed game history
  Future<bool> clearCompletedGames() async {
    try {
      return await _storage.delete(_keyCompletedGames);
    } catch (e) {
      SecureLogger.error('Failed to clear completed games', error: e, tag: 'SudokuPersistence');
      return false;
    }
  }

  // ========== BEST SCORES ==========

  /// Saves best score for a difficulty/mode
  Future<bool> saveBestScore(String mode, SudokuDifficulty difficulty, int score) async {
    try {
      final scores = await getBestScores(mode);

      // Only save if it's a new high score
      final currentBest = scores[difficulty] ?? 0;
      if (score <= currentBest) {
        return true; // No need to update
      }

      scores[difficulty] = score;

      final key = mode == 'classic' ? _keyBestScoresClassic : _keyBestScoresRush;
      final jsonMap = scores.map((key, value) => MapEntry(key.name, value));
      final jsonString = jsonEncode(jsonMap);

      return await _storage.write(key, jsonString);
    } catch (e) {
      SecureLogger.error('Failed to save best score', error: e, tag: 'SudokuPersistence');
      return false;
    }
  }

  /// Gets all best scores for a mode
  Future<Map<SudokuDifficulty, int>> getBestScores(String mode) async {
    try {
      final key = mode == 'classic' ? _keyBestScoresClassic : _keyBestScoresRush;
      final jsonString = await _storage.read(key);

      if (jsonString == null) {
        return {};
      }

      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return Map.fromEntries(
        jsonMap.entries.map((e) {
          final difficulty = SudokuDifficulty.values.firstWhere(
            (d) => d.name == e.key,
            orElse: () => SudokuDifficulty.easy,
          );
          return MapEntry(difficulty, e.value as int);
        }),
      );
    } catch (e) {
      SecureLogger.error('Failed to load best scores', error: e, tag: 'SudokuPersistence');
      return {};
    }
  }

  /// Gets best score for a specific difficulty/mode
  Future<int?> getBestScore(String mode, SudokuDifficulty difficulty) async {
    final scores = await getBestScores(mode);
    return scores[difficulty];
  }

  /// Clears all best scores for a mode
  Future<bool> clearBestScores(String mode) async {
    try {
      final key = mode == 'classic' ? _keyBestScoresClassic : _keyBestScoresRush;
      return await _storage.delete(key);
    } catch (e) {
      SecureLogger.error('Failed to clear best scores', error: e, tag: 'SudokuPersistence');
      return false;
    }
  }

  // ========== GENERAL ==========

  /// Clears all Sudoku persistent data (for testing/reset)
  Future<bool> clearAllData() async {
    try {
      await _storage.delete(_keyClassicSavedGame);
      await _storage.delete(_keyRushSavedGame);
      await _storage.delete(_keyCompletedGames);
      await _storage.delete(_keyBestScoresClassic);
      await _storage.delete(_keyBestScoresRush);

      SecureLogger.log('Cleared all Sudoku data', tag: 'SudokuPersistence');
      return true;
    } catch (e) {
      SecureLogger.error('Failed to clear all data', error: e, tag: 'SudokuPersistence');
      return false;
    }
  }
}
