import 'package:shared_preferences/shared_preferences.dart';
import 'package:multigame/utils/secure_logger.dart';

/// Service for tracking user's daily play streak
/// A streak is maintained by playing at least once each day
class StreakService {
  static const String _keyLastPlayDate = 'streak_last_play_date';
  static const String _keyCurrentStreak = 'streak_current_count';
  static const String _keyLongestStreak = 'streak_longest_count';
  static const String _keyTotalDaysPlayed = 'streak_total_days_played';

  /// Update streak when user plays a game
  /// Call this whenever a user completes a game/puzzle
  Future<StreakData> updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Get last play date
    final lastPlayDateStr = prefs.getString(_keyLastPlayDate);
    final currentStreak = prefs.getInt(_keyCurrentStreak) ?? 0;
    final longestStreak = prefs.getInt(_keyLongestStreak) ?? 0;
    final totalDaysPlayed = prefs.getInt(_keyTotalDaysPlayed) ?? 0;

    int newStreak = currentStreak;
    int newLongestStreak = longestStreak;
    int newTotalDaysPlayed = totalDaysPlayed;

    if (lastPlayDateStr == null) {
      // First time playing
      newStreak = 1;
      newLongestStreak = 1;
      newTotalDaysPlayed = 1;
      SecureLogger.log('Streak: First play');
    } else {
      final lastPlayDate = DateTime.parse(lastPlayDateStr);
      final lastPlay = DateTime(
        lastPlayDate.year,
        lastPlayDate.month,
        lastPlayDate.day,
      );
      final daysDifference = today.difference(lastPlay).inDays;

      if (daysDifference == 0) {
        // Already played today, no change
        SecureLogger.log('Streak: Already played today');
      } else if (daysDifference == 1) {
        // Consecutive day
        newStreak = currentStreak + 1;
        newTotalDaysPlayed = totalDaysPlayed + 1;
        if (newStreak > longestStreak) {
          newLongestStreak = newStreak;
        }
        SecureLogger.log('Streak: Increased to $newStreak days');
      } else {
        // Streak broken
        newStreak = 1;
        newTotalDaysPlayed = totalDaysPlayed + 1;
        SecureLogger.log('Streak: Broken, restarting at 1 day');
      }
    }

    // Save updated values
    await prefs.setString(_keyLastPlayDate, today.toIso8601String());
    await prefs.setInt(_keyCurrentStreak, newStreak);
    await prefs.setInt(_keyLongestStreak, newLongestStreak);
    await prefs.setInt(_keyTotalDaysPlayed, newTotalDaysPlayed);

    return StreakData(
      currentStreak: newStreak,
      longestStreak: newLongestStreak,
      totalDaysPlayed: newTotalDaysPlayed,
      lastPlayDate: today,
    );
  }

  /// Get current streak data without updating
  Future<StreakData> getStreakData() async {
    final prefs = await SharedPreferences.getInstance();

    final lastPlayDateStr = prefs.getString(_keyLastPlayDate);
    final currentStreak = prefs.getInt(_keyCurrentStreak) ?? 0;
    final longestStreak = prefs.getInt(_keyLongestStreak) ?? 0;
    final totalDaysPlayed = prefs.getInt(_keyTotalDaysPlayed) ?? 0;

    // Check if streak is still valid
    if (lastPlayDateStr != null) {
      final lastPlayDate = DateTime.parse(lastPlayDateStr);
      final lastPlay = DateTime(
        lastPlayDate.year,
        lastPlayDate.month,
        lastPlayDate.day,
      );
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final daysDifference = today.difference(lastPlay).inDays;

      // If more than 1 day has passed, streak is broken but we don't update here
      // We'll show 0 but keep the old value in storage until next play
      if (daysDifference > 1) {
        return StreakData(
          currentStreak: 0, // Show as broken
          longestStreak: longestStreak,
          totalDaysPlayed: totalDaysPlayed,
          lastPlayDate: lastPlay,
          isStreakBroken: true,
        );
      }
    }

    return StreakData(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      totalDaysPlayed: totalDaysPlayed,
      lastPlayDate: lastPlayDateStr != null
          ? DateTime.parse(lastPlayDateStr)
          : null,
    );
  }

  /// Reset all streak data (for testing or user request)
  Future<void> resetStreak() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastPlayDate);
    await prefs.remove(_keyCurrentStreak);
    await prefs.remove(_keyLongestStreak);
    await prefs.remove(_keyTotalDaysPlayed);
    SecureLogger.log('Streak: Reset all data');
  }
}

/// Data class for streak information
class StreakData {
  final int currentStreak;
  final int longestStreak;
  final int totalDaysPlayed;
  final DateTime? lastPlayDate;
  final bool isStreakBroken;

  StreakData({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalDaysPlayed,
    this.lastPlayDate,
    this.isStreakBroken = false,
  });

  /// Format streak for display (e.g., "7d", "0d")
  String get formattedStreak => '${currentStreak}d';

  /// Get a user-friendly message about the streak
  String get streakMessage {
    if (currentStreak == 0) {
      return 'Start playing today to begin your streak!';
    } else if (currentStreak == 1) {
      return 'Great start! Play tomorrow to continue your streak.';
    } else if (currentStreak < 7) {
      return '$currentStreak day streak! Keep it up!';
    } else if (currentStreak < 30) {
      return 'Amazing! $currentStreak day streak! 🔥';
    } else {
      return 'Legendary! $currentStreak day streak! 🌟';
    }
  }

  /// Check if user played today
  bool get playedToday {
    if (lastPlayDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return lastPlayDate!.isAtSameMomentAs(today);
  }

  @override
  String toString() {
    return 'StreakData(current: $currentStreak, longest: $longestStreak, total: $totalDaysPlayed)';
  }
}
