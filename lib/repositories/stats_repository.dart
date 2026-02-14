import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multigame/utils/secure_logger.dart';

/// Model for user statistics
class UserStats {
  final String userId;
  final String? displayName;
  final int totalGamesPlayed;
  final int totalScore;
  final DateTime lastPlayed;
  final Map<String, GameStats> gameStats;

  UserStats({
    required this.userId,
    this.displayName,
    required this.totalGamesPlayed,
    required this.totalScore,
    required this.lastPlayed,
    required this.gameStats,
  });

  factory UserStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserStats(
      userId: doc.id,
      displayName: data['displayName'] as String?,
      totalGamesPlayed: data['totalGamesPlayed'] ?? 0,
      totalScore: data['totalScore'] ?? 0,
      lastPlayed: data['lastPlayed'] != null
          ? (data['lastPlayed'] as Timestamp).toDate()
          : DateTime.now(),
      gameStats: (data['gameStats'] as Map<String, dynamic>? ?? {}).map(
        (key, value) =>
            MapEntry(key, GameStats.fromMap(value as Map<String, dynamic>)),
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'totalGamesPlayed': totalGamesPlayed,
      'totalScore': totalScore,
      'lastPlayed': Timestamp.fromDate(lastPlayed),
      'gameStats': gameStats.map((key, value) => MapEntry(key, value.toMap())),
    };
  }
}

/// Model for individual game statistics
class GameStats {
  final int gamesPlayed;
  final int highScore;
  final int totalScore;
  final DateTime? lastPlayed;

  GameStats({
    required this.gamesPlayed,
    required this.highScore,
    required this.totalScore,
    this.lastPlayed,
  });

  factory GameStats.fromMap(Map<String, dynamic> map) {
    return GameStats(
      gamesPlayed: map['gamesPlayed'] ?? 0,
      highScore: map['highScore'] ?? 0,
      totalScore: map['totalScore'] ?? 0,
      lastPlayed: map['lastPlayed'] != null
          ? (map['lastPlayed'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gamesPlayed': gamesPlayed,
      'highScore': highScore,
      'totalScore': totalScore,
      'lastPlayed': lastPlayed != null ? Timestamp.fromDate(lastPlayed!) : null,
    };
  }
}

/// Model for leaderboard entry
class LeaderboardEntry {
  final String userId;
  final String displayName;
  final int highScore;
  final DateTime? lastUpdated;

  LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.highScore,
    this.lastUpdated,
  });

  factory LeaderboardEntry.fromFirestore(DocumentSnapshot doc) {
    final raw = doc.data();
    if (raw == null || raw is! Map<String, dynamic>) {
      throw StateError('Unexpected Firestore document format for ${doc.id}');
    }
    final data = raw;
    return LeaderboardEntry(
      userId: data['userId'] ?? doc.id,
      displayName: data['displayName'] ?? 'Anonymous',
      highScore: data['highScore'] ?? 0,
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : null,
    );
  }
}

/// Abstract interface for game statistics persistence
///
/// This repository handles user statistics and leaderboard data.
abstract class StatsRepository {
  /// Save or update user statistics for a game
  Future<void> saveUserStats({
    required String userId,
    String? displayName,
    required String gameType,
    required int score,
  });

  /// Get user statistics
  Future<UserStats?> getUserStats(String userId);

  /// Stream of user statistics for real-time updates
  Stream<UserStats?> userStatsStream(String userId);

  /// Get leaderboard for a specific game
  Future<List<LeaderboardEntry>> getLeaderboard({
    required String gameType,
    int limit = 100,
  });

  /// Get user's rank in a game's leaderboard
  Future<int?> getUserRank({required String userId, required String gameType});

  /// Stream of leaderboard updates
  Stream<List<LeaderboardEntry>> leaderboardStream({
    required String gameType,
    int limit = 100,
  });
}

/// Firebase implementation of StatsRepository
///
/// Stores statistics and leaderboard data in Firestore.
class FirebaseStatsRepository implements StatsRepository {
  final FirebaseFirestore _firestore;

  static const String _usersCollection = 'users';
  static const String _leaderboardCollection = 'leaderboard';

  FirebaseStatsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> saveUserStats({
    required String userId,
    String? displayName,
    required String gameType,
    required int score,
  }) async {
    try {
      final userRef = _firestore.collection(_usersCollection).doc(userId);
      final doc = await userRef.get();

      if (!doc.exists) {
        // Create new user document
        await userRef.set({
          'displayName': displayName,
          'totalGamesPlayed': 1,
          'totalScore': score,
          'lastPlayed': FieldValue.serverTimestamp(),
          'gameStats': {
            gameType: {
              'gamesPlayed': 1,
              'highScore': score,
              'totalScore': score,
              'lastPlayed': FieldValue.serverTimestamp(),
            },
          },
        });
      } else {
        // Update existing user document
        final data = doc.data()!;
        final gameStats = data['gameStats'] as Map<String, dynamic>? ?? {};
        final currentGameStats =
            gameStats[gameType] as Map<String, dynamic>? ??
            {'gamesPlayed': 0, 'highScore': 0, 'totalScore': 0};

        final newHighScore = score > (currentGameStats['highScore'] ?? 0)
            ? score
            : currentGameStats['highScore'];

        await userRef.update({
          'displayName': displayName ?? data['displayName'],
          'totalGamesPlayed': FieldValue.increment(1),
          'totalScore': FieldValue.increment(score),
          'lastPlayed': FieldValue.serverTimestamp(),
          'gameStats.$gameType': {
            'gamesPlayed': FieldValue.increment(1),
            'highScore': newHighScore,
            'totalScore': FieldValue.increment(score),
            'lastPlayed': FieldValue.serverTimestamp(),
          },
        });
      }

      // Update leaderboard
      await _updateLeaderboard(
        userId: userId,
        displayName: displayName,
        gameType: gameType,
        score: score,
      );
    } catch (e) {
      SecureLogger.error(
        'Failed to save user stats',
        error: e,
        tag: 'StatsRepository',
      );
      rethrow;
    }
  }

  /// Internal method to update leaderboard
  Future<void> _updateLeaderboard({
    required String userId,
    String? displayName,
    required String gameType,
    required int score,
  }) async {
    try {
      final leaderboardRef = _firestore
          .collection(_leaderboardCollection)
          .doc(gameType)
          .collection('scores')
          .doc(userId);

      final doc = await leaderboardRef.get();
      final currentHighScore = doc.data()?['highScore'] ?? 0;

      if (!doc.exists) {
        await leaderboardRef.set({
          'userId': userId,
          'displayName': displayName ?? 'Anonymous',
          'highScore': score,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else if (score > currentHighScore) {
        SecureLogger.firebase(
          'Updating leaderboard',
          details: 'New high score',
        );
        await leaderboardRef.set({
          'userId': userId,
          'displayName': displayName ?? 'Anonymous',
          'highScore': score,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        SecureLogger.firebase(
          'Score not higher than current high score, skipping update',
        );
      }
    } catch (e) {
      SecureLogger.error(
        'Failed to update leaderboard',
        error: e,
        tag: 'StatsRepository',
      );
    }
  }

  @override
  Future<UserStats?> getUserStats(String userId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return UserStats.fromFirestore(doc);
    } catch (e) {
      SecureLogger.error(
        'Failed to get user stats',
        error: e,
        tag: 'StatsRepository',
      );
      return null;
    }
  }

  @override
  Stream<UserStats?> userStatsStream(String userId) {
    return _firestore
        .collection(_usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            return null;
          }
          return UserStats.fromFirestore(doc);
        })
        .handleError((error) {
          SecureLogger.error(
            'Error in user stats stream',
            tag: 'StatsRepository',
          );
          return null;
        });
  }

  @override
  Future<List<LeaderboardEntry>> getLeaderboard({
    required String gameType,
    int limit = 100,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_leaderboardCollection)
          .doc(gameType)
          .collection('scores')
          .orderBy('highScore', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => LeaderboardEntry.fromFirestore(doc))
          .toList();
    } catch (e) {
      SecureLogger.error(
        'Failed to get leaderboard',
        error: e,
        tag: 'StatsRepository',
      );
      return [];
    }
  }

  @override
  Future<int?> getUserRank({
    required String userId,
    required String gameType,
  }) async {
    try {
      final userDoc = await _firestore
          .collection(_leaderboardCollection)
          .doc(gameType)
          .collection('scores')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return null;
      }

      final userScore = userDoc.data()?['highScore'] ?? 0;

      final higherScoresCount = await _firestore
          .collection(_leaderboardCollection)
          .doc(gameType)
          .collection('scores')
          .where('highScore', isGreaterThan: userScore)
          .count()
          .get();

      return (higherScoresCount.count ?? 0) + 1;
    } catch (e) {
      SecureLogger.error(
        'Failed to get user rank',
        error: e,
        tag: 'StatsRepository',
      );
      return null;
    }
  }

  @override
  Stream<List<LeaderboardEntry>> leaderboardStream({
    required String gameType,
    int limit = 100,
  }) {
    return _firestore
        .collection(_leaderboardCollection)
        .doc(gameType)
        .collection('scores')
        .orderBy('highScore', descending: true)
        .limit(limit)
        .snapshots()
        .handleError((error) {
          SecureLogger.error(
            'Leaderboard stream error',
            error: error,
            tag: 'StatsRepository',
          );
          throw error;
        })
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LeaderboardEntry.fromFirestore(doc))
              .toList(),
        );
  }
}
