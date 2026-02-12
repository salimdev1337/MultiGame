import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service for tracking and retrieving rank changes over time
/// Stores rank snapshots with timestamps for each game type
class RankHistoryService {
  static const String _keyPrefix = 'rank_history_';

  /// Save current rank for a specific game type
  Future<void> saveRankSnapshot({
    required String gameType,
    required String userId,
    required int currentRank,
    required int totalPlayers,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix${gameType}_$userId';

    // Get existing history
    final existingData = prefs.getString(key);
    List<RankSnapshot> history = [];

    if (existingData != null) {
      final List<dynamic> decoded = json.decode(existingData);
      history = decoded.map((e) => RankSnapshot.fromJson(e)).toList();
    }

    // Check if rank has changed since last snapshot
    if (history.isNotEmpty && history.last.rank == currentRank) {
      // Rank hasn't changed, no need to save
      return;
    }

    // Add new snapshot
    final snapshot = RankSnapshot(
      rank: currentRank,
      totalPlayers: totalPlayers,
      timestamp: DateTime.now(),
    );
    history.add(snapshot);

    // Keep only last 50 snapshots to prevent unbounded growth
    if (history.length > 50) {
      history = history.sublist(history.length - 50);
    }

    // Save updated history
    await prefs.setString(key, json.encode(history.map((e) => e.toJson()).toList()));
  }

  /// Get the previous rank for a specific game type
  /// Returns null if there's no history or only one snapshot
  Future<int?> getPreviousRank({
    required String gameType,
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix${gameType}_$userId';

    final existingData = prefs.getString(key);
    if (existingData == null) return null;

    final List<dynamic> decoded = json.decode(existingData);
    final List<RankSnapshot> history =
        decoded.map((e) => RankSnapshot.fromJson(e)).toList();

    // Need at least 2 snapshots to have a previous rank
    if (history.length < 2) return null;

    return history[history.length - 2].rank;
  }

  /// Get full rank history for a specific game type
  Future<List<RankSnapshot>> getRankHistory({
    required String gameType,
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix${gameType}_$userId';

    final existingData = prefs.getString(key);
    if (existingData == null) return [];

    final List<dynamic> decoded = json.decode(existingData);
    return decoded.map((e) => RankSnapshot.fromJson(e)).toList();
  }

  /// Clear rank history for a specific game type
  Future<void> clearHistory({
    required String gameType,
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix${gameType}_$userId';
    await prefs.remove(key);
  }

  /// Clear all rank history for a user
  Future<void> clearAllHistory({required String userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    for (final key in keys) {
      if (key.startsWith(_keyPrefix) && key.endsWith('_$userId')) {
        await prefs.remove(key);
      }
    }
  }
}

/// Represents a single rank snapshot at a point in time
class RankSnapshot {
  final int rank;
  final int totalPlayers;
  final DateTime timestamp;

  RankSnapshot({
    required this.rank,
    required this.totalPlayers,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'totalPlayers': totalPlayers,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory RankSnapshot.fromJson(Map<String, dynamic> json) {
    return RankSnapshot(
      rank: json['rank'] as int,
      totalPlayers: json['totalPlayers'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
