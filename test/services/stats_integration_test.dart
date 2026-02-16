/// Integration test: game score save → UserStats update → leaderboard update.
///
/// Uses [FakeFirebaseFirestore] (no emulator required) to exercise the full
/// [FirebaseStatsRepository] persistence path end-to-end:
///
///   saveUserStats() → UserStats document written
///                   → leaderboard/scores document written
///                   → leaderboardStream() emits updated entry
library;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/repositories/stats_repository.dart';

void main() {
  // ── Score save → UserStats ──────────────────────────────────────────────────

  group('saveUserStats — UserStats document', () {
    test('creates a new UserStats document on first save', () async {
      final db = FakeFirebaseFirestore();
      final repo = FirebaseStatsRepository(firestore: db);

      await repo.saveUserStats(
        userId: 'user-1',
        displayName: 'Alice',
        gameType: '2048',
        score: 2048,
      );

      final stats = await repo.getUserStats('user-1');
      expect(stats, isNotNull);
      expect(stats!.userId, 'user-1');
      expect(stats.displayName, 'Alice');
      expect(stats.totalGamesPlayed, 1);
      expect(stats.totalScore, 2048);
      expect(stats.gameStats['2048']?.gamesPlayed, 1);
      expect(stats.gameStats['2048']?.highScore, 2048);
      expect(stats.gameStats['2048']?.totalScore, 2048);
    });

    test('accumulates score on subsequent saves', () async {
      final db = FakeFirebaseFirestore();
      final repo = FirebaseStatsRepository(firestore: db);

      await repo.saveUserStats(
        userId: 'user-2',
        gameType: 'snake_game',
        score: 100,
      );
      await repo.saveUserStats(
        userId: 'user-2',
        gameType: 'snake_game',
        score: 200,
      );

      final stats = await repo.getUserStats('user-2');
      expect(stats!.totalGamesPlayed, 2);
      expect(stats.totalScore, 300);
      expect(stats.gameStats['snake_game']?.gamesPlayed, 2);
      expect(stats.gameStats['snake_game']?.highScore, 200); // new high
      expect(stats.gameStats['snake_game']?.totalScore, 300);
    });

    test('does not lower the high score when a lower score is saved', () async {
      final db = FakeFirebaseFirestore();
      final repo = FirebaseStatsRepository(firestore: db);

      await repo.saveUserStats(
        userId: 'user-3',
        gameType: '2048',
        score: 5000,
      );
      await repo.saveUserStats(
        userId: 'user-3',
        gameType: '2048',
        score: 1000, // lower
      );

      final stats = await repo.getUserStats('user-3');
      expect(stats!.gameStats['2048']?.highScore, 5000); // unchanged
    });

    test('tracks stats independently per game type', () async {
      final db = FakeFirebaseFirestore();
      final repo = FirebaseStatsRepository(firestore: db);

      await repo.saveUserStats(
        userId: 'user-4',
        gameType: '2048',
        score: 500,
      );
      await repo.saveUserStats(
        userId: 'user-4',
        gameType: 'snake_game',
        score: 300,
      );

      final stats = await repo.getUserStats('user-4');
      expect(stats!.gameStats.length, 2);
      expect(stats.gameStats['2048']?.highScore, 500);
      expect(stats.gameStats['snake_game']?.highScore, 300);
      expect(stats.totalGamesPlayed, 2);
      expect(stats.totalScore, 800);
    });
  });

  // ── Score save → leaderboard ────────────────────────────────────────────────

  group('saveUserStats — leaderboard document', () {
    test('creates a leaderboard entry on first save', () async {
      final db = FakeFirebaseFirestore();
      final repo = FirebaseStatsRepository(firestore: db);

      await repo.saveUserStats(
        userId: 'user-5',
        displayName: 'Bob',
        gameType: '2048',
        score: 4096,
      );

      final leaderboard = await repo.getLeaderboard(gameType: '2048');
      expect(leaderboard.length, 1);
      expect(leaderboard.first.userId, 'user-5');
      expect(leaderboard.first.displayName, 'Bob');
      expect(leaderboard.first.highScore, 4096);
    });

    test('updates leaderboard when a higher score is saved', () async {
      final db = FakeFirebaseFirestore();
      final repo = FirebaseStatsRepository(firestore: db);

      await repo.saveUserStats(
        userId: 'user-6',
        displayName: 'Carol',
        gameType: 'snake_game',
        score: 100,
      );
      await repo.saveUserStats(
        userId: 'user-6',
        displayName: 'Carol',
        gameType: 'snake_game',
        score: 300, // new high
      );

      final leaderboard = await repo.getLeaderboard(gameType: 'snake_game');
      expect(leaderboard.first.highScore, 300);
    });

    test('does not update leaderboard when score is not a new high', () async {
      final db = FakeFirebaseFirestore();
      final repo = FirebaseStatsRepository(firestore: db);

      await repo.saveUserStats(
        userId: 'user-7',
        gameType: '2048',
        score: 8192,
      );
      await repo.saveUserStats(
        userId: 'user-7',
        gameType: '2048',
        score: 1024, // lower — should not overwrite
      );

      final leaderboard = await repo.getLeaderboard(gameType: '2048');
      expect(leaderboard.first.highScore, 8192);
    });

    test('leaderboard orders entries by high score descending', () async {
      final db = FakeFirebaseFirestore();
      final repo = FirebaseStatsRepository(firestore: db);

      await repo.saveUserStats(
        userId: 'alice',
        displayName: 'Alice',
        gameType: '2048',
        score: 1000,
      );
      await repo.saveUserStats(
        userId: 'charlie',
        displayName: 'Charlie',
        gameType: '2048',
        score: 5000,
      );
      await repo.saveUserStats(
        userId: 'bob',
        displayName: 'Bob',
        gameType: '2048',
        score: 3000,
      );

      final leaderboard = await repo.getLeaderboard(gameType: '2048');
      expect(leaderboard.length, 3);
      expect(leaderboard[0].userId, 'charlie'); // 5000
      expect(leaderboard[1].userId, 'bob'); // 3000
      expect(leaderboard[2].userId, 'alice'); // 1000
    });
  });

  // ── leaderboardStream real-time updates ────────────────────────────────────

  group('leaderboardStream — real-time updates', () {
    test('stream emits updated entry after saveUserStats', () async {
      final db = FakeFirebaseFirestore();
      final repo = FirebaseStatsRepository(firestore: db);

      final stream = repo.leaderboardStream(gameType: '2048');

      // Collect the first three emissions: [] (initial), [entry], [updated]
      final emissions = <List<LeaderboardEntry>>[];
      final sub = stream.listen(emissions.add);

      await repo.saveUserStats(
        userId: 'dan',
        displayName: 'Dan',
        gameType: '2048',
        score: 2000,
      );

      // Give the stream a chance to emit
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await repo.saveUserStats(
        userId: 'dan',
        displayName: 'Dan',
        gameType: '2048',
        score: 4000,
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      // There should be at least two non-empty emissions
      final nonEmpty = emissions.where((e) => e.isNotEmpty).toList();
      expect(nonEmpty, isNotEmpty);

      // The final non-empty emission must show the updated high score
      final final_ = nonEmpty.last;
      expect(final_.first.highScore, 4000);
      expect(final_.first.displayName, 'Dan');
    });

    test('stream emits initial empty list when no scores exist', () async {
      final db = FakeFirebaseFirestore();
      final repo = FirebaseStatsRepository(firestore: db);

      final first = await repo
          .leaderboardStream(gameType: 'nonexistent_game')
          .first;

      expect(first, isEmpty);
    });
  });

  // ── userStatsStream real-time updates ─────────────────────────────────────

  group('userStatsStream — real-time updates', () {
    test('stream emits null initially and then the saved stats', () async {
      final db = FakeFirebaseFirestore();
      final repo = FirebaseStatsRepository(firestore: db);

      final emissions = <UserStats?>[];
      final sub = repo.userStatsStream('user-stream-1').listen(emissions.add);

      // Initially no document — stream emits null
      await Future<void>.delayed(const Duration(milliseconds: 30));

      await repo.saveUserStats(
        userId: 'user-stream-1',
        displayName: 'Eve',
        gameType: 'memory_game',
        score: 800,
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      // First emission should be null (no doc yet)
      expect(emissions.first, isNull);

      // Subsequent emission should contain the saved stats
      final nonNull = emissions.whereType<UserStats>().toList();
      expect(nonNull, isNotEmpty);
      expect(nonNull.first.displayName, 'Eve');
      expect(nonNull.first.gameStats['memory_game']?.highScore, 800);
    });
  });

  // ── getUserRank ────────────────────────────────────────────────────────────

  group('getUserRank', () {
    test('returns null when user has no score', () async {
      final db = FakeFirebaseFirestore();
      final repo = FirebaseStatsRepository(firestore: db);

      final rank = await repo.getUserRank(userId: 'nobody', gameType: '2048');
      expect(rank, isNull);
    });

    test('returns rank 1 for the only player', () async {
      final db = FakeFirebaseFirestore();
      final repo = FirebaseStatsRepository(firestore: db);

      await repo.saveUserStats(
        userId: 'solo',
        gameType: '2048',
        score: 1000,
      );

      final rank = await repo.getUserRank(userId: 'solo', gameType: '2048');
      expect(rank, 1);
    });

    test('returns correct rank among multiple players', () async {
      final db = FakeFirebaseFirestore();
      final repo = FirebaseStatsRepository(firestore: db);

      await repo.saveUserStats(userId: 'p1', gameType: '2048', score: 5000);
      await repo.saveUserStats(userId: 'p2', gameType: '2048', score: 3000);
      await repo.saveUserStats(userId: 'p3', gameType: '2048', score: 1000);

      // p2 has 3000 — one player (p1) has a higher score → rank 2
      final rank = await repo.getUserRank(userId: 'p2', gameType: '2048');
      expect(rank, 2);
    });
  });
}
