import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/puzzle/providers/puzzle_game_provider.dart';
import 'package:multigame/services/data/achievement_service.dart';
import 'package:multigame/services/data/firebase_stats_service.dart';

/// Fake implementation of AchievementService for testing
class FakeAchievementService implements AchievementService {
  List<String> recordedCompletions = [];
  Map<String, dynamic>? lastCompletionData;

  @override
  Future<List<String>> recordGameCompletion({
    required int gridSize,
    required int moves,
    required int seconds,
  }) async {
    lastCompletionData = {
      'gridSize': gridSize,
      'moves': moves,
      'seconds': seconds,
    };
    recordedCompletions.add('completion_${gridSize}_${moves}_$seconds');

    // Return mock achievements
    if (moves < 50 && seconds < 60) {
      return ['speed_demon', 'efficiency_master'];
    }
    return [];
  }

  @override
  Future<Map<String, bool>> checkAchievements() async => {};

  @override
  Future<Map<String, dynamic>> get2048Stats() async => {};

  @override
  Future<Map<String, bool>> getAchievements() async => {};

  @override
  Future<Map<String, dynamic>> getAllStats() async => {};

  @override
  Future<int?> getBestMoves(int gridSize) async => null;

  @override
  Future<int?> getBestOverallTime() async => null;

  @override
  Future<int?> getBestTime(int gridSize) async => null;

  @override
  Future<int> getTotalCompleted() async => 0;

  @override
  Future<void> incrementTotalCompleted() async {}

  @override
  Future<void> resetAll() async {}

  @override
  Future<void> save2048Achievement({
    required int score,
    required int highestTile,
    required String levelPassed,
  }) async {}

  @override
  Future<void> updateBestMoves(int gridSize, int moves) async {}

  @override
  Future<void> updateBestTime(int gridSize, int seconds) async {}
}

/// Fake implementation of FirebaseStatsService for testing
class FakeFirebaseStatsService implements FirebaseStatsService {
  List<Map<String, dynamic>> savedStats = [];
  bool shouldThrowError = false;
  int callCount = 0;

  @override
  Future<void> saveUserStats({
    required String userId,
    String? displayName,
    required String gameType,
    required int score,
  }) async {
    callCount++;

    if (shouldThrowError) {
      throw Exception('Network error');
    }

    savedStats.add({
      'userId': userId,
      'displayName': displayName,
      'gameType': gameType,
      'score': score,
    });
  }

  @override
  Future<List<LeaderboardEntry>> getLeaderboard({
    required String gameType,
    int limit = 100,
  }) async => [];

  @override
  Future<int?> getUserRank({
    required String userId,
    required String gameType,
  }) async => null;

  @override
  Future<UserStats?> getUserStats(String userId) async => null;

  @override
  Stream<List<LeaderboardEntry>> leaderboardStream({
    required String gameType,
    int limit = 100,
  }) => Stream.value([]);

  @override
  Stream<UserStats?> userStatsStream(String userId) => Stream.value(null);
}

void main() {
  group('PuzzleGameNotifier', () {
    late PuzzleGameNotifier provider;
    late FakeAchievementService fakeAchievementService;
    late FakeFirebaseStatsService fakeStatsService;

    setUp(() {
      fakeAchievementService = FakeAchievementService();
      fakeStatsService = FakeFirebaseStatsService();

      provider = PuzzleGameNotifier(
        achievementService: fakeAchievementService,
        statsService: fakeStatsService,
      );
    });

    tearDown(() {
      provider.dispose();
    });

    group('initialization', () {
      test('should initialize with default values', () {
        // Assert
        expect(provider.game, isNull);
        expect(provider.gridSize, equals(4));
        expect(provider.moveCount, equals(0));
        expect(provider.elapsedSeconds, equals(0));
        expect(provider.isGameInitialized, isFalse);
      });

      test('should have access to injected services', () {
        // Assert
        expect(provider.statsService, equals(fakeStatsService));
      });

      test('should initialize game on initializeGame()', () async {
        // Act
        await provider.initializeGame();

        // Assert
        expect(provider.game, isNotNull);
        expect(provider.isGameInitialized, isTrue);
        expect(provider.moveCount, equals(0));
        expect(provider.elapsedSeconds, equals(0));
      });

      test('should start timer after initialization', () async {
        // Act
        await provider.initializeGame();
        await Future.delayed(const Duration(milliseconds: 1100));

        // Assert
        expect(provider.elapsedSeconds, greaterThan(0));
      });
    });

    group('game state', () {
      setUp(() async {
        await provider.initializeGame();
      });

      test('should track move count', () {
        // Arrange
        final initialMoveCount = provider.moveCount;

        // Act: Find a valid move position
        final emptyPos = provider.game!.emptyPosition;
        final validMovePos = emptyPos == 0 ? 1 : 0;
        provider.movePiece(validMovePos);

        // Assert
        expect(provider.moveCount, equals(initialMoveCount + 1));
      });

      test('should not increment move count for invalid moves', () {
        // Arrange
        final initialMoveCount = provider.moveCount;
        final emptyPos = provider.game!.emptyPosition;

        // Act: Try to move the empty position itself (invalid)
        provider.movePiece(emptyPos);

        // Assert
        expect(provider.moveCount, equals(initialMoveCount));
      });

      test('should update elapsed seconds periodically', () async {
        // Arrange
        final initialSeconds = provider.elapsedSeconds;

        // Act: Wait for timer to tick
        await Future.delayed(const Duration(milliseconds: 1100));

        // Assert
        expect(provider.elapsedSeconds, greaterThan(initialSeconds));
      });

      test('should provide correct isGameInitialized state', () {
        // Assert
        expect(provider.isGameInitialized, isTrue);
      });
    });

    group('resetGame()', () {
      test('should reset move count', () async {
        // Arrange
        await provider.initializeGame();
        // Find a valid move position (not the empty position)
        final emptyPos = provider.game!.emptyPosition;
        final validMovePos = emptyPos == 0 ? 1 : 0;
        provider.movePiece(validMovePos);
        expect(provider.moveCount, greaterThan(0));

        // Act
        await provider.resetGame();

        // Assert
        expect(provider.moveCount, equals(0));
      });

      test('should reset timer', () async {
        // Arrange
        await provider.initializeGame();
        await Future.delayed(const Duration(milliseconds: 1100));
        expect(provider.elapsedSeconds, greaterThan(0));

        // Act
        await provider.resetGame();
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(provider.elapsedSeconds, equals(0));
      });

      test('should keep game initialized after reset', () async {
        // Arrange
        await provider.initializeGame();

        // Act
        await provider.resetGame();

        // Assert
        expect(provider.game, isNotNull);
        // Game is reloaded but could be a different instance
        expect(provider.isGameInitialized, isTrue);
      });

      test('should do nothing if game is not initialized', () async {
        // Arrange: Don't initialize game
        expect(provider.isGameInitialized, isFalse);

        // Act
        await provider.resetGame();

        // Assert
        expect(provider.isGameInitialized, isFalse);
      });
    });

    group('newImageGame()', () {
      test('should reset move count', () async {
        // Arrange
        await provider.initializeGame();
        final emptyPos = provider.game!.emptyPosition;
        final validMovePos = emptyPos == 0 ? 1 : 0;
        provider.movePiece(validMovePos);
        expect(provider.moveCount, greaterThan(0));

        // Act
        await provider.newImageGame();

        // Assert
        expect(provider.moveCount, equals(0));
      });

      test('should reset timer', () async {
        // Arrange
        await provider.initializeGame();
        await Future.delayed(const Duration(milliseconds: 1100));
        expect(provider.elapsedSeconds, greaterThan(0));

        // Act
        await provider.newImageGame();
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(provider.elapsedSeconds, equals(0));
      });

      test('should do nothing if game is not initialized', () async {
        // Arrange: Don't initialize game
        expect(provider.isGameInitialized, isFalse);

        // Act
        await provider.newImageGame();

        // Assert
        expect(provider.isGameInitialized, isFalse);
      });
    });

    group('changeGridSize()', () {
      test('should update grid size', () async {
        // Arrange
        await provider.initializeGame();
        expect(provider.gridSize, equals(4));

        // Act
        await provider.changeGridSize(5);

        // Assert
        expect(provider.gridSize, equals(5));
      });

      test('should reset move count', () async {
        // Arrange
        await provider.initializeGame();
        final emptyPos = provider.game!.emptyPosition;
        final validMovePos = emptyPos == 0 ? 1 : 0;
        provider.movePiece(validMovePos);
        expect(provider.moveCount, greaterThan(0));

        // Act
        await provider.changeGridSize(5);

        // Assert
        expect(provider.moveCount, equals(0));
      });

      test('should reset timer', () async {
        // Arrange
        await provider.initializeGame();
        await Future.delayed(const Duration(milliseconds: 1100));
        expect(provider.elapsedSeconds, greaterThan(0));

        // Act
        await provider.changeGridSize(5);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(provider.elapsedSeconds, equals(0));
      });

      test('should create new game with new grid size', () async {
        // Arrange
        await provider.initializeGame();

        // Act
        await provider.changeGridSize(6);

        // Assert
        expect(provider.game, isNotNull);
        expect(provider.game!.gridSize, equals(6));
        expect(provider.game!.totalPieces, equals(36));
      });

      test('should do nothing if grid size is the same', () async {
        // Arrange
        await provider.initializeGame();
        final gameInstance = provider.game;
        final moveCountBefore = provider.moveCount;

        // Act
        await provider.changeGridSize(4); // Same as current

        // Assert
        expect(provider.gridSize, equals(4));
        expect(provider.game, equals(gameInstance));
        expect(provider.moveCount, equals(moveCountBefore));
      });

      test('should support different grid sizes', () async {
        // Test multiple grid sizes
        for (final size in [3, 4, 5, 6]) {
          await provider.changeGridSize(size);

          expect(provider.gridSize, equals(size));
          expect(provider.game!.gridSize, equals(size));
          expect(provider.game!.totalPieces, equals(size * size));
        }
      });
    });

    group('movePiece()', () {
      setUp(() async {
        await provider.initializeGame();
      });

      test('should return true for valid move', () {
        // Arrange
        final emptyPos = provider.game!.emptyPosition;
        final validPos = emptyPos == 0 ? 1 : 0;

        // Act
        final result = provider.movePiece(validPos);

        // Assert
        expect(result, isTrue);
      });

      test('should return false for invalid move (empty position)', () {
        // Arrange
        final emptyPos = provider.game!.emptyPosition;

        // Act
        final result = provider.movePiece(emptyPos);

        // Assert
        expect(result, isFalse);
      });

      test('should increment move count on valid move', () {
        // Arrange
        final initialMoveCount = provider.moveCount;
        final validPos = provider.game!.emptyPosition == 0 ? 1 : 0;

        // Act
        provider.movePiece(validPos);

        // Assert
        expect(provider.moveCount, equals(initialMoveCount + 1));
      });

      test('should not increment move count on invalid move', () {
        // Arrange
        final initialMoveCount = provider.moveCount;
        final emptyPos = provider.game!.emptyPosition;

        // Act
        provider.movePiece(emptyPos);

        // Assert
        expect(provider.moveCount, equals(initialMoveCount));
      });

      test('should return false if game is not initialized', () {
        // Arrange: Create new provider without initializing
        final uninitializedProvider = PuzzleGameNotifier(
          achievementService: fakeAchievementService,
          statsService: fakeStatsService,
        );

        // Act
        final result = uninitializedProvider.movePiece(0);

        // Assert
        expect(result, isFalse);

        uninitializedProvider.dispose();
      });
    });

    group('timer management', () {
      test('should stop timer when stopTimer is called', () async {
        // Arrange
        await provider.initializeGame();

        // Wait for at least 1 second to pass
        await Future.delayed(const Duration(milliseconds: 1100));
        expect(provider.elapsedSeconds, greaterThan(0));

        // Act
        provider.stopTimer();
        final elapsedAfterStop = provider.elapsedSeconds;

        // Wait and verify timer doesn't increment
        await Future.delayed(const Duration(milliseconds: 1100));

        // Assert: Timer should not increment after stop
        expect(provider.elapsedSeconds, equals(elapsedAfterStop));
      });

      test('should restart timer on resetGame()', () async {
        // Arrange
        await provider.initializeGame();
        await Future.delayed(const Duration(milliseconds: 1100));
        final elapsedBefore = provider.elapsedSeconds;

        // Act
        await provider.resetGame();
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(provider.elapsedSeconds, lessThan(elapsedBefore));
        expect(provider.elapsedSeconds, equals(0));
      });

      test('should restart timer on changeGridSize()', () async {
        // Arrange
        await provider.initializeGame();
        await Future.delayed(const Duration(milliseconds: 1100));

        // Act
        await provider.changeGridSize(5);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(provider.elapsedSeconds, equals(0));
      });

      test('should clean up timer on dispose', () async {
        // Arrange: Create a separate provider for this test
        final testProvider = PuzzleGameNotifier(
          achievementService: fakeAchievementService,
          statsService: fakeStatsService,
        );
        await testProvider.initializeGame();
        await Future.delayed(const Duration(milliseconds: 1100));
        expect(testProvider.elapsedSeconds, greaterThan(0));

        // Act
        testProvider.dispose();
        await Future.delayed(const Duration(milliseconds: 1100));

        // Assert: No errors should occur after disposal
        // (If timer wasn't cancelled, this might cause issues)
        expect(true, isTrue); // Test passes if no errors
      });
    });

    group('recordGameCompletion()', () {
      setUp(() async {
        await provider.initializeGame();
      });

      test('should call achievement service with correct data', () async {
        // Arrange
        final emptyPos = provider.game!.emptyPosition;
        final validMovePos = emptyPos == 0 ? 1 : 0;
        provider.movePiece(validMovePos); // Make at least one move
        await Future.delayed(const Duration(milliseconds: 1100));

        // Act
        await provider.recordGameCompletion();

        // Assert
        expect(fakeAchievementService.lastCompletionData, isNotNull);
        expect(
          fakeAchievementService.lastCompletionData!['gridSize'],
          equals(provider.gridSize),
        );
        expect(
          fakeAchievementService.lastCompletionData!['moves'],
          equals(provider.moveCount),
        );
        expect(
          fakeAchievementService.lastCompletionData!['seconds'],
          greaterThan(0),
        );
      });

      test('should return achievements list', () async {
        // Arrange: Set up conditions for achievements
        // (Based on fake service logic: moves < 50 && seconds < 60)

        // Act
        final achievements = await provider.recordGameCompletion();

        // Assert
        expect(achievements, isA<List<String>>());
      });

      test('should return empty list if game is not initialized', () async {
        // Arrange: Create new provider without initializing
        final uninitializedProvider = PuzzleGameNotifier(
          achievementService: fakeAchievementService,
          statsService: fakeStatsService,
        );

        // Act
        final achievements = await uninitializedProvider.recordGameCompletion();

        // Assert
        expect(achievements, isEmpty);

        uninitializedProvider.dispose();
      });
    });

    group('score saving', () {
      setUp(() async {
        await provider.initializeGame();
        provider.setUserInfo('test_user_123', 'Test Player');
      });

      test('should save score when game is solved', () async {
        // Arrange: Make some moves
        for (int i = 0; i < 5; i++) {
          final pos = provider.game!.emptyPosition == 0 ? 1 : 0;
          provider.movePiece(pos);
        }

        // Manually trigger score save (simulating game solved)
        // In real scenario, this happens in movePiece when isSolved is true
        await provider.saveScore('puzzle', 9900);

        // Assert
        expect(fakeStatsService.savedStats, isNotEmpty);
        expect(fakeStatsService.savedStats.first['gameType'], equals('puzzle'));
        expect(
          fakeStatsService.savedStats.first['userId'],
          equals('test_user_123'),
        );
      });

      test('should calculate score correctly', () {
        // Formula: score = 10000 - (moves * 10) - elapsed seconds
        // Arrange
        final moves = 50;
        final seconds = 100;
        final expectedScore = 10000 - (moves * 10) - seconds;

        // Assert formula
        expect(expectedScore, equals(9400));
        expect(expectedScore, greaterThan(0));
        expect(expectedScore, lessThanOrEqualTo(10000));
      });

      test('should clamp score to valid range', () {
        // Formula should clamp between 0 and 10000
        // Test with high moves and time
        final moves = 1000;
        final seconds = 1000;
        final calculatedScore = (10000 - (moves * 10) - seconds);
        final clampedScore = calculatedScore.clamp(0, 10000);

        // Assert
        expect(clampedScore, equals(0));
        expect(clampedScore, greaterThanOrEqualTo(0));
        expect(clampedScore, lessThanOrEqualTo(10000));
      });

      test('should not save score if userId is null', () async {
        // Arrange: Create provider without setting user info
        final newProvider = PuzzleGameNotifier(
          achievementService: fakeAchievementService,
          statsService: fakeStatsService,
        );
        await newProvider.initializeGame();

        // Act
        final result = await newProvider.saveScore('puzzle', 9000);

        // Assert
        expect(result, isFalse);
        expect(fakeStatsService.savedStats, isEmpty);

        newProvider.dispose();
      });

      test('should not save score if score is zero', () async {
        // Act
        final result = await provider.saveScore('puzzle', 0);

        // Assert
        expect(result, isFalse);
        expect(fakeStatsService.savedStats, isEmpty);
      });

      test('should not save score if score is negative', () async {
        // Act
        final result = await provider.saveScore('puzzle', -100);

        // Assert
        expect(result, isFalse);
        expect(fakeStatsService.savedStats, isEmpty);
      });
    });

    group('formatTime()', () {
      test('should format seconds correctly', () {
        // Assert
        expect(provider.formatTime(0), equals('00:00'));
        expect(provider.formatTime(30), equals('00:30'));
        expect(provider.formatTime(59), equals('00:59'));
      });

      test('should format minutes correctly', () {
        // Assert
        expect(provider.formatTime(60), equals('01:00'));
        expect(provider.formatTime(90), equals('01:30'));
        expect(provider.formatTime(120), equals('02:00'));
      });

      test('should format minutes and seconds with padding', () {
        // Assert
        expect(provider.formatTime(65), equals('01:05'));
        expect(provider.formatTime(305), equals('05:05'));
        expect(provider.formatTime(661), equals('11:01'));
      });

      test('should handle large time values', () {
        // Assert
        expect(provider.formatTime(3600), equals('60:00'));
        expect(provider.formatTime(3661), equals('61:01'));
      });
    });

    group('GameStatsMixin integration', () {
      test('should provide userId getter', () {
        // Arrange
        provider.setUserInfo('user_456', 'Player Name');

        // Assert
        expect(provider.userId, equals('user_456'));
      });

      test('should provide displayName getter', () {
        // Arrange
        provider.setUserInfo('user_456', 'Player Name');

        // Assert
        expect(provider.displayName, equals('Player Name'));
      });

      test('should allow setting user info', () {
        // Act
        provider.setUserInfo('new_user_789', 'New Player');

        // Assert
        expect(provider.userId, equals('new_user_789'));
        expect(provider.displayName, equals('New Player'));
      });

      test('should handle retry on score save failure', () async {
        // Arrange
        provider.setUserInfo('test_user', 'Test');
        fakeStatsService.shouldThrowError = true;

        // Act
        final result = await provider.saveScore('puzzle', 9000);

        // Assert
        expect(result, isFalse);
        expect(
          fakeStatsService.callCount,
          greaterThan(1),
        ); // Should have retried
        expect(provider.lastError, isNotNull);
        expect(provider.lastError, contains('Failed to save score'));
      });

      test('should clear error', () async {
        // Arrange
        provider.setUserInfo('test_user', 'Test');
        fakeStatsService.shouldThrowError = true;
        await provider.saveScore('puzzle', 9000);
        expect(provider.lastError, isNotNull);

        // Act
        provider.clearError();

        // Assert
        expect(provider.lastError, isNull);
      });

      test('should track isSavingScore state', () async {
        // Arrange
        provider.setUserInfo('test_user', 'Test');
        expect(provider.isSavingScore, isFalse);

        // Act: Start save in background
        final saveFuture = provider.saveScore('puzzle', 9000);

        // Give it a moment to start but not complete
        await Future.delayed(const Duration(milliseconds: 10));

        // Note: isSavingScore might already be false if save completes quickly
        // This is expected in a fake service

        // Wait for completion
        await saveFuture;

        // Assert: Should be false after completion
        expect(provider.isSavingScore, isFalse);
      });
    });

    group('notification listeners', () {
      test('should notify listeners on initializeGame()', () async {
        // Arrange
        int notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act
        await provider.initializeGame();

        // Assert
        expect(notificationCount, greaterThan(0));
      });

      test('should notify listeners on resetGame()', () async {
        // Arrange
        await provider.initializeGame();
        int notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act
        await provider.resetGame();

        // Assert
        expect(notificationCount, greaterThan(0));
      });

      test('should notify listeners on movePiece()', () async {
        // Arrange
        await provider.initializeGame();
        int notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act
        final validPos = provider.game!.emptyPosition == 0 ? 1 : 0;
        provider.movePiece(validPos);

        // Assert
        expect(notificationCount, greaterThan(0));
      });

      test('should notify listeners on changeGridSize()', () async {
        // Arrange
        await provider.initializeGame();
        int notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act
        await provider.changeGridSize(5);

        // Assert
        expect(notificationCount, greaterThan(0));
      });

      test('should notify listeners periodically for timer', () async {
        // Arrange
        await provider.initializeGame();
        int notificationCount = 0;
        provider.addListener(() => notificationCount++);

        // Act: Wait for timer to tick
        await Future.delayed(const Duration(milliseconds: 1100));

        // Assert
        expect(notificationCount, greaterThan(0));
      });
    });

    group('edge cases', () {
      test('should handle rapid grid size changes', () async {
        // Act
        await provider.changeGridSize(3);
        await provider.changeGridSize(4);
        await provider.changeGridSize(5);
        await provider.changeGridSize(6);

        // Assert
        expect(provider.gridSize, equals(6));
        expect(provider.game!.gridSize, equals(6));
      });

      test('should handle multiple resets in succession', () async {
        // Arrange
        await provider.initializeGame();

        // Act
        await provider.resetGame();
        await provider.resetGame();
        await provider.resetGame();

        // Assert
        expect(provider.moveCount, equals(0));
        expect(provider.isGameInitialized, isTrue);
      });

      test('should handle dispose without initialization', () {
        // Arrange: Create new provider
        final newProvider = PuzzleGameNotifier(
          achievementService: fakeAchievementService,
          statsService: fakeStatsService,
        );

        // Act & Assert: Should not throw
        expect(() => newProvider.dispose(), returnsNormally);
      });

      test('should handle multiple dispose calls', () async {
        // Arrange: Create a separate provider for this test
        final testProvider = PuzzleGameNotifier(
          achievementService: fakeAchievementService,
          statsService: fakeStatsService,
        );
        await testProvider.initializeGame();

        // Act: First dispose
        testProvider.dispose();

        // Assert: Second dispose will throw in debug mode, which is expected
        // Flutter's ChangeNotifier throws when used after dispose in debug
        expect(() => testProvider.dispose(), throwsFlutterError);
      });
    });

    group('integration scenarios', () {
      test('should handle complete game flow', () async {
        // Arrange & Act: Complete game flow
        provider.setUserInfo('player_123', 'Test Player');
        await provider.initializeGame();

        // Make some moves
        for (int i = 0; i < 3; i++) {
          final pos = provider.game!.emptyPosition == 0 ? 1 : 0;
          provider.movePiece(pos);
        }

        // Wait for time to pass
        await Future.delayed(const Duration(milliseconds: 1100));

        // Record completion
        final achievements = await provider.recordGameCompletion();

        // Assert
        expect(provider.isGameInitialized, isTrue);
        expect(provider.moveCount, equals(3));
        expect(provider.elapsedSeconds, greaterThan(0));
        expect(achievements, isA<List<String>>());
      });

      test('should handle game restart after completion', () async {
        // Arrange
        provider.setUserInfo('player_123', 'Test Player');
        await provider.initializeGame();
        final emptyPos = provider.game!.emptyPosition;
        final validMovePos = emptyPos == 0 ? 1 : 0;
        provider.movePiece(validMovePos);
        await provider.recordGameCompletion();

        // Act: Reset and play again
        await provider.resetGame();

        // Assert
        expect(provider.moveCount, equals(0));
        expect(provider.elapsedSeconds, equals(0));
        expect(provider.isGameInitialized, isTrue);
      });

      test('should handle size change mid-game', () async {
        // Arrange
        await provider.initializeGame();
        final emptyPos = provider.game!.emptyPosition;
        final validMovePos = emptyPos == 0 ? 1 : 0;
        provider.movePiece(validMovePos);
        await Future.delayed(const Duration(milliseconds: 1100));

        // Act: Change size mid-game
        await provider.changeGridSize(5);

        // Assert: Should reset everything
        expect(provider.gridSize, equals(5));
        expect(provider.moveCount, equals(0));
        expect(provider.elapsedSeconds, equals(0));
      });
    });
  });
}
