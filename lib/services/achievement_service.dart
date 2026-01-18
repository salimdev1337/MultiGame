import 'package:shared_preferences/shared_preferences.dart';

class AchievementService {
  static const String _totalCompletedKey = 'total_completed';
  static const String _best3x3MovesKey = 'best_3x3_moves';
  static const String _best4x4MovesKey = 'best_4x4_moves';
  static const String _best5x5MovesKey = 'best_5x5_moves';
  static const String _best3x3TimeKey = 'best_3x3_time';
  static const String _best4x4TimeKey = 'best_4x4_time';
  static const String _best5x5TimeKey = 'best_5x5_time';
  static const String _bestOverallTimeKey = 'best_overall_time';
  static const String _achievementPrefix = 'achievement_';

  // Get total completed puzzles
  Future<int> getTotalCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalCompletedKey) ?? 0;
  }

  // Increment total completed puzzles
  Future<void> incrementTotalCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_totalCompletedKey) ?? 0;
    await prefs.setInt(_totalCompletedKey, current + 1);
  }

  // Update best moves for a grid size
  Future<void> updateBestMoves(int gridSize, int moves) async {
    final prefs = await SharedPreferences.getInstance();
    String key;
    switch (gridSize) {
      case 3:
        key = _best3x3MovesKey;
        break;
      case 4:
        key = _best4x4MovesKey;
        break;
      case 5:
        key = _best5x5MovesKey;
        break;
      default:
        return;
    }

    final currentBest = prefs.getInt(key);
    if (currentBest == null || moves < currentBest) {
      await prefs.setInt(key, moves);
    }
  }

  // Get best moves for a grid size
  Future<int?> getBestMoves(int gridSize) async {
    final prefs = await SharedPreferences.getInstance();
    String key;
    switch (gridSize) {
      case 3:
        key = _best3x3MovesKey;
        break;
      case 4:
        key = _best4x4MovesKey;
        break;
      case 5:
        key = _best5x5MovesKey;
        break;
      default:
        return null;
    }
    return prefs.getInt(key);
  }

  // Update best time for a grid size
  Future<void> updateBestTime(int gridSize, int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    String key;
    switch (gridSize) {
      case 3:
        key = _best3x3TimeKey;
        break;
      case 4:
        key = _best4x4TimeKey;
        break;
      case 5:
        key = _best5x5TimeKey;
        break;
      default:
        return;
    }

    final currentBest = prefs.getInt(key);
    if (currentBest == null || seconds < currentBest) {
      await prefs.setInt(key, seconds);
    }

    // Also update overall best time
    final overallBest = prefs.getInt(_bestOverallTimeKey);
    if (overallBest == null || seconds < overallBest) {
      await prefs.setInt(_bestOverallTimeKey, seconds);
    }
  }

  // Get best time for a grid size
  Future<int?> getBestTime(int gridSize) async {
    final prefs = await SharedPreferences.getInstance();
    String key;
    switch (gridSize) {
      case 3:
        key = _best3x3TimeKey;
        break;
      case 4:
        key = _best4x4TimeKey;
        break;
      case 5:
        key = _best5x5TimeKey;
        break;
      default:
        return null;
    }
    return prefs.getInt(key);
  }

  // Get overall best time
  Future<int?> getBestOverallTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_bestOverallTimeKey);
  }

  // Check and unlock achievements based on current stats
  Future<Map<String, bool>> checkAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final totalCompleted = await getTotalCompleted();
    final best3x3Moves = await getBestMoves(3);
    final best4x4Moves = await getBestMoves(4);
    final bestTime = await getBestOverallTime();

    final achievements = <String, bool>{};

    // First Victory
    if (totalCompleted >= 1) {
      achievements['first_win'] = true;
      await _unlockAchievement('first_win');
    }

    // Puzzle Fan
    if (totalCompleted >= 5) {
      achievements['puzzle_fan'] = true;
      await _unlockAchievement('puzzle_fan');
    }

    // Puzzle Master
    if (totalCompleted >= 10) {
      achievements['puzzle_master'] = true;
      await _unlockAchievement('puzzle_master');
    }

    // 3x3 Expert
    if (best3x3Moves != null && best3x3Moves < 100) {
      achievements['efficient_3x3'] = true;
      await _unlockAchievement('efficient_3x3');
    }

    // 4x4 Pro
    if (best4x4Moves != null && best4x4Moves < 200) {
      achievements['efficient_4x4'] = true;
      await _unlockAchievement('efficient_4x4');
    }

    // Speed Demon
    if (bestTime != null && bestTime < 60) {
      achievements['speed_demon'] = true;
      await _unlockAchievement('speed_demon');
    }

    // Also get previously unlocked achievements
    for (final achievementId in [
      'first_win',
      'puzzle_fan',
      'puzzle_master',
      'efficient_3x3',
      'efficient_4x4',
      'speed_demon',
    ]) {
      if (!achievements.containsKey(achievementId)) {
        achievements[achievementId] =
            prefs.getBool('$_achievementPrefix$achievementId') ?? false;
      }
    }

    return achievements;
  }

  // Unlock a specific achievement
  Future<void> _unlockAchievement(String achievementId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_achievementPrefix$achievementId', true);
  }

  // Record a game completion
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
    final prefs = await SharedPreferences.getInstance();

    final totalCompleted = await getTotalCompleted();

    // Check each achievement
    if (totalCompleted == 1 && !_isAchievementUnlocked('first_win', prefs)) {
      await _unlockAchievement('first_win');
      newAchievements.add('First Victory');
    }

    if (totalCompleted == 5 && !_isAchievementUnlocked('puzzle_fan', prefs)) {
      await _unlockAchievement('puzzle_fan');
      newAchievements.add('Puzzle Fan');
    }

    if (totalCompleted == 10 &&
        !_isAchievementUnlocked('puzzle_master', prefs)) {
      await _unlockAchievement('puzzle_master');
      newAchievements.add('Puzzle Master');
    }

    if (gridSize == 3 &&
        moves < 100 &&
        !_isAchievementUnlocked('efficient_3x3', prefs)) {
      await _unlockAchievement('efficient_3x3');
      newAchievements.add('3x3 Expert');
    }

    if (gridSize == 4 &&
        moves < 200 &&
        !_isAchievementUnlocked('efficient_4x4', prefs)) {
      await _unlockAchievement('efficient_4x4');
      newAchievements.add('4x4 Pro');
    }

    if (seconds < 60 && !_isAchievementUnlocked('speed_demon', prefs)) {
      await _unlockAchievement('speed_demon');
      newAchievements.add('Speed Demon');
    }

    return newAchievements;
  }

  bool _isAchievementUnlocked(String achievementId, SharedPreferences prefs) {
    return prefs.getBool('$_achievementPrefix$achievementId') ?? false;
  }

  // Save 2048 game achievement
  Future<void> save2048Achievement({
    required int score,
    required int highestTile,
    required String levelPassed,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Save best score for 2048
    final currentBest2048Score = prefs.getInt('best_2048_score');
    if (currentBest2048Score == null || score > currentBest2048Score) {
      await prefs.setInt('best_2048_score', score);
    }

    // Save highest tile achieved
    final currentHighestTile = prefs.getInt('highest_2048_tile');
    if (currentHighestTile == null || highestTile > currentHighestTile) {
      await prefs.setInt('highest_2048_tile', highestTile);
    }

    // Save level passed
    await prefs.setString('last_2048_level_passed', levelPassed);

    // Track total 2048 games played
    final gamesPlayed = prefs.getInt('total_2048_games') ?? 0;
    await prefs.setInt('total_2048_games', gamesPlayed + 1);

    // Unlock 2048-specific achievements
    if (highestTile >= 512 && !_isAchievementUnlocked('2048_beginner', prefs)) {
      await _unlockAchievement('2048_beginner');
    }
    if (highestTile >= 1024 &&
        !_isAchievementUnlocked('2048_intermediate', prefs)) {
      await _unlockAchievement('2048_intermediate');
    }
    if (highestTile >= 2048 &&
        !_isAchievementUnlocked('2048_advanced', prefs)) {
      await _unlockAchievement('2048_advanced');
    }
    if (highestTile >= 4096 && !_isAchievementUnlocked('2048_master', prefs)) {
      await _unlockAchievement('2048_master');
    }
  }

  // Get 2048 game stats
  Future<Map<String, dynamic>> get2048Stats() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'bestScore': prefs.getInt('best_2048_score') ?? 0,
      'highestTile': prefs.getInt('highest_2048_tile') ?? 0,
      'lastLevelPassed': prefs.getString('last_2048_level_passed') ?? 'None',
      'gamesPlayed': prefs.getInt('total_2048_games') ?? 0,
    };
  }

  // Get all stats
  Future<Map<String, dynamic>> getAllStats() async {
    return {
      'totalCompleted': await getTotalCompleted(),
      'best3x3Moves': await getBestMoves(3),
      'best4x4Moves': await getBestMoves(4),
      'best5x5Moves': await getBestMoves(5),
      'best3x3Time': await getBestTime(3),
      'best4x4Time': await getBestTime(4),
      'best5x5Time': await getBestTime(5),
      'bestOverallTime': await getBestOverallTime(),
    };
  }

  // Reset all achievements and stats (for testing)
  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Get all 2048 achievements
  Future<Map<String, bool>> getAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      '2048_beginner': _isAchievementUnlocked('2048_beginner', prefs),
      '2048_intermediate': _isAchievementUnlocked('2048_intermediate', prefs),
      '2048_advanced': _isAchievementUnlocked('2048_advanced', prefs),
      '2048_master': _isAchievementUnlocked('2048_master', prefs),
    };
  }
}
