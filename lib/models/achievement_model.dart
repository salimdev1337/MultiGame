class AchievementModel {
  final String id;
  final String title;
  final String description;
  final String icon;
  final bool isUnlocked;
  final int? currentProgress;
  final int? targetProgress;

  AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    this.currentProgress,
    this.targetProgress,
  });

  AchievementModel copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    bool? isUnlocked,
    int? currentProgress,
    int? targetProgress,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      currentProgress: currentProgress ?? this.currentProgress,
      targetProgress: targetProgress ?? this.targetProgress,
    );
  }

  static List<AchievementModel> getAllAchievements({
    required Map<String, bool> unlockedStatus,
    required int totalCompleted,
    required int? best3x3Moves,
    required int? best4x4Moves,
    required int? bestTime,
  }) {
    return [
      AchievementModel(
        id: 'first_win',
        title: 'First Victory',
        description: 'Complete your first puzzle',
        icon: '🎉',
        isUnlocked: unlockedStatus['first_win'] ?? false,
        currentProgress: totalCompleted > 0 ? 1 : 0,
        targetProgress: 1,
      ),
      AchievementModel(
        id: 'puzzle_fan',
        title: 'Puzzle Fan',
        description: 'Complete 5 puzzles',
        icon: '🎮',
        isUnlocked: unlockedStatus['puzzle_fan'] ?? false,
        currentProgress: totalCompleted,
        targetProgress: 5,
      ),
      AchievementModel(
        id: 'puzzle_master',
        title: 'Puzzle Master',
        description: 'Complete 10 puzzles',
        icon: '🏆',
        isUnlocked: unlockedStatus['puzzle_master'] ?? false,
        currentProgress: totalCompleted,
        targetProgress: 10,
      ),
      AchievementModel(
        id: 'efficient_3x3',
        title: '3x3 Expert',
        description: 'Complete 3x3 puzzle in under 100 moves',
        icon: '⭐',
        isUnlocked: unlockedStatus['efficient_3x3'] ?? false,
        currentProgress: best3x3Moves,
        targetProgress: 100,
      ),
      AchievementModel(
        id: 'efficient_4x4',
        title: '4x4 Pro',
        description: 'Complete 4x4 puzzle in under 200 moves',
        icon: '💎',
        isUnlocked: unlockedStatus['efficient_4x4'] ?? false,
        currentProgress: best4x4Moves,
        targetProgress: 200,
      ),
      AchievementModel(
        id: 'speed_demon',
        title: 'Speed Demon',
        description: 'Complete any puzzle in under 60 seconds',
        icon: '⚡',
        isUnlocked: unlockedStatus['speed_demon'] ?? false,
        currentProgress: bestTime,
        targetProgress: 60,
      ),
    ];
  }
}
