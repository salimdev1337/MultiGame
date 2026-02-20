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
    int currentStreak = 0,
    int highestTile2048 = 0,
    Map<String, int> gamePlayCounts = const {},
  }) {
    final sudokuPlayed = gamePlayCounts['sudoku'] ?? 0;
    final memoryPlayed = gamePlayCounts['memory'] ?? 0;
    final snakePlayed = gamePlayCounts['snake'] ?? 0;
    final runnerPlayed = gamePlayCounts['runner'] ?? 0;
    final bombermanPlayed = gamePlayCounts['bomberman'] ?? 0;
    final wordlePlayed = gamePlayCounts['wordle'] ?? 0;
    final connectFourPlayed = gamePlayCounts['connect_four'] ?? 0;

    // Count how many of the 9 games have been played at least once.
    // Puzzle (totalCompleted>0) + 2048 (highestTile2048>0) + Firebase games.
    int gamesPlayedCount = 0;
    if (totalCompleted > 0) {
      gamesPlayedCount++;
    }
    if (highestTile2048 > 0) {
      gamesPlayedCount++;
    }
    if (sudokuPlayed > 0) {
      gamesPlayedCount++;
    }
    if (memoryPlayed > 0) {
      gamesPlayedCount++;
    }
    if (snakePlayed > 0) {
      gamesPlayedCount++;
    }
    if (runnerPlayed > 0) {
      gamesPlayedCount++;
    }
    if (bombermanPlayed > 0) {
      gamesPlayedCount++;
    }
    if (wordlePlayed > 0) {
      gamesPlayedCount++;
    }
    if (connectFourPlayed > 0) {
      gamesPlayedCount++;
    }

    return [
      // ── Completion ─────────────────────────────────────────────────────────
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
        id: 'sudoku_first',
        title: 'Sudoku Starter',
        description: 'Complete your first Sudoku puzzle',
        icon: '🔢',
        isUnlocked: unlockedStatus['sudoku_first'] ?? false,
        currentProgress: sudokuPlayed > 0 ? 1 : 0,
        targetProgress: 1,
      ),
      AchievementModel(
        id: 'memory_first',
        title: 'Memory Champion',
        description: 'Complete your first Memory game',
        icon: '🃏',
        isUnlocked: unlockedStatus['memory_first'] ?? false,
        currentProgress: memoryPlayed > 0 ? 1 : 0,
        targetProgress: 1,
      ),
      AchievementModel(
        id: 'snake_first',
        title: 'Snake Debut',
        description: 'Play your first Snake game',
        icon: '🐍',
        isUnlocked: unlockedStatus['snake_first'] ?? false,
        currentProgress: snakePlayed > 0 ? 1 : 0,
        targetProgress: 1,
      ),
      AchievementModel(
        id: 'runner_first',
        title: 'Running Start',
        description: 'Complete your first Infinite Runner run',
        icon: '🏃',
        isUnlocked: unlockedStatus['runner_first'] ?? false,
        currentProgress: runnerPlayed > 0 ? 1 : 0,
        targetProgress: 1,
      ),
      AchievementModel(
        id: 'bomberman_first',
        title: 'Blast Off',
        description: 'Complete your first Bomberman game',
        icon: '💣',
        isUnlocked: unlockedStatus['bomberman_first'] ?? false,
        currentProgress: bombermanPlayed > 0 ? 1 : 0,
        targetProgress: 1,
      ),
      AchievementModel(
        id: 'wordle_first',
        title: 'Word Wizard',
        description: 'Win your first Wordle Duel',
        icon: '📝',
        isUnlocked: unlockedStatus['wordle_first'] ?? false,
        currentProgress: wordlePlayed > 0 ? 1 : 0,
        targetProgress: 1,
      ),
      AchievementModel(
        id: 'connect_four_first',
        title: 'Four in a Row',
        description: 'Win your first Connect Four game',
        icon: '🔴',
        isUnlocked: unlockedStatus['connect_four_first'] ?? false,
        currentProgress: connectFourPlayed > 0 ? 1 : 0,
        targetProgress: 1,
      ),

      // ── Efficiency ─────────────────────────────────────────────────────────
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

      // ── Speed ──────────────────────────────────────────────────────────────
      AchievementModel(
        id: 'speed_demon',
        title: 'Speed Demon',
        description: 'Complete any puzzle in under 60 seconds',
        icon: '⚡',
        isUnlocked: unlockedStatus['speed_demon'] ?? false,
        currentProgress: bestTime,
        targetProgress: 60,
      ),

      // ── Score ──────────────────────────────────────────────────────────────
      AchievementModel(
        id: 'score_2048',
        title: '2048 Achieved',
        description: 'Reach the 2048 tile',
        icon: '🎯',
        isUnlocked: unlockedStatus['score_2048'] ?? false,
        currentProgress: highestTile2048,
        targetProgress: 2048,
      ),
      AchievementModel(
        id: 'score_4096',
        title: '4096 Master',
        description: 'Reach the 4096 tile',
        icon: '👑',
        isUnlocked: unlockedStatus['score_4096'] ?? false,
        currentProgress: highestTile2048,
        targetProgress: 4096,
      ),

      // ── Streak ─────────────────────────────────────────────────────────────
      AchievementModel(
        id: 'streak_3',
        title: 'Hat Trick',
        description: 'Maintain a 3-day play streak',
        icon: '🔥',
        isUnlocked: unlockedStatus['streak_3'] ?? false,
        currentProgress: currentStreak,
        targetProgress: 3,
      ),
      AchievementModel(
        id: 'streak_7',
        title: 'Weekly Warrior',
        description: 'Maintain a 7-day play streak',
        icon: '📅',
        isUnlocked: unlockedStatus['streak_7'] ?? false,
        currentProgress: currentStreak,
        targetProgress: 7,
      ),
      AchievementModel(
        id: 'streak_30',
        title: 'Monthly Legend',
        description: 'Maintain a 30-day play streak',
        icon: '🌟',
        isUnlocked: unlockedStatus['streak_30'] ?? false,
        currentProgress: currentStreak,
        targetProgress: 30,
      ),

      // ── Mastery ────────────────────────────────────────────────────────────
      AchievementModel(
        id: 'all_games',
        title: 'Multitasker',
        description: 'Play all 9 games at least once',
        icon: '🎪',
        isUnlocked: unlockedStatus['all_games'] ?? false,
        currentProgress: gamesPlayedCount,
        targetProgress: 9,
      ),
    ];
  }
}
