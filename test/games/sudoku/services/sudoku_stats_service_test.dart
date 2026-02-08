// Unit tests for SudokuStatsService

import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/sudoku/services/sudoku_stats_service.dart';
import 'package:multigame/games/sudoku/models/sudoku_stats.dart';
import 'package:multigame/games/sudoku/models/completed_game.dart';
import 'package:multigame/games/sudoku/logic/sudoku_generator.dart';
import 'package:multigame/repositories/secure_storage_repository.dart';

/// Fake SecureStorageRepository for testing
class FakeSecureStorageRepository implements SecureStorageRepository {
  final Map<String, String> _storage = {};

  @override
  Future<String?> read(String key) async {
    return _storage[key];
  }

  @override
  Future<bool> write(String key, String value) async {
    _storage[key] = value;
    return true;
  }

  @override
  Future<bool> delete(String key) async {
    _storage.remove(key);
    return true;
  }

  @override
  Future<bool> containsKey(String key) async {
    return _storage.containsKey(key);
  }

  @override
  Future<Map<String, String>> readAll() async {
    return Map.from(_storage);
  }

  @override
  Future<bool> deleteAll() async {
    _storage.clear();
    return true;
  }

  void clear() {
    _storage.clear();
  }
}

void main() {
  group('SudokuStatsService', () {
    late SudokuStatsService service;
    late FakeSecureStorageRepository fakeStorage;

    setUp(() {
      fakeStorage = FakeSecureStorageRepository();
      service = SudokuStatsService(storage: fakeStorage);
    });

    tearDown(() {
      fakeStorage.clear();
    });

    group('getStats', () {
      test('should return empty stats when no data exists', () async {
        final stats = await service.getStats();

        expect(stats.totalGamesPlayed, 0);
        expect(stats.totalGamesWon, 0);
        expect(stats.totalTimePlayed, 0);
        expect(stats.classicGamesPlayed, 0);
        expect(stats.rushGamesPlayed, 0);
      });

      test('should return saved stats when data exists', () async {
        final originalStats = SudokuStats(
          totalGamesPlayed: 10,
          totalGamesWon: 8,
          totalTimePlayed: 3600,
          classicGamesPlayed: 5,
          classicGamesWon: 4,
        );

        await service.saveStats(originalStats);
        final retrievedStats = await service.getStats();

        expect(retrievedStats.totalGamesPlayed, 10);
        expect(retrievedStats.totalGamesWon, 8);
        expect(retrievedStats.totalTimePlayed, 3600);
        expect(retrievedStats.classicGamesPlayed, 5);
        expect(retrievedStats.classicGamesWon, 4);
      });

      test('should handle corrupted data gracefully', () async {
        await fakeStorage.write('sudoku_player_stats', 'invalid json');

        final stats = await service.getStats();

        // Should return empty stats instead of crashing
        expect(stats.totalGamesPlayed, 0);
      });
    });

    group('saveStats', () {
      test('should save stats successfully', () async {
        final stats = SudokuStats(
          totalGamesPlayed: 5,
          totalGamesWon: 3,
          totalTimePlayed: 1800,
        );

        final result = await service.saveStats(stats);

        expect(result, true);
      });

      test('should persist stats data', () async {
        final stats = SudokuStats(
          totalGamesPlayed: 7,
          totalGamesWon: 5,
          classicBestScores: {
            SudokuDifficulty.easy: 1000,
            SudokuDifficulty.medium: 800,
          },
        );

        await service.saveStats(stats);
        final retrieved = await service.getStats();

        expect(retrieved.totalGamesPlayed, 7);
        expect(retrieved.totalGamesWon, 5);
        expect(retrieved.classicBestScores[SudokuDifficulty.easy], 1000);
        expect(retrieved.classicBestScores[SudokuDifficulty.medium], 800);
      });
    });

    group('recordGameCompletion', () {
      test('should record classic game victory', () async {
        final game = CompletedGame(
          id: 'test-1',
          mode: 'classic',
          difficulty: SudokuDifficulty.easy,
          score: 1200,
          timeSeconds: 300,
          mistakes: 2,
          hintsUsed: 1,
          victory: true,
          completedAt: DateTime.now(),
        );

        final stats = await service.recordGameCompletion(game);

        expect(stats.totalGamesPlayed, 1);
        expect(stats.totalGamesWon, 1);
        expect(stats.totalTimePlayed, 300);
        expect(stats.classicGamesPlayed, 1);
        expect(stats.classicGamesWon, 1);
        expect(stats.classicTotalTime, 300);
        expect(stats.totalHintsUsed, 1);
        expect(stats.totalMistakes, 2);
        expect(stats.classicBestScores[SudokuDifficulty.easy], 1200);
      });

      test('should record classic game loss', () async {
        final game = CompletedGame(
          id: 'test-2',
          mode: 'classic',
          difficulty: SudokuDifficulty.medium,
          score: 0,
          timeSeconds: 600,
          mistakes: 5,
          hintsUsed: 3,
          victory: false,
          completedAt: DateTime.now(),
        );

        final stats = await service.recordGameCompletion(game);

        expect(stats.totalGamesPlayed, 1);
        expect(stats.totalGamesWon, 0);
        expect(stats.classicGamesPlayed, 1);
        expect(stats.classicGamesWon, 0);
        expect(stats.classicTotalTime, 0); // No time added for losses
      });

      test('should record rush game victory', () async {
        final game = CompletedGame(
          id: 'test-3',
          mode: 'rush',
          difficulty: SudokuDifficulty.hard,
          score: 1500,
          timeSeconds: 180,
          mistakes: 1,
          hintsUsed: 0,
          victory: true,
          completedAt: DateTime.now(),
        );

        final stats = await service.recordGameCompletion(game);

        expect(stats.totalGamesPlayed, 1);
        expect(stats.totalGamesWon, 1);
        expect(stats.rushGamesPlayed, 1);
        expect(stats.rushGamesWon, 1);
        expect(stats.rushGamesLost, 0);
        expect(stats.rushBestScores[SudokuDifficulty.hard], 1500);
      });

      test('should record rush game loss', () async {
        final game = CompletedGame(
          id: 'test-4',
          mode: 'rush',
          difficulty: SudokuDifficulty.expert,
          score: 0,
          timeSeconds: 120,
          mistakes: 0,
          hintsUsed: 0,
          victory: false,
          completedAt: DateTime.now(),
        );

        final stats = await service.recordGameCompletion(game);

        expect(stats.totalGamesPlayed, 1);
        expect(stats.totalGamesWon, 0);
        expect(stats.rushGamesPlayed, 1);
        expect(stats.rushGamesWon, 0);
        expect(stats.rushGamesLost, 1);
      });

      test('should update best scores correctly', () async {
        // Record first game
        final game1 = CompletedGame(
          id: 'test-5',
          mode: 'classic',
          difficulty: SudokuDifficulty.easy,
          score: 1000,
          timeSeconds: 400,
          mistakes: 0,
          hintsUsed: 0,
          victory: true,
          completedAt: DateTime.now(),
        );
        await service.recordGameCompletion(game1);

        // Record second game with higher score
        final game2 = CompletedGame(
          id: 'test-6',
          mode: 'classic',
          difficulty: SudokuDifficulty.easy,
          score: 1500,
          timeSeconds: 300,
          mistakes: 0,
          hintsUsed: 0,
          victory: true,
          completedAt: DateTime.now(),
        );
        final stats = await service.recordGameCompletion(game2);

        expect(stats.classicBestScores[SudokuDifficulty.easy], 1500);
      });

      test('should not update best score with lower score', () async {
        // Record first game with high score
        final game1 = CompletedGame(
          id: 'test-7',
          mode: 'rush',
          difficulty: SudokuDifficulty.medium,
          score: 2000,
          timeSeconds: 200,
          mistakes: 0,
          hintsUsed: 0,
          victory: true,
          completedAt: DateTime.now(),
        );
        await service.recordGameCompletion(game1);

        // Record second game with lower score
        final game2 = CompletedGame(
          id: 'test-8',
          mode: 'rush',
          difficulty: SudokuDifficulty.medium,
          score: 1500,
          timeSeconds: 250,
          mistakes: 1,
          hintsUsed: 1,
          victory: true,
          completedAt: DateTime.now(),
        );
        final stats = await service.recordGameCompletion(game2);

        expect(stats.rushBestScores[SudokuDifficulty.medium], 2000);
      });

      test('should accumulate stats across multiple games', () async {
        // Play 3 classic games
        for (int i = 0; i < 3; i++) {
          final game = CompletedGame(
            id: 'classic-$i',
            mode: 'classic',
            difficulty: SudokuDifficulty.easy,
            score: 1000 + (i * 100),
            timeSeconds: 300,
            mistakes: 1,
            hintsUsed: 1,
            victory: true,
            completedAt: DateTime.now(),
          );
          await service.recordGameCompletion(game);
        }

        // Play 2 rush games
        for (int i = 0; i < 2; i++) {
          final game = CompletedGame(
            id: 'rush-$i',
            mode: 'rush',
            difficulty: SudokuDifficulty.medium,
            score: 1500,
            timeSeconds: 200,
            mistakes: 0,
            hintsUsed: 0,
            victory: true,
            completedAt: DateTime.now(),
          );
          await service.recordGameCompletion(game);
        }

        final stats = await service.getStats();

        expect(stats.totalGamesPlayed, 5);
        expect(stats.totalGamesWon, 5);
        expect(stats.classicGamesPlayed, 3);
        expect(stats.rushGamesPlayed, 2);
        expect(stats.totalHintsUsed, 3); // 3 classic games with 1 hint each
        expect(stats.totalMistakes, 3); // 3 classic games with 1 mistake each
      });
    });

    group('getBestScore', () {
      test('should return best score for classic mode', () async {
        final game = CompletedGame(
          id: 'test-9',
          mode: 'classic',
          difficulty: SudokuDifficulty.hard,
          score: 1800,
          timeSeconds: 500,
          mistakes: 0,
          hintsUsed: 0,
          victory: true,
          completedAt: DateTime.now(),
        );
        await service.recordGameCompletion(game);

        final bestScore = await service.getBestScore('classic', SudokuDifficulty.hard);

        expect(bestScore, 1800);
      });

      test('should return null for mode without scores', () async {
        final bestScore = await service.getBestScore('classic', SudokuDifficulty.easy);

        expect(bestScore, null);
      });

      test('should return null for invalid mode', () async {
        final bestScore = await service.getBestScore('invalid', SudokuDifficulty.easy);

        expect(bestScore, null);
      });
    });

    group('getBestScores', () {
      test('should return all best scores for classic mode', () async {
        final games = [
          CompletedGame(
            id: 'easy',
            mode: 'classic',
            difficulty: SudokuDifficulty.easy,
            score: 1000,
            timeSeconds: 300,
            mistakes: 0,
            hintsUsed: 0,
            victory: true,
            completedAt: DateTime.now(),
          ),
          CompletedGame(
            id: 'medium',
            mode: 'classic',
            difficulty: SudokuDifficulty.medium,
            score: 1200,
            timeSeconds: 400,
            mistakes: 0,
            hintsUsed: 0,
            victory: true,
            completedAt: DateTime.now(),
          ),
        ];

        for (final game in games) {
          await service.recordGameCompletion(game);
        }

        final bestScores = await service.getBestScores('classic');

        expect(bestScores[SudokuDifficulty.easy], 1000);
        expect(bestScores[SudokuDifficulty.medium], 1200);
      });

      test('should return empty map for invalid mode', () async {
        final bestScores = await service.getBestScores('invalid');

        expect(bestScores, isEmpty);
      });
    });

    group('getWinRate', () {
      test('should calculate classic win rate correctly', () async {
        // Win 3 out of 5 classic games
        for (int i = 0; i < 5; i++) {
          final game = CompletedGame(
            id: 'classic-$i',
            mode: 'classic',
            difficulty: SudokuDifficulty.easy,
            score: i < 3 ? 1000 : 0,
            timeSeconds: 300,
            mistakes: 0,
            hintsUsed: 0,
            victory: i < 3, // First 3 are victories
            completedAt: DateTime.now(),
          );
          await service.recordGameCompletion(game);
        }

        final winRate = await service.getWinRate('classic');

        expect(winRate, closeTo(0.6, 0.01)); // 3/5 = 0.6
      });

      test('should calculate rush win rate correctly', () async {
        // Win 1 out of 2 rush games
        for (int i = 0; i < 2; i++) {
          final game = CompletedGame(
            id: 'rush-$i',
            mode: 'rush',
            difficulty: SudokuDifficulty.medium,
            score: i == 0 ? 1500 : 0,
            timeSeconds: 200,
            mistakes: 0,
            hintsUsed: 0,
            victory: i == 0,
            completedAt: DateTime.now(),
          );
          await service.recordGameCompletion(game);
        }

        final winRate = await service.getWinRate('rush');

        expect(winRate, closeTo(0.5, 0.01)); // 1/2 = 0.5
      });

      test('should return overall win rate for invalid mode', () async {
        final game = CompletedGame(
          id: 'test',
          mode: 'classic',
          difficulty: SudokuDifficulty.easy,
          score: 1000,
          timeSeconds: 300,
          mistakes: 0,
          hintsUsed: 0,
          victory: true,
          completedAt: DateTime.now(),
        );
        await service.recordGameCompletion(game);

        final winRate = await service.getWinRate('invalid');

        expect(winRate, closeTo(1.0, 0.01)); // 1/1 = 1.0
      });
    });

    group('getAverageSolveTime', () {
      test('should calculate average solve time correctly', () async {
        // Complete 3 classic games with different times
        final times = [300, 400, 500];
        for (int i = 0; i < times.length; i++) {
          final game = CompletedGame(
            id: 'test-$i',
            mode: 'classic',
            difficulty: SudokuDifficulty.easy,
            score: 1000,
            timeSeconds: times[i],
            mistakes: 0,
            hintsUsed: 0,
            victory: true,
            completedAt: DateTime.now(),
          );
          await service.recordGameCompletion(game);
        }

        final avgTime = await service.getAverageSolveTime();

        expect(avgTime, closeTo(400.0, 0.1)); // (300+400+500)/3 = 400
      });

      test('should return 0 when no games won', () async {
        final avgTime = await service.getAverageSolveTime();

        expect(avgTime, 0.0);
      });
    });

    group('clearStats', () {
      test('should clear all stats data', () async {
        final stats = SudokuStats(
          totalGamesPlayed: 10,
          totalGamesWon: 8,
        );
        await service.saveStats(stats);

        final result = await service.clearStats();

        expect(result, true);

        // Verify stats are cleared
        final retrievedStats = await service.getStats();
        expect(retrievedStats.totalGamesPlayed, 0);
      });

      test('should return true even if no data exists', () async {
        final result = await service.clearStats();

        expect(result, true);
      });
    });

    group('resetStats', () {
      test('should reset stats to empty state', () async {
        final stats = SudokuStats(
          totalGamesPlayed: 15,
          totalGamesWon: 12,
          classicBestScores: {SudokuDifficulty.easy: 2000},
        );
        await service.saveStats(stats);

        final result = await service.resetStats();

        expect(result, true);

        // Verify stats are reset
        final retrievedStats = await service.getStats();
        expect(retrievedStats.totalGamesPlayed, 0);
        expect(retrievedStats.totalGamesWon, 0);
        expect(retrievedStats.classicBestScores, isEmpty);
      });
    });

    group('edge cases', () {
      test('should handle multiple difficulty levels', () async {
        for (final difficulty in SudokuDifficulty.values) {
          final game = CompletedGame(
            id: 'diff-${difficulty.name}',
            mode: 'classic',
            difficulty: difficulty,
            score: 1000,
            timeSeconds: 300,
            mistakes: 0,
            hintsUsed: 0,
            victory: true,
            completedAt: DateTime.now(),
          );
          await service.recordGameCompletion(game);
        }

        final stats = await service.getStats();

        expect(stats.totalGamesPlayed, SudokuDifficulty.values.length);
        expect(stats.classicBestScores.length, SudokuDifficulty.values.length);
      });

      test('should persist lastPlayedAt timestamp', () async {
        final now = DateTime.now();
        final game = CompletedGame(
          id: 'test',
          mode: 'classic',
          difficulty: SudokuDifficulty.easy,
          score: 1000,
          timeSeconds: 300,
          mistakes: 0,
          hintsUsed: 0,
          victory: true,
          completedAt: now,
        );

        await service.recordGameCompletion(game);
        final stats = await service.getStats();

        expect(stats.lastPlayedAt, isNotNull);
        expect(stats.lastPlayedAt!.year, now.year);
        expect(stats.lastPlayedAt!.month, now.month);
        expect(stats.lastPlayedAt!.day, now.day);
      });
    });
  });
}
