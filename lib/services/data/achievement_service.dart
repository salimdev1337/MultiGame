import 'package:multigame/repositories/achievement_repository.dart';

/// Service for managing achievements and game statistics
///
/// This service now uses AchievementRepository for data persistence,
/// while maintaining business logic for achievement unlocking and validation.
class AchievementService {
  final AchievementRepository _repository;

  AchievementService({AchievementRepository? repository})
    : _repository = repository ?? SharedPrefsAchievementRepository();

  // ========== Puzzle Game Methods ==========

  /// Get total completed puzzles
  Future<int> getTotalCompleted() async {
    return await _repository.getTotalCompleted();
  }

  /// Increment total completed puzzles
  Future<void> incrementTotalCompleted() async {
    await _repository.incrementTotalCompleted();
  }

  /// Update best moves for a grid size
  Future<void> updateBestMoves(int gridSize, int moves) async {
    await _repository.updateBestMoves(gridSize, moves);
  }

  /// Get best moves for a grid size
  Future<int?> getBestMoves(int gridSize) async {
    return await _repository.getBestMoves(gridSize);
  }

  /// Update best time for a grid size
  Future<void> updateBestTime(int gridSize, int seconds) async {
    await _repository.updateBestTime(gridSize, seconds);
  }

  /// Get best time for a grid size
  Future<int?> getBestTime(int gridSize) async {
    return await _repository.getBestTime(gridSize);
  }

  /// Get overall best time
  Future<int?> getBestOverallTime() async {
    return await _repository.getBestOverallTime();
  }

  // ========== Achievement Methods ==========

  /// Check and unlock puzzle + 2048 achievements based on current local stats.
  /// Use [checkAllAchievements] for the full set including streak and per-game.
  Future<Map<String, bool>> checkAchievements() async {
    final totalCompleted = await getTotalCompleted();
    final best3x3Moves = await getBestMoves(3);
    final best4x4Moves = await getBestMoves(4);
    final bestTime = await getBestOverallTime();

    final achievements = <String, bool>{};

    // First Victory
    if (totalCompleted >= 1) {
      achievements['first_win'] = true;
      await _repository.unlockAchievement('first_win');
    }

    // Puzzle Fan
    if (totalCompleted >= 5) {
      achievements['puzzle_fan'] = true;
      await _repository.unlockAchievement('puzzle_fan');
    }

    // Puzzle Master
    if (totalCompleted >= 10) {
      achievements['puzzle_master'] = true;
      await _repository.unlockAchievement('puzzle_master');
    }

    // 3x3 Expert
    if (best3x3Moves != null && best3x3Moves < 100) {
      achievements['efficient_3x3'] = true;
      await _repository.unlockAchievement('efficient_3x3');
    }

    // 4x4 Pro
    if (best4x4Moves != null && best4x4Moves < 200) {
      achievements['efficient_4x4'] = true;
      await _repository.unlockAchievement('efficient_4x4');
    }

    // Speed Demon
    if (bestTime != null && bestTime < 60) {
      achievements['speed_demon'] = true;
      await _repository.unlockAchievement('speed_demon');
    }

    // Also get previously unlocked achievements
    final allAchievementIds = [
      'first_win',
      'puzzle_fan',
      'puzzle_master',
      'efficient_3x3',
      'efficient_4x4',
      'speed_demon',
    ];

    final previousAchievements = await _repository.getAllAchievements(
      allAchievementIds,
    );
    for (final entry in previousAchievements.entries) {
      if (!achievements.containsKey(entry.key)) {
        achievements[entry.key] = entry.value;
      }
    }

    return achievements;
  }

  /// Check and unlock ALL achievements including streak and per-game ones.
  ///
  /// Call this on profile load. Pass [currentStreak] from StreakService and
  /// [gamePlayCounts] (gameType → gamesPlayed) from Firebase stats.
  /// [highestTile2048] comes from local 2048 stats.
  Future<Map<String, bool>> checkAllAchievements({
    int currentStreak = 0,
    int highestTile2048 = 0,
    Map<String, int> gamePlayCounts = const {},
  }) async {
    // Run base puzzle checks first
    final achievements = await checkAchievements();

    // ── 2048 tile achievements ────────────────────────────────────────────
    if (highestTile2048 >= 2048) {
      achievements['score_2048'] = true;
      await _repository.unlockAchievement('score_2048');
    }
    if (highestTile2048 >= 4096) {
      achievements['score_4096'] = true;
      await _repository.unlockAchievement('score_4096');
    }

    // ── Streak achievements ───────────────────────────────────────────────
    if (currentStreak >= 3) {
      achievements['streak_3'] = true;
      await _repository.unlockAchievement('streak_3');
    }
    if (currentStreak >= 7) {
      achievements['streak_7'] = true;
      await _repository.unlockAchievement('streak_7');
    }
    if (currentStreak >= 30) {
      achievements['streak_30'] = true;
      await _repository.unlockAchievement('streak_30');
    }

    // ── Per-game first-play achievements ─────────────────────────────────
    Future<void> checkFirstPlay(String gameKey, String achievementId) async {
      if ((gamePlayCounts[gameKey] ?? 0) >= 1) {
        achievements[achievementId] = true;
        await _repository.unlockAchievement(achievementId);
      }
    }

    await checkFirstPlay('sudoku', 'sudoku_first');
    await checkFirstPlay('memory', 'memory_first');
    await checkFirstPlay('snake', 'snake_first');
    await checkFirstPlay('runner', 'runner_first');
    await checkFirstPlay('bomberman', 'bomberman_first');
    await checkFirstPlay('wordle', 'wordle_first');
    await checkFirstPlay('connect_four', 'connect_four_first');

    // ── Multitasker: all 9 games played ─────────────────────────────────
    final totalCompleted = await getTotalCompleted();
    int gamesPlayedCount = 0;
    if (totalCompleted > 0) gamesPlayedCount++;
    if (highestTile2048 > 0) gamesPlayedCount++;
    for (final count in gamePlayCounts.values) {
      if (count > 0) gamesPlayedCount++;
    }
    if (gamesPlayedCount >= 9) {
      achievements['all_games'] = true;
      await _repository.unlockAchievement('all_games');
    }

    // Merge in previously stored status for all new achievement IDs
    final newIds = [
      'score_2048',
      'score_4096',
      'streak_3',
      'streak_7',
      'streak_30',
      'sudoku_first',
      'memory_first',
      'snake_first',
      'runner_first',
      'bomberman_first',
      'wordle_first',
      'connect_four_first',
      'all_games',
    ];
    final stored = await _repository.getAllAchievements(newIds);
    for (final entry in stored.entries) {
      if (!achievements.containsKey(entry.key)) {
        achievements[entry.key] = entry.value;
      }
    }

    return achievements;
  }

  /// Record a game completion and return newly unlocked achievements
  Future<List<String>> recordGameCompletion({
    required int gridSize,
    required int moves,
    required int seconds,
  }) async {
    await incrementTotalCompleted();
    await updateBestMoves(gridSize, moves);
    await updateBestTime(gridSize, seconds);

    // Check for newly unlocked achievements
    final newAchievements = <String>[];
    final totalCompleted = await getTotalCompleted();

    // Check each achievement
    if (totalCompleted == 1 &&
        !await _repository.isAchievementUnlocked('first_win')) {
      await _repository.unlockAchievement('first_win');
      newAchievements.add('First Victory');
    }

    if (totalCompleted == 5 &&
        !await _repository.isAchievementUnlocked('puzzle_fan')) {
      await _repository.unlockAchievement('puzzle_fan');
      newAchievements.add('Puzzle Fan');
    }

    if (totalCompleted == 10 &&
        !await _repository.isAchievementUnlocked('puzzle_master')) {
      await _repository.unlockAchievement('puzzle_master');
      newAchievements.add('Puzzle Master');
    }

    if (gridSize == 3 &&
        moves < 100 &&
        !await _repository.isAchievementUnlocked('efficient_3x3')) {
      await _repository.unlockAchievement('efficient_3x3');
      newAchievements.add('3x3 Expert');
    }

    if (gridSize == 4 &&
        moves < 200 &&
        !await _repository.isAchievementUnlocked('efficient_4x4')) {
      await _repository.unlockAchievement('efficient_4x4');
      newAchievements.add('4x4 Pro');
    }

    if (seconds < 60 &&
        !await _repository.isAchievementUnlocked('speed_demon')) {
      await _repository.unlockAchievement('speed_demon');
      newAchievements.add('Speed Demon');
    }

    return newAchievements;
  }

  // ========== 2048 Game Methods ==========

  /// Save 2048 game achievement
  Future<void> save2048Achievement({
    required int score,
    required int highestTile,
    required String levelPassed,
  }) async {
    await _repository.save2048Stats(
      score: score,
      highestTile: highestTile,
      levelPassed: levelPassed,
    );

    // Unlock 2048-specific achievements
    if (highestTile >= 512 &&
        !await _repository.isAchievementUnlocked('2048_beginner')) {
      await _repository.unlockAchievement('2048_beginner');
    }
    if (highestTile >= 1024 &&
        !await _repository.isAchievementUnlocked('2048_intermediate')) {
      await _repository.unlockAchievement('2048_intermediate');
    }
    if (highestTile >= 2048 &&
        !await _repository.isAchievementUnlocked('2048_advanced')) {
      await _repository.unlockAchievement('2048_advanced');
    }
    if (highestTile >= 4096 &&
        !await _repository.isAchievementUnlocked('2048_master')) {
      await _repository.unlockAchievement('2048_master');
    }
  }

  /// Get 2048 game stats
  Future<Map<String, dynamic>> get2048Stats() async {
    return await _repository.get2048Stats();
  }

  /// Get all 2048 achievements
  Future<Map<String, bool>> getAchievements() async {
    final achievementIds = [
      '2048_beginner',
      '2048_intermediate',
      '2048_advanced',
      '2048_master',
    ];
    return await _repository.getAllAchievements(achievementIds);
  }

  // ========== General Methods ==========

  /// Get all stats
  Future<Map<String, dynamic>> getAllStats() async {
    return await _repository.getAllStats();
  }

  /// Reset all achievements and stats (for testing)
  Future<void> resetAll() async {
    await _repository.resetAll();
  }
}
