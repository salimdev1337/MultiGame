// Sudoku statistics service - see docs/SUDOKU_SERVICES.md

import 'package:multigame/repositories/secure_storage_repository.dart';
import 'package:multigame/utils/secure_logger.dart';
import '../models/sudoku_stats.dart';
import '../models/completed_game.dart';
import '../logic/sudoku_generator.dart';

class SudokuStatsService {
  final SecureStorageRepository _storage;

  static const String _keyStats = 'sudoku_player_stats';

  SudokuStatsService({SecureStorageRepository? storage})
    : _storage = storage ?? SecureStorageRepository();

  Future<SudokuStats> getStats() async {
    try {
      final jsonString = await _storage.read(_keyStats);

      if (jsonString == null) {
        return SudokuStats();
      }

      return SudokuStats.fromJsonString(jsonString);
    } catch (e) {
      SecureLogger.error('Failed to load stats', error: e, tag: 'SudokuStats');
      return SudokuStats();
    }
  }

  Future<bool> saveStats(SudokuStats stats) async {
    try {
      final jsonString = stats.toJsonString();
      return await _storage.write(_keyStats, jsonString);
    } catch (e) {
      SecureLogger.error('Failed to save stats', error: e, tag: 'SudokuStats');
      return false;
    }
  }

  Future<SudokuStats> recordGameCompletion(CompletedGame game) async {
    try {
      final currentStats = await getStats();

      final newTotalPlayed = currentStats.totalGamesPlayed + 1;
      final newTotalWon = game.victory
          ? currentStats.totalGamesWon + 1
          : currentStats.totalGamesWon;
      final newTotalTime = currentStats.totalTimePlayed + game.timeSeconds;

      int newClassicPlayed = currentStats.classicGamesPlayed;
      int newClassicWon = currentStats.classicGamesWon;
      int newClassicTime = currentStats.classicTotalTime;
      Map<SudokuDifficulty, int> newClassicBestScores = Map.from(
        currentStats.classicBestScores,
      );

      int newRushPlayed = currentStats.rushGamesPlayed;
      int newRushWon = currentStats.rushGamesWon;
      int newRushLost = currentStats.rushGamesLost;
      Map<SudokuDifficulty, int> newRushBestScores = Map.from(
        currentStats.rushBestScores,
      );

      if (game.mode == 'classic') {
        newClassicPlayed++;
        if (game.victory) {
          newClassicWon++;
          newClassicTime += game.timeSeconds;

          final currentBest = newClassicBestScores[game.difficulty] ?? 0;
          if (game.score > currentBest) {
            newClassicBestScores[game.difficulty] = game.score;
          }
        }
      } else if (game.mode == 'rush') {
        newRushPlayed++;
        if (game.victory) {
          newRushWon++;

          final currentBest = newRushBestScores[game.difficulty] ?? 0;
          if (game.score > currentBest) {
            newRushBestScores[game.difficulty] = game.score;
          }
        } else {
          newRushLost++;
        }
      }

      final newTotalHints = currentStats.totalHintsUsed + game.hintsUsed;
      final newTotalMistakes = currentStats.totalMistakes + game.mistakes;

      final updatedStats = SudokuStats(
        totalGamesPlayed: newTotalPlayed,
        totalGamesWon: newTotalWon,
        totalTimePlayed: newTotalTime,
        classicGamesPlayed: newClassicPlayed,
        classicGamesWon: newClassicWon,
        classicTotalTime: newClassicTime,
        classicBestScores: newClassicBestScores,
        rushGamesPlayed: newRushPlayed,
        rushGamesWon: newRushWon,
        rushGamesLost: newRushLost,
        rushBestScores: newRushBestScores,
        totalHintsUsed: newTotalHints,
        totalMistakes: newTotalMistakes,
        lastPlayedAt: game.completedAt,
      );

      await saveStats(updatedStats);

      SecureLogger.log(
        'Updated stats: ${updatedStats.totalGamesPlayed} played, ${updatedStats.totalGamesWon} won',
        tag: 'SudokuStats',
      );

      return updatedStats;
    } catch (e) {
      SecureLogger.error(
        'Failed to record game completion',
        error: e,
        tag: 'SudokuStats',
      );
      return await getStats();
    }
  }

  Future<int?> getBestScore(String mode, SudokuDifficulty difficulty) async {
    final stats = await getStats();
    if (mode == 'classic') {
      return stats.classicBestScores[difficulty];
    } else if (mode == 'rush') {
      return stats.rushBestScores[difficulty];
    }
    return null;
  }

  Future<Map<SudokuDifficulty, int>> getBestScores(String mode) async {
    final stats = await getStats();
    if (mode == 'classic') {
      return stats.classicBestScores;
    } else if (mode == 'rush') {
      return stats.rushBestScores;
    }
    return {};
  }

  Future<double> getWinRate(String mode) async {
    final stats = await getStats();
    if (mode == 'classic') {
      return stats.classicWinRate;
    } else if (mode == 'rush') {
      return stats.rushWinRate;
    }
    return stats.winRate;
  }

  Future<double> getAverageSolveTime() async {
    final stats = await getStats();
    return stats.averageSolveTime;
  }

  Future<bool> clearStats() async {
    try {
      final success = await _storage.delete(_keyStats);
      if (success) {
        SecureLogger.log('Cleared all Sudoku stats', tag: 'SudokuStats');
      }
      return success;
    } catch (e) {
      SecureLogger.error('Failed to clear stats', error: e, tag: 'SudokuStats');
      return false;
    }
  }

  Future<bool> resetStats() async {
    try {
      final freshStats = SudokuStats();
      return await saveStats(freshStats);
    } catch (e) {
      SecureLogger.error('Failed to reset stats', error: e, tag: 'SudokuStats');
      return false;
    }
  }
}
