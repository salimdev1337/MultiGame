import 'package:flame/components.dart';
import '../components/obstacle.dart';

/// Object pool for obstacles to avoid frequent allocations
/// Improves performance by reusing obstacle instances
class ObstaclePool {
  ObstaclePool({required this.scrollSpeed, this.debugMode = false});

  double scrollSpeed;
  final bool debugMode;

  // Pool of available obstacles
  final Map<ObstacleType, List<Obstacle>> _availableObstacles = {};

  // Maximum pool size per type
  static const int maxPoolSize = 10;

  /// Get an obstacle from the pool or create new one
  Obstacle acquire(ObstacleType type, Vector2 position) {
    final pool = _availableObstacles[type];

    if (pool != null && pool.isNotEmpty) {
      // Reuse from pool
      final obstacle = pool.removeLast();
      obstacle.scrollSpeed = scrollSpeed;
      obstacle.reset(position);
      return obstacle;
    } else {
      // Create new obstacle
      return Obstacle(type: type, position: position, scrollSpeed: scrollSpeed);
    }
  }

  /// Return obstacle to pool for reuse
  void release(Obstacle obstacle) {
    // Only pool if we haven't reached max size
    final pool = _availableObstacles.putIfAbsent(
      obstacle.type,
      () => <Obstacle>[],
    );

    if (pool.length < maxPoolSize) {
      // Reset obstacle state before pooling
      obstacle.removeFromParent();
      pool.add(obstacle);
    }
  }

  /// Update scroll speed for all future obstacles
  void updateSpeed(double newSpeed) {
    scrollSpeed = newSpeed;
  }

  /// Clear the pool (call when restarting game)
  void clear() {
    for (final pool in _availableObstacles.values) {
      for (final obstacle in pool) {
        obstacle.removeFromParent();
      }
      pool.clear();
    }
    _availableObstacles.clear();
  }
}
