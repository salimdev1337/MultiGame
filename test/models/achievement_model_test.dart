import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/models/achievement_model.dart';

void main() {
  group('AchievementModel', () {
    test('creates achievement with all properties', () {
      final achievement = AchievementModel(
        id: 'test_achievement',
        title: 'Test Achievement',
        description: 'Test description',
        icon: '🏆',
        isUnlocked: true,
        currentProgress: 5,
        targetProgress: 10,
      );

      expect(achievement.id, 'test_achievement');
      expect(achievement.title, 'Test Achievement');
      expect(achievement.description, 'Test description');
      expect(achievement.icon, '🏆');
      expect(achievement.isUnlocked, true);
      expect(achievement.currentProgress, 5);
      expect(achievement.targetProgress, 10);
    });

    test('copyWith creates new instance with updated values', () {
      final original = AchievementModel(
        id: 'test',
        title: 'Original',
        description: 'Original desc',
        icon: '🎮',
        isUnlocked: false,
        currentProgress: 0,
        targetProgress: 10,
      );

      final updated = original.copyWith(isUnlocked: true, currentProgress: 5);

      expect(updated.id, original.id);
      expect(updated.title, original.title);
      expect(updated.isUnlocked, true);
      expect(updated.currentProgress, 5);
      expect(updated.targetProgress, 10);
    });

    test('getAllAchievements returns correct list', () {
      final achievements = AchievementModel.getAllAchievements(
        unlockedStatus: {'first_win': true, 'puzzle_fan': false},
        totalCompleted: 3,
        best3x3Moves: 80,
        best4x4Moves: 150,
        bestTime: 45,
      );

      // 10 completion + 2 efficiency + 1 speed + 2 score + 3 streak + 1 mastery
      expect(achievements.length, 19);
      expect(achievements[0].id, 'first_win');
      expect(achievements[0].isUnlocked, true);
      expect(achievements[1].id, 'puzzle_fan');
      expect(achievements[1].isUnlocked, false);
      expect(achievements[1].currentProgress, 3);
      expect(achievements[1].targetProgress, 5);
    });

    test('first_win achievement shows correct progress', () {
      final achievements = AchievementModel.getAllAchievements(
        unlockedStatus: {},
        totalCompleted: 0,
        best3x3Moves: null,
        best4x4Moves: null,
        bestTime: null,
      );

      final firstWin = achievements.firstWhere((a) => a.id == 'first_win');
      expect(firstWin.currentProgress, 0);
      expect(firstWin.targetProgress, 1);
    });

    test('efficient achievements show move progress', () {
      final achievements = AchievementModel.getAllAchievements(
        unlockedStatus: {'efficient_3x3': true},
        totalCompleted: 5,
        best3x3Moves: 85,
        best4x4Moves: 180,
        bestTime: null,
      );

      final efficient3x3 = achievements.firstWhere(
        (a) => a.id == 'efficient_3x3',
      );
      expect(efficient3x3.isUnlocked, true);
      expect(efficient3x3.currentProgress, 85);
      expect(efficient3x3.targetProgress, 100);

      final efficient4x4 = achievements.firstWhere(
        (a) => a.id == 'efficient_4x4',
      );
      expect(efficient4x4.currentProgress, 180);
      expect(efficient4x4.targetProgress, 200);
    });

    test('speed_demon achievement shows time progress', () {
      final achievements = AchievementModel.getAllAchievements(
        unlockedStatus: {},
        totalCompleted: 1,
        best3x3Moves: null,
        best4x4Moves: null,
        bestTime: 55,
      );

      final speedDemon = achievements.firstWhere((a) => a.id == 'speed_demon');
      expect(speedDemon.currentProgress, 55);
      expect(speedDemon.targetProgress, 60);
    });
  });
}
