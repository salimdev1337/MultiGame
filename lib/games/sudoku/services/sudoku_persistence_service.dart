// Sudoku persistence service - see docs/SUDOKU_SERVICES.md

import 'dart:convert';
import 'package:multigame/repositories/secure_storage_repository.dart';
import 'package:multigame/utils/secure_logger.dart';
import '../models/saved_game.dart';
import '../models/completed_game.dart';
import '../logic/sudoku_generator.dart';

class SudokuPersistenceService {
  final SecureStorageRepository _storage;

  static const String _keyClassicSavedGame = 'sudoku_saved_game_classic';
  static const String _keyRushSavedGame = 'sudoku_saved_game_rush';
  static const String _keyCompletedGames = 'sudoku_completed_games';
  static const String _keyBestScoresClassic = 'sudoku_best_scores_classic';
  static const String _keyBestScoresRush = 'sudoku_best_scores_rush';

  SudokuPersistenceService({SecureStorageRepository? storage})
    : _storage = storage ?? SecureStorageRepository();

  Future<bool> saveSavedGame(SavedGame game) async {
    try {
      final key = game.mode == 'classic'
          ? _keyClassicSavedGame
          : _keyRushSavedGame;
      final jsonString = game.toJsonString();
      final success = await _storage.write(key, jsonString);

      if (success) {
        SecureLogger.log('Saved ${game.mode} game', tag: 'SudokuPersistence');
      }

      return success;
    } catch (e) {
      SecureLogger.error(
        'Failed to save game',
        error: e,
        tag: 'SudokuPersistence',
      );
      return false;
    }
  }

  Future<SavedGame?> loadSavedGame(String mode) async {
    try {
      final key = mode == 'classic' ? _keyClassicSavedGame : _keyRushSavedGame;
      final jsonString = await _storage.read(key);

      if (jsonString == null) {
        return null;
      }

      return SavedGame.fromJsonString(jsonString);
    } catch (e) {
      SecureLogger.error(
        'Failed to load saved game',
        error: e,
        tag: 'SudokuPersistence',
      );
      return null;
    }
  }

  Future<bool> deleteSavedGame(String mode) async {
    try {
      final key = mode == 'classic' ? _keyClassicSavedGame : _keyRushSavedGame;
      return await _storage.delete(key);
    } catch (e) {
      SecureLogger.error(
        'Failed to delete saved game',
        error: e,
        tag: 'SudokuPersistence',
      );
      return false;
    }
  }

  Future<bool> hasSavedGame(String mode) async {
    try {
      final key = mode == 'classic' ? _keyClassicSavedGame : _keyRushSavedGame;
      return await _storage.containsKey(key);
    } catch (e) {
      SecureLogger.error(
        'Failed to check saved game',
        error: e,
        tag: 'SudokuPersistence',
      );
      return false;
    }
  }

  Future<bool> saveCompletedGame(CompletedGame game) async {
    try {
      final games = await getCompletedGames();
      games.add(game);

      if (games.length > 100) {
        games.removeRange(0, games.length - 100);
      }

      final jsonList = games.map((g) => g.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      final success = await _storage.write(_keyCompletedGames, jsonString);

      if (success) {
        SecureLogger.log(
          'Saved completed game to history',
          tag: 'SudokuPersistence',
        );
      }

      return success;
    } catch (e) {
      SecureLogger.error(
        'Failed to save completed game',
        error: e,
        tag: 'SudokuPersistence',
      );
      return false;
    }
  }

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
      SecureLogger.error(
        'Failed to load completed games',
        error: e,
        tag: 'SudokuPersistence',
      );
      return [];
    }
  }

  Future<List<CompletedGame>> getCompletedGamesByMode(String mode) async {
    final allGames = await getCompletedGames();
    return allGames.where((game) => game.mode == mode).toList();
  }

  Future<List<CompletedGame>> getCompletedGamesByDifficulty(
    SudokuDifficulty difficulty,
  ) async {
    final allGames = await getCompletedGames();
    return allGames.where((game) => game.difficulty == difficulty).toList();
  }

  Future<bool> clearCompletedGames() async {
    try {
      return await _storage.delete(_keyCompletedGames);
    } catch (e) {
      SecureLogger.error(
        'Failed to clear completed games',
        error: e,
        tag: 'SudokuPersistence',
      );
      return false;
    }
  }

  Future<bool> saveBestScore(
    String mode,
    SudokuDifficulty difficulty,
    int score,
  ) async {
    try {
      final scores = await getBestScores(mode);

      final currentBest = scores[difficulty] ?? 0;
      if (score <= currentBest) {
        return true;
      }

      scores[difficulty] = score;

      final key = mode == 'classic'
          ? _keyBestScoresClassic
          : _keyBestScoresRush;
      final jsonMap = scores.map((key, value) => MapEntry(key.name, value));
      final jsonString = jsonEncode(jsonMap);

      return await _storage.write(key, jsonString);
    } catch (e) {
      SecureLogger.error(
        'Failed to save best score',
        error: e,
        tag: 'SudokuPersistence',
      );
      return false;
    }
  }

  Future<Map<SudokuDifficulty, int>> getBestScores(String mode) async {
    try {
      final key = mode == 'classic'
          ? _keyBestScoresClassic
          : _keyBestScoresRush;
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
      SecureLogger.error(
        'Failed to load best scores',
        error: e,
        tag: 'SudokuPersistence',
      );
      return {};
    }
  }

  Future<int?> getBestScore(String mode, SudokuDifficulty difficulty) async {
    final scores = await getBestScores(mode);
    return scores[difficulty];
  }

  Future<bool> clearBestScores(String mode) async {
    try {
      final key = mode == 'classic'
          ? _keyBestScoresClassic
          : _keyBestScoresRush;
      return await _storage.delete(key);
    } catch (e) {
      SecureLogger.error(
        'Failed to clear best scores',
        error: e,
        tag: 'SudokuPersistence',
      );
      return false;
    }
  }

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
      SecureLogger.error(
        'Failed to clear all data',
        error: e,
        tag: 'SudokuPersistence',
      );
      return false;
    }
  }
}
