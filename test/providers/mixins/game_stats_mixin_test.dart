import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/providers/mixins/game_stats_mixin.dart';
import 'package:multigame/services/data/firebase_stats_service.dart';

// Mock Firebase Stats Service for testing
class MockFirebaseStatsService implements FirebaseStatsService {
  final List<Map<String, dynamic>> savedStats = [];
  bool shouldThrowError = false;
  int failureCount = 0; // Number of times to fail before succeeding
  int attemptCount = 0; // Track number of attempts made

  @override
  Future<void> saveUserStats({
    required String userId,
    String? displayName,
    required String gameType,
    required int score,
  }) async {
    attemptCount++;

    if (shouldThrowError) {
      throw Exception('Mock error saving stats');
    }

    // Support for testing retries: fail N times then succeed
    if (failureCount > 0) {
      failureCount--;
      throw Exception('Mock temporary network error');
    }

    savedStats.add({
      'userId': userId,
      'displayName': displayName,
      'gameType': gameType,
      'score': score,
    });
  }

  void clear() {
    savedStats.clear();
    shouldThrowError = false;
    failureCount = 0;
    attemptCount = 0;
  }

  // Other FirebaseStatsService methods (not tested here)
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Test provider that uses the mixin
class TestGameProvider with ChangeNotifier, GameStatsMixin {
  @override
  final FirebaseStatsService statsService;

  TestGameProvider(this.statsService);
}

void main() {
  late TestGameProvider provider;
  late MockFirebaseStatsService mockStatsService;

  setUp(() {
    mockStatsService = MockFirebaseStatsService();
    provider = TestGameProvider(mockStatsService);
    // Use milliseconds instead of seconds for faster tests
    provider.retryDelayCalculator = (factor) => Duration(milliseconds: factor);
  });

  tearDown(() {
    mockStatsService.clear();
  });

  group('GameStatsMixin - User info management', () {
    test('initializes with null user ID and display name', () {
      expect(provider.userId, isNull);
      expect(provider.displayName, isNull);
    });

    test('sets user ID and display name', () {
      provider.setUserInfo('user_123', 'CoolPlayer');

      expect(provider.userId, 'user_123');
      expect(provider.displayName, 'CoolPlayer');
    });

    test('updates user ID and display name', () {
      provider.setUserInfo('user_old', 'OldName');
      provider.setUserInfo('user_new', 'NewName');

      expect(provider.userId, 'user_new');
      expect(provider.displayName, 'NewName');
    });

    test('allows null values when setting user info', () {
      provider.setUserInfo('user_123', 'Player');
      provider.setUserInfo(null, null);

      expect(provider.userId, isNull);
      expect(provider.displayName, isNull);
    });

    test('allows setting user ID without display name', () {
      provider.setUserInfo('user_123', null);

      expect(provider.userId, 'user_123');
      expect(provider.displayName, isNull);
    });

    test('preserves user ID when display name changes', () {
      provider.setUserInfo('user_123', 'Name1');
      provider.setUserInfo('user_123', 'Name2');

      expect(provider.userId, 'user_123');
      expect(provider.displayName, 'Name2');
    });
  });

  group('GameStatsMixin - saveScore', () {
    test('saves score when user ID is set and score > 0', () async {
      provider.setUserInfo('user_123', 'Player1');

      provider.saveScore('puzzle', 100);

      // Wait for async operation
      await Future.delayed(const Duration(milliseconds: 10));

      expect(mockStatsService.savedStats.length, 1);
      expect(mockStatsService.savedStats[0]['userId'], 'user_123');
      expect(mockStatsService.savedStats[0]['displayName'], 'Player1');
      expect(mockStatsService.savedStats[0]['gameType'], 'puzzle');
      expect(mockStatsService.savedStats[0]['score'], 100);
    });

    test('does not save when user ID is null', () async {
      provider.setUserInfo(null, 'Player1');

      provider.saveScore('puzzle', 100);

      await Future.delayed(const Duration(milliseconds: 10));

      expect(mockStatsService.savedStats, isEmpty);
    });

    test('does not save when score is 0', () async {
      provider.setUserInfo('user_123', 'Player1');

      provider.saveScore('puzzle', 0);

      await Future.delayed(const Duration(milliseconds: 10));

      expect(mockStatsService.savedStats, isEmpty);
    });

    test('does not save when score is negative', () async {
      provider.setUserInfo('user_123', 'Player1');

      provider.saveScore('puzzle', -10);

      await Future.delayed(const Duration(milliseconds: 10));

      expect(mockStatsService.savedStats, isEmpty);
    });

    test('saves with null display name if only user ID is set', () async {
      provider.setUserInfo('user_123', null);

      provider.saveScore('2048', 500);

      await Future.delayed(const Duration(milliseconds: 10));

      expect(mockStatsService.savedStats.length, 1);
      expect(mockStatsService.savedStats[0]['userId'], 'user_123');
      expect(mockStatsService.savedStats[0]['displayName'], isNull);
      expect(mockStatsService.savedStats[0]['score'], 500);
    });

    test('saves multiple scores', () async {
      provider.setUserInfo('user_123', 'Player1');

      provider.saveScore('puzzle', 100);
      provider.saveScore('2048', 200);
      provider.saveScore('snake', 300);

      await Future.delayed(const Duration(milliseconds: 50));

      expect(mockStatsService.savedStats.length, 3);
    });

    test('saves different game types correctly', () async {
      provider.setUserInfo('user_123', 'Player1');

      provider.saveScore('puzzle', 100);
      await Future.delayed(const Duration(milliseconds: 10));

      provider.saveScore('2048', 500);
      await Future.delayed(const Duration(milliseconds: 10));

      provider.saveScore('snake', 300);
      await Future.delayed(const Duration(milliseconds: 10));

      provider.saveScore('infinite_runner', 1000);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(mockStatsService.savedStats[0]['gameType'], 'puzzle');
      expect(mockStatsService.savedStats[1]['gameType'], '2048');
      expect(mockStatsService.savedStats[2]['gameType'], 'snake');
      expect(mockStatsService.savedStats[3]['gameType'], 'infinite_runner');
    });

    test('saves high scores correctly', () async {
      provider.setUserInfo('user_123', 'ProPlayer');

      provider.saveScore('2048', 99999);

      await Future.delayed(const Duration(milliseconds: 10));

      expect(mockStatsService.savedStats[0]['score'], 99999);
    });

    test('handles error when saving score', () async {
      provider.setUserInfo('user_123', 'Player1');
      mockStatsService.shouldThrowError = true;

      // Should not throw error, just log it
      expect(() => provider.saveScore('puzzle', 100), returnsNormally);

      await Future.delayed(const Duration(milliseconds: 10));
    });
  });

  group('GameStatsMixin - Integration scenarios', () {
    test('workflow: set user info then save score', () async {
      // User logs in
      provider.setUserInfo('firebase_uid_abc', 'NewPlayer');

      // User plays game
      provider.saveScore('puzzle', 150);

      await Future.delayed(const Duration(milliseconds: 10));

      // Verify score was saved
      expect(mockStatsService.savedStats.length, 1);
      expect(mockStatsService.savedStats[0]['userId'], 'firebase_uid_abc');
      expect(mockStatsService.savedStats[0]['score'], 150);
    });

    test('workflow: update display name and save score', () async {
      provider.setUserInfo('user_123', 'OldName');
      provider.saveScore('puzzle', 100);

      await Future.delayed(const Duration(milliseconds: 10));

      // User changes display name
      provider.setUserInfo('user_123', 'NewName');
      provider.saveScore('puzzle', 200);

      await Future.delayed(const Duration(milliseconds: 10));

      expect(mockStatsService.savedStats.length, 2);
      expect(mockStatsService.savedStats[0]['displayName'], 'OldName');
      expect(mockStatsService.savedStats[1]['displayName'], 'NewName');
    });

    test('workflow: user logs out (clear user info)', () async {
      provider.setUserInfo('user_123', 'Player1');
      provider.saveScore('puzzle', 100);

      await Future.delayed(const Duration(milliseconds: 10));

      // User logs out
      provider.setUserInfo(null, null);
      provider.saveScore('puzzle', 200); // Should not save

      await Future.delayed(const Duration(milliseconds: 10));

      expect(mockStatsService.savedStats.length, 1); // Only first score saved
    });

    test('workflow: anonymous user then registers', () async {
      // Anonymous user (no display name)
      provider.setUserInfo('anonymous_user_123', null);
      provider.saveScore('puzzle', 50);

      await Future.delayed(const Duration(milliseconds: 10));

      // User registers and sets nickname
      provider.setUserInfo('anonymous_user_123', 'RegisteredPlayer');
      provider.saveScore('puzzle', 100);

      await Future.delayed(const Duration(milliseconds: 10));

      expect(mockStatsService.savedStats.length, 2);
      expect(mockStatsService.savedStats[0]['displayName'], isNull);
      expect(mockStatsService.savedStats[1]['displayName'], 'RegisteredPlayer');
    });

    test('multiple games in sequence', () async {
      provider.setUserInfo('user_123', 'GamerPro');

      // Play multiple games
      provider.saveScore('puzzle', 100);
      provider.saveScore('puzzle', 150);
      provider.saveScore('2048', 500);
      provider.saveScore('snake', 300);

      await Future.delayed(const Duration(milliseconds: 50));

      expect(mockStatsService.savedStats.length, 4);
      expect(mockStatsService.savedStats[0]['gameType'], 'puzzle');
      expect(mockStatsService.savedStats[0]['score'], 100);
      expect(mockStatsService.savedStats[1]['gameType'], 'puzzle');
      expect(mockStatsService.savedStats[1]['score'], 150);
      expect(mockStatsService.savedStats[2]['gameType'], '2048');
      expect(mockStatsService.savedStats[3]['gameType'], 'snake');
    });

    test('user switches accounts', () async {
      // First user
      provider.setUserInfo('user_1', 'Player1');
      provider.saveScore('puzzle', 100);

      await Future.delayed(const Duration(milliseconds: 10));

      // Switch to second user
      provider.setUserInfo('user_2', 'Player2');
      provider.saveScore('puzzle', 200);

      await Future.delayed(const Duration(milliseconds: 10));

      expect(mockStatsService.savedStats.length, 2);
      expect(mockStatsService.savedStats[0]['userId'], 'user_1');
      expect(mockStatsService.savedStats[1]['userId'], 'user_2');
    });

    test('edge case: score of exactly 1', () async {
      provider.setUserInfo('user_123', 'Player1');

      provider.saveScore('puzzle', 1);

      await Future.delayed(const Duration(milliseconds: 10));

      expect(mockStatsService.savedStats.length, 1);
      expect(mockStatsService.savedStats[0]['score'], 1);
    });

    test('preserves user info across multiple saves', () async {
      provider.setUserInfo('user_stable', 'StablePlayer');

      for (int i = 1; i <= 5; i++) {
        provider.saveScore('puzzle', i * 100);
      }

      await Future.delayed(const Duration(milliseconds: 100));

      expect(mockStatsService.savedStats.length, 5);

      // All should have same user info
      for (final stat in mockStatsService.savedStats) {
        expect(stat['userId'], 'user_stable');
        expect(stat['displayName'], 'StablePlayer');
      }
    });
  });

  group('GameStatsMixin - Retry mechanism', () {
    test('succeeds on first attempt without retry', () async {
      provider.setUserInfo('user_123', 'Player1');

      final result = await provider.saveScore('puzzle', 100);

      expect(result, isTrue);
      expect(mockStatsService.attemptCount, 1);
      expect(mockStatsService.savedStats.length, 1);
      expect(provider.retryAttempt, 0);
    });

    test('retries once after first failure and succeeds', () async {
      provider.setUserInfo('user_123', 'Player1');
      mockStatsService.failureCount = 1; // Fail once, then succeed

      final result = await provider.saveScore('puzzle', 100);

      expect(result, isTrue);
      expect(mockStatsService.attemptCount, 2); // 2 total attempts
      expect(mockStatsService.savedStats.length, 1);
      expect(provider.retryAttempt, 0); // Reset after success
    });

    test('retries twice after failures and succeeds', () async {
      provider.setUserInfo('user_123', 'Player1');
      mockStatsService.failureCount = 2; // Fail twice, then succeed

      final result = await provider.saveScore('puzzle', 100);

      expect(result, isTrue);
      expect(mockStatsService.attemptCount, 3); // 3 total attempts
      expect(mockStatsService.savedStats.length, 1);
      expect(provider.retryAttempt, 0); // Reset after success
    });

    test(
      'retries 3 times after failures and succeeds on final attempt',
      () async {
        provider.setUserInfo('user_123', 'Player1');
        mockStatsService.failureCount = 3; // Fail 3 times, succeed on 4th

        final result = await provider.saveScore('puzzle', 100);

        expect(result, isTrue);
        expect(
          mockStatsService.attemptCount,
          4,
        ); // 4 total attempts (1 initial + 3 retries)
        expect(mockStatsService.savedStats.length, 1);
        expect(provider.retryAttempt, 0); // Reset after success
      },
    );

    test('fails after exhausting all 3 retries', () async {
      provider.setUserInfo('user_123', 'Player1');
      mockStatsService.shouldThrowError = true; // Always fail

      final result = await provider.saveScore('puzzle', 100);

      expect(result, isFalse);
      expect(
        mockStatsService.attemptCount,
        4,
      ); // 4 total attempts (1 initial + 3 retries)
      expect(mockStatsService.savedStats, isEmpty);
      expect(provider.lastError, contains('after 4 attempts'));
      expect(provider.retryAttempt, 0); // Reset after final failure
    });

    test('tracks retry attempt during retries', () async {
      provider.setUserInfo('user_123', 'Player1');
      mockStatsService.failureCount = 2; // Fail twice

      // Start the save (don't await yet to check intermediate state)
      final future = provider.saveScore('puzzle', 100);

      // Give it time to start and fail first attempt
      await Future.delayed(const Duration(milliseconds: 100));
      // At this point it should be on retry attempt 1

      // Wait for completion
      await future;

      // After success, retry count should be reset
      expect(provider.retryAttempt, 0);
    });

    test('sets error message after all retries fail', () async {
      provider.setUserInfo('user_123', 'Player1');
      mockStatsService.shouldThrowError = true;

      await provider.saveScore('puzzle', 100);

      expect(provider.lastError, isNotNull);
      expect(provider.lastError, contains('Failed to save score'));
      expect(provider.lastError, contains('4 attempts'));
      expect(provider.lastError, contains('internet connection'));
    });

    test('clears error on successful retry', () async {
      provider.setUserInfo('user_123', 'Player1');

      // First save fails completely
      mockStatsService.shouldThrowError = true;
      await provider.saveScore('puzzle', 100);
      expect(provider.lastError, isNotNull);

      // Second save succeeds (with one retry)
      mockStatsService.clear();
      mockStatsService.failureCount = 1;
      provider.setUserInfo('user_123', 'Player1'); // Reset user info
      await provider.saveScore('puzzle', 200);

      expect(provider.lastError, isNull);
    });

    test('isSavingScore is true during save and retry', () async {
      provider.setUserInfo('user_123', 'Player1');
      mockStatsService.failureCount = 1;

      expect(provider.isSavingScore, isFalse);

      final future = provider.saveScore('puzzle', 100);

      // Should be true during save (check immediately after microtask)
      await Future(() {});
      expect(provider.isSavingScore, isTrue);

      await future;

      // Should be false after completion
      expect(provider.isSavingScore, isFalse);
    });

    test('multiple consecutive saves work correctly', () async {
      provider.setUserInfo('user_123', 'Player1');

      // First save with retry
      mockStatsService.failureCount = 1;
      final result1 = await provider.saveScore('puzzle', 100);

      // Second save without retry
      mockStatsService.clear();
      mockStatsService.attemptCount = 0;
      provider.setUserInfo('user_123', 'Player1');
      final result2 = await provider.saveScore('2048', 200);

      expect(result1, isTrue);
      expect(result2, isTrue);
      expect(mockStatsService.attemptCount, 1); // Second save was first attempt
    });
  });
}
