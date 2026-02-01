import 'package:multigame/repositories/stats_repository.dart';

// Re-export models from repository for backward compatibility
export 'package:multigame/repositories/stats_repository.dart'
    show UserStats, GameStats, LeaderboardEntry;

/// Service for managing user statistics in Firestore
///
/// This service now uses StatsRepository for data persistence,
/// providing a cleaner separation of concerns and making it easier to test.
class FirebaseStatsService {
  final StatsRepository _statsRepository;

  FirebaseStatsService({
    StatsRepository? statsRepository,
  }) : _statsRepository = statsRepository ?? FirebaseStatsRepository();

  /// Save or update user statistics
  Future<void> saveUserStats({
    required String userId,
    String? displayName,
    required String gameType,
    required int score,
  }) async {
    return await _statsRepository.saveUserStats(
      userId: userId,
      displayName: displayName,
      gameType: gameType,
      score: score,
    );
  }

  /// Get user statistics
  Future<UserStats?> getUserStats(String userId) async {
    return await _statsRepository.getUserStats(userId);
  }

  /// Get user statistics stream for real-time updates
  Stream<UserStats?> userStatsStream(String userId) {
    return _statsRepository.userStatsStream(userId);
  }

  /// Get leaderboard for a specific game
  Future<List<LeaderboardEntry>> getLeaderboard({
    required String gameType,
    int limit = 100,
  }) async {
    return await _statsRepository.getLeaderboard(
      gameType: gameType,
      limit: limit,
    );
  }

  /// Get user's rank in leaderboard
  Future<int?> getUserRank({
    required String userId,
    required String gameType,
  }) async {
    return await _statsRepository.getUserRank(
      userId: userId,
      gameType: gameType,
    );
  }

  /// Stream of leaderboard updates
  Stream<List<LeaderboardEntry>> leaderboardStream({
    required String gameType,
    int limit = 100,
  }) {
    return _statsRepository.leaderboardStream(
      gameType: gameType,
      limit: limit,
    );
  }
}