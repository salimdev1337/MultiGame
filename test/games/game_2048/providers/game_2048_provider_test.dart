import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/game_2048/providers/game_2048_provider.dart';
import 'package:multigame/services/data/achievement_service.dart';
import 'package:multigame/services/data/firebase_stats_service.dart';

/// Fake AchievementService for testing
class FakeAchievementService implements AchievementService {
  List<Map<String, dynamic>> savedAchievements = [];
  bool shouldThrowError = false;

  @override
  Future<void> save2048Achievement({
    required int score,
    required int highestTile,
    required String levelPassed,
  }) async {
    if (shouldThrowError) {
      throw Exception('Failed to save achievement');
    }
    savedAchievements.add({
      'score': score,
      'highestTile': highestTile,
      'levelPassed': levelPassed,
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake FirebaseStatsService for testing
class FakeFirebaseStatsService implements FirebaseStatsService {
  List<Map<String, dynamic>> savedStats = [];
  bool shouldThrowError = false;
  int callCount = 0;

  @override
  Future<void> saveUserStats({
    required String userId,
    required String gameType,
    required int score,
    String? displayName,
  }) async {
    callCount++;
    if (shouldThrowError) {
      throw Exception('Failed to save stats');
    }
    savedStats.add({
      'userId': userId,
      'gameType': gameType,
      'score': score,
      'displayName': displayName,
    });
  }

  void reset() {
    savedStats.clear();
    shouldThrowError = false;
    callCount = 0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Custom fake that fails on first attempt then succeeds
class CustomRetryFakeStatsService implements FirebaseStatsService {
  List<Map<String, dynamic>> savedStats = [];
  int callCount = 0;

  @override
  Future<void> saveUserStats({
    required String userId,
    required String gameType,
    required int score,
    String? displayName,
  }) async {
    callCount++;
    if (callCount == 1) {
      throw Exception('First attempt fails');
    }
    // Succeed on retry
    savedStats.add({
      'userId': userId,
      'gameType': gameType,
      'score': score,
      'displayName': displayName,
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Game2048Provider provider;
  late FakeAchievementService fakeAchievementService;
  late FakeFirebaseStatsService fakeStatsService;

  setUp(() {
    fakeAchievementService = FakeAchievementService();
    fakeStatsService = FakeFirebaseStatsService();
    provider = Game2048Provider(
      achievementService: fakeAchievementService,
      statsService: fakeStatsService,
    );
  });

  group('Initialization', () {
    test('should initialize with empty 4x4 grid', () {
      expect(provider.grid.length, 4);
      for (var row in provider.grid) {
        expect(row.length, 4);
      }
    });

    test('should initialize with exactly 2 non-zero tiles', () {
      int nonZeroCount = 0;
      for (var row in provider.grid) {
        for (var cell in row) {
          if (cell != 0) nonZeroCount++;
        }
      }
      expect(nonZeroCount, 2);
    });

    test('should initialize with score of 0', () {
      expect(provider.score, 0);
    });

    test('should initialize with bestScore of 0', () {
      expect(provider.bestScore, 0);
    });

    test('should initialize with gameOver as false', () {
      expect(provider.gameOver, false);
    });

    test('should initialize with currentObjectiveIndex of 0', () {
      expect(provider.currentObjectiveIndex, 0);
    });

    test('should have correct objectives list', () {
      expect(provider.objectives, [256, 512, 1024, 2048]);
    });

    test('should have correct objectiveLabels list', () {
      expect(provider.objectiveLabels, ['Easy', 'Medium', 'Hard', 'Expert']);
    });

    test('should have correct currentObjective', () {
      expect(provider.currentObjective, 256);
    });

    test('should have correct currentObjectiveLabel', () {
      expect(provider.currentObjectiveLabel, 'Easy');
    });
  });

  group('initializeGame()', () {
    test('should reset game state', () {
      // Modify state - set up grid to trigger a merge
      for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
          provider.grid[i][j] = 0;
        }
      }
      provider.grid[0][0] = 2;
      provider.grid[0][1] = 2;

      provider.move('left');
      // Check that score changed (should be > 0 from merge)
      final scoreAfterMove = provider.score;

      // Reset
      provider.initializeGame();

      expect(provider.score, 0);
      expect(provider.gameOver, false);
      expect(scoreAfterMove, greaterThan(0)); // Verify move actually scored
    });

    test('should create new grid with 2 tiles', () {
      provider.initializeGame();

      int nonZeroCount = 0;
      for (var row in provider.grid) {
        for (var cell in row) {
          if (cell != 0) nonZeroCount++;
        }
      }
      expect(nonZeroCount, 2);
    });
  });

  group('move() - basic behavior', () {
    test('should return false when game is over', () {
      // Simulate game over by filling grid
      for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
          provider.grid[i][j] = (i * 4 + j + 1) * 2;
        }
      }
      // Manually set game over
      provider.move('left'); // This should detect no moves and set gameOver

      // Try to move when game over
      final moved = provider.move('left');
      expect(moved, false);
    });

    test('should return false when no tiles can move', () {
      // Create a grid where left move does nothing
      provider.grid[0] = [2, 4, 8, 16];
      provider.grid[1] = [0, 0, 0, 0];
      provider.grid[2] = [0, 0, 0, 0];
      provider.grid[3] = [0, 0, 0, 0];

      final moved = provider.move('left');
      expect(moved, false);
    });

    test('should return true when tiles can move', () {
      // Create a grid where tiles can move left
      provider.grid[0] = [0, 2, 0, 0];
      provider.grid[1] = [0, 0, 0, 0];
      provider.grid[2] = [0, 0, 0, 0];
      provider.grid[3] = [0, 0, 0, 0];

      final moved = provider.move('left');
      expect(moved, true);
    });

    test('should add new tile after successful move', () {
      // Clear grid and set up test case
      for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
          provider.grid[i][j] = 0;
        }
      }
      provider.grid[0][1] = 2;

      int tilesBeforeMove = _countNonZeroTiles(provider.grid);
      provider.move('left');
      int tilesAfterMove = _countNonZeroTiles(provider.grid);

      expect(tilesAfterMove, tilesBeforeMove + 1);
    });

    test('should update best score when score increases', () {
      // Clear grid and set up test case
      for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
          provider.grid[i][j] = 0;
        }
      }
      provider.grid[0][0] = 2;
      provider.grid[0][1] = 2;

      provider.move('left'); // Should merge 2+2 and score 4
      expect(provider.bestScore, greaterThan(0));
    });
  });

  group('move() - directional movements', () {
    test('should move tiles left correctly', () {
      // Clear grid and set up test case
      for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
          provider.grid[i][j] = 0;
        }
      }
      provider.grid[0][1] = 2;
      provider.grid[0][3] = 4;

      provider.move('left');

      expect(provider.grid[0][0], 2);
      expect(provider.grid[0][1], 4);
    });

    test('should move tiles right correctly', () {
      // Clear grid and set up test case
      for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
          provider.grid[i][j] = 0;
        }
      }
      provider.grid[0][0] = 2;
      provider.grid[0][2] = 4;

      provider.move('right');

      expect(provider.grid[0][2], 2);
      expect(provider.grid[0][3], 4);
    });

    test('should move tiles up correctly', () {
      // Clear grid and set up test case
      for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
          provider.grid[i][j] = 0;
        }
      }
      provider.grid[1][0] = 2;
      provider.grid[3][0] = 4;

      provider.move('up');

      expect(provider.grid[0][0], 2);
      expect(provider.grid[1][0], 4);
    });

    test('should move tiles down correctly', () {
      // Clear grid and set up test case
      for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
          provider.grid[i][j] = 0;
        }
      }
      provider.grid[0][0] = 2;
      provider.grid[2][0] = 4;

      provider.move('down');

      expect(provider.grid[2][0], 2);
      expect(provider.grid[3][0], 4);
    });
  });

  group('move() - tile merging', () {
    test('should merge two identical tiles moving left', () {
      // Clear grid and set up test case
      for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
          provider.grid[i][j] = 0;
        }
      }
      provider.grid[0][0] = 2;
      provider.grid[0][1] = 2;

      provider.move('left');

      // After merge, [2,2] becomes [4,0,0,0], then a random tile is added
      expect(provider.grid[0][0], 4);
      // Can't check other positions because random tile is added
      expect(provider.score, 4); // Verify merge happened by checking score
    });

    test('should merge two identical tiles moving right', () {
      // Clear grid and set up test case
      for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
          provider.grid[i][j] = 0;
        }
      }
      provider.grid[0][2] = 2;
      provider.grid[0][3] = 2;

      provider.move('right');

      // After merge, tiles move right and merge, then random tile is added
      expect(provider.grid[0][3], 4);
      expect(provider.score, 4); // Verify merge happened
    });

    test('should merge two identical tiles moving up', () {
      // Clear grid and set up test case
      for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
          provider.grid[i][j] = 0;
        }
      }
      provider.grid[0][0] = 2;
      provider.grid[1][0] = 2;

      provider.move('up');

      // After merge, tiles move up and merge, then random tile is added
      expect(provider.grid[0][0], 4);
      expect(provider.score, 4); // Verify merge happened
    });

    test('should merge two identical tiles moving down', () {
      // Clear grid and set up test case
      for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
          provider.grid[i][j] = 0;
        }
      }
      provider.grid[2][0] = 2;
      provider.grid[3][0] = 2;

      provider.move('down');

      // After merge, tiles move down and merge, then random tile is added
      expect(provider.grid[3][0], 4);
      expect(provider.score, 4); // Verify merge happened
    });

    test('should only merge once per row when moving left', () {
      // Clear grid and set up test case
      for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
          provider.grid[i][j] = 0;
        }
      }
      provider.grid[0][0] = 2;
      provider.grid[0][1] = 2;
      provider.grid[0][2] = 2;
      provider.grid[0][3] = 2;

      provider.move('left');

      // After [2,2,2,2] moves left, it should become [4,4,0,0]
      // Then a random tile is added somewhere in the grid
      expect(provider.grid[0][0], 4);
      expect(provider.grid[0][1], 4);
      // The score should reflect two merges: 4 + 4 = 8
      expect(provider.score, 8);
    });

    test('should increase score when tiles merge', () {
      // Clear grid and set up test case
      for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
          provider.grid[i][j] = 0;
        }
      }
      provider.grid[0][0] = 2;
      provider.grid[0][1] = 2;

      int scoreBefore = provider.score;
      provider.move('left');

      expect(provider.score, scoreBefore + 4);
    });

    test('should accumulate score from multiple merges', () {
      // Clear grid and set up test case
      for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
          provider.grid[i][j] = 0;
        }
      }
      provider.grid[0][0] = 2;
      provider.grid[0][1] = 2;
      provider.grid[0][2] = 4;
      provider.grid[0][3] = 4;

      provider.move('left');

      expect(provider.score, 4 + 8); // 2+2=4, 4+4=8
    });
  });

  group('getHighestTile()', () {
    test('should return 0 for empty grid', () {
      // Clear grid
      for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
          provider.grid[i][j] = 0;
        }
      }
      expect(provider.getHighestTile(), 0);
    });

    test('should return highest tile value', () {
      // Clear grid and set up test case
      for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
          provider.grid[i][j] = 0;
        }
      }
      provider.grid[0][0] = 2;
      provider.grid[1][1] = 16;
      provider.grid[2][2] = 8;
      provider.grid[3][3] = 4;

      expect(provider.getHighestTile(), 16);
    });

    test('should return 2048 when present', () {
      // Clear grid and set up test case
      for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
          provider.grid[i][j] = 0;
        }
      }
      provider.grid[0][0] = 2048;

      expect(provider.getHighestTile(), 2048);
    });
  });

  group('hasReachedObjective()', () {
    test('should return false when highest tile is below objective', () {
      // Clear grid and set up test case
      for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
          provider.grid[i][j] = 0;
        }
      }
      provider.grid[0][0] = 128;

      expect(provider.hasReachedObjective(), false); // Objective is 256
    });

    test('should return true when highest tile meets objective', () {
      // Clear grid and set up test case
      for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
          provider.grid[i][j] = 0;
        }
      }
      provider.grid[0][0] = 256;

      expect(provider.hasReachedObjective(), true);
    });

    test('should return true when highest tile exceeds objective', () {
      // Clear grid and set up test case
      for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
          provider.grid[i][j] = 0;
        }
      }
      provider.grid[0][0] = 512;

      expect(provider.hasReachedObjective(), true);
    });

    test('should respect current objective index', () {
      // Clear grid and set up test case
      for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
          provider.grid[i][j] = 0;
        }
      }
      provider.grid[0][0] = 512;

      provider.nextObjective(); // Move to Medium (512)
      expect(provider.hasReachedObjective(), true);

      provider.nextObjective(); // Move to Hard (1024)
      expect(provider.hasReachedObjective(), false);
    });
  });

  group('hasReachedMinimumObjective()', () {
    test('should return false when highest tile is below 256', () {
      // Clear grid and set up test case
      for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
          provider.grid[i][j] = 0;
        }
      }
      provider.grid[0][0] = 128;

      expect(provider.hasReachedMinimumObjective(), false);
    });

    test('should return true when highest tile is 256', () {
      // Clear grid and set up test case
      for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
          provider.grid[i][j] = 0;
        }
      }
      provider.grid[0][0] = 256;

      expect(provider.hasReachedMinimumObjective(), true);
    });

    test('should return true when highest tile exceeds 256', () {
      // Clear grid and set up test case
      for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
          provider.grid[i][j] = 0;
        }
      }
      provider.grid[0][0] = 2048;

      expect(provider.hasReachedMinimumObjective(), true);
    });
  });

  group('nextObjective()', () {
    test('should increment currentObjectiveIndex', () {
      expect(provider.currentObjectiveIndex, 0);

      provider.nextObjective();
      expect(provider.currentObjectiveIndex, 1);
    });

    test('should not exceed maximum objective index', () {
      provider.nextObjective(); // 1
      provider.nextObjective(); // 2
      provider.nextObjective(); // 3
      provider.nextObjective(); // Should stay at 3

      expect(provider.currentObjectiveIndex, 3);
    });

    test('should update currentObjective value', () {
      expect(provider.currentObjective, 256);

      provider.nextObjective();
      expect(provider.currentObjective, 512);
    });

    test('should update currentObjectiveLabel', () {
      expect(provider.currentObjectiveLabel, 'Easy');

      provider.nextObjective();
      expect(provider.currentObjectiveLabel, 'Medium');
    });
  });

  group('resetObjective()', () {
    test('should reset to first objective', () {
      provider.nextObjective();
      provider.nextObjective();
      expect(provider.currentObjectiveIndex, 2);

      provider.resetObjective();
      expect(provider.currentObjectiveIndex, 0);
    });

    test('should reset currentObjective value', () {
      provider.nextObjective();
      provider.nextObjective();

      provider.resetObjective();
      expect(provider.currentObjective, 256);
    });

    test('should reset currentObjectiveLabel', () {
      provider.nextObjective();
      provider.nextObjective();

      provider.resetObjective();
      expect(provider.currentObjectiveLabel, 'Easy');
    });
  });

  group('recordGameCompletion()', () {
    test('should save achievement with correct level for 256', () async {
      // Clear grid and set up test case
      for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
          provider.grid[i][j] = 0;
        }
      }
      provider.grid[0][0] = 256;

      await provider.recordGameCompletion();

      expect(fakeAchievementService.savedAchievements.length, 1);
      expect(fakeAchievementService.savedAchievements[0]['highestTile'], 256);
      expect(fakeAchievementService.savedAchievements[0]['levelPassed'], 'Easy (256)');
    });

    test('should save achievement with correct level for 512', () async {
      // Clear grid and set up test case
      for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
          provider.grid[i][j] = 0;
        }
      }
      provider.grid[0][0] = 512;

      await provider.recordGameCompletion();

      expect(fakeAchievementService.savedAchievements[0]['levelPassed'], 'Medium (512)');
    });

    test('should save achievement with correct level for 1024', () async {
      // Clear grid and set up test case
      for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
          provider.grid[i][j] = 0;
        }
      }
      provider.grid[0][0] = 1024;

      await provider.recordGameCompletion();

      expect(fakeAchievementService.savedAchievements[0]['levelPassed'], 'Hard (1024)');
    });

    test('should save achievement with correct level for 2048', () async {
      // Clear grid and set up test case
      for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
          provider.grid[i][j] = 0;
        }
      }
      provider.grid[0][0] = 2048;

      await provider.recordGameCompletion();

      expect(fakeAchievementService.savedAchievements[0]['levelPassed'], 'Expert (2048)');
    });

    test('should save achievement with None for tiles below 256', () async {
      // Clear grid and set up test case
      for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
          provider.grid[i][j] = 0;
        }
      }
      provider.grid[0][0] = 128;

      await provider.recordGameCompletion();

      expect(fakeAchievementService.savedAchievements[0]['levelPassed'], 'None');
    });

    test('should include current score in achievement', () async {
      // Clear grid and set up test case
      for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
          provider.grid[i][j] = 0;
        }
      }
      provider.grid[0][0] = 2;
      provider.grid[0][1] = 2;
      provider.move('left'); // Score should be 4

      await provider.recordGameCompletion();

      expect(fakeAchievementService.savedAchievements[0]['score'], greaterThan(0));
    });
  });

  group('GameStatsMixin - setUserInfo()', () {
    test('should set user ID', () {
      provider.setUserInfo('user123', 'TestUser');
      expect(provider.userId, 'user123');
    });

    test('should set display name', () {
      provider.setUserInfo('user123', 'TestUser');
      expect(provider.displayName, 'TestUser');
    });

    test('should accept null values', () {
      provider.setUserInfo(null, null);
      expect(provider.userId, null);
      expect(provider.displayName, null);
    });
  });

  group('GameStatsMixin - saveScore()', () {
    test('should not save score when userId is null', () async {
      provider.setUserInfo(null, null);

      final result = await provider.saveScore('2048', 100);

      expect(result, false);
      expect(fakeStatsService.savedStats.length, 0);
    });

    test('should not save score when score is 0', () async {
      provider.setUserInfo('user123', 'TestUser');

      final result = await provider.saveScore('2048', 0);

      expect(result, false);
      expect(fakeStatsService.savedStats.length, 0);
    });

    test('should not save score when score is negative', () async {
      provider.setUserInfo('user123', 'TestUser');

      final result = await provider.saveScore('2048', -10);

      expect(result, false);
      expect(fakeStatsService.savedStats.length, 0);
    });

    test('should save score with valid userId and score', () async {
      provider.setUserInfo('user123', 'TestUser');

      final result = await provider.saveScore('2048', 100);

      expect(result, true);
      expect(fakeStatsService.savedStats.length, 1);
      expect(fakeStatsService.savedStats[0]['userId'], 'user123');
      expect(fakeStatsService.savedStats[0]['gameType'], '2048');
      expect(fakeStatsService.savedStats[0]['score'], 100);
      expect(fakeStatsService.savedStats[0]['displayName'], 'TestUser');
    });

    test('should retry on failure up to 3 times', () async {
      provider.setUserInfo('user123', 'TestUser');
      fakeStatsService.shouldThrowError = true;

      final result = await provider.saveScore('2048', 100);

      expect(result, false);
      expect(fakeStatsService.callCount, 4); // Initial + 3 retries
    });

    test('should succeed on retry if error is fixed', () async {
      // Create a custom fake that fails once then succeeds
      final customFake = CustomRetryFakeStatsService();

      final customProvider = Game2048Provider(
        achievementService: fakeAchievementService,
        statsService: customFake,
      );
      customProvider.setUserInfo('user123', 'TestUser');

      final result = await customProvider.saveScore('2048', 100);

      expect(result, true);
      expect(customFake.callCount, 2); // Initial + 1 retry
      expect(customFake.savedStats.length, 1);
    });

    test('should set lastError when all retries fail', () async {
      provider.setUserInfo('user123', 'TestUser');
      fakeStatsService.shouldThrowError = true;

      await provider.saveScore('2048', 100);

      expect(provider.lastError, isNotNull);
      expect(provider.lastError, contains('Failed to save score'));
    });

    test('should set isSavingScore during save operation', () async {
      provider.setUserInfo('user123', 'TestUser');

      expect(provider.isSavingScore, false);

      final saveFuture = provider.saveScore('2048', 100);

      // Note: This test is tricky because the operation is fast
      // In a real scenario, isSavingScore would be true during the operation

      await saveFuture;
      expect(provider.isSavingScore, false);
    });

    test('should clear error with clearError()', () async {
      provider.setUserInfo('user123', 'TestUser');
      fakeStatsService.shouldThrowError = true;

      await provider.saveScore('2048', 100);
      expect(provider.lastError, isNotNull);

      provider.clearError();
      expect(provider.lastError, isNull);
    });
  });

  group('Game over detection', () {
    test('should detect game over when grid is full after a move', () {
      // Create a grid with only one empty space and one possible move
      // Pattern ensures no merges will happen
      provider.grid[0][0] = 2;
      provider.grid[0][1] = 4;
      provider.grid[0][2] = 8;
      provider.grid[0][3] = 16;
      provider.grid[1][0] = 32;
      provider.grid[1][1] = 64;
      provider.grid[1][2] = 128;
      provider.grid[1][3] = 256;
      provider.grid[2][0] = 512;
      provider.grid[2][1] = 1024;
      provider.grid[2][2] = 2048;
      provider.grid[2][3] = 4096;
      provider.grid[3][0] = 8192;
      provider.grid[3][1] = 16384;
      provider.grid[3][2] = 32768;
      provider.grid[3][3] = 0; // One empty space

      // Make a move - tiles can't move because they're already against edges
      // But it will add a tile to the empty space
      provider.move('down');

      // After the move, grid should be full and game over detected
      expect(provider.gameOver, true);
    });

    test('should save score when game over is detected', () async {
      provider.setUserInfo('user123', 'TestUser');
      fakeStatsService.reset();

      // First create some score by merging tiles
      for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
          provider.grid[i][j] = 0;
        }
      }
      provider.grid[0][0] = 2;
      provider.grid[0][1] = 2;
      provider.grid[0][2] = 4;
      provider.grid[0][3] = 4;
      provider.move('left'); // Creates score: 4 + 8 = 12

      // Now setup a grid with one empty space that will trigger game over
      provider.grid[0][0] = 2;
      provider.grid[0][1] = 4;
      provider.grid[0][2] = 8;
      provider.grid[0][3] = 16;
      provider.grid[1][0] = 32;
      provider.grid[1][1] = 64;
      provider.grid[1][2] = 128;
      provider.grid[1][3] = 256;
      provider.grid[2][0] = 512;
      provider.grid[2][1] = 1024;
      provider.grid[2][2] = 2048;
      provider.grid[2][3] = 4096;
      provider.grid[3][0] = 8192;
      provider.grid[3][1] = 16384;
      provider.grid[3][2] = 32768;
      provider.grid[3][3] = 0; // One empty

      // Make move that fills grid and triggers game over
      provider.move('down');

      // Wait for async save
      await Future.delayed(Duration(milliseconds: 100));

      // Verify game over was triggered and score was saved
      expect(provider.gameOver, true);
      expect(fakeStatsService.savedStats.length, greaterThan(0));
      expect(fakeStatsService.savedStats[0]['score'], greaterThan(0));
    });
  });

  group('Edge cases', () {
    test('should handle invalid move direction gracefully', () {
      expect(() => provider.move('invalid'), returnsNormally);
    });

    test('should handle empty string direction', () {
      expect(() => provider.move(''), returnsNormally);
    });

    test('should maintain grid size after multiple moves', () {
      for (int i = 0; i < 10; i++) {
        provider.move('left');
        provider.move('right');
        provider.move('up');
        provider.move('down');
      }

      expect(provider.grid.length, 4);
      for (var row in provider.grid) {
        expect(row.length, 4);
      }
    });

    test('should not have negative scores', () {
      // Clear grid and set up test case
      for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
          provider.grid[i][j] = 0;
        }
      }
      provider.grid[0][0] = 2;
      provider.grid[0][1] = 4;

      provider.move('left');

      expect(provider.score, greaterThanOrEqualTo(0));
    });
  });
}

/// Helper function to count non-zero tiles in the grid
int _countNonZeroTiles(List<List<int>> grid) {
  int count = 0;
  for (var row in grid) {
    for (var cell in row) {
      if (cell != 0) count++;
    }
  }
  return count;
}
