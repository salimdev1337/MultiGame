import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/services/data/achievement_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AchievementService Tests', () {
    late AchievementService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = AchievementService();
    });

    test('getTotalCompleted returns 0 initially', () async {
      final total = await service.getTotalCompleted();
      expect(total, 0);
    });

    test('incrementTotalCompleted increases count', () async {
      await service.incrementTotalCompleted();
      final total = await service.getTotalCompleted();
      expect(total, 1);

      await service.incrementTotalCompleted();
      final total2 = await service.getTotalCompleted();
      expect(total2, 2);
    });

    test('updateBestMoves saves best moves for grid size', () async {
      await service.updateBestMoves(3, 50);
      final best = await service.getBestMoves(3);
      expect(best, 50);

      // Better score should update
      await service.updateBestMoves(3, 40);
      final best2 = await service.getBestMoves(3);
      expect(best2, 40);

      // Worse score should not update
      await service.updateBestMoves(3, 60);
      final best3 = await service.getBestMoves(3);
      expect(best3, 40);
    });

    test('getBestMoves returns null if not set', () async {
      final best = await service.getBestMoves(3);
      expect(best, null);
    });

    test('updateBestTime saves best time for grid size', () async {
      await service.updateBestTime(4, 120);
      final best = await service.getBestTime(4);
      expect(best, 120);

      // Better time should update
      await service.updateBestTime(4, 100);
      final best2 = await service.getBestTime(4);
      expect(best2, 100);

      // Worse time should not update
      await service.updateBestTime(4, 150);
      final best3 = await service.getBestTime(4);
      expect(best3, 100);
    });

    test('updateBestTime updates overall best time', () async {
      await service.updateBestTime(3, 80);
      final overallBest = await service.getBestOverallTime();
      expect(overallBest, 80);

      await service.updateBestTime(4, 60);
      final overallBest2 = await service.getBestOverallTime();
      expect(overallBest2, 60);
    });

    test('checkAchievements returns correct status based on stats', () async {
      // Complete one puzzle
      await service.recordGameCompletion(gridSize: 3, moves: 50, seconds: 120);

      final achievements = await service.checkAchievements();
      expect(achievements['first_win'], true);
      expect(achievements['puzzle_fan'], false);
      expect(achievements['puzzle_master'], false);
    });

    test(
      'recordGameCompletion updates stats and returns new achievements',
      () async {
        final achievements = await service.recordGameCompletion(
          gridSize: 3,
          moves: 50,
          seconds: 120,
        );

        expect(achievements.contains('First Victory'), true);

        final total = await service.getTotalCompleted();
        expect(total, 1);

        final bestMoves = await service.getBestMoves(3);
        expect(bestMoves, 50);

        final bestTime = await service.getBestTime(3);
        expect(bestTime, 120);
      },
    );

    test('recordGameCompletion unlocks multiple achievements', () async {
      // Complete 5 puzzles
      for (int i = 0; i < 5; i++) {
        await service.recordGameCompletion(
          gridSize: 3,
          moves: 50,
          seconds: 120,
        );
      }

      final achievements = await service.checkAchievements();
      expect(achievements['first_win'], true);
      expect(achievements['puzzle_fan'], true);
      expect(achievements['puzzle_master'], false);
    });

    test('recordGameCompletion unlocks efficiency achievements', () async {
      await service.recordGameCompletion(gridSize: 3, moves: 80, seconds: 120);

      final achievements = await service.checkAchievements();
      expect(achievements['efficient_3x3'], true);
    });

    test('recordGameCompletion unlocks speed achievement', () async {
      await service.recordGameCompletion(gridSize: 3, moves: 100, seconds: 50);

      final achievements = await service.checkAchievements();
      expect(achievements['speed_demon'], true);
    });

    test('getAllStats returns all statistics', () async {
      await service.recordGameCompletion(gridSize: 3, moves: 50, seconds: 120);
      await service.recordGameCompletion(gridSize: 4, moves: 100, seconds: 200);

      final stats = await service.getAllStats();
      expect(stats['totalCompleted'], 2);
      expect(stats['best3x3Moves'], 50);
      expect(stats['best4x4Moves'], 100);
      expect(stats['best3x3Time'], 120);
      expect(stats['best4x4Time'], 200);
      expect(stats['bestOverallTime'], 120);
    });

    test('resetAll clears all data', () async {
      await service.recordGameCompletion(gridSize: 3, moves: 50, seconds: 120);

      await service.resetAll();

      final total = await service.getTotalCompleted();
      expect(total, 0);

      final achievements = await service.checkAchievements();
      expect(achievements['first_win'], false);
    });
  });
}
