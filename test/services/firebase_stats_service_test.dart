/// Firebase Stats Repository Tests
///
/// Tests UserStats / GameStats model serialization using FakeFirebaseFirestore
/// and FirebaseStatsRepository (which accepts an injected FirebaseFirestore).
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/repositories/stats_repository.dart';

void main() {
  group('GameStats serialization', () {
    test('toMap / fromMap round-trip with lastPlayed', () {
      final now = DateTime(2026, 2, 16, 12, 0, 0);
      final original = GameStats(
        gamesPlayed: 5,
        highScore: 1000,
        totalScore: 3500,
        lastPlayed: now,
      );

      final map = original.toMap();
      final restored = GameStats.fromMap(map);

      expect(restored.gamesPlayed, original.gamesPlayed);
      expect(restored.highScore, original.highScore);
      expect(restored.totalScore, original.totalScore);
      expect(restored.lastPlayed, isNotNull);
      // Timestamps round-trip through seconds precision
      expect(
        restored.lastPlayed!.millisecondsSinceEpoch ~/ 1000,
        original.lastPlayed!.millisecondsSinceEpoch ~/ 1000,
      );
    });

    test('toMap / fromMap round-trip without lastPlayed', () {
      final original = GameStats(
        gamesPlayed: 0,
        highScore: 0,
        totalScore: 0,
      );

      final map = original.toMap();
      final restored = GameStats.fromMap(map);

      expect(restored.gamesPlayed, 0);
      expect(restored.highScore, 0);
      expect(restored.totalScore, 0);
      expect(restored.lastPlayed, isNull);
    });

    test('fromMap handles missing keys with defaults', () {
      final restored = GameStats.fromMap({});

      expect(restored.gamesPlayed, 0);
      expect(restored.highScore, 0);
      expect(restored.totalScore, 0);
      expect(restored.lastPlayed, isNull);
    });

    test('toMap produces the expected keys', () {
      final stats = GameStats(gamesPlayed: 3, highScore: 500, totalScore: 900);
      final map = stats.toMap();

      expect(map.containsKey('gamesPlayed'), isTrue);
      expect(map.containsKey('highScore'), isTrue);
      expect(map.containsKey('totalScore'), isTrue);
      expect(map.containsKey('lastPlayed'), isTrue);
      expect(map['gamesPlayed'], 3);
      expect(map['highScore'], 500);
      expect(map['totalScore'], 900);
      expect(map['lastPlayed'], isNull);
    });
  });

  group('UserStats serialization via FakeFirebaseFirestore', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('toFirestore / fromFirestore round-trip preserves scalar fields', () async {
      final now = DateTime(2026, 2, 16, 10, 30, 0);
      final gameStats = {
        'sudoku': GameStats(
          gamesPlayed: 10,
          highScore: 2000,
          totalScore: 15000,
          lastPlayed: now,
        ),
      };

      final original = UserStats(
        userId: 'user-abc',
        displayName: 'Alice',
        totalGamesPlayed: 10,
        totalScore: 15000,
        lastPlayed: now,
        gameStats: gameStats,
      );

      // Write the document using toFirestore() output
      final docRef = fakeFirestore.collection('users').doc('user-abc');
      await docRef.set(original.toFirestore());

      // Read it back and parse with fromFirestore
      final doc = await docRef.get();
      final restored = UserStats.fromFirestore(doc);

      expect(restored.userId, 'user-abc');
      expect(restored.displayName, 'Alice');
      expect(restored.totalGamesPlayed, 10);
      expect(restored.totalScore, 15000);
      expect(restored.gameStats.containsKey('sudoku'), isTrue);
      expect(restored.gameStats['sudoku']!.highScore, 2000);
      expect(restored.gameStats['sudoku']!.gamesPlayed, 10);
    });

    test('fromFirestore handles null displayName', () async {
      final docRef = fakeFirestore.collection('users').doc('user-no-name');
      // Use an explicitly typed map so FakeFirebaseFirestore preserves types
      await docRef.set(<String, Object?>{
        'totalGamesPlayed': 1,
        'totalScore': 100,
        'lastPlayed': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'gameStats': <String, Object?>{},
      });

      final doc = await docRef.get();
      final stats = UserStats.fromFirestore(doc);

      expect(stats.displayName, isNull);
      expect(stats.totalGamesPlayed, 1);
    });

    test('fromFirestore uses current time when lastPlayed is absent', () async {
      final before = DateTime.now().subtract(const Duration(seconds: 2));
      final docRef = fakeFirestore.collection('users').doc('user-no-time');
      // Use an explicitly typed map so FakeFirebaseFirestore preserves types
      await docRef.set(<String, Object?>{
        'totalGamesPlayed': 0,
        'totalScore': 0,
        // intentionally omit lastPlayed
        'gameStats': <String, Object?>{},
      });

      final doc = await docRef.get();
      final stats = UserStats.fromFirestore(doc);

      // fromFirestore defaults to DateTime.now() when field is absent
      expect(stats.lastPlayed.isAfter(before), isTrue);
    });

    test('toFirestore includes all expected keys', () {
      final stats = UserStats(
        userId: 'u1',
        displayName: 'Bob',
        totalGamesPlayed: 7,
        totalScore: 5000,
        lastPlayed: DateTime(2026, 2, 1),
        gameStats: {},
      );

      final map = stats.toFirestore();

      expect(map.containsKey('displayName'), isTrue);
      expect(map.containsKey('totalGamesPlayed'), isTrue);
      expect(map.containsKey('totalScore'), isTrue);
      expect(map.containsKey('lastPlayed'), isTrue);
      expect(map.containsKey('gameStats'), isTrue);
      expect(map['displayName'], 'Bob');
      expect(map['totalGamesPlayed'], 7);
      expect(map['totalScore'], 5000);
    });
  });

  group('FirebaseStatsRepository with FakeFirebaseFirestore', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirebaseStatsRepository repository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = FirebaseStatsRepository(firestore: fakeFirestore);
    });

    test('getUserStats returns null when user does not exist', () async {
      final result = await repository.getUserStats('nonexistent-user');
      expect(result, isNull);
    });

    test('saveUserStats creates a new document for a new user', () async {
      await repository.saveUserStats(
        userId: 'player-1',
        displayName: 'Carol',
        gameType: 'sudoku',
        score: 750,
      );

      final stats = await repository.getUserStats('player-1');

      expect(stats, isNotNull);
      expect(stats!.userId, 'player-1');
      expect(stats.totalGamesPlayed, 1);
      expect(stats.totalScore, 750);
      expect(stats.gameStats.containsKey('sudoku'), isTrue);
      expect(stats.gameStats['sudoku']!.gamesPlayed, 1);
      expect(stats.gameStats['sudoku']!.highScore, 750);
    });

    test('saveUserStats updates an existing user and tracks high score', () async {
      // First game
      await repository.saveUserStats(
        userId: 'player-2',
        displayName: 'Dave',
        gameType: 'snake',
        score: 300,
      );

      // Second game — lower score, should not replace high score
      await repository.saveUserStats(
        userId: 'player-2',
        displayName: 'Dave',
        gameType: 'snake',
        score: 100,
      );

      final stats = await repository.getUserStats('player-2');
      expect(stats, isNotNull);
      expect(stats!.totalGamesPlayed, 2);
      expect(stats.totalScore, 400);
      expect(stats.gameStats['snake']!.highScore, 300);
      expect(stats.gameStats['snake']!.gamesPlayed, 2);
    });

    test('saveUserStats updates high score when new score is higher', () async {
      await repository.saveUserStats(
        userId: 'player-3',
        displayName: 'Eve',
        gameType: '2048',
        score: 500,
      );

      await repository.saveUserStats(
        userId: 'player-3',
        displayName: 'Eve',
        gameType: '2048',
        score: 1500,
      );

      final stats = await repository.getUserStats('player-3');
      expect(stats!.gameStats['2048']!.highScore, 1500);
    });

    test('userStatsStream emits null for non-existent user then emits after save', () async {
      // Collect two emissions: the initial null and the post-save update.
      final futureItems = repository
          .userStatsStream('stream-user')
          .take(2)
          .toList();

      // Allow the first (null) snapshot to arrive before writing
      await Future.delayed(const Duration(milliseconds: 50));

      await repository.saveUserStats(
        userId: 'stream-user',
        displayName: 'Frank',
        gameType: 'puzzle',
        score: 200,
      );

      final items = await futureItems;
      expect(items.length, 2);
      expect(items[0], isNull);
      expect(items[1], isNotNull);
      expect(items[1]!.totalGamesPlayed, 1);
    });

    test('getLeaderboard returns empty list when no entries exist', () async {
      final entries = await repository.getLeaderboard(gameType: 'memory_game');
      expect(entries, isEmpty);
    });

    test('getLeaderboard returns entries after saving scores', () async {
      await repository.saveUserStats(
        userId: 'lb-user-1',
        displayName: 'Grace',
        gameType: 'memory_game',
        score: 800,
      );
      await repository.saveUserStats(
        userId: 'lb-user-2',
        displayName: 'Hank',
        gameType: 'memory_game',
        score: 1200,
      );

      final entries = await repository.getLeaderboard(gameType: 'memory_game');
      expect(entries.length, 2);
      // Highest score first
      expect(entries.first.highScore, greaterThanOrEqualTo(entries.last.highScore));
    });

    test('LeaderboardEntry.fromFirestore parses document correctly', () async {
      final docRef = fakeFirestore
          .collection('leaderboard')
          .doc('sudoku')
          .collection('scores')
          .doc('lb-parse-user');

      await docRef.set({
        'userId': 'lb-parse-user',
        'displayName': 'Iris',
        'highScore': 999,
        'lastUpdated': Timestamp.fromDate(DateTime(2026, 2, 10)),
      });

      final doc = await docRef.get();
      final entry = LeaderboardEntry.fromFirestore(doc);

      expect(entry.userId, 'lb-parse-user');
      expect(entry.displayName, 'Iris');
      expect(entry.highScore, 999);
      expect(entry.lastUpdated, isNotNull);
    });

    test('LeaderboardEntry.fromFirestore falls back to anonymous when displayName absent', () async {
      final docRef = fakeFirestore
          .collection('leaderboard')
          .doc('snake')
          .collection('scores')
          .doc('anon-user');

      await docRef.set({
        'highScore': 42,
      });

      final doc = await docRef.get();
      final entry = LeaderboardEntry.fromFirestore(doc);

      expect(entry.displayName, 'Anonymous');
      expect(entry.highScore, 42);
    });
  });
}
