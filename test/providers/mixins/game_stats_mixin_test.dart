import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/providers/mixins/game_stats_mixin.dart';
import 'package:multigame/services/data/firebase_stats_service.dart';

// Mock Firebase Stats Service for testing
class MockFirebaseStatsService implements FirebaseStatsService {
  final List<Map<String, dynamic>> savedStats = [];
  bool shouldThrowError = false;

  @override
  Future<void> saveUserStats({
    required String userId,
    String? displayName,
    required String gameType,
    required int score,
  }) async {
    if (shouldThrowError) {
      throw Exception('Mock error saving stats');
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
}
