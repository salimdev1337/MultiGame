import 'package:shared_preferences/shared_preferences.dart';

/// Abstract interface for achievement and game stats persistence
///
/// This repository handles local storage of achievements, best scores,
/// and other game-specific statistics using SharedPreferences.
abstract class AchievementRepository {
  // Puzzle game stats
  Future<int> getTotalCompleted();
  Future<void> incrementTotalCompleted();
  Future<void> updateBestMoves(int gridSize, int moves);
  Future<int?> getBestMoves(int gridSize);
  Future<void> updateBestTime(int gridSize, int seconds);
  Future<int?> getBestTime(int gridSize);
  Future<int?> getBestOverallTime();

  // Achievement management
  Future<bool> isAchievementUnlocked(String achievementId);
  Future<void> unlockAchievement(String achievementId);
  Future<Map<String, bool>> getAllAchievements(List<String> achievementIds);

  // 2048 game stats
  Future<void> save2048Stats({
    required int score,
    required int highestTile,
    required String levelPassed,
  });
  Future<Map<String, dynamic>> get2048Stats();

  // General stats
  Future<Map<String, dynamic>> getAllStats();

  // Utility
  Future<void> resetAll();
}

/// SharedPreferences implementation of AchievementRepository
///
/// Stores achievement data and local game statistics in SharedPreferences.
class SharedPrefsAchievementRepository implements AchievementRepository {
  static const String _totalCompletedKey = 'total_completed';
  static const String _best3x3MovesKey = 'best_3x3_moves';
  static const String _best4x4MovesKey = 'best_4x4_moves';
  static const String _best5x5MovesKey = 'best_5x5_moves';
  static const String _best3x3TimeKey = 'best_3x3_time';
  static const String _best4x4TimeKey = 'best_4x4_time';
  static const String _best5x5TimeKey = 'best_5x5_time';
  static const String _bestOverallTimeKey = 'best_overall_time';
  static const String _achievementPrefix = 'achievement_';
  static const String _best2048ScoreKey = 'best_2048_score';
  static const String _highest2048TileKey = 'highest_2048_tile';
  static const String _last2048LevelKey = 'last_2048_level_passed';
  static const String _total2048GamesKey = 'total_2048_games';

  // Cache preferences instance to avoid repeated getInstance() calls
  SharedPreferences? _prefsCache;

  Future<SharedPreferences> get _prefs async {
    _prefsCache ??= await SharedPreferences.getInstance();
    return _prefsCache!;
  }

  @override
  Future<int> getTotalCompleted() async {
    final prefs = await _prefs;
    return prefs.getInt(_totalCompletedKey) ?? 0;
  }

  @override
  Future<void> incrementTotalCompleted() async {
    final prefs = await _prefs;
    final current = prefs.getInt(_totalCompletedKey) ?? 0;
    await prefs.setInt(_totalCompletedKey, current + 1);
  }

  @override
  Future<void> updateBestMoves(int gridSize, int moves) async {
    final prefs = await _prefs;
    final key = _getMovesKey(gridSize);
    if (key == null) return;

    final currentBest = prefs.getInt(key);
    if (currentBest == null || moves < currentBest) {
      await prefs.setInt(key, moves);
    }
  }

  @override
  Future<int?> getBestMoves(int gridSize) async {
    final prefs = await _prefs;
    final key = _getMovesKey(gridSize);
    if (key == null) return null;
    return prefs.getInt(key);
  }

  @override
  Future<void> updateBestTime(int gridSize, int seconds) async {
    final prefs = await _prefs;
    final key = _getTimeKey(gridSize);
    if (key == null) return;

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

  @override
  Future<int?> getBestTime(int gridSize) async {
    final prefs = await _prefs;
    final key = _getTimeKey(gridSize);
    if (key == null) return null;
    return prefs.getInt(key);
  }

  @override
  Future<int?> getBestOverallTime() async {
    final prefs = await _prefs;
    return prefs.getInt(_bestOverallTimeKey);
  }

  @override
  Future<bool> isAchievementUnlocked(String achievementId) async {
    final prefs = await _prefs;
    return prefs.getBool('$_achievementPrefix$achievementId') ?? false;
  }

  @override
  Future<void> unlockAchievement(String achievementId) async {
    final prefs = await _prefs;
    await prefs.setBool('$_achievementPrefix$achievementId', true);
  }

  @override
  Future<Map<String, bool>> getAllAchievements(
      List<String> achievementIds) async {
    final prefs = await _prefs;
    final achievements = <String, bool>{};

    for (final achievementId in achievementIds) {
      achievements[achievementId] =
          prefs.getBool('$_achievementPrefix$achievementId') ?? false;
    }

    return achievements;
  }

  @override
  Future<void> save2048Stats({
    required int score,
    required int highestTile,
    required String levelPassed,
  }) async {
    final prefs = await _prefs;

    // Save best score for 2048
    final currentBest2048Score = prefs.getInt(_best2048ScoreKey);
    if (currentBest2048Score == null || score > currentBest2048Score) {
      await prefs.setInt(_best2048ScoreKey, score);
    }

    // Save highest tile achieved
    final currentHighestTile = prefs.getInt(_highest2048TileKey);
    if (currentHighestTile == null || highestTile > currentHighestTile) {
      await prefs.setInt(_highest2048TileKey, highestTile);
    }

    // Save level passed
    await prefs.setString(_last2048LevelKey, levelPassed);

    // Track total 2048 games played
    final gamesPlayed = prefs.getInt(_total2048GamesKey) ?? 0;
    await prefs.setInt(_total2048GamesKey, gamesPlayed + 1);
  }

  @override
  Future<Map<String, dynamic>> get2048Stats() async {
    final prefs = await _prefs;
    return {
      'bestScore': prefs.getInt(_best2048ScoreKey) ?? 0,
      'highestTile': prefs.getInt(_highest2048TileKey) ?? 0,
      'lastLevelPassed': prefs.getString(_last2048LevelKey) ?? 'None',
      'gamesPlayed': prefs.getInt(_total2048GamesKey) ?? 0,
    };
  }

  @override
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

  @override
  Future<void> resetAll() async {
    final prefs = await _prefs;
    await prefs.clear();
    _prefsCache = null; // Clear cache after reset
  }

  // Helper methods
  String? _getMovesKey(int gridSize) {
    switch (gridSize) {
      case 3:
        return _best3x3MovesKey;
      case 4:
        return _best4x4MovesKey;
      case 5:
        return _best5x5MovesKey;
      default:
        return null;
    }
  }

  String? _getTimeKey(int gridSize) {
    switch (gridSize) {
      case 3:
        return _best3x3TimeKey;
      case 4:
        return _best4x4TimeKey;
      case 5:
        return _best5x5TimeKey;
      default:
        return null;
    }
  }
}