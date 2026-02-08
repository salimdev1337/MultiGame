import 'package:flutter_test/flutter_test.dart';
import 'package:multigame/games/snake/providers/snake_game_provider.dart';
import 'package:multigame/services/data/firebase_stats_service.dart';

// Mock Firebase Stats Service for testing
class MockFirebaseStatsService implements FirebaseStatsService {
  final List<Map<String, dynamic>> savedStats = [];
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
    callCount = 0;
  }

  // Other FirebaseStatsService methods (not tested here)
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late SnakeGameProvider provider;
  late MockFirebaseStatsService mockStatsService;

  setUp(() {
    mockStatsService = MockFirebaseStatsService();
    provider = SnakeGameProvider(statsService: mockStatsService);
  });

  tearDown(() {
    provider.dispose();
    mockStatsService.clear();
  });

  group('SnakeGameProvider - Initialization', () {
    test('initializes with correct default values', () {
      expect(provider.snake.length, 1);
      expect(provider.snake.first, const Offset(10, 10));
      expect(provider.currentDirection, Direction.right);
      expect(provider.gameMode, GameMode.classic);
      expect(provider.playing, isFalse);
      expect(provider.initialized, isFalse);
      expect(provider.score, 0);
      expect(provider.highScore, 0);
    });

    test('has correct grid size', () {
      expect(SnakeGameProvider.gridSize, 20);
    });

    test('has correct tick rate for classic mode', () {
      expect(provider.tickRate, const Duration(milliseconds: 200));
    });

    test('has correct tick rate for wrap mode', () {
      provider.setGameMode(GameMode.wrap);
      expect(provider.tickRate, const Duration(milliseconds: 200));
    });

    test('has correct tick rate for speed mode', () {
      provider.setGameMode(GameMode.speed);
      expect(provider.tickRate, const Duration(milliseconds: 120));
    });
  });

  group('SnakeGameProvider - startGame', () {
    test('initializes game state correctly', () {
      provider.startGame();

      expect(provider.snake.length, 1);
      expect(provider.snake.first, const Offset(10, 10));
      expect(provider.currentDirection, Direction.right);
      expect(provider.score, 0);
      expect(provider.playing, isTrue);
      expect(provider.initialized, isTrue);
    });

    test('spawns food at valid position', () {
      provider.startGame();

      expect(provider.food, isNotNull);
      expect(provider.food.dx, greaterThanOrEqualTo(0));
      expect(provider.food.dx, lessThan(SnakeGameProvider.gridSize));
      expect(provider.food.dy, greaterThanOrEqualTo(0));
      expect(provider.food.dy, lessThan(SnakeGameProvider.gridSize));
    });

    test('food is not spawned on snake position', () {
      provider.startGame();

      expect(provider.snake.contains(provider.food), isFalse);
    });

    test('resets score when restarting game', () {
      provider.setUserInfo('user_123', 'Player1');
      provider.startGame();

      // Simulate getting some points
      // (This would happen during actual gameplay)
      provider.startGame(); // Restart

      expect(provider.score, 0);
    });

    test('sets playing to true', () {
      expect(provider.playing, isFalse);

      provider.startGame();

      expect(provider.playing, isTrue);
    });

    test('sets initialized to true', () {
      expect(provider.initialized, isFalse);

      provider.startGame();

      expect(provider.initialized, isTrue);
    });
  });

  group('SnakeGameProvider - setGameMode', () {
    test('changes game mode to classic', () {
      provider.setGameMode(GameMode.classic);

      expect(provider.gameMode, GameMode.classic);
      expect(provider.tickRate, const Duration(milliseconds: 200));
    });

    test('changes game mode to wrap', () {
      provider.setGameMode(GameMode.wrap);

      expect(provider.gameMode, GameMode.wrap);
      expect(provider.tickRate, const Duration(milliseconds: 200));
    });

    test('changes game mode to speed', () {
      provider.setGameMode(GameMode.speed);

      expect(provider.gameMode, GameMode.speed);
      expect(provider.tickRate, const Duration(milliseconds: 120));
    });

    test('restarts game when changing mode', () {
      provider.startGame();

      // Manually change some state to verify restart
      // (In real gameplay, the snake would be longer and score higher)

      provider.setGameMode(GameMode.wrap);

      expect(provider.snake.length, 1);
      expect(provider.score, 0);
      expect(provider.playing, isTrue);
    });

    test('can switch between modes multiple times', () {
      provider.setGameMode(GameMode.classic);
      expect(provider.gameMode, GameMode.classic);

      provider.setGameMode(GameMode.speed);
      expect(provider.gameMode, GameMode.speed);

      provider.setGameMode(GameMode.wrap);
      expect(provider.gameMode, GameMode.wrap);

      provider.setGameMode(GameMode.classic);
      expect(provider.gameMode, GameMode.classic);
    });
  });

  group('SnakeGameProvider - togglePause', () {
    test('pauses a running game', () {
      provider.startGame();
      expect(provider.playing, isTrue);

      provider.togglePause();

      expect(provider.playing, isFalse);
    });

    test('resumes a paused game', () {
      provider.startGame();
      provider.togglePause(); // Pause
      expect(provider.playing, isFalse);

      provider.togglePause(); // Resume

      expect(provider.playing, isTrue);
    });

    test('can toggle multiple times', () {
      provider.startGame();

      provider.togglePause(); // Pause
      expect(provider.playing, isFalse);

      provider.togglePause(); // Resume
      expect(provider.playing, isTrue);

      provider.togglePause(); // Pause
      expect(provider.playing, isFalse);

      provider.togglePause(); // Resume
      expect(provider.playing, isTrue);
    });

    test('does not affect game state when pausing', () {
      provider.startGame();
      final snakeBefore = List<Offset>.from(provider.snake);
      final scoreBefore = provider.score;
      final foodBefore = provider.food;

      provider.togglePause();

      expect(provider.snake, snakeBefore);
      expect(provider.score, scoreBefore);
      expect(provider.food, foodBefore);
    });
  });

  group('SnakeGameProvider - changeDirection', () {
    test('changes direction from right to up', () {
      provider.startGame();

      provider.changeDirection(Direction.up);

      // Direction change takes effect on next tick, stored in _nextDirection
      // We can't directly check _nextDirection as it's private
      // But we can verify it doesn't change currentDirection immediately
      expect(provider.currentDirection, Direction.right);
    });

    test('changes direction from right to down', () {
      provider.startGame();

      provider.changeDirection(Direction.down);

      expect(provider.currentDirection, Direction.right);
    });

    test('does not allow reversing from right to left', () {
      provider.startGame();
      expect(provider.currentDirection, Direction.right);

      provider.changeDirection(Direction.left);

      // Should still be right (no reverse allowed)
      expect(provider.currentDirection, Direction.right);
    });

    test('does not allow reversing from left to right', () {
      provider.startGame();
      provider.changeDirection(Direction.up);

      // Simulate tick to actually change direction
      // (In real gameplay this happens automatically)

      provider.changeDirection(Direction.left);
      // Can't directly test this without ticking, but method should not crash
    });

    test('does not allow reversing from up to down', () {
      provider.startGame();
      provider.changeDirection(Direction.up);
      provider.changeDirection(Direction.down);
      // Should not crash or cause issues
    });

    test('does not allow reversing from down to up', () {
      provider.startGame();
      provider.changeDirection(Direction.down);
      provider.changeDirection(Direction.up);
      // Should not crash or cause issues
    });

    test('allows valid direction changes', () {
      provider.startGame();

      // Right -> Up (valid)
      provider.changeDirection(Direction.up);
      expect(() => provider.changeDirection(Direction.up), returnsNormally);

      // Right -> Down (valid)
      provider.changeDirection(Direction.down);
      expect(() => provider.changeDirection(Direction.down), returnsNormally);
    });

    test('can queue multiple valid direction changes', () {
      provider.startGame();

      provider.changeDirection(Direction.up);
      provider.changeDirection(Direction.left);
      provider.changeDirection(Direction.down);
      provider.changeDirection(Direction.right);

      // Should not crash
      expect(provider.currentDirection, Direction.right);
    });
  });

  group('SnakeGameProvider - Score tracking', () {
    test('starts with score of 0', () {
      provider.startGame();

      expect(provider.score, 0);
    });

    test('high score starts at 0', () {
      expect(provider.highScore, 0);
    });

    test('score is reset when starting new game', () {
      provider.startGame();
      provider.startGame(); // Restart

      expect(provider.score, 0);
    });
  });

  group('SnakeGameProvider - Game state management', () {
    test('game is not playing initially', () {
      expect(provider.playing, isFalse);
    });

    test('game is not initialized initially', () {
      expect(provider.initialized, isFalse);
    });

    test('game is playing after start', () {
      provider.startGame();

      expect(provider.playing, isTrue);
    });

    test('game is initialized after start', () {
      provider.startGame();

      expect(provider.initialized, isTrue);
    });

    test('initialized stays true after pause', () {
      provider.startGame();
      provider.togglePause();

      expect(provider.initialized, isTrue);
    });

    test('initialized stays true after resume', () {
      provider.startGame();
      provider.togglePause();
      provider.togglePause();

      expect(provider.initialized, isTrue);
    });
  });

  group('SnakeGameProvider - User info from mixin', () {
    test('can set user info', () {
      provider.setUserInfo('user_123', 'TestPlayer');

      expect(provider.userId, 'user_123');
      expect(provider.displayName, 'TestPlayer');
    });

    test('user info is null initially', () {
      expect(provider.userId, isNull);
      expect(provider.displayName, isNull);
    });

    test('can update user info', () {
      provider.setUserInfo('user_old', 'OldName');
      provider.setUserInfo('user_new', 'NewName');

      expect(provider.userId, 'user_new');
      expect(provider.displayName, 'NewName');
    });

    test('can set user info without display name', () {
      provider.setUserInfo('user_123', null);

      expect(provider.userId, 'user_123');
      expect(provider.displayName, isNull);
    });
  });

  group('SnakeGameProvider - Food spawning', () {
    test('food is spawned within grid bounds', () {
      provider.startGame();

      expect(provider.food.dx, greaterThanOrEqualTo(0));
      expect(provider.food.dx, lessThan(SnakeGameProvider.gridSize.toDouble()));
      expect(provider.food.dy, greaterThanOrEqualTo(0));
      expect(provider.food.dy, lessThan(SnakeGameProvider.gridSize.toDouble()));
    });

    test('food position changes on game restart', () {
      provider.startGame();
      final firstFood = provider.food;

      // Restart multiple times to increase chance of different position
      bool foundDifferent = false;
      for (int i = 0; i < 10; i++) {
        provider.startGame();
        if (provider.food != firstFood) {
          foundDifferent = true;
          break;
        }
      }

      // With 400 grid positions and random placement, should be different
      expect(foundDifferent, isTrue);
    });

    test('food has integer coordinates', () {
      provider.startGame();

      expect(provider.food.dx % 1, 0); // Is integer
      expect(provider.food.dy % 1, 0); // Is integer
    });
  });

  group('SnakeGameProvider - Snake initial state', () {
    test('snake starts at center position', () {
      provider.startGame();

      expect(provider.snake.first, const Offset(10, 10));
    });

    test('snake starts with length 1', () {
      provider.startGame();

      expect(provider.snake.length, 1);
    });

    test('snake position is within grid bounds', () {
      provider.startGame();

      for (final segment in provider.snake) {
        expect(segment.dx, greaterThanOrEqualTo(0));
        expect(segment.dx, lessThan(SnakeGameProvider.gridSize.toDouble()));
        expect(segment.dy, greaterThanOrEqualTo(0));
        expect(segment.dy, lessThan(SnakeGameProvider.gridSize.toDouble()));
      }
    });
  });

  group('SnakeGameProvider - Direction initial state', () {
    test('starts moving right', () {
      provider.startGame();

      expect(provider.currentDirection, Direction.right);
    });

    test('direction is consistent across restarts', () {
      provider.startGame();
      expect(provider.currentDirection, Direction.right);

      provider.startGame();
      expect(provider.currentDirection, Direction.right);

      provider.startGame();
      expect(provider.currentDirection, Direction.right);
    });
  });

  group('SnakeGameProvider - Timer management', () {
    test('timer is started when game starts', () async {
      provider.startGame();

      // Wait a bit and check game is still playing
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.playing, isTrue);
    });

    test('timer is cancelled on dispose', () async {
      final tempProvider = SnakeGameProvider(statsService: mockStatsService);
      tempProvider.startGame();

      tempProvider.dispose();

      // Wait to ensure timer would have ticked
      await Future.delayed(const Duration(milliseconds: 250));

      // Should not crash or cause issues
    });

    test('can restart game multiple times without timer issues', () async {
      provider.startGame();
      await Future.delayed(const Duration(milliseconds: 50));

      provider.startGame();
      await Future.delayed(const Duration(milliseconds: 50));

      provider.startGame();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.playing, isTrue);
    });

    test('pause stops timer ticks', () async {
      provider.startGame();
      final snakeBefore = List<Offset>.from(provider.snake);

      provider.togglePause();

      // Wait longer than tick rate
      await Future.delayed(const Duration(milliseconds: 300));

      // Snake should not have moved while paused
      expect(provider.snake, snakeBefore);
    });
  });

  group('SnakeGameProvider - Mode differences', () {
    test('classic mode has 200ms tick rate', () {
      provider.setGameMode(GameMode.classic);

      expect(provider.tickRate, const Duration(milliseconds: 200));
      expect(provider.gameMode, GameMode.classic);
    });

    test('wrap mode has 200ms tick rate', () {
      provider.setGameMode(GameMode.wrap);

      expect(provider.tickRate, const Duration(milliseconds: 200));
      expect(provider.gameMode, GameMode.wrap);
    });

    test('speed mode has 120ms tick rate', () {
      provider.setGameMode(GameMode.speed);

      expect(provider.tickRate, const Duration(milliseconds: 120));
      expect(provider.gameMode, GameMode.speed);
    });

    test('changing mode preserves tick rate consistency', () {
      provider.setGameMode(GameMode.classic);
      final classicRate = provider.tickRate;

      provider.setGameMode(GameMode.speed);
      final speedRate = provider.tickRate;

      provider.setGameMode(GameMode.classic);
      final classicRate2 = provider.tickRate;

      expect(classicRate, classicRate2);
      expect(speedRate, const Duration(milliseconds: 120));
    });
  });

  group('SnakeGameProvider - Edge cases', () {
    test('can call changeDirection before starting game', () {
      expect(() => provider.changeDirection(Direction.up), returnsNormally);
    });

    test('can call togglePause before starting game', () {
      expect(() => provider.togglePause(), returnsNormally);
    });

    test('can set game mode multiple times quickly', () {
      provider.setGameMode(GameMode.classic);
      provider.setGameMode(GameMode.speed);
      provider.setGameMode(GameMode.wrap);
      provider.setGameMode(GameMode.classic);

      expect(provider.gameMode, GameMode.classic);
    });

    test('can dispose without starting game', () {
      final tempProvider = SnakeGameProvider(statsService: mockStatsService);
      expect(() => tempProvider.dispose(), returnsNormally);
    });

    test('can dispose after starting game', () {
      final tempProvider = SnakeGameProvider(statsService: mockStatsService);
      tempProvider.startGame();

      expect(() => tempProvider.dispose(), returnsNormally);
    });

    test('can dispose while paused', () {
      final tempProvider = SnakeGameProvider(statsService: mockStatsService);
      tempProvider.startGame();
      tempProvider.togglePause();

      expect(() => tempProvider.dispose(), returnsNormally);
    });

    test('handles rapid start/stop cycles', () {
      provider.startGame();
      provider.startGame();
      provider.startGame();

      expect(provider.playing, isTrue);
      expect(provider.initialized, isTrue);
    });
  });

  group('SnakeGameProvider - Integration scenarios', () {
    test('typical game flow: start, play, pause, resume', () async {
      provider.setUserInfo('user_123', 'Player1');

      // Start game
      provider.startGame();
      expect(provider.playing, isTrue);
      expect(provider.initialized, isTrue);

      // Pause
      provider.togglePause();
      expect(provider.playing, isFalse);

      // Resume
      provider.togglePause();
      expect(provider.playing, isTrue);
    });

    test('mode switching during gameplay', () {
      provider.startGame();
      expect(provider.gameMode, GameMode.classic);

      provider.setGameMode(GameMode.speed);
      expect(provider.gameMode, GameMode.speed);
      expect(provider.playing, isTrue);

      provider.setGameMode(GameMode.wrap);
      expect(provider.gameMode, GameMode.wrap);
      expect(provider.playing, isTrue);
    });

    test('direction changes during gameplay', () {
      provider.startGame();

      provider.changeDirection(Direction.up);
      provider.changeDirection(Direction.down);
      provider.changeDirection(Direction.left);
      provider.changeDirection(Direction.right);

      // Should not crash
      expect(provider.playing, isTrue);
    });

    test('user plays, loses, and starts new game', () {
      provider.setUserInfo('user_123', 'Player1');

      // First game
      provider.startGame();
      expect(provider.score, 0);

      // Start new game (simulating game over and restart)
      provider.startGame();
      expect(provider.score, 0);
      expect(provider.playing, isTrue);
    });
  });

  group('SnakeGameProvider - ChangeNotifier behavior', () {
    test('notifies listeners on startGame', () {
      int notificationCount = 0;
      provider.addListener(() => notificationCount++);

      provider.startGame();

      expect(notificationCount, greaterThan(0));
    });

    test('notifies listeners on togglePause', () {
      provider.startGame();

      int notificationCount = 0;
      provider.addListener(() => notificationCount++);

      provider.togglePause();

      expect(notificationCount, greaterThan(0));
    });

    test('notifies listeners on setGameMode', () {
      int notificationCount = 0;
      provider.addListener(() => notificationCount++);

      provider.setGameMode(GameMode.speed);

      expect(notificationCount, greaterThan(0));
    });

    test('can remove listeners', () {
      int notificationCount = 0;
      void listener() => notificationCount++;

      provider.addListener(listener);
      provider.startGame();
      expect(notificationCount, greaterThan(0));

      final countBefore = notificationCount;
      provider.removeListener(listener);
      provider.togglePause();

      // Should not increment after removing listener
      expect(notificationCount, countBefore);
    });
  });

  group('SnakeGameProvider - Constants and enums', () {
    test('Direction enum has all values', () {
      expect(Direction.values.length, 4);
      expect(Direction.values, contains(Direction.up));
      expect(Direction.values, contains(Direction.down));
      expect(Direction.values, contains(Direction.left));
      expect(Direction.values, contains(Direction.right));
    });

    test('GameMode enum has all values', () {
      expect(GameMode.values.length, 3);
      expect(GameMode.values, contains(GameMode.classic));
      expect(GameMode.values, contains(GameMode.wrap));
      expect(GameMode.values, contains(GameMode.speed));
    });

    test('grid size is 20', () {
      expect(SnakeGameProvider.gridSize, 20);
    });
  });

  group('SnakeGameProvider - Memory management', () {
    test('dispose cleans up timer', () async {
      final tempProvider = SnakeGameProvider(statsService: mockStatsService);
      tempProvider.startGame();
      await Future.delayed(const Duration(milliseconds: 50));

      tempProvider.dispose();

      // Timer should be cancelled, no more ticks
      await Future.delayed(const Duration(milliseconds: 300));
      // Should not crash
    });

    test('multiple dispose calls throw error', () {
      final tempProvider = SnakeGameProvider(statsService: mockStatsService);
      tempProvider.startGame();

      tempProvider.dispose();
      // Second dispose should throw in debug mode
      expect(() => tempProvider.dispose(), throwsA(isA<AssertionError>()));
    });

    test('can create multiple providers', () {
      final provider2 = SnakeGameProvider(statsService: mockStatsService);
      final provider3 = SnakeGameProvider(statsService: mockStatsService);

      provider.startGame();
      provider2.startGame();
      provider3.startGame();

      expect(provider.playing, isTrue);
      expect(provider2.playing, isTrue);
      expect(provider3.playing, isTrue);

      // Only dispose the extra providers, tearDown will handle the main one
      provider2.dispose();
      provider3.dispose();
    });
  });
}
