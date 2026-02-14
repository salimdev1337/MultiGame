import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:multigame/repositories/achievement_repository.dart';

void main() {
  late AchievementRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = SharedPrefsAchievementRepository();
  });

  group('AchievementRepository - Puzzle stats (total completed)', () {
    test('returns 0 when no completions', () async {
      final result = await repository.getTotalCompleted();
      expect(result, 0);
    });

    test('increments total completed', () async {
      await repository.incrementTotalCompleted();

      final result = await repository.getTotalCompleted();
      expect(result, 1);
    });

    test('increments multiple times', () async {
      await repository.incrementTotalCompleted();
      await repository.incrementTotalCompleted();
      await repository.incrementTotalCompleted();

      final result = await repository.getTotalCompleted();
      expect(result, 3);
    });
  });

  group('AchievementRepository - Best moves', () {
    test('returns null when no best moves for 3x3', () async {
      final result = await repository.getBestMoves(3);
      expect(result, isNull);
    });

    test('updates best moves for 3x3 grid', () async {
      await repository.updateBestMoves(3, 50);

      final result = await repository.getBestMoves(3);
      expect(result, 50);
    });

    test('updates to lower moves for 3x3', () async {
      await repository.updateBestMoves(3, 100);
      await repository.updateBestMoves(3, 50);

      final result = await repository.getBestMoves(3);
      expect(result, 50);
    });

    test('does not update to higher moves for 3x3', () async {
      await repository.updateBestMoves(3, 50);
      await repository.updateBestMoves(3, 100);

      final result = await repository.getBestMoves(3);
      expect(result, 50);
    });

    test('updates best moves for 4x4 grid', () async {
      await repository.updateBestMoves(4, 200);

      final result = await repository.getBestMoves(4);
      expect(result, 200);
    });

    test('updates best moves for 5x5 grid', () async {
      await repository.updateBestMoves(5, 500);

      final result = await repository.getBestMoves(5);
      expect(result, 500);
    });

    test('maintains separate best moves for each grid size', () async {
      await repository.updateBestMoves(3, 50);
      await repository.updateBestMoves(4, 200);
      await repository.updateBestMoves(5, 500);

      expect(await repository.getBestMoves(3), 50);
      expect(await repository.getBestMoves(4), 200);
      expect(await repository.getBestMoves(5), 500);
    });

    test('returns null for unsupported grid size', () async {
      await repository.updateBestMoves(6, 100); // Unsupported size
      final result = await repository.getBestMoves(6);
      expect(result, isNull);
    });
  });

  group('AchievementRepository - Best time', () {
    test('returns null when no best time for 3x3', () async {
      final result = await repository.getBestTime(3);
      expect(result, isNull);
    });

    test('updates best time for 3x3 grid', () async {
      await repository.updateBestTime(3, 60);

      final result = await repository.getBestTime(3);
      expect(result, 60);
    });

    test('updates to lower time for 3x3', () async {
      await repository.updateBestTime(3, 120);
      await repository.updateBestTime(3, 60);

      final result = await repository.getBestTime(3);
      expect(result, 60);
    });

    test('does not update to higher time for 3x3', () async {
      await repository.updateBestTime(3, 60);
      await repository.updateBestTime(3, 120);

      final result = await repository.getBestTime(3);
      expect(result, 60);
    });

    test('updates overall best time', () async {
      await repository.updateBestTime(3, 60);

      final result = await repository.getBestOverallTime();
      expect(result, 60);
    });

    test(
      'updates overall best time when improving across grid sizes',
      () async {
        await repository.updateBestTime(3, 100);
        await repository.updateBestTime(4, 80);
        await repository.updateBestTime(5, 50);

        final result = await repository.getBestOverallTime();
        expect(result, 50);
      },
    );

    test('maintains separate best times for each grid size', () async {
      await repository.updateBestTime(3, 60);
      await repository.updateBestTime(4, 120);
      await repository.updateBestTime(5, 180);

      expect(await repository.getBestTime(3), 60);
      expect(await repository.getBestTime(4), 120);
      expect(await repository.getBestTime(5), 180);
    });

    test('returns null for unsupported grid size', () async {
      await repository.updateBestTime(6, 100);
      final result = await repository.getBestTime(6);
      expect(result, isNull);
    });
  });

  group('AchievementRepository - Achievements', () {
    test(
      'returns false for unlocked achievement that does not exist',
      () async {
        final result = await repository.isAchievementUnlocked('first_win');
        expect(result, false);
      },
    );

    test('unlocks an achievement', () async {
      await repository.unlockAchievement('first_win');

      final result = await repository.isAchievementUnlocked('first_win');
      expect(result, true);
    });

    test('unlocking twice keeps achievement unlocked', () async {
      await repository.unlockAchievement('puzzle_master');
      await repository.unlockAchievement('puzzle_master');

      final result = await repository.isAchievementUnlocked('puzzle_master');
      expect(result, true);
    });

    test('unlocks multiple achievements independently', () async {
      await repository.unlockAchievement('first_win');
      await repository.unlockAchievement('puzzle_fan');
      await repository.unlockAchievement('speed_demon');

      expect(await repository.isAchievementUnlocked('first_win'), true);
      expect(await repository.isAchievementUnlocked('puzzle_fan'), true);
      expect(await repository.isAchievementUnlocked('speed_demon'), true);
    });

    test('getAllAchievements returns status for all provided IDs', () async {
      await repository.unlockAchievement('first_win');
      await repository.unlockAchievement('puzzle_master');

      final results = await repository.getAllAchievements([
        'first_win',
        'puzzle_master',
        'speed_demon',
      ]);

      expect(results['first_win'], true);
      expect(results['puzzle_master'], true);
      expect(results['speed_demon'], false);
    });

    test('getAllAchievements returns empty map for empty list', () async {
      final results = await repository.getAllAchievements([]);
      expect(results, isEmpty);
    });

    test(
      'getAllAchievements returns all false when no achievements unlocked',
      () async {
        final results = await repository.getAllAchievements([
          'first_win',
          'puzzle_fan',
        ]);

        expect(results['first_win'], false);
        expect(results['puzzle_fan'], false);
      },
    );
  });

  group('AchievementRepository - 2048 stats', () {
    test('returns default stats when no 2048 games played', () async {
      final stats = await repository.get2048Stats();

      expect(stats['bestScore'], 0);
      expect(stats['highestTile'], 0);
      expect(stats['lastLevelPassed'], 'None');
      expect(stats['gamesPlayed'], 0);
    });

    test('saves 2048 stats', () async {
      await repository.save2048Stats(
        score: 1000,
        highestTile: 512,
        levelPassed: 'Level 3',
      );

      final stats = await repository.get2048Stats();

      expect(stats['bestScore'], 1000);
      expect(stats['highestTile'], 512);
      expect(stats['lastLevelPassed'], 'Level 3');
      expect(stats['gamesPlayed'], 1);
    });

    test('updates best score when new score is higher', () async {
      await repository.save2048Stats(
        score: 1000,
        highestTile: 256,
        levelPassed: 'Level 1',
      );
      await repository.save2048Stats(
        score: 2000,
        highestTile: 512,
        levelPassed: 'Level 2',
      );

      final stats = await repository.get2048Stats();
      expect(stats['bestScore'], 2000);
    });

    test('keeps best score when new score is lower', () async {
      await repository.save2048Stats(
        score: 2000,
        highestTile: 512,
        levelPassed: 'Level 2',
      );
      await repository.save2048Stats(
        score: 1000,
        highestTile: 256,
        levelPassed: 'Level 1',
      );

      final stats = await repository.get2048Stats();
      expect(stats['bestScore'], 2000);
    });

    test('updates highest tile when new tile is higher', () async {
      await repository.save2048Stats(
        score: 1000,
        highestTile: 256,
        levelPassed: 'Level 1',
      );
      await repository.save2048Stats(
        score: 1500,
        highestTile: 512,
        levelPassed: 'Level 2',
      );

      final stats = await repository.get2048Stats();
      expect(stats['highestTile'], 512);
    });

    test('keeps highest tile when new tile is lower', () async {
      await repository.save2048Stats(
        score: 1000,
        highestTile: 512,
        levelPassed: 'Level 2',
      );
      await repository.save2048Stats(
        score: 1500,
        highestTile: 256,
        levelPassed: 'Level 1',
      );

      final stats = await repository.get2048Stats();
      expect(stats['highestTile'], 512);
    });

    test('increments games played on each save', () async {
      await repository.save2048Stats(
        score: 1000,
        highestTile: 256,
        levelPassed: 'Level 1',
      );
      await repository.save2048Stats(
        score: 1500,
        highestTile: 512,
        levelPassed: 'Level 2',
      );
      await repository.save2048Stats(
        score: 2000,
        highestTile: 1024,
        levelPassed: 'Level 3',
      );

      final stats = await repository.get2048Stats();
      expect(stats['gamesPlayed'], 3);
    });

    test('updates last level passed on each save', () async {
      await repository.save2048Stats(
        score: 1000,
        highestTile: 256,
        levelPassed: 'Level 1',
      );
      await repository.save2048Stats(
        score: 1500,
        highestTile: 512,
        levelPassed: 'Level 2',
      );

      final stats = await repository.get2048Stats();
      expect(stats['lastLevelPassed'], 'Level 2');
    });

    test('handles reaching 2048 tile', () async {
      await repository.save2048Stats(
        score: 5000,
        highestTile: 2048,
        levelPassed: 'Level 5',
      );

      final stats = await repository.get2048Stats();
      expect(stats['highestTile'], 2048);
    });

    test('handles reaching 4096 tile', () async {
      await repository.save2048Stats(
        score: 10000,
        highestTile: 4096,
        levelPassed: 'Level 7',
      );

      final stats = await repository.get2048Stats();
      expect(stats['highestTile'], 4096);
    });
  });

  group('AchievementRepository - getAllStats', () {
    test('returns default stats when nothing is saved', () async {
      final stats = await repository.getAllStats();

      expect(stats['totalCompleted'], 0);
      expect(stats['best3x3Moves'], isNull);
      expect(stats['best4x4Moves'], isNull);
      expect(stats['best5x5Moves'], isNull);
      expect(stats['best3x3Time'], isNull);
      expect(stats['best4x4Time'], isNull);
      expect(stats['best5x5Time'], isNull);
      expect(stats['bestOverallTime'], isNull);
    });

    test('returns all saved stats', () async {
      await repository.incrementTotalCompleted();
      await repository.updateBestMoves(3, 50);
      await repository.updateBestMoves(4, 200);
      await repository.updateBestTime(3, 60);
      await repository.updateBestTime(4, 120);

      final stats = await repository.getAllStats();

      expect(stats['totalCompleted'], 1);
      expect(stats['best3x3Moves'], 50);
      expect(stats['best4x4Moves'], 200);
      expect(stats['best5x5Moves'], isNull);
      expect(stats['best3x3Time'], 60);
      expect(stats['best4x4Time'], 120);
      expect(stats['best5x5Time'], isNull);
      expect(stats['bestOverallTime'], 60);
    });
  });

  group('AchievementRepository - resetAll', () {
    test('clears all data', () async {
      // Save various data
      await repository.incrementTotalCompleted();
      await repository.updateBestMoves(3, 50);
      await repository.updateBestTime(3, 60);
      await repository.unlockAchievement('first_win');
      await repository.save2048Stats(
        score: 1000,
        highestTile: 512,
        levelPassed: 'Level 2',
      );

      // Reset
      await repository.resetAll();

      // Verify all cleared
      expect(await repository.getTotalCompleted(), 0);
      expect(await repository.getBestMoves(3), isNull);
      expect(await repository.getBestTime(3), isNull);
      expect(await repository.isAchievementUnlocked('first_win'), false);

      final stats2048 = await repository.get2048Stats();
      expect(stats2048['bestScore'], 0);
      expect(stats2048['gamesPlayed'], 0);
    });

    test('allows saving new data after reset', () async {
      await repository.incrementTotalCompleted();
      await repository.resetAll();

      await repository.incrementTotalCompleted();
      expect(await repository.getTotalCompleted(), 1);
    });
  });

  group('AchievementRepository - Integration scenarios', () {
    test('complete game workflow with achievements', () async {
      // Play first game
      await repository.incrementTotalCompleted();
      await repository.updateBestMoves(3, 100);
      await repository.updateBestTime(3, 120);

      // Unlock first achievement
      await repository.unlockAchievement('first_win');

      // Play better game
      await repository.incrementTotalCompleted();
      await repository.updateBestMoves(3, 80);
      await repository.updateBestTime(3, 90);

      // Verify stats
      expect(await repository.getTotalCompleted(), 2);
      expect(await repository.getBestMoves(3), 80);
      expect(await repository.getBestTime(3), 90);
      expect(await repository.isAchievementUnlocked('first_win'), true);
    });

    test('play multiple grid sizes', () async {
      // 3x3 games
      await repository.updateBestMoves(3, 50);
      await repository.updateBestTime(3, 60);

      // 4x4 games
      await repository.updateBestMoves(4, 200);
      await repository.updateBestTime(4, 180);

      // 5x5 games
      await repository.updateBestMoves(5, 500);
      await repository.updateBestTime(5, 300);

      // Verify independence
      expect(await repository.getBestMoves(3), 50);
      expect(await repository.getBestMoves(4), 200);
      expect(await repository.getBestMoves(5), 500);
      expect(await repository.getBestTime(3), 60);
      expect(await repository.getBestTime(4), 180);
      expect(await repository.getBestTime(5), 300);
      expect(await repository.getBestOverallTime(), 60);
    });

    test('2048 game progression', () async {
      // First game
      await repository.save2048Stats(
        score: 500,
        highestTile: 128,
        levelPassed: 'Level 1',
      );

      // Better game
      await repository.save2048Stats(
        score: 1000,
        highestTile: 256,
        levelPassed: 'Level 2',
      );

      // Best game
      await repository.save2048Stats(
        score: 2000,
        highestTile: 512,
        levelPassed: 'Level 3',
      );

      // Worse game (shouldn't update best)
      await repository.save2048Stats(
        score: 800,
        highestTile: 256,
        levelPassed: 'Level 2',
      );

      final stats = await repository.get2048Stats();
      expect(stats['bestScore'], 2000);
      expect(stats['highestTile'], 512);
      expect(stats['lastLevelPassed'], 'Level 2'); // Last played
      expect(stats['gamesPlayed'], 4);
    });

    test('achievement unlocking progression', () async {
      // Unlock achievements as player progresses
      await repository.unlockAchievement('first_win');
      await repository.incrementTotalCompleted();

      await repository.incrementTotalCompleted();
      await repository.incrementTotalCompleted();
      await repository.incrementTotalCompleted();
      await repository.incrementTotalCompleted();
      await repository.unlockAchievement('puzzle_fan'); // 5 completions

      await repository.updateBestMoves(3, 50);
      await repository.unlockAchievement('efficient_3x3');

      await repository.updateBestTime(3, 45);
      await repository.unlockAchievement('speed_demon');

      final achievements = await repository.getAllAchievements([
        'first_win',
        'puzzle_fan',
        'efficient_3x3',
        'speed_demon',
        'puzzle_master', // Not unlocked
      ]);

      expect(achievements['first_win'], true);
      expect(achievements['puzzle_fan'], true);
      expect(achievements['efficient_3x3'], true);
      expect(achievements['speed_demon'], true);
      expect(achievements['puzzle_master'], false);
    });
  });
}
