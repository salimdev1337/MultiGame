import 'dart:math' as math;
import 'package:flame/components.dart';
import '../components/obstacle.dart';
import 'obstacle_pool.dart';

/// System that spawns obstacles at appropriate intervals
/// Ensures proper spacing, variety, and uses object pooling
class SpawnSystem {
  SpawnSystem({
    required this.gameWidth,
    required this.groundY,
    required this.obstaclePool,
  });

  double gameWidth;
  double groundY;
  final ObstaclePool obstaclePool;

  // Spawn configuration
  static const double minSpawnDistance = 350.0;
  static const double maxSpawnDistance = 600.0;
  static const double spawnX = 100.0; // Spawn beyond screen right edge

  double _nextSpawnDistance = minSpawnDistance;
  double _distanceTraveled = 0.0;

  final math.Random _random = math.Random();

  // Track last obstacle type for variety
  ObstacleType? _lastObstacleType;

  /// Update distance traveled and check if should spawn
  /// Returns obstacle if spawn needed, null otherwise
  Obstacle? update(
    double dt,
    double scrollSpeed,
    List<Obstacle> activeObstacles,
  ) {
    _distanceTraveled += scrollSpeed * dt;

    // Check if it's time to spawn
    if (_distanceTraveled >= _nextSpawnDistance) {
      _distanceTraveled = 0;
      _calculateNextSpawnDistance();

      // Verify safe spawn (no obstacles too close)
      if (_canSpawnSafely(activeObstacles)) {
        return _createObstacle(scrollSpeed);
      }
    }

    return null;
  }

  /// Check if we can safely spawn without overlapping
  bool _canSpawnSafely(List<Obstacle> obstacles) {
    if (obstacles.isEmpty) return true;

    // Check distance from rightmost obstacle
    double rightmostX = double.negativeInfinity;
    for (final obstacle in obstacles) {
      if (obstacle.position.x > rightmostX) {
        rightmostX = obstacle.position.x;
      }
    }

    final spawnPositionX = gameWidth + spawnX;
    return spawnPositionX - rightmostX >= minSpawnDistance;
  }

  /// Create new obstacle with varied type using object pool
  Obstacle _createObstacle(double scrollSpeed) {
    // Choose obstacle type with variety (avoid repeating same type)
    final type = _selectObstacleType();
    _lastObstacleType = type;

    // Calculate position - spawn at ground level (Anchor.bottomLeft)
    final spawnX = gameWidth + SpawnSystem.spawnX;
    final spawnY = groundY;

    // Get obstacle from pool
    return obstaclePool.acquire(type, Vector2(spawnX, spawnY));
  }

  /// Select obstacle type with variety and balance
  ObstacleType _selectObstacleType() {
    // All available types
    final types = ObstacleType.values;

    // Filter out last type for variety
    var availableTypes = types;
    if (_lastObstacleType != null) {
      availableTypes = types.where((t) => t != _lastObstacleType).toList();
    }

    // Random selection from available types
    return availableTypes[_random.nextInt(availableTypes.length)];
  }

  /// Calculate next spawn distance with some randomness
  void _calculateNextSpawnDistance() {
    _nextSpawnDistance =
        minSpawnDistance +
        _random.nextDouble() * (maxSpawnDistance - minSpawnDistance);
  }

  /// Reset spawn system for new game
  void reset() {
    _distanceTraveled = 0;
    _nextSpawnDistance = minSpawnDistance;
    _lastObstacleType = null;
  }

  /// Update dimensions when screen size changes
  void updateDimensions(double newGameWidth, double newGroundY) {
    gameWidth = newGameWidth;
    groundY = newGroundY;
  }
}
